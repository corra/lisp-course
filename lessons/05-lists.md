# 05 — Cons cells, lists, and ownership

**Goals:** understand list representation, dotted pairs, sharing, and destructive
operations. **Prerequisite:** 04. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 04](04-control.md):

- `if` handles a two-way choice; `cond` tests ordered alternatives; `when` and
  `unless` execute a body on one side of a test.
- `dolist`, `dotimes`, and `loop` repeat computations and can return accumulated
  results. Recursion needs a base case and progress toward it.
- Local bindings hold working state, while assignment updates places; an early
  `return` exits its enclosing loop/block rather than every enclosing function.

You have already traversed lists. Now you will inspect their cons-cell structure
to understand sharing, copying, and the effects of mutation.

**Core path:** construct/read lists, observe shared tails, copy before changing
caller-owned data, and build a list with `push`/`nreverse`. Complete Lab 05 with
those tools. Alists/plists are useful lookup examples; tree recursion and
destructuring are a second pass, not additional barriers to starting Lesson 06.

## Lists are linked structures

A **cons cell** contains two references, its `car` and its `cdr`. A proper list
is either `nil` or a cons whose `cdr` is another proper list. Its final `cdr` is
`nil`. The elements themselves can be any objects.

`cons` constructs a cell. `car` reads its first reference and `cdr` its second;
`first` and `rest` are the corresponding list-oriented names. Symbols such as
`a`, `b`, and `c` in quoted examples are data we choose, not predefined variables.

```lisp
(cons 1 nil)              ; (1)
(cons 1 (cons 2 nil))     ; (1 2)
(car '(a b c))           ; A
(cdr '(a b c))           ; (B C)
(first '(a b c))         ; A
(rest '(a b c))          ; (B C)
(cons :name "Ada")       ; (:NAME . "Ada"), a dotted pair
(car nil)                ; NIL
(cdr nil)                ; NIL
```

The printed dot means the final `cdr` is not represented as another proper-list
tail. `(a . (b . nil))` is another spelling of `(a b)`. Do not pass an arbitrary
dotted or circular list to functions that require a proper sequence.

Accessing the nth element of a linked list requires traversal: it is O(n), not
constant time. Repeated indexed access can turn a linear algorithm quadratic.
Use traversal or choose a vector for frequent random access.

## Shared tails and shallow copies

```lisp
(let* ((tail (list 2 3))
       (a (cons 1 tail))
       (b (cons 0 tail)))
  (setf (first tail) 99)
  (list a b))               ; ((1 99 3) (0 99 3))
```

`let*` creates bindings for `tail`, `a`, and `b`. Each `cons` creates one new
head cell whose `cdr` refers to the same existing tail; it does not copy that tail.
`(setf (first tail) 99)` mutates a shared cell, so both lists show the change.
By contrast, assigning another list to `tail` with `setf` would update that
variable's binding without changing the cells already referenced by `a` and `b`.
An inner `let` named `tail` would create a separate shadowing binding, not assign
to the outer one. `copy-list` copies only the outer spine; nested elements remain
shared. `copy-tree` recursively copies cons structure, not arbitrary arrays or
objects, and is not a general cyclic graph copier.

## Mutation rules

Never destructively modify literal objects such as `'(1 2)` or `"abc"` embedded
in source. Consequences are undefined, even if an experiment seems to work.
Construct mutable data with `list`, `copy-list`, `copy-seq`, or other constructors.

```lisp
(let ((items (list 2 3)))
  (push 1 items)
  (pop items)                ; returns 1, updates the variable
  items)                    ; (2 3)
```

`push` and `pop` update a place. `append` copies the spines of all list arguments
except the last, which can be shared. `reverse` produces a reversed sequence;
`nreverse` may destructively rearrange the original, and its returned head must
be used. The `n` prefix often warns of destructive behavior, but naming is not a
complete rule: `sort` is destructive too.

