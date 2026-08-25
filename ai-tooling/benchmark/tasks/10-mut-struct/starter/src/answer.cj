package task_10_mut_struct

public struct MutableVector2 {
    public let x: Float64
    public let y: Float64

    public init(x: Float64, y: Float64) {
        this.x = x
        this.y = y
    }

    public func scale(factor: Float64): Unit {
        x *= factor
        y *= factor
    }

    public func magnitudeSquared(): Int64 {
        return x * x + y * y
    }
}
