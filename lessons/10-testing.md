# 10 — Tests and interactive debugging

**Goals:** automate meaningful tests and investigate failures in the REPL.
**Prerequisite:** 09. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 09](09-systems.md):

- Packages organize symbols and public exports; switching packages does not
  load a library or change the operating-system process.
- ASDF systems declare source components and dependencies. Loading an ASD and
  system explicitly avoids relying on personal registry or startup configuration.
- Compiling and loading are separate phases. A working REPL can retain definitions
  that are missing from saved source, so fresh-process checks still matter.

This lesson turns those reproducible loading steps into automated tests and uses
interactive debugging to investigate failures without hiding them.

## Tests are programs

For small labs, standard `assert` and a few helpers suffice:

```lisp
(assert (= 120 (factorial-iter 5)))
(assert (equal '(9 1) (positive-squares '(-2 0 3 1))))
(multiple-value-bind (value present-p) (safe-mean nil)
  (assert (null value))
  (assert (null present-p)))
```

These examples assume your earlier functions have been loaded: `factorial-iter`
and `safe-mean` are Lab 04 functions, and `positive-squares` is from Lab 06.
They are not built-ins. Use your implementations or load the reference solutions
and intentionally select their `COURSE-EXERCISES` package. `assert` signals
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

The [optional FiveAM module](../optional/QUICKLISP.md) makes that transition
concrete: named tests and suites wrap assertions, an ASDF test operation runs
them, and failed results produce a nonzero batch exit. It includes tests of the
unchanged capstone API. Keep your dependency-free tests as the core baseline.

## Design a test matrix

**Preview of error-handling syntax:** `handler-case` protects one form, followed
by clauses `(condition-type (condition-variable) handler-body...)`. In the
example above, `type-error` is a built-in condition type and `()` means the
handler does not need a condition variable. The clause returns `t` only for that
error type; normal completion returns the `nil` supplied by `progn`.
[Lesson 11](11-conditions.md#unwinding-handlers-versus-active-handlers) teaches
unwinding, handlers, and recovery in full.

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

`abs` computes absolute value; the expression compares the magnitude of the
difference, not its sign. `actual` and `expected` are placeholders for your
numbers. `1d-9` means 10^-9 as a double-float. It is an example tolerance, not a
universally appropriate threshold.

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

`describe` prints an object's descriptive information. `documentation` retrieves
documentation of the named kind: `'function` selects function documentation for
the symbol `'car`. `apropos` searches accessible names for a substring. `trace`
and `untrace` enable/disable call reporting for function names; `factorial` here
is the recursive example from Lesson 04, not the separate `factorial-iter` lab.

For deliberate debugging, compile development code with:

```lisp
(declaim (optimize (debug 3) (safety 3) (speed 0)))
```

Declarations affect compilation, so recompile relevant functions. More debug
information can preserve useful locals and frames; optimized code may not.

`declaim` establishes declarations globally for subsequent compilation.
`optimize` is a declaration specifying compiler priorities; `debug`, `safety`,
and `speed` are quality names, not calls or local variables. Levels range from
0 (least emphasis) to 3 (most); their effects are implementation-dependent.
[Lesson 14](14-performance.md#types-are-promises-not-conversions) explains local
`declare` forms and type declarations. No unsafe optimization is required here.

## A debugging procedure

1. Reproduce with the smallest input in a fresh process.
2. Read the condition type, message, and top relevant application frame.
3. Compare actual arguments with the function's contract.
4. Fix the definition in its source file, reload/recompile, and rerun.
5. Add a regression test and run the full suite.

Continuing a live image is a productivity tool, not proof that source is fixed.
Never rely on interactive corrections to make batch tests pass.

## Lab 10 — Test and repair

### Exercises

1. Add a test file and a `run-tests` function to `course-sequences`.
2. Configure an ASDF test system or test operation; the capstone supplies a pattern.
3. Add at least eight assertions, including empty input, tie ordering, and no mutation.
4. Introduce a deliberate error in `positive-squares`, inspect it, and record
   one useful backtrace. Confirm that the batch test run fails.
5. Repair the source and rerun the full suite in a fresh process.

### Acceptance checklist

- [ ] Exercise 1: the test entry point runs without interactive input.
- [ ] Exercise 2: the ASDF test operation invokes that entry point.
- [ ] Exercise 3: at least eight assertions cover the required cases.
- [ ] Exercise 4: the deliberate failure produces a nonzero process exit status,
  and your notes identify a useful application frame in the backtrace.
- [ ] Exercise 5: the repaired source passes in a fresh process.

### Review questions

1. Why does a function printing the expected number not prove it returns that number?
2. What makes an error-handling test accidentally pass?
