(in-package #:course-extras)

(defun word-count-report (words)
  "Count case-normalized string WORDS; return (word . count) pairs.
Sort by descending count, then ascending word. Do not mutate or retain input
strings. Input is already tokenized; punctuation and Unicode normalization
policies are outside this exercise."
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (word words)
      (check-type word string)
      (let ((key (string-downcase (copy-seq word))))
        (incf (gethash key counts 0))))
    ;; Alexandria collects fresh pairs; hash iteration order is unspecified,
    ;; so presentation order still needs an explicit sorting policy.
    (sort (alexandria:hash-table-alist counts)
          (lambda (left right)
            (or (> (cdr left) (cdr right))
                (and (= (cdr left) (cdr right))
                     (string< (car left) (car right))))))))
