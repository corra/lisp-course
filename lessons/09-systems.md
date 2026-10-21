# 09 — Packages, compilation, and ASDF

**Goals:** separate names from systems, organize files, and load deterministically.
**Prerequisite:** 08. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 08](08-io.md):

- Streams separate processing from its destination/source; scoped file operations
  close resources even when control leaves the body unexpectedly.
- Parsing an integer, reading Lisp data, and evaluating Lisp code are different
  operations. User data must not be treated as trusted executable code.
- Pathnames identify files; explicit paths and documented encoding/overwrite
  policies make file behavior reproducible rather than dependent on hidden defaults.

This lesson applies that explicitness to project structure: packages organize
names, while ASDF describes how source files and systems are built and loaded.

**Two passes:** first create one package and call its exported function. Then
put that working example in separate files and load it with ASDF. Package name
conflicts and compile-time helpers are follow-up references, not prerequisites
for your first successful system load.

## Packages organize symbols

`CL` is the package containing standard Common Lisp symbols. A normal fresh
SBCL REPL starts in `CL-USER`, a user workspace that can access standard names.
`course-math` below is a package name chosen for this example, not an installed
library. Likewise, `square` is defined in the example rather than built into Lisp.

Use a distinctive project-related package/system name and lowercase hyphenated
source/file names, as in `course-math` and `course-math.asd`. Do not use case
changes to distinguish packages or automatically repeat the entire package name
inside every exported function name. See the [style guide](../STYLE.md#5-packages-systems-and-dependencies).

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

`:use` lists packages whose exported symbols should be accessible; `:export`
lists symbols this new package makes public. These are `defpackage` options.
The special variable `*package*` holds the current reader package, and
`find-package` retrieves a package object from a name. A package's **interned**
symbols are registered by name so reading the same name there can find the same
symbol; `#:` and `gensym` produce uninterned symbols instead.

From another package call `(course-math:square 4)`. A single colon requires an
exported symbol. Double colon accesses internal symbols and should not be a
routine substitute for a public API. Keywords belong to the `KEYWORD` package.

Some projects additionally prefix internal helpers with `%`; this is optional
and does not make a symbol private or uncallable. Exports define the ordinary
public API boundary. Follow a project's established helper-naming convention
rather than inventing a different prefix for each file.
`(:use #:cl)` makes exported Common Lisp symbols accessible; do not redefine
inherited names such as `list`, `count`, or `remove`. SBCL package locks often
catch this mistake. Choose a different name or intentionally shadow when justified.

Packages do not load files or install dependencies. A **system** is a collection
of source components and dependency/build instructions. A single system can
contain several packages; neither is a Linux process.

### Special variables and API name collisions

**Follow-up example; skip to the minimal ASDF system on the first pass.**
[Lesson 03](03-functions.md#top-level-variables-for-shared-settings) introduced
top-level settings without promising name isolation. The relevant
identity is the **symbol**, not just its spelling. The same applies to function
names, though variables and functions occupy separate namespaces on a symbol.

Evaluate these forms in order in a fresh session. Each `in-package` must be
processed before the following forms are read, so do not wrap the entire example
in a single `progn`.

```lisp
(defpackage #:course-settings-a
  (:use #:cl)
  (:export #:*setting*))

(defpackage #:course-settings-b
  (:use #:cl)
  (:export #:*setting*))

(in-package #:course-settings-a)
(defparameter *setting* 10)

(in-package #:course-settings-b)
(defparameter *setting* 20)

(in-package #:cl-user)
(list course-settings-a:*setting*
      course-settings-b:*setting*) ; (10 20)

(let ((course-settings-a:*setting* 99))
  (list course-settings-a:*setting*
        course-settings-b:*setting*)) ; (99 20)

course-settings-a:*setting*     ; 10 again
```

Both packages use the spelling `*setting*`, but each owns a different symbol.
Rebinding one does not change the other. The distinct package names themselves
are important too: two libraries that choose the same package name do not obtain
independent namespaces automatically.

Within one package, repeating a definition uses the same symbol:

```lisp
(defparameter course-settings-a:*setting* 30)
(defvar course-settings-a:*setting* 40)
course-settings-a:*setting*     ; 30, not 40
```

Here `defparameter` overwrites the earlier value, while `defvar` preserves the
existing bound value; neither diagnoses an accidental duplicate definition.
Use distinctive package names, export the intended API, and prefer qualified
references when combining libraries. If you import a symbol or make it accessible
through `:use`, you are using that same symbol, not a copy. Trying to make two
distinct exported symbols with the same name accessible without qualification
causes a package name conflict that must be resolved; it does not merge them.

An export marks an intended public interface, not an access-control boundary.
Keep implementation state lexical when possible, and do not treat package
internals or earmuffs as security mechanisms.

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

`require` asks the implementation to provide a named module. `(require :asdf)`
loads/registers the ASDF supplied with SBCL; it is not a general command to fetch
missing internet libraries. Evaluate it before reading `asdf:`-qualified forms.

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

In the ASD, `asdf:defsystem` defines the system, `:description` and `:version`
are metadata, and `:components` lists its source components. A component such as
`(:file "math")` names `math.lisp` relative to the ASD; it is ASDF configuration,
not a function call to `:file`. `:depends-on` can name other required systems,
as shown in the [optional library example](../optional/libraries/course-extras.asd).
Declaring a dependency does not itself install a missing library.

For future projects ASDF's source registry can discover systems automatically;
use its manual rather than requiring machine-specific paths in shared code.
`asdf:test-system` invokes a system's configured test operation—it does not
magically discover every test function.

The [capstone source guide](15-capstone.md#reading-the-reference-source) explains
`:in-order-to`, `:perform`, and `asdf:test-op` used to configure that test operation.
These build-system options are not needed to understand the minimal ASD above.

**Optional after this lab:** [Quicklisp, Alexandria, and FiveAM](../optional/QUICKLISP.md)
adds explicit dependency acquisition to this model. Read its setup and utility
sections now; complete the named test-suite lab after Lesson 10. The main course
and capstone keep using ASDF without any third-party library requirement.

## Compile time versus load time

Now complete the deferred [Lab 00.3 compilation recipe](00-environment.md#4-scripts-and-noninteractive-checks)
if you skipped it. Source loading is already familiar, so compare it with
compiling and then loading the resulting `.fasl`.

Compiled Lisp still supports interactive function redefinition. Compilation does
not imply a static, permanently sealed application. Conversely, a fresh process
cannot know definitions you only typed at yesterday's REPL.

Macros used in a file must be available while that file is compiled. Advanced
compile-time helpers may need `eval-when`; do not scatter it everywhere to silence
ordering problems. First separate packages, macro definitions, and consumers
into correctly ordered files. Lesson 13 returns to this distinction.

## Lab 09 — Package a library

If you do not use an automatic ASDF source registry, explicitly load your ASD
as shown above. `asdf:load-system` then compiles/loads its components in dependency
order; it does not change the REPL to the system's package. Use exported qualified
names or an intentional `in-package` when calling your API.

### Exercises

1. Organize your Lesson 06 functions as `course-sequences`, with a package file
   and a separate implementation file.
2. Export `positive-squares`, `total-by`, and `sorted-scores` as the public API;
   keep helpers internal.
3. Add an ASDF definition with the required component order.
4. Add public-function docstrings and a README with reproducible load commands.

### Acceptance checklist

- [ ] Exercise 1: package and implementation definitions live in separate files.
- [ ] Exercise 2: all three public functions are callable by their exported names;
  an unexported helper is not presented as public API.
- [ ] Exercise 3: a fresh SBCL process can explicitly load the ASD and system
  without definitions from `CL-USER` or init files.
- [ ] Exercise 4: the docstrings describe the API, and the README commands
  reproduce loading and calling it.

### Review questions

1. What is the difference between a package, source file, ASDF system, library
   distributor, and implementation?
2. Why does changing packages not install a missing library?
