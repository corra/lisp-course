# Optional setup — Vim/Neovim, Vlime, and SLIMV

**Placement:** plain editing after Lesson 00; bridges preferably after Lessons
09–10. Choose Vlime **or** SLIMV, not both in the same trial configuration.

## Prerequisite recap

- [Lesson 00](../../lessons/00-environment.md): a source editor and terminal SBCL
  already provide the complete required workflow.
- [Lesson 09](../../lessons/09-systems.md): Lisp libraries and editor plugins are
  distinct installations; record which runtime and packages you are connecting to.
- [Quicklisp setup](../QUICKLISP.md): clean sessions must load `setup.lisp`
  explicitly before Quicklisp-qualified code can be read.

Configurations below are **Vimscript**, not Common Lisp. Use a separate `.vim`
file with `-u` so you need not overwrite an existing vimrc or Neovim init file.

## 1. Install an editor and verify features

Use the appropriate distribution command and install only what you need:

```sh
# Debian / Ubuntu
sudo apt install vim git
# Alternative editor: sudo apt install neovim
```

```sh
# Fedora
sudo dnf install vim-enhanced git
# Alternative editor: sudo dnf install neovim
```

```sh
# Arch Linux
sudo pacman -S vim git
# Alternative editor: sudo pacman -S neovim
```

Run `vim --version` or `nvim --version`. Vlime's upstream minimum is Vim
8.0.0312 with channels, or Neovim 0.2.2; use a supported current distribution
build rather than deliberately installing those old minima. In Vim,
`:echo has('channel')` should print `1` for Vlime. SLIMV has different Python
requirements, checked in its section below; installing Python alone does not
add a missing embedded-Python feature to Vim.

For a plain-editor trial, create `~/.config/common-lisp-course/vim-basic.vim`
after making its parent directory with `mkdir -p`:

```vim
set nocompatible
syntax enable
filetype plugin indent on
set expandtab shiftwidth=2 softtabstop=2
set showmatch
```

From the course directory, open the sample:

```sh
vim -u "$HOME/.config/common-lisp-course/vim-basic.vim" optional/editor-check.lisp
```

Or substitute `nvim` for `vim`. Press `i` to insert text, Esc to return to normal
mode, `:w` then Enter to save, and `:q` to quit. Start a separate terminal SBCL
and `load` the saved file as in Lesson 00. This needs no bridge or Quicklisp.

## 2. Route A: Vlime for Vim or Neovim

### Install the client and its matching server source

First complete [Quicklisp setup](../QUICKLISP.md). The initial Vlime server run
may install dependencies through it. Source installation avoids requiring a
particular Vim plugin manager:

```sh
mkdir -p "$HOME/.local/share/common-lisp-course/editors"
mkdir -p "$HOME/.config/common-lisp-course"
git clone https://github.com/vlime/vlime.git \
  "$HOME/.local/share/common-lisp-course/editors/vlime"
git -C "$HOME/.local/share/common-lisp-course/editors/vlime" rev-parse HEAD
```

Review the source/license and record its commit. Do not move the `vim/`
subdirectory away from the rest of the checkout: Vlime uses the surrounding
source tree to locate its server.

Create `~/.config/common-lisp-course/vim-vlime.vim`:

```vim
set nocompatible
execute 'set runtimepath+=' . fnameescape(
      \ expand('~/.local/share/common-lisp-course/editors/vlime/vim'))
let maplocalleader = ','
syntax enable
filetype plugin indent on
set expandtab shiftwidth=2 softtabstop=2
set showmatch
```

`runtimepath` is Vim's plugin search path; the additional `vim/` component is
essential. `maplocalleader` selects the prefix used by Vlime's local mappings.
The backslash begins a Vimscript continuation line, not a Lisp escape.

### Start SBCL with setup explicitly loaded

In a terminal **in the course directory**, leave this process running:

```sh
sbcl --noinform --no-sysinit --no-userinit \
  --load "$HOME/quicklisp/setup.lisp" \
  --load "$HOME/.local/share/common-lisp-course/editors/vlime/lisp/start-vlime.lisp"
```

Replace the Quicklisp path for a custom installation. Do not use `--script` or
`--non-interactive` for this long-lived interactive server. It normally listens
on loopback `127.0.0.1`, port `7002`; read its startup output and do not expose it
to the network. Do not answer an unexpected read/eval prompt with untrusted text.

In another terminal:

```sh
vim -u "$HOME/.config/common-lisp-course/vim-vlime.vim" optional/editor-check.lisp
```

Again, `nvim -u ...` is the alternative. In normal mode press `,cc` to connect,
using `127.0.0.1` and port `7002` if prompted. For explicit connection instead:

```vim
:call vlime#plugin#ConnectREPL('127.0.0.1', 7002)
```

Save the source and press `,l` to load the current file. Use `,si` to compose
`(course-editor-check:greeting "Ada")` in an input buffer, then submit with Enter
in normal mode. `,ss` instead sends the form under the cursor. The ordinary
Vlime output buffer is **read-only**; typing directly into it is not its normal
input workflow. Expect `"Hello, Ada. SBCL is connected."`.

