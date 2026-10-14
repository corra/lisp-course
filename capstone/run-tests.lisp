(require :asdf)
(asdf:load-asd (merge-pathnames "course-tasks.asd" *load-truename*))
(asdf:test-system "course-tasks")
