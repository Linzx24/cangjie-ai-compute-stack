package task_07_relu_array

public func relu(values: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(values.size, repeat: 0.0)
    for (index in 0..values.size) {
        if (values[index] > 0.0) {
            result[index] = values[index]
        }
    }
    return result
}
