# 04 — Decisions, iteration, and recursion

**Goals:** choose clear control forms, handle boundaries, and compare recursive
and iterative algorithms. **Prerequisite:** 03. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 03](03-functions.md):

- `defun` defines a function with parameters and a body; the final body form
  supplies its normal returned values.
- `let` evaluates initializers before establishing its new bindings; `let*`
  makes each new binding available to later initializers. Both initialize left to right.
- `setf` and `incf` update places rather than introduce new bindings; lexical
  scope determines which binding a variable reference uses.

This lesson uses those functions and bindings to choose branches, repeat work,
and express recursive computations.

## Branches produce values

Numeric predicates used here are `minusp` (negative), `zerop` (zero), `plusp`
(positive), and `oddp`/`evenp` (odd/even integer). `1+` and `1-` return a number
plus/minus one without changing the argument's binding. Numeric comparisons
`<`, `>`, `<=`, and `>=` mean less/greater than, with or without equality;
`(<= 0 n 100)` checks both bounds. `sign-label` below is a function we define.

```lisp
(defun sign-label (n)
  (cond ((minusp n) :negative)
        ((zerop n) :zero)
        (t :positive)))
```

`if` chooses between one then-form and an optional else-form. Use `progn` when a
branch needs several forms. `when` and `unless` make one-sided tests readable.
`cond` tests clauses in order; the first true test wins. `case` selects among
literal keys using `eql`; `ecase` signals an error if no key matches. `and` and
`or` short-circuit and return operand values, not necessarily `t` or `nil`.

```lisp
(or nil 0 99)              ; 0
(and 1 2 3)                ; 3
(when (> 4 2) :yes)        ; :YES
```

### Several alternatives: `cond` versus nested `if`

Each `cond` clause has the shape `(test body-form...)`. It checks tests in order
and runs only the first successful clause, returning that body's last values.
A final `t` test is an always-true fallback. If no test succeeds it returns `nil`.
Unlike an `if` branch, a clause already accepts several body forms, so it does
not need an extra `progn`. A clause with no body returns its test's primary value.

The first example's body can also be written with nested `if` forms:

```lisp
(defun sign-label-with-if (n)
  (if (minusp n)
      :negative
      (if (zerop n) :zero :positive)))

(sign-label-with-if -3) ; :NEGATIVE
```

Use `if` for one two-way choice; `cond` often reads better for several ordered
choices. `case` instead evaluates one key form and matches literal clause keys
using `eql`: `(case 2 (1 "one") (2 "two") (otherwise "other"))` returns `"two"`.
`otherwise` names its fallback clause, not a variable. `ecase` has no fallback:
an unmatched key is an error. These are selection forms, not string comparisons.

`and` stops at the first false operand; otherwise it returns the last operand's
values. `or` stops at the first true operand, returning its primary value;
otherwise it returns `nil`. Short-circuiting means later operands may not run.

### One-sided tests: `when` and `unless`

Use `(when test body-form...)` when work should happen only if a test is true,
with no alternate action. It evaluates the test once, then either executes the
body forms in order and returns the last form's values, or skips the body and
returns `nil`. This is the form previewed in Lesson 01.

```lisp
(when (> 4 2)
  (format t "Continuing.~%")
  (+ 20 22)) ; prints Continuing. and returns 42

(when (> 2 4)
  (/ 1 0))   ; NIL; the body is not evaluated
```

For these examples, think of `when` as shorthand for an `if` whose true branch
is a `progn` and whose false branch is `nil`. It already groups its body, so
adding a surrounding `progn` inside that body is unnecessary.

`unless` reverses the test: `(unless test body-form...)` executes the body only
when the test is false. It also returns `nil` when its body is skipped.

```lisp
(unless (> 2 4)
  "The comparison was false.") ; "The comparison was false."
```

Choose `if` when both outcomes need an explicit result or action. Choose `when`
or `unless` when only one outcome needs work; clarity is the reason for these
forms, not different truth rules.

## Iteration

`dotimes` has syntax `(dotimes (variable count result-form) body...)`; the
variable counts from zero up to but excluding `count`. `dolist` has syntax
`(dolist (variable list-form result-form) body...)` and visits list elements.
Both return their optional `result-form` after ordinary completion, or `nil`
when it is omitted. The `total` after the count/list below is therefore the
loop's result expression, not an additional loop variable.

