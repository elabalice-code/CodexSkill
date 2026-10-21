---
name: fastcompare
description: 使用随附的 fastcompare.exe 在 Windows 上比较两个文本文件或两个目录树。适用于行级 unified diff、增删统计、目录路径差异和共有文件字节比较；比较两个代码目录时，先做内置路径对比，再识别结构相似且芯片或业务命名不同的对应代码，逐一比较并保存 diff 文件。文件模式自动忽略行尾空白及换行风格差异。
---

# FastCompare

使用本 skill 目录下的 `bin/fastcompare.exe`（v1.2.0，Windows x64 单文件自包含，无需安装 .NET）。根据实际 skill 安装位置解析路径，不依赖当前工作目录或 PATH。

## 调用

在 PowerShell 中设置工具路径；以下路径适用于默认安装位置，若 skill 位于其他目录则替换为实际路径：

```powershell
$fastcompareExe = Join-Path $env:USERPROFILE '.codex/skills/fastcompare/bin/fastcompare.exe'
& $fastcompareExe --no-color 'D:/input/old.txt' 'D:/input/new.txt'
$compareExit = $LASTEXITCODE
```

两个参数必须同为文件或同为目录。第一个是旧版/左侧，第二个是新版/右侧。工具只读输入；保存报告时写到用户指定或任务输出目录。

按需求选模式：

| 需求 | 参数示例 |
|---|---|
| 文件行级差分，默认上下文 3 行 | `--no-color old.txt new.txt` |
| 只显示变更行 | `--no-color -U0 old.txt new.txt` |
| 增删行数统计 | `--no-color --stat old.txt new.txt` |
| 仅判断是否不同 | `--quiet old.txt new.txt` |
| 比较目录中的相对文件路径集合 | `--no-color dirA dirB` |
| 同时比较共有文件的字节内容 | `--no-color --content dirA dirB` |
| 目录差异计数 | `--no-color --stat --content dirA dirB` |

目录输出 `-` 表示仅左侧存在、`+` 表示仅右侧存在、`~` 表示共有文件字节不同（仅 `--content`）。需要查看 `~` 文件的行级差异时，再对对应文件单独调用文件模式。用户要求确认目录内容一致时使用 `--content`，默认目录模式只比较文件路径。

## 两个代码路径的对比流程

用户要求使用本 skill 对比两个目录路径时，按以下流程执行：

1. 先运行内置路径对比：`& $fastcompareExe --no-color $leftPath $rightPath`，快速获取相对文件路径的差异，并将输出保存为 `paths.diff`。这一步只判断路径集合，后续还需比较代码内容。
2. 观察两边的目录层级、模块组织、文件命名及代表性代码，判断结构是否有明确相似性，特别是结构对应、仅芯片或业务名称发生变化的情况。工具不会自动检测改名，需要 Agent 根据这些证据建立对应关系。
3. 对相同相对路径的代码文件，以及结构相似时具有相同前缀或后缀的候选代码文件，建立一一对应关系，再逐对调用文件模式：`& $fastcompareExe --no-color $leftFile $rightFile`。例如 `chipA_audio.c` 与 `chipB_audio.c`，或 `audio_chipA.c` 与 `audio_chipB.c`。结合所在模块、扩展名和代码职责确认配对；仅有通用前缀或后缀不足以证明对应关系，多候选且无法确认时记录为待确认。结构缺乏明确相似性时，仍比较能确认对应的文件，并记录未匹配项。
4. 将逐对文件模式的原始 unified diff 汇集为 `code.diff`，保留原始文件路径、名称和实际代码差异；不要先替换芯片或业务名称来消除差异。用 `#` 注释记录配对依据、无差异的文件对、仅单侧存在或待确认的文件，以及比较错误或未完成项。最终交付 `paths.diff` 和 `code.diff`，不能只提供路径清单、统计或文字结论。

上述 diff 文件使用无颜色的 UTF-8 文本，写入用户指定或任务输出目录，并放在两个输入目录之外，避免报告文件进入本次比较。每次调用后立即保存退出码，按下文规则区分差异和错误；文件模式保留换行提示等影响结论的信息。

## 结果判读

立即保存 `$LASTEXITCODE`：`0` = 所选模式下相同，`1` = 有差异（正常比较结果），`2` = 错误。不要用简单的成功/失败二分法把差异和执行错误混在一起；错误时检查 stderr 并报告原因。

- 文件模式自动忽略行尾空白、CRLF/LF 及末尾换行差异；行首与行内空白仍参与比较。换行风格不同时通常输出 `# Note: line endings differ: ...`，内容其余相同仍返回 0。`--quiet` 隐藏该提示。
- 目录 `--content` 按字节比较，不应用上述文本归一化。目录路径比较忽略大小写，包含隐藏/系统文件，跳过符号链接和 junction，不报告空目录差异。
- 不把文件模式的“相同”解读为字节完全一致。文件模式面向文本，二进制输入可能只输出 `Binary files ... differ`，不能据此提供可靠的二进制字节相等判定。
- 对机器可读报告使用 `--no-color`。汇报实际比较范围、差异摘要和输出位置；保留影响结论的换行提示或跳过链接说明。

完整参数、编码规则、输出示例和规模限制见 [references/cli.md](references/cli.md)，需要这些细节时再读取。也可运行 `& $fastcompareExe --help`。
