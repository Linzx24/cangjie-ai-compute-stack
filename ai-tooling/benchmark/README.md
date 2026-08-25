# Cangjie Benchmark v0.1

这是一套用于比较 Codex 使用仓颉 Skill 前后能力变化的小型测试。

## 它怎么判分

每道题要求提交一个 `answer.cj`。判分器把答案与隐藏在题目目录中的单元测试放进临时项目，然后运行真实的 `cjpm test`。代码不能编译或测试失败，都不得分。

v0.1 有 5 道公开开发题，共 10 分：

| 题目 | 内容 | 分值 |
| --- | --- | ---: |
| 01-add | 基础函数 | 1 |
| 02-clamp | 条件判断 | 2 |
| 03-sum-array | 数组与循环 | 2 |
| 04-factorial | 递归和边界 | 2 |
| 05-dot-product | 机器学习常用点积 | 3 |

## 验证判分器

在仓库根目录执行：

```powershell
.\ai-tooling\benchmark\run-benchmark.ps1 -Mode Reference
```

标准答案应得到 10/10。这只能证明题目和判分器工作正常，不是 Codex 的基线成绩。

## 进行无 Skill 基线测试

1. 新建一个没有加载仓颉 Skill 的 Codex 任务；
2. 让它逐题阅读 `tasks/<题号>/prompt.md`；
3. 将答案保存为 `<提交目录>/<题号>/answer.cj`；
4. 执行：

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
