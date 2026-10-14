# 00 — Linux setup and an editor-independent workflow

**Goals:** install SBCL, distinguish shell from REPL, run and compile a source
file, and recover from errors without a particular editor. **Time:** 2–4 hours.

## 1. Install the essentials

Open a terminal. These commands are alternatives for different distributions;
use **only** the appropriate one. Package installation needs administrator
permission. If you lack it, ask your administrator or follow the binary/source
installation instructions at [sbcl.org](https://www.sbcl.org/platform-table.html).

```sh
# Debian / Ubuntu
sudo apt update
sudo apt install sbcl
```

```sh
# Fedora
sudo dnf install sbcl
```

```sh
# Arch Linux
sudo pacman -S sbcl
```

Verify in the terminal:

```sh
command -v sbcl
sbcl --version
pwd
mkdir -p work
```

The first command should print a program path; the second an SBCL version. Exact
versions and architecture labels vary. The course uses longstanding language
features rather than a version-specific SBCL release. If a command is not found,
check that installation succeeded and that its directory is in your shell's
`PATH`. Do not fix this by running your programming sessions as root.

Use any installed plain-text editor: vi/vim, Emacs, nano, a graphical text editor,
or another. Save UTF-8 plain text with the `.lisp` extension, not rich text.
Two terminal windows—one editor, one SBCL—are sufficient. Parenthesis highlighting
and indentation help but are optional. SLIME and SLY are optional Emacs integrations,
not editors themselves and not requirements for the course.

## 2. Start a predictable REPL

```sh
sbcl --noinform --no-sysinit --no-userinit
```

The **read–eval–print loop** reads a Lisp expression, evaluates it, prints results,
then waits again. SBCL commonly displays `*` as its top-level prompt. Type just:

```lisp
(+ 20 22)
```

It prints `42`. Quit with `(sb-ext:exit)` or end-of-input (usually Ctrl-D at an
empty prompt). `sb-ext:exit` is SBCL-specific; `+` is standard Common Lisp.

The flags suppress startup banners and site/user init files. This avoids hidden
configuration while learning. Without those flags SBCL normally reads optional
initialization files, including `~/.sbclrc`. **You need not create or modify an
init file.** If you later customize one, keep project definitions in project
files, not in global startup code. Never load untrusted Lisp as configuration.

At the REPL, `*` also names the most recent primary result, `**` the previous one,
and `***` the one before that. These conveniences are not application variables.

## 3. Write, load, edit, reload

Create `work/hello.lisp` with your editor:

```lisp
(defun greet (name)
  "Print a greeting and return NAME."
  (format t "Hello, ~A!~%" name)
  name)

(greet "Lisp learner")
```

Start SBCL **from the course directory** and enter:

```lisp
(load "work/hello.lisp")
(greet "Ada")
```

Change the greeting text in the editor, save, and `load` again. A definition can
be replaced in a running Lisp. Reloading does not undo every previous side effect:
deleted definitions and old variable values may remain. Restart periodically to
check reproducibility. Relative paths are interpreted using Lisp's pathname
defaults, initially normally based on the launch directory; avoid changing those
defaults until you understand pathnames.

## 4. Scripts and noninteractive checks

Back in the Linux terminal:

```sh
sbcl --noinform --no-sysinit --no-userinit --script work/hello.lisp
```

Unlike the REPL, a script does not automatically print each form's return values.
Only explicit output is displayed. A file of function definitions can load
successfully without printing anything.

Compile and then load a file interactively:

```lisp
(compile-file "work/hello.lisp")
(load "work/hello.fasl")
```

`compile-file` returns an output pathname plus warning/failure indicators; `.fasl`
is SBCL's usual compiled-file extension. Compilation and loading are different
operations. Keep `.lisp` source: compiled files are not portable between arbitrary
implementations, versions, and architectures. Compilation may process definitions
needed at compile time; do not assume compilation of arbitrary code is inert.

For a simple noninteractive check from the shell:

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load work/hello.lisp
```

## 5. Getting unstuck

Try `(car 17)` at the REPL. SBCL enters its debugger with a type error and lists
numbered **restarts**. Read the list and select the restart labelled `ABORT` that
returns to top level; numbers vary, so do not memorize one. Type `help` at the
debugger prompt to see commands, including backtrace commands. See Lesson 10.

If SBCL is waiting after an incomplete form, finish the missing parentheses or
press Ctrl-C; at the interrupt debugger choose the offered abort-to-top-level
restart. Terminal interruption behavior may vary. Never paste shell commands into
the Lisp debugger. A new shell prompt and a Lisp prompt are different environments.

| Symptom | Likely cause and next step |
|---|---|
| `command not found` in shell | SBCL missing or `PATH` incorrect |
| Reader waits without a result | Unclosed parenthesis or string |
| Package does not exist | Typo, or dependency/package definition not loaded |
| Undefined function | File not loaded, misspelling, wrong package, or wrong Lisp dialect |
| File not found | Wrong working directory; check `pwd` in shell and `(truename ".")` in Lisp |
| Old behavior survives edits | File not saved/reloaded, or retained image state; restart |
| Editor inserts “smart quotes” | Switch to plain text and ASCII source delimiters |

## Lab 00

Create a function that prints your chosen course nickname. Run it using `load`,
then `--script`. Compile and load its FASL. Deliberately cause an error and return
to the REPL without terminating SBCL. Record the SBCL version and exact commands.

**Pass:** you can reproduce the greeting in a fresh process, explain the shell
versus REPL distinction, and demonstrate that no editor plugin is needed.

**Checkpoint:** Why does a source file containing only `(+ 1 2)` print a result in
the REPL but not necessarily when executed as a script?
