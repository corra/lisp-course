# Optional module — Quicklisp, Alexandria, and FiveAM

**Placement:** start after Lesson 09; complete the test-framework section after
Lesson 10. The macro extension belongs after Lesson 13. **Time:** 4–6 hours.

**Goals:** install/load dependencies explicitly, distinguish systems from
packages, use a utility library and a test framework, and record the environment.
No editor integration is required. This module does not change the dependency-free
core course or capstone. Network access is needed for installation and uncached
libraries; neither the core test command nor its CI job installs Quicklisp.

## Prerequisite recap

- [Lesson 09](../lessons/09-systems.md): packages control names; ASDF describes
  systems, source order, and dependencies. A dependency declaration does not
  obtain a missing library by itself.
- [Sequences](../lessons/06-sequences.md), [collections](../lessons/07-collections.md),
  and [I/O](../lessons/08-io.md): explicit equality, ordering,
  ownership, and text policies still matter when using a utility library.
- Before the testing section, complete [Lesson 10](../lessons/10-testing.md):
  tests must check behavior and propagate failure to a nonzero batch exit status.

This module adds explicit library acquisition and named test reporting without
replacing the core course's editor-independent, dependency-free workflow.

## 1. Three different responsibilities

| Tool | Responsibility | Not its job |
|---|---|---|
| SBCL | Implements and compiles Common Lisp | Distributing the whole library ecosystem |
| ASDF (with UIOP) | Describes systems, builds dependencies, runs configured operations | Obtaining arbitrary missing libraries by itself |
| Quicklisp | Obtains library releases and connects them to system loading | An editor, language feature, or automatic project lockfile |

In this module the system `"alexandria"` supplies the `ALEXANDRIA` package, and
`"fiveam"` supplies a package accessible as `FIVEAM` (also commonly `5AM`). These
names happen to correspond, but that is not guaranteed for other libraries.
Inspect a library's documentation, license, ASD, supported implementations, and
source before adding it. Transitive dependencies matter too.

**Reading prerequisites:** package/keyword notation is taught in
[Lesson 09](../lessons/09-systems.md); the string/hash-table examples use
[Lessons 06–08](../lessons/07-collections.md). The code links below contain
worked implementations, not functions magically installed by the course.

## 2. Install once, without changing the required startup workflow

These are **learner instructions**, not actions performed by checking out the
course. First check whether you already have Quicklisp. A common location is
`~/quicklisp/setup.lisp`; a custom installation may be elsewhere. Reuse a known,
trusted installation rather than installing over it. Back up existing startup
configuration before any optional edits.

