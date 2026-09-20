---
name: fastsearch
description: "布尔逻辑 CLI 搜索工具(fastsearch.ps1 · PowerShell 版,免编译 exe)。何时调用——★首要触发:在大型文件夹/项目里大海捞针,急需确认几个初步锚点(即使只有一个关键词也行),优先用 fastsearch 而不是 grep/rg。①摸清陌生项目/目录全貌;②在大量日志里取证(事件时间线、计数、上下文);③定位代码符号/调用点;④需要 &|! 布尔组合精确命中或排除时更是首选。核心心法:词元/词根/词缀拆分(别拼长串)+ 按行 AND + 三步法(先 *.* 列文件 → 布尔锁定 → -s N 取上下文)。含完整用法、选项、运算符、转义、已验证语义坑(按行AND/词间不能空格/子串默认命中/连续转义合并)、.fschk 验算法、recipe 库、乱码诊断、大文件处理。载体为 PowerShell 脚本(内嵌 C# 即时编译),需 Windows PowerShell,免预编译 exe。"
---

# fastsearch — 布尔逻辑 CLI 搜索

> 跨项目 CLI 搜索工具。在大量文件/日志/代码里用 `& | ! ()` 布尔逻辑定位关键词,支持上下文扫描。流式搜索,可处理 GB 级单文件。
> 实战提炼(AIGC-APO 日志取证 + 代码定位),持续维护。

> **载体**:`$HOME\.codex\skills\fastsearch\fastsearch.ps1` —— PowerShell 脚本内嵌全部 C# 源(`Add-Type` 运行时即时编译),**免预编译 exe、纯文本可维护**;语义与旧 `fastsearch.exe` **完全一致**(同一份 C#,所有语义坑逐条继承);额外**默认 UTF-8 输出**,中文重定向不再乱码(§8)。调用约定见 §1。

## 何时用

- **★ 大海捞针 + 急需锚点(首要触发)**:在大型文件夹/项目里翻资料,对一个陌生或复杂的目录结构没概念、急需几个初步线索来建立方向感 → **优先用 fastsearch**(哪怕只搜一个词也行)。它比 grep/rg 更快给你"文件分布"的概貌。
- **摸清陌生项目**:`*.*` 速览目录全貌 → 按后缀锁定功能范围。
- **日志取证**:抽事件时间线、计数、上下文(如 KWS 触发时机、异常堆栈、请求链路)。
- **代码定位**:找符号/调用点/配置,尤其驼峰命名拆词元组合。
- **布尔精确定位**(`&|!`):关键词散落在海量文件里山堆噪声 → 用 AND/OR/NOT 精确过滤比 grep 单关键词叠管道干净得多(这是 fastsearch 的拿手好戏但不是唯一用法)。

> 不适用:已知单个文件/行号直接读 → 用 Read;只是读干净内容/计数/`-o` 提取 → 用 Grep(ripgrep)。fastsearch 强项是**快速定位 + 布尔组合过滤 + 上下文**,定位后交给 Grep/Read 取干净内容。

## 0. 心法(一句话)

**先 `*.*` 列文件速览 → 词元拆分布尔锁定 → `-s N` 取上下文。命中率来自拆词元(词根/词缀/驼峰),不来自长串。**

## 1. 前置:定位入口 + 调用约定

入口是 PowerShell 脚本(优先,固定位置);旧 `fastsearch.exe` 散落各项目时仍可作 fallback,但**以 ps1 为权威**。

```powershell
# 优先:skill 自带的 ps1(固定路径)
$FAST = "$env:USERPROFILE\.codex\skills\fastsearch\fastsearch.ps1"
Test-Path -LiteralPath $FAST

# 兼容:某项目仍带旧 exe(非权威,行为同质)
Get-ChildItem -Recurse -Filter fastsearch.exe -ErrorAction SilentlyContinue | Select-Object -First 5
```

**PowerShell 调用约定**:

```powershell
# 方式一(推荐):定义一次函数,后续像 CLI 一样用
$FAST = "$env:USERPROFILE\.codex\skills\fastsearch\fastsearch.ps1"
function fastsearch { powershell.exe -NoProfile -ExecutionPolicy Bypass -File $FAST @args }
fastsearch '*.*'
fastsearch '*.log' 'Keyword1&Keyword2' -s 3

# 方式二:每次写全(不想定义函数时)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\fastsearch\fastsearch.ps1" '*.log' 'A&B'
```

