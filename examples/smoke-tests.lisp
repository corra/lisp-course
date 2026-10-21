;; Run from any directory; no editor or external libraries required.
(defpackage #:course-smoke (:use #:cl))
(in-package #:course-smoke)

;;; Lesson 08–14 examples, copied from the lessons so their claims stay checked.

(defun count-lines-in (in)
  (loop for line = (read-line in nil nil)
        while line
        count t))

(defun print-banner ()
  (format t "== Report ==~%"))

(define-condition invalid-score (error)
  ((value :initarg :value :reader invalid-score-value))
  (:report (lambda (condition stream)
             (format stream "Invalid score: ~S"
                     (invalid-score-value condition)))))

(defun checked-score (value)
  (check-type value (integer 0 100))
  value)

(defun validated-score (value)
  (if (and (integerp value) (<= 0 value 100))
      value
      (error 'invalid-score :value value)))

(defun recoverable-score (value)
  (restart-case (validated-score value)
    (use-zero ()
      :report "Use zero for this score."
      0)))

(defstruct reading
  (sensor "unknown")
  (value 0))

(defclass task ()
  ((title :initarg :title :reader task-title)
   (done-p :initform nil :accessor task-done-p)))

(defclass urgent-task (task)
  ((deadline :initarg :deadline :reader task-deadline)))

(defgeneric display-label (object))

(defmethod display-label ((object task))
  (format nil "[~A] ~A" (if (task-done-p object) "x" " ")
          (task-title object)))

(defmethod display-label ((object urgent-task))
  (format nil "~A (due ~A)" (call-next-method) (task-deadline object)))

(defmacro when-positive (expression &body body)
  `(when (plusp ,expression)
     ,@body))

(defmacro bad-twice (expression)
  `(+ ,expression ,expression))

(defmacro twice (expression)
  (let ((value (gensym "VALUE")))
    `(let ((,value ,expression))
       (+ ,value ,value))))

(defmacro with-collected-output ((name) &body body)
  `(with-output-to-string (,name)
     ,@body))

(defun sum-double-vector (samples)
  (declare (type (simple-array double-float (*)) samples)
           (optimize (speed 2) (safety 3) (debug 1)))
  (loop for value across samples
        sum value into total of-type double-float
        finally (return total)))

(defun run-later-lesson-tests (check)
  "Run Lesson 08–14 example checks, calling CHECK on each result."
  ;; Lesson 08: string streams, rebinding *STANDARD-OUTPUT*, parsing, READ.
  (funcall check (= 1 (with-input-from-string (in "last line without newline")
                        (count-lines-in in))))
  (funcall check (= 0 (with-input-from-string (in "") (count-lines-in in))))
  (funcall check (= 1 (with-input-from-string (in (format nil "~%"))
                        (count-lines-in in))))
  (funcall check (string= (format nil "== Report ==~%")
                          (with-output-to-string (out)
                            (let ((*standard-output* out))
                              (print-banner)))))
  (funcall check (equal '(42 4) (multiple-value-list (parse-integer " 42 "))))
  (funcall check (equal '(42 2) (multiple-value-list
                                 (parse-integer "42x" :junk-allowed t))))
  (funcall check (handler-case (progn (parse-integer "42x") nil)
                   (parse-error () t)))
  (funcall check (null (let ((eof (gensym "EOF"))
                             (*read-eval* nil))
                         (with-input-from-string (in "nil")
                           (let ((value (read in nil eof)))
                             (if (eq value eof) :empty value))))))
  (funcall check (handler-case (let ((*read-eval* nil))
                                 (read-from-string "#.(+ 1 2)")
                                 nil)
                   (reader-error () t)))
  ;; Lesson 11: handlers and restarts.
  (funcall check (eq :rejected (handler-case (checked-score 150)
                                 (type-error () :rejected))))
  (funcall check (string= "Rejected 150"
                          (handler-case (validated-score 150)
                            (invalid-score (condition)
                              (format nil "Rejected ~S"
                                      (invalid-score-value condition))))))
  (funcall check (= 0 (handler-bind ((invalid-score
                                       (lambda (condition)
                                         (declare (ignore condition))
                                         (invoke-restart 'use-zero))))
                        (recoverable-score 150))))
  (funcall check (= 50 (recoverable-score 50)))
  ;; Lesson 12: structures and generic functions.
  (funcall check (= 22 (let ((r (make-reading :sensor "room" :value 21)))
                         (incf (reading-value r))
                         (reading-value r))))
  (funcall check (string= "[ ] Study (due Friday)"
                          (display-label (make-instance 'urgent-task
                                                        :title "Study"
                                                        :deadline "Friday"))))
  ;; Lesson 13: expansions, repeated evaluation, intentional binding.
  (funcall check (equal '((when (plusp (+ 1 2)) (format t "yes~%")) t)
                        (multiple-value-list
                         (macroexpand-1 '(when-positive (+ 1 2)
                                          (format t "yes~%"))))))
  (funcall check (equal '(3 2) (let ((n 0)) (list (bad-twice (incf n)) n))))
  (funcall check (equal '(2 1) (let ((n 0)) (list (twice (incf n)) n))))
  (funcall check (string= "hi" (with-collected-output (out)
                                 (write-string "hi" out))))
  (funcall check (string= "(+ 2 3)" (eval "(+ 2 3)")))
  ;; Lesson 14: a specialized vector and its empty case.
  (funcall check (= 3d0 (sum-double-vector
                         (make-array 2 :element-type 'double-float
                                       :initial-contents '(1d0 2d0)))))
  (funcall check (= 0d0 (sum-double-vector
                         (make-array 0 :element-type 'double-float)))))

(defun run-tests ()
  (let ((checks 0))
    (flet ((check (value) (incf checks) (assert value)))
      (check (= 36 (* (+ 8 4) (- 9 6))))
      (check (equal '(5 (+ 2 3)) (list (+ 2 3) '(+ 2 3))))
      (check (eq :safe (if t :safe (/ 1 0))))
      (check (equal '(+ 1 2) (list '+ 1 2)))
      (check (= 3 (eval '(+ 1 2))))
      (check (= 5 (eval (list '+ 2 3))))
      (check (string= "(+ 2 3)" (eval "(+ 2 3)")))
      (check (= 7 (progn (+ 1 2) (+ 3 4))))
      (check (equal '(3 7) (list (+ 1 2) (+ 3 4))))
      (check (null (progn)))
      (check (equal '(1 2)
                    (multiple-value-list (progn (values 0) (values 1 2)))))
      (dolist (n '(-3 0 5))
        (check (eq (cond ((minusp n) :negative)
                         ((zerop n) :zero)
                         (t :positive))
                   (if (minusp n) :negative
                       (if (zerop n) :zero :positive)))))
      (check (null (cond ((> 2 4) :not-reached))))
      (check (string= "two"
                      (case 2 (1 "one") (2 "two") (otherwise "other"))))
      (check (= 5 (flet ((add-one (n) (1+ n))) (add-one 4))))
      (let* ((result nil)
             (output (with-output-to-string (out)
                       (let ((*standard-output* out))
                         (setf result (progn (format t "Hi~%") 9))))))
        (check (= 9 result))
        (check (string= (format nil "Hi~%") output)))
      (check (= 42 (if (> 4 2) (progn (+ 1 2) (+ 20 22)) 0)))
      (check (= 42 (when (> 4 2) (+ 1 2) (+ 20 22))))
      (check (null (when (> 2 4) (/ 1 0))))
      (check (string= "The comparison was false."
                      (unless (> 2 4) "The comparison was false.")))
      ;; Final AND/OR forms preserve all values; earlier short circuits do not.
      (check (equal '(1 2) (multiple-value-list (or nil (values 1 2)))))
      (check (equal '(1) (multiple-value-list (or (values 1 2) :not-reached))))
      (check (equal '(nil :extra)
                    (multiple-value-list (and t (values nil :extra)))))
      (check (equal '(nil)
                    (multiple-value-list (and (values nil :extra) :not-reached))))
      (check (= 5/3 (/ (+ 1 2 2) 3)))
      (check (typep (coerce 5/3 'double-float) 'double-float))
      (check (equal '(-2 -1) (multiple-value-list (truncate -7 3))))
      ;; Compare every rounding policy, including both divisor signs,
      ;; exact division, zero, and the reconstruction invariant.
      (dolist (case '((7 3 ((2 1) (3 -2) (2 1) (2 1)))
                      (-7 3 ((-3 2) (-2 -1) (-2 -1) (-2 -1)))
                      (7 -3 ((-3 -2) (-2 1) (-2 1) (-2 1)))
                      (-7 -3 ((2 -1) (3 2) (2 -1) (2 -1)))
                      (6 3 ((2 0) (2 0) (2 0) (2 0)))
                      (0 3 ((0 0) (0 0) (0 0) (0 0)))))
        (destructuring-bind (number divisor expected-results) case
          (loop for operation in '(floor ceiling truncate round)
                for expected in expected-results
                do (multiple-value-bind (quotient remainder)
                       (funcall operation number divisor)
                     (check (equal expected (list quotient remainder)))
                     (check (= number (+ (* quotient divisor) remainder)))))))
      (dolist (case '((5 2 (2 1)) (7 2 (4 -1))
                      (-5 2 (-2 -1)) (-7 2 (-4 1))))
        (destructuring-bind (number divisor expected) case
          (multiple-value-bind (quotient remainder) (round number divisor)
            (check (equal expected (list quotient remainder)))
            (check (= number (+ (* quotient divisor) remainder))))))
      (check (equal '(2 1/3) (multiple-value-list (floor 7/3))))
      (check (equal '(2 1) (multiple-value-list (floor 7 3))))
      (check (equal '(-2 -0.75d0) (multiple-value-list (truncate -2.75d0))))
      (dolist (operation '(floor ceiling truncate round))
        (check (handler-case (progn (funcall operation 7 0) nil)
                 (division-by-zero () t))))
      (check (= 3 3.0))
      (check (not (eql 3 3.0)))
      (check (string-equal "Ada" "ada"))
      (check (eq :true (if 0 :true :false)))
      (check (let ((x 5)) (let ((x 10) (y x)) (declare (ignore x)) (= y 5))))
      (check (let ((x 5)) (declare (ignorable x)) (let* ((x 10) (y x)) (= y 10))))
      (check (= 30 (let ((x 10) (y 20)) (+ x y))))
      (check (= 120 (let* ((x 10) (y (+ x 2))) (* x y))))
      (check (= 120 (let ((x 10)) (let ((y (+ x 2))) (* x y)))))
      (check (equal '((10 5) 5)
                    (let ((x 5))
                      (list (let ((x 10) (y x)) (list x y)) x))))
      (check (equal '((10 10) 5)
                    (let ((x 5))
                      (list (let* ((x 10) (y x)) (list x y)) x))))
      (check (equal '(10 5) (let ((x 5)) (list (let ((x 10)) x) x))))
      ;; Both forms evaluate initializers left to right, even though
      ;; LET does not make its new sibling bindings visible to them.
      (check (equal '(1 2 2)
                    (let ((count 0))
                      (let ((first (incf count)) (second (incf count)))
                        (list first second count)))))
      (check (equal '(1 2 2)
                    (let ((count 0))
                      (let* ((first (incf count)) (second (incf count)))
                        (list first second count)))))
      (check (equal '((1 99 3) (0 99 3))
                    (let* ((tail (list 2 3)) (a (cons 1 tail)) (b (cons 0 tail)))
                       (setf (first tail) 99)
                       (list a b))))
      (check (equal '((1 2 3) (0 2 3) (8 9))
                    (let* ((tail (list 2 3)) (a (cons 1 tail)) (b (cons 0 tail)))
                      (setf tail (list 8 9))
                      (list a b tail))))
      (check (let* ((a (list (list 1))) (b (copy-list a)))
               (setf (caar b) 2)
               (= 2 (caar a))))
      (check (= 10 (apply #'+ 1 2 '(3 4))))
      (check (equal '("Ada" 7)
                    (destructuring-bind (name (x y)) '("Ada" (3 4))
                      (list name (+ x y)))))
      (check (equalp #(2 3 4) (map 'vector #'1+ '(1 2 3))))
      (check (string= "bcd" (subseq "abcdef" 1 4)))
      (check (let ((table (make-hash-table :test #'equal)))
               (setf (gethash "Ada" table) nil)
               (equal '(nil t) (multiple-value-list (gethash "Ada" table)))))
      (run-later-lesson-tests #'check))
    (format t "Language smoke tests: ~D checks passed.~%" checks)))

(run-tests)
