# Cangjie AI Compute Stack

面向仓颉编程语言的轻量级原生 AI 计算栈。

本公共仓库是整个项目的总入口，当前直接维护 Codex 仓颉开发 Skill、编译诊断工具、可重复 Benchmark 和跨仓库路线图。机器学习库 alpha 暂在私有协作仓 `Xi-shiqing/cangjie_machinelearning` 开发，许可证明确后再决定迁入方式。

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

## 仓库边界

```text
examples/               # 公开的仓颉验证示例
ai-tooling/             # Skill、Benchmark 和诊断工具
docs/                   # 架构、环境与验证文档
ROADMAP.md              # 跨仓库阶段计划
```

本公共仓库既是项目总入口，也是 Skill 与 Benchmark 的唯一真源。机器学习私有仓只消费这些开发工具，不复制 Skill，也不把 Skill 引入框架运行时依赖；Skill 或 Benchmark 的变更统一回到本仓库维护。

机器学习框架源码目前只存在于私有协作仓，版本为 `v0.1.0-alpha.1`。该仓尚未附加开源许可证，因此其源码暂不复制或迁入本公共仓库。

## 当前协作边界

- 本公共仓库负责项目总览、跨仓库路线图、Skill、Benchmark、Doctor、验证环境及公开状态文档。
- 私有协作仓负责机器学习库 alpha 的实现与验证；许可证明确后再决定公开迁移方案。

## 当前状态

- Cangjie 1.1.3 CPU core 已真实构建并通过 `243/243` 项测试；
- `model-demo` 已在同一 Cangjie 1.1.3 环境构建成功；
- CUDA 与 CANN 后端已有 alpha 源码，但尚未在对应真实硬件上验证；
- 机器学习源码因缺少开源许可证暂不进入本公共仓库。

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

v22 稳定版与 v23.1 候选版的诊断性 A/B 结果见 [v24 测试报告](ai-tooling/benchmark/results/benchmark-v24-v22-vs-v23.1-2026-09-01.md)。公开仓库只保存题面、starter、公开测试和复现工具，不保存隐藏测试或参考答案；已经出分的 v24 不再改题，后续扩展使用新的 Benchmark 版本。

## Codex Skill

日常开发请安装固定的 [v22 稳定版 Skill](https://github.com/Linzx24/cangjie-ai-compute-stack/tree/cangjie-developer-v22-stable/ai-tooling/skills/cangjie-developer)。主分支中的 [v23.1 候选版](https://github.com/Linzx24/cangjie-ai-compute-stack/tree/cangjie-developer-v23.1-candidate/ai-tooling/skills/cangjie-developer) 只用于后续 A/B，不作为默认安装版本。将稳定版目录复制到 Codex 的 `skills` 目录后，可在新任务中使用：

```text
使用 $cangjie-developer 实现并验证这个仓颉任务。
```

当前已安装的稳定版是 `v22`，本仓库主分支中的目录是 `v23.1` 候选版。Skill 会引导 Codex 使用真实的 `cjc` / `cjpm` 编译测试，并按需读取语言核心、抽象与集合、工程测试、并发与 C 互操作或 AI 数值实现资料。

冻结的 v24 结果仅是诊断性证据；原正式实验结论仍为 `INCONCLUSIVE`，`promotion=false`，不能据此把 v23.1 表述为已晋级或已安装。正式晋级需要修复基础设施后，在新的预注册 Benchmark 版本上从头运行干净 A/B。

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
