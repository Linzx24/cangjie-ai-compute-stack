# Docker / Linux 仓颉环境

这个目录把仓颉 1.1.3 Linux x64 工具链装进 Ubuntu 22.04，并在容器内执行真实的 `cjpm build` 和 `cjpm test`。

## 为什么 SDK 不在 GitHub 仓库里

官方 Linux SDK 约 403 MB。它既不适合提交到 Git，也不应由本项目重新分发。请从[仓颉 1.1.3 官方下载中心](https://cangjie-lang.cn/download/1.1.3)下载：

```text
cangjie-sdk-linux-x64-1.1.3.tar.gz
```

可以在仓库根目录自动下载并校验：

```powershell
.\scripts\download-cangjie-linux-sdk.ps1
```

也可以手动把文件放到：

```text
docker/sdk/cangjie-sdk-linux-x64-1.1.3.tar.gz
```

该路径已加入 `.gitignore`，不会误传到 GitHub。

下载脚本和 Docker 验证脚本都会校验 SHA-256，校验失败的文件不会用于构建。

## 一键验证

先安装并启动 Docker Desktop，然后在仓库根目录运行：

```powershell
.\scripts\docker-verify.ps1
```

脚本会构建本地镜像，并把当前仓库挂载到 `/workspace`，最后验证 `examples/hello-cangjie` 的构建和测试。

## 当前限制

- 镜像只面向 x86_64 Linux SDK；
- 本地镜像包含官方 SDK，不应直接发布到公共镜像仓库；
- Windows 原生测试与 Docker/Linux 测试都通过后，才称为跨平台验证完成。
