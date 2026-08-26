# Docker/Linux 验证记录

日期：2026-08-26

## 结论

仓颉开发环境和 Skill 语言能力套件已在 Docker 的 Linux x86_64 环境中完成真实编译与测试，
不再只依赖开发者本机的 Windows 工具链。本记录不代表正式机器学习框架已经实现。

## 环境与输入

- Docker Desktop：4.87.0
- Docker Engine / CLI：29.7.2
- WSL：2.7.12，WSL 2 后端
- 基础镜像：Ubuntu 22.04
- Cangjie：1.1.3，CJNative，`x86_64-unknown-linux-gnu`
- Linux SDK SHA-256：`2b68905afc466e665ae181595c63f96c18d75fd2c1fb6c6f0cb64e179c28d61a`
- 本地镜像：`cangjie-ai-stack-dev:1.1.3`

## 可复现命令

```powershell
.\scripts\docker-verify.ps1
```

脚本会先强制核对 SDK 哈希，再构建镜像，随后分别执行：

1. `/workspace/examples/hello-cangjie` 的 `cjpm build` 与 `cjpm test --no-color`；
2. `/workspace/ai-tooling/validation/language-suite` 的 `cjpm build` 与 `cjpm test --no-color`。

## 实测结果

```text
Cangjie Compiler: 1.1.3 (cjnative)
Target: x86_64-unknown-linux-gnu
Cangjie Project Manager: 1.1.3

hello-cangjie: TOTAL 1, PASSED 1, FAILED 0
language-suite: TOTAL 5, PASSED 5, FAILED 0
```

语言套件覆盖 Lambda/函数类型、struct 可变性、class/interface、泛型、`Option`/`match`、
数组、集合和异常处理。这些是 Skill 的编译器验证夹具，不是正式框架源码。
