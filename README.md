# Cangjie Codex Skill

面向仓颉编程语言的 Codex 开发能力、编译诊断工作流与可重复 Benchmark。

## 项目目标

本项目用于解决三个问题：

1. 让 Codex 基于仓颉官方文档和真实编译结果学习仓颉 1.1.3。
2. 建立可重复运行的 Benchmark，衡量使用 Skill 前后的代码生成与修复能力。
3. 沉淀可供其他开发者复用的仓颉开发与诊断 Skill。

## 计划交付

```text
skills/
├── cangjie-developer/   # 仓颉开发基础 Skill
└── cangjie-doctor/      # 编译、测试与错误诊断 Skill

benchmark/
├── practice/            # 公开练习集
├── development/         # Skill 调试集
├── holdout/             # 独立测试集
├── runner/              # 自动编译和测试
└── scoring/             # 自动评分

reports/                 # 无 Skill / 不同 Skill 版本的对比报告
```

## 第一阶段

- 固定 STS Cangjie 1.1.3 开发环境。
- 建立 10 个最小可编译示例。
- 建立 10 道初始 Benchmark。
- 记录无 Skill 的基线成绩。
- 发布 `cangjie-developer` v0.1。
- 比较使用 Skill 前后的编译成功率、测试通过率和修复成功率。

## 与 CjTensor 的关系

本仓库不是机器学习框架本身，而是 CjTensor 项目的开发基础设施：

```text
Cangjie Developer Skill
        ↓
Cangjie Benchmark
        ↓
Cangjie Doctor
        ↓
CjTensor 机器学习框架
```

## 当前状态

项目初始化中。所有仓颉代码必须以官方文档为依据，并通过真实的 `cjc` / `cjpm` 编译和测试后才能计为有效样例。

## 许可证

Apache License 2.0。
