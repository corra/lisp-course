# 06 — Functions as values and sequence processing

**Goals:** pass functions as values, transform collections, and choose explicit
comparison policies. **Prerequisite:** 05. **Time:** 4–6 hours.

## Prerequisite recap

- Lists can share cells. Copying their spine does not copy nested objects.
- Do not mutate quoted literals; copy caller-owned data before destructive work.
- Functions have parameters and local working bindings. So far, most calls have
  named the function directly, as in `(+ 2 3)`.

**Learn in three passes:** first call and pass function values; then build a
small map/filter/sum pipeline; finally handle sorting and ownership. Closures
and local named helpers build on the first pass. The argument-list reference
and nested visibility comparison can wait until the main examples are comfortable.
No knowledge of Lesson 03's optional closure exercise is assumed.

## Calling a function value

`#'name` obtains the function named `name`. It does not call that function.
`funcall` calls a function value with arguments supplied individually:

```lisp
(funcall #'+ 2 3) ; 5

(let ((operation #'+))
  (funcall operation 2 3)) ; 5
```

### Function values versus local function names

Common Lisp has separate variable and function namespaces. A variable named
`operation` is not a function definition named `operation`. Thus
`(operation 2 3)` would not call the function stored in that variable.
Use `(funcall operation 2 3)`. `#'name` is shorthand for `(function name)`;
it obtains a function through its function name, not a variable's value.

`lambda` creates an anonymous function with syntax `(lambda (parameters...) body...)`:

```lisp
(let ((square (lambda (n) (* n n))))
  (funcall square 4)) ; 16
```

There is no need for `eval` or constructing source code to call a function value.

## Transform, filter, and sum — one step at a time

`mapcar` calls a function on each list element and collects the returned values:

```lisp
(mapcar (lambda (n) (* n n)) '(1 2 3)) ; (1 4 9)
```

`remove-if-not` keeps elements for which its predicate returns true. `plusp`
tests for a positive number. `reduce` combines values with a supplied function:

```lisp
(remove-if-not #'plusp '(-2 0 3 1)) ; (3 1)
(reduce #'+ '(9 1) :initial-value 0) ; 10
(reduce #'+ nil :initial-value 0)    ; 0
```

### A small transformation pipeline

```lisp
(defun sum-positive-squares (numbers)
  "Return the sum of squares of positive NUMBERS without changing the input."
  (reduce #'+
          (mapcar (lambda (n) (* n n))
                  (remove-if-not #'plusp numbers))
          :initial-value 0))

(sum-positive-squares '(-2 0 3 1)) ; 10
```

Read the inner computation first: filter to `(3 1)`, square to `(9 1)`, then
sum to 10. `:initial-value 0` makes the empty sum explicit. This is one way to
express the computation, not a requirement to nest everything:

```lisp
(loop for n in '(-2 0 3 1)
      when (plusp n)
        sum (* n n)) ; 10
```

`in` traverses a list; `sum` accumulates a numeric result, defaulting to zero.
The pipeline allocates intermediate lists; the loop can avoid them. Choose
clarity first. Measurement and optimization belong in Lesson 14.

## Sequence operations: a lookup menu

A **sequence** is a proper list or vector; strings are vectors of characters.
Use this table to find an operation, not as a memorization assignment:

| Need | Functions |
|---|---|
| Size or indexed element | `length`, `elt` |
| Portion of a sequence | `subseq` (start inclusive, end exclusive) |
| Matching element, index, or number of matches | `find`, `position`, `count` |
| Omit a value or elements satisfying a predicate | `remove`, `remove-if` |
| Test all elements or find a true predicate result | `every`, `some` |

Many operations accept `:key` (extract what to compare) and `:test` (how to
compare it). For example, compare a name with each pair's first part:

```lisp
(find "ada" '(("bob" . 3) ("ada" . 5))
      :key #'car :test #'string=) ; ("ada" . 5)
(subseq "abcdef" 1 4)           ; "bcd"
(some #'evenp '(1 3 4))         ; true
```

`find` returns an element or `nil`, so it cannot distinguish a found `nil` from
absence by that value alone. `position` returns an index or `nil`; index 0 is
true in Lisp. Lesson 07 develops a similar presence issue for hash tables.

## Sorting and ownership

```lisp
(let ((names (list "Grace" "Ada" "Linus")))
  (sort (copy-list names) #'string<)) ; ("Ada" "Grace" "Linus")
```

`string<` supplies alphabetical ordering; `string=` tests equality. `sort` may
mutate its sequence, so copy caller-owned input and use the returned value.
The comparison must mean strict precedence, not `<=`. `stable-sort` additionally
preserves the relative order of ties.

For Lab 06, a **projection function** extracts or computes a quantity to use,
such as `#'cdr` for the score in `("Ada" . 5)`. `identity` returns its argument
unchanged, useful when an API expects a projection but no transformation is needed.

## Closures: keeping private state

Now return to Lesson 03's guided counter example:

```lisp
(defun make-counter (&key (start 0))
  (let ((count start))
    (lambda () (incf count))))

(let ((next (make-counter :start 10)))
  (list (funcall next) (funcall next))) ; (11 12)
```

The `let` runs once when a counter is created; the `lambda` body runs each time
the returned function is called. The empty `()` means no arguments. The function
retains access to its lexical `count` binding after `make-counter` returns:
that is a **closure**. It retains a binding, not a frozen initial value.
Separate calls to `make-counter` create independent counters. Putting the `let`
inside `lambda` would initialize a new count on every call instead.

## Local named functions

### `flet`: local named helpers

Use `flet` for a helper that belongs to one computation, not the global API:

