# 03 — Functions, bindings, and scope

**Goals:** define small functions, use local working variables, and distinguish
local bindings from top-level variables. **Prerequisite:** 02. **Time:** 4–6 hours.

## Prerequisite recap

- Calls evaluate their arguments; `if` selects one branch.
- A body can perform several operations and return its last result.
- Integers and ratios support exact arithmetic; `nil` is false.

**Learn now:** `defun`, simple `let`, `setf`/`incf`, dependent bindings with
`let*`, keyword defaults, and ordinary use of `defvar`/`defparameter`.
The closure example is a guided extension, revisited in Lesson 06. Explicit
special declarations and subtle scope exceptions are **not prerequisites** here.

## Naming conventions

Write names in lowercase with hyphens: `rectangle-area`, `price-with-tax`,
`task-count`. Normal Lisp reading treats uppercase and lowercase spellings as
the same symbol; uppercase REPL output is expected.

### Predicates and truth-valued names

Predicates commonly end in `p` or `-p`: `integerp`, `valid-title-p`. They may
return any non-`nil` true value. Use descriptive names, not punctuation to guess
what a function does.

Ordinary local variables need no decoration. Top-level special variables use
`*earmuffs*`, explained below. Follow the required exercise API names and avoid
redefining standard functions such as `list` or `count`. The [style guide](../STYLE.md)
is a lookup reference: apply naming and indentation now, later conventions when
their features are taught. Do not study its entire table before writing a function.

## Definitions and argument lists

```lisp
(defun rectangle-area (width height)
  "Return the area of a rectangle."
  (* width height))

(rectangle-area 3 4) ; 12
```

`defun` names a function. `(width height)` lists required parameters; a call
supplies their argument values. The optional string documents the function.
Evaluating the definition makes it available; calling it executes the body.

A function body can contain several forms and returns the last form's values.
You do not need `progn` around the body or a final `return` statement.

## Local bindings and assignment

### Start with `let`

A **binding** associates a variable name with a value. `let` creates local
bindings, executes a body, and returns its last result:

```lisp
(let ((width 3)
      (height 4))
  (* width height)) ; 12
```

The binding list contains `(name initial-form)` entries, not calls to `width`
or `height`. Each **initializer** computes an initial value. The body can use
these names; they are not defined globally by this form.

Use this for intermediate results inside functions:

```lisp
(defun rectangle-cost (width height price-per-unit)
  "Return the cost of a rectangle at PRICE-PER-UNIT."
  (let ((area (* width height)))
    (* area price-per-unit)))

(rectangle-cost 3 4 2) ; 24
```

### Updating a variable: `setf` and `incf`

```lisp
(let ((total 10))
  (incf total 3)
  (setf total (* total 2))
  total) ; 26
```

`(setf place new-value)` assigns to an existing place. A variable is one kind
of place; later lessons update collection elements too. `(incf place)` adds 1;
`(incf place amount)` adds the specified amount and returns the new value.
Neither creates a local binding. You may see `setq` for variable assignment;
prefer the more general `setf` in this course. There is no performance reason
to choose `setq` over `setf` for an ordinary variable.

### Dependent initializers: `let*`

Both `let` and `let*` evaluate initializers left to right. With `let`, the new
bindings become visible only after **all** initializers have run. With `let*`,
each new binding is visible to later initializers:

```lisp
(let* ((width 3)
       (height (+ width 1)))
  (* width height)) ; 12
```

Use `let` for independent initializers; use `let*` when a later one depends on
an earlier new binding. The star is part of the operator's name, not multiplication.

### The same names, different bindings: a direct comparison

An inner binding can **shadow** an outer one: references in its scope use the
inner binding. This creates a separate binding, not an assignment to the outer one.

```lisp
(let ((x 5))
  (let ((x 10)
        (y x))
    (list x y))) ; (10 5)

(let ((x 5))
  (let* ((x 10)
         (y x))
    (list x y))) ; (10 10)
```

For the inner `let`: evaluate 10, then read the outer `x` (5); only then
establish inner `x = 10` and `y = 5`. For `let*`: establish inner `x = 10`
before reading `x` to initialize `y`. Both bodies see the inner `x`.
The outer binding remains 5 in both cases; it has not been assigned a new value.
“Parallel bindings” for `let` refers to visibility, not threads or simultaneous
evaluation.

## Top-level variables for shared settings

Use local variables and function parameters for normal working state. Sometimes
a setting should be available across several calls. Define that at top level:

```lisp
(defvar *default-unit-price* 2
  "Default price per square unit for estimates.")

(defun estimated-cost (width height)
  "Return an estimate using the current default unit price."
  (let ((area (* width height)))
    (* area *default-unit-price*)))

(estimated-cost 3 4) ; 24
```

Here `area` is local to a call; `*default-unit-price*` is a shared setting.
The surrounding asterisks warn readers of that different role.

`defvar` initializes only if the variable is **unbound** (has no value).
`defparameter` always evaluates its initializer and assigns the result:

```lisp
(setf *default-unit-price* 3)
(defvar *default-unit-price* 2)
*default-unit-price* ; 3: the existing value is preserved

(defparameter *default-unit-price* 2)
*default-unit-price* ; 2: the value is reset
```

Both establish special-variable behavior. For now, recognize one practical
effect: `let` can temporarily rebind such a setting for calls made in its body:

