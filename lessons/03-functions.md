# 03 — Functions, bindings, and scope

**Goals:** define functions and local helpers, understand lexical environments and closures, and
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
function names have separate namespaces, as the
[local named functions section](#local-named-functions) explains later.

## Lexical scope and closures

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

Separate calls to `make-counter` create independent bindings.

### A function keeps access to its defining bindings

An ordinary lexical reference uses the binding surrounding the function's
definition, not a same-named binding surrounding a later call:

```lisp
(let ((prefix "Report"))
  (let ((heading (lambda () prefix)))
    (let ((prefix "Temporary"))
      (list prefix (funcall heading))))) ; ("Temporary" "Report")
```

The inner body sees its own `prefix`, but the function stored in `heading`
still refers to the outer `prefix`. Calling the function does not reconnect its
lexical references to the caller's variables.

In `make-counter`, the function similarly retains access to its `count` binding.
It retains the binding, not a frozen copy of the initial value: `incf` changes
that binding, so the next call sees the updated count. Returning the function
keeps the lexical binding available even after `make-counter` finishes.

That gives us the default rule for variables. Next we contrast it with
**special variables**, whose references use the dynamic bindings active when
the function runs. After that, we introduce local function names separately.

## Special (dynamic) variables

### Global is not the meaning of special

Ordinary variables are **lexical**: source-code nesting determines which binding
a reference uses. A **special** variable instead uses **dynamic binding**: a
special reference finds the most recently established binding for that name
that is still active during execution. If no temporary dynamic binding is
active, it uses the global value, if one has been established.

These describe different things:

- **Global binding:** the top-level value available across calls.
- **Special:** the rules for binding and looking up the variable, including
  temporary bindings established with `let` or function parameters.
- **Dynamic extent:** the period while a temporary binding is active. Once
  execution leaves that binding's body, the previous binding is in effect again.

`defparameter` and `defvar` both proclaim a name special globally. They are not
merely ways to create ordinary lexical variables at top level. The earmuffs in
`*report-prefix*` warn readers of this behavior; the punctuation itself has no
effect on scope.

### Defining a special variable and temporarily rebinding it

```lisp
(defparameter *report-prefix* "Report")

(defun report-heading () *report-prefix*)

(report-heading)                ; "Report"

(let ((*report-prefix* "Temporary"))
  (report-heading))            ; "Temporary"

(report-heading)                ; "Report"
```

Read the middle call as follows:

1. `let` establishes a new dynamic binding containing `"Temporary"`.
2. `report-heading` runs while that binding is active. Its reference to
   `*report-prefix*` therefore uses that binding, even though the function's
   definition is outside the `let`.
3. Leaving the `let` removes the temporary binding; the global value is still
   `"Report"`. Normal completion or an exit that unwinds this body restores the
   previous binding. Conditions and such exits are developed in Lessons 04 and 11.

Compare this with the preceding lexical `heading` example: that function reads
`"Report"` despite being called under a new `prefix` binding. The special
reference instead uses the temporary dynamic binding active during the call.

### Rebinding is not assignment

```lisp
(let ((*report-prefix* "Temporary"))
  (setf *report-prefix* "Edited")
  (report-heading))            ; "Edited"

(report-heading)                ; "Report"
```

`let` creates a temporary binding; `setf` changes the binding currently active.
Here the assignment changes only the temporary binding. Without a temporary
binding, assigning to this special variable changes its global value. Restoring
a binding does not undo arbitrary side effects or mutations of shared objects.

### `defparameter` versus `defvar`

| Form | Effect when evaluated |
|---|---|
| `(defparameter *name* initial-form)` | Proclaim the name special and always evaluate the initializer and assign its result. |
| `(defvar *name* initial-form)` | Proclaim the name special; evaluate and assign the initializer only if the variable is unbound. |
| `(defvar *name*)` | Proclaim the name special without supplying an initial value. |

Both accept an optional documentation string after the initializer. **Unbound**
means there is no value, not that the value is `nil`. An existing `nil` value
prevents `defvar` initialization just as any other existing value does.

For example, evaluate these top-level forms in order in a fresh session:

```lisp
(defvar *demo-setting* 10)
(setf *demo-setting* nil)
(defvar *demo-setting* 20)
*demo-setting*                  ; NIL, not 20
(defparameter *demo-setting* 30)
*demo-setting*                  ; 30
```

This explains why reloading definitions can preserve old settings with `defvar`
but reset them with `defparameter`. After globally proclaiming a name
special, a later ordinary `let` using that name also creates a special binding;
removing the definition from a file does not remove the proclamation from the
running session. Use fresh sessions for scope experiments.

### Top-level placement is recommended, not required

`defparameter` and `defvar` can legally appear inside a function or another
form. Nesting does **not** turn them into local definitions: their special
proclamation is global, and leaving the enclosing form does not undo it.

```lisp
(defun initialize-demo-option ()
  (defparameter *demo-option* 10))

(initialize-demo-option)
*demo-option*                  ; 10, still available after the call
```

Each call executes the nested defining form. `defparameter` assigns each time;
`defvar` initializes only if the variable is unbound when the form runs. Do not
rely on defining a function containing one of these forms to initialize the
variable before the function has been called.

There is a further distinction: **the proclamation is global, but assignment
uses the current dynamic binding**, which is not necessarily the global one:

```lisp
(defparameter *demo-option* 10)

(let ((*demo-option* 20))
  (defparameter *demo-option* 30)
  *demo-option*)                ; 30

*demo-option*                  ; 10
```

Likewise, a `defvar` initializer is skipped if a current dynamic binding already
has a value. Neither form creates a fresh temporary binding for its enclosing
body. Use `let` for that purpose. Prefer top-level `defparameter`/`defvar` forms
for clear, predictable global definitions in normal course code; this is a
style recommendation, not a restriction in the language.

### Avoiding collisions: a preview of packages

Nesting a definition does not protect its name from another library. Neither do
earmuffs: `*setting*` is a naming convention, not a private namespace.

A variable name is a **symbol**, and packages organize symbols. For example,
`course-app:*setting*` and `other-library:*setting*` can denote different symbols
with independent bindings, even though both use the spelling `*setting*`.
The text before the colon identifies a package; a single colon refers to a
symbol that package exports as public. These names are illustrative, not forms
to evaluate: those packages have not been defined here.

If two definitions use the **same symbol**, however, a second `defparameter`
can overwrite its value and `defvar` can silently retain the earlier value.
Neither form detects an accidental API collision. Different packages help only
when code actually uses different symbols; importing the same symbol shares
its identity rather than making a private copy.

For early labs in `CL-USER`, use descriptive names and keep private state lexical.
Reusable libraries should have their own distinctive packages and export only
their intended public API. [Lesson 09](09-systems.md#special-variables-and-api-name-collisions)
provides the runnable package example and full syntax. Package boundaries also
protect function names, but are not security barriers.

### Explicit local declarations: `declare (special ...)`

A **declaration** gives the language information about code. At the start of a
binding or function body, `(declare (special name...))` requests special-variable
semantics in that declaration's scope. It is not an ordinary function call, does
not assign a value, and does not by itself proclaim the name special globally.

This self-contained example deliberately uses a name without a global definition:

```lisp
(let ((*local-setting* "Outer"))
  (declare (special *local-setting*))
  (let ((read-setting
          (lambda ()
            (declare (special *local-setting*))
            *local-setting*)))
    (let ((*local-setting* "Inner"))
      (declare (special *local-setting*))
      (funcall read-setting)))) ; "Inner"
```

The outer declaration makes its `let` binding special. The declaration inside
the `lambda` makes its reference special. The inner `let` needs its own
declaration to make its **new binding** special: a local special declaration
does not automatically make every nested binding of the same name special.
Without that inner declaration, the inner binding would be lexical and the
function's special reference would still find `"Outer"`.

For normal global settings, prefer the clearer top-level `defparameter` or
`defvar` pattern. Explicit local declarations are useful to understand when
reading code, but are not required for your stepper. Ordinary private counters
should remain lexical.

### Closures do not retain temporary special bindings

Compare two returned functions:

```lisp
(let ((read-lexical
        (let ((prefix "Saved"))
          (lambda () prefix)))
      (read-special
        (let ((*report-prefix* "Temporary"))
          (lambda () *report-prefix*))))
  (list (funcall read-lexical)
        (funcall read-special))) ; ("Saved" "Report")
```

The lexical closure retains access to its `prefix` binding. The special reference
is resolved when the function runs; its temporary `let` has already finished.
Calling that same function under another active binding of `*report-prefix*`
would use that binding instead. This example assumes the preceding global
definition still has value `"Report"`.

Use special variables for deliberately shared execution-context settings, such
as output streams, not as a replacement for explicit function arguments or
private lexical state.

### Constants are a separate concept

`defconstant` has the basic shape `(defconstant name value)` and establishes a
global constant rather than a dynamically rebound setting. Constant names often
use `+earmuffs+` by convention. It is recognition-only in this lesson; consult
the HyperSpec's `DEFCONSTANT` entry before adding constants whose redefinition
or object identity would matter. No lab requires redefining constants.

## Local named functions

So far we have used globally named functions defined by `defun` and anonymous
functions created by `lambda`. We now give helpers local **function names**.
This adds a separate question: how do we refer to a function, and where is its
name visible? It does not change the variable-binding rules just established.

### Function values versus local function names

Common Lisp has separate variable and function namespaces: a variable name and a
function name can coexist without replacing one another. With a function value
in a variable `f`, write `(funcall f 3)`, not `(f 3)`. The latter looks up a
function name, not the value of the variable `f`.

`#'name` obtains a function object from a function name; it is reader notation
for `(function name)`. Local function names follow the same rule.

### `flet`: local named helpers

Use `flet` when a helper function belongs to one computation rather than the
global API. Its syntax is:

```lisp
(flet ((helper-name (parameters...) helper-body...)
       (another-helper (parameters...) helper-body...))
  body-form...)
```

The names and ellipses here are placeholders. Each entry defines a function;
it is not a call, and there is no `defun` inside the entry. The outer body can
contain several forms and returns the last form's values.

```lisp
(let ((offset 10))
  (flet ((add-offset (number)
           (+ number offset)))
    (list (add-offset 3)
          (funcall #'add-offset 5)))) ; (13 15)
```

The helper can access the surrounding lexical variable `offset`. The outer body
can call it directly as `(add-offset 3)` or obtain its function value using
`#'add-offset`. No global `add-offset` definition is installed. Its local name is
in scope in the `flet` body; a returned function object can nevertheless outlive
that scope, just like the closure returned by `make-counter`.

**Important scope rule:** the new function names are not visible inside any of
the helper definitions in that same `flet`. A call there uses an enclosing
function binding, if one exists; otherwise it refers to a global function.
Definition order does not make sibling helpers visible to each other.

### `labels`: helpers that can call local helpers

`labels` has the same syntax, but its new function names are visible both in
the outer body **and inside all of its helper definitions**. This lets one local
helper call another, regardless of their order:

```lisp
(labels ((add-two (number)
           (add-one (add-one number)))
         (add-one (number)
           (+ number 1)))
  (add-two 5)) ; 7
```

Replacing this `labels` with `flet` would not make the local `add-one` available
inside `add-two`. A leftover global definition could hide that mistake, so check
examples in a fresh session.

Here is a runnable comparison that does not depend on a global definition:

```lisp
(flet ((adjust (number) (+ number 100)))
  (flet ((adjust (number) (+ number 1))
         (use-adjust (number) (adjust number)))
    (list (adjust 5) (use-adjust 5)))) ; (6 105)

(flet ((adjust (number) (+ number 100)))
  (labels ((adjust (number) (+ number 1))
           (use-adjust (number) (adjust number)))
    (list (adjust 5) (use-adjust 5)))) ; (6 6)
```

In both forms, the inner body sees the inner `adjust`. In the first form,
`use-adjust`'s definition sees the enclosing `adjust`, which adds 100. In the
second, it sees the new sibling `adjust`, which adds 1. The enclosing function
binding is shadowed, not changed.

| Need | Choose |
|---|---|
| Store or return an anonymous function value | `lambda` |
| Local named helpers that do not call the new local names | `flet` |
| Helpers that call one another or themselves | `labels` |

A function calling itself is **recursive**; functions calling one another can
be **mutually recursive**. `labels` supports both, but neither is required merely
because you use `labels`. [Lesson 04](04-control.md#recursive-local-helpers-with-labels)
teaches termination and works through recursive examples. For now, concentrate
on which function binding each call sees. Neither construct is inherently a
faster version of the other.

## Lab 03 — Small APIs

### Exercises

1. Implement `price-with-tax` with a required price and keyword `rate`, default
   `1/5`. Return the exact total, not printed text.
2. Implement `make-stepper`, returning a closure that advances a private counter
   by a chosen step. Give it keyword arguments `start` and `step`.
3. Show that two steppers do not share state.
4. Write and run the two [direct-comparison forms](#the-same-names-different-bindings-a-direct-comparison)
   with outer `x = 5`, inner `x = 10`, and `y` initialized from `x`. Predict each
   `(list x y)` result before running it. Write a step-by-step walkthrough of the
   initializer evaluations,
   identify which `x` each reference sees, and explain why the outer binding is
   unchanged. State which form you would choose when one initializer depends on
   an earlier new binding.
5. Review the names in your implementations against this lesson's conventions.
   Keep the required API names, and explain any deliberate naming exceptions.
6. Use `flet` inside a `let` binding `offset` to 20. Define a local helper
   `add-offset` that takes one number and adds the surrounding `offset` value.
   In the `flet` body, return a list containing the results of these two calls:
   - `(add-offset 2)`: call the helper directly by its local function name.
   - `(funcall #'add-offset 5)`: obtain that same helper's function value and
     call it through `funcall`.

   Expect `(22 25)`. These are two ways to call the **same local function**, not
   two different helper definitions. Neither call changes `offset`.

   Then, still inside the `flet` body, try this additional expression:

   ```lisp
   (let ((helper #'add-offset))
     (funcall helper 5)) ; 25
   ```

   Explain the distinction: `#'add-offset` obtains a function by its function
   name, while `helper` reads a variable containing that function. Why would
   `(helper 5)` not call the value stored in the variable? You need not run that
   incorrect call. Keep the required two-call list as your main result; the
   extra expression is a separate check of your understanding.
7. Predict and run the two nested `adjust` examples above. Write down which
   function binding each call uses. Then use `labels` to define local
   `triple` and `triple-plus-one` helpers, where the latter calls the former;
   call `triple-plus-one` with 4. Explain why `flet` would not establish the
   intended helper-to-helper reference.
8. Predict and run the special-variable examples in this section, starting in a
   fresh session. Explain global versus special, rebinding versus assignment,
   and why the two returned functions produce different values. In the local
   declaration example, remove only the innermost declaration and predict the
   result before running it again.

#### How to write the walkthrough for Exercise 4

Here, **trace** means following evaluation by hand and recording your reasoning
in notes. It does **not** mean using the SBCL debugger, a stepper, or Common Lisp's
`trace` facility. No debugger commands are required for this exercise.

For each form, record:

1. Which bindings are visible before entering the inner form.
2. Each initializer, in left-to-right order: which binding any variable reference
   uses, and what value the initializer produces.
3. When each new binding becomes visible.
4. The bindings used by `(list x y)` and its predicted result.
5. Why the outer `x` remains unchanged after the inner form finishes.

For example, a note might read: “The initializer `10` evaluates to 10; with
`let`, the new inner `x` is not visible to the next initializer yet.” Continue
that reasoning yourself for both forms, then evaluate them at the REPL to check
your predictions. The numbered explanations in the
[local-bindings section](#local-bindings-and-assignment) model this procedure.

Tool-assisted function-call tracing and interactive debugging are introduced
in [Lesson 10](10-testing.md); they are different from this written scope walkthrough.

### Acceptance checklist

- [ ] Exercise 1: default tax on 100 returns the exact total 120.
- [ ] Exercise 2: each stepper advances by its configured step from its start.
- [ ] Exercise 3: advancing one stepper does not advance another.
- [ ] Exercise 4: inner `let` gives `y = 5`, while inner `let*` gives `y = 10`;
  both inner bodies see `x = 10`. Your trace distinguishes initializer scope
  from body scope, preserves outer `x = 5`, and justifies the dependency choice.
- [ ] Exercise 5: names use the applicable Common Lisp conventions; ordinary
   lexical variables are not misleadingly marked as special variables/constants.
- [ ] Exercise 6: the result is `(22 25)`; the helper uses the surrounding
  lexical binding without changing it or installing a global helper definition.
  The additional variable-based call returns 25. Your explanation distinguishes
  direct calls by function name, obtaining a function with `#'`, and calling a
  function stored in a variable with `funcall`.
- [ ] Exercise 7: predictions match `(6 105)` and `(6 6)`, with function scope
   explained; `triple-plus-one` returns 13 through the local `triple` helper.
- [ ] Exercise 8: your explanation distinguishes global bindings from dynamic
  lookup, shows restoration after temporary rebinding, and accounts for
  `("Saved" "Report")`. The local declaration example returns `"Inner"` with
  all declarations and `"Outer"` without the innermost one.

### Review questions

1. How are binding, assignment, and mutation different?
2. Why can reloading a file containing `defvar` leave an old value intact?
3. Which naming conventions signal intent without changing language semantics?
4. Do `let` and `let*` evaluate initializer expressions in a different order,
   or do they differ in when the new bindings become visible?
5. Where are new function names visible in `flet` versus `labels`? Does placing
   one `flet` helper before another change that visibility?
6. Why does special not simply mean global? How does a local special declaration
   differ from a global proclamation made by `defparameter` or `defvar`?
7. Does nesting `defparameter` make its definition local? What happens if a
   dynamic binding is active when it assigns? What actually separates two
   libraries' identically spelled variable names?
