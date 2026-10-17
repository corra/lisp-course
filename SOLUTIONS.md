# Hints, worked solutions, and review answers

The optional library lab has a separate worked example in
[`optional/libraries/`](optional/libraries/) and an explicit
[`optional/run-library-tests.lisp`](optional/run-library-tests.lisp) driver.
Its [module guide](optional/QUICKLISP.md) explains setup and acceptance criteria;
it is not loaded by the core solutions or test suite.

Attempt the labs first. These are reference approaches, not the only correct
solutions. Full runnable definitions for most programming exercises are in
[`examples/exercise-solutions.lisp`](examples/exercise-solutions.lisp). The three
milestone projects intentionally have specifications rather than complete answers.

Run reference tests:

```sh
sbcl --noinform --no-sysinit --no-userinit --script examples/exercise-solutions.lisp
```

To explore the definitions interactively, load the file, then use
`(in-package #:course-exercises)`. Loading also runs its tests. These are teaching
definitions in a dedicated package, not an installed public library.

## 00 — Setup

A sufficient file is:

```lisp
(defun nickname ()
  (format t "Learner Ada~%"))
(nickname)
```

Load it, run it with `--script`, and compile/load it as in Lesson 00. A REPL
explicitly prints returned values; a script evaluates forms but prints only
explicit output. A function can both print something and return an unrelated
value. `format` with destination `t` normally returns `nil`.

## 01 — Evaluation

```lisp
(* (+ 8 4) (- 9 6))                  ; 36
(list (+ 2 3) '(+ 2 3))              ; (5 (+ 2 3))
(if (> 3 2) :safe (/ 1 0))           ; :SAFE
(progn (format t "ready~%") 42)      ; prints ready, returns 42
```

In the last example, `format` performs the printing; its return value is
discarded. The last form, `42`, supplies the whole `progn`'s return value.
A REPL displays that value after the printed text, while a script displays only
the explicit output. `(progn (+ 1 2) (+ 3 4))` returns `7`, whereas using `list`
instead collects both computed values as `(3 7)`. `progn` is useful inside an
`if` branch because that branch accepts one form, not several separate forms.

An ordinary eager function would evaluate both branch arguments before the call,
so it could not provide `if`'s non-evaluation of the unused branch. A quoted
symbol is an object; a string is a character sequence; a quoted list is data;
an evaluated list normally describes an operation.

## 02 — Values

```lisp
(/ (+ 1 2 2) 3)                     ; 5/3
(coerce 5/3 'double-float)           ; an approximate double-float
(multiple-value-list (truncate -7 3)) ; (-2 -1)
(multiple-value-list (floor -7 3))    ; (-3 2)
(list (= 3 3.0) (eql 3 3.0))         ; (T NIL)
(equal '(1 (2)) '(1 (2)))            ; T
(string-equal "Ada" "ada")           ; T
```

For Lab 02.3, `truncate` chooses -2 because it rounds -7/3 toward zero;
`floor` chooses -3 because it rounds toward negative infinity. Their remainders
then follow from `remainder = number - quotient * divisor`:

```text
truncate: -7 = (-2 * 3) + (-1)
floor:    -7 = (-3 * 3) + 2
```

For positive 7, both choose quotient 2 and remainder 1. That agreement does not
make their policies equivalent: the negative case exposes the difference.
`ceiling` rounds toward positive infinity, while `round` chooses the nearest
integer with exact ties to even. Thus `(round 5 2)` returns `2, 1`, while
`(round 7 2)` returns `4, -1`. A negative remainder is not itself an error; it
is the amount needed to reconstruct the original number from the chosen quotient.

`'()` and `nil` are the same false/empty-list object. An empty string is true.
Integer cents avoid binary rounding for whole-cent amounts, although division,
tax, rounding, and multiple currencies still need domain rules.

## 03 — Functions and scope

See `price-with-tax` and `make-stepper` in the executable answers.

For Lab 03.4, both inner forms evaluate their initializer expressions from left
to right. What changes is when the new bindings become visible:

