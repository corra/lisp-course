# Numeric details — optional reference after Lesson 02

Use this when a calculation needs a particular rounding policy. It is not
required reading before Lesson 03. The core lesson covers exact versus
approximate numbers, and compares `floor` with `truncate` on negative input.

## The numeric tower

Common Lisp includes arbitrary-precision integers, exact ratios, floating-point
numbers, and complex numbers. `expt` raises a number to a power:

```lisp
(expt 2 100) ; an integer, not silent fixed-width overflow
#C(2 3)      ; the complex number 2 + 3i
```

`#C(real imaginary)` is reader notation, not a function call. `1.0d0` requests
a double-float; `1.0` uses the default float format.

## How the four integer-quotient rules differ

Each function accepts `(function number divisor)` and returns an integer
quotient and a remainder. The rule applies to **number divided by divisor**:

| Function | Rule | For `7 / 3` | For `-7 / 3` |
|---|---|---:|---:|
| `floor` | Toward negative infinity | 2 | -3 |
| `ceiling` | Toward positive infinity | 3 | -2 |
| `truncate` | Toward zero | 2 | -2 |
| `round` | Nearest integer; exact ties to even | 2 | -2 |

“Down” is not “toward zero”: -3 is below -7/3. The remainder preserves
`number = quotient * divisor + remainder`:

| Call | Quotient | Remainder |
|---|---:|---:|
| `(floor -7 3)` | -3 | 2 |
| `(ceiling -7 3)` | -2 | -1 |
| `(truncate -7 3)` | -2 | -1 |
| `(round -7 3)` | -2 | -1 |

For nonzero remainders, `floor` gives the divisor's sign, `ceiling` the opposite
sign, and `truncate` the original number's sign. `round` can give either sign.
Negative divisors work too: `(floor 7 -3)` gives -3 and -2. A zero divisor errors.
With floating-point inputs allow for rounding; do not require exact arithmetic
identities where approximation is involved.

## Ties to even

```lisp
(multiple-value-list (round 5 2))   ; (2 1)
(multiple-value-list (round 7 2))   ; (4 -1)
(multiple-value-list (round -5 2))  ; (-2 -1)
(multiple-value-list (round -7 2))  ; (-4 1)
```

These exact integer inputs avoid uncertainty about whether the quotient is
exactly halfway. Approximate decimal inputs may fall slightly either side.

## Omitting the divisor

The divisor defaults to 1:

```lisp
(multiple-value-list (floor 7/3))        ; (2 1/3)
(multiple-value-list (truncate -2.75d0)) ; (-2 -0.75d0)
```

`(floor 7/3)` and `(floor 7 3)` have the same integer quotient but different
remainders: one divides 7/3 by 1, the other divides 7 by 3. The remainder is in
the original number's units. These operations take real numbers, not general
complex numbers.

## Choosing a policy

- Complete groups with nonnegative counts: `floor` often fits.
- Required capacity: `(ceiling 7 3)` gives three containers; its remainder -2
  is not a count of unpacked items.
- Remove fractional parts toward zero: `truncate`.
- Nearest integer when ties-to-even is intended: `round`.

Choose from the problem's rule, not agreement on one positive example.
