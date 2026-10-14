# 09 — Packages, compilation, and ASDF

**Goals:** separate names from systems, organize files, and load deterministically.
**Prerequisite:** 08. **Time:** 4–6 hours.

## Packages organize symbols

```lisp
(defpackage #:course-math
  (:use #:cl)
  (:export #:square))

(in-package #:course-math)

(defun square (x) (* x x))
```

`#:name` is an uninterned symbol, often used as a name designator in definitions
without accidentally interning it in the current package. `defpackage` establishes
a namespace and its public exports; `in-package` changes which package the reader
uses for subsequent unqualified symbols. Read/evaluation order therefore matters.

From another package call `(course-math:square 4)`. A single colon requires an
exported symbol. Double colon accesses internal symbols and should not be a
routine substitute for a public API. Keywords belong to the `KEYWORD` package.
`(:use #:cl)` makes exported Common Lisp symbols accessible; do not redefine
inherited names such as `list`, `count`, or `remove`. SBCL package locks often
catch this mistake. Choose a different name or intentionally shadow when justified.

Packages do not load files or install dependencies. A **system** is a collection
of source components and dependency/build instructions. A single system can
contain several packages; neither is a Linux process.

## A minimal ASDF system

Create a separate `work/course-math/` directory containing:

`package.lisp`:

```lisp
(defpackage #:course-math (:use #:cl) (:export #:square))
```

`math.lisp`:

```lisp
(in-package #:course-math)
(defun square (x) (* x x))
```

`course-math.asd`:

```lisp
(asdf:defsystem "course-math"
  :description "A small course exercise"
  :version "0.1.0"
  :serial t
  :components ((:file "package")
               (:file "math")))
```

In a fresh SBCL started from the course directory:

```lisp
(require :asdf)
(asdf:load-asd (truename "work/course-math/course-math.asd"))
(asdf:load-system "course-math")
(course-math:square 7)       ; 49
```

Explicit `load-asd` avoids assuming any user registry configuration. `:serial t`
means later components depend on earlier ones. Larger systems should model
actual dependencies rather than relying on accidental load order. ASDF normally
places compiled outputs in a cache, not necessarily beside your source.

For future projects ASDF's source registry can discover systems automatically;
use its manual rather than requiring machine-specific paths in shared code.
`asdf:test-system` invokes a system's configured test operation—it does not
magically discover every test function.

## Compile time versus load time

Compiled Lisp still supports interactive function redefinition. Compilation does
not imply a static, permanently sealed application. Conversely, a fresh process
cannot know definitions you only typed at yesterday's REPL.

Macros used in a file must be available while that file is compiled. Advanced
compile-time helpers may need `eval-when`; do not scatter it everywhere to silence
ordering problems. First separate packages, macro definitions, and consumers
into correctly ordered files. Lesson 13 returns to this distinction.

## Lab 09 — Package a library

Turn your Lesson 06 functions into `course-sequences`, with a public API of
`positive-squares` and `total-by`, a package file, an implementation file, and an
ASDF definition. Add docstrings and a short load command in a README.

**Pass:** a new SBCL process can explicitly load the ASD, load the system, and
call both exported functions. No definitions from `CL-USER` or init files are
required. An unexported helper is not part of the public API.

**Checkpoint:** What is the difference between a package, source file, ASDF
system, library distributor, and implementation? Why does changing packages not
install a missing library?
