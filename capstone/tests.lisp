(defpackage #:course-tasks.tests
  (:use #:cl)
  (:export #:run-tests))
(in-package #:course-tasks.tests)

(defvar *checks* 0)

(defun check (test)
  (incf *checks*)
  (assert test))

(defmacro signals (type &body body)
  `(handler-case (progn ,@body nil)
     (,type () t)))

(defun check-bad-file (path text)
  (with-open-file (out path :direction :output :if-exists :supersede)
    (write-string text out))
  (check (signals course-tasks:bad-data (course-tasks:load-store path))))

(defun run-tests ()
  (let ((*checks* 0)
        (store (course-tasks:make-store)))
    (check (null (course-tasks:all-tasks store)))
    (let* ((title (copy-seq "Read"))
           (first (course-tasks:add-task store title)))
      (check (= 1 (course-tasks:task-id first)))
      (setf (char title 0) #\X)
      (setf (char (course-tasks:task-title first) 0) #\Y)
      (check (string= "Read" (course-tasks:task-title
                              (first (course-tasks:all-tasks store))))))
    (course-tasks:add-task store "Practice")
    (check (equal '(1 2) (mapcar #'course-tasks:task-id
                                (course-tasks:all-tasks store))))
    (course-tasks:complete-task store 1)
    (course-tasks:complete-task store 1)
    (check (course-tasks:task-done-p (first (course-tasks:all-tasks store))))
    (check (not (course-tasks:task-done-p (second (course-tasks:all-tasks store)))))
    (check (signals course-tasks:missing-task (course-tasks:complete-task store 99)))
    (dolist (title (list "" "   " (string #\Tab) 42 nil))
      (check (signals course-tasks:bad-data (course-tasks:add-task store title))))
    (dolist (id '(0 -1 "1" 1.5))
      (check (signals course-tasks:bad-data (course-tasks:complete-task store id))))
    (let ((copy (first (course-tasks:all-tasks store))))
      (setf (char (course-tasks:task-title copy) 0) #\Z)
      (check (string= "Read" (course-tasks:task-title
                              (first (course-tasks:all-tasks store))))))
    (uiop:with-temporary-file (:pathname path :stream stream :keep nil)
      (close stream)
      (course-tasks:save-store store path)
      (let ((loaded (course-tasks:load-store path)))
        (check (equal '(1 2) (mapcar #'course-tasks:task-id
                                    (course-tasks:all-tasks loaded))))
        (check (course-tasks:task-done-p (first (course-tasks:all-tasks loaded))))
        (check (string= "Practice" (course-tasks:task-title
                                    (second (course-tasks:all-tasks loaded)))))
        (check (= 3 (course-tasks:task-id (course-tasks:add-task loaded "Next")))))
      (dolist (text '("" "(" "nil" "(:version 2 :next-id 1 :tasks nil)"
                      "(:version 1 :next-id 1 :tasks ((1 \"A\" nil)))"
                      "(:version 1 :next-id 3 :tasks ((1 \"A\" nil) (1 \"B\" t)))"
                      "(:version 1 :next-id 2 :tasks ((1 \" \" nil)))"
                      "(:version 1 :next-id 2 :tasks ((1 \"A\" :yes)))"
                      "(:version 1 :next-id 2 :tasks ((1 \"A\" nil extra)))"
                      "(:version 1 :next-id 1 :tasks nil) 42"
                      "#.42"
                      "(:version 1 :next-id 1 :tasks (a . b))"
                      "(:version 1 :next-id 1 :tasks #1=(nil . #1#))"))
        (check-bad-file path text))
      (course-tasks:save-store (course-tasks:make-store) path)
      (check (null (course-tasks:all-tasks (course-tasks:load-store path))))
      (delete-file path)
      (check (null (course-tasks:all-tasks (course-tasks:load-store path)))))
    (format t "Capstone: ~D checks passed.~%" *checks*)
    t))
