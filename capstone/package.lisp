(defpackage #:course-tasks
  (:use #:cl)
  (:export #:make-store #:add-task #:complete-task #:all-tasks
           #:task-id #:task-title #:task-done-p #:save-store #:load-store
           #:bad-data #:missing-task))

;; Reader package for data files: symbols in a file are interned here, not in
;; the application package. Only NIL and T are shared with Common Lisp.
(defpackage #:course-tasks.data
  (:use)
  (:import-from #:cl #:nil #:t))
