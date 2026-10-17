# 15 — Capstone: a persistent task tracker

**Goal:** integrate the whole course into a tested Linux command-line application.
**Prerequisites:** 00–14. **Time:** 16–24 hours.

## Prerequisite recap

Bring together the main course's foundations:

- [Lessons 03](03-functions.md)–[07](07-collections.md): functions, scope, control flow, data ownership,
  sequence operations, and appropriate collection/equality choices.
- [Lessons 08](08-io.md)–[09](09-systems.md): resource-safe file I/O, validated data boundaries,
  packages, and explicit ASDF loading/build dependencies.
- [Lessons 10](10-testing.md)–[13](13-macros.md): reproducible tests, specific conditions and
  recovery policies, record/object APIs, and restrained use of macros.
- [Lesson 14](14-performance.md): measure before optimizing, preserve safety,
  and separate source delivery from implementation-specific compiled artifacts.

The capstone integrates these skills; it does not require every abstraction in
every function. Keep library behavior, file persistence, and the CLI boundary separate.

## Build your own before reading the reference

**CLI** means command-line interface; an **ID** is an identifier. Command names
such as `add`, `list`, and `done` below are arguments interpreted by our program,
not calls to similarly named Lisp functions. `FILE`, `TITLE`, and `ID` are usage
placeholders to replace with actual arguments.

Create a task tracker with a reusable core library and a separate CLI. A task has
a positive integer ID, a nonblank string title, and a boolean done status. IDs
are unique and increase monotonically. A store keeps tasks and its next ID.
Choose structures or classes and justify your choice. The reference uses
structures because record shape is simple and generic dispatch is not needed.

Required commands, using a data-file argument to avoid hidden global state:

```text
help
add  FILE TITLE
list FILE
done FILE ID
```

`TITLE` is one shell argument; quote titles containing spaces. `list` displays
tasks in ascending ID order. `done` is idempotent: marking an already-completed
task complete succeeds without changing other data. An absent ID is an error.
Missing files represent an empty store; malformed existing files are errors,
not silently replaced with an empty store. Reads do not create files.

## Persistence contract

Use a versioned representation, for example:

```lisp
(:version 1 :next-id 3 :tasks ((1 "Read chapter" nil) (2 "Run tests" t)))
```

This block shows **data-file contents**, not a form to execute at the REPL.
Use quotation if experimenting with it as a literal Lisp value. The keywords
`:version`, `:next-id`, and `:tasks` are field labels we choose for our file
protocol; they are not standard persistence operators. The reference format
requires that field order, as well as the version and value constraints below.

Validate version, record shape, nonblank title, positive/unique IDs, boolean
status, and `next-id > all existing IDs`. Check for extra top-level objects.
Disable read-time evaluation if using Lisp data. Never `eval` the representation.

The supplied implementation is for **trusted local files only**, single-process
use, and modest data sizes. Its reader is not hardened against malicious input
or resource exhaustion. It validates fully before replacing an in-memory store
and validates before opening a destination for writing, but directly supersedes
the destination: a crash or I/O failure during writing can lose data. Do not use
it for important records without adding safe replacement/backups. There is no
concurrency control, transaction log, or symlink defense. Document these limits
honestly; do not label it production-safe.

## Public API and separation

Expose operations like `make-store`, `add-task`, `complete-task`, `all-tasks`,
`save-store`, and `load-store`. Use private helpers for format validation. Use
custom conditions for bad data and missing IDs. The CLI translates user mistakes
to stderr plus a nonzero exit code; the core library does not terminate SBCL.

Decide who owns task objects returned by the library. The reference returns copies
and copies titles so callers cannot mutate its storage through public results.
A shallow record copy alone would still share a mutable string title.

## Exercises

Work through these steps using the requirements above and acceptance checklist below.

1. Write contracts and tests for ID assignment, ordering, and completion.
2. Implement the in-memory core; keep all file I/O out initially.
3. Add conversion to/from versioned data and invalid-data tests.
4. Add file operations, including a round-trip test in a temporary location.
5. Add CLI parsing with strict arity and integer checks.
6. Define ASDF systems and test operation; run in a clean process.
7. Write usage notes and a threat/limitations section.
8. Review the reference only after your version works; explain differences.

