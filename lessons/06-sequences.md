# 06 — Functions as values and sequence processing

**Goals:** use higher-order functions, closures, sequences, and explicit
comparison policies. **Prerequisite:** 05. **Time:** 4–6 hours.

## Calling a function value

```lisp
(funcall #'+ 2 3)           ; 5
(apply #'+ '(2 3 4))        ; 9
(apply #'+ 1 2 '(3 4))      ; 10
(mapcar (lambda (n) (* n n)) '(1 2 3)) ; (1 4 9)
```

`funcall` supplies arguments individually. `apply` takes zero or more leading
arguments and a final list whose elements become trailing arguments. Do not use
`apply` to pass an unbounded dataset as arguments; implementations have argument
count limits. Use `reduce` or a loop for large aggregations.

`mapcar` processes lists and returns a list. `map` handles sequences and takes an
explicit result type: `(map 'vector #'1+ '(1 2 3))` returns `#(2 3 4)`.
Mapping several sequences stops at the shortest. `mapc` is for side effects and
returns its first list argument, not a list of results.

## A small transformation pipeline

```lisp
(defun sum-positive-squares (numbers)
  (reduce #'+
          (mapcar (lambda (n) (* n n))
                  (remove-if-not #'plusp numbers))
          :initial-value 0))
```

This reads as filter, transform, aggregate. It allocates intermediate lists.
A single `loop` may be clearer or more memory-efficient; neither style is
automatically superior. `reduce` on an empty sequence without an initial value
has function-dependent behavior; specify the identity when appropriate.

Common sequence functions include `length`, `elt`, `subseq`, `find`, `position`,
`count`, `remove`, `remove-if`, `every`, `some`, `sort`, and `stable-sort`.
Many accept `:key`, `:test`, or `:start`/`:end`. End indices are exclusive.

```lisp
(find "ada" '(("bob" . 3) ("ada" . 5))
      :key #'car :test #'string=) ; ("ada" . 5)
(subseq "abcdef" 1 4)            ; "bcd"
(some #'evenp '(1 3 4))          ; true
```

`find` returns the matching element, so a found `nil` is indistinguishable from
absence using that value alone. `position` returns an index or `nil`; index 0 is
true in Lisp. Choose a representation that does not lose necessary information.

## Sorting and ownership

```lisp
(let ((names (list "Grace" "Ada" "Linus")))
  (sort (copy-list names) #'string<)) ; ("Ada" "Grace" "Linus")
```

`sort` and `stable-sort` may mutate the supplied sequence. Use their return value
and copy first if you do not own the input. A sorting predicate must describe
strict precedence, not `<=`. `stable-sort` preserves the relative order of ties.

## Lab 06 — Data pipeline

1. Write `positive-squares`, preserving input order and leaving the input unchanged.
2. Write `total-by` taking a projection function and a list, returning the sum
   of projected values. Return 0 for an empty list.
3. Sort an alist of string names and scores by descending score, with ascending
   string names for ties, without mutating the input.
4. Write both a pipeline and a one-pass loop for positive-square totals; test
   equivalent behavior before discussing allocation.

**Pass:** `(-2 0 3 1)` produces `(9 1)`; empty totals return 0; ties are deterministic;
the caller's original list order is intact.

**Checkpoint:** Why is `#'` clearer than quote when referring to a function? How
does `apply` differ from passing one list argument? Does functional-looking code
guarantee that no mutation occurs?
