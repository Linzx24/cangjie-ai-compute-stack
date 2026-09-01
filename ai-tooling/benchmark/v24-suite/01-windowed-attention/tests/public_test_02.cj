package windowed_attention

import std.math.*

func attentionTestNear2(actual: Float64, expected: Float64): Unit {
    var difference = actual - expected
    if (difference < 0.0) { difference = -difference }
    if (difference > 1.0e-9) { throw Exception("attention softmax mismatch") }
}

main() {
    let result = applyWindowedAttention(
        [1.0, 0.0], [1.0, 0.0],
        [10.0, 20.0], 2, 1, 1, 1.0
    )
    let p = exp(1.0) / (exp(1.0) + 1.0)
    attentionTestNear2(result.weights[0], p)
    attentionTestNear2(result.weights[1], 1.0 - p)
    attentionTestNear2(result.weights[2], 0.5)
    attentionTestNear2(result.weights[3], 0.5)
    attentionTestNear2(result.outputs[0], 10.0 * p + 20.0 * (1.0 - p))
    attentionTestNear2(result.outputs[1], 15.0)
}
