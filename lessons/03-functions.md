# 03 — Functions, bindings, and scope

**Goals:** define functions, understand lexical environments and closures, and
recognize dynamic special variables. **Prerequisite:** 02. **Time:** 4–6 hours.

## Definitions and argument lists

```lisp
(defun rectangle-area (width height)
  "Return the area of a rectangle."
  (* width height))

(defun greet (name &key (prefix "Hello"))
  (format nil "~A, ~A" prefix name))

(greet "Ada" :prefix "Welcome") ; "Welcome, Ada"
```

`defun` names a function, specifies its parameters, optionally documents it, and
supplies body forms. `format nil` builds a string rather than printing it.

Required parameters come first. `&optional` introduces positional defaults,
`&rest` collects remaining arguments into a list, and `&key` introduces named
arguments. A supplied-p parameter distinguishes omission from an explicit `nil`:

```lisp
(defun supplied-demo (&optional (value 10 supplied-p))
  (list value supplied-p))

(supplied-demo)       ; (10 NIL)
(supplied-demo nil)   ; (NIL T)
```

Avoid mixing `&optional` and `&key` in beginner APIs: positional consumption can
make calls surprising. Do not mutate a quoted list used as a parameter default.

## Local bindings and assignment

```lisp
(let ((x 10)
      (y 20))
  (+ x y))                    ; 30

(let* ((x 10)
       (y (+ x 2)))
  (* x y))                    ; 120
```

`let` evaluates initializers in the surrounding environment before establishing
its new bindings; `let*` establishes them sequentially. `setf` changes a **place**:
a variable, list element, array element, object slot, and more. `incf` increments
a place. Prefer local state to avoid accidental coupling.

```lisp
(let ((count 0))
  (incf count)
  (setf count (+ count 4))
  count)                      ; 5
```

## Lexical functions and closures

Bindings are lexical by default: source nesting determines which binding a
reference denotes. A closure retains access to bindings even after the function
that established them has returned.

```lisp
(defun make-counter (&optional (start 0))
  (let ((count start))
    (lambda () (incf count))))

(let ((next (make-counter 10)))
  (list (funcall next) (funcall next))) ; (11 12)
```

Separate calls to `make-counter` create independent bindings. `flet` defines local
functions that do not see their own new names in their definitions; `labels`
allows recursive and mutually recursive local functions.

Common Lisp has separate variable and function namespaces. With a function value
in a variable `f`, write `(funcall f 3)`, not `(f 3)`. The latter uses a function
name. `#'name` obtains a function object; it is reader notation for `(function name)`.

## Special (dynamic) variables

```lisp
(defparameter *report-prefix* "Report")

(defun report-heading () *report-prefix*)

(let ((*report-prefix* "Temporary"))
  (report-heading))            ; "Temporary"
```

`defparameter` proclaims a variable special and assigns it each time the form is
evaluated. `defvar` also proclaims it special but initializes it only if unbound.
The `*earmuff*` naming convention warns readers about dynamic scope. A dynamic
binding temporarily affects calls made during its extent, then the previous
binding is restored. This is useful for settings and streams, not a replacement
for ordinary parameters. A closure does not turn such a special binding into a
lexical one. Use `defconstant` only for genuinely constant values and understand
redefinition rules before using it for nontrivial objects.

## Lab 03 — Small APIs

1. Implement `price-with-tax` with a required price and keyword `rate`, default
   `1/5`. Return the exact total, not printed text.
2. Implement `make-stepper`, returning a closure that advances a private counter
   by a chosen step. Give it keyword arguments `start` and `step`.
3. Show that two steppers do not share state.
4. Explain the result of an outer `let` binding `x` to 5 and an inner `let`
   binding `x` to 10 and `y` to `x`; compare with inner `let*`.

**Pass:** default tax on 100 is 120; independent steppers work; inner `let` gives
`y = 5`, inner `let*` gives `y = 10`.

**Checkpoint:** How are binding, assignment, and mutation different? Why can
reloading a file containing `defvar` leave an old value intact?
