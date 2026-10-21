# 04 — Decisions, iteration, and recursion

**Goals:** choose branches, accumulate loop results, and follow a small recursive
function. **Prerequisite:** 03 core path. **Time:** 4–6 hours, plus milestone work.

## Prerequisite recap

- `defun` defines a function; its last body form supplies its ordinary result.
- `let` creates local bindings; `let*` allows dependent initializers.
- `setf` and `incf` update places. Local working state needs no global definition.
- Only `nil` is false. `if` selects one branch; `progn` groups several forms.

**Learn in order:** branches, then loops, then recursion. Pause to write a small
example after each section. Start with Lab 04.1–3; the milestone is a separate
integration session. Local recursive helpers are a guided second pass; mutual
recursion and the extra control forms are optional recognition material.
No closure or explicit special-declaration knowledge is assumed.

## Branches produce values

The syntax is `(if test then-form else-form)`, with the else-form optional.
Only the selected branch is evaluated, and its values are returned:

```lisp
(if (> 4 2) :larger :not-larger) ; :LARGER
(if (> 2 4) :larger)            ; NIL
```

`if` is useful when choosing between results. `when` is useful for conditional
work without an alternative action; both return values.

### One-sided tests: `when` and `unless`

`(when test body-form...)` executes its body only when the test is true.
It accepts several body forms without `progn`, returning the last form's values,
or `nil` if the test is false (or the body is empty).

```lisp
(when (> 4 2)
  (format t "Continuing.~%")
  (+ 20 22)) ; prints Continuing. and returns 42
```

`format t` prints; `~%` emits a newline. The equivalent `if` needs a `progn`
around the printing and addition. Choose `when` for readability, not speed.
`unless` reverses the test: its body runs only when the test is false.

### Several alternatives: `cond` versus nested `if`

`cond` tries clauses `(test body-form...)` in order and executes only the first
successful one. A final `t` is an always-true fallback; no match returns `nil`.

`minusp` tests for a negative number; `zerop` for zero; `plusp` for a positive one.
`oddp` and `evenp` test integer parity. Numeric comparisons `<`, `>`, `<=`, and
`>=` mean less/greater than, without/with equality; `(<= 0 n 100)` checks both
inclusive bounds. Use the operations you need rather than memorizing a table.

```lisp
(defun sign-label (n)
  "Return a keyword describing the sign of N."
  (cond ((minusp n) :negative)
        ((zerop n) :zero)
        (t :positive)))

(sign-label -3) ; :NEGATIVE
(sign-label 0)  ; :ZERO
```

Use `if` for two outcomes and `cond` for several ordered alternatives. Each
`cond` body already groups forms and returns its last result.

### Combining tests: `and` and `or`

`and` stops when an operand is false; `or` stops when an operand is true.
Both evaluate from left to right, and later operands may never be evaluated.
An earlier false operand makes `and` return `nil`; an earlier true operand
makes `or` return only its primary value. If evaluation reaches the final form,
both return **all** of that form's values, even if its primary value is `nil`.

```lisp
(and (integerp 5) (> 5 0)) ; T
(or nil 0 99)             ; 0: zero is true, so 99 is not evaluated
```

For later multiple-value use, compare:

```lisp
(multiple-value-list (or nil (values 1 2)))        ; (1 2)
(multiple-value-list (and t (values nil :extra))) ; (NIL :EXTRA)
```

**Checkpoint:** predict a positive, zero, and negative call to `sign-label`.
Then write a `when` that prints only for a positive input. No new tool is needed.

## Iteration

**Iteration** repeats work in a loop. An **accumulator** holds a result being
built, such as a running total.

### Count repetitions with `dotimes`

The shape is `(dotimes (variable count result-form) body...)`; result-form is
optional. The variable runs from zero up to but excluding count:

```lisp
(let ((total 0))
  (dotimes (i 5 total)
    (incf total i))) ; 10: add 0, 1, 2, 3, 4
```

