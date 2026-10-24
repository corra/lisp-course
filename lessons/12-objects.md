# 12 — Structures, classes, and generic functions

**Goals:** model records, use CLOS dispatch, and choose the least complicated
abstraction that fits. **Prerequisite:** 11. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 11](11-conditions.md):

- A condition gives a situation a type and can carry named fields; generated
  readers retrieve fields without requiring callers to parse error text.
- `handler-case` handles after unwinding, while `handler-bind` responds in the
  signaling context where suitable restarts may still be active.
- Reporting a problem, choosing recovery, and cleaning up resources are distinct
  responsibilities. Callers should control policy when the library offers a choice.

The named fields and readers provide a first encounter with object-like APIs.
This lesson develops records, classes, accessors, and generic behavior explicitly.

**Build in stages:** construct/read/update a structure first. Then render one
class through a generic function. Add a subclass only after those calls work.
Multiple dispatch is a follow-up example; advanced method combination and slot
type declarations are not prerequisites for the lab.

## Start with a structure

```lisp
(defstruct reading
  (sensor "unknown")
  (value 0))

(let ((r (make-reading :sensor "room" :value 21)))
  (incf (reading-value r))
  (reading-value r))          ; 22
```

`defstruct` creates a constructor, predicate, accessors, and copier by default.
The copier is shallow. Structures suit compact records with a mostly fixed shape.
Start with plain slot defaults; validate public inputs with ordinary code.

For this definition the generated names are `make-reading` (constructor),
`reading-p` (predicate), `reading-sensor`/`reading-value` (accessors), and
`copy-reading` (shallow copier). The example calls those generated functions;
you do not need to find separate `defun` definitions for them. Each slot form is
`(name default-value)`. The `:sensor`/`:value` construction keywords select values.
Optional slot `:type` declarations can wait for Lesson 14; they communicate
assumptions, not a complete public-input validation strategy.

**Reloading a changed structure.** If you add or remove a slot and reload the
file, SBCL warns about a "change in instance length" and stops in the debugger:
it cannot silently update instances and accessors already compiled for the old
shape. The `CONTINUE` restart uses the new definition and invalidates old code
and instances; avoid `RECKLESSLY-CONTINUE` while learning. After continuing,
reload every file that uses the structure, or simply restart SBCL and load the
source fresh. Classes from `defclass` can be redefined more gracefully.