> 下文所有示例一律用 `fastsearch ...` 简写(假定已按方式一定义函数;或自行脑补 `powershell.exe -File "$FAST"` 前缀)。
> 无参数运行 `fastsearch` 可显示官方 usage(权威,以它为准)。
> **扩展点**:设 `FS_NO_UTF8=1` 关闭 UTF-8 输出(回到 exe 的控制台代码页行为);设 `FS_ECHO=1` 在 stderr 回显参数(调试用)。详见 ps1 末尾 EXTENSION POINT。
> **WSL 注意**:若从 WSL 调用,fastsearch 实际在 Windows PowerShell 侧跑,搜索范围是 Windows 文件系统。传 `--root` 需给**Windows 路径**(如 `D:\path`)或先用 `wslpath -w` 转义 Linux 路径。

## 2. 完整用法

```
fastsearch "<file-pattern>"                                     # 只列文件名(项目速览)
fastsearch "<file-pattern>" "<expression>" [search-root] [options]
```

| 选项 | 作用 |
|---|---|
| `-s, --scope <N>` | 匹配行**上下各 N 行**(默认 0=只显示匹配行)← 定位后取上下文 |
| `--root, -r <路径>` | 显式搜索根 |
| `--exclude-dir, -x <名>` | 跳过目录(可重复) |
| `--case-sensitive` | 区分大小写(默认**不区分**) |

**表达式运算符**:`&` AND · `|` OR · `!` NOT · `()` 分组
**转义字面特殊字符**:`\& \| \! \( \)`(搜字面 `&&` 等时用)
**默认跳过目录**:`bin, obj, .git, .vs`

```
fastsearch "*.log" "Keyword1&(Keyword2|Keyword3)"
fastsearch "*.log" "Keyword1&(Keyword2|Keyword3)" --root "D:\Test"
fastsearch "*.cs" "TODO" --root "D:\Work" --exclude-dir packages
```

## 3. 三步心法(展开)

1. **`*.*` 速览全貌**:`fastsearch "*.*"` 只列文件名,快速摸清结构(单参数模式=只列名)。
2. **按后缀锁定范围**:对感兴趣的后缀搜(`*.cs` / `*.log` / `*.ts`),快速定位功能区。
3. **关键词 + 布尔锁定**:用 `&|!` 过滤/排除;**对词元、词根、词缀检索大幅提升命中率**(驼峰命名法最典型——`HDMIIngestCamera` 差,拆成 `HDMI&Camera`)。
4. **`-s N` 取上下文**:位置明确后设 scope 扫上下文,常能意外关联到其他关键判断条件。
  - `-s 3` 适合快速确认:看相邻 3 行是否在同一个方法/条件块里
  - **`-s 10` 适合常量/状态变量影响面分析**:看 10 行能覆盖注释块、if-guard 链、方法签名、相邻变量赋值、以及整个调用站点

## 4. ⚠️ 已验证语义坑(取证前必读)

> 实测沉淀,绕过这些会误判命中/漏命中。ps1 与 exe 同一份 C#,以下行为逐条一致。

**WSL/跨环境调用:**
0. **`wslpath -w` 必填**:powershell.exe 在 Windows 侧跑,看不到 WSL 的 `/root/...` 路径 — 传给 `--File` 前必须先 `wslpath -w` 转成 `\\wsl.localhost\...` UNC 路径。
0a. **`--%` stop-parsing marker 必填**:不带 `--%` 时,Windows PowerShell 会把参数里的 `& | ! ()` 当成自己的运算符先解析掉,快到达 fastsearch 时已是空壳 → **报 parse error**。加了 `--%` 后面的参数才原样透传。
0b. **搜索范围是 Windows 文件系统**:不加 `--root` 时默认搜 Windows 当前目录(对应 WSL cwd)。传 `--root` 要给 Windows 路径(如 `D:\path`)或先用 `wslpath -w` 转 Linux 路径。直接传 `/mnt/d/...` 会报 "does not exist"。

