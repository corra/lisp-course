# 03 — Functions, bindings, and scope

**Goals:** define functions, understand lexical environments and closures, and
recognize dynamic special variables. **Prerequisite:** 02. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 02](02-values.md):

- Integers and ratios support exact arithmetic; floating-point values are
  approximate. Choose comparisons and conversions to suit the values involved.
- `nil` is false and the empty list; every non-`nil` value is true. Symbols,
  keywords, characters, and strings are distinct kinds of objects.
- A form can return multiple values. `multiple-value-bind` gives those values
  local names, while `multiple-value-list` collects them into a list.

You already know how to evaluate forms and inspect their results. Here you learn
to name reusable computations and control which bindings their variable references see.

## Naming conventions

Common Lisp has well-established naming habits, but **ANSI Common Lisp does not
mandate one universal style guide**. Some conventions communicate important
semantics; others vary between projects. Follow these defaults in your own labs,
and follow an existing project's conventions when contributing to it.

The course-wide [style guide](../STYLE.md) collects these rules with layout,
documentation, API, ownership, and testing guidance. This section introduces
naming; the guide is a reference to apply as you reach the relevant features.

### Everyday names

- Write ordinary source names in **lowercase with hyphens between words**:
  `rectangle-area`, `price-with-tax`, `task-count`, and `user-name`. This is often
  called *kebab-case*. Prefer it to `rectangleArea`, `RectangleArea`, or
  `rectangle_area`; those are not the conventional Common Lisp source style.
- Use descriptive domain names: `tasks` for a collection, `task` for one task,
  and `task-count` for its count. Avoid unexplained abbreviations and type prefixes
  such as `str-name`. Short names such as `x`, `n`, and `i` are reasonable for
  small mathematical examples or short loops, not a substitute for naming intent.
- Function names should describe their result or operation: `rectangle-area`
  computes a value, `find-task` searches, and `complete-task` changes a task.
  These are naming examples, not additional functions you must load here.
- Use the same hyphenated style for parameters and keyword options, such as
  `supplied-p` and `:start-id`. Do not use letter case to distinguish two names:
  the normal reader treats `task-count` and `TASK-COUNT` as the same symbol.
  Uppercase REPL output is normal; it is not a recommendation to write source
  in uppercase. Avoid escaped mixed-case names such as `|TaskCount|`.

### Predicates and truth-valued names

A predicate tests a property and returns a true or false value (Lesson 02).
Names often end in `p` or `-p`:

- Many single-word built-ins append `p`: `integerp`, `numberp`, `evenp`.
- Compound names commonly use `-p`: `valid-title-p`, `task-done-p`.
- This is a convention, not an infallible grammar: `null` and `equal` are also
  predicates. Some projects consistently prefer `-p` even for single-word names,
  and `defstruct` generates `reading-p` by default (Lesson 12).
- A truth-valued variable or slot can use the same convention, such as `done-p`
  or `supplied-p`. Do not import a Scheme-style `?` suffix or routinely replace
  predicate suffixes with `is...`/`has...` prefixes in this course.

Predicates need not return exactly `t` when true: any non-`nil` value is true.
The suffix describes the intended question, not a compiler-enforced return type.

If retrieving an object is the primary purpose, choose a query name such as
`find-task`; do not add `-p` just because the returned object can be used as true.

### Conventions introduced later

Recognize these now; use their linked explanations when you reach the feature.
The punctuation is part of a symbol's name, not a declaration by itself.

