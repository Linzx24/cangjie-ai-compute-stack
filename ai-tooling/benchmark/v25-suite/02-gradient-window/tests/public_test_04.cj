package gradient_window

func nearG4(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-10) { throw Exception("window rollback or reset mismatch") }
}

main() {
    let initial = [5.0]
    let window = GradientWindow(initial, 2, 1.0, 10.0)
    initial[0] = 99.0
    _ = window.add([2.0], 2)
    var rejected = false
    try {
        _ = window.add([Float64.NaN], 1)
    } catch (e: IllegalArgumentException) {
        rejected = true
    }
    if (!rejected || window.step() != 1 || window.collected() != 0) { throw Exception("rejected update changed state") }
    let snapshot = window.values()
    snapshot[0] = 88.0
    nearG4(window.values()[0], 4.0)
    window.reset()
    nearG4(window.values()[0], 5.0)
    if (window.step() != 0 || window.collected() != 0) { throw Exception("reset counters mismatch") }
}
