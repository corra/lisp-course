# Independent course review — 2026-10-20

## Scope and baseline

Reviewed the 16 core lessons, supporting course/reference/solution material,
and reference implementations against the in-progress working tree based on
commit `455d3c3`. This included uncommitted changes, not just that commit.
The independent review used a snapshot to avoid interfering with other edits.

The beginner progression is substantially clearer after separating core work,
guided second passes, and optional reference material. The review found no
blocking runtime regression in the supplied reference suite. Four remaining
issues were identified and are resolved below. These findings describe the
reviewed files, not which contributor introduced them.

## 1. Tracing example depended on an undefined function

**Priority:** medium. **Status:** fixed.

**Location:** [Lesson 10 — Inspect rather than guess](lessons/10-testing.md#inspect-rather-than-guess).

The lesson allowed learners to load `examples/exercise-solutions.lisp` and
select its `COURSE-EXERCISES` package. That file defines `factorial-iter`, but
the subsequent tracing example called `factorial`, which was not defined in
that package. Following the reference-solution route could therefore produce
an `undefined-function` error instead of a useful trace.

**Resolution:** include the recursive definition directly before its tracing
calls. Explicitly instruct learners to evaluate it in their current package,
and distinguish it from the iterative reference answer. The example no longer
depends on a definition left in another package or a previous REPL session.

## 2. Short-circuit description lost the final form's multiple values

**Priority:** medium. **Status:** fixed.

**Location:** [Lesson 04 — Combining tests](lessons/04-control.md#combining-tests-and-and-or).

The blanket statement that `or` returns only the selected operand's primary
value was incorrect when evaluation reaches its final form. Both `and` and
`or` return all values from that final form, even when its primary value is
`nil`. Earlier short-circuit decisions use primary values instead.

```lisp
(multiple-value-list (or nil (values 1 2)))        ; (1 2)
(multiple-value-list (or (values 1 2) :skipped))   ; (1)
(multiple-value-list (and t (values nil :extra))) ; (NIL :EXTRA)
```

**Resolution:** correct the explanation, retain the simple short-circuit
examples, and add a brief multiple-value illustration. The language smoke suite
now checks both final-form preservation and earlier short circuits for each
operator. This agrees with the HyperSpec entries for
[`or`](https://www.lispworks.com/documentation/HyperSpec/Body/m_or.htm) and
[`and`](https://www.lispworks.com/documentation/HyperSpec/Body/m_and.htm).

## 3. Sorting test's shallow snapshot could conceal input mutation

**Priority:** medium. **Status:** fixed.

**Location:** the `sorted-scores` checks in
[`examples/exercise-solutions.lisp`](examples/exercise-solutions.lisp).

The test used `copy-list` for its before-call snapshot, sharing the inner
name/score pairs with the input. Mutating a score changed both the input and
the supposed snapshot. The output check compared names only, so a score-mutating
implementation could still pass all 50 exercise checks. This was reproduced
by substituting an intentionally faulty implementation in a separate process.

**Resolution:** allocate independently owned input name strings, then snapshot
each pair and copy each name string before sorting. Check the full returned
records, including scores, as well as the unchanged input. The solution notes
now distinguish copying enough for the sorting implementation from copying
enough for an independent no-mutation test.

The actual `sorted-scores` implementation did not require a change. Diagnostic
substitutions that return correct detached results but mutate input scores or
input names must now fail the preservation check.

## 4. Shared-tail explanation conflated binding, assignment, and mutation

**Priority:** low. **Status:** fixed.

**Location:** [Lesson 05 — Shared tails](lessons/05-lists.md#shared-tails-and-shallow-copies).

The explanation called `let*` initializations assignments and described
rebinding as changing the variable. This contradicted Lesson 03's distinction
between establishing a binding and assigning to an existing one.

**Resolution:** explicitly distinguish creating the three bindings, allocating
new head cells that share a tail, mutating a shared cell, assigning a different
list to the existing `tail` binding, and creating a shadowing inner binding.
An additional smoke check confirms that assigning another list to `tail`
does not change the cells referenced by the existing lists.

## Validation and limitations

Run the complete dependency-free reference suite from the course directory:

```sh
sbcl --noinform --no-sysinit --no-userinit --script examples/run-all.lisp
```

Result after the fixes: **223 checks passed** — 115 language smoke checks,
50 exercise checks, 39 capstone checks, and 19 CLI subprocess checks.

The fixes are also checked with the exact Lesson 10 tracing block in fresh
sessions, both in `CL-USER` and after loading/selecting `COURSE-EXERCISES`;
deliberate score/name-mutation substitutions in separate processes; and local
Markdown link/heading checks. Diagnostic substitutions never modify the saved
implementation.

Both tracing setups passed, both deliberately mutating implementations were
rejected, and the local Markdown paths/heading anchors and `git diff --check`
passed.

Quicklisp-dependent tests, editor installations, and hosted CI are outside this
validation. Passing the reference suite alone does not prove every prose claim
or every learner implementation correct; the tracing and mutation checks are
deliberately additional checks of the review findings.
