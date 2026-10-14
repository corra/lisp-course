# 01 — Reading and evaluating Lisp

**Goals:** read nested forms; separate reading from evaluation; understand
quotation and special operators. **Prerequisite:** 00. **Time:** 4–6 hours.

## The basic model

Lisp source consists of **forms**. Parentheses group expressions, not merely
function arguments. In an ordinary function call, the first position names the
operation and the remaining forms produce arguments:

```lisp
(+ 2 3)                  ; 5
(* (+ 2 3) (- 10 6))     ; 20
(list 1 (+ 1 1) 3)       ; (1 2 3)
```

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

```lisp
(if (> 4 2) "yes" (/ 1 0)) ; "yes"; unused branch is not evaluated
(let ((x 10)) (+ x 2))     ; 12; creates a local binding
(progn (format t "Hi~%") 9) ; prints Hi, returns 9
```

`if`, `let`, and `quote` are special operators. `when` and `defun` are macros.
You can use macros long before you learn to write them. Most positions that
accept several body forms execute them in order and return the last one's
values. There is no mandatory `return` statement at the end of a function.

Symbols are normally read case-insensitively and displayed uppercase. `hello`,
`HELLO`, and `Hello` normally denote the same symbol. Strings preserve case.
Avoid escaped symbol names such as `|MiXeD|` while learning.

## Predict, then test

```lisp
(list (+ 1 2) '(+ 1 2))  ; (3 (+ 1 2))
(if nil "left" "right") ; "right"
(progn (+ 1 2) (+ 3 4))  ; 7
```

Do not reach for `eval` to call a function or process a list. Function calling
uses `funcall`/`apply` (Lesson 06); evaluating arbitrary constructed code is a
different operation with safety and scope consequences.

## Lab 01 — Expression notebook

1. Translate `(8 + 4) * (9 - 6)` into Lisp.
2. Return a two-element list containing the value of `(+ 2 3)` and the unevaluated
   expression `(+ 2 3)`.
3. Write an `if` whose unselected branch divides by zero; prove it is not run.
4. Use `progn` to print `ready` and return `42`.

**Pass:** expected results are `36`, `(5 (+ 2 3))`, a non-error selected value,
and `42` plus explicit output. Explain which forms evaluate their arguments.

**Checkpoint:** What differs between a symbol, a string containing its name,
a quoted list, and a call? Why can't `if` be implemented as an ordinary eager
three-argument function with the same behavior?
