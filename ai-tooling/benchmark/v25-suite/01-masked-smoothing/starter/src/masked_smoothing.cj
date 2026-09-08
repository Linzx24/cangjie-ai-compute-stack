package masked_smoothing

import std.math.*

public struct SmoothedLossResult {
    public let loss: Float64
    public let probabilities: Array<Float64>
    public let gradients: Array<Float64>
    public let active: Int64

    public init(loss: Float64, probabilities: Array<Float64>, gradients: Array<Float64>, active: Int64) {
        this.loss = loss
        this.probabilities = copySmoothingFloats(probabilities)
        this.gradients = copySmoothingFloats(gradients)
        this.active = active
    }
}

func copySmoothingFloats(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (i in 0..values.size) { result[i] = values[i] }
    return result
}

func smoothingFinite(value: Float64): Bool {
    return !value.isNaN() && !value.isInf()
}

public func maskedSmoothedCrossEntropy(logits: Array<Float64>, labels: Array<Int64>, activeMask: Array<Bool>, rows: Int64, classes: Int64, smoothing: Float64): SmoothedLossResult {
    if (rows <= 0 || classes <= 1 || !smoothingFinite(smoothing) || smoothing < 0.0 || smoothing >= 1.0) {
        throw IllegalArgumentException("invalid loss configuration")
    }
    if (rows > Int64.Max / classes) { throw IllegalArgumentException("loss shape overflow") }
    let length = rows * classes
    if (logits.size != length || labels.size != rows || activeMask.size != rows) {
        throw IllegalArgumentException("loss input shape mismatch")
    }
    var active: Int64 = 0
    for (row in 0..rows) {
        if (labels[row] < 0 || labels[row] >= classes) { throw IllegalArgumentException("label out of range") }
        if (activeMask[row]) { active += 1 }
    }
    for (i in 0..length) {
        if (!smoothingFinite(logits[i])) { throw IllegalArgumentException("logits must be finite") }
    }
    if (active == 0) { throw IllegalArgumentException("at least one row must be active") }

    let probabilities = Array<Float64>(length, repeat: 0.0)
    let gradients = Array<Float64>(length, repeat: 0.0)
    // Incomplete starter objective.
    let inverse = 1.0 / Float64(rows)
    var totalLoss = 0.0
    for (row in 0..rows) {
        if (!activeMask[row]) { continue }
        let offset = row * classes
        var maximum = logits[offset]
        for (classIndex in 1..classes) {
            if (logits[offset + classIndex] > maximum) { maximum = logits[offset + classIndex] }
        }
        var denominator = 0.0
        for (classIndex in 0..classes) { denominator += exp(logits[offset + classIndex] - maximum) }
        if (!smoothingFinite(denominator) || denominator <= 0.0) { throw IllegalArgumentException("softmax denominator is invalid") }
        let logNormalizer = maximum + log(denominator)
        for (classIndex in 0..classes) {
            let index = offset + classIndex
            let probability = exp(logits[index] - maximum) / denominator
            let target = if (classIndex == labels[row]) { 1.0 } else { 0.0 }
            probabilities[index] = probability
            gradients[index] = (probability - target) * inverse
        }
        totalLoss += logNormalizer - logits[offset + labels[row]]
    }
    return SmoothedLossResult(totalLoss * inverse, probabilities, gradients, active)
}
