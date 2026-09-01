# Windowed attention

Implement the single source file `starter/src/windowed_attention.cj` for a
CPU-only, dependency-free Cangjie 1.1.3 package. Do not add files or change
the public declarations. The evaluator compiles this source together with
each public test as a separate native program.

The API is:

```text
public struct WindowAttentionResult {
    public let outputs: Array<Float64>  // tokens * width, row major
    public let weights: Array<Float64>  // tokens * tokens, row major
    public let tokens: Int64
    public let width: Int64
}

public func applyWindowedAttention(
    query: Array<Float64>, key: Array<Float64>, value: Array<Float64>,
    tokens: Int64, width: Int64, window: Int64, temperature: Float64
): WindowAttentionResult
```

Validate at the public boundary. `tokens` and `width` are positive, `window`
is in `0..tokens-1`, and `temperature` is finite and strictly positive.
Guard the `tokens * width` allocation before multiplying it. Each of query,
key, and value must have exactly `tokens * width` finite elements; reject a
bad shape, NaN, or infinity with `IllegalArgumentException`.

For each row `i`, attend only to columns
`max(0, i-window) .. min(tokens-1, i+window)`. A score is the dot product of
the row of query and the row of key divided by `temperature`. Convert the
scores to probabilities with a numerically stable softmax (subtract the
maximum score before calling `exp`). Store zero in `weights[i*tokens+j]` for
columns outside the window. Each output row is the probability-weighted sum
of the corresponding value rows. The output shape and row-major indexing are
part of the contract.

The returned arrays must not alias the caller's arrays. There is no mutable
state between calls. Reject a non-finite score or output as well as a
non-finite input.
