# Cangjie Benchmark 报告

- 模式：Submission
- 仓颉版本：1.1.3
- 总成绩：45/45
- 执行方式：全新隔离 Codex 任务；加载 Cangjie Developer Skill；不联网；不访问测试或标准答案
- Codex 任务：`01a03a18-979c-7231-a4f9-75fc22de3acd`
- 用时：156687 ms
- 实际读取：`SKILL.md`、`references/language-pitfalls.md`、`references/ai-compute-patterns.md`

| 题目 | 类别 | 结果 | 得分 |
| --- | --- | --- | ---: |
| 01-add | basic | 通过 | 1/1 |
| 02-clamp | control-flow | 通过 | 2/2 |
| 03-sum-array | collections | 通过 | 2/2 |
| 04-factorial | functions | 通过 | 2/2 |
| 05-dot-product | ml-foundation | 通过 | 3/3 |
| 06-safe-divide | option | 通过 | 3/3 |
| 07-relu-array | tensor-op | 通过 | 4/4 |
| 08-matrix-vector | tensor-op | 通过 | 5/5 |
| 09-generic-swap | generic | 通过 | 3/3 |
| 10-mut-struct | compile-fix | 通过 | 5/5 |
| 11-tensor-2d | ml-capstone | 通过 | 15/15 |

## 与无 Skill 基线比较

| 模式 | 得分 | 用时 | 结论 |
| --- | ---: | ---: | --- |
| 无 Skill | 45/45 | 134594 ms | 已具备较强的仓颉基础编码能力 |
| 使用 Skill | 45/45 | 156687 ms | 分数持平；按题型选择资料，并留下明确的工作流证据 |

单次用时受任务调度和推理过程影响，不能据此声称 Skill 提升或降低速度。当前证据支持的价值是开发流程一致性，而不是虚构的分数提升。