This historical `n` naming pattern is a warning, not a rule for naming all your
mutating functions. Do not mechanically add `n-` or import a `!` mutation suffix
from another Lisp dialect. Use a descriptive operation name and document its
mutation/ownership contract; [Lesson 03](03-functions.md#naming-conventions)
summarizes the conventions used by this course.

`copy-seq` makes a shallow copy of a sequence (a list, vector, or string).
Sequences and sorting are taught in [Lesson 06](06-sequences.md); vectors and
strings are developed in [Lesson 07](07-collections.md). Here it is enough to
recognize copying as a way to obtain data you own before modifying it.

```lisp
(let ((result nil))
  (dolist (n '(1 2 3))
    (push (* n 10) result))
  (nreverse result))         ; (10 20 30)
```

Pushing then reversing avoids repeatedly traversing a growing list with `append`.
Clearly document whether a function owns, copies, or may mutate its input.

## Association and property lists

```lisp
(cdr (assoc :name '((:name . "Ada") (:role . "student")))) ; "Ada"
(getf '(:name "Ada" :role "student") :role)               ; "student"
```

An **alist** is a list of key/value pairs; a **plist** alternates indicators and
values. Both are convenient for small records and options, but lookup is linear.
The keyword keys in this example work with the default comparison. For string
keys use an appropriate equality test; function-valued options such as
`:test #'equal` are taught in Lesson 06, not assumed here.

`assoc` returns the matching pair, or `nil`, which is why `cdr` then extracts
its value. `getf` returns the matching property's value instead.

## Trees and structural recursion

**Second pass after the lab.** This reuses recursion from Lesson 04; it is not
needed for this lesson's counting and copy exercises.

Nested cons structure is naturally recursive. Distinguish the empty list, a leaf
that is not a cons, and a branching cons:

```lisp
(defun tree-leaf-count (tree)
  (cond ((null tree) 0)
        ((atom tree) 1)
        (t (+ (tree-leaf-count (car tree))
              (tree-leaf-count (cdr tree))))))

(tree-leaf-count '(a (b c) nil)) ; 3
(tree-leaf-count '(a . b))      ; 2
```

Here `nil` is not counted as a leaf: that is an explicit representation policy.
`atom` means “not a cons,” not “a tiny scalar value.” This walker handles dotted
trees but not cycles, and deeply nested input can exhaust the stack. Structural
recursion is useful when the input branches; it is not a mandate to replace
every loop with recursion.

For a record of known shape, destructuring can clarify which part is which:

```lisp
(destructuring-bind (name (x y)) '("Ada" (3 4))
  (list name (+ x y)))          ; ("Ada" 7)
```

`destructuring-bind` binds names from list structure; it does not validate a
business data schema. Validate external records before destructuring them.

In this pattern, `name` receives `"Ada"`, while nested names `x` and `y` receive
`3` and `4`. The pattern is binding syntax, not a call to `name`. The related
accessors `second`, `third`, `fourth`, `fifth`, and `sixth` select successive list
elements; they appear in the [capstone](15-capstone.md#reading-the-reference-source).

Composed accessor names such as `caar` are abbreviations: `(caar tree)` means
`(car (car tree))`. The worked solutions use it to demonstrate nested sharing;
it is not a separate representation or a new kind of list.

## Lab 05 — Shape and sharing

### Exercises

1. Draw the cells for `(cons 'a (list 'b 'c))` and `(cons 'a 'b)`.
2. Write `(count-occurrences item items)`, returning how many elements of
   `items` are `equal` to `item`. Use `dolist` and an explicit `equal` comparison.
3. Write `replace-first-copy`: given a nonempty list and a new value, return a
   list with a changed first element without modifying the input spine.
4. Demonstrate that `copy-list` does not independently copy nested lists, using
   freshly allocated data rather than literals.

### Acceptance checklist

- [ ] Exercise 1: your diagrams distinguish a proper list from a dotted pair.
- [ ] Exercise 2: counting handles an empty list and nested `equal` values.
- [ ] Exercise 3: replacement changes the returned list but leaves the input
  spine unchanged.
- [ ] Exercise 4: the demonstration uses freshly allocated data, and your
  explanation of sharing agrees with the observed cell identities.

### Review questions

1. Why can `(setf xs (nreverse xs))` be necessary?
2. What does `append` share?
3. Why is mutating a quoted list a bug rather than an optimization?
