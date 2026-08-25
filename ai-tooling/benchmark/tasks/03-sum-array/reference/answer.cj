package task_03_sum_array

public func sumArray(values: Array<Int64>): Int64 {
    var total: Int64 = 0
    for (value in values) {
        total += value
    }
    return total
}
