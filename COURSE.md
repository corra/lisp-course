# Course guide

## Destination

By the end, you will be able to:

- Read, write, compile, test, and debug Common Lisp without editor integration.
- Explain evaluation, quotation, lexical scope, function namespaces, and mutation.
- Choose suitable list, sequence, hash-table, structure, and class representations.
- Use closures, generic functions, conditions/restarts, and small safe macros.
- Organize a project with packages and ASDF; distinguish source from compiled code.
- Deliver a tested command-line program with validated persistent data.
- Consult the Common Lisp HyperSpec and identify SBCL-specific extensions.

Optional extensions teach explicit Quicklisp loading, responsible third-party
dependency use, Alexandria utilities, FiveAM tests, Git checkpoints, and CI.
Editor integrations are explained as choices, not prerequisites.

## Prerequisites and pace

You should already understand variables, functions, conditionals, loops, and basic
data structures in some programming language. You do **not** need recursion,
functional programming, macros, object-oriented programming, or Unix expertise.

Plan for **100–130 hours**, roughly 12–16 weeks at 8 hours/week. This is an estimate,
not a deadline. Most lessons take 4–6 hours including exercises; setup takes 2–4,
and the capstone 16–24. Treat the three milestones as separate integration
sessions, not extra work to squeeze into the preceding lesson's first sitting.
The whole-course estimate includes those projects. Spend extra time practicing
evaluation, bindings, and list sharing, rather than memorizing reference details.

Allow another **6–9 hours** for the optional library/tooling modules. Editor
integration setup is discretionary and varies with your chosen environment.

Suggested progression:

| Stage | Lessons | Evidence of readiness |
|---|---|---|
| Environment | 00 core | Run a file, reload it, deliberately recover from an error |
| Foundations | 01–04 core | Explain an expression and write a small numerical program |
| Data and functions | 05–08 | Transform collections and process a file safely |
| Engineering | 09–11 | Build a system, test it, inspect failures, recover deliberately |
| Abstraction | 12–14 | Choose objects/macros carefully and measure before optimizing |
| Integration | 15 | Deliver the task tracker and demonstrate its failure cases |

### Core path versus reference material

The intended learner is new to Lisp, not already fluent in its scope machinery.
Learn a useful pattern, practice it, and only then compare alternatives. A lesson
should not answer every possible language-lawyer question before its first lab.

- **Core / learn now:** enough explanation and worked examples for the current
  lab. Complete these before relying on them in the next lesson.
- **Guided second pass:** a small extension after the basic task works. Its
  scheduled revisit is stated; it must not silently become an earlier prerequisite.
- **Optional reference / later recognition:** consult when a real task needs it.
  This is not a memorization assignment or an extra core acceptance requirement.
  Essential correctness warnings (such as not mutating literals) still apply.

| Lesson | First useful outcome | Return to later |
|---|---|---|
| 00 | Edit/load/run a greeting; recover to the REPL | Compilation in 09; integrations only if wanted |
| 01 | Predict calls, quotation, `if`, and `progn` | Macro implementation and `eval` in 13 |
| 02 | Exact arithmetic, truth, appropriate equality, observing multiple values | Detailed rounding in the numeric reference; named multiple-value capture in 07 |
| 03 | Small functions, `let`/`let*`, assignment, keyword defaults, ordinary top-level settings | Closure exercises in 06; special declarations after 08, only if needed |
| 04 | Branches, loop accumulators, a direct recursive example | Local recursive helpers on a second pass or in 06; extra control syntax by lookup |
| 05 | Construct, traverse, copy, and safely change lists | Tree recursion and destructuring after the core lab |
| 06 | Call/pass functions, transform collections, preserve ownership | Revisit steppers; local helpers next; unusual argument lists by lookup |
| 07 | Choose vectors/strings/hash tables; distinguish absence from stored `nil` | Multidimensional arrays and text-policy details as needed |
| 08 | Read/write text and strictly parse numbers | Lisp-object persistence after 09, before capstone persistence |
| 09 | Define a package, then build/load a small ASDF system | Symbol-collision examples and compilation details after the first system works |
| 10 | Assert results, run tests in batch, inspect one failure | Compiler-debug settings only if needed |
| 11 | Handle a known failure, define a domain condition, then offer one restart | Low-level cleanup and other signaling variants by lookup |
| 12 | Build a record, render a class, then add a subclass | Multiple dispatch, method combination, slot types |
| 13 | Inspect a macro expansion and preserve once-only evaluation | `eval` scope and phase-control rules |
| 14 | Measure correct algorithms before optimizing | Typed kernels, profiling, saved executables |
| 15 | In-memory core first, then persistence, then CLI | Reference-source tables only for the feature currently being added |

