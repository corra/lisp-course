;; Explicit opt-in: this file is NEVER loaded by examples/run-all.lisp.
;; QUICKLOAD may use the network if dependencies are not installed yet.
(require :asdf)

(let ((setup (or (uiop:getenv "COURSE_QUICKLISP_SETUP")
                 (merge-pathnames "quicklisp/setup.lisp"
                                  (user-homedir-pathname)))))
  (unless (probe-file setup)
    (error "Quicklisp setup not found at ~A. See optional/QUICKLISP.md." setup))
  (load setup))

;; Keep this as a separate top-level form: QL must exist before it is read.
(ql:quickload '("alexandria" "fiveam"))

(format t "Implementation: ~A ~A~%ASDF: ~A~%"
        (lisp-implementation-type) (lisp-implementation-version)
        (asdf:asdf-version))
(format t "Quicklisp client: ~A~%" (ql:client-version))
(dolist (dist (ql-dist:all-dists))
  (format t "Distribution: ~A ~A~%" (ql-dist:name dist) (ql-dist:version dist)))
(dolist (name '("alexandria" "fiveam"))
  (format t "System: ~A ~A, source: ~A~%" name
          (asdf:component-version (asdf:find-system name))
          (asdf:system-source-directory name)))

(asdf:load-asd (merge-pathnames "../capstone/course-tasks.asd" *load-truename*))
(asdf:load-asd (merge-pathnames "libraries/course-extras.asd" *load-truename*))
(asdf:test-system "course-extras")
