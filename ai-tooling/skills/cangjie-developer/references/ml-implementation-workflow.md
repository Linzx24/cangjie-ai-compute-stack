# Logic-first Cangjie ML implementation

Apply this only when routed from `SKILL.md` for an interdependent new ML
feature. It is an internal aid, not a second deliverable. Priority is:
caller contract, verified Cangjie APIs, the smallest compile/test loop, ML
behavior completeness, then refactoring.

## Ground the contract and APIs

Before editing, keep one short internal checkpoint containing only decisions
that affect code:

- fixed public API and output format; inputs, outputs, shapes, and invalid
  boundaries;
- exact numeric/index types, ownership, aliasing, required formula/operation
  order, and the required error priority when invalid conditions overlap;
- state transitions, rejected-call preservation, and one commit point;
- one small known answer or invariant when numerical behavior is uncertain.

Each item must map to a declared behavior, code location, or observable check.
Do not invent a framework or emit this checkpoint unless the caller asks.

Ground every nontrivial Cangjie operation before using it:

- prefer repository code, tests, loaded references, and compile-tested assets;
- for variable-length output or collection members, read
  `abstraction-and-collections.md`; an `Array<T>` is fixed-length;
- if an SDK feature is uncertain and execution is allowed, compile a minimal
  probe; if execution is forbidden, use only a verified pattern and do not
  invent a method or constructor.

Implement directly in Cangjie. Never write a complete Python, Java, C++, or
other-language implementation to translate line by line. A disposable oracle
may check one uncertain value or property, but never supplies production code
or evidence that Cangjie compiles.

## Implement the smallest useful slices

1. Exact API, native types, ownership boundary, and validation.
2. Smallest happy path, checked by the known answer or property.
3. Stateful, I/O, or concurrent behavior only after the smaller slice builds.

When execution is allowed, compile and run the narrow test after each slice.
When it is forbidden, perform the same API and consistency review without
claiming compilation.

## Diagnostic-first repair

After a compiler or test failure, do not rebuild the behavior checkpoint. The
first actionable diagnostic becomes the active constraint and overrides the
earlier implementation plan:

- preserve the public API and code not implicated by the diagnostic;
- for a member, constructor, string, or collection error, read
  `compiler-diagnostics.md` and its focused language/collection reference;
- replace only the invalid construct and the minimum required type ripple;
- confirm the rejected token or construct is gone; never exchange one guessed
  API for another;
- rerun the narrow failure before making any broader change.

## Final reconciliation

Before delivery, check that every public branch, state transition,
failure-preservation rule, and ownership promise has implementation evidence.
Then use the relevant domain reference and `ml-preflight.md`; keep exact-output
responses free of plan, checkpoint, or oracle prose.
