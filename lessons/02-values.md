# 02 — Values, numbers, symbols, and equality

**Goals:** use the numeric tower, boolean conventions, predicates, and appropriate
equality tests. **Prerequisite:** 01. **Time:** 4–6 hours.

## Values have types; bindings need not have a fixed type

```lisp
(type-of 42)
(integerp 42)            ; T
(numberp "42")          ; NIL
(/ 3 2)                 ; 3/2, an exact ratio
(+ 1/3 1/6)             ; 1/2
(expt 2 100)            ; an integer, not silent fixed-width overflow
(/ 3.0d0 2)             ; 1.5d0, a double-float
#C(2 3)                 ; a complex number
```

Common Lisp includes integers (including arbitrary-precision integers), ratios,
floating-point numbers, and complex numbers. Exact arithmetic is valuable for
counts and rational quantities. Floats approximate real values; do not expect
decimal fractions to be exact binary floats. `1.0d0` explicitly requests a
double-float; the precision of `1.0` follows the default float format.

`floor`, `ceiling`, `truncate`, and `round` return both an integer quotient and
a remainder. Their rounding policies differ, especially for negative inputs.

```lisp
(multiple-value-bind (quotient remainder) (floor -7 3)
  (list quotient remainder)) ; (-3 2)
```

An ordinary argument position uses only a form's primary value. Use
`multiple-value-bind` or `multiple-value-list` when you need more.

## Truth, symbols, characters, and strings

`nil` is both false and the empty list; it evaluates to itself. `t` is the usual
true value and also evaluates to itself. **Every value other than `nil` is true**,
including `0`, `""`, and an empty vector. Predicates can return useful true values
rather than the symbol `t` specifically.

```lisp
(if 0 :true :false)       ; :TRUE
(not nil)                ; T
(null '())               ; T
#\A                      ; a character
"A"                      ; a one-character string, not a character
:pending                 ; a keyword symbol, self-evaluating
'pending                 ; an ordinary symbol, quoted to use as data
```

Keywords are useful named options and small categorical values. Symbols have
identity and a home package; strings are sequences of characters. They are not
interchangeable representations of a name.

## Choose equality deliberately

| Predicate | Intended use |
|---|---|
| `eq` | Object identity; especially symbols; do not use for numeric value comparison |
| `eql` | Same-type numeric/character value, otherwise identity; common default |
| `=` | Numeric equality, including across numeric types |
| `equal` | Structural lists, string contents (case-sensitive), and some other types |
| `equalp` | More permissive structural comparison, including case-insensitive strings and numeric `=` behavior |
| `string=` / `string-equal` | Case-sensitive / case-insensitive string comparison |

```lisp
(= 3 3.0)                 ; T
(eql 3 3.0)               ; NIL
(equal '(1 (2)) '(1 (2))) ; T
(string= "Ada" "ada")     ; NIL
(string-equal "Ada" "ada") ; T
```

Do not use `eq` to compare numbers or character values: results are not a portable
value-equality test. `equal` is not a universal deep comparison of all objects.

## Lab 02 — Exact calculations

1. Compute the exact mean of `1`, `2`, and `2` without introducing floats.
2. Convert that result to a double-float with `coerce`.
3. Capture both values from `(truncate -7 3)` and compare with `floor` above.
4. Write examples distinguishing `=`, `eql`, `equal`, and `string-equal`.

**Pass:** mean `5/3`, approximate double-float, truncate values `-2` and `-1`, and
tests showing the intended distinctions. Never compare float approximations with
exact equality when a tolerance is needed.

**Checkpoint:** Is `(if '() 1 2)` different from `(if nil 1 2)`? Is an empty string
false? Why might using integer cents be simpler than binary floats for money?
