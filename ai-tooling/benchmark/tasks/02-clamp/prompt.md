# 02 — 限制数值范围

实现：

```cangjie
public func clamp(value: Int64, minimum: Int64, maximum: Int64): Int64
```

- 小于 `minimum` 时返回 `minimum`；
- 大于 `maximum` 时返回 `maximum`；
- 否则返回原值。

可以假设 `minimum <= maximum`。
