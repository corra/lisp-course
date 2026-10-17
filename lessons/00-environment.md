# 00 — Linux setup and an editor-independent workflow

**Goals:** install SBCL, distinguish shell from REPL, run and compile a source
file, and recover from errors without a particular editor. **Time:** 2–4 hours.

## Prerequisite recap

From your introductory programming experience, you should recognize:

- Values and variables: a program works with data and gives values names.
- Functions: arguments provide inputs, and a call can return a result.
- Conditionals and loops: programs choose actions and repeat work.

No Lisp syntax, Linux administration, or particular editor is assumed. This
lesson establishes the tools and workflow needed for the rest of the course.

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

`pwd` prints the current working directory. `mkdir -p work` creates a scratch
directory named `work` if needed. `PATH` is the shell's list of directories to
search for programs; `sudo` requests administrator privileges for installation.
In shell blocks, `#` starts a comment. In Lisp blocks, `;` starts a line comment.

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

Read `(+ 20 22)` as “call addition with 20 and 22.” The parentheses delimit one
expression. `sb-ext:exit` is a name qualified by the `SB-EXT` package; you need
only recognize the whole name for now. [Lesson 01](01-evaluation.md) explains
calls, and [Lesson 09](09-systems.md) explains packages and the colon notation.

The flags suppress startup banners and site/user init files. This avoids hidden
configuration while learning. Without those flags SBCL normally reads optional
initialization files, including `~/.sbclrc`. **You need not create or modify an
init file.** If you later customize one, keep project definitions in project
files, not in global startup code. Never load untrusted Lisp as configuration.

For optional terminal history, Git checkpoints, local manuals, and sensible
configuration defaults, see [practical tools](../optional/TOOLING.md). The
[editor/integration guide](../optional/EDITORS.md) explains available conveniences
without changing this lesson's editor-independent workflow. Quicklisp belongs
in the later optional module, not in your initial setup requirements.

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

This is a setup exercise, not a requirement to know all the syntax already:

| Part | Meaning now | Full treatment |
|---|---|---|
| `defun` | Define a named function; `greet` is a name we choose, not a built-in | [Lesson 03](03-functions.md#definitions-and-argument-lists) |
| `(name)` | One parameter, called `name`; the call supplies its value | [Lesson 03](03-functions.md#definitions-and-argument-lists) |
| First string in the body | Documentation describing the function | [Lesson 03](03-functions.md#definitions-and-argument-lists) |
| `format` with `t` | Print to the usual output; `~A` inserts the name and `~%` emits a newline | [Lesson 08](08-io.md#streams-and-formatting) |
| Final `name` | Return the parameter's value after printing | [Lesson 01](01-evaluation.md#progn-do-several-things-return-the-last-result) and [Lesson 03](03-functions.md) |
| `"Lisp learner"` | A string value passed to the function | [Lesson 02](02-values.md) |

The definition runs before the call below it. `load` reads and evaluates a file's
forms in order; it does not merely open the file in your editor.

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

The shell option `--load` evaluates the named file during startup;
`--non-interactive` prevents entering a REPL afterward and disables interactive
debugging. `--script` is the dedicated file-as-program mode used in the earlier
command. These are SBCL command-line options, not Lisp functions named with dashes.

## 5. Getting unstuck

Try `(car 17)` at the REPL. This is **deliberately invalid**: `car` retrieves the
first part of a cons/list, not an integer (see [Lesson 05](05-lists.md)).
SBCL enters its debugger with a type error and lists
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

In the pathname check above, `truename` resolves an existing pathname and `"."`
denotes the current directory. [Lesson 08](08-io.md#pathnames) covers pathnames;
[Lesson 10](10-testing.md) covers debugging, and [Lesson 11](11-conditions.md)
explains conditions and restarts. You only need the recovery procedure here.

## Lab 00

### Exercises

1. Create a function that prints your chosen course nickname.
2. Run it using `load`, then `--script`, without an editor plugin.
3. Compile the source file and load its FASL.
4. Deliberately cause an error and return to the REPL without terminating SBCL.
5. Record the SBCL version and exact commands you used.

### Acceptance checklist

- [ ] Exercise 1: the function prints your chosen nickname.
- [ ] Exercise 2: the greeting runs in a fresh process using either workflow;
  you can distinguish shell commands from REPL forms.
- [ ] Exercise 3: the compiled file loads successfully.
- [ ] Exercise 4: you recover to the top-level REPL and can evaluate another form.
- [ ] Exercise 5: your notes contain the version and reproducible commands.

### Review questions

1. Why does a source file containing only `(+ 1 2)` print a result in the REPL
   but not necessarily when executed as a script?
