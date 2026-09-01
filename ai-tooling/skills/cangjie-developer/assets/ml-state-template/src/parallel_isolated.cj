package ml_state_template

import std.collection.*

public func parallelScale(values: Array<Float64>, factor: Float64): Array<Float64> {
    if (factor.isNaN() || factor.isInf()) {
        throw IllegalArgumentException("factor must be finite")
    }
    for (value in values) {
        if (value.isNaN() || value.isInf()) {
            throw IllegalArgumentException("values must be finite")
        }
    }
    let futures = ArrayList<Future<Float64>>()
    for (index in 0..values.size) {
        let value = values[index]
        futures.add(spawn { => value * factor })
    }
    let result = Array<Float64>(values.size, repeat: 0.0)
    var invalidResult = false
    for (index in 0..values.size) {
        let candidate = futures[index].get()
        if (candidate.isNaN() || candidate.isInf()) {
            invalidResult = true
        }
        result[index] = candidate
    }
    if (invalidResult) {
        throw IllegalArgumentException("result must be finite")
    }
    return result
}
