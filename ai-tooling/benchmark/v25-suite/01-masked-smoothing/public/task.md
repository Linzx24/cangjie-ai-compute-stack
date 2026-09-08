# Masked label-smoothed cross entropy

Implement the single file starter/src/masked_smoothing.cj for a CPU-only,
dependency-free Cangjie 1.1.3 package. Keep the declared public API and do not
add a main function. Each test is compiled with this source as a separate
native program.

The API is:

    SmoothedLossResult(
        loss: Float64,
        probabilities: Array<Float64>,
        gradients: Array<Float64>,
        active: Int64
    )

    maskedSmoothedCrossEntropy(
        logits: Array<Float64>,
        labels: Array<Int64>,
        activeMask: Array<Bool>,
        rows: Int64,
        classes: Int64,
        smoothing: Float64
    ): SmoothedLossResult

Rows must be positive, classes must be greater than one, and smoothing must be
finite in the half-open interval [0.0, 1.0). Guard rows * classes before
multiplication. The three input arrays have exact lengths rows * classes,
rows, and rows. Every logit must be finite and every label must be in
0..classes-1, including entries whose mask is false. At least one row must be
active. Reject any invalid request with IllegalArgumentException.

For each active row, compute a stable softmax by subtracting the row maximum.
For class c the smoothed target is smoothing / classes, plus
1.0 - smoothing when c is the row label. The loss is the mean over active
rows of minus the complete target-weighted log probability. Compute it through
the stable log-normalizer so a tiny probability does not require log(0.0).
The gradient is (probability - target) / activeRows. Inactive rows have zero
probabilities and zero gradients.

All returned values must be finite. Returned arrays are newly owned and do not
alias any input.
