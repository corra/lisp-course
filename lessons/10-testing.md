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

**Order of work:** get one assertion passing, build a small test file, then
make it run through ASDF. Only then deliberately break a function and inspect
the debugger. The expected-error pattern below is a recipe for tests; full
handler semantics belong to Lesson 11. Compiler tuning is optional follow-up.

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

**Preview of error-handling syntax:** `handler-case` protects one form, followed
by clauses `(condition-type (condition-variable) handler-body...)`. In the
example above, `type-error` is a built-in condition type and `()` means the
handler does not need a condition variable. The clause returns `t` only for that
error type; normal completion returns the `nil` supplied by `progn`.
[Lesson 11](11-conditions.md#unwinding-handlers-versus-active-handlers) teaches
unwinding, handlers, and recovery in full.

The [optional FiveAM module](../optional/QUICKLISP.md) makes that transition
concrete: named tests and suites wrap assertions, an ASDF test operation runs
them, and failed results produce a nonzero batch exit. It includes tests of the
unchanged capstone API. Keep your dependency-free tests as the core baseline.

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
```

For the tracing example, first evaluate this recursive definition in your
**current package**, then run the tracing calls below it. This setup is needed
even if you loaded the reference exercise solutions: that file defines
`factorial-iter`, not the recursive `factorial` from Lesson 04.

```lisp
(defun factorial (n)
  "Return the factorial of nonnegative integer N."
  (check-type n (integer 0 *))
  (if (zerop n)
      1
      (* n (factorial (1- n)))))

(trace factorial)
(factorial 4) ; prints a call/return trace and returns 24
(untrace factorial)
```

Tracing prints calls/results and can change timing; untrace before measuring.
`inspect` provides an interactive object inspector, with commands documented by
your implementation.

`describe` prints an object's descriptive information. `documentation` retrieves
documentation of the named kind: `'function` selects function documentation for
the symbol `'car`. `apropos` searches accessible names for a substring. `trace`
and `untrace` enable/disable call reporting for function names; `factorial` here
is the recursive example from Lesson 04, not the separate `factorial-iter` lab.

**Optional follow-up if locals/frames are missing:** compile development code with:

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

## Read a backtrace in the SBCL debugger

Save this deliberately fragile file as `work/buggy.lisp`. `mean-score` promises
a list of numbers, but nothing checks that promise:

```lisp
(defun mean-score (scores)
  "Return the mean of SCORES, a nonempty list of numbers."
  (/ (reduce #'+ scores) (length scores)))

(defun report-mean (scores)
  (format nil "Mean: ~A" (mean-score scores)))
```

Load it in a fresh REPL and call `(report-mean (list 90 "85" 70))`. SBCL stops
in the debugger (this transcript is from SBCL 2.6.9; addresses and thread names vary):

```text
debugger invoked on a TYPE-ERROR ...:
  The value
    "85"
  is not of type
    NUMBER

restarts (invokable by number or by possibly-abbreviated name):
  0: [ABORT] Exit debugger, returning to top level.

(SB-KERNEL:TWO-ARG-+ 90 "85")
0]
```

The `0]` prompt means you are in the debugger, looking at frame 0. Debugger
commands are typed at this prompt; they are not Lisp function calls. A Lisp
form typed here is still evaluated, but use the commands below to inspect frames.

| Command | Effect |
|---|---|
| `help` | List debugger commands |
| `backtrace 6` | Show the six most recent frames; plain `backtrace` shows all |
| `frame 3` | Select frame 3 |
| `up` / `down` | Move toward frame 0 (newer calls) / toward older callers |
| `list-locals` | Show the selected frame's local variables and arguments |
| `print` | Show the selected frame's call again |
| `abort` or the restart's number | Invoke that restart, here returning to top level |

Here `backtrace 6` prints:

```text
0: (SB-KERNEL:TWO-ARG-+ 90 "85")
1: (+ 90 "85")
2: (REDUCE #<FUNCTION +> (90 "85" 70))
3: (MEAN-SCORE (90 "85" 70))
4: (REPORT-MEAN (90 "85" 70))
5: (SB-INT:SIMPLE-EVAL-IN-LEXENV (REPORT-MEAN (LIST 90 "85" 70)) #<NULL-LEXENV>)
```

Read it from the top down. Frames 0–2 are SBCL and standard-library internals;
frame 3 is the first function **you** wrote. That is the frame to study:

```text
0] frame 3
(MEAN-SCORE (90 "85" 70))
3] list-locals
SCORES  =  (90 "85" 70)
```

The argument already contains a string, so `mean-score` received input that
breaks its documented contract. `down` shows that `report-mean` passed the same
list along, and frame 5 is the REPL evaluating your form. The fix is a policy
decision: validate in `mean-score` (for example, signal a clear error for a
non-number) or make the caller convert text first. Type `abort` to return to
`*`, then edit the source file rather than repairing the running image.

Locals depend on debug settings. If `list-locals` shows nothing useful, use
the optional `declaim` above, recompile, and reproduce the failure.

## A debugging procedure

1. Reproduce with the smallest input in a fresh process.
2. Read the condition type, message, and top relevant application frame.
3. Compare actual arguments with the function's contract.
4. Fix the definition in its source file, reload/recompile, and rerun.
5. Add a regression test and run the full suite.

Continuing a live image is a productivity tool, not proof that source is fixed.
Never rely on interactive corrections to make batch tests pass.

## Lab 10 — Test and repair

### A test-operation recipe, not a capstone prerequisite

You do not need to study the capstone to run a test system. Keep your Lesson 09
package and implementation. Add `tests.lisp` containing:

```lisp
(in-package #:course-sequences)

(defun run-tests ()
  (assert (equal (positive-squares '(-2 0 3 1)) '(9 1)))
  (assert (= (total-by #'identity nil) 0))
  t)
```

In the existing main `asdf:defsystem`, add this option so testing the main
system delegates to the test system:

```lisp
:in-order-to ((asdf:test-op (asdf:test-op "course-sequences/tests")))
```

This is an ASD option fragment, not a standalone REPL form. Then add a second
system definition to that same ASD:

```lisp
(asdf:defsystem "course-sequences/tests"
  :depends-on ("course-sequences")
  :components ((:file "tests"))
  :perform (asdf:test-op (operation component)
             (uiop:symbol-call :course-sequences :run-tests)))
```

`:depends-on` loads the library first; `:components` loads the tests file.
`:perform` supplies the test action. `operation` and `component` are parameters
supplied by ASDF; this action does not need their values. `uiop:symbol-call`
calls the named function after its package has loaded, avoiding a read-order
dependency in the ASD. It is an ASDF/UIOP helper, not something to memorize.
Do not add the test file to the production system's components.

After the explicit ASD loading recipe from Lesson 09, evaluate
`(asdf:test-system "course-sequences")`. A failed assertion must fail the run.
Add your remaining tests before debugging a deliberately broken version.

For a batch check, if your library lives in `work/course-sequences/`, save
`work/run-sequence-tests.lisp` with:

```lisp
(require :asdf)
(asdf:load-asd (truename "work/course-sequences/course-sequences.asd"))
(asdf:test-system "course-sequences")
```

Adjust that one pathname if you chose another directory in Lab 09. From the
course directory run this **shell** command, not a Lisp REPL form:

```sh
sbcl --noinform --no-sysinit --no-userinit --script work/run-sequence-tests.lisp
```

Script mode makes an unhandled test failure end unsuccessfully rather than
waiting in the debugger. Check the shell status with `echo $?` immediately
afterward: 0 means success, a nonzero value means failure. Use an interactive
REPL separately when you want to inspect the deliberate failure.

### Exercises

1. Add a test file and a `run-tests` function to `course-sequences`.
2. Configure an ASDF test system using the recipe above.
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
