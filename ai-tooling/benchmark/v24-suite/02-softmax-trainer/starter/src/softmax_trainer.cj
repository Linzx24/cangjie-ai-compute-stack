package softmax_trainer

import std.math.*

public struct BatchReport {
    public let loss: Float64
    public let accuracy: Float64
    public let step: Int64
    public let applied: Bool

    public init(loss: Float64, accuracy: Float64, step: Int64, applied: Bool) {
        this.loss = loss
        this.accuracy = accuracy
        this.step = step
        this.applied = applied
    }
}

func copyTrainerArray(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (i in 0..values.size) { result[i] = values[i] }
    return result
}

func trainerFinite(value: Float64): Bool {
    return !value.isNaN() && !value.isInf()
}

public class SoftmaxTrainer {
    public let featureCount: Int64
    public let classCount: Int64
    private let learningRateState: Float64
    private var weightState: Array<Float64>
    private var biasState: Array<Float64>
    private var stepState: Int64

    public init(featureCount: Int64, classCount: Int64, learningRate: Float64) {
        if (featureCount <= 0 || classCount <= 1 || !trainerFinite(learningRate) || learningRate <= 0.0) {
            throw IllegalArgumentException("invalid trainer configuration")
        }
        if (featureCount > Int64.Max / classCount) {
            throw IllegalArgumentException("trainer shape overflow")
        }
        this.featureCount = featureCount
        this.classCount = classCount
        this.learningRateState = learningRate
        this.weightState = Array<Float64>(featureCount * classCount, repeat: 0.0)
        this.biasState = Array<Float64>(classCount, repeat: 0.0)
        this.stepState = 0
    }

    public func weights(): Array<Float64> {
        return copyTrainerArray(weightState)
    }

    public func bias(): Array<Float64> {
        return copyTrainerArray(biasState)
    }

    public func step(): Int64 {
        return stepState
    }

    public func reset(): Unit {
        for (i in 0..weightState.size) { weightState[i] = 0.0 }
        for (i in 0..biasState.size) { biasState[i] = 0.0 }
        stepState = 0
    }

    public func predict(features: Array<Float64>): Array<Int64> {
        if (features.size <= 0 || features.size % featureCount != 0) {
            throw IllegalArgumentException("feature shape does not form a batch")
        }
        let batch = features.size / featureCount
        let result = Array<Int64>(batch, repeat: 0)
        for (row in 0..batch) {
            var bestClass = 0
            var bestScore = 0.0
            for (classIndex in 0..classCount) {
                var score = biasState[classIndex]
                for (feature in 0..featureCount) {
                    let input = features[row * featureCount + feature]
                    if (!trainerFinite(input)) { throw IllegalArgumentException("features must be finite") }
                    score += input * weightState[feature * classCount + classIndex]
                }
                if (!trainerFinite(score)) { throw IllegalArgumentException("logit is not finite") }
                if (classIndex == 0 || score > bestScore) {
                    bestClass = classIndex
                    bestScore = score
                }
            }
            result[row] = Int64(bestClass)
        }
        return result
    }

    public func trainBatch(features: Array<Float64>, labels: Array<Int64>): BatchReport {
        if (features.size <= 0 || features.size % featureCount != 0) {
            throw IllegalArgumentException("feature shape does not form a batch")
        }
        let batch = features.size / featureCount
        if (labels.size != batch) { throw IllegalArgumentException("label count does not match batch") }
        for (i in 0..features.size) {
            if (!trainerFinite(features[i])) { throw IllegalArgumentException("features must be finite") }
        }
        for (i in 0..labels.size) {
            if (labels[i] < 0 || labels[i] >= classCount) { throw IllegalArgumentException("label is out of range") }
        }

        let gradientW = Array<Float64>(weightState.size, repeat: 0.0)
        let gradientB = Array<Float64>(classCount, repeat: 0.0)
        var totalLoss = 0.0
        var correct: Int64 = 0
        for (row in 0..batch) {
            let logits = Array<Float64>(classCount, repeat: 0.0)
            var maximum = 0.0
            var haveMaximum = false
            for (classIndex in 0..classCount) {
                var score = biasState[classIndex]
                for (feature in 0..featureCount) {
                    score += features[row * featureCount + feature] * weightState[feature * classCount + classIndex]
                }
                if (!trainerFinite(score)) { throw IllegalArgumentException("logit is not finite") }
                logits[classIndex] = score
                if (!haveMaximum || score > maximum) {
                    maximum = score
                    haveMaximum = true
                }
            }
            let probabilities = Array<Float64>(classCount, repeat: 0.0)
            var denominator = 0.0
            for (classIndex in 0..classCount) { denominator += exp(logits[classIndex] - maximum) }
            if (!trainerFinite(denominator) || denominator <= 0.0) { throw IllegalArgumentException("softmax denominator is invalid") }
            var bestClass = 0
            var bestProbability = -1.0
            for (classIndex in 0..classCount) {
                probabilities[classIndex] = exp(logits[classIndex] - maximum) / denominator
                if (probabilities[classIndex] > bestProbability) {
                    bestProbability = probabilities[classIndex]
                    bestClass = classIndex
                }
            }
            let label = labels[row]
            if (bestClass == label) { correct += 1 }
            let targetProbability = probabilities[label]
            if (!trainerFinite(targetProbability) || targetProbability <= 0.0) { throw IllegalArgumentException("target probability is invalid") }
            totalLoss += -log(targetProbability)
            for (classIndex in 0..classCount) {
                let delta = probabilities[classIndex] - if (classIndex == label) { 1.0 } else { 0.0 }
                gradientB[classIndex] += delta
                for (feature in 0..featureCount) {
                    gradientW[feature * classCount + classIndex] += features[row * featureCount + feature] * delta
                }
            }
        }

        let inverseBatch = 1.0 / Float64(batch)
        let nextWeights = copyTrainerArray(weightState)
        let nextBias = copyTrainerArray(biasState)
        for (i in 0..nextWeights.size) {
            nextWeights[i] -= learningRateState * gradientW[i] * inverseBatch
            if (!trainerFinite(nextWeights[i])) { throw IllegalArgumentException("weight update is not finite") }
        }
        for (i in 0..nextBias.size) {
            nextBias[i] -= learningRateState * gradientB[i] * inverseBatch
            if (!trainerFinite(nextBias[i])) { throw IllegalArgumentException("bias update is not finite") }
        }
        // Starter limitation: the candidate update is not yet committed.
        _ = nextWeights
        _ = nextBias
        stepState += 1
        return BatchReport(totalLoss * inverseBatch, Float64(correct) * inverseBatch, stepState, true)
    }
}
