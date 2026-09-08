package beam_frontier

func nearB1(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-12) { throw Exception("single-parent beam mismatch") }
}

main() {
    let frontier = BeamFrontier([0.0], 3, 2)
    let result = frontier.expand([-2.0, -0.1, -0.5])
    if (result.step != 1 || result.choices.size != 2) { throw Exception("beam result shape mismatch") }
    if (result.choices[0].parent != 0 || result.choices[0].token != 1 || result.choices[1].token != 2) {
        throw Exception("beam rank mismatch")
    }
    nearB1(result.choices[0].score, -0.1)
    nearB1(frontier.scores()[1], -0.5)
}
