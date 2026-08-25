# 项目路线图

## Phase 0 — 立项与环境

- [ ] 确定项目正式名称和对外介绍
- [x] 固定 STS Cangjie 1.1.3 环境
- [x] 验证 `cjc`、`cjpm`、构建和测试命令
- [x] 提交 Docker/Linux 可复现环境配置
- [x] 安装 Docker Desktop 与 WSL 2
- [ ] 在安装 Docker 后完成 Linux 运行验证
- [ ] 完成比赛规则与现有项目查重
- [ ] 确定两人分工和每周验收标准

## Phase 1 — 仓颉开发能力

- [x] 建立第一个仓颉可编译示例
- [x] 建立无 Skill 基线 Benchmark v0.1
- [x] 扩展 Benchmark v0.3，增加 Option、泛型、诊断和 Tensor 综合题
- [x] 发布 Cangjie Developer Skill v0.1
- [x] 建立 Cangjie Doctor 初版
- [x] 对比使用 Skill 前后的成绩

## Phase 2 — CjTensor 最小原型

- [x] Tensor 数据与 shape
- [x] add、mul、sum、matmul
- [x] 最小动态计算图
- [x] `y = x * x + x` 自动微分验证
- [x] 数值梯度检查

## Phase 3 — 神经网络闭环

- [ ] Module 与 Parameter
- [ ] Linear、ReLU、Sequential
- [ ] 损失函数
- [ ] SGD
- [ ] XOR 训练
- [ ] MNIST 训练

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
