# Optional setup — VS Code/VSCodium with Alive

**Placement:** plain editing after Lesson 00; Alive after Lessons 09–10 and the
optional Quicklisp setup. A Lisp-aware editor is still not a course requirement.

## Prerequisite recap

- [Lesson 00](../../lessons/00-environment.md): the editor saves source; SBCL
  executes it. Syntax highlighting alone does not establish a runtime connection.
- [Lesson 09](../../lessons/09-systems.md): ASDF loads systems/packages only after
  their source/dependencies can be found.
- [Quicklisp](../QUICKLISP.md): load trusted setup explicitly in sessions that
  skip personal startup files.

The editor extension and Lisp server are separate installations. Their upstream
documentation was checked for this course, but verify the graphical workflow on
your own Linux/editor combination before relying on it.

## 1. Install the editor

For Microsoft's VS Code, use the [official Linux instructions](https://code.visualstudio.com/docs/setup/linux).
Check `uname -m` and select the matching architecture. Download the publisher's
`.deb` or `.rpm` and verify provenance using its guidance. If you deliberately
saved it as `~/Downloads/code-editor.deb` or `.rpm`, install with one command:

```sh
# Debian / Ubuntu, after downloading the matching .deb
sudo apt install "$HOME/Downloads/code-editor.deb"
```

```sh
# Fedora, after downloading the matching .rpm
sudo dnf install "$HOME/Downloads/code-editor.rpm"
```

Use the actual downloaded filename if different. Standard repositories may not
contain a package named `code`. On Arch, follow publisher/distro instructions
for the chosen build; distribution Code-OSS and Microsoft's product can have
different extension marketplaces.

