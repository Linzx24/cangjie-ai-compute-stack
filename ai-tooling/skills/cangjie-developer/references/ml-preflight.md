# Multi-file ML preflight

Read this reference before implementing and again for the final review of an interdependent numerical change.
Apply only relevant checks and do not rewrite a working public API.

1. Write the exact contract for each public entry point: endpoints, finite-value
   policy, shapes, indices, ownership, error, and state after rejection.
2. Trace shapes across producers and consumers. Guard a multiplication before
   evaluating it, and index row biases by output column.
3. Check ownership at construction, access, snapshots, and returned gradients.
   Copy mutable arrays to the depth promised by the API.
4. Check numeric types and imports: explicit integer-to-float conversion,
   floating literals, `std.math.*`, and `isNaN()`/`isInf()`.
5. Check formulas with one hand-computable case and one property such as stable
   normalization, conservation, translation invariance, or finite outputs.
6. For gradients, follow the loss-reachable graph and verify shared contributions
   accumulate before propagation, then test backward/reset twice.
7. For state, cache, optimizer, or I/O, compute and validate a complete private
   candidate before the only commit point; rejection preserves all observables.
8. For concurrency, workers return private results. Join every future and merge
   deterministically; do not write a captured numerical output array.
9. Run the top-level workflow for at least two transitions and cross one empty,
   exhaustion, capacity, reset, corrupted-input, or fallback boundary.
10. Compile the complete package and run its tests. Fix the earliest useful
    diagnostic before later cascades.

Run the normal quality gate once with `-StrictNumerical`; it includes the
preflight, build, and tests. Strict findings are conservative review prompts,
not compiler or behavioral proof; justify false positives instead of changing
correct code to satisfy a syntactic rule.
