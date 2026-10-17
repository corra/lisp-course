(asdf:defsystem "course-extras"
  :description "Optional Alexandria and FiveAM course lab"
  :version "0.1.0"
  :depends-on ("alexandria")
  :serial t
  :components ((:file "package") (:file "report"))
  :in-order-to ((asdf:test-op (asdf:test-op "course-extras/tests"))))

(asdf:defsystem "course-extras/tests"
  :depends-on ("course-extras" "course-tasks" "fiveam")
  :components ((:file "tests"))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :course-extras.tests :run-tests)))
