# 07 — Arrays, strings, and hash tables

**Goals:** choose data structures and understand capacity, presence, and equality.
**Prerequisite:** 06. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 06](06-sequences.md):

- Functions are values: pass them to `funcall`, `apply`, mapping, filtering,
  and reduction operations rather than constructing code for `eval`.
- Sequence operations can use explicit projections, equality tests, and bounds;
  lists, vectors, and strings share useful sequence interfaces.
- Sorting can mutate its input, and deterministic output needs an explicit
  ordering/tie policy. Copy when you do not own the sequence being sorted.

This lesson develops the alternative representations behind those interfaces:
arrays/vectors, strings, and hash tables for keyed lookup.

**Work in short stages:** change one vector element, transform one string, then
build a tiny hash table. Only combine them after each works independently.
The growable-vector recipe is for exercise 3; multidimensional arrays and
Unicode caveats are reference context, not new algorithms to implement here.

## Arrays and vectors

A vector is a one-dimensional array. General arrays can have multiple dimensions.
Unlike lists, vectors support efficient indexed access.

`vector` constructs a vector from argument values; `make-array` constructs an
array from dimensions and options. A single integer dimension means a vector;
a list such as `'(2 3)` means two rows and three columns. `#(...)` is vector
literal notation: literal vectors, like literal lists/strings, are not mutable
scratch storage. Use constructors when you intend to modify their contents.

```lisp
(let ((v (vector 10 20 30)))
  (setf (aref v 1) 99)
  v)                         ; #(10 99 30)

(let ((grid (make-array '(2 3) :initial-element 0)))
  (setf (aref grid 1 2) 7)
  (aref grid 1 2))            ; 7
```

`elt` works on sequences; `aref` indexes arrays. Bounds are zero-based.
`:initial-element` installs the same object in every position; if that object
is mutable, entries share it. Allocate separate nested objects when necessary.

An adjustable vector with a fill pointer can serve as a growable buffer:

```lisp
(let ((buffer (make-array 0 :adjustable t :fill-pointer 0)))
  (vector-push-extend :new buffer)
  (length buffer))             ; 1
```

The fill pointer represents active length; capacity can be larger. Sequence
operations respect the active length. Distinguish that from array dimensions.

`:adjustable t` permits resizing, and `:fill-pointer 0` starts the active portion
empty. `vector-push-extend` appends to the active portion, extending capacity
when needed. `:new` is an arbitrary keyword value stored in the buffer, not an
option for `vector-push-extend`.

## Strings

Strings are vectors of characters. `char` accesses a string character;
`string-upcase`, `string-downcase`, `string-trim`, and `concatenate` build useful
transformations. Non-destructive does not imply every returned string is fresh;
copy explicitly before mutation when ownership is uncertain.

`string-upcase`/`string-downcase` change case in the returned string;
`string-trim` removes characters in its first argument from both ends of its
second. `#\Space` and `#\Tab` name whitespace characters. `concatenate` joins
sequences; its first argument, `'string` here, specifies the result type.

```lisp
(string-trim '(#\Space #\Tab) "  Ada ") ; "Ada"
(concatenate 'string "Common" " " "Lisp") ; "Common Lisp"
(let ((s (copy-seq "cat")))
  (setf (char s 0) #\B)
  s)                           ; "Bat"
```

Characters are not bytes. SBCL supports Unicode, but text encodings and Unicode
case/normalization issues still require explicit policies. This course's text
splitting examples deliberately use a small ASCII whitespace set.

## Hash tables and the missing-value problem

First, learn named capture of multiple values. Lesson 02 used
`multiple-value-list` to examine them together. Now that `let` bindings are
familiar, give each returned value its own local name:

```lisp
(multiple-value-bind (quotient remainder) (floor 7 3)
  (list quotient remainder)) ; (2 1)
```

The shape is `(multiple-value-bind (names...) value-form body...)`. It evaluates
value-form once, binds successive results to the names, and returns the body's
last values. These names are chosen locally, not calls or global definitions.
Use this same pattern for the value and presence flag returned by `gethash`.

```lisp
(let ((table (make-hash-table :test #'equal)))
  (setf (gethash "Ada" table) nil)
  (multiple-value-list (gethash "Ada" table))) ; (NIL T)
```

`gethash` returns **value and present-p**. A stored `nil` is different from a
missing entry. Standard hash tests are `eq`, `eql`, `equal`, and `equalp`; the
default is `eql`, which is usually wrong for independently constructed string
keys. Do not mutate a key in a way that changes its equality/hash behavior while
it is stored. Hash-table traversal order is unspecified.

`make-hash-table` creates the table. `(gethash key table default)` returns
`default` when absent (the default default is `nil`) and a second presence value.
As a `setf` place it inserts/replaces the key's value. Thus
`(incf (gethash item counts 0))` in `frequencies` below changes an absent count
from the supplied zero to one, or increments an existing count.

```lisp
(defun frequencies (items)
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (item items counts)
      (incf (gethash item counts 0)))))
```

Use `maphash` to visit entries; if you need sorted output, collect entries and
sort separately. Hash tables are good for lookup, not an implicit ordering policy.

`maphash` takes a function and a table; the function receives each key and value.
`remhash` removes an entry and `hash-table-count` returns the entry count.
For Lab 07's failure case, `(error "Missing key: ~S" key)` signals a failure
with a formatted message. This is a preview of [Lesson 11](11-conditions.md),
which teaches custom conditions and handling; you need only signal the error now.
Check the missing-key case separately at the REPL and use Lesson 00's abort
procedure; automated expected-error tests wait until Lesson 10.

## Lab 07 — Counting and lookup

### Exercises

1. Implement `frequencies` and test independently allocated equal strings.
2. Write `lookup-or-error`: retrieve a key, returning stored `nil` normally but
   signaling an error for absence.
3. Create a growable vector of squares from 0 through 9.
4. Compare an alist, hash table, and vector for a phonebook; state assumptions
   about size, ordering, and access patterns.

### Acceptance checklist

- [ ] Exercise 1: independently allocated equal strings share a count.
- [ ] Exercise 2: stored `nil` is returned normally, but a missing key signals
  an error.
- [ ] Exercise 3: the vector's active contents are the squares from 0 through 9.
- [ ] Exercise 4: your phonebook choice is justified by size, ordering, and
  access requirements rather than habit.

### Review questions

1. Why should deterministic reports not depend on `maphash` order?
2. How does a fill pointer differ from an array's capacity?
