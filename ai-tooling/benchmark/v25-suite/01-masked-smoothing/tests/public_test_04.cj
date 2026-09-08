package masked_smoothing

func nearS4(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("stable translation mismatch") }
}

func rejectsS4(logits: Array<Float64>, labels: Array<Int64>): Unit {
    var rejected = false
    try {
        _ = maskedSmoothedCrossEntropy(logits, labels, [true], 1, 2, 0.0)
    } catch (e: IllegalArgumentException) {
        rejected = true
    }
    if (!rejected) { throw Exception("invalid loss request accepted") }
}

main() {
    let first = maskedSmoothedCrossEntropy([1000.0, 999.0], [0], [true], 1, 2, 0.0)
    let shifted = maskedSmoothedCrossEntropy([20.0, 19.0], [0], [true], 1, 2, 0.0)
    nearS4(first.loss, shifted.loss)
    nearS4(first.probabilities[0], shifted.probabilities[0])
    rejectsS4([0.0, 0.0], [2])
    rejectsS4([Float64.NaN, 0.0], [0])
}