## Reference implementation

From the course directory:

```sh
sbcl --noinform --no-sysinit --no-userinit --script capstone/run-tests.lisp
sbcl --noinform --no-sysinit --no-userinit --script capstone/cli.lisp help
```

Use a new file that you are willing to create/overwrite:

```sh
sbcl --noinform --no-sysinit --no-userinit --script capstone/cli.lisp add work/tasks.sexp "Read the conditions lesson"
sbcl --noinform --no-sysinit --no-userinit --script capstone/cli.lisp list work/tasks.sexp
sbcl --noinform --no-sysinit --no-userinit --script capstone/cli.lisp done work/tasks.sexp 1
```

The `work` directory must exist. CLI execution is SBCL-specific (`sb-ext:*posix-argv*`
and `sb-ext:exit`); core operations use standard Common Lisp with SBCL's `:utf-8`
external-format designator for file encoding. Tests use
ASDF/UIOP for system loading and temporary-file handling. Scripts find sibling
files relative to their own locations, not a hardcoded home directory.

## Reading the reference source

The reference integrates earlier lessons, but also uses a few small facilities
not needed by their isolated labs. Use this guide rather than guessing from
unfamiliar names. Names defined by the application are not new language features.

### Records and validation (`package.lisp`, `tasks.lisp`)

| Construct | Meaning or origin |
|---|---|
| `make-store`, `add-task`, `complete-task`, `all-tasks`, `save-store`, `load-store` | Public application functions, defined in `tasks.lisp`; not Common Lisp built-ins |
| `task-id`, `task-title`, `task-done-p`, `store-next-id`, `store-tasks` | Accessors generated by `defstruct` (Lesson 12) |
| `:constructor %make-task (id title done-p)` | Structure option defining a positional constructor with that parameter list, instead of the default keyword constructor |
| `:constructor make-store ()` | Constructor taking no arguments; slot defaults initialize a store |
| `%make-task`, `reject-data`, `valid-title-p`, `detached-task`, `proper-list-p`, `store-data`, `data-store` | Private functions/constructor defined in this file; `%` is a naming convention, not special evaluation syntax |
| `bad-data`, `missing-task`, their generated readers | Application-defined condition types/accessors from `define-condition` (Lesson 11) |
| `typep` | Test an object against a type supplied as data; `'(integer 1 *)` means positive integers, unlike unquoted type syntax in `check-type` |
| `stringp`, `listp` | Predicates for strings and cons-or-`nil` lists; `listp` alone does not guarantee a proper, acyclic list |
| `list-length` | Length for proper lists, `nil` for circular lists, and an error for an improper dotted list; used with `handler-case` to validate shape |
| `first` through `sixth` | List-element accessors introduced in Lesson 05 |
| `member` | Search a list with a chosen equality test; returns the matching tail or `nil`, not necessarily `t` |
| `max` | Return the largest numeric argument; used to validate the next ID |
| Multiple `setf` pairs | `(setf place-1 value-1 place-2 value-2)` performs assignments in order |

### Persistence and readers (`tasks.lisp`)

| Construct | Meaning or origin |
|---|---|
| `with-standard-io-syntax` | Temporarily establishes standard reader/printer settings for its body; not a sandbox |
| `*print-readably*` | Request output readable back by Lisp, or an error if the object cannot be printed readably |
| `write` with `:stream` | Write a Lisp object's printed representation to the selected stream; unlike `write-string`, which emits string characters |
| `terpri` | Write a newline to an optional stream |
| `*read-eval*`, `gensym`, `read` EOF arguments | Reader-safety setting, fresh sentinel, and EOF protocol taught in Lesson 08; explicitly rebound inside `with-standard-io-syntax` |
| `*package*`, `find-package` | Current reader package and package lookup, taught in Lesson 09 |
| `reader-error`, `end-of-file` | Built-in condition types handled at the file boundary, not application-defined functions |