### Local help and troubleshooting

Generate help tags inside Vim once:

```vim
:execute 'helptags ' . fnameescape(expand('~/.local/share/common-lisp-course/editors/vlime/vim/doc'))
:help vlime
:help vlime-tutor
```

With the comma leader, `,?` shows the current buffer's mappings. If none work,
check `:set filetype?` (expect `lisp`) and `:set runtimepath?`. Connection refused
usually means the server failed, the wrong port was selected, or initialization
is still downloading/compiling dependencies. Check the **server terminal** first.
If a port is occupied, do not kill an unidentified process: use the server's
documented alternate-port option and connect to that same port.

The manual also documents editor-managed startup (`:help vlime-start-up`) and a
custom command builder for explicit SBCL/Quicklisp arguments. Use manual startup
first so hidden startup configuration is not needed to get a working connection.

## 3. Route B: SLIMV for Python-enabled Vim

This route is for **Vim with embedded Python 3 support**; Neovim's external Python
provider is not a drop-in replacement for that requirement. Use Vlime or plain
editing for Neovim unless your chosen SLIMV version explicitly supports another
configuration. Some older SLIMV documentation mentions Python 2; do not install
obsolete Python 2 to follow it.

In Vim check:

```vim
:echo has('python3')
:python3 import sys; print(sys.version)
```

The first must print `1`, and the second must successfully run the embedded
Python. Debian/Ubuntu's `vim-nox` or `vim-gtk3` packages commonly provide suitable
builds; verify the installed binary rather than assuming `vim` has this feature.
For example, Debian/Ubuntu users can choose `sudo apt install vim-nox python3`.
On other distributions inspect the available Vim builds and verify with the
same commands. Do not downgrade a working editor just to enable this route.

Install the source into a new directory:

```sh
mkdir -p "$HOME/.local/share/common-lisp-course/editors"
mkdir -p "$HOME/.config/common-lisp-course"
git clone https://github.com/kovisoft/slimv.git \
  "$HOME/.local/share/common-lisp-course/editors/slimv"
git -C "$HOME/.local/share/common-lisp-course/editors/slimv" rev-parse HEAD
```

Create `~/.config/common-lisp-course/vim-slimv.vim` (make the parent directories
from Route A first if you skipped it):

```vim
set nocompatible
execute 'set runtimepath+=' . fnameescape(
      \ expand('~/.local/share/common-lisp-course/editors/slimv'))
let g:slimv_python_version = 3
let g:slimv_keybindings = 1
let g:swank_host = '127.0.0.1'
let g:swank_port = 4005
let g:paredit_mode = 0
syntax enable
filetype plugin indent on
set expandtab shiftwidth=2 softtabstop=2
```

Disabling its bundled Paredit initially keeps structural editing from becoming
an accidental prerequisite. Start the checkout's matching Swank in a separate
terminal from the course directory:

```sh
sbcl --noinform --no-sysinit --no-userinit \
  --load "$HOME/.local/share/common-lisp-course/editors/slimv/slime/start-swank.lisp"
```

This basic bridge does not require Quicklisp. Keep the server local; its default
port is `4005`. In a second terminal run:

```sh
vim -u "$HOME/.config/common-lisp-course/vim-slimv.vim" optional/editor-check.lisp
```

Connect with the explicit Vim command `:call SlimvConnectServer()`. Save the
source, then use the plugin's Compile and Load File operation (`,L` in the first
mapping set explicitly selected above). Use the REPL or the Eval Current
Expression operation to run the greeting call from the shared exercise.
For exact mappings, generate tags in the checkout's `doc/` directory as in the
Vlime recipe (replace the path), then open `:help slimv-keyboard` and
`:help slimv-installation`. Changing mapping sets can change shortcuts; the
explicit connection function above avoids that ambiguity.

If Python initialization fails, fix the Vim build/runtime match first. If Swank
protocol errors occur, do not combine an unrelated Swank checkout with the
client: start with the matching server supplied by this SLIMV checkout.

## 4. Stop, record, and undo a trial setup

Disconnect the editor, then exit the manually started SBCL with `(sb-ext:exit)`
at its top-level prompt. A disconnect alone may leave the server process alive.
Use Ctrl-C and an offered abort restart if needed to recover the terminal prompt.
Do not solve port conflicts by terminating unrelated processes.

Record editor/SBCL versions, the plugin commit, Python support (for SLIMV), server
port, and explicit launch commands. Backing out simply means no longer using
the trial `-u` configuration. Remove only your own added configuration if you
later merge it into a normal init file; do not delete an entire existing vimrc.

Finish the [shared verification exercise](../EDITORS.md#shared-verification-exercise).
Upstream references: [Vlime](https://github.com/vlime/vlime),
[Vlime manual](https://github.com/vlime/vlime/blob/master/vim/doc/vlime.txt),
[SLIMV](https://github.com/kovisoft/slimv), and
[SLIMV manual](https://github.com/kovisoft/slimv/blob/master/doc/slimv.txt).
