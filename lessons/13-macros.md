# 13 — Macros and code as data

**Goals:** read macro expansions and write a small macro with explicit evaluation
and name-capture guarantees. **Prerequisite:** 12. **Time:** 4–6 hours.

## A macro receives forms, not their run-time values

```lisp
(defmacro when-positive (expression &body body)
  `(when (plusp ,expression)
     ,@body))

(macroexpand-1 '(when-positive (+ 1 2) (format t "yes~%")))
```

Backquote constructs a template. Comma inserts one expression's value while
constructing that template. Comma-at splices the elements of a list into it.
This happens in the macro expander, not as arbitrary evaluation of user source.

The expansion is ordinary Lisp code. The compiler compiles it or the evaluator
evaluates it. `macroexpand-1` performs one outer expansion and also returns an
expanded-p value; it does not recursively expand every nested form.

Use a function whenever ordinary evaluated arguments suffice. A macro is
justified for new binding, control, resource, or syntactic conventions—not merely
to avoid typing a short function call.

## The repeated-evaluation trap

This macro is wrong for a once-only contract:

```lisp
(defmacro bad-twice (expression)
  `(+ ,expression ,expression))
```

`(bad-twice (incf n))` increments twice. The expansion duplicates the form.
A better macro uses a fresh temporary symbol:

```lisp
(defmacro twice (expression)
  (let ((value (gensym "VALUE")))
    `(let ((,value ,expression))
       (+ ,value ,value))))
```

`gensym` avoids capturing a caller's binding with an accidentally identical name.
Common Lisp macros are not automatically hygienic. Inspect expansions and test
with side effects and suspicious caller variable names. Literal helper symbols
in a macro expansion also have package identities; macro-defining packages should
manage their dependencies intentionally.

Even `twice` would usually be a function in real code. It is an exercise in
evaluation semantics, not a recommendation to replace arithmetic functions with
macros.

## A binding macro

```lisp
(defmacro with-collected-output ((name) &body body)
  `(with-output-to-string (,name)
     ,@body))
```

Here the binding of `name` is intentional: the caller chooses it and refers to
it in the body. Document intentional binding separately from accidental capture.
The standard macro already exists; wrapping it is useful only if your application
adds a real convention.

## Compile-time availability

Put macro definitions before consumers, normally in an earlier ASDF component.
If a macro's expander calls a helper during compilation, that helper must also be
available then. `eval-when (:compile-toplevel :load-toplevel :execute)` can arrange
this for appropriate top-level definitions, but its semantics depend on context.
Consult the HyperSpec before solving complex phase problems with it.

Never use macro expansion to perform surprise file I/O or application mutations.
A file can be compiled repeatedly, and expansion is not a reliable run-time hook.

## Lab 13 — Evaluate once

1. Implement `twice` and show that `(let ((n 0)) (list (twice (incf n)) n))`
   yields `(2 1)`.
2. Write `when-bind`: syntax `(when-bind (name expression) body...)`. Evaluate
   `expression` once, bind its value to `name`, and execute the body only if true.
3. Test true, false, zero, and side-effecting expressions; inspect expansions.
4. Explain which of these macros could instead be a function and what would
   change in the call syntax/evaluation behavior.

**Pass:** `when-bind` binds intentionally, evaluates the expression once, and
returns `nil` on false input. Its body can access `name` without outside capture.

**Checkpoint:** Why does a macro not simply receive values like a function?
What can `gensym` prevent, and what intentional bindings should it not replace?
