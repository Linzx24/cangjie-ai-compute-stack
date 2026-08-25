package task_08_matrix_vector

public func matrixVector(matrix: Array<Float64>, rows: Int64, columns: Int64, vector: Array<Float64>): Array<Float64> {
    let result = Array<Float64>(rows, repeat: 0.0)
    for (row in 0..rows) {
        var total: Float64 = 0.0
        for (column in 0..columns) {
            total += matrix[row * columns + column] * vector[column]
        }
        result[row] = total
    }
    return result
}
