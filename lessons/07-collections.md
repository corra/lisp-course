# 07 — Arrays, strings, and hash tables

**Goals:** choose data structures and understand capacity, presence, and equality.
**Prerequisite:** 06. **Time:** 4–6 hours.

## Arrays and vectors

A vector is a one-dimensional array. General arrays can have multiple dimensions.
Unlike lists, vectors support efficient indexed access.

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

## Strings

Strings are vectors of characters. `char` accesses a string character;
`string-upcase`, `string-downcase`, `string-trim`, and `concatenate` build useful
transformations. Non-destructive does not imply every returned string is fresh;
copy explicitly before mutation when ownership is uncertain.

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

```lisp
(defun frequencies (items)
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (item items counts)
      (incf (gethash item counts 0)))))
```

Use `maphash` to visit entries; if you need sorted output, collect entries and
sort separately. Hash tables are good for lookup, not an implicit ordering policy.

## Lab 07 — Counting and lookup

1. Implement `frequencies` and test independently allocated equal strings.
2. Write `lookup-or-error`: retrieve a key, returning stored `nil` normally but
   signaling an error for absence.
3. Create a growable vector of squares from 0 through 9.
4. Compare an alist, hash table, and vector for a phonebook; state assumptions
   about size, ordering, and access patterns.

**Pass:** two equal strings share a count, stored `nil` is preserved, missing
keys fail, and your structure choice follows requirements rather than habit.

**Checkpoint:** Why should deterministic reports not depend on `maphash` order?
How does a fill pointer differ from an array's capacity?
