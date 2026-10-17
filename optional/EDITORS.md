# Editors and Common Lisp integrations: selection and setup

**No editor, extension, key binding, or integration in this guide is required.**
All main lessons and assessments use plain source files, SBCL, and terminal
commands. Choose tools according to availability, accessibility, and preference,
not because a particular editor is considered the only legitimate Lisp workflow.

## Prerequisite recap

From the baseline in [Lesson 00](../lessons/00-environment.md):

- Edit/save `.lisp` source with any plain-text editor, then load it in SBCL.
- The shell, REPL, and debugger are different contexts; input belongs to the
  context that understands it.
- Restarting and running the documented terminal commands checks saved source
  independently of any editor's retained runtime state.

This guide describes optional conveniences built on that baseline. Advanced
inspection/package/macro features retain the teaching references given below;
you need not learn them just to choose an editor.

## 1. What an editor can provide

There are three distinct levels:

1. **Plain-text editing:** save `.lisp` files; use a separate terminal for SBCL.
   This is the course baseline and works with vim, Emacs, nano, graphical editors,
   and other text editors.
2. **Language-aware editing:** indentation, syntax highlighting, matching
   parentheses, snippets, and optional structural movement/editing. These features
   may not communicate with a running Lisp at all.
3. **Runtime integration:** send a form or file to SBCL, compile selected
   definitions, inspect objects, browse definitions, request documentation and
   completions, and interact with the debugger in editor buffers/windows.

An integration's REPL is still a Lisp session. It can accumulate stale state just
like a terminal REPL; it is not a replacement for source files and batch tests.
A language server and a live runtime bridge are different architectures; a
completion popup alone does not imply access to the running image or restarts.

## 2. Common choices

