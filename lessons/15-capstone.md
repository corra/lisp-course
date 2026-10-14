# 15 — Capstone: a persistent task tracker

**Goal:** integrate the whole course into a tested Linux command-line application.
**Prerequisites:** 00–14. **Time:** 16–24 hours.

## Build your own before reading the reference

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

## Suggested development sequence

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

## Acceptance tests

- First task receives ID 1; later tasks receive increasing IDs.
- Empty store lists nothing; output ordering is deterministic.
- Completion affects only the chosen task, including after save/load.
- A returned record/title cannot mutate the internal store.
- Empty/whitespace titles, invalid IDs, malformed files, duplicate IDs, unsupported
  versions, bad next IDs, nonboolean statuses, and extra objects fail clearly.
- Missing file means empty store; malformed existing file never means empty store.
- Read-time evaluation is rejected; document that this is not general sandboxing.
- Wrong CLI arity/command yields nonzero status; help succeeds without a file.
- Tests and commands run without user init files or editor support.

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
