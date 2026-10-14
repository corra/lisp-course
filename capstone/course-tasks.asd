(asdf:defsystem "course-tasks"
  :description "Editor-independent Common Lisp course capstone"
  :version "1.0.0"
  :serial t
  :components ((:file "package") (:file "tasks"))
  :in-order-to ((asdf:test-op (asdf:test-op "course-tasks/tests"))))

(asdf:defsystem "course-tasks/tests"
  :depends-on ("course-tasks")
  :serial t
  :components ((:file "tests"))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :course-tasks.tests :run-tests)))
