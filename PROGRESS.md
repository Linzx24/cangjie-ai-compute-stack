# 项目实时进度

最后更新：2026-08-26

```text
[完成] 1/6 准备仓颉开发环境
[完成] 2/6 建立学习前 Benchmark
[完成] 3/6 制作仓颉学习 Skill
[进行] 4/6 建立 Docker 统一环境
[等待] 5/6 制作编译诊断 Skill
[等待] 6/6 用机器学习代码验收
```

## 已完成

- Cangjie 1.1.3 Windows 工具链验证；
- `cjc`、`cjpm`、构建和单元测试闭环；
- 第一个可编译仓颉示例；
- Benchmark v0.1 的 5 道题和自动判分框架；
- 标准答案 10/10、错误初始答案 0/10 的双向验证；
- 独立 Codex 无 Skill 基线考试：10/10。
- Benchmark v0.2 无 Skill 基线：30/30；
- Benchmark v0.3 Tensor 综合基线：45/45。
- Cangjie Developer Skill v0.1 已创建、校验并安装到本机 Codex；
- 使用 Skill 的独立隔离复测：45/45，11 道隐藏测试全部通过。

## 当前正在做

- 建立可复现的 Docker/Linux 仓颉 1.1.3 环境；
- 验证同一示例在 Windows 与 Linux 两套工具链中通过。

## 下一验收点

Docker 镜像完成构建并执行 `cjpm build`、`cjpm test`；如果本机没有 Docker，则先完成仓库配置并继续不依赖 Docker 的工作。