| Environment | Possible workflow | Important distinction |
|---|---|---|
| Any plain-text editor | Edit/save; `load` in terminal; run script tests | Complete required workflow; no plugin needed |
| Vim / Neovim | Lisp indentation and matching; optional tools such as [Vlime](https://github.com/vlime/vlime) or [SLIMV](https://github.com/kovisoft/slimv) | Check each plugin's supported editor versions, runtime bridge, and dependencies |
| Emacs | Common Lisp editing; optional [SLIME](https://slime.common-lisp.dev/) or [SLY](https://github.com/joaotavora/sly) | Emacs is the editor; SLIME/SLY are integrations, not separate editors |
| VS Code / VSCodium | Text editing; optionally a Common Lisp extension such as [Alive](https://github.com/nobody-famous/alive) | Check client/server installation, SBCL launch command, and current compatibility |
| Other graphical editors | Plain-text editing, possibly terminal panes or plugins | A Scheme/Clojure extension is not automatically a Common Lisp integration |

These are examples, not a ranking or a guarantee of future maintenance. Consult
each project's current installation guide and license before installing. No
extension is preinstalled by this course, and this guide does not modify editor
configuration. Start with one integration, not several competing bridges.

SLIME uses a Lisp-side server commonly called **Swank**. SLY uses its own server,
**Slynk**. Other clients may use Swank or a different server/protocol. Use matching
client/server instructions; do not assume all bridges are interchangeable. A
plugin may obtain components through an editor package manager, a Lisp library
manager, or both. These are separate dependency environments.

## Installation and configuration routes

The steps below are instructions for your own optional setup, **not** software
installed by checking out this course. Read the route's requirements first.
Back up existing configuration and use the isolated trial configurations where
provided. Do not run the editor or its Lisp runtime as root.

Choose one editor; these package commands are alternatives:

| Editor | Debian / Ubuntu | Fedora | Arch Linux |
|---|---|---|---|
| Nano | `sudo apt install nano` | `sudo dnf install nano` | `sudo pacman -S nano` |
| Vim | `sudo apt install vim` | `sudo dnf install vim-enhanced` | `sudo pacman -S vim` |
| Neovim | `sudo apt install neovim` | `sudo dnf install neovim` | `sudo pacman -S neovim` |
| Emacs | `sudo apt install emacs-nox` (terminal; `emacs` for GUI) | `sudo dnf install emacs` | `sudo pacman -S emacs` |

Package names/features vary by distribution release. `editor --version`, using
your actual command (`nano`, `vim`, `nvim`, or `emacs`), confirms installation.
For graphical VS Code/VSCodium, use the dedicated instructions rather than
assuming a `code` package exists in every default repository.

| Route | Complete installation/configuration instructions | Additional requirements |
|---|---|---|
| Plain text + terminal | Nano recipe below; plain Vim/Emacs recipes in their guides | SBCL only; no runtime bridge |
| Emacs + SLIME | [Emacs guide, Route A](editors/EMACS.md#2-route-a-slime-from-its-source-repository) | Git/source checkout or Emacs package manager; matching bundled Swank |
| Emacs + SLY | [Emacs guide, Route B](editors/EMACS.md#3-route-b-sly-from-its-source-repository) | Matching Slynk; separate trial config from SLIME |
| Vim/Neovim + Vlime | [Vim guide, Route A](editors/VIM.md#2-route-a-vlime-for-vim-or-neovim) | Suitable channel/job support and explicit Quicklisp setup |
| Vim + SLIMV | [Vim guide, Route B](editors/VIM.md#3-route-b-slimv-for-python-enabled-vim) | Embedded Python 3 in Vim; matching bundled Swank |
| VS Code/VSCodium + Alive | [Alive setup guide](editors/VSCODE.md) | Compatible extension/server, Quicklisp, ASDF 3.3.3 or newer |

Each guide explains install, launch, verification, failure diagnosis, and how
to back out. Network access is needed to acquire uncached packages/plugins;
it is not a new requirement for the core course. The commands use user-owned
paths and explicitly skipped Lisp startup files; they do not edit `.sbclrc`.

### Minimal Nano workflow

After installing Nano, run from the course directory:

```sh
nano optional/editor-check.lisp
```

Ctrl+O writes the file (confirm the filename with Enter), Ctrl+X exits, and
Ctrl+G opens help. The `^` in Nano's shortcut display means Ctrl. Nano need not
have a Common Lisp integration: save, then use a separate terminal to load/test
the file. You may use another plain-text editor in exactly this two-process
workflow. Do not mistake a built-in terminal pane for a connected Lisp REPL.

## Shared verification exercise

The [editor-check source](editor-check.lisp) is a tiny dependency-free library.
It uses packages, `defun`, and `format` taught in Lessons 03, 08, and 09; its
purpose here is checking the tool connection, not adding language requirements.

### Exercises

1. Before configuring a bridge, check the source from a terminal in the course
   directory:

   ```sh
   sbcl --noinform --no-sysinit --no-userinit --non-interactive \
     --load optional/editor-check.lisp \
     --eval '(format t "~A~%" (course-editor-check:greeting "Ada"))'
   ```

   Expected printed line: `Hello, Ada. SBCL is connected.` The shell's single
   quotes protect the Lisp expression; do not include them in REPL input.
2. Follow one route's launch instructions. Save/load the same source through
   the integration and evaluate `(course-editor-check:greeting "Ada")` there.
   A REPL displays the returned string with quotes, unlike `format` above.
   With plain editing, perform this step in the separate SBCL terminal.
3. Make a working copy without silently overwriting existing work:

   ```sh
   mkdir -p work
   cp -i optional/editor-check.lisp work/editor-check.lisp
   ```

   If prompted about an existing copy, inspect it or choose a new filename.
   Open the working copy, change the greeting text, save, and reload **that copy**
   in the connected Lisp. Confirm the result changes; undo the edit and reload.
4. Deliberately evaluate `(car 17)`. Read the type error, choose an offered
   abort-to-top-level restart, and prove the greeting still works. Use the
   integration's debugger controls where present, not a memorized restart number.
5. Restart the editor's Lisp process and reload the source. Record the editor,
   integration/server, SBCL, and relevant ASDF/Quicklisp versions, paths, and
   launch commands. Do not rely on definitions from the previous process.
6. Run the unchanged core suite from a terminal:

   ```sh
   sbcl --noinform --no-sysinit --no-userinit --script examples/run-all.lisp
   ```

### Acceptance checklist

- [ ] Exercise 1: the terminal prints the expected greeting without editor dependencies.
- [ ] Exercise 2: the chosen workflow loads/evaluates the file, not just highlights it.
- [ ] Exercise 3: the saved working-copy edit is reflected only after evaluation/reload.
- [ ] Exercise 4: debugger recovery leaves a usable Lisp session.
- [ ] Exercise 5: startup is repeatable and the actual configuration/versions are recorded.
- [ ] Exercise 6: the main course's terminal tests still pass independently.

### Review questions

1. How do you know which Lisp process evaluated a form?
2. Which setup information lives in the editor, and which belongs to your project?
3. Why must terminal tests remain independent of a successful editor connection?

## 3. Useful features, independent of brand

Good first conveniences are Lisp-aware indentation, visible parenthesis matching,
and a way to compile/load the current file. Structural tools can move entire
forms, wrap expressions, and maintain balance; learn the difference between
structural and ordinary deletion before enabling strict modes. Such tools are
optional and do not justify making exercises depend on a specific shortcut.

Live inspection, argument hints, macro expansion, and debugger/frame inspection
become useful after the corresponding lessons. Learn the terminal meaning first:
`describe`, `documentation`, `macroexpand-1`, tracing, conditions, and restarts
exist independently of an editor's presentation. A lint or language-server
warning may not be an SBCL compiler warning; identify its source.

These are previews if you read this guide early: [Lesson 09](../lessons/09-systems.md)
teaches packages; [Lesson 10](../lessons/10-testing.md) teaches `describe`,
`documentation`, tracing, and debugger operation; [Lesson 11](../lessons/11-conditions.md)
teaches handlers/restarts; and [Lesson 13](../lessons/13-macros.md) teaches
`macroexpand-1`. You do not need them to configure basic text editing.

## 4. A neutral integration checklist

Whatever integration you choose, verify that you can:

- Identify the SBCL executable, its version, startup arguments, and working directory.
- Identify whether user/site init files are loaded and whether Quicklisp is explicit.
- Open an existing `.lisp` file without converting it to rich text or changing delimiters.
- Save and load a file; redefine one function; see a deliberately signaled error.
- Return from the debugger through an offered restart, then rerun fixed source.
- Select/check the current Lisp package before evaluating a form.
- Expand a macro and distinguish expansion from execution.
- Restart the Lisp process and load the project from source in a known order.
- Run the documented terminal test command unchanged, outside the editor.

For comparability with the course, configure a clean-session launch profile using
`--noinform --no-sysinit --no-userinit` where supported. Some integrations depend
on their own startup code; load that code explicitly according to their manual,
not by assuming your personal init file will run. Do not put a specific editor's
bridge in the capstone's required ASDF dependencies.

## 5. Common integration problems

| Symptom | Check |
|---|---|
| Terminal works but editor reports undefined functions | Is the right file/system loaded in the editor's separate Lisp process? |
| Wrong relative file paths | Compare working directory and pathname defaults |
| `QL` package missing | Load setup explicitly before reading Quicklisp-qualified forms |
| Existing function appears missing | Confirm package selection and export/name spelling |
| No source navigation or locals | Source locations and compilation/debug settings may differ |
| Debugger opens in terminal rather than editor | Check bridge connection and version pairing |
| Editor tests pass but terminal tests fail | Hidden init files, unsaved definitions, source registry, or retained state |
| Plain text editing behaves strangely | Disable/reconfigure structural mode rather than fight unfamiliar deletion rules |

For a runtime identity check, evaluate `(lisp-implementation-version)` and
`(truename ".")` in the connection. To inspect ASDF, evaluate `(require :asdf)`
first, then `(asdf:asdf-version)` as a separate form. Compare these with your
terminal session rather than assuming the environments are identical.

When reporting a problem, include the exact launch/configuration, versions or
commits, the first substantive error, and whether the terminal greeting check
passes. Remove secrets and unrelated personal paths from shared logs.

Installation recipes were checked against the upstream references linked in the
individual guides. That is not a claim of end-to-end testing on every editor,
plugin release, Linux distribution, or graphical desktop. Verify your chosen
combination with the shared exercise. Do not install every route to troubleshoot
one: first make the simplest failing layer work.

Remote bridges deserve particular care. A Lisp runtime connection can allow code
execution with your account's permissions. Do not expose Swank, Slynk, or another
debug server on a public interface. Follow the integration's local binding and
secure-tunnel guidance, and do not connect to an untrusted runtime or evaluate
unreviewed project-local startup configuration.

## Suggested adoption path

Complete Lesson 00 with the terminal baseline. Add indentation and matching when
convenient. After Lesson 09/10, optionally adopt an integration and use the
checklist above. Keep using fresh-process terminal tests for every milestone.
There is no assessment credit for choosing a particular editor; credit follows
correct, understandable, reproducible programs.
