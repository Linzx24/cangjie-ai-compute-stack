package windowed_attention

func attentionTestNear(actual: Float64, expected: Float64, tolerance: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > tolerance) { throw Exception("attention known answer mismatch") }
}

main() {
    let result = applyWindowedAttention(
        [3.0, 4.0], [1.0, 0.0],
        [8.0, -2.0], 1, 2, 0, 2.0
    )
    if (result.tokens != 1 || result.width != 2 || result.weights.size != 1 || result.outputs.size != 2) {
        throw Exception("attention result shape mismatch")
    }
    attentionTestNear(result.weights[0], 1.0, 1.0e-12)
    attentionTestNear(result.outputs[0], 8.0, 1.0e-12)
    attentionTestNear(result.outputs[1], -2.0, 1.0e-12)
}
