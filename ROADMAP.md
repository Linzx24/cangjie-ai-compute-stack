# 项目路线图

最后更新：2026-09-05

本公共仓库是整个项目的总入口，也是 Skill 与 Benchmark 的唯一真源；机器学习 alpha 在私有协作仓 `Xi-shiqing/cangjie_machinelearning` 开发，不复制 Skill。该私有仓尚无开源许可证，许可证明确前不向本公共仓库迁移源码。

## Phase 0 — 立项与环境

- [ ] 确定项目正式名称和对外介绍
- [x] 固定 STS Cangjie 1.1.3 环境
- [x] 验证 `cjc`、`cjpm`、构建和测试命令
- [x] 提交 Docker/Linux 可复现环境配置
- [x] 安装 Docker Desktop 与 WSL 2
- [x] 在安装 Docker 后完成 Linux 运行验证
- [ ] 完成比赛规则与现有项目查重
- [x] 确定公共工具仓与私有机器学习仓的协作边界

## Phase 1 — 仓颉开发能力

- [x] 建立第一个仓颉可编译示例
- [x] 建立无 Skill 基线 Benchmark v0.1
- [x] 扩展 Benchmark v0.3，增加 Option、泛型、诊断和 Tensor 综合题
- [x] 发布并安装 Cangjie Developer Skill v22 稳定版
- [x] 建立 Cangjie Doctor 初版
- [x] 对比使用 Skill 前后的成绩
- [x] 冻结 v24 公开评测集并完成 v22 与 v23.1 的诊断性 A/B
- [ ] 在新的预注册 Benchmark 上完成 v23.1 正式晋级验证（v24 正式结论为 `INCONCLUSIVE`）

## Phase 2 — 机器学习 alpha（私有协作仓）

- [x] 完成 README 标记的 `v0.1.0-alpha.1` 开发检查点
- [x] 使用 Cangjie 1.1.3 构建 CPU core
- [x] CPU core 单元测试 `243/243` 通过
- [x] `model-demo` 构建成功
- [ ] 选择并附加明确的开源许可证
- [ ] 许可证明确后决定源码公开迁移方案

## Phase 3 — 加速后端真实硬件验证

- [ ] 在目标 CUDA 硬件上完成构建、测试与演示
- [ ] 在目标 CANN 硬件上完成构建、测试与演示
- [ ] 记录可复现的正确性与性能结果

## Phase 4 — 工程化与性能

- [ ] 完整单元测试
- [ ] 性能基准
- [ ] 错误处理和文档
- [ ] CPU 优化或 BLAS 接入
- [ ] 评估单一加速后端

## Phase 5 — 比赛交付

- [ ] README、README.OpenSource、CHANGELOG
- [ ] 架构说明和项目提案
- [ ] 演示视频
- [ ] Benchmark 对比报告
- [ ] AI 使用及 AI 生态贡献说明
- [ ] 备用离线演示
