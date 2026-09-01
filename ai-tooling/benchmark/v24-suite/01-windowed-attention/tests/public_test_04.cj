package windowed_attention

func attentionTestNear4(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-8) { throw Exception("stable attention mismatch") }
}

main() {
    let query = [0.0, 0.0]
    let key = [0.0, 0.0]
    let value = [3.0, 7.0]
    let result = applyWindowedAttention(query, key, value, 2, 1, 1, 1.0)
    attentionTestNear4(result.weights[0], 0.5)
    attentionTestNear4(result.weights[1], 0.5)
    attentionTestNear4(result.weights[2], 0.5)
    attentionTestNear4(result.weights[3], 0.5)
    attentionTestNear4(result.outputs[0], 5.0)
    attentionTestNear4(result.outputs[1], 5.0)
    query[0] = -9.0
    key[0] = -9.0
    value[0] = 99.0
    attentionTestNear4(result.outputs[0], 5.0)
}