| Step | Inner `let` | Inner `let*` |
|---|---|---|
| First initializer, `10` | Save 10 as the future value for inner `x`; no inner binding yet | Evaluate 10 and establish inner `x = 10` immediately |
| Second initializer, `x` | Read outer `x = 5`; save 5 as the future value for `y` | Read the already established inner `x = 10`; bind `y` to 10 |
| Inner body, `(list x y)` | Establish both bindings, then return `(10 5)` | Both bindings already exist; return `(10 10)` |
| Outer binding | Still 5; the inner binding shadows it, not assigns it | Still 5; the inner binding shadows it, not assigns it |

Use `let*` for a later initializer that needs an earlier new binding. Use `let`
when the initializers are independent of the new sibling bindings. “Parallel”
binding does not mean concurrent evaluation: both forms evaluate initializers
left to right. The [lesson's worked traces](lessons/03-functions.md#local-bindings-and-assignment)
explain these steps before the exercise.

A binding associates a name with a location/value in an environment. Assignment
changes what a place holds. Mutating a cons or string changes an object that
other references may share. A closure retains lexical bindings, not a frozen
copy of every value. `defvar` intentionally preserves an already-bound value.

For Lab 03.5, `price-with-tax` and `make-stepper` already use conventional
hyphenated function names. Parameters such as `rate`, `start`, and `step`, and
the closure's private counter, are ordinary lexical bindings: do not give them
special-variable earmuffs or constant decorations. Explain exceptions using the
[style guide](STYLE.md), rather than renaming the required API.

## 04 — Control

The executable answers show iterative factorial, sum of squares, and `safe-mean`.
An especially straightforward factorial alternative is:

```lisp
(defun factorial-iter (n)
  (check-type n (integer 0 *))
  (let ((result 1))
    (dotimes (i n result)
      (setf result (* result (1+ i))))))
```

For empty input `safe-mean` returns `(values nil nil)`. For nonempty input it
returns `(values (/ total count) t)`, preserving exact ratios when possible.
`return` exits the nearest lexically enclosing block named `nil` (often a loop).
Tail-call optimization is not a language guarantee; large linear traversals
should not depend on it.

## 05 — Lists

Cell diagrams (`[car | cdr]`, arrows denote references):

```text
(a b c): [A | *] -> [B | *] -> [C | NIL]
(a . b): [A | B]
```

See `count-occurrences` and `replace-first-copy`. A sharing demonstration:

```lisp
(let* ((original (list (list 1 2) 3))
       (copy (copy-list original)))
  (setf (caar copy) 99)
  original) ; ((99 2) 3)
```

Only the spine was copied. `nreverse` can change which original cell is the new
head, so callers must use the returned value. `append` may share its last
argument. Modifying quoted literal data violates the language's contract;
working on one implementation does not make it valid.

## 06 — Sequence processing

The executable answers implement each requested transformation, including a
two-part strict sorting predicate: descending score, then ascending name for ties.
They copy the list spine before sorting. This suffices because sorting rearranges
outer cells rather than modifying the pair objects or their name strings.

`#'` denotes the function namespace and can refer to lexical functions. Quote
produces a symbol, which some APIs also accept as a global function designator,
but it is not the same operation. `apply` spreads its last list; `funcall` with
a list argument passes that list as one value. A called function may mutate data
even when the surrounding code looks like a functional pipeline.

## 07 — Collections

`frequencies`, `lookup-or-error`, and `square-buffer` are executable answers.
`lookup-or-error` uses both `gethash` values and signals a dedicated `missing-key`
condition; a stored `nil` is returned normally.

A small alist is easy to inspect and preserves a deliberate list order. A hash
table is appropriate for many lookups; sort separately for presentation. A vector
is natural for indexed dense data but not itself a mapping from arbitrary names.
A fill pointer counts active entries, while capacity describes storage space.

## 08 — I/O

`count-stream-lines` factors the loop away from opening a file. Tests use string
streams for empty input, one empty line, and an unterminated final line. The file
wrapper uses `with-open-file` to close the resource.

`parse-positive-integer` uses strict `parse-integer` then checks positivity.
`"3x"` signals a parsing error; `"0"` and `"-1"` fail the value constraint. Leading
and trailing whitespace are accepted by this policy.

For milestone 2, a useful tokenizer design walks character positions, remembers
the start of the current word, and emits a `subseq` when whitespace ends it.
Flush the last word at end-of-line. Decide whether punctuation belongs to words;
do not silently promise natural-language tokenization.

Disabling read-time evaluation rejects `#.` execution, but it does not limit
memory use or all reader behavior. Reading trusted Lisp data and accepting
hostile network input are different security problems.

## 09 — Packages and ASDF

Use the three-file pattern in Lesson 09, replacing the package/system names and
exporting only the intended API. The capstone gives a complete multi-file example.
A package controls symbol names; a source file contains forms; ASDF models build
dependencies; a distributor obtains libraries; SBCL implements the language.

## 10 — Tests and debugging

For an ASDF test setup, adapt `capstone/course-tasks.asd`: a main system delegates
its test operation to a secondary `/tests` system, whose `:perform` calls a test
entry point. The test file defines its own package and loads after the library.

An error test must fail if the body returns normally. The supplied `signals`
macro expands to a `handler-case` that returns `nil` on normal completion and
`t` only for the specified condition type. A handler that merely catches all
`error`s can accidentally accept undefined-function errors as validation success.

There is no single required backtrace transcript: exact frames vary by build.
Your explanation should identify an application function and its bad argument,
then show a source fix and regression test.

## 11 — Conditions and restarts

Executable answers include the score condition and recovery example. A reusable
handler should check whether the intended restart exists before invoking it.
For milestone 3, place `restart-case` around validation of each single record,
with a `skip-record` clause that returns a sentinel or zero values under a clear
contract. The caller installs `handler-bind` to select that restart specifically
for your invalid-record condition. Accumulate only successfully validated data.

`handler-case` unwinds before its clause runs, potentially leaving a restart's
dynamic extent. `handler-bind` runs where the signal occurs. `signal` can return
normally when no handler transfers control; `error` cannot simply return normally.

## 12 — Objects

See the executable `reading`, `sensor-alert`, `urgent-alert`, and `render`
definitions. The urgent method prefixes the string returned by
`call-next-method`. Tests verify both default values and inherited behavior.

CLOS generic functions are independent behavior abstractions and can dispatch
on several required parameters. A structure is often sufficient for a record;
a class hierarchy is useful when extensible behavior justifies it. A read-only
accessor is a public API choice, not complete object immutability.

## 13 — Macros

`twice` introduces a fresh temporary to avoid accidental capture and duplicate
evaluation. `when-bind` intentionally uses the caller's chosen variable:

```lisp
(defmacro when-bind ((name expression) &body body)
  `(let ((,name ,expression))
     (when ,name ,@body)))