The `let` creates `total` once. The loop establishes `i`; each `incf` updates
the existing total. The final `total` in the loop header is its returned result,
not another loop variable. Omitting it makes ordinary completion return `nil`.
Zero iterations still return that result-form: an initially zero sum stays zero.

### Visit list elements with `dolist`

```lisp
(let ((total 0))
  (dolist (n '(2 4 6) total)
    (incf total n))) ; 12
```

The shape is `(dolist (variable list-form result-form) body...)`. Each element
becomes the loop variable's value. Count/list forms are evaluated once; bodies
repeat. Initializing `total` inside the repeated body would reset it each time.

### A small `loop` vocabulary

`loop` has an extended syntax whose bare words are clauses, not function calls:

```lisp
(loop for n in '(2 4 6) sum n) ; 12
(loop for n from 1 to 5 collect (* n n)) ; (1 4 9 16 25)
```

`in` visits a list; `from ... to ...` includes both numeric endpoints. `sum`
returns a numeric total (zero for no items); `collect` returns a list. These
clauses are sufficient here. Lesson 06 adds filtering, Lesson 08 adds input
termination, and Lesson 14 has optional typed accumulators.

**Checkpoint:** write the total after each iteration of the `dotimes` loop above:
`0 → 0 → 1 → 3 → 6 → 10`. Then test zero iterations. This is a written
walkthrough, not a debugger trace. Complete Lab 04.1–3 before adding recursion.
Read the short validation recipe below first; you can use `check-type` without
implementing the recursive factorial.

## Recursion

A **recursive** function calls itself. It needs a **base case** that stops
calling and a recursive case that makes progress toward it. Factorial is the
product of integers 1 through `n`, with factorial of zero defined as 1.

First, one validation tool: `(check-type n (integer 0 *))` requires an integer
from zero upward. The type specification is syntax, not a quoted argument;
`*` means no upper limit. Invalid input signals a `type-error`.
`1-` returns one less than its argument without changing the binding (`1+`
similarly returns one more). It is not assignment.

```lisp
(defun factorial (n)
  "Return the factorial of nonnegative integer N."
  (check-type n (integer 0 *))
  (if (zerop n)
      1
      (* n (factorial (1- n)))))

(factorial 0) ; 1
(factorial 3) ; 6
```

For 3, the pending calculation is `3 * (2 * (1 * 1))`. Each call has its own
`n` binding; passing `(1- n)` does not decrement the caller's `n`. Zero stops
the recursion. Nonnegative integer validation ensures that subtracting one
eventually reaches that base case.

The **call stack** tracks active calls and work waiting for their results.
Here multiplications wait for recursive results, so stack use grows with input.
Use iteration for large linear traversals. Even a **tail call** (a call whose
result is returned with no further computation) is not guaranteed to avoid
stack growth in Common Lisp. No compiler optimization knowledge is required.

### Checking intentional errors