**表达式解析:**
1. **匹配是"按行"的**:`&` 要求所有词在**同一行**。跨行的两词用 `&` 命不中 → 改用 `-s N` 拉上下文,或分次查。
2. **默认子串 + 不区分大小写**:`web` 命中 `WebSearch`;要精确加 `--case-sensitive`。
3. **词间不能有空格**:`"Web Video"` → **报错 `missing operator between two terms`**(不是静默当关键词!)。要 AND 必须**显式 `&`**(`Web&Video`);**无短语/空格算子**,多词各自用 `&`。
4. **空格也是被识别对象**:关键词不可随意带空格(空格会被当词元分隔/报错)。
5. **转义实测**(搜字面 `&&` 等):`\&`=字面 `&`、`\&\&`=字面 `&&`——**连续转义会合并成一个词条**(不报 missing operator,与"空格分词"相反);未转义 `&&` 报 `operator '&' is missing left operand`。同理 `\|`、`\!`、`\(`、`\)`。
6. **无参数运行**=显示 usage(权威帮助)。

## 5. .fschk 验算法(降低成本)

不确定表达式行为时,**先在小文件上验证再上真实项目**:

1. 建一个含已知关键词的小文件,后缀 `.fschk`(如 `test.fschk`,内容随意混入想测的词)。
2. `fastsearch "*.fschk" "<expr>" --root <scratch目录>` 确认命中/排除符合预期。
3. 验过再上真实(可能 GB 级)项目,省时省 token。

> 实测:`Recv&Web`、`Web&(!Video)`、`(web|video)&(!operations)` 全部符合预期。

## 6. recipe 库(实战沉淀)

```powershell
# 定义入口函数(每会话一次,或写进 ~/.bashrc)
$FAST = "$env:USERPROFILE\.codex\skills\fastsearch\fastsearch.ps1"
function fastsearch { powershell.exe -NoProfile -ExecutionPolicy Bypass -File $FAST @args }

# —— 摸结构 ——
fastsearch '*.*'                                       # 全目录文件名速览
fastsearch '*.cs'                                      # 某后缀文件清单

# —— 代码定位(驼峰拆词元)——
fastsearch "*.cs" "WebSearch&Cancel" -s 3
fastsearch "*.cs" "(response&cancel)|(function_call_output)" -s 3
fastsearch "*.cs" "Recv&Web" -s 3                      # 命名嗅觉(Recv 命中 RecvWeb)
fastsearch "*.cs" "HDMI&Camera&(!USB)"                 # 精确排除 USB Camera

# —— 常量影响面分析(推荐 -s 10)——
# 追一个常量(如 30000/60000)的完整上下文时, -s 3 经常不够看清调用链:
# -s 10 能覆盖:if-guard、注释块、相邻变量赋值、方法签名
fastsearch "*.cs" "ForceClearAfterMs" --root <repo> -s 10  # 声明 + 条件判断 + 归属方法
fastsearch "*.cs" "30000" --root <repo> -s 5              # 全常量分类后 -s 5 取判定上下文
fastsearch "*.cs" "_latestResponseCompletedUtcTicks" -s 5 # 状态变量生命周期:SET/READ/CLEAR

# —— 日志取证 ——
# 按行 AND 的正面用例:同行必含两字段,精确命中、零误扰
fastsearch "*.log" "user_question&taskType" --root <logs_dir>          # 提问时间线(时戳+taskType+文本)
# KWS 唤醒/结束关键词触发时机
fastsearch "*.log" "(hey|hello|thanks)&nova&keyword_monitor" --root <logs_dir>
# FAIL 嗅探
fastsearch "*.log" "response_pending_lock|enqueue_user_text" --root <logs> -s 2
# 异常/取消
fastsearch "*.log" "OperationCanceledException|TaskCanceledException" --root <logs> -s 2
```

**输出格式**(便于解析):
- 每个匹配行前缀:`>> <绝对路径>(<行号>): <行内容>`
- 文件之间用 `  ---` 分隔
- 末尾统计:`Scanned files: N / Matched files: M / Matched lines: K / Unreadable files: 0`

**计数**(fastsearch 无 `--count`):重定向到文件后用 `wc -l`,或用 Grep 工具计数:
```bash
fastsearch "*.log" "<expr>" --root <logs> > _out.txt 2>/dev/null
wc -l _out.txt
```

