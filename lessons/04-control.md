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
  scope determines which ordinary variable binding a reference uses. Special
  variables instead use the dynamic binding active during execution.
- Functions retain access to surrounding lexical bindings. `flet` introduces
  local function names visible in its body; `labels` also makes all its new
  names visible inside every helper definition, allowing self- and sibling calls.
- A direct call such as `(helper n)` uses a function name. `#'helper` obtains
  that function's value; `funcall` calls a function value, including one stored
  in a variable. Obtaining a function is not the same as calling it.

This lesson uses those functions and bindings to choose branches, repeat work,
and express recursive computations. Keep counters and accumulators ordinary
lexical variables; no global `defparameter` or `defvar` definitions are needed
for the numeric APIs in this lesson.

## Working terminology and method

- A **branch** is an alternative path selected by a test.
- **Iteration** repeats work using a loop. An **accumulator** holds a result
  being built, such as a running total.
- **Recursion** is a function calling itself, directly or through other functions.
  A **base case** stops further recursive calls; a **recursive case** makes
  progress toward a base case.
- A **call stack** tracks active function calls and work waiting for their
  results. A **tail call** is a call whose result is returned without further
  computation by its caller. Tail-call optimization can avoid retaining that
  caller's stack frame, but Common Lisp does not require it.

Predict results before running examples. When asked to follow or trace
evaluation, write a step-by-step walkthrough by hand, then check it at the REPL.
No debugger tracing or stepping commands are required here. Basic error recovery
is in [Lesson 00](00-environment.md#5-getting-unstuck); tool-assisted tracing and
debugging are taught in [Lesson 10](10-testing.md).

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

The syntax of `if` is `(if test then-form else-form)`, with `else-form` optional.
It evaluates the test and then **only the selected branch**; an omitted false
branch returns `nil`. As in Lesson 02, only `nil` is false: zero and empty
strings are true. These control constructs do not evaluate all their operands
like an ordinary function call.

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

### Loop bindings and accumulator updates

The `let` in each total example creates an accumulator binding once. The loop
establishes its own variable binding (`i` or `n`); each `(incf total ...)` then
updates the existing accumulator. No global variable is involved. Putting
`(let ((total 0)) ...)` inside the repeated body would start a new total each
time rather than accumulate across iterations.

For the first example, write the running total as `0 → 0 → 1 → 3 → 6 → 10`
as `i` takes values 0 through 4. The final `total` result-form returns 10.
Without that result-form, this `dotimes` would return `nil` even though its
body still performs the updates. The same distinction applies to `dolist`.

`dotimes` evaluates its count form once; `dolist` evaluates its list form once.
Zero iterations still evaluate the result-form, so an initially zero total
can correctly represent an empty sum. These loop forms supply bindings and
control evaluation; they are not calls to functions named `i`, `n`, or `total`.

## Recursion

Factorial of nonnegative integer `n` is the product of integers 1 through `n`,
with factorial of zero defined as 1. Here is a direct recursive implementation:

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

The base case is `(zerop n)`, which returns 1 without another call. Otherwise,
the function calls itself with `(1- n)`, then multiplies that returned value by
its own `n`. Each call has its own parameter binding: `(1- n)` computes the next
argument; it does not assign to the caller's `n`. Validating nonnegative integer
input ensures that repeatedly subtracting one reaches zero.

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

To check invalid input now, enter `(factorial -1)` and `(factorial 1/2)`
**separately** at the REPL. Each is an intentional error, not an ordinary example
to include in an unattended script. For each, read the type error, choose the
offered `ABORT` restart that returns to top level (as taught in Lesson 00), then
confirm that `(factorial 3)` still returns 6. You do not need to implement custom
conditions or automatic expected-error tests yet; Lesson 10 teaches those tests.

### Recursive local helpers with `labels`

[Lesson 03](03-functions.md#labels-helpers-that-can-call-local-helpers) established
that `labels` makes local function names visible inside their own definitions.
Use that property to keep a recursive implementation helper out of the global API:

```lisp
(defun factorial-local (n)
  "Return the factorial of nonnegative integer N using a local helper."
  (check-type n (integer 0 *))
  (labels ((product-down (remaining)
             (if (zerop remaining)
                 1
                 (* remaining (product-down (1- remaining))))))
    (product-down n)))

(factorial-local 0) ; 1
(factorial-local 3) ; 6
```

`factorial-local` checks the public input once. Its helper receives a nonnegative
integer, stops at zero, and decreases it by one on each recursive call. The
helper's name is local; it is not a global function you can call at the REPL.
The initial `(product-down n)` and the recursive `(product-down ...)` both call
that local function by name. Neither needs `funcall` or `#'`: those would be
useful when passing or storing its function value, not for these direct calls.

Follow `(product-down 3)` by hand: it waits for `3 * (product-down 2)`, which
waits for `2 * (product-down 1)`, which waits for `1 * (product-down 0)`.
The base case returns 1; the pending multiplications then produce 1, 2, and 6.
This is a written walkthrough, not an instruction to use debugger commands.

Replacing `labels` with `flet` would make the helper's self-call refer outside
the new local definitions, not recurse into this local `product-down`.
Localizing the helper does not remove the stack-growth limitation discussed above.

### Mutual recursion: a small extension

Two helpers can call each other. This deliberately simple parity example is for
understanding scope and termination; use built-in `evenp`/`oddp` for real parity tests.

```lisp
(defun even-via-local-p (n)
  "Return true if nonnegative integer N is even, using mutual recursion."
  (check-type n (integer 0 *))
  (labels ((even-step-p (remaining)
             (if (zerop remaining)
                 t
                 (odd-step-p (1- remaining))))
           (odd-step-p (remaining)
             (if (zerop remaining)
                 nil
                 (even-step-p (1- remaining)))))
    (even-step-p n)))

(even-via-local-p 0) ; T
(even-via-local-p 3) ; NIL
(even-via-local-p 4) ; T
```

Every helper name is visible in both definitions, even though `odd-step-p` is
written second. Each call reduces the nonnegative argument until one base case
is reached: `even-step-p(3)` → `odd-step-p(2)` → `even-step-p(1)` →
`odd-step-p(0)` → `nil`. Each caller returns that result unchanged.
As with other recursion here, large inputs can exhaust the stack.

## Exiting a region

`return-from` exits a named block. A `defun` implicitly establishes a block with
the function's name. Loops such as `dolist` also provide an implicit `nil` block,
so `(return value)` inside a loop exits its nearest enclosing `nil` block, not
every enclosing function. These are **early exits**: ordinary completion still
returns the last form's values, without a mandatory `return` statement.

An explicit named region would use `(block name body...)`; `return-from` exits
that lexically enclosing region with a supplied result. `(return value)` is the
convenient spelling for `(return-from nil value)`. There is no need to add an
explicit `block` to `defun` or the loops that already provide one.

The syntax is `(return-from block-name result-form)` or `(return result-form)`;
the result-form can be omitted, giving `nil`. A block name is syntax, not a
variable to look up or quote. The target must be lexically enclosing and still
active; `return-from` is not a way to exit an unrelated caller by its function name.

```lisp
(defun first-negative (numbers)
  "Return the first negative number in NUMBERS, or NIL if none exists."
  (dolist (n numbers nil)
    (when (minusp n)
      (return n))))

(first-negative '(3 -2 -5)) ; -2
(first-negative '(1 2 3))  ; NIL
```

Here the loop's returned value is also the function's result because the loop is
its last form. To see the difference between exiting a loop and exiting a
function, compare:

```lisp
(defun loop-exit-demo ()
  (dolist (n '(1 -2 3))
    (when (minusp n)
      (return n)))
  :after-loop)

(defun function-exit-demo ()
  (dolist (n '(1 -2 3))
    (when (minusp n)
      (return-from function-exit-demo n)))
  :after-loop)

(loop-exit-demo)     ; :AFTER-LOOP
(function-exit-demo) ; -2
```

The first exit leaves the loop, then evaluates the next function-body form.
The second leaves the function's named block, so that next form is skipped.
Leaving a region also unwinds temporary special bindings established within it;
the previous bindings become active again. This restores bindings, not arbitrary
assignments or mutations performed before the exit.

## Lab 04 — Numeric report

For exercise 3, use `values` from [Lesson 02](02-values.md) to return the mean
and validity flag separately; write `(values nil nil)` for the empty case.
All functions below should return their results, not merely print them. Keep
accumulators and implementation helpers local. Define the public functions at
top level, save the source, and load it before calling them in a fresh session.

### Exercises

1. Write iterative `factorial-iter`, rejecting negative and non-integer input
   with `check-type`. Use a local accumulator initially equal to 1; explain
   why this initial value also handles zero iterations correctly.
2. Write `sum-squares` for nonnegative integer `n`, summing the squares of integers
   1 through `n`. Use `check-type` to reject negative and non-integer input.
   For `n = 0`, return 0 without processing any integers.
3. Write `safe-mean` on a list of numbers: return mean and a true second value
   for nonempty input; return `nil, nil` for empty input. Do not divide by zero.
4. Complete milestone 1 in [the course guide](../COURSE.md).
5. Write `sum-to-local` for nonnegative integers using a recursive `labels`
   helper to sum 1 through `n`. Check the public input with `check-type`.
   Identify the base case and decreasing argument; write a by-hand walkthrough
   for `n = 3`. Explain why changing `labels` to `flet` breaks the intended
   self-reference, and why large inputs favor iteration.
   Your walkthrough should record each helper argument, the base-case result,
   and the additions performed as the calls return. Do not attempt to call the
   local helper from the top-level REPL or use debugger tracing commands.

For invalid-input checks in exercises 1, 2, and 5, use the separate intentional
REPL-error procedure above. Keep those calls out of your normal script, and
record that each signals a type error. Automated expected-error tests come later.

### Acceptance checklist

- [ ] Exercise 1: factorial of 0 is 1 and factorial of 5 is 120; negative and
  non-integer inputs are rejected.
- [ ] Exercise 2: sum-squares of 3 is 14 and sum-squares of 0 is 0; negative
  and non-integer inputs are rejected.
- [ ] Exercise 3: mean of `(1 2 2)` is `5/3` with a true second value; empty
  input returns `nil, nil` without division by zero.
- [ ] Exercise 4: your numeric report meets milestone 1's requirements in the
  course guide, including a documented empty-input policy and two loop styles.
- [ ] Exercise 5: `sum-to-local` returns 0 for 0 and 6 for 3, rejects negative
  and non-integer input, and keeps its helper local. Your walkthrough explains
  termination, function-name visibility, and the stack limitation.

### Review questions

1. When does `return` exit only a loop?
2. Why is tail recursion not a portable substitute for iteration in Common Lisp?
3. How does `labels` allow a helper to call itself or a helper defined later?
   What guarantees termination in the two worked recursive examples?
4. In the loop examples, which forms create bindings and which update them?
   How does `(1- n)` in a recursive call differ from `(incf n -1)`?
5. Why can the first-negative example return a number without explicitly
   returning from the function? What changes if another form follows its loop?
