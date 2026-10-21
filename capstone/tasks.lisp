(in-package #:course-tasks)

(define-condition bad-data (error)
  ((detail :initarg :detail :reader bad-data-detail))
  (:report (lambda (condition stream)
             (format stream "Invalid task data: ~A"
                     (bad-data-detail condition)))))

(define-condition missing-task (error)
  ((id :initarg :id :reader missing-task-id))
  (:report (lambda (condition stream)
             (format stream "No task has ID ~D."
                     (missing-task-id condition)))))

(defstruct (task (:constructor %make-task (id title done-p)))
  id title done-p)

(defstruct (store (:constructor make-store ()))
  (next-id 1)
  (tasks nil))

(defun reject-data (control &rest arguments)
  (error 'bad-data :detail (apply #'format nil control arguments)))

(defun valid-title-p (value)
  ;; One line per task keeps LIST output unambiguous.
  (and (stringp value)
       (not (or (find #\Newline value) (find #\Return value)))
       (plusp (length (string-trim '(#\Space #\Tab) value)))))

(defun owned-title (title)
  ;; A fresh CHARACTER string. SBCL's command-line arguments are base strings,
  ;; which *PRINT-READABLY* would save in SBCL-specific #A syntax, not "...".
  (make-array (length title) :element-type 'character :initial-contents title))

(defun detached-task (task)
  ;; The structure copier alone would leave the title string shared.
  (%make-task (task-id task) (owned-title (task-title task)) (task-done-p task)))

(defun add-task (store title)
  "Add a nonblank, single-line TITLE. Return a detached record with a fresh ID."
  (unless (valid-title-p title)
    (reject-data "Title must be a nonblank, single-line string."))
  (let ((task (%make-task (store-next-id store) (owned-title title) nil)))
    (incf (store-next-id store))
    (push task (store-tasks store))
    (detached-task task)))

(defun complete-task (store id)
  "Mark ID complete, idempotently. Signal MISSING-TASK if it is absent."
  (unless (typep id '(integer 1 *))
    (reject-data "ID must be a positive integer."))
  (let ((task (find id (store-tasks store) :key #'task-id :test #'=)))
    (unless task (error 'missing-task :id id))
    (setf (task-done-p task) t)
    (detached-task task)))

(defun all-tasks (store)
  "Return detached task records ordered by ascending ID."
  (mapcar #'detached-task
          (sort (copy-list (store-tasks store)) #'< :key #'task-id)))

(defun proper-list-p (object)
  ;; LIST-LENGTH returns NIL for circular lists; NIL itself has length zero.
  (and (listp object)
       (handler-case (not (null (list-length object)))
         (type-error () nil))))

(defun store-data (store)
  (list :version 1 :next-id (store-next-id store)
        :tasks (mapcar (lambda (task)
                         (list (task-id task) (task-title task)
                               (task-done-p task)))
                       (all-tasks store))))

(defun data-store (data)
  ;; Version 1 has a canonical field order, deliberately not an arbitrary plist.
  (unless (and (proper-list-p data) (= (length data) 6)
               (eq (first data) :version) (eql (second data) 1)
               (eq (third data) :next-id) (eq (fifth data) :tasks))
    (reject-data "Expected canonical version-1 store fields."))
  (let ((next-id (fourth data))
        (records (sixth data))
        (seen (make-hash-table :test #'eql))
        (store (make-store))
        (largest-id 0))
    (unless (and (typep next-id '(integer 1 *)) (proper-list-p records))
      (reject-data "Invalid next ID or task list."))
    (dolist (record records)
      (unless (and (proper-list-p record) (= (length record) 3))
        (reject-data "Each task must have exactly three fields."))
      (destructuring-bind (id title done-p) record
        (unless (and (typep id '(integer 1 *)) (valid-title-p title)
                     (member done-p '(nil t) :test #'eq))
          (reject-data "Invalid task fields."))
        (when (gethash id seen) (reject-data "Duplicate ID ~D." id))
        (setf (gethash id seen) t
              largest-id (max largest-id id))
        (push (%make-task id (owned-title title) done-p) (store-tasks store))))
    (unless (> next-id largest-id)
      (reject-data "Next ID must exceed every existing ID."))
    (setf (store-next-id store) next-id)
    store))

(defun save-store (store path)
  "Save STORE to PATH, replacing it. Single-process, non-atomic local storage."
  (let ((data (store-data store)))
    ;; Validate before opening/truncating the destination.
    (data-store data)
    (with-open-file (out path :direction :output :if-exists :supersede
                             :if-does-not-exist :create :external-format :utf-8)
      (with-standard-io-syntax
        (let ((*print-readably* t))
          (write data :stream out)
          (terpri out)))))
  store)

(defun load-store (path)
  "Read a trusted local data file; a nonexistent PATH means an empty store."
  (unless (probe-file path) (return-from load-store (make-store)))
  (with-open-file (in path :direction :input :external-format :utf-8)
    (with-standard-io-syntax
      (let ((*read-eval* nil)
            (*package* (find-package :course-tasks.data))
            (eof (gensym "EOF")))
        (handler-case
            (let ((data (read in nil eof)))
              (when (eq data eof) (reject-data "Empty file."))
              (unless (eq (read in nil eof) eof)
                (reject-data "Extra object after store."))
              (data-store data))
          (reader-error () (reject-data "Reader rejected the file."))
          (end-of-file () (reject-data "Incomplete data in file.")))))))
