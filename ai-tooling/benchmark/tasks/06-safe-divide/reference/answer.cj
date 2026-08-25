package task_06_safe_divide

public func safeDivide(numerator: Float64, denominator: Float64): Option<Float64> {
    if (denominator == 0.0) {
        return None
    }
    return Some(numerator / denominator)
}
