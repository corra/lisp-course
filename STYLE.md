# Common Lisp course style guide

## Purpose and when to use this guide

These are the course's defaults for readable, idiomatic Common Lisp. They follow
widely used Common Lisp conventions, **not an ANSI-mandated formatting or naming
standard**. Existing projects sometimes make different reasonable choices:
follow the surrounding project's documented style rather than imposing a new one.

Start with naming and layout. Apply later sections as you learn their features;
the lesson references tell you when that is. This is a reference, not an extra
prerequisite or an invitation to use advanced constructs before understanding them.
Do not rename the specified lab APIs just to demonstrate a preference.

No editor, formatter, linter, or structural-editing extension is required.
Plain-text source and the documented terminal test commands remain the baseline.

Short teaching fragments sometimes omit full application documentation so the
syntax remains visible. Use the applicable guide sections when writing complete
lab/library code; do not mechanically expand every tiny demonstration.

## 1. Naming

**Learn in:** [Lesson 01](lessons/01-evaluation.md),
[Lesson 02](lessons/02-values.md), and the
[Lesson 03 naming guide](lessons/03-functions.md#naming-conventions).

| Kind | Course default | Examples / cautions |
|---|---|---|
| Functions, parameters, lexical variables, slots | Lowercase, hyphen-separated words | `price-with-tax`, `task-count`, `done-p`; not camelCase, PascalCase, or snake_case |
| Predicates | Conventional `p` or `-p` suffix | `integerp`, `valid-title-p`; see the exceptions below |
| Special variables | Paired asterisks | `*report-prefix*`; reserve earmuffs for actual special-variable semantics |
| Constants | Paired plus signs, where following this common project convention | `+maximum-items+`; the defining form, not the spelling, establishes a constant |
| Constructors | Usually `make-` plus the thing being constructed | `make-reading`, `make-store`; a descriptive alternative is fine when it better expresses the API |
| Record accessors | Commonly type/slot names | `reading-value`, `task-title`; use the generated names where appropriate |
| Binding/resource macros | Often `with-` plus the resource/context | `with-open-file`; a recognizable pattern, not a rule for every macro |
| Private helpers | Normal descriptive names; optionally a project-specific `%` prefix | `%make-task` in the capstone; `%` does not provide privacy |
| Files and ASDF systems | Descriptive lowercase, hyphenated names | `word-report.lisp`, `course-tasks.asd`, system `"course-tasks"` |

### Naming details that matter

- Under normal reader settings, symbol case is folded: `task-count` and
  `TASK-COUNT` denote the same symbol. Write lowercase source even when the REPL
  displays uppercase. Do not use escaped mixed-case names to imitate another
  language's class naming style.
- Many single-word predicates use `p`; compound names commonly use `-p`.
  Existing `null`, `equal`, and generated `reading-p` illustrate why this is not
  a rigid grammatical rule. Projects may consistently use `-p` more broadly.
  Truth-valued variables/slots can use `-p` as well. Do not import Scheme's `?`
  predicate suffix as the course default.
- A predicate may return any useful non-`nil` true value, not just `t`. Do not
  silently promise a strict boolean if your contract permits a useful object.
  If an operation's main purpose is to retrieve an object, prefer a query name
  such as `find-task` rather than adding `-p` merely because its result is truthy.
- Name for meaning, not an incidental representation: prefer `user-name` to
  `str-name`. Use singular/plural names where helpful (`task` versus `tasks`).
  Short mathematical/index names are appropriate only when their meaning is clear.
- Do not mark ordinary lexical locals with `*earmuffs*`. Special variables remain
  special when temporarily rebound; the earmuffs should still warn the reader.
  Punctuation alone does not declare scope or constantness, and constantness
  does not make every referenced object deeply immutable.
  Globally defined functions do not take earmuffs merely because they are global.
- Historical `n` names such as `nreverse` can signal destruction, but `sort` is
  destructive without that prefix. Do not mechanically prefix all mutators with
  `n-`, or add a `!` suffix. Use a clear operation name and document mutation.
- Do not redefine inherited standard Common Lisp or implementation-owned symbols.
  A local variable `count` is different from redefining the standard function
  `count`; see the separate namespaces in Lesson 03 and packages in Lesson 09.

## 2. Layout and whitespace

**Learn in:** [Lesson 01](lessons/01-evaluation.md) and
[Lesson 03](lessons/03-functions.md).

- Use spaces for indentation. Two spaces for a body is the course default;
  align continuation arguments/bindings so the expression structure is visible.
- Indent by Lisp structure, not by what a line would mean in a brace language.
  Parentheses determine grouping; indentation communicates it to people.
- Keep closing parentheses together at the end of the expression they close,
  rather than routinely placing one closing parenthesis on each separate line.
- Put a space between arguments; do not put padding immediately inside parentheses.
- Separate top-level definitions with a blank line. Avoid trailing whitespace;
  end source files with a newline.
- Aim for source lines around 80–100 columns where practical. A clear expression
  is more important than a forced wrap or a universal hard limit.
- Use plain-text `.lisp` files. Ordinary ASCII delimiters (`"`, `'`, parentheses)
  must not become typographic “smart quotes.” UTF-8 text in strings/comments is
  fine when the file's encoding and the application's text policy are clear.

For example, the function from Lesson 03 can be laid out as:

```lisp
(defun price-with-tax (price &key (rate 1/5))
  "Return PRICE with tax at RATE, preserving exact arithmetic when possible."
  (* price (+ 1 rate)))
```

This uses `defun`, `&key`, and a docstring from Lesson 03; it is an ordinary
definition, not a new formatting construct. Lisp-aware indentation is a useful
optional editor feature, not a requirement.

## 3. Functions, bindings, and returned values

**Learn in:** [Lessons 02–04](lessons/03-functions.md).

- Give each function a clear responsibility and contract. Prefer ordinary
  functions and explicit parameters to hidden dependencies on global settings.
- Use lexical bindings by default. Use `let*` when later initializers deliberately
  depend on earlier bindings; do not use it to conceal unclear data flow.
- Return values for reusable computations. Keep presentation and command-line
  process termination at the application boundary.
- Let the final form return a function's ordinary result. Use `return-from` for
  a meaningful early exit, not as mandatory boilerplate at every function's end.
- State empty-input and invalid-input policies. If a second value distinguishes
  absence from a stored `nil`, preserve and document it rather than discarding it.
- Use `progn` when several forms must occupy one form position, such as an `if`
  branch. Do not wrap bodies that already accept several forms unnecessarily.
- Choose control flow for clarity: `if` for a two-way choice, `cond` for ordered
  alternatives, and `when`/`unless` for one-sided work. Avoid deeply nested
  conditionals when a clearer equivalent exists.

## 4. Collections, equality, mutation, and ownership

**Learn in:** [Lesson 02](lessons/02-values.md) and
[Lessons 05–08](lessons/05-lists.md).

- Choose equality deliberately: `=` for numeric values, suitable string comparisons
  for text, `equal` for ordinary list/string structure, and `eq` for identity
  where appropriate. Do not use `eq` as portable numeric value equality.
- State whether a function may mutate its input, retain references to it, share
  storage in its output, or return independently owned data.
- Never mutate quoted literal lists, literal strings, or other literal data.
  Construct/copy owned data first. A shallow copy does not detach nested objects.
- Copy before destructive operations when the caller owns the input. Use the
  returned value of operations such as `sort` and `nreverse`.
- Do not assume hash-table iteration order is presentation order. Make reports
  deterministic with an explicit sort and tie-breaking rule.
- Choose data structures for access patterns. Avoid repeated list indexing or
  repeated append-to-a-growing-list when a traversal or push/reverse is clearer.
- Close resources using scoped constructs such as `with-open-file`. Document
  encoding and overwrite policies rather than relying on invisible assumptions.

## 5. Packages, systems, and dependencies

**Learn in:** [Lesson 09](lessons/09-systems.md) and the
[optional library module](optional/QUICKLISP.md).

- Give a reusable library its own package and ASDF system. Use a distinctive,
  project-related name rather than putting every definition in `CL-USER`.
- Export the intended API; keep implementation helpers internal. Access public
  symbols with `package:name`, not routine `package::internal` calls.
- A `%` prefix is optional documentation of intent. Package exports, rather than
  spelling tricks, define the ordinary public API boundary; neither is a security
  mechanism.
- Declare system dependencies and component order in the ASD. Do not hide setup
  requirements in your editor or personal startup file.
- Prefer qualified calls to third-party utilities where they make dependencies
  clearer. Avoid wholesale `:use` of many library packages and resulting conflicts.
- Keep dependency installation/loading outside reusable library operations.
  Do not add Quicklisp to the core capstone or mandatory test workflow.
- Use lowercase hyphenated file/system names. Package names in `defpackage` can
  follow the same source spelling even though the reader/REPL normally uses uppercase.

## 6. Records and object-oriented APIs

**Learn in:** [Lesson 12](lessons/12-objects.md).

- Start with a structure for a straightforward record; introduce classes and
  generic functions when extensible behavior justifies them.
- Use generated constructor/accessor names consistently. Lesson 12's `reading`
  structure provides `make-reading`, `reading-p`, `reading-value`, and related
  accessors, as well as `copy-reading`; these are not hand-written missing functions.
- A class accessor such as `task-title` is a normal function API. Where mutation
  is part of that API, use its `setf` accessor rather than adding repetitive
  `get-...`/`set-...` wrappers solely to imitate another language.
- Keep slot names descriptive and normally unadorned by the type's name inside
  the definition; qualified accessors can carry the type prefix.
- Document invariants and validation. Slot declarations and read-only public
  readers do not by themselves guarantee deeply immutable, validated objects.

## 7. Conditions, input boundaries, and recovery

**Learn in:** [Lesson 08](lessons/08-io.md),
[Lesson 10](lessons/10-testing.md), and [Lesson 11](lessons/11-conditions.md).

- Signal meaningful condition types for reusable domain failures. Callers should
  not have to parse the wording of an error message.
- Handle a condition where you can choose an appropriate policy. Do not hide
  programming bugs under a blanket `ignore-errors` or a fabricated success value.
- Offer restarts only where meaningful recovery exists. Let callers choose
  recovery rather than forcing interactive prompts in batch/library code.
- Parse user data according to a documented format. Never evaluate untrusted input;
  disabling read-time evaluation is not a general sandbox.
- Send CLI diagnostics to stderr and return nonzero failure status. Reusable core
  functions should not terminate the Lisp process.

## 8. Macros and declarations

**Learn in:** [Lesson 13](lessons/13-macros.md) and
[Lesson 14](lessons/14-performance.md).

- Prefer a function when evaluated arguments suffice. Do not write a macro simply
  to avoid a small function call or to display knowledge of macros.
- Document evaluation count/order and intentional bindings. Inspect expansions;
  use fresh temporary symbols to avoid accidental capture.
- Do not use `eval` to substitute for function calls, closure capture, or returning
  a macro expansion. Keep compile/load/run-time responsibilities explicit.
- Keep safety enabled while learning. Type declarations are promises, not input
  conversion or a replacement for validation. Measure before optimizing.

## 9. Docstrings, comments, and files

**Learn in:** [Lesson 03](lessons/03-functions.md),
[Lesson 09](lessons/09-systems.md), and [Lesson 10](lessons/10-testing.md).

- Give public functions concise docstrings describing arguments, returned values,
  invalid-input behavior, and any mutation/sharing that matters. Include secondary
  returned values in the contract.
- Prefer comments explaining decisions, assumptions, and pitfalls over comments
  restating an obvious operation.
- Common comment levels are `;` for a brief line-end note, `;;` for a standalone
  comment, and `;;;` for a larger file section. All start ordinary line comments;
  the number of semicolons is a presentation convention, not different execution.
- Use a consistent file order: package definition, related implementation files,
  then separate tests/entry scripts. Model the actual dependencies in ASDF rather
  than relying on whatever happens to be loaded at your REPL.
- Commit source, ASDs, tests, and necessary documentation. Keep local scratch data,
  compiled files, saved cores, caches, and personal configuration out of the course
  repository, following its `.gitignore` and your learner backup policy.

## 10. Tests and review checklist

**Learn in:** [Lesson 10](lessons/10-testing.md), with integration in
[Lesson 15](lessons/15-capstone.md).

Test ordinary, boundary, empty, and invalid cases as appropriate. Check returned
values, secondary values, mutation/ownership promises, and deterministic ordering.
Expected-error tests should fail when the expected error does not occur. Add a
regression test for a fixed bug, and rerun in a fresh process with startup files
disabled. Do not mistake successful printing or a repaired live image for correct
saved source.

Apply the relevant items before submitting each lab:

- [ ] Required API names are unchanged and other names follow the applicable conventions.
- [ ] Predicate/special-variable/constant names communicate their actual meaning.
- [ ] Layout shows structure; there are no literal-data mutation or ownership surprises.
- [ ] Public functions document their contract and return useful values.
- [ ] Dependencies and setup are explicit, not hidden in an editor or startup file.
- [ ] Expected failures are tested and not silently treated as success.
- [ ] Tests pass from saved source in a fresh process.
- [ ] Any deliberate style exception follows existing project style or has a clear reason.

Style supports correctness and communication; it is not a contest to use every
convention or abstraction in the earliest exercise. Apply only the features you
have reached, and use the linked lessons for explanations before adopting new ones.

## Further guidance

- The [Google Common Lisp Style Guide](https://google.github.io/styleguide/lispguide.html)
  is one detailed example of professional project conventions, not a universal
  specification. It includes organization-specific policies that this course
  does **not** adopt wholesale, including restrictions on CLOS usage.
- The [Common Lisp HyperSpec](https://www.lispworks.com/documentation/HyperSpec/Front/)
  specifies language behavior. Use it to distinguish a semantic requirement from
  a naming or formatting recommendation.
