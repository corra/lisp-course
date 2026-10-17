# Common Lisp / SBCL quick reference

For optional additions, see [Quicklisp and libraries](optional/QUICKLISP.md),
[tools/configuration](optional/TOOLING.md), and [editors/integrations](optional/EDITORS.md).
The required commands below remain editor- and third-party-library-independent.

## Where constructs are taught

Earlier appearances are labelled previews or given a short explanation in the
lesson that uses them. This index identifies the teaching location, not a claim
that every incidental name is a separate language feature.

| Topic / constructs | Teaching location |
|---|---|
| Shell/REPL distinction, `load`, `compile-file`, SBCL invocation/exit | [00 — environment](lessons/00-environment.md) |
| Calls, `+ - * /`, quotation (`'`, `quote`), `list`, `if`, `progn` | [01 — evaluation](lessons/01-evaluation.md) |
| `eval` preview and full explanation | [01 — preview](lessons/01-evaluation.md#preview-eval-treats-an-object-as-code), [13 — evaluation versus expansion](lessons/13-macros.md#evaluation-is-not-macro-expansion) |
| Numbers, `#C`, float/ratio notation, predicates, equality, `t`/`nil`, keywords, `#\`, `coerce` | [02 — values](lessons/02-values.md) |
| `floor`, `ceiling`, `truncate`, `round`, quotient/remainder relationship, ties to even | [02 — rounding and division](lessons/02-values.md#integer-quotients-rounding-and-remainders) |
| `values`, `multiple-value-bind`, `multiple-value-list` | [02 — multiple values](lessons/02-values.md#capturing-both-returned-values) |
| `defun`, parameters, `&optional`, `&rest`, `&key`, `let`/`let*`, `setf`/`incf` | [03 — functions and bindings](lessons/03-functions.md) |
| `let` versus `let*`: initializer visibility, shadowing, and assignment | [03 — worked binding comparison](lessons/03-functions.md#local-bindings-and-assignment) |
| Naming conventions, predicate suffixes, earmuffs, constants, constructor/accessor names, formatting and API style | [03 — naming](lessons/03-functions.md#naming-conventions), [course style guide](STYLE.md) |
| `lambda`, closures, `funcall`, `#'`, `function`, `flet`/`labels` | [03 — lexical functions](lessons/03-functions.md#lexical-functions-and-closures), [06 — calling function values](lessons/06-sequences.md#calling-a-function-value) |
| `defvar`/`defparameter`/`defconstant`, dynamic special variables | [03 — special variables](lessons/03-functions.md#special-dynamic-variables) |
| `cond` versus `if`, `case`/`ecase`, `and`/`or`, numeric tests, `1+`/`1-` | [04 — decisions](lessons/04-control.md) |
| `when`/`unless`, grouped bodies | [04 — one-sided tests](lessons/04-control.md#one-sided-tests-when-and-unless) |
| `dotimes`, `dolist`, `loop`, recursion, `check-type`, interval type syntax, `return`/`return-from` | [04 — iteration and control](lessons/04-control.md) |
| Cons/list accessors, copying/sharing, `push`/`pop`, `append`, `reverse`/`nreverse`, `assoc`/`getf`, `atom`, `destructuring-bind` | [05 — lists](lessons/05-lists.md) |
| `apply`, mapping, filtering, `reduce`, sequence search/counting, `:key`/`:test`, sorting, `string<` | [06 — sequences](lessons/06-sequences.md) |
| `vector`, `#(...)`, `make-array`, `aref`, fill pointers, string transformations, hash-table operations | [07 — collections](lessons/07-collections.md) |
| `format`, `~` directives, streams, file options, reader/EOF arguments, `parse-integer`, `gensym`, pathnames | [08 — I/O](lessons/08-io.md) |
| `defpackage`/`in-package`, `#:` and colon syntax, `*package*`, `find-package`, `require`, ASDF components/dependencies | [09 — systems](lessons/09-systems.md) |
| `assert`, expected-error test preview, `abs`, inspection/tracing, `declaim`/`optimize` | [10 — testing](lessons/10-testing.md) |
| `define-condition`, `error`/`warn`/`signal`, handlers, restarts, `declare (ignore ...)`, cleanup | [11 — conditions](lessons/11-conditions.md) |
| `defstruct`, generated names, `defclass`, `make-instance`, `defgeneric`/`defmethod`, slots, `call-next-method` | [12 — objects](lessons/12-objects.md) |
| `defmacro`, `&body`, backquote/comma/comma-at, `macroexpand-1`, fresh names, phase rules (`eval-when`) | [13 — macros](lessons/13-macros.md) |
| `time`, type declarations, `simple-array`, `the`, `loop across`/`into`/`of-type`/`finally`, saved images | [14 — performance](lessons/14-performance.md) |
| Application-defined names, constructor options, validation helpers, reader/printer settings, ASDF test options, UIOP and SBCL CLI helpers | [15 — reference source guide](lessons/15-capstone.md#reading-the-reference-source) |
| Quicklisp, Alexandria, FiveAM, dependency introspection, optional test entry points | [Optional library module](optional/QUICKLISP.md) |
| Git, `rlwrap`, local manuals, compiler configuration, CI | [Optional tools](optional/TOOLING.md) |
| Editor/bridge installation, explicit runtime startup, greeting/reload/debugger verification | [Optional integrations](optional/EDITORS.md), [Emacs](optional/editors/EMACS.md), [Vim/Neovim](optional/editors/VIM.md), [VS Code/VSCodium](optional/editors/VSCODE.md) |

## Shell versus Lisp

From a Linux shell, in the course directory:

```sh
sbcl --version
sbcl --noinform --no-sysinit --no-userinit
sbcl --noinform --no-sysinit --no-userinit --script path/to/program.lisp
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load path/to/file.lisp
```

At the Lisp REPL:

```lisp
(load "path/to/file.lisp")
(compile-file "path/to/file.lisp")
(load "path/to/file.fasl")
(describe some-object)
(documentation 'some-function 'function)
(apropos "fragment")
(sb-ext:exit) ; SBCL-specific
```

`some-object` and `some-function` above are placeholders for your actual objects
and names. Never paste a shell prompt (`$`) or REPL prompt (`*`) into source.

## Evaluation and syntax

| Form | Meaning |
|---|---|
| `(f x y)` | Call the named function/operator with forms x and y |
| `'x` / `(quote x)` | Use x as literal data, without evaluating it |
| `#'f` / `(function f)` | Refer to a named function object |
| `(lambda (x) ...)` | Anonymous function |
| `(progn a b)` | Evaluate in order; return b's values |
| `(let ((x a)) ...)` | Local bindings, initializers in outer environment |
| `(let* ((x a) (y x)) ...)` | Sequential local bindings |
| `(setf place value)` | Assign to a generalized place |
| `(values a b)` | Return multiple values |
| `(multiple-value-bind (a b) form ...)` | Capture multiple returned values |
| `; text` / `#| text |#` | Line / nestable block comments |

`nil` = false = empty list. All other values are true. Most predicates end in
`p` or `-p`. A trailing `!` is not a standard mutation marker in Common Lisp.

## Function argument lists

```lisp
(defun example (required &optional (optional 10 supplied-p)
                        &rest remaining)
  (list required optional supplied-p remaining))

(defun keyword-example (required &key (mode :normal))
  (list required mode))
```

Do not confuse keyword symbols `:mode` and `:normal` with variables or strings.
Use `funcall` for a function held in a variable; `apply` spreads its final list.

## Data and operations

| Need | Useful operations / cautions |
|---|---|
| Exact arithmetic | `+ - * / expt mod`; integer division can return a ratio |
| Quotient/remainder | `floor` down, `ceiling` up, `truncate` toward zero, `round` nearest/ties-to-even; each returns integer quotient and remainder ([worked examples](lessons/02-values.md#integer-quotients-rounding-and-remainders)) |
| Lists | `cons list first rest car cdr null endp` |
| List stacks | `push pop`, both update a place |
| Copy | `copy-list` spine, `copy-tree` cons tree, `copy-seq` sequence |
| Transform/filter | `mapcar map remove-if remove-if-not` |
| Aggregate/search | `reduce find position count every some` |
| Sort | `sort stable-sort`; destructive, use return value and consider copying |
| Vectors/arrays | `vector make-array aref elt vector-push-extend` |
| Strings | `char string= string-equal string< string-trim concatenate` |
| Hash tables | `make-hash-table gethash remhash maphash hash-table-count` |
| Small mappings | `assoc` for alists, `getf` for plists |
| Files/streams | `with-open-file read-line write-line format` |
| Numeric parsing | `parse-integer`; default rejects trailing non-whitespace junk |

Lists are linked; repeated random indexing costs traversal. String hash keys
normally need `equal`, not default `eql`. `gethash` returns a presence flag.
`equal` is structural for lists/strings, not every possible object. Use `=` for
numeric values; do not use `eq` as a portable number comparison.

## Names and systems

- `package:symbol`: exported symbol; `package::symbol`: internal access.
- `defpackage`: namespace definition; `in-package`: reader's current namespace.
- `defun`: function; `defmacro`: source transformer; `defgeneric`/`defmethod`: CLOS behavior.
- `defstruct`: record type; `defclass`: class definition.
- `defparameter`: special variable, assigned on reevaluation.
- `defvar`: special variable, initial value only if previously unbound.
- `*earmuffs*`: convention for special variables, not syntax creating dynamic scope.

Explicit ASDF loading at a fresh REPL:

```lisp
(require :asdf)
(asdf:load-asd (truename "capstone/course-tasks.asd"))
(asdf:load-system "course-tasks")
(asdf:test-system "course-tasks")
```

## Error handling vocabulary

| Construct | Purpose |
|---|---|
| `error` | Signal an error; debugger if no handler transfers control |
| `warn` | Issue a warning |
| `signal` | Notify condition handlers; may return normally |
| `handler-case` | Handle after unwinding protected context |
| `handler-bind` | Run handler in signaling context |
| `restart-case` | Offer named recovery paths |
| `find-restart` / `invoke-restart` | Discover / select an available recovery |
| `unwind-protect` | Ensure cleanup on exit |
| `assert` / `check-type` | Test invariants / type constraints |

At the SBCL debugger prompt use `help` and read the offered restart descriptions.
Restart numbers vary. In production/batch code, do not require human recovery.

## Frequent mistakes

1. Writing `(1 2 3)` when you mean data: use `list` or quote.
2. Writing `(f x)` when `f` is a variable holding a function: use `funcall`.
3. Using `eq` for numbers or string contents.
4. Mutating quoted lists or literal strings.
5. Ignoring the return value of `sort`, `delete`, or `nreverse`.
6. Assuming copies recursively duplicate all referenced objects.
7. Treating `nil` as always meaning absence when it can be stored data.
8. Assuming `let` initializers see sibling new bindings.
9. Assuming a package loads or installs a library.
10. Trusting a running REPL instead of checking source in a fresh process.
11. Using `read` or `eval` as a generic safe parser for user input.
12. Writing a macro when a function would give simpler semantics.

## Reference lookup

The HyperSpec symbol index explains argument order, keyword parameters, return
values, exceptional situations, side effects, and portability notes. Look up a
specific operation rather than guessing from its name. For SBCL debugger commands,
process arguments, images, profiling, and Unicode external formats, use the SBCL
manual. For system discovery/build/test operations, use the ASDF manual.