```lisp
(let ((total 0))
  (dotimes (i 5 total)      ; i takes 0,1,2,3,4
    (incf total i)))       ; 10

(let ((total 0))
  (dolist (n '(2 4 6) total)
    (incf total n)))       ; 12

(loop for n from 1 to 5
      when (oddp n)
        collect (* n n))   ; (1 9 25)
```

`dotimes` counts, `dolist` traverses a list, and extended `loop` offers expressive
iteration clauses such as `for`, `when`, `collect`, `sum`, and `finally`.
Prefer a short loop over an elaborate mini-language puzzle. `do` supplies explicit
initialization, stepping, and termination; recognize it when reading code.

In `loop`, `for n from 1 to 5` visits an inclusive numeric range; `when` is a
loop clause (not a separate call to the `when` macro), and `collect` accumulates
results into a list. These bare words belong to `loop`'s syntax, not to variable
lookup. [Lesson 06](06-sequences.md) uses `sum` for totals;
[Lesson 08](08-io.md) adds input/termination clauses, and
[Lesson 14](14-performance.md) explains vector iteration and typed accumulators.
`do` is recognition-only here; its full syntax is in the HyperSpec's `DO, DO*`
entry, reached through the [symbol index](https://www.lispworks.com/documentation/HyperSpec/Front/).

## Recursion

```lisp
(defun factorial (n)
  (check-type n (integer 0 *))
  (if (zerop n)
      1
      (* n (factorial (1- n)))))
```

A recursive function needs a base case and progress toward it. This version is
clear but consumes stack as `n` grows. Common Lisp does **not** guarantee tail-call
optimization. Do not depend on unlimited recursion even for a tail-recursive
function; use iteration for large linear traversals. Tree recursion will become
useful when structure naturally branches.

`check-type` checks a place against a type and signals a condition when invalid.
It can offer correction interactively; noninteractive tests should expect the
error rather than wait for human input.

In `(check-type n (integer 0 *))`, the type specification means integers from
zero upward, inclusive; `*` is an unbounded limit, **not multiplication** here.
`check-type` takes that type specification as syntax, so it is not quoted like
a type passed as an ordinary function argument. [Lesson 10](10-testing.md) shows
tests for the resulting built-in `type-error` condition; [Lesson 11](11-conditions.md)
explains condition handling.

## Exiting a region

`return-from` exits a named block. A `defun` implicitly establishes a block with
the function's name. Loops such as `dolist` also provide an implicit `nil` block,
so `(return value)` exits that loop, not every enclosing function.

An explicit named region would use `(block name body...)`; `return-from` exits
that lexically enclosing region with a supplied result. `(return value)` is the
convenient spelling for `(return-from nil value)`. There is no need to add an
explicit `block` to `defun` or the loops that already provide one.

```lisp
(defun first-negative (numbers)
  (dolist (n numbers nil)
    (when (minusp n)
      (return n))))
```

## Lab 04 — Numeric report

For exercise 3, use `values` from [Lesson 02](02-values.md) to return the mean
and validity flag separately; write `(values nil nil)` for the empty case.

### Exercises

1. Write iterative `factorial-iter`, rejecting negative and non-integer input.
2. Write `sum-squares` for integers 1 through `n`, including `n = 0`.
3. Write `safe-mean` on a list of numbers: return mean and a true second value
   for nonempty input; return `nil, nil` for empty input. Do not divide by zero.
4. Complete milestone 1 in [the course guide](../COURSE.md).

### Acceptance checklist

- [ ] Exercise 1: factorial of 0 is 1 and factorial of 5 is 120; negative and
  non-integer inputs are rejected.
- [ ] Exercise 2: sum-squares of 3 is 14 and sum-squares of 0 is 0.
- [ ] Exercise 3: mean of `(1 2 2)` is `5/3` with a true second value; empty
  input returns `nil, nil` without division by zero.
- [ ] Exercise 4: your numeric report meets milestone 1's requirements in the
  course guide, including a documented empty-input policy and two loop styles.

### Review questions

1. When does `return` exit only a loop?
2. Why is tail recursion not a portable substitute for iteration in Common Lisp?
