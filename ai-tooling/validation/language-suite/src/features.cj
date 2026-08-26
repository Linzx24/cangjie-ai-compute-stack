package cangjie_language_suite

import std.collection.ArrayList

public interface Transform {
    func apply(value: Float64): Float64
}

public class Scale <: Transform {
    private let factor: Float64

    public init(factor: Float64) {
        this.factor = factor
    }

    public func apply(value: Float64): Float64 {
        return value * factor
    }
}

public struct Counter {
    public var value: Int64

    public init(value: Int64) {
        this.value = value
    }

    public mut func increment(): Unit {
        value++
    }
}

public func applyTwice(value: Int64, operation: (Int64) -> Int64): Int64 {
    return operation(operation(value))
}

public func identity<T>(value: T): T {
    return value
}

public func valueOr(option: Option<Int64>, fallback: Int64): Int64 {
    match (option) {
        case Some(value) => value
        case None => fallback
    }
}

public func scaledCopy(values: Array<Float64>, transform: Transform): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (index in 0..values.size) {
        result[index] = transform.apply(values[index])
    }
    return result
}

public func collectNonNegative(values: Array<Int64>): ArrayList<Int64> {
    let result = ArrayList<Int64>()
    for (value in values) {
        if (value >= 0) {
            result.add(value)
        }
    }
    return result
}

public func requireNonNegative(value: Int64): Int64 {
    if (value < 0) {
        throw IllegalArgumentException("value must be non-negative")
    }
    return value
}
