package masked_smoothing

import std.math.*

func nearS2(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("label smoothing mismatch") }
}

main() {
    let result = maskedSmoothedCrossEntropy([0.0, 0.0], [0], [true], 1, 2, 0.2)
    nearS2(result.loss, log(2.0))
    nearS2(result.gradients[0], -0.4)
    nearS2(result.gradients[1], 0.4)
}