| Kind of name | Typical form | Meaning and teaching location |
|---|---|---|
| Ordinary lexical variable | `task-count` | No decorative punctuation; [local bindings below](#local-bindings-and-assignment) |
| Special (dynamically scoped) variable | `*report-prefix*` | Asterisks (“earmuffs”) signal special-variable semantics; [special variables below](#special-dynamic-variables) |
| Named constant | `+maximum-items+` | Paired plus signs are a common project convention, not universal; [constants below](#special-dynamic-variables) |
| Constructor | `make-reading` | `make-` commonly means construct an object; [Lesson 12](12-objects.md#start-with-a-structure) |
| Record accessor | `reading-value` | Common type/slot naming; [Lesson 12](12-objects.md#start-with-a-structure) |
| Binding/resource macro | `with-open-file` | `with-` often suggests a body executed within a binding/resource scope; [Lesson 08](08-io.md#text-files-and-eof) |
| Internal helper | `%make-task` | Optional `%` convention in some projects, not actual privacy; [Lesson 09](09-systems.md#packages-organize-symbols) and [the capstone](15-capstone.md#reading-the-reference-source) |
| Some destructive operations | `nreverse` | Historical `n` prefix can warn of mutation; not a universal rule; [Lesson 05](05-lists.md#mutation-rules) |

Do **not** put `*earmuffs*` around an ordinary local variable just for emphasis.
Conversely, a variable established as special should retain the warning when
temporarily rebound locally. Naming something `*setting*` does not make it
special, and naming something `+limit+` does not make it constant; the defining
forms/declarations establish those properties. A constant name also does not
make an arbitrary referenced object deeply immutable.

Earmuffs do not mark every globally defined thing: an ordinary top-level function
still has a name such as `price-with-tax`, not `*price-with-tax*`.

### Names to avoid and consistency to preserve

Do not redefine standard Common Lisp functions/types or implementation-owned
names. For example, do not define your own function named `list` or `count` in a
package inheriting those standard symbols; [Lesson 09](09-systems.md) explains
packages and name conflicts. A local variable named `count` is legal and common:
the separate variable/function namespaces explained below make that a different
case. Do not change required exercise API names merely to follow another style.

Naming does not replace documentation. Read the contract to determine mutation,
ownership, validity constraints, and return values rather than guessing from a
prefix or suffix alone. No editor plugin is needed to apply these conventions.

## Definitions and argument lists

```lisp
(defun rectangle-area (width height)
  "Return the area of a rectangle."
  (* width height))

(rectangle-area 3 4) ; 12
```

`defun` defines a named function. In this example, `rectangle-area` is the name,
`(width height)` lists two required parameters, the string is an optional
documentation string, and `(* width height)` is the body. Evaluating the
definition makes the function available; it does **not** run the body to compute
an area. Calling `(rectangle-area 3 4)` supplies values for the parameters and
then executes the body.

A body can contain several forms. Like the `progn` introduced in Lesson 01,
it evaluates them in order and returns the last form's values, without requiring
an explicit final `return`. The documentation string, when present, documents
the function rather than becoming an extra run-time body step.

Explicit early exits using `return`/`return-from` are taught in
[Lesson 04](04-control.md#exiting-a-region); they are different from a function's
ordinary last-form return and are not needed for these definitions.

Here is a function that also accepts a named option:

```lisp
(defun greet (name &key (prefix "Hello"))
  (format nil "~A, ~A" prefix name))

(greet "Ada" :prefix "Welcome") ; "Welcome, Ada"
```

`defun` names a function, specifies its parameters, optionally documents it, and
supplies body forms. `format nil` builds a string rather than printing it.

`~A` inserts the corresponding argument in that string; the rest of this
formatting notation is taught in [Lesson 08](08-io.md#streams-and-formatting).
In the parameter specification `(prefix "Hello")`, `prefix` is the parameter
name and `"Hello"` its default. `&key` makes the call use the keyword `:prefix`
to supply a different value. The ampersand is part of the lambda-list marker's
name; it is not an arithmetic or address-taking operator.

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

### What a binding does

A **binding** associates a variable name with a value in a particular scope:
the part of the program where references to that name use that binding.
`let` and `let*` both introduce local bindings, execute a body, and return the
last body form's values. They do not define global variables or functions.

Their binding lists have the same shape: `((name initial-form) ...)`. Each
`initial-form`, or **initializer**, is an expression whose result supplies that
binding's initial value. The list of bindings is syntax, not a series of calls
to the names being bound. The `*` in `let*` is part of the operator's name
(pronounced “let star”); it is not multiplication or a variable earmuff.

The important difference is **when a new binding becomes visible to subsequent
initializers**. Both forms evaluate initializers from left to right.

### `let`: initialize in the surrounding scope, then bind

```lisp
(let ((x 10)
      (y 20))
  (+ x y))                    ; 30
```

Read this in four steps:

1. Evaluate `10` to obtain the future value for `x`.
2. Evaluate `20` to obtain the future value for `y`.
3. Establish **both** new bindings: local `x` is 10 and local `y` is 20.
4. Evaluate the body `(+ x y)` using those bindings; return 30.

Neither initializer can refer to a new binding from this same `let`. Initializers
instead see the **surrounding scope**—the bindings already in effect outside
this form. Once initialization is complete, the body sees all the new bindings.

### `let*`: initialize and bind one variable at a time

```lisp
(let* ((x 10)
       (y (+ x 2)))
  (* x y))                    ; 120
```

Here the second initializer deliberately depends on the first binding:

1. Evaluate `10`, then immediately establish local `x = 10`.
2. Evaluate `(+ x 2)` **with that new `x` visible**; its value is 12.
3. Establish local `y = 12`. Both bindings are now visible to the body.
4. Evaluate `(* x y)`, meaning `10 * 12`; return 120.

For these ordinary lexical bindings, the nested form below expresses the same
dependency explicitly:

```lisp
(let ((x 10))
  (let ((y (+ x 2)))
    (* x y)))                  ; 120
```

Simply changing the original `let*` to `let` would **not** give its second
initializer access to the new `x`. That initializer would instead use an outer
`x`, if one exists, or signal an unbound-variable error if none exists. Do not
rely on a variable left over from an earlier REPL experiment to make it work.

### The same names, different bindings: a direct comparison

An inner binding may reuse an outer binding's name. It **shadows** the outer
binding: references in its scope use the inner binding instead. This does not
assign a new value to the outer binding.

First compare an outer `x = 5` with an inner `let`:

```lisp
(let ((x 5))
  (let ((x 10)
        (y x))
    (list x y)))               ; (10 5)
```

The inner `let` evaluates `10` and then `x` **before** establishing either inner
binding. At that point the visible `x` is still the outer one, with value 5.
The body then has inner `x = 10` and inner `y = 5`.

Now change only the inner operator to `let*`:

```lisp
(let ((x 5))
  (let* ((x 10)
         (y x))
    (list x y)))               ; (10 10)
```

The inner `let*` establishes `x = 10` before evaluating the initializer `x` for
`y`. That reference therefore finds the **inner** binding, and `y` becomes 10.
The outer binding still exists but is hidden at that point.

| Question | Inner `let` | Inner `let*` |
|---|---|---|
| Which `x` does `y`'s initializer see? | Outer `x`, value 5 | Earlier inner `x`, value 10 |
| Which bindings does the inner body see? | `x = 10`, `y = 5` | `x = 10`, `y = 10` |
| Was the outer `x` assigned a new value? | No | No |

After leaving the inner scope, the outer binding is visible again:

```lisp
(let ((x 5))
  (list (let ((x 10)) x)
        x))                    ; (10 5)
```

The first list element comes from the inner binding; the second uses the outer
one after the inner form has finished. This illustrates binding scope, not
copying objects or undoing arbitrary changes to program state.

### Choosing between them

- Use `let` when the initializers do not need the new sibling bindings.
- Use `let*` when a later initializer needs an earlier new binding.
- Both evaluate initializers **left to right**. The phrase “parallel bindings,”
  sometimes used for `let`, describes binding visibility—not simultaneous
  evaluation, separate threads, or a promise of parallel execution.
- With independent initializers, either can produce the same result; there is
  no universal speed advantage to choosing the starred form.

This is the full basic distinction needed for Lab 03.4, not a topic deferred
to another lesson. These examples use ordinary lexical variables; the later
[special-variable section in this lesson](#special-dynamic-variables) explains
the separate issue of dynamically scoped variables.

### Assignment changes a binding or another place

Creating a binding is different from assigning a value to an existing place.
`setf` changes a **place**: a variable, list element, array element, object slot,
and more. `incf` increments a place. Prefer local state to avoid accidental coupling.

`(incf place)` adds 1; `(incf place amount)` adds a specified
amount. `setf` evaluates a new value and stores it in the given place. Updating
list/array places is taught in [Lessons 05](05-lists.md) and [07](07-collections.md).

```lisp
(let ((count 0))
  (incf count)
  (setf count (+ count 4))
  count)                      ; 5
```

Here `let` first creates the local `count` binding. `incf` and `setf` then change
that binding's value; they do not create replacement bindings. When a variable
name is shadowed, an assignment to it affects the binding visible at that point.

`count` here is our local variable name. It is not a call to the sequence
function also named `count`, which is introduced in Lesson 06; variable and
function names have separate namespaces, as the next section explains.

## Lexical functions and closures

Bindings are lexical by default: source nesting determines which binding a
reference denotes. A closure retains access to bindings even after the function
that established them has returned.

`lambda` creates an anonymous function: `(lambda (parameters...) body...)`.
An empty parameter list `()` means it takes no arguments. `funcall` calls a
function value, as opposed to looking up a function by the operator name.
These are used below; [Lesson 06](06-sequences.md#calling-a-function-value)
expands on function values, mapping, and `apply`.

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

Both have the binding shape `(flet ((name (parameters...) body...) ...) body...)`
(replace `flet` with `labels` for recursive visibility). For example:

```lisp
(flet ((add-one (n) (1+ n)))
  (add-one 4)) ; 5
```

`add-one` exists as a local function only within this body. The local definition
is not a call to `add-one`; it supplies that function's parameter list and body.

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

`defconstant` has the basic shape `(defconstant name value)` and establishes a
global constant rather than a dynamically rebound setting. Constant names often
use `+earmuffs+` by convention. It is recognition-only in this lesson; consult
the HyperSpec's `DEFCONSTANT` entry before adding constants whose redefinition
or object identity would matter. No lab requires redefining constants.

## Lab 03 — Small APIs

### Exercises

1. Implement `price-with-tax` with a required price and keyword `rate`, default
   `1/5`. Return the exact total, not printed text.
2. Implement `make-stepper`, returning a closure that advances a private counter
   by a chosen step. Give it keyword arguments `start` and `step`.
3. Show that two steppers do not share state.
4. Write and run the two [direct-comparison forms](#the-same-names-different-bindings-a-direct-comparison)
   with outer `x = 5`, inner `x = 10`, and `y` initialized from `x`. Predict each
   `(list x y)` result before running it. Trace the initializer evaluations,
   identify which `x` each reference sees, and explain why the outer binding is
   unchanged. State which form you would choose when one initializer depends on
   an earlier new binding.
5. Review the names in your implementations against this lesson's conventions.
   Keep the required API names, and explain any deliberate naming exceptions.

### Acceptance checklist

- [ ] Exercise 1: default tax on 100 returns the exact total 120.
- [ ] Exercise 2: each stepper advances by its configured step from its start.
- [ ] Exercise 3: advancing one stepper does not advance another.
- [ ] Exercise 4: inner `let` gives `y = 5`, while inner `let*` gives `y = 10`;
  both inner bodies see `x = 10`. Your trace distinguishes initializer scope
  from body scope, preserves outer `x = 5`, and justifies the dependency choice.
- [ ] Exercise 5: names use the applicable Common Lisp conventions; ordinary
  lexical variables are not misleadingly marked as special variables/constants.

### Review questions

1. How are binding, assignment, and mutation different?
2. Why can reloading a file containing `defvar` leave an old value intact?
3. Which naming conventions signal intent without changing language semantics?
4. Do `let` and `let*` evaluate initializer expressions in a different order,
   or do they differ in when the new bindings become visible?
