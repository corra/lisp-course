# Common Lisp on Linux: a practical programming course

A complete, editor-independent introduction to **Common Lisp**, using **SBCL**
(Steel Bank Common Lisp) on Linux. You need introductory programming experience,
but no Lisp knowledge. This is Common Lisp, not Scheme, Racket, Clojure, or Emacs
Lisp; examples from those languages are not necessarily interchangeable.

## Start here

1. Read [the course guide](COURSE.md).
2. Complete [Lesson 00: environment and workflow](lessons/00-environment.md).
3. Work through the lessons in order, attempting exercises before solutions.

The required tools are a terminal, SBCL, and **any plain-text editor**. No editor
commands, structural-editing plugins, SLIME, SLY, language server, Quicklisp, or
third-party Lisp libraries are required. All required labs work offline once
SBCL and these files are installed.

## Contents

- [Course guide and assessment](COURSE.md)
- [00 — Linux setup and reproducible workflow](lessons/00-environment.md)
- [01 — Reading and evaluating Lisp](lessons/01-evaluation.md)
- [02 — Values, numbers, symbols, and equality](lessons/02-values.md)
- [03 — Functions, bindings, and scope](lessons/03-functions.md)
- [04 — Decisions, iteration, and recursion](lessons/04-control.md)
- [05 — Cons cells, lists, and ownership](lessons/05-lists.md)
- [06 — Functions as values and sequence processing](lessons/06-sequences.md)
- [07 — Arrays, strings, and hash tables](lessons/07-collections.md)
- [08 — Streams, files, and data boundaries](lessons/08-io.md)
- [09 — Packages, compilation, and ASDF](lessons/09-systems.md)
- [10 — Tests and interactive debugging](lessons/10-testing.md)
- [11 — Conditions, handlers, and restarts](lessons/11-conditions.md)
- [12 — Structures, classes, and generic functions](lessons/12-objects.md)
- [13 — Macros and code as data](lessons/13-macros.md)
- [14 — Types, performance, and deployment](lessons/14-performance.md)
- [15 — Capstone: a persistent task tracker](lessons/15-capstone.md)
- [Exercise hints and worked solutions](SOLUTIONS.md)
- [Command and language reference](REFERENCE.md)

## Executable material

From this directory:

```sh
sbcl --noinform --no-sysinit --no-userinit --script examples/run-all.lisp
```

Or run individual checks and the application:

```sh
sbcl --noinform --no-sysinit --no-userinit --script examples/smoke-tests.lisp
sbcl --noinform --no-sysinit --no-userinit --script examples/exercise-solutions.lisp
sbcl --noinform --no-sysinit --no-userinit --script capstone/run-tests.lisp
sbcl --noinform --no-sysinit --no-userinit --script capstone/cli.lisp help
```

`examples/smoke-tests.lisp` checks representative language examples, not every
possible exercise answer. `examples/exercise-solutions.lisp` contains executable
reference answers. `capstone/` is a complete reference implementation: build your
own first, then compare. It intentionally uses only standard Common Lisp plus
SBCL's command-line interface, its UTF-8 external-format name, and the ASDF/UIOP
supplied with SBCL.

Shell blocks are Linux terminal commands. Lisp blocks contain Lisp source only:
do not type a displayed REPL prompt into a file. Unless specified otherwise,
commands assume this directory is the working directory.

## Validation

The full reference suite was checked on Linux with **SBCL 2.6.9**, with site and
user initialization disabled. It covers language examples, exercise solutions,
capstone behavior and malformed files, plus 18 CLI subprocess scenarios. CLI
tests execute from a different working directory. You can select a different
SBCL binary for subprocess tests using the `COURSE_SBCL` environment variable.
