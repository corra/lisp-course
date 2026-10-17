# Practical tools and configuration

**Placement:** Git and terminal guidance alongside Lesson 00; compilation settings
after Lesson 10; CI after Lesson 09/10. **Time:** 2–3 hours plus practice.
Only SBCL, a terminal, and a plain-text editor remain necessary for core labs.
These additions improve workflow; none makes an editor integration mandatory.

## Prerequisite recap

- [Lesson 00](../lessons/00-environment.md): the terminal launches SBCL, source
  lives in plain-text files, and scripts differ from interactive REPL sessions.
- A saved file is the reproducible artifact; a live REPL can contain unsaved
  definitions or state that disappears when the process ends.
- For this guide's later build/debugging sections, first complete
  [Lesson 09](../lessons/09-systems.md) and [Lesson 10](../lessons/10-testing.md): explicit system loading and automated
  fresh-process tests keep workstation conveniences from becoming hidden requirements.

Use the early terminal/Git sections during setup, then return to the later
configuration and CI sections at their stated placement points.

## 1. Optional Linux packages

Install only tools you want, using your distribution's package manager:

```sh
# Debian / Ubuntu
sudo apt install git rlwrap curl gnupg
```

```sh
# Fedora
sudo dnf install git rlwrap curl gnupg2
```

```sh
# Arch Linux
sudo pacman -S git rlwrap curl gnupg
```

Git is for history; `rlwrap` is a terminal convenience; `curl` and GnuPG support
the optional verified Quicklisp bootstrap. They are not Lisp libraries. Package
names/availability can vary by distribution release. Do not run SBCL as root.

The shell setup commands and `sudo` are explained in [Lesson 00](../lessons/00-environment.md).
Here `rlwrap program arguments...` wraps that program's terminal input; it does
not change the Lisp language or the meaning of SBCL's startup flags.

After installing the tools you selected, verify them independently:

```sh
git --version
rlwrap --version
curl --version
gpg --version
```