You can start the capstone after the core work through 12 and the milestones;
writing macros and tuning compiler declarations are not entrance requirements.
For the full course, still work through 13–14, either before or alongside the
capstone. In early lessons, do not require an exhaustive API, ownership, type,
or portability audit before a learner has written a working function.

Extensions are labelled where they appear: Lab 03.5 (closures) is revisited as
Lab 06.5, and Lab 04.5 is a guided second pass, not a gate to Lesson 05.
Assess core and extension work
separately rather than treating every numbered item as an immediate prerequisite.

### Optional routes without changing the main course

- **Alongside 00:** use [tools and configuration](optional/TOOLING.md) for Git,
  `rlwrap`, offline documentation, and backup/ignore policies. `work/` is ignored;
  keep assessed work in your own repository or deliberately tracked directory.
- **After 09/10:** complete [Quicklisp and libraries](optional/QUICKLISP.md) using
  Alexandria and FiveAM. Its ASDF example remains separate from the capstone.
- **After 10:** revisit development compiler settings and the supplied core CI job.
- **After 13:** explore Alexandria's macro helpers, relating them to expansions
  you already understand rather than using them as magic.
- **When a question calls for it:** [numeric details](optional/NUMBERS.md) after
  02, and [dynamic scope and special declarations](optional/DYNAMIC-SCOPE.md)
  after 08. These preserve deeper explanations outside the beginner core path.
- **At any point:** read [editors and integrations](optional/EDITORS.md). Its
  editor-specific installation guides include isolated configurations and a
  shared verification exercise. Adopt an integration only if helpful; keep the
  terminal commands as the common baseline.

## How to study each lesson

### How examples introduce names and notation

Each lesson builds on earlier lessons in numerical order. A new language feature
used in an example should have a local explanation or a specific reference to
its teaching section. A **preview** is recognition-only until the linked lesson;
you need not independently research it to complete the current lab. Definitions
are sometimes explained immediately after the example so you can read both
together.

- Names introduced by `defun`, `defmacro`, `defpackage`, parameter lists, `let`,
  or loop bindings are **chosen by the example**, not additional built-ins.
  Later lessons identify names automatically generated by record/class definitions.
- Syntax shapes such as `(operator argument...)` use descriptive placeholders;
  `...` is explanatory notation, not text to enter. Inline names such as
  `actual`, `expected`, `entries`, or `user-text` stand for your own data unless
  the surrounding example supplies a binding. Source-file contents and deliberate
  error demonstrations are labelled rather than presented as ordinary REPL calls.
- `:name` is keyword-symbol notation (Lesson 02), `#'name` denotes a function
  reference (Lesson 06), and `package:name` is package qualification (Lesson 09).
  Each has a brief introduction where used earlier. Context matters: the same
  printed symbol can be a variable, function name, type name, or syntax marker.
- Exercises referring to earlier lab functions require loading your saved
  definitions first. A fresh process does not contain yesterday's REPL definitions.

The same rule applies to tooling: required commands and workflows must be taught
before an exercise relies on them. [Lesson 00](lessons/00-environment.md) is the
baseline terminology and SBCL user's guide for starting, loading, compiling, and
recovering to the REPL. It introduces working definitions; later lessons explain
specialist terms where first needed. Small one-off tool instructions belong
inline where needed; fuller debugging coverage belongs in
[Lesson 10](lessons/10-testing.md). Earlier labs
must not silently assume that later tooling knowledge. Instructions to “trace”
evaluation by hand mean a written walkthrough, not a debugger command, unless
the exercise explicitly asks for tool-assisted tracing and explains how to use it.

