# 08 — 矩阵乘向量

矩阵按行存放在一维数组中。实现：

```cangjie
public func matrixVector(
    matrix: Array<Float64>,
    rows: Int64,
    columns: Int64,
    vector: Array<Float64>
): Array<Float64>
```

可以假设 `matrix.size == rows * columns`、`vector.size == columns`，并且行列数均大于零。返回长度为 `rows` 的结果数组。