```lisp
(let ((*default-unit-price* 5))
  (estimated-cost 3 4)) ; 60

(estimated-cost 3 4)    ; 24: the global setting is still 2
```

An ordinary local variable is **lexical**: code nesting determines which binding
it refers to. A **special** variable uses the current dynamic binding, so the
function above sees the temporary setting while the `let` is active.
The naming convention alone does not make a variable special.

`(defvar *name*)` is legal but supplies no value; reading a still-unbound variable
signals an error. `defparameter` requires an initializer. An explicit `nil` is a
value, not “unbound.” Keep these definitions at top level for clarity; nesting
them is legal but does not create private local definitions.

**Stop at this level of scope detail on a first pass; continue to named options
below.** You do not need `declare`, global proclamation rules, or
closure/special-binding interactions to write these APIs. Return to
[dynamic-scope details](../optional/DYNAMIC-SCOPE.md) after Lesson 08, when stream
settings give those details a practical context. [Lesson 09](09-systems.md)
explains how packages keep different libraries' names separate; earmuffs do not.

## A named option with a default

```lisp
(defun greet (name &key (prefix "Hello"))
  (format nil "~A, ~A" prefix name))

(greet "Ada")                   ; "Hello, Ada"
(greet "Ada" :prefix "Welcome") ; "Welcome, Ada"
```

`&key` introduces keyword arguments. `(prefix "Hello")` gives a parameter and
its default; the keyword `:prefix` supplies a different value at the call site.
Required parameters come first. `format nil` returns a string; each `~A` inserts
the corresponding argument. `format t` prints instead, and `~%` adds a newline.
The full formatting guide is in Lesson 08.

That is enough argument-list syntax for Lab 03. Positional defaults (`&optional`)
and collecting arguments (`&rest`) are taught in
[Lesson 06](06-sequences.md#more-argument-list-options), when you have more
practice with lists and functions.

## Guided extension: lexical scope and closures

**Optional until Lesson 06.** A function can return another function. `lambda`
creates an anonymous function; `funcall` calls a function stored in a variable.

```lisp
(defun make-counter (&key (start 0))
  (let ((count start))
    (lambda () (incf count))))

(let ((next (make-counter :start 10)))
  (list (funcall next) (funcall next))) ; (11 12)
```

`make-counter` creates a private `count` binding and returns a function without
calling it. The empty parameter list `()` means that returned function takes no
arguments. Each later call advances the same binding. This function is a
**closure**: it retains access to its surrounding lexical bindings after the
creating call finishes. Separate calls to `make-counter` create separate counters.

If this is too much at once, complete the core exercises and return after
Lesson 06's function-value examples. Closures are not needed for Lesson 04's loops.

## Lab 03 — Small APIs

### Exercises

**Core path: exercises 1–4.** Exercise 5 is a guided extension; Lab 06.5
revisits it once function values have been taught, so it does not block Lesson 04.

1. Implement `price-with-tax` with required price and keyword `rate`, default
   `1/5`. Return the exact total, not printed text.
2. Predict and run the two direct-comparison forms above. Write down each
   initializer's value and which `x` it reads, when the new bindings become
   visible, and why the outer `x` is unchanged. Choose the form appropriate
   when one initializer needs an earlier new binding.
3. Define `*default-unit-price*` with `defvar` and run `estimated-cost` above.
   Change the setting with `setf`, repeat `defvar`, then reset it with
   `defparameter`. Record the estimates and explain which values are local and
   which are shared. Finally try the temporary `let` binding shown above.
4. Review your names for lowercase hyphenation and appropriate earmuffs.
   Keep the required API names; no full style-guide audit is expected yet.
5. **Extension; revisit in Lab 06.5:** implement `make-stepper`, returning a
   closure that advances a private counter by a chosen step. Give it keyword
   arguments `start` and `step`. Adapt the `make-counter` example: its `let`
   belongs outside `lambda`, so the counter is initialized once per stepper.
   Show that two steppers do not share state.

Local-function practice with `flet` and `labels` is in Lab 06. Optional
special-declaration practice is in the [dynamic-scope reference](../optional/DYNAMIC-SCOPE.md),
best taken after Lesson 08.

### How to write the walkthrough for Exercise 2

“Trace” here means a written walkthrough, not the SBCL debugger or Lisp's
`trace` facility. For each form, record the outer binding, the initializers in
order, the point when inner bindings become visible, and the body's result.
Then check your prediction at the REPL. No new tooling is needed.

### Acceptance checklist

- [ ] Exercise 1: default tax on 100 returns the exact total 120.
- [ ] Exercise 2: inner `let` returns `(10 5)`; inner `let*` returns `(10 10)`.
  Your written explanation distinguishes initialization from body scope and
  shows that outer `x` remains 5.
- [ ] Exercise 3: changing the setting changes estimates; repeating `defvar` keeps
  its value, `defparameter` resets it, and temporary rebinding leaves the global
  value unchanged. `area` remains local to each call.
- [ ] Exercise 4: names follow the conventions introduced here.
- [ ] Extension 5: each stepper advances independently by its configured step.

### Review questions

1. How does creating a binding differ from assigning a new value to one?
2. When does an initializer need `let*` rather than `let`?
3. Why can reloading a file containing `defvar` preserve an old setting?
4. How do local working variables differ from a top-level shared setting?
