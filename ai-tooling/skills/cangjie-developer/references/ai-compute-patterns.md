# AI-compute implementation patterns

Build a small, testable CPU core before adding automatic differentiation, native kernels, or accelerators.

## Tensor representation

For the first two-dimensional Tensor, store:

- `rows` and `cols`;
- one flat row-major `Array<Float64>`;
- element `(row, col)` at `row * cols + col`.

Copy caller-provided data during construction when Tensor ownership should be independent. Validate that `rows * cols` equals the data size and reject negative shapes.

Before multiplying dimensions, consider integer overflow. Define empty-shape behavior deliberately instead of inheriting it from loop behavior.

## Operation contracts

- `get` and `set`: validate row and column bounds.
- `add`: require identical shapes and return a new Tensor.
- `relu`: return a new Tensor with negative elements replaced by zero.
- `sum`: accumulate every element into a `Float64`.
- `matmul`: require `left.cols == right.rows`; output shape is `left.rows` by `right.cols`.

Use the direct three-loop matrix multiplication first:

```text
for row in left rows
  for col in right columns
    for k in shared dimension
      output[row, col] += left[row, k] * right[k, col]
```

This is intentionally simple and easy to test. Optimize only after a benchmark identifies a real bottleneck.

## Numerical-development order

1. Tensor storage, shape checks, indexing, copying.
2. Element-wise operations, reductions, matrix multiplication.
3. Numerical gradient checks for later automatic differentiation.
4. A minimal trainable example such as linear regression.
5. Only then evaluate BLAS, SIMD, GPU, or NPU backends behind a stable interface.

Keep public APIs small. A competition demo benefits more from a correct end-to-end training example and reproducible measurements than from many unfinished operators.

## Numerical correctness rules

- Use a documented tolerance for floating-point assertions; exact equality is appropriate only when the operation is known to be exact.
- Compare automatic gradients with central finite differences on small deterministic inputs before trusting training output.
- Accumulate gradients when a value contributes along multiple graph paths; reset gradients deliberately between optimization steps.
- Keep dtype, shape, device/backend, ownership, and mutation behavior explicit at public boundaries.
- Benchmark release builds after warm-up and report input shape, dtype, platform, compiler mode, and iteration count.