### Build and tests (`course-tasks.asd`, test scripts)

| Construct | Meaning or origin |
|---|---|
| `:in-order-to` with `asdf:test-op` | Delegate the main system's test operation to its `/tests` system |
| `:perform` | Supply code to execute for an ASDF operation; `operation` and `component` are its bound parameters |
| `uiop:symbol-call` | Call a function identified by package and symbol-name designators after that package is loaded |
| `(declare (ignore ...))` | Mark deliberately unused bindings (Lesson 11), not a run-time call |
| `*load-truename*` | Pathname of the file currently being loaded; `merge-pathnames` uses it to locate sibling files without assuming the working directory |
| `check`, `signals`, `check-bad-file`, `run-tests` | Helpers defined in the test source; `signals` is our small error-checking macro, not a standard operator |
| `string` | In the test `(string #\Tab)`, convert a character to a one-character string; distinct from the type name `string` in a declaration |
| `write-string` | Emit the supplied characters without Lisp string quoting; used to create deliberately malformed test files |
| `uiop:with-temporary-file` | Bind a temporary pathname/stream; `:keep nil` requests cleanup; `:pathname`/`:stream` select the names to bind |
| `close`, `delete-file` | Explicit stream closure and removal of temporary files, introduced in Lesson 08 |
| `#1=` and `#1#` inside a test string | Reader labels: define and refer back to an object, allowing a circular list; that particular file must be rejected |
| `uiop:run-program` | Launch a subprocess; with string output/error capture and ignored error status, return output, error text, and exit status for assertions |
| `uiop:getenv`, `uiop:temporary-directory`, `uiop:read-file-string` | Read an environment variable, locate a temporary directory, and read file text; these are UIOP utilities, not ANSI Lisp |
| `search` | Return the starting index of one sequence within another, or `nil`; used to check output messages |

### CLI boundary (`cli.lisp`)

`sb-ext:*posix-argv*` is SBCL's command-line argument list; `rest` drops the
implementation's leading program argument in this script workflow.
`sb-ext:exit :code` terminates the process with the chosen integer status.
The driver's `main` and `usage` are application functions. Its `destructuring-bind`
uses Lesson 03's `&optional` convention for the optional third argument. All
parsing, collection access, conditions, and formatting otherwise reuse
[Lessons 03](03-functions.md), [05–08](08-io.md), and [11](11-conditions.md).

## Acceptance checklist

- [ ] First task receives ID 1; later tasks receive increasing IDs.
- [ ] Empty store lists nothing; output ordering is deterministic.
- [ ] Completion affects only the chosen task, including after save/load.
- [ ] A returned record/title cannot mutate the internal store.
- [ ] Empty/whitespace titles, invalid IDs, malformed files, duplicate IDs, unsupported
  versions, bad next IDs, nonboolean statuses, and extra objects fail clearly.
- [ ] Missing file means empty store; malformed existing file never means empty store.
- [ ] Read-time evaluation is rejected; document that this is not general sandboxing.
- [ ] Wrong CLI arity/command yields nonzero status; help succeeds without a file.
- [ ] Tests and commands run without user init files or editor support.

## Rubric, 100 points

| Area | Points |
|---|---:|
| Correct core behavior and stable IDs | 25 |
| Persistence validation and explicit failure behavior | 20 |
| Automated normal, boundary, and regression tests | 20 |
| Packages, ASDF, separation, API ownership | 15 |
| Usable CLI, documented commands and exit codes | 10 |
| Reasoning, readability, documented limitations | 10 |

Do not add a macro, class hierarchy, or restart solely to display knowledge.
Explain where these tools would help a future importer or extensible renderer.

## Optional extensions

Add deletion without reusing IDs; filtering by completion; an importer offering
`skip-record`; safe same-directory temp-file replacement (state durability limits);
a dedicated bounded parser for untrusted input; or JSON via a deliberately chosen
library. Each extension needs a revised contract and tests. Threads, GUI, and web
interfaces belong in subsequent projects, not the required capstone.
