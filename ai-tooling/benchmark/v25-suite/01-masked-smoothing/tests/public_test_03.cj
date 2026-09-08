package masked_smoothing

import std.math.*

func nearS3(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("masked mean mismatch") }
}

main() {
    let result = maskedSmoothedCrossEntropy([0.0, 0.0, 8.0, -8.0], [0, 1], [true, false], 2, 2, 0.0)
    if (result.active != 1) { throw Exception("masked active count mismatch") }
    nearS3(result.loss, log(2.0))
    nearS3(result.gradients[0], -0.5)
    nearS3(result.gradients[1], 0.5)
    nearS3(result.probabilities[2], 0.0)
    nearS3(result.gradients[3], 0.0)
}
