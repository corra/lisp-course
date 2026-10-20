# 06 — Functions as values and sequence processing

**Goals:** use higher-order functions, closures, sequences, and explicit
comparison policies. **Prerequisite:** 05. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 05](05-lists.md):

- Lists are linked cons structures. `car`/`first` and `cdr`/`rest` access their
  parts; different lists can share cells or nested objects.
- `copy-list` copies the spine, not every referenced object. Never mutate
  quoted literals; document whether callers and results share mutable data.
- `push` followed by `nreverse` can build a list efficiently, but destructive
  operations require ownership and attention to their returned result.

Also recall function values, `lambda`, and `funcall` from
[Lesson 03](03-functions.md#lexical-scope-and-closures). This lesson combines
them with collection traversal, filtering, reduction, and sorting.

## Calling a function value

A **sequence** is a proper list or vector; strings are vectors of characters.
`#'` denotes a function reference, and `lambda` supplies an anonymous function
as introduced in [Lesson 03](03-functions.md#function-values-versus-local-function-names).

```lisp
(funcall #'+ 2 3)           ; 5
(apply #'+ '(2 3 4))        ; 9
(apply #'+ 1 2 '(3 4))      ; 10
(mapcar (lambda (n) (* n n)) '(1 2 3)) ; (1 4 9)
```

`funcall` supplies arguments individually. `apply` takes zero or more leading
arguments and a final list whose elements become trailing arguments. Do not use
`apply` to pass an unbounded dataset as arguments; implementations have argument
count limits. Use `reduce` or a loop for large aggregations.

`mapcar` processes lists and returns a list. `map` handles sequences and takes an
explicit result type: `(map 'vector #'1+ '(1 2 3))` returns `#(2 3 4)`.
Mapping several sequences stops at the shortest. `mapc` is for side effects and
returns its first list argument, not a list of results.

`'vector` names the desired result type. `#(2 3 4)` is printed/read notation for
a vector, not a list or a call; [Lesson 07](07-collections.md) teaches arrays.
`1+` returns its argument plus one (Lesson 04), so `#'1+` passes that function.

## A small transformation pipeline

```lisp
(defun sum-positive-squares (numbers)
  (reduce #'+
          (mapcar (lambda (n) (* n n))
                  (remove-if-not #'plusp numbers))
          :initial-value 0))
```

This reads as filter, transform, aggregate. It allocates intermediate lists.
A single `loop` may be clearer or more memory-efficient; neither style is
automatically superior. `reduce` on an empty sequence without an initial value
has function-dependent behavior; specify the identity when appropriate.

`remove-if-not` keeps elements for which its predicate is true; `plusp` tests
for a positive number (Lesson 04). `reduce` combines elements using the supplied
function; `:initial-value 0` seeds this sum with zero, including on empty input.
An equivalent loop is `(loop for n in numbers when (plusp n) sum (* n n))`:
`in` traverses a list and `sum` accumulates a numeric total, defaulting to zero.

Useful sequence functions have these roles:

| Names | Meaning |
|---|---|
| `length`, `elt` | Active sequence length; element at a zero-based index |
| `subseq` | Extract a subsequence between start and optional exclusive end |
| `find`, `position`, `count` | Find a matching element, its index, or the number of matches |
| `remove`, `remove-if`, `remove-if-not` | Return a sequence omitting a value, true-predicate elements, or false-predicate elements |
| `every`, `some` | Test all elements, or seek a true predicate result |
| `sort`, `stable-sort` | Destructively order a sequence; see the next section |

Many accept `:key` (a projection applied to elements before comparison), `:test`
(the equality predicate), or `:start`/`:end` (a half-open traversal interval).
`evenp` in the example below tests for an even integer. `some` returns the first
true predicate result, or `nil` if none exists.

```lisp
(find "ada" '(("bob" . 3) ("ada" . 5))
      :key #'car :test #'string=) ; ("ada" . 5)
(subseq "abcdef" 1 4)            ; "bcd"
(some #'evenp '(1 3 4))          ; true
```

`find` returns the matching element, so a found `nil` is indistinguishable from
absence using that value alone. `position` returns an index or `nil`; index 0 is
true in Lisp. Choose a representation that does not lose necessary information.

## Sorting and ownership

```lisp
(let ((names (list "Grace" "Ada" "Linus")))
  (sort (copy-list names) #'string<)) ; ("Ada" "Grace" "Linus")
```

`sort` and `stable-sort` may mutate the supplied sequence. Use their return value
and copy first if you do not own the input. A sorting predicate must describe
strict precedence, not `<=`. `stable-sort` preserves the relative order of ties.

`string<` compares strings lexicographically and supplies the alphabetical ordering
used here; `string=` instead tests equality. In the `find` example, `:key #'car`
compares the sought name with each pair's first part, not with the whole pair.
For Lab 06, a **projection function** means any function extracting/computing the
quantity to aggregate, such as `#'cdr` for scores stored in dotted pairs.

`identity` is the function that returns its argument unchanged. The worked
tests use `#'identity` when an API expects a projection but no transformation
is desired.

## Lab 06 — Data pipeline

### Exercises

1. Write `positive-squares`, preserving input order and leaving the input unchanged.
2. Write `total-by` taking a projection function and a list, returning the sum
   of projected values. Return 0 for an empty list.
3. Sort an alist of string names and scores by descending score, with ascending
   string names for ties, without mutating the input.
4. Write both a pipeline and a one-pass loop for positive-square totals; test
   equivalent behavior before discussing allocation.

### Acceptance checklist

- [ ] Exercise 1: `(-2 0 3 1)` produces `(9 1)` in that order without mutation.
- [ ] Exercise 2: projected values are summed correctly; an empty input returns 0.
- [ ] Exercise 3: scores sort descending, names break ties ascending, and the
  caller's original list order remains intact.
- [ ] Exercise 4: the pipeline and one-pass loop return equivalent totals.

### Review questions

1. Why is `#'` clearer than quote when referring to a function?
2. How does `apply` differ from passing one list argument?
3. Does functional-looking code guarantee that no mutation occurs?
