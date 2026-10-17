# 02 — Values, numbers, symbols, and equality

**Goals:** use the numeric tower, boolean conventions, predicates, and appropriate
equality tests. **Prerequisite:** 01. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 01](01-evaluation.md):

- Ordinary function calls evaluate their argument forms; quotation preserves
  an object as data instead of evaluating it as code.
- Numbers and strings evaluate to themselves, while ordinary variable names
  are looked up for their values. A list can represent data or an operation, by context.
- `if` evaluates only its chosen branch; `progn` evaluates forms in order and
  returns the last form's values. Returned values are not the same as printed text.

This lesson examines the values those forms produce: numeric types, truth,
symbols, equality, and multiple returned values.

## Values have types; bindings need not have a fixed type

`type-of` reports a value's type (the exact type name can depend on the
implementation). `integerp` and `numberp` are predicates: they test whether a
value is an integer or any number. `expt` raises its first argument to the power
of its second. These names are ordinary built-in functions.

The trailing `p` in `integerp` and `numberp` is a common predicate naming
convention. Compound predicate names often end in `-p`, as in `valid-title-p`.
It is not special syntax, and not every predicate follows it (`equal` and `null`
are examples). See [Lesson 03's naming guide](03-functions.md#predicates-and-truth-valued-names).

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

`#C(real imaginary)` is reader notation for a complex-number literal: `#C(2 3)`
means 2 + 3i, not a call to a function named `C`. A ratio such as `1/3` is one
numeric token; `(/ 1 3)` is a function call that computes the same value.

## Integer quotients, rounding, and remainders

`/` computes a numeric quotient: `(/ 7 3)` gives the exact ratio `7/3`.
Sometimes you instead need an **integer quotient** and the amount left over.
`floor`, `ceiling`, `truncate`, and `round` provide both, using different rules
to choose that integer.

Each has the calling form `(function number divisor)`. For example,
`(floor 7 3)` conceptually:

1. Considers the exact quotient `7/3`, between 2 and 3.
2. Chooses an integer quotient according to its rounding rule—2 for `floor`.
3. Computes the remainder as `number - quotient * divisor`: `7 - 2 * 3 = 1`.
4. Returns **two values**, quotient first and remainder second: `2` and `1`.

These are separate returned values, not the list `(2 1)`. SBCL's REPL displays
them separately. The `multiple-value-bind` example below will collect them so
you can examine both in one list.

### How the four rules differ

The rule applies to **number divided by divisor**, not just to `number`:

| Function | How it chooses the integer quotient | For `7 / 3` | For `-7 / 3` |
|---|---|---:|---:|
| `floor` | Round down, toward negative infinity | 2 | -3 |
| `ceiling` | Round up, toward positive infinity | 3 | -2 |
| `truncate` | Round toward zero: discard the fractional part | 2 | -2 |
| `round` | Choose the nearest integer; exact halfway cases go to the even integer | 2 | -2 |

“Down” does **not** mean “closer to zero.” On a number line, -3 is below -7/3,
while -2 is above it. Thus `floor` and `truncate` agree on `7/3` but disagree on
`-7/3`. Similarly, `ceiling` is not always rounding away from zero.

Once the quotient is chosen, the remainder must preserve this relationship:

```text
number = quotient * divisor + remainder
```

For integer inputs this identity is exact. With floating-point inputs, allow
for floating-point rounding rather than requiring exact arithmetic identities.

For division of -7 by 3:

| Call | Quotient | Remainder | Reconstruction |
|---|---:|---:|---|
| `(floor -7 3)` | -3 | 2 | `-7 = (-3 * 3) + 2` |
| `(ceiling -7 3)` | -2 | -1 | `-7 = (-2 * 3) - 1` |
| `(truncate -7 3)` | -2 | -1 | `-7 = (-2 * 3) - 1` |
| `(round -7 3)` | -2 | -1 | `-7 = (-2 * 3) - 1` |

A remainder is therefore **not necessarily positive**. For nonzero remainders,
`floor` gives the divisor's sign, `ceiling` the opposite sign, and `truncate`
the original number's sign. `round` can give either sign, depending on which
integer is nearest. Negative divisors are allowed too: `(floor 7 -3)` returns
`-3` and `-2`, since `7 = (-3 * -3) - 2`. A zero divisor is an error.

### Capturing both returned values

```lisp
(multiple-value-bind (quotient remainder) (floor -7 3)
  (list quotient remainder)) ; (-3 2)
```

An ordinary argument position uses only a form's primary (first) value.
`multiple-value-bind` evaluates its value-producing form once, binds the listed
names to successive returned values, and executes its body with those bindings.
Here `quotient` and `remainder` are names we choose, not built-ins.
`multiple-value-list` instead collects all returned values into one list.
To return several values yourself, use `(values first-value second-value ...)`;
this does not construct a list. [Lesson 03](03-functions.md) explains local
bindings and function bodies in more detail.

Here are all four results as lists, for comparison:

```lisp
(multiple-value-list (floor -7 3))    ; (-3 2)
(multiple-value-list (ceiling -7 3))  ; (-2 -1)
(multiple-value-list (truncate -7 3)) ; (-2 -1)
(multiple-value-list (round -7 3))    ; (-2 -1)
```

### `round`: nearest integer, with ties to even

Nearest-integer rounding is not the same as always rounding halfway values up.
When exactly halfway between two integers, Common Lisp's `round` chooses the
**even** one:

```lisp
(multiple-value-list (round 5 2))   ; (2 1): 5/2 is 2.5; choose even 2
(multiple-value-list (round 7 2))   ; (4 -1): 7/2 is 3.5; choose even 4
(multiple-value-list (round -5 2))  ; (-2 -1): -2.5; choose even -2
(multiple-value-list (round -7 2))  ; (-4 1): -3.5; choose even -4
```

These examples use exact integers/ratios, so there is no uncertainty about
whether the quotient is exactly halfway. Approximate float inputs can make a
seemingly decimal halfway case slightly above or below the actual midpoint.

### Omitting the divisor

The divisor is optional and defaults to 1. This makes the functions useful for
rounding an individual real number to an integer:

```lisp
(multiple-value-list (floor 7/3))         ; (2 1/3)
(multiple-value-list (truncate -2.75d0))  ; (-2 -0.75d0)
```

Notice that `(floor 7/3)` and `(floor 7 3)` have the same integer quotient but
different remainders: the first divides `7/3` by 1; the second divides 7 by 3.
The remainder is measured in the original number's units, not automatically
as the fractional part of `number / divisor`. These functions take real numbers,
not general complex numbers.

### Choosing a function

- Use `floor` for complete groups when the rule calls for rounding downward;
  for nonnegative counts, `(floor 7 3)` gives two complete groups and one leftover.
- Use `ceiling` for capacity requirements: seven items at three per container
  require `(ceiling 7 3)`, or three containers. Its remainder is -2, not a count
  of unpacked items; the quotient answers this capacity question.
- Use `truncate` when the intended policy is to remove a fractional part toward
  zero, including for negative numbers.
- Use `round` for the nearest integer when ties-to-even is the desired policy.

Choose from the problem's rule, not just from results on one positive example.

## Truth, symbols, characters, and strings

`nil` is both false and the empty list; it evaluates to itself. `t` is the usual
true value and also evaluates to itself. **Every value other than `nil` is true**,
including `0`, `""`, and an empty vector. Predicates can return useful true values
rather than the symbol `t` specifically.

A vector is a one-dimensional array, introduced in [Lesson 07](07-collections.md).
You do not need array syntax to apply the truth rule here.

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

`not` returns true for `nil` and false for every other value. `null` tests for
`nil` too, emphasizing the empty-list interpretation. `#\` introduces a character
literal; named characters such as `#\Space` and `#\Tab` appear in
[Lesson 07](07-collections.md). A package is a namespace for symbols, explained
in [Lesson 09](09-systems.md); no package setup is needed here.

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

For exercise 2, `coerce` converts an object to a requested type when that
conversion is supported: `(coerce 1/2 'double-float)` gives `0.5d0`. The quoted
symbol names the target type; it is not a variable to look up.

### Exercises

1. Compute the exact mean of `1`, `2`, and `2` without introducing floats.
2. Convert that result to a double-float with `coerce`.
3. Before running them, predict both values from `(truncate -7 3)` and
   `(floor -7 3)`. Capture each pair with `multiple-value-list` or
   `multiple-value-bind`. Reconstruct -7 from each pair, and explain why the
   quotients differ. Repeat with positive 7 to show why that case alone does
   not distinguish the two policies.
4. Write examples distinguishing `=`, `eql`, `equal`, and `string-equal`.

### Acceptance checklist

- [ ] Exercise 1: the exact mean is `5/3`.
- [ ] Exercise 2: the converted result is an approximate double-float; you do
  not require exact equality where a floating-point tolerance is needed.
- [ ] Exercise 3: `truncate` returns `-2` and `-1`; `floor` returns `-3` and `2`.
  Both pairs reconstruct -7, and you explain toward-zero versus downward rounding.
- [ ] Exercise 3: for positive 7, both calls return `2` and `1`; you explain
  why this agreement does not make their rounding policies equivalent.
- [ ] Exercise 4: your tests demonstrate the intended equality distinctions.

### Review questions

1. Is `(if '() 1 2)` different from `(if nil 1 2)`?
2. Is an empty string false?
3. Why might using integer cents be simpler than binary floats for money?
4. Why does `(round 7 2)` choose 4 but `(round 5 2)` choose 2?
5. Why can an integer quotient have a negative remainder?
