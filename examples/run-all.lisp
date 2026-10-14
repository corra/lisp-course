;; One entry point for the entire reference suite. Relative to this file,
;; not the caller's current working directory.
(load (merge-pathnames "smoke-tests.lisp" *load-truename*))
(load (merge-pathnames "exercise-solutions.lisp" *load-truename*))
(load (merge-pathnames "../capstone/run-tests.lisp" *load-truename*))
(load (merge-pathnames "../capstone/test-cli.lisp" *load-truename*))
(format t "All course reference tests passed.~%")
