# Dynamic scope and special declarations — optional reference

**When to read:** after Lessons 06–08, when you have used function values and
stream settings. **Not required for the core labs.** Lesson 03 teaches everyday
`defvar`, `defparameter`, and temporary `let` bindings; use those patterns first.

This reference preserves answers to deeper scope questions without making them
prerequisites for a beginner's first functions. Read one section when needed,
not the whole page before proceeding with the course.

## Global is not the meaning of special

An ordinary lexical reference uses the binding surrounding its definition.
A special reference uses the most recently established dynamic binding for
that symbol that is still active. Otherwise it uses the global value, if any.

```lisp
(defparameter *report-prefix* "Report")
(defun report-heading () *report-prefix*)

(let ((*report-prefix* "Temporary"))
  (report-heading)) ; "Temporary"

(report-heading) ; "Report"
```

**Global** describes a top-level binding; **special** describes binding and
lookup rules. `defvar` and `defparameter` globally proclaim the name special.
Earmuffs are only a warning to readers. A later `let` of that name therefore
creates a dynamic binding, even though it looks like an ordinary local `let`.

## Rebinding versus assignment

```lisp
(let ((*report-prefix* "Temporary"))
  (setf *report-prefix* "Edited")
  (report-heading)) ; "Edited"

(report-heading) ; "Report"
```

`let` creates a temporary binding; `setf` updates the currently active binding.
Leaving the body, normally or through an exit that unwinds it, restores the
previous binding. This does not undo arbitrary mutations of shared objects.

## Top-level placement is recommended, not required

These forms can occur inside another form. Nesting does not make their special
proclamations local or cause their effects to disappear when a function returns:

```lisp
(defun initialize-demo-option ()
  (defparameter *demo-option* 10))

(initialize-demo-option)
*demo-option* ; 10
```

The form executes when the function is called; do not depend on defining the
function alone to initialize the value. A subtle point: the proclamation is
global, but assignment uses the current binding, not necessarily the global one.

```lisp
(defparameter *demo-option* 10)
(let ((*demo-option* 20))
  (defparameter *demo-option* 30)
  *demo-option*) ; 30
*demo-option*   ; 10
```

`defvar` similarly skips its initializer when a current dynamic binding has a
value. An existing `nil` counts as a value. Without an initializer, `defvar`
only proclaims the name special; it does not default the value to `nil`.
Removing a global proclamation from a source file does not undo it in a running
session. Use fresh processes for these experiments.

## Explicit local declarations: `declare (special ...)`

A declaration provides information about code; it is not an ordinary function
call. `(declare (special name...))` at the beginning of a binding or function
body requests special semantics in its scope. It does not initialize a value
or by itself proclaim the name special globally.

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

The outer declaration makes that binding special; the declaration in `lambda`
makes its reference special. The innermost `let` needs its own declaration for
its **new binding**. Remove only that innermost declaration and the new binding
is lexical: the special reference still finds `"Outer"`. A local declaration
does not automatically make every nested same-named binding special.

This is useful for understanding existing code, not the everyday pattern for
private counters. Keep ordinary state lexical and use top-level `defvar` or
`defparameter` for deliberately shared settings.

## Closures do not retain temporary special bindings

Assuming the preceding global `*report-prefix*` still contains `"Report"`:

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

The first function retains a lexical binding. The second looks up a special
binding when called, after its original temporary binding has ended. Calling
it under another active dynamic binding would use that binding instead.

## Constants and symbol identity

`(defconstant +maximum-items+ 100)` defines a constant: it cannot legally be
assigned or rebound with `let`. The plus signs are a convention, not what
enforces that restriction. This does not deeply freeze an object referenced
by a constant. Redefinition has strict rules; start with simple numeric values
and consult the HyperSpec before using objects whose identity matters.

Packages, not nesting or earmuffs, separate library names. Different symbols
can have the same spelling, such as `course-app:*setting*` and
`other-library:*setting*`. These are illustrative names, not packages defined
by this reference. Importing the same symbol shares its identity rather than
copying it. [Lesson 09](../lessons/09-systems.md#special-variables-and-api-name-collisions)
has a runnable example. Packages are not security boundaries.

## Optional practice

1. Predict and run each example in order in a fresh session.
2. Explain global versus special, and rebinding versus assignment.
3. Explain `("Saved" "Report")` in the closure comparison.
4. Remove only the innermost special declaration and predict `"Outer"` before
   checking it. Do not globally define `*local-setting*` before this experiment.

No part of this exercise is needed to implement a price calculator or stepper.
