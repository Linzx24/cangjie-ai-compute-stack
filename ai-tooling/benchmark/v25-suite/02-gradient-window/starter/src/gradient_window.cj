package gradient_window

import std.math.*

public struct GradientWindowReport {
    public let collected: Int64
    public let step: Int64
    public let applied: Bool
    public let gradientNorm: Float64
    public let clipScale: Float64

    public init(collected: Int64, step: Int64, applied: Bool, gradientNorm: Float64, clipScale: Float64) {
        this.collected = collected
        this.step = step
        this.applied = applied
        this.gradientNorm = gradientNorm
        this.clipScale = clipScale
    }
}

func copyGradientFloats(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (i in 0..values.size) { result[i] = values[i] }
    return result
}

func gradientFinite(value: Float64): Bool {
    return !value.isNaN() && !value.isInf()
}

public class GradientWindow {
    public let expectedSamples: Int64
    public let learningRate: Float64
    public let maxNorm: Float64
    private let initialState: Array<Float64>
    private var valueState: Array<Float64>
    private var accumulationState: Array<Float64>
    private var collectedState: Int64
    private var stepState: Int64

    public init(initialValues: Array<Float64>, expectedSamples: Int64, learningRate: Float64, maxNorm: Float64) {
        if (initialValues.size <= 0 || expectedSamples <= 0 || !gradientFinite(learningRate) || learningRate <= 0.0 || !gradientFinite(maxNorm) || maxNorm <= 0.0) {
            throw IllegalArgumentException("invalid gradient window configuration")
        }
        for (i in 0..initialValues.size) {
            if (!gradientFinite(initialValues[i])) { throw IllegalArgumentException("initial values must be finite") }
        }
        this.expectedSamples = expectedSamples
        this.learningRate = learningRate
        this.maxNorm = maxNorm
        this.initialState = copyGradientFloats(initialValues)
        this.valueState = copyGradientFloats(initialValues)
        this.accumulationState = Array<Float64>(initialValues.size, repeat: 0.0)
        this.collectedState = 0
        this.stepState = 0
    }

    public func values(): Array<Float64> { return copyGradientFloats(valueState) }
    public func accumulated(): Array<Float64> { return copyGradientFloats(accumulationState) }
    public func collected(): Int64 { return collectedState }
    public func step(): Int64 { return stepState }

    public func add(gradientSums: Array<Float64>, samples: Int64): GradientWindowReport {
        if (samples <= 0 || samples > expectedSamples - collectedState || gradientSums.size != valueState.size) {
            throw IllegalArgumentException("invalid microbatch shape or sample count")
        }
        let nextAccumulation = copyGradientFloats(accumulationState)
        for (i in 0..gradientSums.size) {
            if (!gradientFinite(gradientSums[i])) { throw IllegalArgumentException("gradient sums must be finite") }
            nextAccumulation[i] += gradientSums[i]
            if (!gradientFinite(nextAccumulation[i])) { throw IllegalArgumentException("accumulated gradient is not finite") }
        }
        let nextCollected = collectedState + samples
        if (nextCollected < expectedSamples) {
            accumulationState = nextAccumulation
            collectedState = nextCollected
            return GradientWindowReport(collectedState, stepState, false, 0.0, 1.0)
        }

        let means = Array<Float64>(valueState.size, repeat: 0.0)
        var normSquared = 0.0
        for (i in 0..means.size) {
            // Incomplete starter completion transition.
            means[i] = nextAccumulation[i] / Float64(samples)
            let squared = means[i] * means[i]
            if (!gradientFinite(means[i]) || !gradientFinite(squared)) { throw IllegalArgumentException("mean gradient is not finite") }
            normSquared += squared
            if (!gradientFinite(normSquared)) { throw IllegalArgumentException("gradient norm is not finite") }
        }
        let norm = sqrt(normSquared)
        let scale = if (norm > maxNorm) { maxNorm / norm } else { 1.0 }
        let nextValues = copyGradientFloats(valueState)
        for (i in 0..nextValues.size) {
            nextValues[i] = valueState[i] - learningRate * means[i] * scale
            if (!gradientFinite(nextValues[i])) { throw IllegalArgumentException("updated value is not finite") }
        }
        valueState = nextValues
        accumulationState = Array<Float64>(valueState.size, repeat: 0.0)
        collectedState = 0
        stepState += 1
        return GradientWindowReport(0, stepState, true, norm, scale)
    }

    public func reset(): Unit {
        // Incomplete starter reset transition.
        accumulationState = Array<Float64>(initialState.size, repeat: 0.0)
        collectedState = 0
        stepState = 0
    }
}
