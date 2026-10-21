# 11 — Conditions, handlers, and restarts

**Goals:** separate reporting a problem from choosing a recovery policy.
**Prerequisite:** 10. **Time:** 4–6 hours.

## Prerequisite recap

From [Lesson 10](10-testing.md):

- Tests check returned values, boundaries, failures, and ownership promises—not
  just whether a program prints one plausible answer.
- An expected-error test must fail if the error never occurs. Catching every
  error can accidentally count an unrelated bug as successful validation.
- The debugger, tracing, and fresh-process regression tests help connect a
  failure to its source and verify that the saved repair actually works.

You have briefly used `handler-case` in tests. This lesson explains conditions,
handler behavior, and caller-selected recovery through restarts.

**Two study sessions:** first handle a familiar built-in error, then define a
condition for your domain. Once those work, add one restart and compare stopping
with recovery. The importer milestone is a separate integration task, not the
first example to write. Cleanup machinery and the other signaling operations
are follow-up reading; no special-variable declarations are needed for this lab.

## Start with a familiar failure

```lisp
(defun checked-score (value)
  "Return VALUE if it is an integer from 0 through 100; otherwise signal a type error."
  (check-type value (integer 0 100))
  value)

(handler-case (checked-score 150)
  (type-error () :rejected)) ; :REJECTED
```

This uses the validation and expected-error pattern you already know. The
handler runs after leaving the failing computation; it returns `:rejected`,
not a corrected value to the original `check-type` operation. Next give the
failure a domain-specific name so callers can distinguish it from unrelated bugs.

## Beyond a single exception mechanism

A **condition** describes a situation. Some are informational, some warnings,
some errors. `signal` notifies handlers and may return normally if none transfers
control; `error` signals a serious failure and invokes the debugger if unhandled;
`warn` reports a warning. A **handler** responds to a condition. A **restart** is a
named recovery action made available by code that knows how to recover.

```lisp
(define-condition invalid-score (error)
  ((value :initarg :value :reader invalid-score-value))
  (:report (lambda (condition stream)
             (format stream "Invalid score: ~S"
                     (invalid-score-value condition)))))

(defun validated-score (value)
  (if (and (integerp value) (<= 0 value 100))
      value
      (error 'invalid-score :value value)))
```

Defining a condition gives callers a stable type to handle instead of asking
them to parse an error message.

Read the definition as `(define-condition name (parent-types...) slots options...)`.
Here `invalid-score` is our new condition type, inheriting from built-in `error`.
It stores a `value` slot (a named field). `:initarg :value` permits supplying that
field with the keyword `:value`; `:reader invalid-score-value` generates a function
to read it. That reader is **created by this definition**, not a missing built-in.
The `:report` function receives the condition and an output stream and prints
the diagnostic. [Lesson 12](12-objects.md) develops slots and generated accessors.

`(error 'invalid-score :value value)` creates/signals that condition with a field
value, rather than using the formatted-string variant of `error` previewed in
Lesson 07. The quote passes the type's symbol as data. `<=` checks the inclusive
bounds here, as introduced in Lesson 04.

## Unwinding handlers versus active handlers

`handler-case` transfers control out of the protected form before its selected
clause runs. It is convenient for boundary translation:

```lisp
(handler-case (validated-score 150)
  (invalid-score (condition)
    (format nil "Rejected ~S" (invalid-score-value condition))))
```

The `(condition)` clause parameter binds the signaled condition object so its
fields can be inspected. It is a name chosen by this handler, not a new operator.

`handler-bind` runs a handler in the signaling context, while applicable restarts
are still active. A handler can inspect the condition, invoke a restart, or
decline by returning normally. Returning a replacement value from a handler is
not the same thing as resuming the failed operation with that value.

## Offer a recovery, let a caller select it

```lisp
(defun recoverable-score (value)
  (restart-case (validated-score value)
    (use-zero ()
      :report "Use zero for this score."
      0)))

(handler-bind ((invalid-score
                (lambda (condition)
                  (declare (ignore condition))
                  (invoke-restart 'use-zero))))
  (recoverable-score 150))       ; 0
```

`restart-case` wraps a form and defines clauses `(restart-name (parameters...) body...)`.
`use-zero` is a restart name we choose; `()` means it takes no arguments, and
`:report` supplies its human-readable debugger description. `invoke-restart`
selects the active restart by name. `handler-bind` takes pairs of condition type
and handler function; its body runs while those handlers are installed.
`(declare (ignore condition))` tells the compiler the handler deliberately does
not use its parameter; `declare` is a declaration, not a function call. More
declaration forms appear in [Lesson 14](14-performance.md).

The low-level code offers a meaningful action. The caller decides whether it is
appropriate. Another caller could allow the error to reach the debugger instead.
In reusable handlers, use `find-restart` (optionally with the condition) before
invoking a restart that may not exist. Restart names are symbols: package identity
matters. Export names intended for callers or provide a public recovery function.

`unwind-protect` ensures cleanup when leaving a protected computation, whether
normally or by nonlocal exit. It is for cleanup, not selecting recovery policy;
`with-open-file` already uses this kind of resource discipline for you.

**Follow-up reference:** you need not write your own cleanup construct for the
score exercise. Keep using `with-open-file` for the file resources introduced
earlier; study `unwind-protect` when managing a resource without such a wrapper.

Its general shape is `(unwind-protect protected-form cleanup-form...)`: cleanup
runs when control leaves the protected form, including through an error or
`return-from`. It is not needed around a stream already managed by
`with-open-file`. `ignore-errors` is a broad handler that returns `nil` and the
condition on an error; the next section explains why that can hide bugs.

## Do not erase failures

Avoid wrapping an entire program in `(ignore-errors ...)` and pretending a `nil`
result means success. It obscures both expected user mistakes and unexpected
programming bugs. Handle specific conditions where you have a policy; report
unexpected errors clearly at a CLI boundary and exit unsuccessfully.

## Lab 11 — Resilient input

### Exercises

1. Define `invalid-score`, `validated-score`, and `recoverable-score` above.
2. Test values 0, 100, -1, 101, and a string.
3. Prove invalid input errors without a handler and returns 0 with the recovery
   handler. Valid input must not invoke the restart.
4. **Separate integration session:** complete milestone 3, an importer offering
   `skip-record` for invalid records. First validate one record, then offer one
   restart, then add traversal; do not implement all layers at once.

### Acceptance checklist

- [ ] Exercises 1–2: the score condition and validators handle the specified
  valid and invalid values as documented.
- [ ] Exercise 3: the same validation code supports both stop and recover
  policies; valid input does not invoke recovery, and tests need no human input.
- [ ] Exercise 4: the importer meets milestone 3's requirements and does not
  silently skip unrelated programming errors.

### Review questions

1. Why might a restart no longer be available inside a `handler-case` clause?
2. Does `signal` always stop execution?
