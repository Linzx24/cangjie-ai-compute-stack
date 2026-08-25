# 06 — 安全除法

实现：

```cangjie
public func safeDivide(numerator: Float64, denominator: Float64): Option<Float64>
```

当分母等于 `0.0` 时返回 `None`，否则返回包含计算结果的 `Some`。
