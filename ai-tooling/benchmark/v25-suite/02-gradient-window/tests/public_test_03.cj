package gradient_window

func nearG3(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("gradient clipping mismatch") }
}

main() {
    let window = GradientWindow([0.0, 0.0], 1, 2.0, 1.0)
    let report = window.add([3.0, 4.0], 1)
    nearG3(report.gradientNorm, 5.0)
    nearG3(report.clipScale, 0.2)
    nearG3(window.values()[0], -1.2)
    nearG3(window.values()[1], -1.6)
}
