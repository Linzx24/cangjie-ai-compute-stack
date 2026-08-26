# CjTensor v0.1 技术验收

日期：2026-08-26  
环境：Cangjie 1.1.3，CJNative；Windows x86_64 MinGW 与 Docker/Linux x86_64

## 验收结论

CjTensor v0.1 已通过真实仓颉工具链构建和 8 个单元测试，证明以下最小闭环可行：

1. 使用仓颉原生 `Array<Float64>` 实现二维 Tensor；
2. 实现 shape、索引、数据复制、逐元素运算、ReLU、sum 和 matmul；
3. 使用动态计算图完成标量反向自动微分；
4. `y = x * x + x` 在 `x = 3` 时得到 `y = 12`、梯度 `7`；
5. 自动微分结果通过中心差分数值梯度检查；
6. 使用自动微分和梯度下降学习 `y = 2x + 1`。

## 验证命令

```powershell
cd framework
cjpm build
cjpm test --no-color
```

结果：

```text
cjpm build success
Summary: TOTAL: 8
PASSED: 8, SKIPPED: 0, ERROR: 0
FAILED: 0
cjpm test success
```

Cangjie Doctor 复核结果：SDK、Build、Tests 全部通过，结论为“健康”。

Docker/Linux 复核结果：官方 Linux x64 SDK 的 SHA-256 校验通过，容器内编译器目标为
`x86_64-unknown-linux-gnu`；hello 示例 1/1、CjTensor 8/8 测试全部通过。运行命令：

```powershell
.\scripts\docker-verify.ps1
```

## 测试覆盖

- Tensor 输入复制与行优先索引；
- add、multiply、ReLU、sum、zeros；
- 2×3 与 3×2 的矩阵乘；
- 非法 shape、越界索引和不兼容算子输入；
- 共享输入计算图的梯度累加；
- 数值梯度检查；
- 线性回归端到端训练；
- 非法训练参数。

## 已知边界

- Tensor 当前只支持二维 `Float64` 和 CPU；
- 自动微分当前以标量 `Value` 验证机制，尚未连接 Tensor 算子；
- 当前反向传播按路径递归，后续需要拓扑排序以支持更大的通用计算图；
- 3 条编译 warning 来自 `@AssertThrows` 的单元测试宏展开，测试仍全部通过；
- 当前 Docker 镜像面向 Linux x86_64；ARM64 和其他 Linux 发行版尚未验证。

因此，这一版本应描述为“仓颉原生 AI 计算栈的可运行技术原型”，而不是“仓颉版 PyTorch 已完成”。
