package task_02_clamp

public func clamp(value: Int64, minimum: Int64, maximum: Int64): Int64 {
    if (value < minimum) {
        return minimum
    }
    if (value > maximum) {
        return maximum
    }
    return value
}
