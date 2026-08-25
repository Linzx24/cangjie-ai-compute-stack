package task_11_tensor_2d

public class Tensor2D {
    public let rows: Int64
    public let columns: Int64
    private let values: Array<Float64>

    public init(values: Array<Float64>, rows: Int64, columns: Int64) {
        this.rows = rows
        this.columns = columns
        this.values = copyArray(values)
    }

    public func at(row: Int64, column: Int64): Float64 {
        return values[row * columns + column]
    }

    public func toArray(): Array<Float64> {
        return copyArray(values)
    }

    public func add(other: Tensor2D): Tensor2D {
        let result = Array<Float64>(values.size, repeat: 0.0)
        for (index in 0..values.size) {
            result[index] = values[index] + other.values[index]
        }
        return Tensor2D(result, rows, columns)
    }

    public func relu(): Tensor2D {
        let result = Array<Float64>(values.size, repeat: 0.0)
        for (index in 0..values.size) {
            if (values[index] > 0.0) {
                result[index] = values[index]
            }
        }
        return Tensor2D(result, rows, columns)
    }

    public func sum(): Float64 {
        var total: Float64 = 0.0
        for (value in values) {
            total += value
        }
        return total
    }

    public func matmul(other: Tensor2D): Tensor2D {
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
        return Tensor2D(result, rows, other.columns)
    }

    private static func copyArray(source: Array<Float64>): Array<Float64> {
        let result = Array<Float64>(source.size, repeat: 0.0)
        for (index in 0..source.size) {
            result[index] = source[index]
        }
        return result
    }
}
