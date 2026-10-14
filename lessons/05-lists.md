# 05 — Cons cells, lists, and ownership

**Goals:** understand list representation, dotted pairs, sharing, and destructive
operations. **Prerequisite:** 04. **Time:** 4–6 hours.

## Lists are linked structures

A **cons cell** contains two references, its `car` and its `cdr`. A proper list
is either `nil` or a cons whose `cdr` is another proper list. Its final `cdr` is
`nil`. The elements themselves can be any objects.

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

`a` and `b` share tail cells; neither assignment copied them. Rebinding `tail`
would change the variable, not those existing cells. `copy-list` copies only the
outer spine; nested elements remain shared. `copy-tree` recursively copies cons
structure, not arbitrary arrays or objects, and is not a general cyclic graph
copier.

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
Supply an appropriate `:test`, e.g. `#'equal`, when alist keys are strings.

## Trees and structural recursion

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

## Lab 05 — Shape and sharing

1. Draw the cells for `(cons 'a (list 'b 'c))` and `(cons 'a 'b)`.
2. Write `count-occurrences` using `dolist` and an explicit `equal` comparison.
3. Write `replace-first-copy`: given a nonempty list and a new value, return a
   list with a changed first element without modifying the input spine.
4. Demonstrate that `copy-list` does not independently copy nested lists, using
   freshly allocated data rather than literals.

**Pass:** counts handle an empty list and nested equal values; replacement leaves
the original unchanged; your sharing explanation matches actual cell identity.

**Checkpoint:** Why can `(setf xs (nreverse xs))` be necessary? What does `append`
share? Why is mutating a quoted list a bug rather than an optimization?
