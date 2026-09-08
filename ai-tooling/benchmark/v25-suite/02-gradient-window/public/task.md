# Transactional gradient window

Implement starter/src/gradient_window.cj as a dependency-free Cangjie 1.1.3
CPU component. Preserve the public declarations and do not add a main
function. Tests compile this source independently.

The public API is:

    GradientWindowReport(
        collected: Int64, step: Int64, applied: Bool,
        gradientNorm: Float64, clipScale: Float64
    )

    GradientWindow(
        initialValues: Array<Float64>, expectedSamples: Int64,
        learningRate: Float64, maxNorm: Float64
    )

    values(): Array<Float64>
    accumulated(): Array<Float64>
    collected(): Int64
    step(): Int64
    add(gradientSums: Array<Float64>, samples: Int64): GradientWindowReport
    reset(): Unit

The initial array is non-empty and finite. expectedSamples is positive.
learningRate and maxNorm are finite and strictly positive. Construction owns
an independent copy of initialValues, and all array accessors return
independent snapshots.

Each add call supplies the sum of gradients from a positive number of samples.
Its array must exactly match the parameter count and contain only finite
values. Accumulate calls until collected samples equal expectedSamples. A call
that would exceed the window is rejected. A partial call commits only the
accumulated sums and count, reports applied false, gradientNorm 0.0 and
clipScale 1.0, and does not advance step.

When the window becomes complete, divide every accumulated sum by
expectedSamples. Compute the Euclidean norm of that mean gradient. The clip
scale is maxNorm / norm when norm is greater than maxNorm, otherwise 1.0.
Update every value by subtracting learningRate * meanGradient * clipScale.
Then clear the accumulator and count, increment step exactly once, and report
the norm and scale.

Every request is all-or-nothing: validate and compute all candidates before
changing any field. Reject non-finite intermediate or final values with
IllegalArgumentException and preserve every observable. reset restores the
owned initial values, empty accumulation, and step zero.
