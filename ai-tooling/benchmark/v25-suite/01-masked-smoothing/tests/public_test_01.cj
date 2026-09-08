package masked_smoothing

import std.math.*

func nearS1(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("basic smoothed loss mismatch") }
}

main() {
    let result = maskedSmoothedCrossEntropy([0.0, 0.0], [1], [true], 1, 2, 0.0)
    if (result.active != 1) { throw Exception("active count mismatch") }
    nearS1(result.loss, log(2.0))
    nearS1(result.probabilities[0], 0.5)
    nearS1(result.probabilities[1], 0.5)
    nearS1(result.gradients[0], 0.5)
    nearS1(result.gradients[1], -0.5)
}
