;; This file can be loaded for its definitions or run as an SBCL script.
(defpackage #:course-exercises
  (:use #:cl)
  (:export #:run-tests))
(in-package #:course-exercises)

;; Lessons 03–04: functions, closures, and iteration.
(defun price-with-tax (price &key (rate 1/5))
  (* price (+ 1 rate)))

(defun make-stepper (&key (start 0) (step 1))
  (let ((value start))
    (lambda () (incf value step))))

(defun factorial-iter (n)
  (check-type n (integer 0 *))
  ;; Starting at 1 makes zero iterations return the correct factorial of 0.
  (let ((result 1))
    (dotimes (i n result)
      (setf result (* result (1+ i))))))

(defun sum-squares (n)
  (check-type n (integer 0 *))
  (loop for i from 1 to n sum (* i i)))

(defun safe-mean (numbers)
  (let ((count 0)
        (total 0))
    (dolist (n numbers)
      (incf count)
      (incf total n))
    (if (zerop count)
        (values nil nil)
        (values (/ total count) t))))

;; Lessons 05–06: lists and sequences.
(defun count-occurrences (item items)
  (let ((total 0))
    (dolist (candidate items total)
      (when (equal item candidate) (incf total)))))

(defun replace-first-copy (items value)
  (check-type items cons)
  (let ((result (copy-list items)))
    (setf (first result) value)
    result))

(defun positive-squares (numbers)
  (mapcar (lambda (n) (* n n)) (remove-if-not #'plusp numbers)))

(defun total-by (projection items)
  (let ((total 0))
    (dolist (item items total)
      (incf total (funcall projection item)))))

(defun sorted-scores (entries)
  (sort (copy-list entries)
        (lambda (left right)
          (or (> (cdr left) (cdr right))
              (and (= (cdr left) (cdr right))
                   (string< (car left) (car right)))))))

(defun sum-positive-squares (numbers)
  (loop for n in numbers when (plusp n) sum (* n n)))

;; Lessons 07–08: collections and streams.
(defun frequencies (items)
  (let ((table (make-hash-table :test #'equal)))
    (dolist (item items table)
      (incf (gethash item table 0)))))

(defun lookup-or-error (key table)
  (multiple-value-bind (value present-p) (gethash key table)
    (unless present-p (error "Missing key: ~S" key))
    value))

(defun square-buffer ()
  (let ((buffer (make-array 0 :adjustable t :fill-pointer 0)))
    (dotimes (i 10 buffer)
      (vector-push-extend (* i i) buffer))))

(defun count-lines-in (in)
  (loop for line = (read-line in nil nil) while line count t))

(defun count-lines (path)
  (with-open-file (in path :direction :input)
    (count-lines-in in)))

(defun parse-positive-integer (text)
  (let ((number (parse-integer text)))
    (unless (plusp number)
      (error "Expected a positive integer"))
    number))

;; Lesson 11: caller-selected recovery.
(define-condition invalid-score (error)
  ((value :initarg :value :reader invalid-score-value))
  (:report (lambda (condition stream)
             (format stream "Invalid score ~S" (invalid-score-value condition)))))

(defun validated-score (value)
  (if (and (integerp value) (<= 0 value 100))
      value
      (error 'invalid-score :value value)))

(defun recoverable-score (value)
  (restart-case (validated-score value)
    (use-zero () :report "Use zero." 0)))

;; Lesson 12: records and generic behavior.
(defstruct reading (sensor "unknown") (value 0))

(defclass sensor-alert ()
  ((message :initarg :message :reader alert-message)))

(defclass urgent-alert (sensor-alert) ())

(defgeneric render (object))
(defmethod render ((object reading))
  (format nil "~A: ~A" (reading-sensor object) (reading-value object)))
(defmethod render ((object sensor-alert)) (alert-message object))
(defmethod render ((object urgent-alert))
  (concatenate 'string "URGENT: " (call-next-method)))

;; Lesson 13: once-only evaluation and intentional binding.
(defmacro twice (expression)
  (let ((value (gensym "VALUE")))
    `(let ((,value ,expression)) (+ ,value ,value))))

(defmacro when-bind ((name expression) &body body)
  `(let ((,name ,expression)) (when ,name ,@body)))

;; Lesson 14: contrast allocation strategies, not compiler safety levels.
(defun build-with-append (n)
  (let ((items nil))
    (dotimes (i n items)
      (setf items (append items (list i))))))

(defun build-with-push (n)
  (let ((items nil))
    (dotimes (i n (nreverse items)) (push i items))))

(defvar *checks* 0)
(defun check (value)
  (incf *checks*)
  (assert value))

(defmacro signals (type &body body)
  `(handler-case (progn ,@body nil) (,type () t)))

(defun run-tests ()
  (let ((*checks* 0))
    (check (= 120 (price-with-tax 100)))
    (check (= 105 (price-with-tax 100 :rate 1/20)))
    (let ((a (make-stepper :start 10 :step 2)) (b (make-stepper)))
      (check (equal '(12 14 1) (list (funcall a) (funcall a) (funcall b)))))
    (check (= 1 (factorial-iter 0)))
    (check (= 120 (factorial-iter 5)))
    (check (signals type-error (factorial-iter -1)))
    (check (signals type-error (factorial-iter 1/2)))
    (check (= 0 (sum-squares 0)))
    (check (= 14 (sum-squares 3)))
    (check (equal '(5/3 t) (multiple-value-list (safe-mean '(1 2 2)))))
    (check (equal '(nil nil) (multiple-value-list (safe-mean nil))))
    (check (= 2 (count-occurrences '(1) '((1) (2) (1)))))
    (check (= 0 (count-occurrences :x nil)))
    (let* ((input (list 1 2 3)) (result (replace-first-copy input 9)))
      (check (equal '(1 2 3) input))
      (check (equal '(9 2 3) result)))
    (check (equal '(9 1) (positive-squares '(-2 0 3 1))))
    (check (null (positive-squares nil)))
    (check (= 8 (total-by #'cdr (list (cons "Ada" 5) (cons "Bob" 3)))))
    (check (= 6 (total-by #'identity '(1 2 3))))
    (check (= 0 (total-by #'identity nil)))
    (let* ((input (list (cons (copy-seq "Bob") 3)
                        (cons (copy-seq "Ada") 3)
                        (cons (copy-seq "Zoe") 4)))
           ;; Copy both the pairs and their mutable names. A shallow snapshot
           ;; would share score/name changes with INPUT and miss mutation bugs.
           (before (mapcar (lambda (entry)
                             (cons (copy-seq (car entry)) (cdr entry)))
                           input))
           (result (sorted-scores input)))
      (check (equal '(("Zoe" . 4) ("Ada" . 3) ("Bob" . 3)) result))
      (check (equal before input)))
    (check (= 10 (sum-positive-squares '(-2 0 3 1))))
    (let ((table (frequencies (list (copy-seq "a") (copy-seq "a")))))
      (check (= 2 (gethash "a" table)))
      (setf (gethash "nil" table) nil)
      (check (null (lookup-or-error "nil" table)))
      (check (signals simple-error (lookup-or-error "absent" table))))
    (check (equalp #(0 1 4 9 16 25 36 49 64 81) (square-buffer)))
    (dolist (case (list (cons "" 0) (cons (string #\Newline) 1)
                       (cons (format nil "one~%two") 2)))
      (with-input-from-string (in (car case))
        (check (= (cdr case) (count-lines-in in)))))
    (check (= 42 (parse-positive-integer " 42 ")))
    (check (signals parse-error (parse-positive-integer "3x")))
    (check (signals simple-error (parse-positive-integer "0")))
    (check (signals simple-error (parse-positive-integer "-1")))
    (check (= 0 (validated-score 0)))
    (check (= 100 (validated-score 100)))
    (dolist (value '(-1 101 "1"))
      (check (signals invalid-score (validated-score value))))
    (check (signals invalid-score (recoverable-score 101)))
    (handler-bind ((invalid-score (lambda (c)
                                   (declare (ignore c))
                                   (invoke-restart 'use-zero))))
      (check (= 0 (recoverable-score 101)))
      (check (= 50 (recoverable-score 50))))
    (check (string= "unknown: 0" (render (make-reading))))
    (check (string= "hot" (render (make-instance 'sensor-alert :message "hot"))))
    (check (string= "URGENT: hot"
                    (render (make-instance 'urgent-alert :message "hot"))))
    (check (equal '(2 1) (let ((n 0)) (list (twice (incf n)) n))))
    (check (null (when-bind (x nil) (error "Body ran: ~S" x))))
    (check (= 1 (when-bind (x 0) (1+ x))))
    (check (equal '(1 1)
                  (let ((n 0)) (list (when-bind (x (incf n)) x) n))))
    (check (equal (build-with-append 100) (build-with-push 100)))
    (format t "Exercise solutions: ~D checks passed.~%" *checks*)
    t))

(run-tests)
