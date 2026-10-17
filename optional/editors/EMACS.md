# Optional setup — Emacs with SLIME or SLY

**Placement:** plain editing after Lesson 00; runtime integration preferably
after Lessons 09–10. Install **one** integration first, not both.

## Prerequisite recap

- [Lesson 00](../../lessons/00-environment.md): SBCL and saved plain-text files
  are sufficient to run the course.
- [Lesson 09](../../lessons/09-systems.md): an editor package and a Lisp system
  are separate things; neither substitutes for loading your own project.
- [Lesson 10](../../lessons/10-testing.md): a fresh-process test verifies saved
  source, while a connected REPL may retain old definitions.

These instructions use dedicated configuration files and `emacs -Q`, leaving
your normal Emacs configuration untouched. `-Q` belongs to Emacs; the separate
SBCL startup flags belong to the Lisp process Emacs launches.

## 1. Install Emacs and verify it

Use one distribution command, not all of them:

```sh
# Debian / Ubuntu: terminal-only Emacs; use package emacs for a graphical build
sudo apt install emacs-nox git
```

```sh
# Fedora
sudo dnf install emacs git
```

```sh
# Arch Linux
sudo pacman -S emacs git
```

Then run `emacs --version` and `command -v sbcl`. A graphical build can also run
in a terminal with `emacs -nw`. The source-install routes below need Git/network
access but do **not** require Quicklisp: each integration supplies its own Lisp-side
bridge. Review third-party source/licenses before loading it.

In Emacs notation, `C-x` means hold Ctrl and press x; `M-x` usually means Alt+x,
or Esc followed by x. `RET` means Enter. These shortcuts are specific to this
optional setup, not the main lessons.

For plain editing alone, start `emacs -Q optional/editor-check.lisp` from the
course directory. `C-x C-s` saves, `C-x C-f` opens a file, and `C-x C-c` exits.
Use the separate terminal workflow from Lesson 00; you may stop here.

## 2. Route A: SLIME from its source repository

SLIME is the Emacs client; Swank is its Lisp-side bridge. Clone into a new,
user-owned directory. If the destination already exists, inspect/reuse it rather
than overwriting it:

```sh
mkdir -p "$HOME/.local/share/common-lisp-course/editors"
mkdir -p "$HOME/.config/common-lisp-course"
git clone https://github.com/slime/slime.git \
  "$HOME/.local/share/common-lisp-course/editors/slime"
git -C "$HOME/.local/share/common-lisp-course/editors/slime" rev-parse HEAD
```

Record the commit printed by `rev-parse`; this guide does not pin a release.
Create `~/.config/common-lisp-course/emacs-slime.el` with your editor:

```elisp
;; Emacs Lisp configuration, NOT Common Lisp source for SBCL.
(add-to-list 'load-path
             (expand-file-name "~/.local/share/common-lisp-course/editors/slime"))
(require 'slime-autoloads)
(setq slime-lisp-implementations
      '((sbcl ("sbcl" "--noinform" "--no-sysinit" "--no-userinit"))))
```

`load-path` tells Emacs where to find its integration; the implementation entry
names SBCL and its arguments as separate strings. Replace `"sbcl"` with the
absolute executable path from `command -v sbcl` if your GUI environment's `PATH`
differs from the terminal. These are Emacs Lisp settings, not a `.sbclrc` file.

From the course directory:

```sh
emacs -Q --load "$HOME/.config/common-lisp-course/emacs-slime.el" \
  optional/editor-check.lisp
```

Run `M-x slime RET`. Wait for compilation/connection to finish. The first launch
can take longer while Swank is compiled. In the source buffer, save, then run
`M-x slime-compile-and-load-file RET`. In the SLIME REPL evaluate:

```lisp
(course-editor-check:greeting "Ada")
```