For VSCodium, obtain a matching release through its
[official installation page](https://vscodium.com/#install). Install a downloaded
`.deb`/`.rpm` by the same local-package method, substituting its filename. If Snap
is already enabled, the documented alternative is `sudo snap install codium --classic`;
`--classic` grants broad host access, so choose knowingly. Repository-based
installation is documented upstream; do not import repository keys from an
arbitrary tutorial.

Verify `code --version` or `codium --version`. From the course directory, open
the **folder** using `code .` or `codium .`. Review Workspace Trust/extension
permissions. Plain editing requires no extension: save `.lisp` files and run
the ordinary terminal commands. You may stop here.

## 2. Check SBCL, ASDF, and Quicklisp

Alive's documented minimum is **ASDF 3.3.3**; do not infer this from SBCL's version.
At a clean SBCL REPL evaluate:

```lisp
(require :asdf)
(asdf:asdf-version)
```

If too old, follow the [isolated ASDF upgrade](../TOOLING.md#when-an-integration-needs-a-newer-asdf)
or use an implementation installation with a suitable bundled ASDF. Then load
trusted Quicklisp setup explicitly, as in its module. Alive uses libraries
including `bordeaux-threads`, `usocket`, `cl-json`, and `flexi-streams` for
concurrency, sockets, JSON, and streams. These are optional server dependencies,
not new core-course requirements; Quicklisp can obtain them and their dependencies.

## 3. Install the extension and server

Find **Alive**, identifier **`rheller.alive`**, in the Extensions view; check
its publisher/repository. For VS Code's CLI:

```sh
code --install-extension rheller.alive
code --list-extensions --show-versions
```

VSCodium normally uses Open VSX, not Microsoft's marketplace. Search for the
same identifier there; availability may differ. If absent, obtain a compatible
`.vsix` from a trusted upstream distribution if provided, then use
**Extensions: Install from VSIX...** or `codium --install-extension /absolute/path/to/alive.vsix`.
Do not substitute a similarly named unknown extension. If no trusted compatible
build exists, choose another integration or plain editing.

Use a reviewed server checkout rather than an unrecorded automatic download:

```sh
mkdir -p "$HOME/.local/share/common-lisp-course/editors"
git clone https://github.com/nobody-famous/alive-lsp.git \
  "$HOME/.local/share/common-lisp-course/editors/alive-lsp"
git -C "$HOME/.local/share/common-lisp-course/editors/alive-lsp" rev-parse HEAD
```

Record the commit and extension version. Inspect/reuse existing directories;
do not overwrite them. The extension can also download servers automatically,
but this recipe selects a known source location.

## 4. Configure an explicit server launch

Open **Preferences: Open User Settings (JSON)** from the Command Palette
(usually Ctrl+Shift+P). Back up and merge keys into the existing object, not
replace all settings. A dedicated editor profile makes a trial easy to reverse.

Replace **every** `/home/YOUR_USER/...` with actual absolute paths, including a
custom Quicklisp path if applicable. These strings are not shell commands:
do not assume `~`, `$HOME`, or workspace substitution works in arbitrary settings.

```json
{
  "alive.lsp.install.path": "/home/YOUR_USER/.local/share/common-lisp-course/editors/alive-lsp",
  "alive.lsp.startCommand": [
    "sbcl", "--noinform", "--no-sysinit", "--no-userinit",
    "--load", "/home/YOUR_USER/quicklisp/setup.lisp",
    "--eval", "(require :asdf)",
    "--eval", "(asdf:load-asd \"/home/YOUR_USER/.local/share/common-lisp-course/editors/alive-lsp/alive-lsp.asd\")",
    "--eval", "(ql:quickload \"alive-lsp\")",
    "--eval", "(alive/server:start)"
  ],
  "alive.enableDiagnostics": false,
  "[commonlisp]": {
    "editor.insertSpaces": true,
    "editor.tabSize": 2
  }
}
```

If using isolated ASDF, insert `"--load"` and its absolute `asdf.lisp` pathname
as two entries **before** Quicklisp's `--load` pair. Use an absolute SBCL path
if the editor cannot find the program. The ASD registers your selected checkout;
Quicklisp supplies dependencies before `alive/server:start` starts it. Do not
add `--script`, `--quit`, or `--non-interactive`: the server must stay alive.

Diagnostics are initially disabled to avoid background compilation while
learning startup. This is not a security boundary or a promise that the extension
does no other evaluation. Enable diagnostics later after understanding their behavior.

## 5. Start, verify, troubleshoot, and undo

Run **Developer: Reload Window**, then open `optional/editor-check.lisp`. Watch
the Output view's Alive/LSP-related channel and Lisp/REPL views for startup
errors; initial dependency downloads/compilation may take time. Save the file,
invoke **Alive: Load File Into REPL**, then enter in Alive's REPL input area
or select and invoke **Alive: Send To REPL**:

```lisp
(course-editor-check:greeting "Ada")
```

Expect `"Hello, Ada. SBCL is connected."`, then complete the
[shared verification exercise](../EDITORS.md#shared-verification-exercise).

| Symptom | Next check |
|---|---|
| No Alive commands | Check Common Lisp file language, extension enabled status, editor version, and Workspace Trust |
| Server immediately exits | Inspect the first Output error; confirm command paths and ASDF version |
| `QL` missing | Check explicit setup path/order; `.sbclrc` is intentionally skipped |
| `alive-lsp` missing | Check cloned ASD and `install.path`, not just extension installation |
| Dependency failure | Reproduce the explicit setup/ASD/Quicklisp sequence in a terminal |
| Protocol incompatibility | Review extension/server release notes and choose a matching pair |
| Snap/Flatpak cannot find host SBCL/files | Check sandbox access; its environment may differ from the host terminal |

Do not expose the server publicly or connect to an untrusted runtime. Closing a
REPL panel may leave the process running: use editor process/extension controls
and check that the server stops. To back out, disable/uninstall Alive, stop its
server, and remove only the settings/profile you added. Core files and `.sbclrc`
need no changes. Review source/extension updates together and rerun verification.

References: [Alive](https://github.com/nobody-famous/alive),
[Alive server](https://github.com/nobody-famous/alive-lsp),
[VS Code Linux setup](https://code.visualstudio.com/docs/setup/linux), and
[VSCodium installation](https://vscodium.com/#install).
