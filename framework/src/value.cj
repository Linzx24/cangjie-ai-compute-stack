package cjtensor

/**
 * A scalar value with a small dynamic reverse-mode automatic-differentiation
 * graph. It is intentionally minimal and validates the core gradient idea
 * before Tensor-level autograd is introduced.
 */
public class Value {
    public var data: Float64
    public var grad: Float64
    private let operation: String
    private let left: ?Value
    private let right: ?Value

    public init(data: Float64) {
        this.data = data
        this.grad = 0.0
        this.operation = "leaf"
        this.left = None
        this.right = None
    }

    private init(data: Float64, operation: String, left: Value, right: Value) {
        this.data = data
        this.grad = 0.0
        this.operation = operation
        this.left = Some(left)
        this.right = Some(right)
    }

    public func add(other: Value): Value {
        return Value(data + other.data, "add", this, other)
    }

    public func multiply(other: Value): Value {
        return Value(data * other.data, "multiply", this, other)
    }

    public func zeroGrad(): Unit {
        grad = 0.0
    }

    public func backward(): Unit {
        propagate(1.0)
    }

    private func propagate(seed: Float64): Unit {
        grad += seed
        if (operation == "add") {
            left.getOrThrow().propagate(seed)
            right.getOrThrow().propagate(seed)
        } else if (operation == "multiply") {
            let leftValue = left.getOrThrow()
            let rightValue = right.getOrThrow()
            leftValue.propagate(seed * rightValue.data)
            rightValue.propagate(seed * leftValue.data)
        }
    }
}
