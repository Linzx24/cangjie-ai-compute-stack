package beam_frontier

main() {
    let frontier = BeamFrontier([0.0], 2, 2)
    let first = frontier.expand([-0.2, -0.1])
    if (first.choices[0].token != 1 || first.choices[1].token != 0) { throw Exception("first beam transition mismatch") }
    let second = frontier.expand([-1.0, -0.3, -0.05, -0.8])
    if (second.step != 2 || frontier.step() != 2) { throw Exception("beam step transition mismatch") }
    if (second.choices[0].parent != 1 || second.choices[0].token != 0 || second.choices[0].score != -0.25) {
        throw Exception("second beam transition mismatch")
    }
    if (second.choices[1].parent != 0 || second.choices[1].token != 1 || second.choices[1].score != -0.4) {
        throw Exception("second beam runner-up mismatch")
    }
}
