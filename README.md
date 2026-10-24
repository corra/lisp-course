# Common Lisp on Linux: a practical programming course

A complete, editor-independent introduction to **Common Lisp**, using **SBCL**
(Steel Bank Common Lisp) on Linux. You need introductory programming experience,
but no Lisp knowledge. This is Common Lisp, not Scheme, Racket, Clojure, or Emacs
Lisp; examples from those languages are not necessarily interchangeable.

## Start here

1. Read [the course guide](COURSE.md).
2. Complete [Lesson 00: environment and workflow](lessons/00-environment.md).
3. Work through the lessons in order, attempting exercises before solutions.

Follow the [core learning path](COURSE.md#core-path-versus-reference-material).
Sections marked optional reference or later practice are not prerequisites for
the current lab. In particular, explicit special declarations are not part of
your first functions lesson; closures are revisited when functions-as-values
are taught in Lesson 06.

The [example-reading conventions](COURSE.md#how-examples-introduce-names-and-notation)
distinguish required concepts, previews, placeholders, and application-defined
names. Use the [construct index](REFERENCE.md#where-constructs-are-taught) to find
where a form or notation is taught.

The required tools are a terminal, SBCL, and **any plain-text editor**. No editor
commands, structural-editing plugins, SLIME, SLY, language server, Quicklisp, or
third-party Lisp libraries are required for the **core course**. All core labs
work offline once SBCL and these files are installed. Optional modules add
Quicklisp, Alexandria, FiveAM, and workflow conveniences without changing that
baseline. Their installation may require network access.

## Contents

- [Course guide and assessment](COURSE.md)
- [Common Lisp style guide](STYLE.md): naming, layout, APIs, ownership, and review
- [00 — Starter terminology, Linux setup, and reproducible workflow](lessons/00-environment.md)
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

### Optional environment and ecosystem modules

- [Numeric details](optional/NUMBERS.md): rounding policies and less common numeric forms.
- [Dynamic scope and special declarations](optional/DYNAMIC-SCOPE.md): a reference
  after Lesson 08, not required before learning local variables and functions.
- [Practical tools and configuration](optional/TOOLING.md): Git, `rlwrap`, local
  documentation, development settings, `.gitignore`, and continuous integration.
- [Quicklisp, Alexandria, and FiveAM](optional/QUICKLISP.md): explicit setup,
  dependency management, a utility-library example, and a named test suite.
  Start after Lesson 09; finish the testing material after Lesson 10.
- [Editors and integrations](optional/EDITORS.md): editor installation choices,
  a shared greeting/reload/debugger check, and complete setup paths for
  [Emacs with SLIME/SLY](optional/editors/EMACS.md),
  [Vim/Neovim with Vlime or SLIMV](optional/editors/VIM.md), and
  [VS Code/VSCodium with Alive](optional/editors/VSCODE.md).

No course script installs an editor, alters `.sbclrc`, or bootstraps Quicklisp.
The explicitly selected optional library driver can download missing libraries
through an existing Quicklisp installation; it is not part of the core suite.

The optional guides include prerequisites, explicit startup configuration,
verification, failure diagnosis, and reversible setup instructions. The
[editor-check source](optional/editor-check.lisp) requires no external libraries.
Editor integration recipes are based on upstream documentation; complete the
shared verification exercise on your own editor/OS combination.

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

After completing the optional Quicklisp setup, run its **separate** suite:

```sh
sbcl --noinform --no-sysinit --no-userinit --script optional/run-library-tests.lisp
```

See [the optional module](optional/QUICKLISP.md) for custom setup paths, trust and
network caveats, dependency reporting, and failure handling. The
[CI workflow](.github/workflows/test.yml) runs only the dependency-free core suite.

Shell blocks are Linux terminal commands. Lisp blocks contain Lisp source only:
do not type a displayed REPL prompt into a file. Unless specified otherwise,
commands assume this directory is the working directory.

## Validation

The full reference suite was checked on Linux with **SBCL 2.6.9**, with site and
user initialization disabled. It covers language examples, exercise solutions,
capstone behavior and malformed files, plus 22 CLI subprocess scenarios. CLI
tests execute from a different working directory. You can select a different
SBCL binary for subprocess tests using the `COURSE_SBCL` environment variable.

The separate optional example was also checked with Alexandria 1.0.1 and FiveAM
1.4.3 from Quicklisp distribution `2026-01-01`: all 11 checks passed. These are
tested versions, not a dependency lock or a promise about future releases.
The hosted GitHub Actions job must be run on GitHub to validate that environment.
It installs Ubuntu's packaged SBCL, which is usually several releases older than
2.6.9. The course relies on longstanding features, and the job prints the version
it used; a pass there checks that older release, not 2.6.9.

See [the independent review record](REVIEW.md) for the 2026-10-20 findings,
their fixes, and additional regression checks.

## License

The course text and source code are available under the [MIT License](LICENSE).
