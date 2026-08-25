package task_04_factorial

public func factorial(value: Int64): Int64 {
    if (value <= 1) {
        return 1
    }
    return value * factorial(value - 1)
}
