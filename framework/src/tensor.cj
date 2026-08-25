package cjtensor

/**
 * A two-dimensional, CPU-only tensor backed by row-major Float64 data.
 *
 * Tensor owns a copy of the input data. Operations return new tensors and do
 * not mutate their operands.
 */
public class Tensor {
    public let rows: Int64
    public let columns: Int64
    private let values: Array<Float64>

    public init(values: Array<Float64>, rows: Int64, columns: Int64) {
        if (rows < 0 || columns < 0) {
            throw IllegalArgumentException("Tensor shape cannot be negative.")
        }
        if (rows * columns != values.size) {
            throw IllegalArgumentException("Tensor shape does not match the number of values.")
        }
        this.rows = rows
        this.columns = columns
        this.values = copyArray(values)
    }

    public static func zeros(rows: Int64, columns: Int64): Tensor {
        if (rows < 0 || columns < 0) {
            throw IllegalArgumentException("Tensor shape cannot be negative.")
        }
        return Tensor(Array<Float64>(rows * columns, repeat: 0.0), rows, columns)
    }

    public func at(row: Int64, column: Int64): Float64 {
        checkIndex(row, column)
        return values[row * columns + column]
    }

    public func toArray(): Array<Float64> {
        return copyArray(values)
    }

    public func add(other: Tensor): Tensor {
        requireSameShape(other, "add")
        let result = Array<Float64>(values.size, repeat: 0.0)
        for (index in 0..values.size) {
            result[index] = values[index] + other.values[index]
        }
        return Tensor(result, rows, columns)
    }

    public func multiply(other: Tensor): Tensor {
        requireSameShape(other, "multiply")
        let result = Array<Float64>(values.size, repeat: 0.0)
        for (index in 0..values.size) {
            result[index] = values[index] * other.values[index]
        }
        return Tensor(result, rows, columns)
    }

    public func relu(): Tensor {
        let result = Array<Float64>(values.size, repeat: 0.0)
        for (index in 0..values.size) {
            if (values[index] > 0.0) {
                result[index] = values[index]
            }
        }
        return Tensor(result, rows, columns)
    }

    public func sum(): Float64 {
        var total: Float64 = 0.0
        for (value in values) {
            total += value
        }
        return total
    }

    public func matmul(other: Tensor): Tensor {
        if (columns != other.rows) {
            throw IllegalArgumentException("matmul requires left columns to equal right rows.")
        }
        let result = Array<Float64>(rows * other.columns, repeat: 0.0)
        for (row in 0..rows) {
            for (column in 0..other.columns) {
                var total: Float64 = 0.0
                for (inner in 0..columns) {
                    total += at(row, inner) * other.at(inner, column)
                }
                result[row * other.columns + column] = total
            }
        }
        return Tensor(result, rows, other.columns)
    }

    private func checkIndex(row: Int64, column: Int64): Unit {
        if (row < 0 || row >= rows || column < 0 || column >= columns) {
            throw IndexOutOfBoundsException("Tensor index is outside its shape.")
        }
    }

    private func requireSameShape(other: Tensor, operation: String): Unit {
        if (rows != other.rows || columns != other.columns) {
            throw IllegalArgumentException("${operation} requires tensors with the same shape.")
        }
    }

    private static func copyArray(source: Array<Float64>): Array<Float64> {
        let result = Array<Float64>(source.size, repeat: 0.0)
        for (index in 0..source.size) {
            result[index] = source[index]
        }
        return result
    }
}
