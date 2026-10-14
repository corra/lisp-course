;; SBCL --script driver; core library code never exits the process.
(require :asdf)
(asdf:load-asd (merge-pathnames "course-tasks.asd" *load-truename*))
(asdf:load-system "course-tasks")

(defpackage #:course-tasks.cli (:use #:cl))
(in-package #:course-tasks.cli)

(defun usage (&optional (stream *standard-output*))
  (format stream "Usage: sbcl --script capstone/cli.lisp COMMAND ...~%")
  (format stream "  help | add FILE TITLE | list FILE | done FILE ID~%"))

(defun main (arguments)
  "Return an exit status: 0 success, 1 operation failed, 2 usage error."
  (unless (and arguments
               (cond ((string= (first arguments) "help") (= (length arguments) 1))
                     ((string= (first arguments) "list") (= (length arguments) 2))
                     ((member (first arguments) '("add" "done") :test #'string=)
                      (= (length arguments) 3))
                     (t nil)))
    (usage *error-output*)
    (return-from main 2))
  (when (string= (first arguments) "help")
    (usage)
    (return-from main 0))
  (handler-case
      (destructuring-bind (command file &optional argument) arguments
        (let ((store (course-tasks:load-store file)))
          (cond
            ((string= command "add")
             (let ((task (course-tasks:add-task store argument)))
               (course-tasks:save-store store file)
               (format t "Added ~D: ~A~%" (course-tasks:task-id task)
                       (course-tasks:task-title task))))
            ((string= command "done")
             (let ((id (parse-integer argument)))
               (course-tasks:complete-task store id)
               (course-tasks:save-store store file)
               (format t "Completed ~D.~%" id)))
            ((string= command "list")
             (dolist (task (course-tasks:all-tasks store))
               (format t "~D [~A] ~A~%" (course-tasks:task-id task)
                       (if (course-tasks:task-done-p task) "x" " ")
                       (course-tasks:task-title task))))))
        0)
    ;; A CLI boundary may report unexpected errors too, but must not claim success.
    (error (condition)
      (format *error-output* "Error: ~A~%" condition)
      1)))

(sb-ext:exit :code (main (rest sb-ext:*posix-argv*)))
