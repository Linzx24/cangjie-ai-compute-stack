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
3. 完成 CjTensor 技术验证；
4. 合并正式项目计划；
5. 进入框架主体开发。

## 立即开始

Windows 开发环境请先阅读 [docs/setup-cangjie-1.1.3-windows.md](docs/setup-cangjie-1.1.3-windows.md)，然后运行：

```powershell
.\scripts\check-cangjie.ps1 -RunSmokeTest
```

该命令会检查仓颉版本，并编译、运行、测试仓库中的第一个仓颉小项目。

项目当前做到哪里，请查看 [PROGRESS.md](PROGRESS.md)。仓颉能力评测位于 [ai-tooling/benchmark](ai-tooling/benchmark)。

## Codex Skill

仓颉开发 Skill 位于 [ai-tooling/skills/cangjie-developer](ai-tooling/skills/cangjie-developer)。将该目录复制到 Codex 的 `skills` 目录后，可在新任务中使用：

```text
使用 $cangjie-developer 实现并验证这个仓颉任务。
```

Skill 会引导 Codex 使用真实的 `cjc` / `cjpm` 编译测试，并按需读取仓颉语法、工程测试或 AI 张量实现资料。Benchmark v0.3 的隔离复测为 45/45；详细结果见 [Skill 复测报告](ai-tooling/benchmark/results/skill-v0.3-2026-08-26.md)。

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
