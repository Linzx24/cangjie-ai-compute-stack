package ml_core_template

import std.math.*

func templateFinite(value: Float64): Bool {
    return !value.isNaN() && !value.isInf()
}

public class Tensor2D {
    public let rows: Int64
    public let columns: Int64
    private let values: Array<Float64>

    public init(values: Array<Float64>, rows: Int64, columns: Int64) {
        if (rows <= 0 || columns <= 0 || rows > values.size / columns || rows * columns != values.size) {
            throw IllegalArgumentException("invalid tensor shape")
        }
        for (value in values) {
            if (!templateFinite(value)) {
                throw IllegalArgumentException("tensor values must be finite")
            }
        }
        this.rows = rows
        this.columns = columns
        this.values = copyFloatArray(values)
    }

    public func at(row: Int64, column: Int64): Float64 {
        if (row < 0 || row >= rows || column < 0 || column >= columns) {
            throw IllegalArgumentException("invalid tensor index")
        }
        return values[row * columns + column]
    }

    public func toArray(): Array<Float64> {
        return copyFloatArray(values)
    }
}

func copyFloatArray(source: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(source.size, repeat: 0.0)
    for (index in 0..source.size) {
        result[index] = source[index]
    }
    return result
}
