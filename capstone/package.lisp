(defpackage #:course-tasks
  (:use #:cl)
  (:export #:make-store #:add-task #:complete-task #:all-tasks
           #:task-id #:task-title #:task-done-p #:save-store #:load-store
           #:bad-data #:missing-task))
