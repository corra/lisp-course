# 10 — Tests and interactive debugging

**Goals:** automate meaningful tests and investigate failures in the REPL.
**Prerequisite:** 09. **Time:** 4–6 hours.

## Tests are programs

For small labs, standard `assert` and a few helpers suffice:

```lisp
(assert (= 120 (factorial-iter 5)))
(assert (equal '(9 1) (positive-squares '(-2 0 3 1))))
(multiple-value-bind (value present-p) (safe-mean nil)
  (assert (null value))
  (assert (null present-p)))
```

These examples assume your earlier functions have been loaded. `assert` signals
an error if its test fails; at a REPL SBCL may offer interactive restarts. In a
script failure should produce a nonzero exit status, not wait for a person.
The included test scripts use SBCL's script mode for that reason.

Check expected errors specifically, rather than accepting any failure:

```lisp
(assert
 (handler-case
     (progn (factorial-iter -1) nil)
   (type-error () t)))
```

If no error occurs the `progn` returns `nil` and the assertion fails. Catching
the broad `error` type here could wrongly count an unrelated bug as success.
Use a test framework later if you need richer reporting; it is not required now.

## Design a test matrix

For each function include:

- Typical input, minimal input, empty input if allowed, and a larger case.
- Invalid type and invalid value where the API promises validation.
- Return-value checks, not merely printed output.
- Multiple-value checks when absence/presence matters.
- Invariants: inputs remain unchanged, output ordering is deterministic.
- A regression test for every fixed bug.

For floating-point results, compare an error tolerance such as
`(< (abs (- actual expected)) 1d-9)` when that tolerance fits your problem.
For sort tests, test both order and preservation of the expected elements.

## Inspect rather than guess

At the REPL, useful tools include:

```lisp
(describe '(a b c))
(documentation 'car 'function)
(apropos "HASH")
(trace factorial)
(factorial 4)
(untrace factorial)
```

Tracing prints calls/results and can change timing; untrace before measuring.
`inspect` provides an interactive object inspector, with commands documented by
your implementation. SBCL's debugger has help, backtrace, and frame-navigation
commands; use `help` and `backtrace` in the debugger, not as Lisp function calls.
Exact debugger presentation depends on SBCL version and debug settings.

For deliberate debugging, compile development code with:

```lisp
(declaim (optimize (debug 3) (safety 3) (speed 0)))
```

Declarations affect compilation, so recompile relevant functions. More debug
information can preserve useful locals and frames; optimized code may not.

## A debugging procedure

1. Reproduce with the smallest input in a fresh process.
2. Read the condition type, message, and top relevant application frame.
3. Compare actual arguments with the function's contract.
4. Fix the definition in its source file, reload/recompile, and rerun.
5. Add a regression test and run the full suite.

Continuing a live image is a productivity tool, not proof that source is fixed.
Never rely on interactive corrections to make batch tests pass.

## Lab 10 — Test and repair

Add a test file to `course-sequences` and a `run-tests` function. Configure an ASDF
test system or test operation (the capstone supplies a complete pattern). Add at
least eight assertions, including empty input, tie ordering, and no mutation.
Introduce and then repair a deliberate error in `positive-squares`.

**Pass:** tests run noninteractively, a deliberate failure exits unsuccessfully,
and the repaired source passes in a new process. Record one useful backtrace.

**Checkpoint:** Why does a function printing the expected number not prove it
returns that number? What makes an error-handling test accidentally pass?
