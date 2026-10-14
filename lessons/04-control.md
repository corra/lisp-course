# 04 — Decisions, iteration, and recursion

**Goals:** choose clear control forms, handle boundaries, and compare recursive
and iterative algorithms. **Prerequisite:** 03. **Time:** 4–6 hours.

## Branches produce values

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

## Iteration

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

## Exiting a region

`return-from` exits a named block. A `defun` implicitly establishes a block with
the function's name. Loops such as `dolist` also provide an implicit `nil` block,
so `(return value)` exits that loop, not every enclosing function.

```lisp
(defun first-negative (numbers)
  (dolist (n numbers nil)
    (when (minusp n)
      (return n))))
```

## Lab 04 — Numeric report

1. Write iterative `factorial-iter`, rejecting negative and non-integer input.
2. Write `sum-squares` for integers 1 through `n`, including `n = 0`.
3. Write `safe-mean` on a list of numbers: return mean and a true second value
   for nonempty input; return `nil, nil` for empty input. Do not divide by zero.
4. Complete milestone 1 in [the course guide](../COURSE.md).

**Pass:** factorial of 0 is 1; factorial of 5 is 120; sum-squares of 3 is 14;
mean of `(1 2 2)` is `5/3` with a true validity value; empty input is distinguishable.

**Checkpoint:** When does `return` exit only a loop? Why is tail recursion not
a portable substitute for iteration in Common Lisp?
