package beam_frontier

import std.collection.*

public struct BeamChoice {
    public let parent: Int64
    public let token: Int64
    public let score: Float64

    public init(parent: Int64, token: Int64, score: Float64) {
        this.parent = parent
        this.token = token
        this.score = score
    }
}

public struct BeamStep {
    public let choices: ArrayList<BeamChoice>
    public let step: Int64

    public init(choices: ArrayList<BeamChoice>, step: Int64) {
        this.choices = copyBeamChoices(choices)
        this.step = step
    }
}

func beamFinite(value: Float64): Bool {
    return !value.isNaN() && !value.isInf()
}

func copyBeamScores(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (i in 0..values.size) { result[i] = values[i] }
    return result
}

func copyBeamChoices(values: ArrayList<BeamChoice>): ArrayList<BeamChoice> {
    let result = ArrayList<BeamChoice>()
    for (i in 0..values.size) {
        let item = values[i]
        result.add(BeamChoice(item.parent, item.token, item.score))
    }
    return result
}

public class BeamFrontier {
    public let vocabulary: Int64
    public let beamWidth: Int64
    private let initialState: Array<Float64>
    private var scoreState: Array<Float64>
    private var stepState: Int64

    public init(initialScores: Array<Float64>, vocabulary: Int64, beamWidth: Int64) {
        if (initialScores.size <= 0 || vocabulary <= 0 || beamWidth <= 0 || initialScores.size > beamWidth) {
            throw IllegalArgumentException("invalid beam configuration")
        }
        for (i in 0..initialScores.size) {
            if (!beamFinite(initialScores[i])) { throw IllegalArgumentException("initial scores must be finite") }
        }
        this.vocabulary = vocabulary
        this.beamWidth = beamWidth
        this.initialState = copyBeamScores(initialScores)
        this.scoreState = copyBeamScores(initialScores)
        this.stepState = 0
    }

    public func scores(): Array<Float64> { return copyBeamScores(scoreState) }
    public func step(): Int64 { return stepState }

    public func expand(tokenLogProbabilities: Array<Float64>): BeamStep {
        let currentCount = scoreState.size
        if (currentCount > Int64.Max / vocabulary) { throw IllegalArgumentException("beam shape overflow") }
        let candidateCount = currentCount * vocabulary
        if (tokenLogProbabilities.size != candidateCount) { throw IllegalArgumentException("beam input shape mismatch") }
        let candidateScores = Array<Float64>(candidateCount, repeat: 0.0)
        // Incomplete starter expansion.
        for (parent in 0..1) {
            for (token in 0..vocabulary) {
                let index = parent * vocabulary + token
                if (!beamFinite(tokenLogProbabilities[index])) { throw IllegalArgumentException("token score must be finite") }
                candidateScores[index] = scoreState[parent] + tokenLogProbabilities[index]
            }
        }
        let selectedCount = if (candidateCount < beamWidth) { candidateCount } else { beamWidth }
        let used = Array<Bool>(candidateCount, repeat: false)
        let choices = ArrayList<BeamChoice>()
        let nextScores = Array<Float64>(selectedCount, repeat: 0.0)
        for (rank in 0..selectedCount) {
            var bestIndex: Int64 = -1
            var bestScore = 0.0
            var bestParent: Int64 = 0
            var bestToken: Int64 = 0
            for (index in 0..candidateCount) {
                if (used[index]) { continue }
                let parent = index / vocabulary
                let token = index % vocabulary
                let score = candidateScores[index]
                if (bestIndex < 0 || score > bestScore || (score == bestScore && (parent < bestParent || (parent == bestParent && token < bestToken)))) {
                    bestIndex = index
                    bestScore = score
                    bestParent = parent
                    bestToken = token
                }
            }
            used[bestIndex] = true
            // Intentional local compiler-repair site.
            choices.append(BeamChoice(bestParent, bestToken, bestScore))
            nextScores[rank] = bestScore
        }
        scoreState = nextScores
        stepState += 1
        return BeamStep(choices, stepState)
    }

    public func reset(): Unit {
        scoreState = copyBeamScores(initialState)
        stepState = 0
    }
}
