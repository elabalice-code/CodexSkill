---
name: fastdeai
description: "去 AI 格式化噪声工具(fastdeai.ps1 + fastdeai.exe)。从 Markdown 文档中去除 AI 风格的装饰性格式(表情、引用、强调、行内代码、粗斜体等),同时保护 fenced 代码块原样保留。单文件处理 + 批量目录模式。"
---

# fastdeai — 去 AI 格式化噪声

> 从 Markdown 文档中剥离 AI 风格装饰性格式（表情符号、引用块、分割线、强调标记、行内代码、粗体/斜体、标题修饰等），保护 fenced 代码块原样保留，输出聚焦内容本身。
>
> 载体: `$HOME\.codex\skills\fastdeai\fastdeai.ps1` + 自包含 `fastdeai.exe`（.NET 9 单文件，无运行时依赖）

## 何时用

- **输出需要做二次编辑/人工审阅**：AI 生成的 Markdown 带大量装饰格式（表情、引用、分割线），人眼阅读或复制粘贴前需要清理
- **跨平台粘贴**：去掉 AI 表情和格式，内容更干净地贴合目标平台
- **批量处理文档**：整个目录的 Markdown 文件一键去格式化
- **对接 CI/自动化流程**：下游工具需要纯干净内容

> 不适用：保留格式的最终发布文档、需要 AI 风格美观的成品。

## 前置：定位入口

```powershell
# 固定路径
$FASTDEAI = "$env:USERPROFILE\.codex\skills\fastdeai\fastdeai.ps1"
Test-Path -LiteralPath $FASTDEAI
```

**PowerShell 调用约定**（与 fastsearch 一致）：

```powershell
# 定义一次函数，后续像 CLI 一样用
$FASTDEAI = "$env:USERPROFILE\.codex\skills\fastdeai\fastdeai.ps1"
function fastdeai { powershell.exe -NoProfile -ExecutionPolicy Bypass -File $FASTDEAI @args }
```

## 用法

```bash
# 单文件（直接覆盖写入输出，原名 + _out.md）
fastdeai input.md

# 单文件指定输出路径
fastdeai input.md output.md

# 批量处理目录下所有 .md（跳过已生成的 _out.md）
fastdeai -Batch D:\path\to\docs

# 批量递归子目录
fastdeai -Batch D:\path\to\docs -Recurse
```

## 已知行为

- **输出文件命名**: 单文件模式下，未指定输出路径时，在输入文件同目录生成 `{原文件名}_out.md`
- **缓存跳过**: 批量模式自动跳过 `*_out.md` 文件（不重复处理已生成的输出）
- **代码块保护**: fenced 代码块（```` ``` ```` 或 `~~~`）内容完全保留，不清理内部格式
- **非破坏性**: 源文件不被修改，输出始终是新文件
- **原地修 titles**: 标题标记 `# `、`## ` 等前的空格额外处理

## 典型工作流

```powershell
# 1. 定义入口
$FASTDEAI = "$env:USERPROFILE\.codex\skills\fastdeai\fastdeai.ps1"
function fastdeai { powershell.exe -NoProfile -ExecutionPolicy Bypass -File $FASTDEAI @args }

# 2. 清理单个文档
fastdeai D:\Project\docs\output.md

# 3. 批量清理整个文档目录
fastdeai -Batch D:\Project\docs -Recurse
```
