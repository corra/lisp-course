# 14 — Types, performance, and deployment

**Goals:** measure representative work, use declarations responsibly, and ship a
reproducible program. **Prerequisite:** 13. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 13](13-macros.md):

- Macros receive source forms and return expansions; ordinary functions receive
  evaluated arguments. Prefer a function when its evaluation behavior is sufficient.
- An expansion must preserve intended evaluation counts/order and avoid accidental
  name capture. Inspect it and test side-effecting inputs rather than guessing.
- Compile-time availability differs from load/run time; `eval` is not a shortcut
  for calling functions or gaining access to a caller's lexical variables.

With abstraction and correctness established, this lesson turns to measurement,
responsible compiler declarations, and reproducible delivery.

## Algorithm and representation first

Before optimizing, establish correctness with tests. Measure representative input
sizes and record SBCL version, machine, compilation settings, and input data.

```lisp
(time (loop for n below 100000 sum (* n n)))
```

SBCL's `time` reports elapsed/CPU time and allocation information; exact output
varies. Run several trials after an initial warm-up. Include loading/I/O only if
your question includes startup/I/O. A fast microbenchmark of an irrelevant kernel
does not prove the application is fast.

`time` is a standard Common Lisp macro; SBCL supplies its particular report.
In this `loop`, `for n below 100000` counts from zero to 99999, and `sum`
accumulates the expression's values into the loop's numeric result.

Common improvements:

- Replace repeated `append` on a growing list with `push` then `nreverse`.
- Replace repeated list indexing with traversal or a vector.
- Use a hash table instead of repeated linear lookup when size justifies it.
- Avoid intermediate allocations only after showing they matter.
- Separate data processing from output so both are measurable and testable.

SBCL offers statistical and allocation profiling extensions; consult its manual
when `time` no longer identifies the relevant cost. Profiling APIs are not ANSI.

## Types are promises, not conversions

```lisp
(defun sum-double-vector (samples)
  (declare (type (simple-array double-float (*)) samples)
           (optimize (speed 2) (safety 3) (debug 1)))
  (loop for value across samples
        sum value into total of-type double-float
        finally (return total)))
```

`declare` supplies information inside this function rather than globally as
`declaim` did in Lesson 10. `(type type-specifier variable)` declares the input
type. `(simple-array double-float (*))` means a simple, one-dimensional array of
double-floats with unspecified length: `(*)` is a dimension pattern, not a call
to multiplication. Here “simple” excludes adjustability, a fill pointer, and
displacement to another array. `samples`, `value`, and `total` are names chosen
for this function and loop, not new built-ins.

`across` traverses a vector; `sum ... into total` names the accumulator;
`of-type double-float` declares its type; `finally` runs after normal iteration,
and `(return total)` makes it the loop's result. These are `loop` clauses, not
ordinary calls. `:element-type` in `make-array` below requests an array element
type rather than merely asserting what elements happen to be present.

Build suitable input with `make-array` and `:element-type 'double-float`;
general vectors containing double-floats need not have this specialized type.
Check the empty-vector case too. `declare` and `the` assert information to the
compiler; they do not turn a string into a number or automatically validate every
public API argument. Use validation and explicit conversion such as `coerce`.

`the` has syntax `(the type-specifier form)`: it asserts a type for a form's
result. It does not perform the conversion that `coerce` performs (Lesson 02).
The `optimize` quality settings retain the meanings introduced in Lesson 10.

Do not promise a `fixnum` if a calculation may exceed its implementation-dependent
range. Arbitrary-precision integer arithmetic is part of Lisp's value model.
Never lower safety simply to remove a warning. Incorrect declarations combined
with aggressive unsafe compilation can have severe consequences.

## Deployment choices

1. **Source + SBCL:** simplest for this course; ship `.lisp`/`.asd`, a run command,
   tests, and dependency/environment notes.
2. **Compiled files:** faster loading, but rebuild for compatible implementation,
   version, and platform; do not distribute them as universally portable bytecode.
3. **SBCL executable image:** `sb-ext:save-lisp-and-die` can save an executable
   with a `:toplevel` entry function and `:executable t`. This is SBCL-specific and
   must be tested on the target environment. Saving normally terminates the build
   Lisp process; use a disposable process, not a valuable interactive session.

The capstone uses option 1 so there is no hidden image-building step. A top-level
entry function should parse arguments, call library code, report expected errors
to stderr, and return an appropriate process exit code. Keep command-line parsing
and process termination out of reusable core functions.

## Optional ecosystem orientation

External libraries can provide test frameworks, regexes, JSON, sockets, and more.
Before adding one, identify its system/package names, license, supported
implementations, maintained source, installation method, and version policy.
Loading Lisp dependencies executes code; inspect what you install. Quicklisp is
one optional distribution mechanism; ASDF still defines and builds systems.
Threads, sockets, and FFI interfaces are implementation-specific or library-based,
not portable core Common Lisp features supplied by this course.

For a hands-on introduction, complete [Quicklisp, Alexandria, and FiveAM](../optional/QUICKLISP.md).
For source checkpoints, development configuration, and the supplied dependency-free
CI workflow, see [practical tools](../optional/TOOLING.md). Neither extension
changes the capstone's library requirements or assumes an editor integration.

## Lab 14 — Measure and explain

### Exercises

1. Implement repeated-append and push/reverse versions of building `n` integers.
   Verify equivalent results before timing.
2. Compare them on at least three input sizes. Record commands, environment,
   times, and allocations without claiming universal speed ratios.
3. Benchmark your word-frequency report on generated input and identify its
   dominant cost.
4. Justify an optimization or explain why you would not optimize. Keep safety enabled.

### Acceptance checklist

- [ ] Exercise 1: both implementations produce equivalent results.
- [ ] Exercise 2: the report includes reproducible commands, environment details,
  and measurements at three or more input sizes.
- [ ] Exercise 3: the word-frequency benchmark identifies its dominant cost.
- [ ] Exercise 4: your decision follows the measurements and preserves safety.

### Review questions

1. Why can a data structure change beat compiler tuning?
2. Why does a type declaration not replace validation?
3. What is portable about source delivery that is not portable about an SBCL
   executable image?