If one is missing, revisit that package's installation; do not reinstall SBCL
to fix a missing shell utility. Editor package instructions are in the
[editor setup routes](EDITORS.md#installation-and-configuration-routes).

## 2. Terminal history with rlwrap

```sh
rlwrap sbcl --noinform --no-sysinit --no-userinit
```

This can add line editing and persistent history to an otherwise basic terminal
REPL. It does not provide Lisp-aware compilation, a graphical debugger, or reliable
multiline structural editing. Keep program definitions in source files, not only
history. Do not put secrets in a history-recording REPL. If you later use an IDE
connection, it normally starts SBCL directly; adding `rlwrap` there is unnecessary
and can interfere with subprocess communication.

If SBCL was built with a suitable interactive line-editing facility, an external
wrapper may be unnecessary. Test your terminal before adding more configuration.

To check `rlwrap`, evaluate `(+ 20 22)`, then use the Up arrow to recall it and
edit/re-evaluate it. Quit with `(sb-ext:exit)` or Ctrl-D at an empty prompt.
If the terminal behaves badly, rerun SBCL without `rlwrap` to isolate the wrapper.

For a deliberately separate history file, create a private directory and use
the wrapper's `-H` option:

```sh
mkdir -p "$HOME/.local/state/common-lisp-course"
chmod 700 "$HOME/.local/state/common-lisp-course"
rlwrap -H "$HOME/.local/state/common-lisp-course/sbcl.history" \
  sbcl --noinform --no-sysinit --no-userinit
```

The history can contain everything you type, including personal data. Do not
commit it or treat it as your only source backup. Removing the wrapper from the
launch command backs out this optional behavior; no Lisp init-file edit is needed.

## 3. Git as a learning tool

If you cloned the course, it is already a repository: **do not initialize it
again**. In a separately copied directory with no repository, `git init` is the
one-time initialization step. Configure your author identity locally if needed:

```sh
git config user.name "Your Name"
git config user.email "you@example.com"
git status --short
```

Use your own identity, not the literal placeholders. For independent work outside
the ignored `work/` directory, choose a deliberate location such as `my-labs/`:

```sh
git diff -- my-labs/
git add my-labs/
git diff --cached
git commit -m "Add tested sequence exercises"
git log --oneline -5
```

Create that directory and save your files there before using these examples.

`git status --short` summarizes tracked/untracked changes; `git diff` compares
unstaged tracked changes, `git add` stages selected paths, and `git diff --cached`
reviews that staged snapshot. `git commit -m` saves it with a message; `git log
--oneline -5` shows the five most recent commits compactly. `--` before a path
separates path arguments from options. Untracked file contents do not appear in
ordinary `git diff` until staged; inspect those files directly first.
Stage only intended paths; review the staged diff before committing. A useful
checkpoint includes source, tests, and short notes about behavior. Commit before
trying a major refactor. A Git commit preserves source, **not your live Lisp
image**. Check out source in another working copy and run a fresh process to
demonstrate reproducibility; do not use destructive resets as a learning shortcut.

The supplied [`.gitignore`](../.gitignore) excludes `work/`, local installations,
FASLs, saved cores, build output, and editor scratch files. It deliberately keeps
`.lisp`, `.asd`, documentation, and tests. Ignoring a file does not stop tracking
it if it was already committed. Do not store valuable exercise source only in
ignored `work/` without a separate backup or learner repository. Avoid broad
rules such as ignoring every `*.lisp` or all task-format files everywhere.

If Git refuses a commit because identity is missing, check `git config --get
user.name` and `git config --get user.email`, then set the local values shown
above. These values identify commits; they do not authenticate to GitHub. If
you cannot see a lab in status, use `git check-ignore -v path/to/lab.lisp` to
identify an ignore rule. Move assessed source to a deliberately tracked learner
directory or separate repository; do not broadly disable useful ignore rules.

## 4. Local documentation

Try `man sbcl`. If absent, check your distribution's SBCL documentation package;
Debian/Ubuntu commonly provide `sbcl-doc`. Distribution packages may place HTML
manuals under `/usr/share/doc/`, but exact paths vary. For Debian packages,
`dpkg -L sbcl-doc` lists installed files; on RPM systems `rpm -qd sbcl` lists
packaged documentation. Some systems separate these into another package.

For the HyperSpec, use the [online reference](https://www.lispworks.com/documentation/HyperSpec/Front/)
or obtain an authorized local copy under its license. Do not assume you can bundle
or redistribute a mirror with your course fork. Save the local index pathname
in your personal notes; editor-specific lookup is optional. SBCL's manual, ASDF's
manual, and library manuals answer different questions—keep all available.

Within Lisp, `documentation`, `describe`, and `apropos` remain useful without a
browser or editor plugin. Documentation strings are supplementary, not complete
substitutes for a language specification.

Those three Lisp facilities are introduced in [Lesson 10](../lessons/10-testing.md#inspect-rather-than-guess).
`man` is a Linux manual viewer, not a Lisp function.

### Install and locate offline documentation

For Debian/Ubuntu's packaged manual:

```sh
sudo apt install sbcl-doc
dpkg -L sbcl-doc
```

Choose the HTML index or manual file shown by the listing and open it with your
browser's local-file command. A distro may compress text manuals; consult its
package description rather than guessing an index path. On Fedora/Arch, inspect
the SBCL package's file list/documentation and the distro's available doc packages;
do not assume Debian's `sbcl-doc` name is portable.

For an offline HyperSpec, follow the authorized download/license links from
[LispWorks' Common Lisp documentation](https://www.lispworks.com/documentation/common-lisp.html).
Inspect the archive listing, extract only into a new user-owned docs directory,
and open its `Front/index.htm` locally. Keep the original directory structure:
cross-page links depend on it. Do not redistribute the download with your course
fork unless its terms permit that use. Set your editor's optional documentation
lookup path only after verifying the local index works in an ordinary browser.

Acceptance check: with the network unavailable, find `GETHASH` and
`WITH-OPEN-FILE` through the local index, then find invocation/debugger information
in the SBCL manual. Missing library manuals are separate from a missing HyperSpec.

### When an integration needs a newer ASDF

The core course uses SBCL's bundled ASDF. An optional integration may need a
newer one (Alive documents 3.3.3 or newer). Check the actually loaded version:

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --eval '(require :asdf)' --eval '(format t "~A~%" (asdf:asdf-version))'
```

If sufficient, do not upgrade just to follow a recipe. Otherwise use a suitable
implementation installation, or make an **explicit, user-local** ASDF copy.
The [ASDF upgrade manual](https://asdf.common-lisp.dev/asdf/Upgrading-ASDF.html)
describes its supported upgrade mechanisms. This isolated alternative avoids
replacing SBCL's installation or adding a globally auto-discovered source tree:

Do not overwrite an existing local copy: inspect/reuse it or choose a new
version-specific destination before running the download below.

```sh
mkdir -p "$HOME/.local/share/common-lisp-course/asdf"
curl --fail --location --proto '=https' --proto-redir '=https' \
  --output "$HOME/.local/share/common-lisp-course/asdf/asdf.lisp" \
  https://asdf.common-lisp.dev/archives/asdf.lisp
sha256sum "$HOME/.local/share/common-lisp-course/asdf/asdf.lisp"
```

Read the official source/version header and review
its provenance before loading; recording a checksum identifies the bytes but
does not independently authenticate them. This is a mutable upstream URL, not a
pinned dependency. Record the version/hash and retain the reviewed copy.

In a **new** disposable SBCL process, load it before Quicklisp or other ASDF consumers:

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load "$HOME/.local/share/common-lisp-course/asdf/asdf.lisp" \
  --eval '(format t "~A~%" (asdf:asdf-version))'
```

Point only the optional integration's startup at this file. Stop on an upgrade
error and use the manual/compatible implementation; do not continue after an
incomplete upgrade in a live image. To back out, start a fresh process without
that `--load`; no system ASDF or `.sbclrc` was replaced. Keep core tests on their
documented baseline, and test any explicitly upgraded environment separately.

## 5. Development compilation settings

Keep init files minimal. In a **development-only** source file you can use:

```lisp
(declaim (optimize (debug 3) (safety 3) (speed 0)))
```

`declaim` applies declarations to subsequent compilation; `optimize` selects
compiler priorities. `debug`, `safety`, and `speed` are quality names whose
levels range from 0 (least emphasis) to 3 (most). See
[Lesson 10](../lessons/10-testing.md#inspect-rather-than-guess) for the first
debugging use and [Lesson 14](../lessons/14-performance.md) for local declarations.

Load the settings before compiling the code you want to debug, then recompile
it. Settings cannot reconstruct debug information missing from an old FASL.
Keep these declarations out of generic user startup if they would unexpectedly
affect every loaded project. A local function declaration can make intent even
clearer. Compare with Lesson 14's measured optimization, never turning safety off
just to remove warnings. Review compiler warnings rather than globally muffling
them; compiler notes, warnings, and fatal errors are not interchangeable.

If you experiment with a personal `~/.sbclrc`, back it up, avoid project-specific
absolute paths, and document what it loads. Core course commands still skip it.
Do not commit credentials, machine-specific home paths, compiled caches, or runtime
images containing accidental session state.

## 6. Continuous integration (CI)

The supplied [GitHub Actions workflow](../.github/workflows/test.yml) installs
distribution SBCL on an Ubuntu runner and executes:

```sh
sbcl --noinform --no-sysinit --no-userinit --script examples/run-all.lisp
```

It runs on pushes, pull requests, and manual dispatch **when this repository is
hosted on GitHub with Actions enabled**. Creating the YAML does not publish the
repository, enable external hosting, or install anything on your own machine.
Other CI services can run the same command. Tests fail the job through a nonzero
exit status; no editor or Lisp startup configuration is involved.

This baseline does not install Quicklisp, invoke optional tests, or cache a home
directory. It records SBCL's version but does not pin the Ubuntu image or package
version, so it is a compatibility check rather than a bit-for-bit reproducible
build. The initial action reference uses a readable major version; higher-assurance
projects should review/pin action revisions and their update process.

An optional library CI job should be separate and should specify reviewed
dependency acquisition, versions, and cache keys before downloading anything.
Do not make a build silently update a Quicklisp distribution. Caching can improve
speed but must not hide incompatible compiler/platform artifacts or be treated as
dependency locking.

### Enable and inspect the supplied CI job

1. First run the exact test command locally. CI should reproduce a known command,
   not be the first place you discover an uncommitted source file.
2. If you choose GitHub hosting, create/select your own repository and its
   visibility deliberately. Check `git remote -v`; do not replace an existing
   remote casually. Commit reviewed source/tests and the workflow, excluding
   personal data and generated files.
3. Push to the selected remote using your normal authenticated Git workflow.
   For a repository whose `origin` you have already verified, `git push -u origin
   HEAD` pushes the current branch. This publishes files to that remote; it is
   not necessary if you want to keep the course entirely local.
4. Open the repository's **Actions** tab. Enable workflows if the host requires
   approval (commonly for forks), then inspect **Core course tests**, the SBCL
   version step, and the final test output. Restricted organizations may need
   an administrator's approval.
5. For manual dispatch, the workflow must be available on the default branch.
   Select it and use **Run workflow**; no course token/secret is required.

In the YAML, `on` lists triggers, `jobs` defines the runner job, `uses` selects
an action, and `run` executes shell commands on that runner. `contents: read`
limits the job's repository token permission. A failed command makes the step
fail; read the first useful error, not merely the last stack-frame line.
If your host blocks package downloads, fix the runner/network policy rather
than adding personal credentials to the workflow. A green job tests that runner
configuration; it does not prove every Linux version or optional editor works.

## Practice and acceptance criteria

### Exercises

1. Run the core suite both directly and through your chosen terminal wrapper.
2. Put one lab's source/tests in a learner repository and review a staged diff.
3. Find the entries for `gethash` and `with-open-file` in your reference setup.
4. Recompile a small function with development settings and inspect an error.
5. Read the CI YAML and explain which commands affect the runner versus your
   workstation. Hosting a repository or running GitHub Actions is optional.

### Acceptance checklist

- [ ] Exercise 1: the core suite runs directly and through your chosen wrapper
  without depending on hidden image state.
- [ ] Exercise 2: the learner repository contains source/tests, and you can
  explain the staged diff and what Git does not save about a running image.
- [ ] Exercise 3: you can locate the specified reference entries.
- [ ] Exercise 4: you recompile the function and inspect the resulting error.
- [ ] Exercise 5: you distinguish runner setup from workstation changes and
  explain why the core CI job needs no library manager.

### Review questions

1. Why is a Git commit not a snapshot of your running Lisp session?
2. Why should CI run in a fresh process without relying on your startup file?
