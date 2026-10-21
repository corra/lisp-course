# 02 — Values, numbers, symbols, and equality

**Goals:** calculate with exact numbers, use Lisp truth values, and choose a
comparison for your data. **Prerequisite:** 01. **Time:** 4–6 hours.

## Prerequisite recap

- Calls evaluate arguments; quotation preserves data instead of executing it.
- Numbers and strings evaluate to themselves; ordinary variable names are looked up.
- `if` selects one branch; returned values are different from printed output.

**Learn now:** integers versus ratios/floats, `nil` and truth, symbols versus
strings, a few comparisons, and observing multiple values. The numeric tower,
all rounding edge cases, and every equality predicate are reference material,
not a vocabulary test before you can define a function.

## Values have types; bindings need not have a fixed type

`type-of` reports a value's type (the exact printed name can vary). `integerp`
and `numberp` are **predicates**: they ask a question and return true or false.
The suffix `p` or `-p` is a naming convention, not special syntax.

```lisp
(type-of 42)    ; SBCL: (INTEGER 0 4611686018427387903), an integer range
(integerp 42)   ; T
(numberp "42") ; NIL
(/ 3 2)        ; 3/2, an exact ratio
(+ 1/3 1/6)    ; 1/2
(/ 3.0d0 2)    ; 1.5d0, an approximate floating-point result
```

Integers and ratios support exact arithmetic. Floats are approximate; decimal
fractions need not be exactly representable as binary floats. `1.0d0` requests
a double-float. A ratio such as `1/3` is one numeric token; `(/ 1 3)` computes
the same value. Integers can grow beyond fixed machine-word size.

`coerce` converts to a requested type when supported:

```lisp
(coerce 1/2 'double-float) ; 0.5d0
```

The quoted symbol names a type; it is not a variable to read.

## Truth, symbols, characters, and strings

`nil` is both false and the empty list. **Every other value is true**, including
0 and the empty string. `t` is the conventional true value.

```lisp
(if 0 :true :false) ; :TRUE
(not nil)          ; T
(null '())         ; T
#\A                ; a character
"A"                ; a one-character string, not a character
:pending           ; a keyword symbol: evaluates to itself
'pending           ; an ordinary symbol used as data
```

`not` and `null` perform the same test: both return `t` for `nil` and `nil` for
every other value. Use `not` for logical negation and `null` when emphasizing
an empty list. Since `nil` is both false and the empty list, the distinction is
intent, not behavior.

Keywords are useful for named options and categories. A symbol has identity;
a string contains characters. Do not substitute one representation for the other
just because they print similarly. `#\` introduces a character literal.
Packages organize symbols, but no package setup is required until Lesson 09.

## Choose equality deliberately

Start with the comparison that answers your question:

| Question | Use |
|---|---|
| Are these numeric values equal? | `=` |
| Do these strings have the same contents? | `string=` |
| Ignore case when comparing strings? | `string-equal` |
| Do these lists have equal structure and elements? | `equal` |

```lisp
(= 3 3.0)                ; T
(equal '(1 (2)) '(1 (2))) ; T
(string= "Ada" "ada")    ; NIL
(string-equal "Ada" "ada") ; T
```

You will also encounter `eql`, which requires the same numeric type for numeric
equality: `(eql 3 3.0)` is `nil`. `eq` tests object identity, not portable numeric
or string value equality. `equalp` offers more permissive structural comparison.
Exercise 4 uses `eql`; keep `eq` and `equalp` as lookup references. Later
lessons explain where a default equality test matters. `equal` is not a universal comparison for all objects.

## Integer quotients, rounding, and remainders

`/` returns a quotient, possibly a ratio. `floor` and `truncate` instead return
an integer quotient **and** a remainder:

```lisp
(floor 7 3)     ; returns 2 and 1, as separate values
(truncate 7 3)  ; also 2 and 1
(floor -7 3)    ; -3 and 2
(truncate -7 3) ; -2 and -1
```

`floor` rounds the quotient downward; `truncate` rounds toward zero. These agree
for positive 7/3, but not negative -7/3. In each case:
`number = quotient * divisor + remainder`. The remainder need not be positive.

### Capturing both returned values

Separate values are not a list. The REPL displays them separately; an ordinary
argument position uses only the first. `multiple-value-list` collects them:

```lisp
(multiple-value-list (floor -7 3))    ; (-3 2)
(multiple-value-list (truncate -7 3)) ; (-2 -1)
(multiple-value-list (values 10 t))   ; (10 T)
```

`values` returns multiple values deliberately, as needed by Lab 04's `safe-mean`.
Use `multiple-value-list` for the current lab. Named capture with
`multiple-value-bind` comes in Lesson 07, after ordinary local bindings are clear.

`ceiling` rounds upward and `round` rounds to nearest, choosing an even integer
at exact halfway points. You do not need their edge cases for this lab.
[Rounding details](../optional/NUMBERS.md) retains the comparison tables,
negative-divisor examples, and optional-divisor behavior for later lookup.

## Lab 02 — Exact calculations

### Exercises

1. Compute the exact mean of 1, 2, and 2 without introducing floats.
2. Convert that result to a double-float with `coerce`.
3. Predict both values from `(truncate -7 3)` and `(floor -7 3)`. Capture each
   pair with `multiple-value-list`, reconstruct -7, and explain why the
   quotients differ. Repeat with positive 7. You may use `multiple-value-bind`
   if already familiar with it, but it is not required yet.
4. Write examples distinguishing `=`, `eql`, `equal`, and `string-equal`.

### Acceptance checklist

- [ ] Exercise 1: the exact mean is `5/3`.
- [ ] Exercise 2: the result is an approximate double-float.
- [ ] Exercise 3: `truncate` gives -2 and -1; `floor` gives -3 and 2. Both
  pairs reconstruct -7. For positive 7 both give 2 and 1; explain why agreement
  there does not make their rounding rules equivalent.
- [ ] Exercise 4: examples demonstrate the intended equality distinctions.

### Review questions

1. Are zero and an empty string false in Lisp?
2. How does the exact ratio `1/3` differ from a floating-point approximation?
3. Why do numeric equality, string equality, and list equality need different tests?
4. How do two returned values differ from a returned two-element list?
