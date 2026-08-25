# 10 — 修复可变结构体

当前 `answer.cj` 无法编译。请修复 `MutableVector2`，但保留类型名、公开字段、构造函数及两个函数的名称和参数。

要求：

- `x`、`y` 是可以被修改的 `Float64` 字段；
- `scale(factor)` 原地缩放两个字段；
- `magnitudeSquared()` 返回 `x * x + y * y`；
- 必须保留为 `struct`，不能改成 `class`。
