(defpackage #:course-extras.tests
  (:use #:cl)
  (:export #:run-tests))
(in-package #:course-extras.tests)

(fiveam:def-suite extras :description "Optional library examples and capstone checks")
(fiveam:in-suite extras)

(fiveam:test empty-report
  (fiveam:is (null (course-extras:word-count-report nil))))

(fiveam:test normalized-counts
  (fiveam:is (equal '(("lisp" . 2) ("sbcl" . 1))
                    (course-extras:word-count-report '("Lisp" "SBCL" "LISP")))))

(fiveam:test deterministic-ties
  (fiveam:is (equal '(("ada" . 1) ("grace" . 1))
                    (course-extras:word-count-report '("Grace" "Ada")))))

(fiveam:test ownership
  (let* ((word (copy-seq "Lisp"))
         (report (course-extras:word-count-report (list word))))
    (fiveam:is (string= "Lisp" word))
    (setf (char word 0) #\X)
    (fiveam:is (string= "lisp" (caar report)))))

(fiveam:test invalid-word
  (fiveam:signals type-error
    (course-extras:word-count-report '("Lisp" 42))))

(fiveam:test task-completion
  (let* ((store (course-tasks:make-store))
         (task (course-tasks:add-task store "Run library tests")))
    (fiveam:is (= 1 (course-tasks:task-id task)))
    (fiveam:is (not (course-tasks:task-done-p task)))
    (course-tasks:complete-task store 1)
    (fiveam:is (course-tasks:task-done-p (first (course-tasks:all-tasks store))))
    (fiveam:signals course-tasks:missing-task
      (course-tasks:complete-task store 99))))

(fiveam:test invalid-title
  (fiveam:signals course-tasks:bad-data
    (course-tasks:add-task (course-tasks:make-store) "  ")))

(defun run-tests ()
  "Explain results and signal an error if any test failed or was skipped."
  (let* ((fiveam:*debug-on-error* nil)
         (fiveam:*debug-on-failure* nil)
         (results (fiveam:run 'extras)))
    (fiveam:explain! results)
    ;; Printing a report alone does not guarantee an unsuccessful process exit.
    (unless (fiveam:results-status results)
      (error "Optional library tests failed or were skipped."))
    t))
