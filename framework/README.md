# Framework

这里是 CjTensor 机器学习框架主体，包括 Tensor、算子、自动微分、神经网络、优化器、测试和性能基准。

当前 v0.1 原型提供一个 CPU-only、`Float64`、二维 Tensor：

- 行优先存储和 shape 检查；
- 安全索引和数据复制；
- 逐元素加法、乘法和 ReLU；
- 求和与矩阵乘法；
- 非法 shape、索引及算子输入的明确异常。
- 最小动态计算图和反向自动微分；
- `y = x * x + x` 解析梯度与数值梯度对照；
- 使用自动微分训练 `y = 2x + 1` 的端到端线性回归示例。

验证方式：

```powershell
cd framework
cjpm build
cjpm test --no-color
```

这是技术地基，不是完整 PyTorch。当前自动微分先以标量 `Value` 验证机制；下一步把计算图扩展到 Tensor 算子，并加入 `Module`、`Linear` 和 SGD 接口。