Expected result: `"Hello, Ada. SBCL is connected."`. Follow the
[shared verification exercise](../EDITORS.md#shared-verification-exercise) next.

## 3. Route B: SLY from its source repository

SLY is a separate Emacs integration using **Slynk**, not Swank. Start a fresh
Emacs process for this route instead of loading it on top of the SLIME setup.

```sh
mkdir -p "$HOME/.local/share/common-lisp-course/editors"
mkdir -p "$HOME/.config/common-lisp-course"
git clone https://github.com/joaotavora/sly.git \
  "$HOME/.local/share/common-lisp-course/editors/sly"
git -C "$HOME/.local/share/common-lisp-course/editors/sly" rev-parse HEAD
```

Create `~/.config/common-lisp-course/emacs-sly.el`:

```elisp
;; Emacs Lisp configuration, NOT Common Lisp source for SBCL.
(add-to-list 'load-path
             (expand-file-name "~/.local/share/common-lisp-course/editors/sly"))
(require 'sly-autoloads)
(setq sly-lisp-implementations
      '((sbcl ("sbcl" "--noinform" "--no-sysinit" "--no-userinit"))))
```

Start it from the course directory:

```sh
emacs -Q --load "$HOME/.config/common-lisp-course/emacs-sly.el" \
  optional/editor-check.lisp
```

Run `M-x sly RET`, then save the source and run
`M-x sly-compile-and-load-file RET` in its buffer. Call the same qualified
`greeting` function in the SLY REPL and expect the same string. SLY's REPL is
not the same process as a SLIME REPL or a separately launched terminal SBCL.

## 4. Package-manager alternative and optional editing aids

Instead of cloning, Emacs's package manager can install `slime` or `sly` from
[MELPA](https://melpa.org/#/getting-started). Add that HTTPS package archive
according to its instructions, run `M-x package-refresh-contents RET`, then
`M-x package-install RET slime RET` or select `sly`. This uses the network and
installs Emacs code. Do not also point `load-path` at a second source copy of
the same integration. Record the installed version and use the same explicit
SBCL argument configuration above.

The `-Q` launch recipes intentionally skip normal package initialization. If
using package-manager installations in an isolated config, call
`(require 'package)` and `(package-initialize)` there before requiring that
integration's autoloads; omit the source-copy `add-to-list` form.

Built-in Lisp indentation and `M-x show-paren-mode RET` are enough initially.
Paredit, Parinfer, and other structural-editing packages are optional; install
one only after learning its deletion/undo behavior. Neither bridge requires
that you adopt a structural editor.

## 5. Failure diagnosis and backing out

| Symptom | Next check |
|---|---|
| `Cannot open load file ...-autoloads` | Confirm the clone directory and `load-path`; avoid mixing source/package-manager copies |
| SBCL executable not found | Use its absolute path in the implementation entry; GUI `PATH` may differ |
| Bridge compiler/load failure | Read the inferior Lisp buffer and first real error; check client/server commit compatibility |
| `QL` package missing | Clean startup deliberately skips `.sbclrc`; explicitly load trusted Quicklisp setup if your project needs it |
| Function/package missing after editing | Save and compile/load the file in this connection, not another REPL |
| Wrong relative paths | Check `(truename ".")`; launch Emacs from the course directory or use absolute Lisp pathnames |

Use `M-x slime-quit-lisp RET` or `M-x sly-quit-lisp RET` to stop the corresponding
Lisp process. Closing an editor buffer alone need not stop every process.
For a reversible trial, stop using the dedicated `--load` configuration file;
your ordinary Emacs startup file was never changed. If you later merge settings
into your normal init file, back it up and remove only the block you added when
backing out. Review and test updates deliberately rather than blindly pulling
new bridge code before a lab.

## Upstream references

- [SLIME installation](https://slime.common-lisp.dev/doc/html/Installation.html)
- [SLIME implementation arguments](https://slime.common-lisp.dev/doc/html/Multiple-Lisps.html)
- [SLY installation and manual](https://github.com/joaotavora/sly)
