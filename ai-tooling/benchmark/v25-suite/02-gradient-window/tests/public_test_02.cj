package gradient_window

func nearG2(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("microbatch accumulation mismatch") }
}

main() {
    let window = GradientWindow([1.0], 4, 0.4, 100.0)
    let partial = window.add([1.0], 1)
    if (partial.applied || partial.collected != 1 || window.step() != 0) { throw Exception("partial window state mismatch") }
    nearG2(window.accumulated()[0], 1.0)
    let complete = window.add([3.0], 3)
    if (!complete.applied || complete.step != 1 || window.collected() != 0) { throw Exception("complete window state mismatch") }
    nearG2(complete.gradientNorm, 1.0)
    nearG2(window.values()[0], 0.6)
}