Install `curl` and GnuPG if needed; see [the tooling guide](TOOLING.md). Download
the bootstrap source, signature, and signing key from the
[official installation page](https://www.quicklisp.org/beta/). From the course
directory, these commands keep the downloaded files out of version control:

```sh
mkdir -p work/quicklisp-bootstrap/gnupg
chmod 700 work/quicklisp-bootstrap/gnupg
curl --fail --location --proto '=https' --proto-redir '=https' \
  --output work/quicklisp-bootstrap/quicklisp.lisp \
  https://beta.quicklisp.org/quicklisp.lisp
curl --fail --location --proto '=https' --proto-redir '=https' \
  --output work/quicklisp-bootstrap/quicklisp.lisp.asc \
  https://beta.quicklisp.org/quicklisp.lisp.asc
curl --fail --location --proto '=https' --proto-redir '=https' \
  --output work/quicklisp-bootstrap/release-key.txt \
  https://beta.quicklisp.org/release-key.txt
gpg --homedir work/quicklisp-bootstrap/gnupg --show-keys --with-fingerprint \
  work/quicklisp-bootstrap/release-key.txt
```

Shell `\` continues a command on the next line. `chmod 700` restricts that
directory to its owner. The `curl` flags fail on HTTP errors, follow redirects,
restrict initial/redirect protocols to HTTPS, and select a destination file.
GnuPG's `--homedir` uses this isolated keyring, `--show-keys --with-fingerprint`
displays the downloaded key, `--import` adds it there, and `--verify` checks the
detached signature against the source file. These are shell tools, not Lisp forms.

Compare the **full** fingerprint with the official page, preferably through an
independently trusted source as well. At the time this module was written the
published fingerprint was `D7A3 489D DEFE 32B7 D0E7 CC61 3079 65AB 028B 5FF7`.
Do not silently accept a changed key. Downloading the key and file from the same
site does not provide an independent trust anchor. After checking:

```sh
gpg --homedir work/quicklisp-bootstrap/gnupg --import \
  work/quicklisp-bootstrap/release-key.txt
gpg --homedir work/quicklisp-bootstrap/gnupg --verify \
  work/quicklisp-bootstrap/quicklisp.lisp.asc \
  work/quicklisp-bootstrap/quicklisp.lisp
```

Stop on download, signature, or fingerprint problems. A valid signature proves
the file matches the key, not that every line is safe. Read the bootstrap source
and installation documentation before loading it. Do not pipe a download into
SBCL, disable TLS verification, or run your Lisp session as root.

**Transport caveat:** HTTPS for the bootstrap does not establish end-to-end HTTPS
for later downloads. Traditional Quicklisp clients use HTTP for some subsequent
metadata/archive requests. Check the current client's behavior and your network
policy before installing. If authenticated HTTPS throughout is required, stop and
use an approved dependency-acquisition workflow; do not treat this module as a
secure supply-chain solution. Signature checking of the bootstrap alone does not
authenticate all future dependencies.

For a new installation, start a clean session:

```sh
sbcl --noinform --no-sysinit --no-userinit --load work/quicklisp-bootstrap/quicklisp.lisp
```

At the Lisp REPL, after accepting the documented trust/network limitations:

```lisp
(quicklisp-quickstart:install
 :path (merge-pathnames "quicklisp/" (user-homedir-pathname)))
```

This creates a user-local installation, not a system-wide package. Choose a
different new directory with `:path` if needed; record it. Do not run this against
an existing installation. Installation is a one-time operation; later sessions
load the installed `setup.lisp`, not the bootstrap again.

`quicklisp-quickstart:install` belongs to the downloaded bootstrap package;
`:path` selects its installation directory. `user-homedir-pathname` and
`merge-pathnames` are the pathname functions explained in
[Lesson 08](../lessons/08-io.md#pathnames).

## 3. Load explicitly in a clean session

Start SBCL with the same `--no-sysinit --no-userinit` flags as the core course.
For the default installation:

```lisp
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(ql:system-apropos "alexandria")
(ql:quickload '("alexandria" "fiveam"))
```

Evaluate the `load` form first. The `QL` package must exist before the reader
encounters `ql:quickload`. Combining both forms inside a single `progn` does not
solve this: Lisp must first read the whole `progn`. The optional driver uses
separate top-level forms for that reason.

`ql:quickload` may download missing releases and compile them. Once dependencies
are locally installed, ASDF can load the registered systems. Application ASDs
declare `:depends-on`; do not put `ql:quickload` inside reusable library functions.
Quicklisp installation, system definition, and run-time work are separate stages.

`ql:system-apropos` searches available system names; `ql:quickload` obtains and
loads the requested systems. The quoted list passes two system-name strings,
not source forms to execute. These are Quicklisp functions, not ANSI Lisp.

Do **not** run `ql:add-to-init-file` for the required course workflow. It is an
optional personal convenience, writes startup configuration, and is bypassed by
`--no-userinit` anyway. Explicit setup is easier to reproduce and troubleshoot.

## 4. Alexandria: reuse utilities without hiding the lesson

After loading the systems:

```lisp
(alexandria:iota 4 :start 1) ; (1 2 3 4)
(let ((counts (make-hash-table :test #'equal)))
  (setf (gethash "lisp" counts) 2)
  (alexandria:hash-table-alist counts)) ; (("lisp" . 2))
```

`alexandria:iota` constructs a numeric sequence of the given length; `:start 1`
chooses its first value. `alexandria:hash-table-alist` converts table entries to
key/value cons pairs in a newly allocated alist (the keys/values themselves are
not recursively copied). Standard `make-hash-table`, `gethash`, and `setf` retain
the meanings taught in Lesson 07.

Read the documentation for ownership and ordering guarantees. Hash-table
conversion does not give deterministic ordering for multiple keys: sort the
result explicitly. Prefer qualified names such as `alexandria:iota` over importing
an entire utility package with `:use`; this makes dependencies visible and reduces
name conflicts.

The [sample library](libraries/report.lisp) counts already-tokenized words and
uses `alexandria:hash-table-alist` for presentation. It retains explicit policies
for case, sorting ties, and string ownership. Compare it with your milestone-2
code; using a library does not remove responsibility for those decisions.

After Lesson 13, try replacing a hand-written temporary-binding pattern with
`alexandria:with-gensyms` or `alexandria:once-only`. Explain the expansion first;
these utilities are not substitutes for understanding macro evaluation.

`with-gensyms` binds expander variables to fresh symbols; `once-only` helps build
an expansion that evaluates the caller's selected forms once and reuses their
values. Their detailed syntax is in the linked Alexandria manual; they are
optional extensions, not unexplained requirements for this module's tests.

After completing Lesson 13, try this concrete `once-only` example in a session
where Alexandria is already loaded:

```lisp
(defmacro twice-with-library (expression)
  (alexandria:once-only (expression)
    `(+ ,expression ,expression)))

(let ((n 0))
  (list (twice-with-library (incf n)) n)) ; (2 1)
```

The helper constructs temporary-binding code for the expansion; it does not
evaluate `(incf n)` during expansion. Inspect the expansion and compare it with
Lesson 13's hand-written `gensym` version. This is a macro-writing exercise,
not a suggestion that ordinary arithmetic doubling needs a macro.

## 5. FiveAM: named tests, suites, and reports

In a session where FiveAM is loaded:

```lisp
(defpackage #:course-test-demo (:use #:cl))
(in-package #:course-test-demo)
(fiveam:def-suite arithmetic)
(fiveam:in-suite arithmetic)
(fiveam:test exact-addition
  (fiveam:is (= 1/2 (+ 1/3 1/6))))
(fiveam:run! 'arithmetic)
```

`def-suite` groups tests, `in-suite` selects where subsequent tests belong,
`test` names a test, `is` checks an assertion, and `signals` checks an expected
condition. These are library facilities, not new Common Lisp operators.

`fiveam:run!` runs the selected test/suite and prints a report. `arithmetic` and
`exact-addition` are names defined by the example, not predefined FiveAM tests.

Add a named boundary/error test in that same demonstration package/suite:

```lisp
(fiveam:test arithmetic-and-input-boundary
  (fiveam:is (= 0 (+ 0 0)))
  (fiveam:signals parse-error
    (parse-integer "not-an-integer")))

(fiveam:run! 'arithmetic)
```

`parse-error` is the built-in condition for this invalid numeric text (Lesson 08).
`signals` fails if that specific kind of error does not occur. The plain
`run!` report is useful interactively; use the supplied batch entry point below
when a failed test must become an unsuccessful process exit.

Printed failures alone do not guarantee a failed process exit. The supplied
ASDF test entry point uses `fiveam:run`, prints with `fiveam:explain!`, checks
`fiveam:results-status`, and signals an error on failure or skipped checks. It
also disables interactive failure/error debugging during batch runs. Thus the
normal SBCL script error path gives an unsuccessful exit status.

## 6. Run the complete optional example

From the course directory, with Quicklisp installed in the default location:

```sh
sbcl --noinform --no-sysinit --no-userinit --script optional/run-library-tests.lisp
```

For a custom installation (including paths containing spaces):

```sh
COURSE_QUICKLISP_SETUP="/absolute/path/to/quicklisp/setup.lisp" \
  sbcl --noinform --no-sysinit --no-userinit --script optional/run-library-tests.lisp
```

The driver explicitly loads setup, obtains Alexandria/FiveAM if missing, records
versions and source locations, loads the course ASDs by explicit pathname, and
invokes `asdf:test-system`. The test system also exercises the unchanged capstone
through its public API. Nothing in `examples/run-all.lisp` loads this driver.

### Reading the supplied library and driver

`word-count-report` is our function in `libraries/report.lisp`; `run-tests` is
our entry point in `libraries/tests.lisp`, not a standard FiveAM function. Both
are named/exported by their respective package definitions. Most other forms
reuse Lessons 03–11. The additional introspection/configuration helpers are:

| Name or option | Meaning |
|---|---|
| `fiveam:*debug-on-error*`, `fiveam:*debug-on-failure*` | Special variables controlling interactive debugging; the test entry point binds them false for automation |
| `uiop:getenv` | Get an environment variable's string value, or `nil` when unset; `or` chooses a fallback |
| `COURSE_QUICKLISP_SETUP` | Our optional environment-variable name, not a standard Quicklisp setting |
| `lisp-implementation-type`, `lisp-implementation-version` | Standard functions identifying the running Lisp implementation |
| `asdf:asdf-version`, `ql:client-version` | Report the ASDF and Quicklisp-client versions |
| `ql-dist:all-dists`, `ql-dist:name`, `ql-dist:version` | List installed distribution objects and obtain each one's name/version |
| `asdf:find-system`, `asdf:component-version`, `asdf:system-source-directory` | Look up a registered system, inspect its version metadata, and locate its sources |
| `*load-truename*` | Pathname of the currently loading script, used to find sibling files; see the [capstone source guide](../lessons/15-capstone.md#reading-the-reference-source) |
| `:depends-on`, `:in-order-to`, `:perform`, `asdf:test-op`, `uiop:symbol-call` | System dependencies and test delegation, explained in [Lesson 09](../lessons/09-systems.md) and the capstone source guide |

In the custom-location shell command, `NAME="value" command` sets an environment
variable for that command. It does not assign a Lisp variable.

## 7. Reproducibility and updates

Record the command, SBCL/ASDF/client versions, distribution name/version, library
system versions, and actual source locations. The driver prints these; save them:

```sh
mkdir -p work
sbcl --noinform --no-sysinit --no-userinit --script optional/run-library-tests.lisp \
  > work/library-environment.txt 2>&1
```

Shell `>` writes stdout to the file (replacing it), and `2>&1` sends stderr to
the same destination. `echo $?` used in the lab prints the preceding command's
exit status: zero normally means success, a nonzero value means failure.

This file is an environment report, **not** a lockfile or backup. System versions
can be incomplete; a dated Quicklisp distribution also does not describe local
overrides or edited sources. Record overrides and exact source revisions/hashes
when repeatability matters. Do not commit an entire home-directory installation.

`ql:update-dist` changes library releases; `ql:update-client` changes Quicklisp
itself. Neither is part of the test driver. Make intentional updates in a separate
change, retain the previous environment information, and rerun tests. For larger
projects investigate [Qlot](https://github.com/fukamachi/qlot) or a reviewed vendoring
workflow for project-local dependency management. These are advanced alternatives,
not another mandatory setup step, and do not automatically solve all trust issues.

## 8. Verify setup, diagnose failures, and recover

### Check installation separately from library loading

Confirm the installed setup file exists. For a default installation, in a
clean REPL use `(probe-file (merge-pathnames "quicklisp/setup.lisp"
(user-homedir-pathname)))`. A returned pathname confirms a file exists, not that
the entire installation is healthy. A missing file means you must locate the
actual installation or finish the one-time install, not repeatedly reload the
bootstrap hoping that `QL` will appear.

Check loading in a new terminal process:

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load "$HOME/quicklisp/setup.lisp" \
  --eval '(format t "Quicklisp client: ~A~%" (ql:client-version))'
```

For a custom path, substitute its actual `setup.lisp` pathname. This command
loads installed code; it does not install or update Quicklisp. If a tool needs
a newer ASDF, explicitly load the reviewed ASDF copy **before** setup, following
the [tooling instructions](TOOLING.md#when-an-integration-needs-a-newer-asdf).

Next load the libraries with diagnostics visible:

```lisp
(ql:quickload '("alexandria" "fiveam") :verbose t)
(asdf:system-source-directory "alexandria")
(asdf:system-source-directory "fiveam")
```

`:verbose t` shows compilation/loading details that Quicklisp may otherwise
abbreviate. The source directories identify what ASDF actually selected;
a local checkout or distribution package can differ from what you expected.
Run `optional/run-library-tests.lisp` afterward and preserve its environment
report along with the exact failure output if a problem remains.

### Failure-to-layer checklist

| Symptom | Likely layer and next action |
|---|---|
| Signature/fingerprint verification fails | Stop before loading the bootstrap; recheck trusted source/key and publisher guidance, not a weaker verification mode |
| `QUICKLISP-QUICKSTART` missing | Bootstrap was not loaded into this process; installed sessions instead load `setup.lisp` |
| `QL` package missing | Installed setup was not loaded before a qualified form was read; check path, startup flags, and separate top-level forms |
| Download/network failure | Inspect URL, proxy, DNS, certificate/transport policy, and available network; do not disable TLS checks or silently switch to a less trusted source |
| System not found | Check exact system name with `ql:system-apropos`, not just a project/package nickname |
| Compile failure | Read the first real compiler error with verbose output; check implementation/ASDF/library compatibility and actual source directory |
| `ALEXANDRIA`/`FIVEAM` package missing | The matching system did not finish loading in this session, or the name is misspelled |
| Optional driver says setup not found | Set `COURSE_QUICKLISP_SETUP` to an existing absolute `setup.lisp` path; that variable is used by this driver, not every external tool |
| Tests fail but setup/library loads succeed | Treat it as a behavior/version issue; do not repeatedly reinstall the bootstrap |

Quicklisp's traditional HTTP behavior is described in section 2. A TLS-aware
bootstrap download does not eliminate that later transport limitation. If your
network/security policy disallows the client's requests, use an approved
acquisition workflow instead of weakening the policy.

### Offline checks and reversible changes

The core suite is offline-capable without Quicklisp. To establish whether your
**optional** environment is also ready offline, first load/install the selected
systems online, record versions/source locations, then rerun the optional driver
with the network unavailable. If it still requests uncached metadata/releases,
the optional environment is not yet offline-complete; do not claim the core's
offline guarantee covers it automatically.

Before an intentional library/client update, retain the previous environment
report and recoverable source/install snapshot. Do not rely on a live REPL to
undo an update. Restart after changing dependency versions; already loaded
definitions can conceal what a fresh process will see. Update procedures and
distribution-version selection are documented by Quicklisp; Qlot/vendoring are
further-study options, not additional installation requirements in this module.

To stop using Quicklisp for a session, start SBCL with the documented clean flags
and omit the setup load. If you personally added an init-file block, back up the
file and remove only that block. Do not delete an entire Lisp init file or a
shared Quicklisp directory used by other projects. Avoid in-place client/source
reinstalls as a first troubleshooting step.

## Lab — Adopt dependencies deliberately

### Exercises

1. Install/reuse Quicklisp, then load it explicitly with user startup disabled.
2. Run the sample optional test system. Explain both `:depends-on` declarations.
3. Write one Alexandria-backed utility and test normal, empty, invalid, and
   ownership cases with FiveAM. Keep it outside the core capstone.
4. Temporarily add a failing assertion to your own test copy. Verify a nonzero
   shell exit status (`echo $?` immediately after the command), then repair it.
5. Save an environment report and explain why it is not a lockfile.
6. Run the core suite again with startup disabled, proving independence from the
   optional setup. Compare named test reports with the original `assert` approach.

### Acceptance checklist

- [ ] Exercise 1: Quicklisp loads explicitly in a clean session without relying
  on user startup configuration.
- [ ] Exercise 2: the optional test system passes, and you can explain its
  declared dependencies.
- [ ] Exercise 3: your utility's FiveAM tests cover normal, empty, invalid, and
  ownership cases without changing the core capstone.
- [ ] Exercise 4: a deliberate test failure produces a nonzero exit status;
  the repaired tests pass.
- [ ] Exercise 5: the saved environment report identifies dependencies, and you
  explain why it is not a lockfile.
- [ ] Exercise 6: the original core suite passes without loading Quicklisp;
  you compare its assertion reporting with the optional named test reports.

### Review questions

1. Why can a `QL` package error occur before a load expression runs?
2. Does adding Quicklisp to `.sbclrc` affect `--no-userinit` sessions?
3. What exactly would another learner need to reproduce your dependency environment?

## References

- [Quicklisp installation and commands](https://www.quicklisp.org/beta/)
- [Alexandria manual](https://alexandria.common-lisp.dev/draft/alexandria.html)
- [FiveAM manual](https://fiveam.common-lisp.dev/docs/)
- [ASDF manual](https://asdf.common-lisp.dev/asdf.html)
