# 01 — Reading and evaluating Lisp

**Goals:** read nested forms; separate reading from evaluation; understand
quotation and special operators. **Prerequisite:** 00. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 00](00-environment.md):

- The Linux shell launches SBCL; the Lisp REPL reads and evaluates Lisp forms.
- Save definitions in `.lisp` files, then load/reload them; restart to check that
  your saved source works without leftover session state.
- The REPL displays returned values automatically; scripts display only explicit
  output. Printing a greeting and returning a value are different actions.

You can now run examples reliably. This lesson explains how their forms are read
and evaluated, rather than asking you to treat the setup file as unexplained syntax.

**What to learn now:** calls versus data, quotation, choosing a branch with `if`,
and grouping sequential work with `progn`. Other forms are identified as previews
with links to their teaching lessons; you do not need to understand macro writing
or function-definition syntax to complete this lesson.

## The basic model

Lisp source consists of **forms**. Parentheses group expressions, not merely
function arguments. In an ordinary function call, the first position names the
operation and the remaining forms produce arguments:

The ordinary numeric functions `+`, `-`, `*`, and `/` mean addition, subtraction,
multiplication, and division. They are written before their operands rather than
between them. [Lesson 02](02-values.md) develops their numeric results.

```lisp
(+ 2 3)                  ; 5
(* (+ 2 3) (- 10 6))     ; 20
(list 1 (+ 1 1) 3)       ; (1 2 3)
```

`list` constructs a list containing its evaluated arguments. Here it receives
the values `1`, `2`, and `3`; it does not preserve the expression `(+ 1 1)`.

Arguments are evaluated left to right. Indent nested forms to show structure.
Semicolons introduce line comments; `#| ... |#` delimits nestable block comments.
Whitespace generally separates tokens; indentation is for humans. Do not put a
closing parenthesis on every separate line as if it were a brace language.

The reader turns text into Lisp objects. The evaluator assigns meaning to those
objects. Numbers and strings evaluate to themselves. An ordinary symbol such as
`total` is looked up as a variable. A list in an evaluated position is generally
a call or a special form—not automatically a list of data.

```lisp
42                       ; 42
"hello"                  ; "hello"
'(red green blue)        ; (RED GREEN BLUE)
(quote (red green blue)) ; same meaning as the previous form
```

`'` is reader notation for `quote`. Quotation suppresses evaluation of its
argument. `(1 2 3)` is not how you construct a list at run time: it attempts to
use `1` as an operator and is invalid. Use `(list 1 2 3)` or quoted data.

## Not everything is an ordinary function

An **ordinary function** receives evaluated argument values. A **special
operator** has its own evaluation rules. A **macro** expands a source form into
another form before that resulting form is evaluated or compiled.

### `if`: choose one branch

`if` has the shape `(if test then-form else-form)`. It evaluates the test, then
evaluates **only one** branch. The chosen branch's result is the result of the
whole `if`. The `>` function compares numbers; `(> 4 2)` is true.

```lisp
(if (> 4 2) "yes" (/ 1 0)) ; "yes"; the division is never evaluated
```

The else-form can be omitted; a false test then gives `nil`, Lisp's false value.
[Lesson 02](02-values.md) explains truth values fully, and
[Lesson 04](04-control.md) develops conditional control flow.

### `progn`: do several things, return the last result

`progn` is a **special operator for sequencing**. Its shape is
`(progn form-1 form-2 ... form-n)`: evaluate the enclosed forms in order, from
left to right, and return the last form's result. Earlier forms still run, but
their return values are discarded. It does not collect the results into a list.

```lisp
(progn
  (+ 1 2)     ; evaluated first; its result, 3, is discarded
  (+ 3 4))    ; evaluated last; 7 becomes the result of the whole progn
```

Earlier forms are most useful when they have a **side effect**: an observable
action such as printing text, rather than just computing a value.

```lisp
(progn
  (format t "Hi~%")
  9)
```

Step through this example:

1. `(format t "Hi~%")` prints `Hi` followed by a newline. For now, `t` means
   the usual output destination, and `~%` means a newline. Its return value is
   discarded here. [Lesson 08](08-io.md) teaches `format` in detail.
2. The number `9` evaluates to itself.
3. The whole `progn` returns `9`. The REPL displays that result **in addition to**
   the text already printed. A script prints `Hi` but does not automatically
   display the returned `9`.

Why group forms? Each `if` branch has room for **one form**. A `progn` occupies
that one position while letting the chosen branch perform several steps:

```lisp
(if (> 4 2)
    (progn
      (format t "The test passed.~%")
      (+ 20 22))
    0) ; prints the message and returns 42
```

