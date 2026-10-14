# 14 — Types, performance, and deployment

**Goals:** measure representative work, use declarations responsibly, and ship a
reproducible program. **Prerequisite:** 13. **Time:** 4–6 hours.

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
(defun sum-double-vector (values)
  (declare (type (simple-array double-float (*)) values)
           (optimize (speed 2) (safety 3) (debug 1)))
  (loop for value across values
        sum value into total of-type double-float
        finally (return total)))
```

Build suitable input with `make-array` and `:element-type 'double-float`;
general vectors containing double-floats need not have this specialized type.
Check the empty-vector case too. `declare` and `the` assert information to the
compiler; they do not turn a string into a number or automatically validate every
public API argument. Use validation and explicit conversion such as `coerce`.

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

## Lab 14 — Measure and explain

Compare repeated-append and push/reverse implementations for building `n` integers
on at least three input sizes. Verify equality before timing. Report measured
times/allocations without claiming universal speed ratios. Then benchmark your
word-frequency report on a generated input and identify its dominant cost.

**Pass:** report includes reproducible commands, environment, equivalent results,
and a justified optimization or a reason not to optimize. Keep safety enabled.

**Checkpoint:** Why can a data structure change beat compiler tuning? Why does a
type declaration not replace validation? What is portable about source delivery
that is not portable about an SBCL executable image?
