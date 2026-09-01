# AI-compute implementation patterns

Build a small, testable CPU core before adding automatic differentiation, native kernels, or accelerators.

## Tensor representation

For the first two-dimensional Tensor, store:

- `rows` and `cols`;
- one flat row-major `Array<Float64>`;
- element `(row, col)` at `row * cols + col`.

Copy caller-provided data during construction when Tensor ownership should be independent. Validate that `rows * cols` equals the data size and reject negative shapes.

Before multiplying dimensions, guard the multiplication itself rather than checking only after overflow. For positive `cols`, reject `rows > data.size / cols` before evaluating `rows * cols`; then compare the product with `data.size`. Handle zero and negative dimensions according to the Tensor contract before the division. Define empty-shape behavior deliberately instead of inheriting it from loop behavior.

```cangjie
if (rows <= 0 || cols <= 0 || rows > data.size / cols || rows * cols != data.size) {
    throw IllegalArgumentException("shape does not match data size")
}
```

## Operation contracts

- `get` and `set`: validate row and column bounds.
- `add`: require identical shapes and return a new Tensor.
- `relu`: return a new Tensor with negative elements replaced by zero.
- `sum`: accumulate every element into a `Float64`.
- `matmul`: require `left.cols == right.rows`; output shape is `left.rows` by `right.cols`.
- Adding a row-vector bias to a matrix requires `bias.size == matrix.cols`; each output `(row, col)` uses `bias[col]`, not `bias[row]`.
- For 2-D convolution, derive output rows and columns from input, kernel,
  padding, dilation, and stride only after validating every positive dimension
  and guarding intermediate products. Make cross-correlation versus flipped
  convolution explicit in the public contract.

Use the direct three-loop matrix multiplication first:

```text
for row in left rows
  for col in right columns
    for k in shared dimension
      output[row, col] += left[row, k] * right[k, col]
```

This is intentionally simple and easy to test. Optimize only after a benchmark identifies a real bottleneck.

## Public numerical boundaries

Before implementation, reduce each public constructor, free function, method, and accessor to a compact contract: exact intervals and endpoints; finite-value policy; shapes, indices, and overflow guards; copy or alias behavior; output invariants; exception type; and observable state after failure. Enforce that contract at the public boundary before loops or delegated work. Zero iterations, empty ranges, and early returns must not bypass required validation. Indexed accessors validate every index, and nested mutable arrays are copied to every depth required by the ownership contract.

For a `Float64` that must be finite, ordered comparisons alone are insufficient: `NaN` makes comparisons false, while an infinity can satisfy a one-sided range check. Cangjie 1.1.3 accepts `value.isNaN()` and `value.isInf()`; reject either before applying the exact range predicate. Apply the same policy element by element when the contract covers an array or nested array.

## Numerical correctness rules

- With `import std.math.*`, call functions such as `sqrt(value)` directly; do not invent a `Math.sqrt` namespace. For a simple absolute value, an explicit `if (value < 0.0) { -value } else { value }` avoids assuming an unavailable `abs` overload.
- When an objective is the mean over a batch, divide both the reported loss and its per-example gradient by the batch size. Otherwise training updates scale incorrectly even when the loss value looks right.
- Use a documented tolerance for floating-point assertions; exact equality is appropriate only when the operation is known to be exact.
- For an all-or-nothing state update, validate the request, compute into local candidate storage, validate the complete candidate, and only then commit fields and counters. Test rejection by snapshotting every public observable first.
- For stable softmax, subtract the row maximum before `exp`, require a finite
  positive sum, and normalize in the same row. Check row sums, translation
  invariance, extreme logits, and the associated loss/gradient divisor.
- For quantized kernels, validate integer ranges before accumulation, apply the
  documented per-tensor or per-row scale exactly once, and keep bias addition
  outside the integer dot product. Guard shape products before allocation.
- When invalid conditions have different results, write down their precedence
  and keep them in separate guards. Every rejected call preserves public state.
- Keep dtype, shape, device/backend, ownership, and mutation behavior explicit at public boundaries.
- Benchmark release builds after warm-up and report input shape, dtype, platform, compiler mode, and iteration count.
