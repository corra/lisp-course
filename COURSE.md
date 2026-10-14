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

## Prerequisites and pace

You should already understand variables, functions, conditionals, loops, and basic
data structures in some programming language. You do **not** need recursion,
functional programming, macros, object-oriented programming, or Unix expertise.

Plan for **100–130 hours**, roughly 12–16 weeks at 8 hours/week. This is an estimate,
not a deadline. Each lesson takes 4–6 hours including exercises; setup takes 2–4,
and the capstone 16–24. Spend extra time on evaluation, list sharing, and scope:
later topics depend on them.

Suggested progression:

| Stage | Lessons | Evidence of readiness |
|---|---|---|
| Environment | 00 | Run a file, reload it, deliberately recover from an error |
| Foundations | 01–04 | Explain an expression and write a small numerical program |
| Data and functions | 05–08 | Transform collections and process a file safely |
| Engineering | 09–11 | Build a system, test it, inspect failures, recover deliberately |
| Abstraction | 12–14 | Choose objects/macros carefully and measure before optimizing |
| Integration | 15 | Deliver the task tracker and demonstrate its failure cases |

## How to study each lesson

1. Read the objectives and predict each example's result **before** evaluating it.
2. Type examples into a file; load them into a fresh SBCL session.
3. Change one thing and explain the new result. Keep a prediction journal.
4. Complete the numbered lab; include normal, boundary, and invalid-input tests.
5. Consult [solutions](SOLUTIONS.md) only after a genuine attempt.
6. Close SBCL and rerun from a fresh process. Hidden REPL state is not a dependency.

Use the terminal workflow throughout, even if you later add editor integration.
Store deliverables in your own `work/` directory; do not edit reference solutions
as a substitute for writing your own program. Use descriptive names, docstrings
for public functions, and short comments explaining decisions rather than syntax.

## Assessment

Every lesson has a lab, a checkpoint, and acceptance criteria. A passing lab must
be reproducible in a fresh process and explain its design, not merely print one
correct answer. Treat checkpoint questions as oral or written self-tests.

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
