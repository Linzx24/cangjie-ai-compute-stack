# Cangjie Benchmark v0.3

这是一套用于比较 Codex 使用仓颉 Skill 前后能力变化的小型测试。

## 它怎么判分

每道题要求提交一个 `answer.cj`。判分器把答案与隐藏在题目目录中的单元测试放进临时项目，然后运行真实的 `cjpm test`。代码不能编译或测试失败，都不得分。

v0.3 保留基础题和仓颉特性题，并增加一个完整二维 Tensor 综合题，共 45 分：

| 题目 | 内容 | 分值 |
| --- | --- | ---: |
| 01-add | 基础函数 | 1 |
| 02-clamp | 条件判断 | 2 |
| 03-sum-array | 数组与循环 | 2 |
| 04-factorial | 递归和边界 | 2 |
| 05-dot-product | 机器学习常用点积 | 3 |
| 06-safe-divide | Option 错误处理 | 3 |
| 07-relu-array | 数组构造与 ReLU | 4 |
| 08-matrix-vector | 矩阵向量乘法 | 5 |
| 09-generic-swap | 泛型与元组 | 3 |
| 10-mut-struct | 修复可变结构体 | 5 |
| 11-tensor-2d | 二维 Tensor 综合实现 | 15 |

## 验证判分器

在仓库根目录执行：

```powershell
.\ai-tooling\benchmark\run-benchmark.ps1 -Mode Reference
```

标准答案应得到 45/45。这只能证明题目和判分器工作正常，不是 Codex 的基线成绩。

无 Skill 基线结果：

- [v0.1：10/10](results/baseline-2026-08-26.md)
- [v0.2：30/30](results/baseline-v0.2-2026-08-26.md)
- [v0.3：45/45](results/baseline-v0.3-2026-08-26.md)

当前 Codex 在隔离、无 Skill、无联网条件下仍通过了 Tensor 综合题。因此 Skill 后评测除通过率外，还必须记录开发流程、编译尝试次数和诊断质量，避免制造虚假的分数提升。

## 进行无 Skill 基线测试

1. 生成不包含测试和答案的隔离考试目录：

   ```powershell
   .\ai-tooling\benchmark\prepare-exam.ps1 -OutputPath <考试目录>
   ```

2. 新建一个没有加载仓颉 Skill 的 Codex 任务，并发送 [BASELINE_TASK_PROMPT.md](BASELINE_TASK_PROMPT.md) 中的提示词；
3. 将隔离考试目录的绝对路径一并告诉它；
4. 等它完成后执行：

   ```powershell
   .\ai-tooling\benchmark\run-benchmark.ps1 `
       -Mode Submission `
       -SubmissionPath <提交目录> `
       -ReportPath .\ai-tooling\benchmark\results\baseline.md
   ```

公开题用于开发和纠错，不能作为最终比赛证明。最终版应由队友保留一组不进入公开仓库的隐藏题。

## 设计依据

- [OpenAI Evals](https://developers.openai.com/api/reference/resources/evals)：评测由固定数据和明确的测试标准组成；
- [仓颉项目管理工具](https://cj-docs.gitcode.com/zh/1.1.3/tools/source_zh_cn/cmd-tools/cjpm_manual.html)：使用 `cjpm test` 编译并运行仓颉单元测试。
