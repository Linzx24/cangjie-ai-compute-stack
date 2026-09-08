package gradient_window

func nearG1(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("single-window update mismatch") }
}

main() {
    let window = GradientWindow([2.0, -1.0], 2, 0.5, 10.0)
    let report = window.add([2.0, -4.0], 2)
    if (!report.applied || report.step != 1 || report.collected != 0) { throw Exception("single-window report mismatch") }
    nearG1(report.gradientNorm, 2.23606797749979)
    nearG1(report.clipScale, 1.0)
    nearG1(window.values()[0], 1.5)
    nearG1(window.values()[1], 0.0)
}
