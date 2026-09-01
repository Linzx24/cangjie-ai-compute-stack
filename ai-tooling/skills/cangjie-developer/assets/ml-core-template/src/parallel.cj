package ml_core_template
import std.collection.*

public func parallelRowSums(input: Tensor2D): Array<Float64> {
    let futures = ArrayList<Future<Float64>>()
    for (row in 0..input.rows) {
        futures.add(spawn { =>
            var total = 0.0
            for (column in 0..input.columns) {
                total += input.at(row, column)
            }
            total
        })
    }
    let result = Array<Float64>(input.rows, repeat: 0.0)
    for (row in 0..input.rows) {
        let total = futures[row].get()
        if (!templateFinite(total)) {
            throw IllegalArgumentException("row sum is not finite")
        }
        result[row] = total
    }
    return result
}
