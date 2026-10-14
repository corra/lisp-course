# 12 — Structures, classes, and generic functions

**Goals:** model records, use CLOS dispatch, and choose the least complicated
abstraction that fits. **Prerequisite:** 11. **Time:** 4–6 hours.

## Start with a structure

```lisp
(defstruct reading
  (sensor "unknown" :type string)
  (value 0 :type real))

(let ((r (make-reading :sensor "room" :value 21)))
  (incf (reading-value r))
  (reading-value r))          ; 22
```

`defstruct` creates a constructor, predicate, accessors, and copier by default.
The copier is shallow. Structures suit compact records with a mostly fixed shape.
Slot type declarations communicate assumptions; do not treat them as a complete
user-input validation strategy across implementations and optimization settings.

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

## Dispatch is not limited to one receiver

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

Use an alist/plist for tiny flexible data, a structure for straightforward
records, and classes/generic functions when extensible behavior and relationships
justify them. Plain functions and lists remain good tools.

## Lab 12 — Rendering different objects

Define a `reading` structure and a `sensor-alert` class with a message slot.
Define generic `render` with methods for both types. Return strings rather than
printing directly, so callers can choose the output destination. Add a subclass
of `sensor-alert` that augments the parent rendering using `call-next-method`.

**Pass:** both representations render through one API; subclass rendering retains
the original message; tests compare strings and exercise constructor defaults.

**Checkpoint:** Why doesn't a generic function need to live inside a class?
When is `defstruct` simpler than `defclass`? Does a read-only accessor make the
underlying object immutable?
