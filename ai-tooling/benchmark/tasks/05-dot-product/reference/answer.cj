package task_05_dot_product

public func dotProduct(left: Array<Int64>, right: Array<Int64>): Int64 {
    var total: Int64 = 0
    for (index in 0..left.size) {
        total += left[index] * right[index]
    }
    return total
}
