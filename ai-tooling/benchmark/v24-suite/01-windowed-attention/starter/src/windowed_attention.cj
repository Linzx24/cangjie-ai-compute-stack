package windowed_attention

import std.math.*

public struct WindowAttentionResult {
    public let outputs: Array<Float64>
    public let weights: Array<Float64>
    public let tokens: Int64
    public let width: Int64

    public init(outputs: Array<Float64>, weights: Array<Float64>, tokens: Int64, width: Int64) {
        this.outputs = outputs
        this.weights = weights
        this.tokens = tokens
        this.width = width
    }
}

func copyFloats(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (i in 0..values.size) {
        result[i] = values[i]
    }
    return result
}

func finiteAttentionValue(value: Float64): Bool {
    return !value.isNaN() && !value.isInf()
}

public func applyWindowedAttention(query: Array<Float64>, key: Array<Float64>, value: Array<Float64>, tokens: Int64, width: Int64, window: Int64, temperature: Float64): WindowAttentionResult {
    if (tokens <= 0 || width <= 0 || window < 0 || window >= tokens || !finiteAttentionValue(temperature) || temperature <= 0.0) {
        throw IllegalArgumentException("invalid attention shape or temperature")
    }
    if (tokens > Int64.Max / width) {
        throw IllegalArgumentException("attention shape overflow")
    }
    let length = tokens * width
    if (query.size != length || key.size != length || value.size != length) {
        throw IllegalArgumentException("query, key, and value shapes must match")
    }
    for (i in 0..length) {
        if (!finiteAttentionValue(query[i]) || !finiteAttentionValue(key[i]) || !finiteAttentionValue(value[i])) {
            throw IllegalArgumentException("attention inputs must be finite")
        }
    }

    let output = Array<Float64>(length, repeat: 0.0)
    let allWeights = Array<Float64>(tokens * tokens, repeat: 0.0)
    for (row in 0..tokens) {
        // Starter limitation: it currently attends only to the diagonal.
        let start = row
        let stop = row + 1
        let scores = Array<Float64>(tokens, repeat: 0.0)
        var maximum = 0.0
        var first = true
        for (column in start..stop) {
            var score = 0.0
            for (feature in 0..width) {
                score += query[row * width + feature] * key[column * width + feature]
            }
            score = score / temperature
            if (!finiteAttentionValue(score)) {
                throw IllegalArgumentException("attention score is not finite")
            }
            scores[column] = score
            if (first || score > maximum) {
                maximum = score
                first = false
            }
        }

        var denominator = 0.0
        for (column in start..stop) {
            let weight = exp(scores[column] - maximum)
            if (!finiteAttentionValue(weight)) {
                throw IllegalArgumentException("attention softmax is not finite")
            }
            denominator += weight
        }
        if (!finiteAttentionValue(denominator) || denominator <= 0.0) {
            throw IllegalArgumentException("attention softmax denominator is invalid")
        }
        for (column in start..stop) {
            let probability = exp(scores[column] - maximum) / denominator
            allWeights[row * tokens + column] = probability
        }
        for (feature in 0..width) {
            var accumulated = 0.0
            for (column in start..stop) {
                accumulated += allWeights[row * tokens + column] * value[column * width + feature]
            }
            if (!finiteAttentionValue(accumulated)) {
                throw IllegalArgumentException("attention output is not finite")
            }
            output[row * width + feature] = accumulated
        }
    }
    return WindowAttentionResult(copyFloats(output), copyFloats(allWeights), tokens, width)
}