Use the [construct-to-lesson index](REFERENCE.md#where-constructs-are-taught) when
you want to revisit the teaching section, rather than guessing from a name.

### Study cycle

Each lesson opens with a brief **Prerequisite recap** and links to the relevant
earlier material. Use it to reconnect the concepts needed next; it is a reminder,
not a replacement for the original explanations. Lesson 00 instead summarizes
the introductory programming knowledge assumed by the course.

1. Read the objectives and prerequisite recap, then predict each example's result
   **before** evaluating it.
2. Type examples into a file; load them into a fresh SBCL session.
3. Change one thing and explain the new result. Keep a prediction journal.
4. Complete the core lab; check normal and boundary cases, plus invalid inputs
   where the exercise promises validation. Take extension exercises at their
   stated revisit point rather than treating them as a gate to the next lesson.
5. Consult [solutions](SOLUTIONS.md) only after a genuine attempt.
6. Close SBCL and rerun from a fresh process. Hidden REPL state is not a dependency.

Follow the lesson's core/extension labels. Before Lesson 10, checking returned
values at the REPL and recording deliberate errors is sufficient: you are not
expected to invent an automated test harness or learn handlers ahead of time.
Avoid consulting all optional links during the first reading.

Use the terminal workflow throughout, even if you later add editor integration.
Use `work/` for scratch exercises, but remember that it is ignored by Git: back
it up or keep assessed source in your own learner repository/tracked directory
(see the tooling guide). Do not edit reference solutions as a substitute for
writing your own program. Use descriptive names, docstrings
for public functions, and short comments explaining decisions rather than syntax.

Follow the [course style guide](STYLE.md), starting with naming/layout and adding
the later guidance as each feature is taught. It describes common Common Lisp
practice, distinguishes conventions from language requirements, and permits
justified project-specific exceptions. [Lesson 03](lessons/03-functions.md#naming-conventions)
provides the main naming lesson. Style review should not change required API names.

## Assessment

Labs use a consistent format: **Exercises** are numbered actions;
an **Acceptance checklist** gives individually checkable outcomes labelled with
their exercise numbers; and numbered **Review questions** are oral or written
self-tests. The larger capstone uses a numbered development sequence and a
project-wide acceptance checklist, followed by its marking rubric.

A completed core lab must be reproducible in a fresh process and explain its design,
not merely print one correct answer. Use the checklists to verify your work,
not as additional unnumbered exercises.

Suggested marking:

| Component | Weight | What earns credit |
|---|---:|---|
| Labs 01–14 | 40% | Correct results, edge cases, readable Lisp, fresh-process tests |
| Three milestone projects | 20% | Integration and reasoning about representation |
| Capstone | 30% | Required behavior, validation, tests, packaging, usable CLI |
| Explanations and review | 10% | Evaluation, scope, sharing, recovery, macro justification |

Milestones:

1. **After 04: numeric report.** Accept an in-memory list of numbers; return count,
   sum, and exact mean, with a documented policy for empty input. Use two loop
   styles and compare clarity. Do not add file parsing yet.
2. **After 08: word-frequency report.** Read a text file line by line, split on
   whitespace (punctuation handling is an explicit policy), normalize case, count
   with an `equal` hash table, and sort by descending count with lexical tie-breaks.
   Preserve input strings; demonstrate empty input and a missing file.
3. **After 11: resilient importer.** Validate a list of candidate task records,
   report invalid records with a custom condition, and let a caller choose to
   stop or skip using a restart. Do not hide unrelated programming errors.

No solution is supplied for these three integration projects: use lesson
solutions as building blocks, and the requirements above as acceptance criteria.

## Scope and portability

The language is ANSI Common Lisp. SBCL is one implementation; the terminal,
debugger commands, executable images, and `sb-ext` are implementation-specific.
ASDF is a system definition/build facility; UIOP is its portability utility layer.
They are widely distributed but not part of the ANSI language standard.
Quicklisp is a separate library distribution tool; it is not a language feature,
compiler, or prerequisite for this course.

The optional module supplies installation instructions, not an implicit install
step. Core tests and CI do not load it. Optional tests explicitly load Quicklisp
even with `--no-userinit`, and keep dependency acquisition out of library code.

The core course does not cover GUI programming, web frameworks, FFI, networking,
threads, lock-free programming, Unicode normalization, or secure sandboxing.
These are sensible follow-on projects, not prerequisites hidden inside a lab.

## Reading alongside the course

These are reference and supplementary resources, not required purchases:

- [Common Lisp HyperSpec](https://www.lispworks.com/documentation/HyperSpec/Front/):
  authoritative language reference; start with the symbol index and glossary.
- [SBCL manual](https://www.sbcl.org/manual/): invocation, debugger, compiler,
  platform differences, and implementation extensions.
- [ASDF manual](https://asdf.common-lisp.dev/asdf.html): systems, components,
  dependency order, discovery, and test operations.
- [Practical Common Lisp](https://gigamonkeys.com/book/), Peter Seibel:
  complementary explanations and projects; its historical setup advice is not
  the required setup for this course.
- [Common Lisp: A Gentle Introduction to Symbolic Computation](https://www.cs.cmu.edu/~dst/LispBook/),
  David Touretzky: additional practice with symbols, lists, and recursion.

When using online examples, check the Lisp dialect, implementation, dependency
requirements, and whether the example is intended as interactive code or a file.
