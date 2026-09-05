# 项目实时进度

最后更新：2026-09-05

## 当前发布与仓库边界

- 本公共仓库是整个项目的总入口，也是 Cangjie Developer Skill 与 Benchmark 的唯一真源；机器学习仓不复制 Skill；
- 当前已安装的稳定版为 `v22`，本仓库主分支目录为 `v23.1` 候选版；
- v24 仅提供诊断性证据，原正式实验结论为 `INCONCLUSIVE`，未发生晋级或自动安装；
- 机器学习库 `v0.1.0-alpha.1` 位于私有协作仓 `Xi-shiqing/cangjie_machinelearning`；该仓尚无开源许可证，源码暂不能迁入本公共仓库。

## 公共 AI 工具链路线

```text
[完成] 1/6 准备仓颉开发环境
[完成] 2/6 建立学习前 Benchmark
[完成] 3/6 制作仓颉学习 Skill
[完成] 4/6 建立 Docker 统一环境
[完成] 5/6 制作编译诊断 Skill
[完成] 6/6 用面向机器学习的仓颉能力题验收
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
- Dockerfile、一键验证脚本和 Linux SDK 放置说明已完成；
- Docker 脚本语法和缺失环境诊断已验证。
- 官方 Cangjie 1.1.3 Linux x64 SDK 已自动下载到 Git 忽略目录，SHA-256 校验通过；
- SDK 自动下载与强制哈希校验脚本已完成。
- Docker Desktop 4.87.0 已安装，Docker CLI 29.7.2 可用；
- WSL 2.7.12 已安装，CPU 固件虚拟化与 SLAT 均已启用。
- Docker Desktop 重启后引擎正常，成功构建 `cangjie-ai-stack-dev:1.1.3`；
- Linux x86_64 容器内 `cjc`、`cjpm` 均为 1.1.3；
- Linux 容器内 hello 示例 1/1、仓颉语言能力套件 5/5 测试全部通过。
- Cangjie Doctor v0.1 已创建、安装并通过 Skill 格式校验；
- Doctor 对故障项目正确报告类型错误，对正常项目报告构建和测试均健康。
- Cangjie Developer Skill 已补充 Lambda、类与接口、集合、异常、并发和 C FFI 等知识路由；
- 独立语言能力验证套件已建立，Windows 真实构建成功，5/5 单元测试通过；
- Tensor 综合题仅作为 Skill 面向后续机器学习开发的能力考试，不作为框架实现。
- 已冻结并公开 v24 题面、starter、16 个公开测试和完整性校验工具；
- 已完成 v22 稳定版与 v23.1 候选版的诊断性 A/B；结果不具备正式晋级资格。

## 机器学习 alpha 验证

- 私有协作仓的 CPU core 已在 Cangjie 1.1.3 下构建成功，单元测试 `243/243` 通过；
- `model-demo` 已在同一环境构建成功；
- CUDA 与 CANN 后端尚未完成对应真实硬件验证。

## 下一验收点

- 为机器学习仓选择并附加明确的开源许可证，再决定源码公开迁移；
- 分别在真实 CUDA 与 CANN 硬件上完成可复现验证；
- 如需晋级 v23.1，使用修复后的基础设施和新的预注册 Benchmark 从头执行干净 A/B。
