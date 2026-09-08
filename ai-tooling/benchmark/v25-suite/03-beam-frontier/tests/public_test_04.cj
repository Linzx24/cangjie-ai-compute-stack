package beam_frontier

main() {
    let initial = [2.0]
    let frontier = BeamFrontier(initial, 2, 2)
    initial[0] = 99.0
    _ = frontier.expand([-1.0, -2.0])
    let before = frontier.scores()
    var rejected = false
    try {
        _ = frontier.expand([Float64.NaN, 0.0, 0.0, 0.0])
    } catch (e: IllegalArgumentException) {
        rejected = true
    }
    if (!rejected || frontier.step() != 1 || frontier.scores()[0] != before[0]) { throw Exception("beam rejection was not atomic") }
    before[0] = 77.0
    if (frontier.scores()[0] == 77.0) { throw Exception("beam score snapshot aliases state") }
    frontier.reset()
    if (frontier.step() != 0 || frontier.scores().size != 1 || frontier.scores()[0] != 2.0) { throw Exception("beam reset mismatch") }
}
