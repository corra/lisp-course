# Common Lisp / SBCL quick reference

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
| Quotient/remainder | `floor ceiling truncate round` return multiple values |
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