```

The `let` initializer is outside the scope of its new lexical binding, so the
expression is evaluated in the caller's previous environment and only once.
`0` is true, so the body runs for zero. `nil` skips it. Arithmetic doubling can
be a function; creating a caller-visible lexical binding requires different
syntax or explicit function/closure arguments.

## 14 — Performance

Use `build-with-append` and `build-with-push` from the executable answers. First
assert equality, then time each on 100, 1000, and 5000 elements (adjust if needed).
Repeated append copies an increasingly long prefix and is quadratic in total
copied cells; push/reverse is linear. Actual timings are environment-specific.
There is no canned timing table to memorize. For the word report, include the
tokenizer, counting, sorting, and I/O measurements separately if practical.

Declarations supply compiler assumptions; validation enforces API boundaries.
Source can be recompiled on another conforming implementation; saved SBCL images
are tied to implementation/platform constraints and bundled state.

## 15 — Capstone review

The complete reference is in `capstone/`. Read `package.lisp`, `tasks.lisp`,
`tests.lisp`, the ASD, then `cli.lisp`. Ask:

- Which functions can mutate the store? Which return detached records?
- Why is copying a structure insufficient when its title is a mutable string?
- Where is version validation performed? Why reject extra top-level objects?
- Which parts are standard Common Lisp, ASDF/UIOP, or SBCL-specific?
- What happens on a crash during save? What would a stronger storage contract need?

Version 1 deliberately accepts a canonical field order rather than arbitrary
plist ordering: `:version`, `:next-id`, then `:tasks`. This is a small serialization
protocol, not a general Lisp object loader. Compare your design against the
acceptance criteria, not exact internal helper names.
