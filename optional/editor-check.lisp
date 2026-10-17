;;; Small, dependency-free source file for optional editor setup verification.
(defpackage #:course-editor-check
  (:use #:cl)
  (:export #:greeting))

(in-package #:course-editor-check)

(defun greeting (name)
  "Return a greeting for NAME to verify a source-load/runtime connection."
  (format nil "Hello, ~A. SBCL is connected." name))
