package beam_frontier

main() {
    let frontier = BeamFrontier([0.0, 0.0], 2, 4)
    let result = frontier.expand([1.0, 1.0, 1.0, 1.0])
    if (result.choices.size != 4) { throw Exception("beam tie result size mismatch") }
    for (i in 0..4) {
        let expectedParent = i / 2
        let expectedToken = i % 2
        if (result.choices[i].parent != expectedParent || result.choices[i].token != expectedToken || result.choices[i].score != 1.0) {
            throw Exception("beam tie order mismatch")
        }
    }
}
