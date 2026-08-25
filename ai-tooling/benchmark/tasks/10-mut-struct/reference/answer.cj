package task_10_mut_struct

public struct MutableVector2 {
    public var x: Float64
    public var y: Float64

    public init(x: Float64, y: Float64) {
        this.x = x
        this.y = y
    }

    public mut func scale(factor: Float64): Unit {
        x *= factor
        y *= factor
    }

    public func magnitudeSquared(): Float64 {
        return x * x + y * y
    }
}