These defaults demonstrate the constructor/type-accessor conventions from
[Lesson 03](03-functions.md#naming-conventions). Keep them unless an API has a
reason to override them; do not add `get-`/`set-` wrappers solely to imitate
another language. An accessor that supports `setf` already supplies that update
interface. See [the style guide](../STYLE.md#6-records-and-object-oriented-apis).

## Classes and objects

CLOS, the Common Lisp Object System, supports classes, inheritance, generic
functions, and methods. Behavior belongs to generic functions, rather than being
syntactically enclosed inside class definitions.

```lisp
(defclass task ()
  ((title :initarg :title :reader task-title)
   (done-p :initform nil :accessor task-done-p)))

(defclass urgent-task (task)
  ((deadline :initarg :deadline :reader task-deadline)))

(defgeneric display-label (object)
  (:documentation "Return a concise label for OBJECT."))

(defmethod display-label ((object task))
  (format nil "[~A] ~A" (if (task-done-p object) "x" " ")
          (task-title object)))

(defmethod display-label ((object urgent-task))
  (format nil "~A (due ~A)" (call-next-method) (task-deadline object)))

(display-label (make-instance 'urgent-task :title "Study" :deadline "Friday"))
```

`:initarg` specifies a construction keyword. `:initform` provides an initial
value when one is not supplied. A slot without a supplied value or initial form
can be unbound; accessing it then signals an error. `:reader` creates a read-only
API accessor, while `:accessor` also supports `setf`. This is API discipline, not
a security boundary; `slot-value` can access slots explicitly.

In `(defclass task () ...)`, `()` means there are no explicitly named parent
classes; `(task)` in `urgent-task` names its superclass. `defgeneric` declares
a generic function's interface; `defmethod` supplies an implementation.
`((object task))` is a specialized parameter list: bind `object`, with this
method applying to instances of `task` and appropriate subclasses.
`make-instance` constructs a class instance from its quoted class name and
initialization arguments. `:documentation` documents the generic function.
`task-title`, `task-done-p`, and `task-deadline` are generated accessors from
the class definitions, not built-ins. `slot-value` takes an object and a slot-name
symbol when explicit slot access is needed, rather than a generated accessor.

## Dispatch is not limited to one receiver

**Follow-up after your first rendering method works.** The lab only needs a
single object argument; there is no requirement to build multiple-dispatch APIs.

```lisp
(defgeneric combine-labels (left right))
(defmethod combine-labels ((left task) (right task))
  (format nil "~A + ~A" (task-title left) (task-title right)))
```

Required parameters can be specialized; method selection considers all of them.
The most specific applicable primary method normally runs. `call-next-method`
invokes the next applicable method. Standard method combination also supports
`:before`, `:after`, and `:around` methods. Learn their ordering before using
them for side effects; avoid building an inheritance hierarchy simply to share
one utility function.

The `:before`/`:after`/`:around` qualifiers are an **optional advanced topic**,
not required for this lab. Their ordering is specified in the HyperSpec's
“Standard Method Combination” section; find it through the
[HyperSpec](https://www.lispworks.com/documentation/HyperSpec/Front/).
The examples here use only primary methods and `call-next-method`, so there is
no hidden requirement to implement the other method combinations.

## Follow-up: how objects print at the REPL

**Optional; not needed for Lab 12.** A class instance normally prints with only
its class name and an implementation-specific identity, such as
`#<TASK {1200DADA13}>`, which says little in a backtrace or REPL result.
`print-object` is a standard generic function that the printer calls for every
object; add a method to it for your class rather than calling it yourself:

```lisp
(defmethod print-object ((object task) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~S" (task-title object))))

(make-instance 'task :title "Study") ; displays #<TASK "Study">
```

The method receives the object and the stream to write to. The standard macro
`print-unreadable-object` writes the surrounding `#<...>`, and `:type t` adds
the class name; it shows the subclass name for subclasses too, so an
`urgent-task` displays as `#<URGENT-TASK "Ship">` through this inherited method.
`#<` tells readers that the text cannot be read back as Lisp data: with
`*print-readably*` true (Lesson 15's persistence), printing such an object
signals a `print-not-readable` error instead. Structures already print readably
as `#S(READING :SENSOR "room" :VALUE 21)`, so they rarely need this.

Keep the two jobs separate: `print-object` is the programmer-facing
representation used by the REPL, the debugger, and `~S`/`~A`; application text,
such as `display-label` above or Lab 12's `render`, belongs in your own generic
functions. Redefining `print-object` does not change those functions' output.

Use an alist/plist for tiny flexible data, a structure for straightforward
records, and classes/generic functions when extensible behavior and relationships
justify them. Plain functions and lists remain good tools.

## Lab 12 — Rendering different objects

### Exercises

1. Define a `reading` structure and a `sensor-alert` class with a message slot.
2. Define generic `render` with methods for both types. Return strings rather
   than printing directly, so callers can choose the output destination.
3. Add a subclass of `sensor-alert` that augments the parent rendering using
   `call-next-method`.
4. Test the returned strings, inherited behavior, and constructor defaults.

### Acceptance checklist

- [ ] Exercise 1: instances of both representations can be constructed.
- [ ] Exercise 2: both render through the same API and return strings.
- [ ] Exercise 3: subclass rendering retains the original message and augments it.
- [ ] Exercise 4: tests compare strings and exercise constructor defaults.

### Review questions

1. Why doesn't a generic function need to live inside a class?
2. When is `defstruct` simpler than `defclass`?
3. Does a read-only accessor make the underlying object immutable?
