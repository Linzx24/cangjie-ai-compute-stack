# Cangjie AI Compute Stack

面向仓颉编程语言的轻量级原生 AI 计算栈。

本项目计划使用仓颉实现张量计算、自动微分、基础神经网络和可扩展计算后端，并提供配套的 Codex 仓颉开发 Skill、编译诊断工具及可重复 Benchmark。

## 项目愿景

```text
仓颉应用开发者
      │
      ▼
CjTensor：张量、自动微分、神经网络、优化器
      │
      ▼
Backend：CPU，后续扩展 GPU / NPU

开发基础设施
├── Cangjie Developer Skill
├── Cangjie Doctor
└── Cangjie Benchmark
```

## 比赛版本目标

比赛阶段不追求完整重写 PyTorch，而是交付一个小而完整、可以真实运行和验证的版本：

- 仓颉原生 Tensor 数据结构；
- 加减乘除、矩阵乘、求和等基础算子；
- 动态计算图和自动微分；
- Linear、ReLU、Sequential 等基础神经网络组件；
- SGD 优化器；
- XOR 与 MNIST 训练示例；
- 单元测试、梯度检查和性能基准；
- Codex 仓颉开发与编译诊断 Skill。

## 仓库规划

```text
framework/              # CjTensor 机器学习框架主体
examples/               # XOR、MNIST 等完整演示
ai-tooling/              # Skill、Benchmark 和诊断工具
docs/                   # 架构、比赛材料和开发文档
ROADMAP.md               # 项目阶段计划
```

## 两位成员当前分工

- 项目计划：需求范围、开发排期、演示与比赛材料规划。
- 仓颉 AI 开发能力：仓颉学习、Skill、Benchmark、编译诊断及验证环境。

具体代码模块将在计划确认后进一步分配，所有成果统一进入本仓库。

## 当前阶段

1. 固定 STS Cangjie 1.1.3 开发环境；
2. 建立仓颉可编译示例和能力 Benchmark；
3. 完成仓颉开发 Skill 与编译诊断 Skill 的验证；
4. 合并正式项目计划；
5. 进入框架主体开发。

## 立即开始

Windows 开发环境请先阅读 [docs/setup-cangjie-1.1.3-windows.md](docs/setup-cangjie-1.1.3-windows.md)，然后运行：

```powershell
.\scripts\check-cangjie.ps1 -RunSmokeTest
```

该命令会检查仓颉版本，并编译、运行、测试仓库中的第一个仓颉小项目。

项目当前做到哪里，请查看 [PROGRESS.md](PROGRESS.md)。仓颉能力评测位于 [ai-tooling/benchmark](ai-tooling/benchmark)。

准备好官方 Cangjie 1.1.3 Linux x64 SDK 与 Docker Desktop 后，可执行跨平台一键验收：

```powershell
.\scripts\docker-verify.ps1
```

该脚本会校验 SDK 哈希、构建 Linux 镜像，并测试 hello 示例和仓颉语言能力验证套件。实测结果见 [Docker/Linux 验证记录](docs/docker-linux-validation.md)。

## 可复现 Benchmark

当前冻结的公开评测集是 [Cangjie v24 Benchmark](ai-tooling/benchmark/v24-suite)：包含 4 道复杂任务、4 份待完善 starter、16 个公开测试，以及清单、哈希和校准脚本。题目覆盖窗口注意力、Softmax 训练、批量事件解析和状态快照。

在安装 Cangjie 1.1.3 后，可以验证公开评测集的文件边界和完整性：

```powershell
pwsh -NoProfile -File .\ai-tooling\benchmark\v24-suite\scripts\Validate-V24PublicSuite.ps1
```

Windows 下建议把仓库放在较短的绝对路径中；路径过深时，`cjpm` 生成的构建日志路径可能超过系统限制。

最新版 Skill 与上一稳定版的诊断性 A/B 结果见 [v24 测试报告](ai-tooling/benchmark/results/benchmark-v24-v22-vs-v23.1-2026-09-01.md)。公开仓库只保存题面、starter、公开测试和复现工具，不保存隐藏测试或参考答案；已经出分的 v24 不再改题，后续扩展使用新的 Benchmark 版本。

## Codex Skill

仓颉开发 Skill 位于 [ai-tooling/skills/cangjie-developer](ai-tooling/skills/cangjie-developer)。将该目录复制到 Codex 的 `skills` 目录后，可在新任务中使用：

```text
使用 $cangjie-developer 实现并验证这个仓颉任务。
```

Skill 会引导 Codex 使用真实的 `cjc` / `cjpm` 编译测试，并按需读取语言核心、抽象与集合、工程测试、并发与 C 互操作或 AI 数值实现资料。最新公开证据以冻结的 v24 评测集和对应报告为准；该轮结果属于诊断性证据，不冒充正式晋级结论。

独立于正式框架的语言验证套件位于 [ai-tooling/validation](ai-tooling/validation)，用于确认 Skill 中的关键语法和工程判断能通过真实编译器。
当前覆盖范围、验证证据和能力边界见 [仓颉 Skill 验收报告](docs/cangjie-skill-validation.md)。

编译、测试或环境出错时，可使用 [Cangjie Doctor](ai-tooling/skills/cangjie-doctor)：

```text
使用 $cangjie-doctor 诊断这个仓颉项目，先不要修改代码。
```

## 开发原则

- 官方文档负责说明，真实编译器负责裁决；
- 未通过 `cjc` / `cjpm` 编译和测试的代码，不标记为已完成；
- 先完成稳定的 CPU 版本，再考虑 GPU 或 NPU；
- 所有重要功能必须配套测试和可复现实验；
- AI 生成内容必须经过人工审查和真实环境验证。

## 许可证

Apache License 2.0。
