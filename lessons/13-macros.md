# 13 — Macros and code as data

**Goals:** read macro expansions and write a small macro with explicit evaluation
and name-capture guarantees. **Prerequisite:** 12. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 12](12-objects.md):

- Structures/classes model data, and their definitions can provide constructors
  and accessors. Generated names are part of the definition's API, not missing built-ins.
- Generic functions select methods by applicable argument types; use ordinary
  functions and records when a more elaborate object model is unnecessary.
- From [Lessons 01](01-evaluation.md) and [05](05-lists.md), source forms can be
  represented as list data; from [Lesson 03](03-functions.md), lexical bindings
  determine name visibility.

This lesson uses those foundations
to transform source forms while preserving deliberate evaluation and binding rules.

**Focus on one small macro:** inspect an expansion, find repeated evaluation,
then introduce a fresh temporary variable. Those steps are enough for the lab.
The `eval` discussion and compile-time availability section are references for
specific questions, not extra techniques to use in every macro. No macro is
required in the capstone merely to demonstrate that you know how to write one.

## A macro receives forms, not their run-time values

`defmacro` has a name, a parameter list, and an expander body. Unlike `defun`, its
parameters receive the caller's **source forms**, not evaluated argument values.
`&body body` collects the remaining source forms into a list named `body`, like
`&rest` with an intentional body/indentation convention. `when-positive` is the
macro we define below, not a built-in operator.

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
evaluates it. `macroexpand-1` performs one outer expansion and also returns a
second value, true when it performed an expansion; it does not recursively
expand every nested form.

In the template, `,expression` inserts the source form held by the expander's
parameter; `,@body` inserts the list's individual forms, not one nested list.
These comma notations apply inside backquote. The expansion's generated
`when` follows the ordinary control rules taught in Lesson 04.

Use a function whenever ordinary evaluated arguments suffice. A macro is
justified for new binding, control, resource, or syntactic conventions—not merely
to avoid typing a short function call.

**Redefining a macro does not update compiled callers.** A call site is
expanded when its function is compiled, and SBCL compiles definitions as they
are loaded. If you change a macro, functions defined earlier still run the old
expansion until you reload or recompile them. After editing a macro, reload the
files that use it, or restart SBCL and load everything in order. Ordinary,
non-inlined global function calls use the new definition without recompiling
their callers. Inlined callers can retain the old code and need recompilation.

## Evaluation is not macro expansion

**Reference; skip to the repeated-evaluation trap on a first pass.** `eval`
takes a Lisp object and evaluates that object as a form. It does not merely
inspect or expand it. Earlier lessons deliberately did not require using it.

```lisp
(list '+ 2 3)         ; constructs the data (+ 2 3)
(eval (list '+ 2 3))  ; executes that form, returning 5
(funcall #'+ 2 3)     ; calls the function directly, also returning 5
(apply #'+ '(2 3))    ; calls it with arguments from a list, returning 5
```

If your goal is to call a function, choose `funcall` or `apply`, not construction
of a source form followed by `eval`. Use list/sequence operations for processing
data. `eval` is appropriate only when executing Lisp forms is deliberately part
of the program's contract, such as a controlled evaluator for trusted forms.

`eval` evaluates in the **null lexical environment**: it cannot see the caller's
local lexical variables, functions, or macros. Current dynamic special-variable
bindings still apply. Consequently, constructing a symbol with the same name as
a local variable does not give evaluated code access to that variable. Pass data
to ordinary functions or capture lexical bindings in closures instead. The
`*package*` used while reading a symbol determines its identity; it does not give
`eval` access to a caller's lexical bindings.

Contrast `(eval '(+ 2 3))` with the earlier `macroexpand-1` example. `eval`
executes the addition; `macroexpand-1` returns an expansion without executing the
expanded body. A macro normally **returns code** for the compiler/evaluator to
process in its use-site context; its expander should not `eval` the caller's body
as a substitute for returning that code.

`eval` takes an object, not source text to parse. A string evaluates to itself,
so `(eval "(+ 2 3)")` returns the string, not `5`. Adding `read-from-string` would
introduce the reader's own behavior and security concerns, not make user input
safe. Recall Lesson 08: never execute untrusted data, and disabling read-time
evaluation does not make later calls to `eval` safe.

## The repeated-evaluation trap

This macro is wrong for a once-only contract:

```lisp
(defmacro bad-twice (expression)
  `(+ ,expression ,expression))
```

`(bad-twice (incf n))` increments twice. The expansion duplicates the form.
A better macro evaluates the expression once, into a variable with a fresh name.

`gensym`, introduced as an EOF-marker constructor in [Lesson 08](08-io.md),
also creates variable names that cannot accidentally equal a caller's interned
symbol. Below, the local expander variable `value` holds that fresh symbol; comma
inserts the symbol into the generated binding and references:

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

The parameter pattern `((name) &body body)` destructures the macro call's first
argument as a one-element list, binding its element to the expander variable
`name`. It is the source-pattern counterpart of the destructuring introduced
in Lesson 05; the caller's syntax is `(with-collected-output (out) body...)`.
`with-output-to-string` is the stream-binding macro from Lesson 08.

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

**Later reference, not part of Lab 13.** First keep definitions before consumers;
study phase-control forms only when a compile-time helper actually needs them.

Put macro definitions before consumers, normally in an earlier ASDF component.
If a macro's expander calls a helper during compilation, that helper must also be
available then. `eval-when (:compile-toplevel :load-toplevel :execute)` can arrange
this for appropriate top-level definitions, but its semantics depend on context.
Consult the HyperSpec before solving complex phase problems with it.

`eval-when` lists the situations in which its body should be processed:
`:compile-toplevel` allows top-level compile-time evaluation, `:load-toplevel`
arranges for evaluation when the resulting file is loaded, and `:execute`
covers ordinary evaluation outside that file-compilation handling. These are
phase names, not run-time variables. Exact interactions depend on whether the
form is top-level and on surrounding forms; the lab does not require using it.
Consult the HyperSpec's `EVAL-WHEN` entry for the full phase rules rather than
treating it as a general dependency-order repair.

Never use macro expansion to perform surprise file I/O or application mutations.
A file can be compiled repeatedly, and expansion is not a reliable run-time hook.

## Lab 13 — Evaluate once

### Exercises

1. Implement `twice` and show that `(let ((n 0)) (list (twice (incf n)) n))`
   yields `(2 1)`.
2. Write `when-bind`: syntax `(when-bind (name expression) body...)`. Evaluate
   `expression` once, bind its value to `name`, and execute the body only if true.
3. Test true, false, zero, and side-effecting expressions; inspect expansions.
4. Explain which of these macros could instead be a function and what would
   change in the call syntax/evaluation behavior.

### Acceptance checklist

- [ ] Exercise 1: the side-effect test for `twice` returns `(2 1)`.
- [ ] Exercise 2: `when-bind` evaluates its expression once, intentionally binds
  the chosen name for the body, and returns `nil` on false input without capture.
- [ ] Exercise 3: true, false, zero, and side-effect cases behave as documented;
  you can explain the inspected expansions.
- [ ] Exercise 4: your explanation distinguishes ordinary function arguments
  from the macros' binding and evaluation behavior.

### Review questions

1. Why does a macro not simply receive values like a function?
2. What can `gensym` prevent, and what intentional bindings should it not replace?