For Lab 04's integer APIs, copy the `check-type` pattern above. To check invalid
input now, enter `(factorial -1)` and `(factorial 1/2)` **separately** at the REPL.
Each should report a type error. Choose the offered `ABORT` restart returning
to top level as in [Lesson 00](00-environment.md#5-getting-unstuck), then confirm
`(factorial 3)` still returns 6. Keep intentional failures out of normal scripts.
Lesson 10 teaches automated expected-error tests; no handlers are required yet.

### Recursive local helpers with `labels`

**Guided second pass:** localize an implementation helper after the global
recursive example is clear. You do not need this to write the iterative APIs.

`labels` introduces local function names with this shape:
`(labels ((name (parameters...) helper-body...) ...) body...)`.
The helper entry defines a function, not a call. Its name is visible in its own
definition, in sibling definitions, and in the outer body:

```lisp
(defun factorial-local (n)
  "Return the factorial of nonnegative integer N using a local helper."
  (check-type n (integer 0 *))
  (labels ((product-down (remaining)
             (if (zerop remaining)
                 1
                 (* remaining (product-down (1- remaining))))))
    (product-down n)))

(factorial-local 3) ; 6
```

Validation occurs once at the public boundary. `product-down` has a local
function name, not a variable containing a function, so call it directly.
It is not installed as a global function to call at the REPL. This changes
organization, not the algorithm's stack-growth behavior. Lesson 06 teaches
function values, `flet`, and a fuller comparison of local function-name scope.

## Exiting a region

Ordinary function completion returns the last form's values; explicit exits
are only needed to leave early. `(return result-form)` exits the nearest
lexically enclosing block named `nil`, such as the one provided by `dolist`:

```lisp
(defun first-negative (numbers)
  "Return the first negative number in NUMBERS, or NIL if none exists."
  (dolist (n numbers nil)
    (when (minusp n)
      (return n))))

(first-negative '(3 -2 -5)) ; -2
(first-negative '(1 2 3))  ; NIL
```

Here the loop is the function's last form, so its returned value also becomes
the function result. If another form followed the loop, that form would run.
To leave the function itself early, use `(return-from function-name result-form)`:
`defun` provides an implicit block with that function's name. A block name is
syntax, not a variable or quoted argument. The target must lexically enclose
the exit and still be active; it is not a way to exit an unrelated caller.

## Later recognition: additional control forms

**Skip on the first pass.** You can complete this lab without these forms:

- `case` matches a key against literal clause keys using `eql`:
  `(case 2 (1 "one") (2 "two") (otherwise "other"))` returns `"two"`.
  `ecase` signals an error when no key matches.
- `do` specifies explicit loop initialization, stepping, and termination.
- `(block name body...)` creates an explicit named region for `return-from`.
- Mutually recursive `labels` helpers call each other. Each call must still
  progress toward a base case. Learn this when a real algorithm needs it,
  rather than implementing parity tests that built-in `evenp`/`oddp` already solve.

The HyperSpec is the syntax reference when you encounter these. They are not
additional acceptance requirements for this lesson.

## Lab 04 — Numeric report

Return values, not just printed output. For exercise 3, use Lesson 02's `values`
to return two values; `nil, nil` below means `(values nil nil)`, not a list.
For exercises 1–2 use `(check-type n (integer 0 *))` and local accumulators.

### Exercises

1. Write iterative `factorial-iter`, rejecting negative and non-integer input.
   Initialize the accumulator to 1 so zero iterations produce the correct result.
2. Write `sum-squares` for nonnegative integer `n`, summing squares of integers
   1 through `n`. Return 0 for zero; reject negative and non-integer input.
3. Write `safe-mean` on a list of numbers: return mean and a true second value
   for nonempty input; return `nil, nil` for empty input. Do not divide by zero.
   Use local count and total accumulators; no list-access functions are needed.
4. **Separate integration session:** complete milestone 1 in the course guide.
   Reuse your accumulator patterns; start with one loop style, then a second.
5. **Guided second pass:** write `sum-to-local` using a recursive `labels`
   helper to sum 1 through nonnegative integer `n`. Validate the public input.
   For `n = 3`, write each helper argument, base-case result, and pending addition.
   Explain why large inputs favor iteration. Do this after the direct recursive
   example, or revisit alongside Lesson 06; it does not block Lesson 05.

### Acceptance checklist

- [ ] Exercise 1: factorial of 0 is 1 and factorial of 5 is 120; negative and
  non-integer inputs signal type errors.
- [ ] Exercise 2: sum-squares of 3 is 14 and of 0 is 0; invalid inputs are rejected.
- [ ] Exercise 3: `(1 2 2)` gives `5/3` and a true second value; empty input
  gives `nil, nil`. Use `multiple-value-list` to examine both results.
- [ ] Exercise 4: milestone 1 has a documented empty-input policy and two loop styles.
- [ ] Second-pass 5: sums for 0 and 3 are 0 and 6; invalid inputs are rejected.
  The helper stays local and your walkthrough explains termination and stack use.

### Review questions

1. What do `if` and `when` return? Why choose one over the other?
2. Which loop forms create bindings, and which forms update an accumulator?
3. What stops the recursive factorial? Why does `(1- n)` not change its caller's `n`?
4. When does `return` leave only a loop rather than the enclosing function?
