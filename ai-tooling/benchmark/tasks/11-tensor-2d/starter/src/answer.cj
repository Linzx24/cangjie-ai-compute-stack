package task_11_tensor_2d

public class Tensor2D {
    public let rows: Int64
    public let columns: Int64
    private let values: Array<Float64>

    public init(values: Array<Float64>, rows: Int64, columns: Int64) {
        this.rows = rows
        this.columns = columns
        this.values = values
    }

    public func at(row: Int64, column: Int64): Float64 {
        return 0.0
    }

    public func toArray(): Array<Float64> {
        return values
    }

    public func add(other: Tensor2D): Tensor2D {
        return this
    }

    public func relu(): Tensor2D {
        return this
    }

    public func sum(): Float64 {
        return 0.0
    }

    public func matmul(other: Tensor2D): Tensor2D {
        return this
    }
}
