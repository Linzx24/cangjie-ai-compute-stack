# 仓颉 1.1.3 Windows 环境

本项目当前固定使用 Cangjie 1.1.3，避免不同编译器版本导致代码行为不一致。

## 安装

1. 从[仓颉官方下载中心](https://cangjie-lang.cn/download/1.1.3)下载 `cangjie-sdk-windows-x64-1.1.3.zip`。
2. 核对文件 SHA-256：

   ```text
   8bb65499c1b30271eaca422568bc9537677bd25debd8f5208e780a22c917da72
   ```

3. 解压 ZIP，例如解压到 `D:\tools\cangjie-1.1.3`。
4. 在 PowerShell 中载入环境：

   ```powershell
   . D:\tools\cangjie-1.1.3\cangjie\envsetup.ps1
   ```

5. 在仓库根目录运行检查：

   ```powershell
   .\scripts\check-cangjie.ps1 -RunSmokeTest
   ```

如果已经永久设置了 `CANGJIE_HOME` 和 `Path`，第 4 步可以省略。官方提醒 Windows 工具链的部分能力少于 Linux 版本，因此比赛发布前还会增加 Linux 验证，但不影响当前学习和 CPU 原型开发。

## 成功标准

看到以下四项成功，就说明环境可用：

- `cjc` 显示 1.1.3；
- `cjpm` 显示 1.1.3；
- 示例输出 `1 + 2 = 3`；
- 单元测试全部通过。