```lisp
(let ((offset 10))
  (flet ((add-offset (number)
           (+ number offset)))
    (list (add-offset 3)
          (funcall #'add-offset 5)))) ; (13 15)
```

The syntax is `(flet ((name (parameters...) helper-body...) ...) body...)`.
The helper entry defines a function; it is not a call and needs no `defun`.
The outer body can use the function name directly or obtain its function value
with `#'`. The helper sees the surrounding lexical `offset` binding.

### `labels`: helpers that can call local helpers

Recall Lesson 04's recursive helper: `labels` has the same shape as `flet`, but
all new function names are visible inside all their definitions too:

```lisp
(labels ((add-two (number) (add-one (add-one number)))
         (add-one (number) (+ number 1)))
  (add-two 5)) ; 7
```

With `flet`, these new names are visible only in its outer body; references
inside helper definitions use enclosing or global function bindings instead.
Definition order does not change either rule. Use `labels` for helpers that call
one another or themselves; it need not be recursive.

### Later scope practice: a direct comparison

**Optional on the first pass.** Lab 06.7 starts from this comparison:

```lisp
(flet ((adjust (number) (+ number 100)))
  (flet ((adjust (number) (+ number 1))
         (use-adjust (number) (adjust number)))
    (list (adjust 5) (use-adjust 5)))) ; (6 105)

(flet ((adjust (number) (+ number 100)))
  (labels ((adjust (number) (+ number 1))
           (use-adjust (number) (adjust number)))
    (list (adjust 5) (use-adjust 5)))) ; (6 6)
```

Both inner bodies call the inner `adjust`. Only `labels` makes that new binding
visible inside `use-adjust` too. `flet`'s definition sees the enclosing `adjust`.
This is about function-name visibility, not changing a variable's value.

## More argument-list options

**Reference when needed; not additional Lab 06 requirements.** `&optional`
provides positional defaults; `&rest` collects remaining arguments into a list:

```lisp
(defun supplied-demo (&optional (value 10 supplied-p))
  (list value supplied-p))

(supplied-demo)     ; (10 NIL)
(supplied-demo nil) ; (NIL T)

(defun collect-items (&rest items)
  items)

(collect-items 1 2 3) ; (1 2 3)
```

The optional supplied-p parameter distinguishes omission from an explicit value.
Avoid mixing `&optional` and `&key` in beginner APIs: positional consumption can
be surprising. Do not mutate quoted list defaults.

`apply` calls a function using a final list of arguments:

```lisp
(apply #'+ '(2 3 4))   ; 9
(apply #'+ 1 2 '(3 4)) ; 10
```

Do not pass an unbounded dataset as arguments: implementations have argument-count
limits. Use a loop or `reduce` for large aggregations. Other mapping variants
(`map`, `mapc`, mapping multiple lists) can wait until an actual task needs them;
their contracts are in the HyperSpec.

## Lab 06 — Data pipeline

Complete exercises 1–2 before combining filtering and sorting. Then take 3–4.
Exercise 5 revisits Lab 03's guided closure work with the necessary background
now taught. Exercises 6–7 practise local functions; they are not needed to
implement this lesson's collection APIs.

### Exercises

1. Write `positive-squares`, preserving input order and leaving input unchanged.
2. Write `total-by` taking a projection function and a list, returning the sum
   of projected values. Return 0 for an empty list. Call the projection with
   `funcall`; test `#'cdr` on an alist and `#'identity` on plain numbers.
3. Write `sorted-scores`: sort an alist of string names and scores by descending
   score, with ascending string names for ties, without mutating the input.
4. Write both a pipeline and a one-pass loop for positive-square totals; check
   equivalent behavior. No benchmark or allocation measurement is required yet.
5. Complete or revisit Lab 03.5: `make-stepper` has keyword `start` and `step`,
   returns a private stateful function, and separate steppers advance independently.
   Use start 10 and step 3 to obtain 13 then 16 from successive calls.
6. **Local-function practice:** bind `offset` to 20 with `let` and define
   `add-offset` with `flet`. Return a list of `(add-offset 2)` and
   `(funcall #'add-offset 5)`, expecting `(22 25)`. Inside the `flet`, separately
   bind `helper` to `#'add-offset` and evaluate `(funcall helper 5)`, expecting 25.
   Explain function-name lookup versus a variable containing a function;
   `(helper 5)` would not call that variable's value. Neither call changes `offset`.
7. **Local-function practice:** work through the `flet`/`labels` visibility
   comparison above. Then define local `triple` and `triple-plus-one` helpers
   with `labels`; the latter calls the former. A call with 4 returns 13.

### Acceptance checklist

- [ ] Exercise 1: `(-2 0 3 1)` produces `(9 1)` in order without mutation.
- [ ] Exercise 2: projected values sum correctly; empty input returns 0.
- [ ] Exercise 3: scores sort descending, names break ties ascending, and the
  caller's original order remains intact.
- [ ] Exercise 4: the pipeline and one-pass loop return equivalent totals.
- [ ] Exercise 5: one stepper returns 13 then 16 for start 10, step 3; advancing
  it does not advance a second stepper. Explain when the counter is initialized.
- [ ] Exercise 6: both calls return `(22 25)`, `(funcall helper 5)` returns 25,
  and you explain why `(helper 5)` is a different, undefined function call.
- [ ] Exercise 7: you explain both comparison results, `(6 105)` and `(6 6)`, and
  the `labels` helpers return 13 for 4.

### Review questions

1. How do obtaining a function with `#'` and calling it with `funcall` differ?
2. When should a helper use `labels` rather than `flet`?
3. Does functional-looking code guarantee that no mutation occurs?