You do not need `progn` around every sequence of expressions. At the top-level
REPL you can enter forms one at a time; a source file can also contain successive
top-level forms. Use `progn` when several operations must fit into one form.
With no enclosed forms, `(progn)` returns `nil`. In Lesson 02 you will also learn
that a form can return multiple values; `progn` preserves the last form's values,
not just its primary value.

### Previews: `let`, `when`, and `defun`

You will meet these names in explanations and examples. Here is enough to
recognize their purpose; **their full use is not required in Lab 01**:

| Form | Purpose | Where it is taught |
|---|---|---|
| `let` | Create local variable bindings for a body of forms | [Lesson 03 — local bindings](03-functions.md#local-bindings-and-assignment) |
| `defun` | Define a named function with parameters and a body | [Lesson 03 — definitions](03-functions.md#definitions-and-argument-lists); first encountered in Lesson 00's setup file |
| `when` | Run a body of forms only when a test is true | [Lesson 04 — one-sided tests](04-control.md#one-sided-tests-when-and-unless) |

For example, this `when` has the same behavior as the preceding `if`: a true test
prints the message and returns `42`. If the test is false, it does nothing and
returns `nil`, rather than the `0` used by that `if`.

```lisp
(when (> 4 2)
  (format t "The test passed.~%")
  (+ 20 22))
```

`when` already accepts several body forms, so you do not need an extra `progn`
inside it. Function bodies defined with `defun` similarly execute their body
forms in order and return the last form's values; Lesson 03 explains this when
you start defining your own functions. There is no mandatory final `return`
statement.

`if`, `progn`, `let`, and `quote` are special operators. `when` and `defun` are
macros, not ordinary function calls. This classification explains why they need
not follow ordinary argument-evaluation rules; it is not a requirement to learn
their implementation now. [Lesson 13](13-macros.md) teaches macro expansion and
writing macros. You can use a macro long before learning to write one.

Symbols are normally read case-insensitively and displayed uppercase. `hello`,
`HELLO`, and `Hello` normally denote the same symbol. Strings preserve case.
Avoid escaped symbol names such as `|MiXeD|` while learning.

For names you choose, write lowercase words separated by hyphens, such as
`task-count`, rather than `taskCount` or `task_count`. Hyphens inside a symbol
are part of its name, not subtraction operators. [Lesson 03's naming guide](03-functions.md#naming-conventions)
explains predicates, special variables, constants, constructors, and the
difference between community conventions and language rules.

## Predict, then test

```lisp
(list (+ 1 2) '(+ 1 2))  ; (3 (+ 1 2))
(if nil "left" "right") ; "right"
(progn (+ 1 2) (+ 3 4))  ; 7
```

### Preview: `eval` treats an object as code

`eval` is a function that takes a Lisp object and evaluates it as a form. For
example, quotation below first supplies a list as data; `eval` then treats that
list as an expression to execute:

```lisp
'(+ 1 2)        ; the list (+ 1 2), without performing the addition
(eval '(+ 1 2)) ; 3
```

You do **not** need `eval` for an ordinary expression such as `(+ 1 2)`: Lisp
already evaluates that expression normally. Nor should you use it just to call
a function or process list data. You do not need to use `eval` in Lab 01.

[Lesson 06](06-sequences.md) teaches `funcall` and `apply` for calling function
values. [Lesson 08](08-io.md#parse-user-input-dont-evaluate-it) explains why user
input must not be executed as code. The fuller explanation of `eval`, including
its scope rules and how it differs from macro expansion, is in
[Lesson 13 — evaluation versus expansion](13-macros.md#evaluation-is-not-macro-expansion).

## Lab 01 — Expression notebook

### Exercises

1. Translate `(8 + 4) * (9 - 6)` into Lisp.
2. Return a two-element list containing the value of `(+ 2 3)` and the unevaluated
   expression `(+ 2 3)`.
3. Write an `if` whose unselected branch divides by zero; prove it is not run.
4. Use `progn` to print `ready` and return `42`. Identify which form prints,
   which form supplies the return value, and what a script versus a REPL displays.

### Acceptance checklist

- [ ] Exercise 1: the expression returns `36`.
- [ ] Exercise 2: the result is `(5 (+ 2 3))`; you explain what was evaluated
  and what was preserved as data.
- [ ] Exercise 3: the selected branch returns normally without division by zero.
- [ ] Exercise 4: the form prints `ready` and returns `42`; you distinguish
  explicit output from the REPL's display of a returned value.

### Review questions

1. What differs between a symbol, a string containing its name, a quoted list,
   and a call?
2. Why can't `if` be implemented as an ordinary eager three-argument function
   with the same behavior?
3. How does `(progn (+ 1 2) (+ 3 4))` differ from `(list (+ 1 2) (+ 3 4))`,
   and why might an `if` branch need `progn`?
