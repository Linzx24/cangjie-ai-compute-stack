package windowed_attention

main() {
    var rejected = false
    try {
        _ = applyWindowedAttention(
            [1.0, 2.0], [1.0],
            [1.0, 2.0], 2, 1, 0, 0.0
        )
    } catch (e: Exception) {
        rejected = true
    }
    if (!rejected) { throw Exception("invalid attention input was accepted") }
}