## 7. 大文件处理

- **流式搜索,可处理 GB 级单文件**(实测 1GB TestActor 日志可搜,耗时数十秒~几分钟)。
- **输出可能巨大**(海量匹配行)→ **务必重定向到文件**,再用 Grep/Read 提取,别直接打到终端。
- **按行 AND + `-o` 提取**配合:fastsearch 定位时刻/行号 → Grep `-o` 抽干净字段(如时戳、`key=value`)。
- **首次运行编译开销**:ps1 用 `Add-Type` 首次即时编译 C#(~1s,同进程只一次),之后纯执行;对 GB 级搜索可忽略。

## 8. 乱码诊断(中文日志/终端)

> ps1 **默认 UTF-8 输出**(相对旧 exe 的改进):命中行重定向到文件后,用 **Grep 工具 / Read 工具** 直读即干净,**不再受 git bash 终端 GBK 渲染困扰**。仍需注意源头编码:

1. **fastsearch 命中本身正确**;若仍见乱码,先排查源头文件编码(见下),而非工具。
2. **`file --mime-encoding <log>`** 先定编码:
   - `utf-8` → 用 Grep/Read 直读(如 `AIAssistant_*.log` / `TestActor_*.log`)。
   - `us-ascii` 且中文已是字面 `?` → **落盘即丢、不可恢复**,换源文件(如某些 `stdout_*.log`)。
   - 其它(GBK/iso-8859-1 等) → fastsearch 内部 `EncodeGit` 会探测(BOM/UTF-8 字节序/否则按 GB18030)并正确解码,命中与输出均正常;`file` 标 `iso-8859-1` 是其识别局限,不代表读错。
3. **`-s N` 看上下文**判断"系统性 vs 特例":相邻中文行**都** `?`、纯 ASCII 行干净 → 系统性(整份该编码);仅个别行乱 → 特例,可绕过。
4. **要回到 exe 旧行为**(按控制台代码页输出,如需对接 GBK 下游):设 `FS_NO_UTF8=1`。

## 9. 与其它工具分工

| 场景 | 工具 |
|---|---|
| 大海捞针 + 急需锚点(单关键词也行) | **fastsearch**(本 skill) → 定位后交 Grep/Read |
| 布尔逻辑(&\|!)精确定位 + 上下文 | **fastsearch**(本 skill) |
| 读干净内容 / `-o` 提取字段 / 计数 | Grep(ripgrep,UTF-8 安全) |
| 读特定行/整个文件 | Read |

> 典型流水线:**fastsearch 布尔锁定行号/时刻 → Grep `-o` 抽取字段流 → Read 取完整上下文**。

## 10. 维护笔记(给维护者)

> **🔐 授权(重要)**:用户(ElabAlice)于 2026-06-22 明确授权——**任何 Claude Code agent 都可按需直接维护本脚本**(`fastsearch.ps1` 及配套 `SKILL.md`),无需逐次向用户确认。这是对"工作区边界/只读 skill"惯例**针对本 skill 的显式放宽**;遇到不方便处(编码、提示、新选项等)可自行迭代,改完跑一遍 §4/§5 验证即可。

- **载体决策**:旧 `fastsearch.exe`(.NET Framework 预编译,写死 exe)**不适合维护** → 改为 `fastsearch.ps1` 内嵌 C# 源(`Add-Type` 即时编译)。C# 源 = `0_FastTool/4_FastSearch/workspace/FastSearch/fastsearch/*.cs` 的 6 文件合并(仅 `Program`/`Main` 改 public 供 PS 调用)。
- **C# 版本坑**:Windows PowerShell 5.1 的 `Add-Type` 走 legacy CodeDom,**只支持到 C# 5**——C# 6 的 `=>` 表达式体方法、`nameof()` 会被拒。ps1 里这两处已回退为经典语法(见注释)。改 C# 时勿引入 C# 6+ 语法。
- **.NET Core/PS7**:ps1 顶部已 `RegisterProvider(CodePagesEncodingProvider)`,GB18030 可用;PS 5.1 默认就有,catch 忽略。
- **扩展点**:Encoding/echo 等完善一律加在 ps1 末尾 `=== EXTENSION POINT ===`,不动 C# 主体。
