# 11 — Conditions, handlers, and restarts

**Goals:** separate reporting a problem from choosing a recovery policy.
**Prerequisite:** 10. **Time:** 4–6 hours.

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

## Unwinding handlers versus active handlers

`handler-case` transfers control out of the protected form before its selected
clause runs. It is convenient for boundary translation:

```lisp
(handler-case (validated-score 150)
  (invalid-score (condition)
    (format nil "Rejected ~S" (invalid-score-value condition))))
```

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

The low-level code offers a meaningful action. The caller decides whether it is
appropriate. Another caller could allow the error to reach the debugger instead.
In reusable handlers, use `find-restart` (optionally with the condition) before
invoking a restart that may not exist. Restart names are symbols: package identity
matters. Export names intended for callers or provide a public recovery function.

`unwind-protect` ensures cleanup when leaving a protected computation, whether
normally or by nonlocal exit. It is for cleanup, not selecting recovery policy;
`with-open-file` already uses this kind of resource discipline for you.

## Do not erase failures

Avoid wrapping an entire program in `(ignore-errors ...)` and pretending a `nil`
result means success. It obscures both expected user mistakes and unexpected
programming bugs. Handle specific conditions where you have a policy; report
unexpected errors clearly at a CLI boundary and exit unsuccessfully.

## Lab 11 — Resilient input

1. Define `invalid-score`, `validated-score`, and `recoverable-score` above.
2. Test values 0, 100, -1, 101, and a string.
3. Prove invalid input errors without a handler and returns 0 with the recovery
   handler. Valid input must not invoke the restart.
4. Complete milestone 3: an importer offering `skip-record` for invalid records.

**Pass:** the same validation code supports both stop and recover policies, tests
do not require interactive input, and unrelated errors are not silently skipped.

**Checkpoint:** Why might a restart no longer be available inside a
`handler-case` clause? Does `signal` always stop execution?
