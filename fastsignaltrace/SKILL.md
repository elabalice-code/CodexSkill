---
name: fastsignaltrace
description: FastSignalTrace 系列的唯一顶层入口。自动盘点源码扩展名和工程标记，选择 C#、Godot/GDScript、Rust+Tauri 、普通 C/C++ 或 C-UEFI 子 skill，扫描语言状态与专用承担者的生产者消费者角色并生成标准信号方程；扫描完成后必须调用 EqualAnalyzer 展开完整 PATH，按终端层、信号汇集层和信号编织层检查架构与命名，并将信号地图写入 00_STATUS/Extra_SignalMap.md。适用于用户要求分析源码信号地图、生产消费关系、变量读写、UEFI Protocol/PPI/PCD/HOB/Event 或调用 FastSignalTrace，但没有明确指定语言版本的场景；遇到真正的多语言范围歧义时停止并要求缩小根目录，不静默混扫。
---

# FastSignalTrace

始终从本 skill 进入。让 `scripts/invoke.ps1` 自动检测项目语言，再调用同级的内部子 skill：

- C#：`fastsignaltrace-csharp`
- Godot/GDScript：`fastsignaltrace-godot`
- Rust、TypeScript/TSX、Tauri：`fastsignaltrace-rusttauri`
- EDK2/PI/UEFI C：`fastsignaltrace-uefi`
- Linux/Android（LA）及普通 C/C++：`fastsignaltrace-lacpp`，包含结构体函数指针和完整信号消费链；可用 `-Language Lacpp` 显式选择。调用者/被调用者查询另用 `source-insight-cli`。

## 标准流程

1. 选择用户明确指定的单个源码根目录。一次测试只使用一个 Harness，不把多个实战工程放在同一根目录扫描。
2. 默认使用 `-Language Auto`。只有用户明确要求覆盖自动判定时才指定具体语言。
3. 优先把方程和变量表写入文件：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" `
  -SourceRoot "D:\Work\Project" `
  -EquationOutput "D:\Work\result\equations.txt" `
  -VariablesOutput "D:\Work\result\variables.tsv" `
  -Detailed
```

4. 从标准错误读取检测摘要，例如 `SelectedLanguage=CSharp` 以及各扩展名计数。
5. 退出码为 0 后，验证方程格式和 TSV 信号闭包，再汇报统计、输出路径和对应语言的静态分析边界。
6. 需要语言级语义时读取被选中子 skill 的 `SKILL.md`；需要完整 CLI 手册时再读取其 `references/使用手册.md`。

## 扫描完成后的复杂信号业务门禁（强制）

把“方程已生成”视为中间产物。只要本次任务面向复杂信号业务，必须在 FastSignalTrace 子脚本成功后执行以下后处理；不能只交付 `equations.txt` 或 `variables.tsv`：

1. **先做 PATH 分析**：调用 `$equalanalyzer`（单独使用其 `scripts/invoke.ps1`），输入本次生成的单个方程文件，同时生成文本报告和 `equation-graph.json`。完整流程必须保留有效/非法方程、依赖边、循环、Paths 数量，并按 EqualAnalyzer 规则展开用户关注信号的每一条上下游路径。
2. **按三层归类**：
   - **终端层（Endpoint）**：UI、IO、Executor、持久化适配器等生产终端和消费终端；终端可以分发原始意图，也可以只消费状态用于显示或执行。
   - **信号汇集层（Model/View bus）**：类似匝道总线/颈部的集中转运层，所有终端信号都必须公平经过这里；使用 `MODELVIEW_` 前缀。
   - **信号编织层（Signal brain）**：状态机、决策、编排和反馈的核心；使用 `SIGNAL_` 前缀。
   目标路径形态应能解释为：`ORIGIN_* → MODELVIEW_* → SIGNAL_* → MODELVIEW_* → ORIGIN_*`。单向路径可缺少反馈段，但不得绕开汇集层直达编织层或终端；所有例外都列为 bypass 风险。
3. **执行三层 PATH 审计**：将每条 Root→End 或 Loop 压缩路径映射到三层，报告缺失层、跨层直连、终端到终端短接、跨层回环和无法归类的节点。EqualAnalyzer 的环路报告是候选线索，不得擅自判定为死锁。
4. **执行命名审计**：按 `层级 + 业务范围 + 功能名 + 信号名` 检查所有方程信号和 TSV 变量：
   - 终端层信号统一为 `ORIGIN_<业务范围>_<功能>_<信号>`；
   - 汇集层统一为 `MODELVIEW_<业务范围>_<功能>_<信号>`；
   - 编织层统一为 `SIGNAL_<业务范围>_<功能>_<信号>`。
   前缀不符合、层级与生产/消费角色矛盾、业务/功能字段缺失都要列出。终端生产者和终端消费者都属于终端层；前缀表达所有权层，Producer/Consumer 方向以方程和 TSV 为准。
5. **重命名必须两阶段**：发现不规范名称时先生成 TSV/Markdown 重命名表（至少 `old_name`、`new_name`、`layer`、`business_scope`、`feature`、`reason`、`status`），向用户确认后才可执行。不得直接批量替换。执行统一脚本时必须按 `old_name` 字符串长度从长到短排序；脚本应使用转义后的最长匹配、预览模式和显式 `-Apply` 门槛，防止部分字符串替换失控。
6. **落盘到驾驶舱**：从 `SourceRoot` 开始检查 `00_STATUS`；不存在时在项目根创建，或向上查找最近的同名驾驶舱，禁止写入其他工程的状态目录。可先执行 `scripts/ensure-signal-cockpit.ps1 -SourceRoot <root>`，它只在缺失时创建目录和 `Extra_SignalMap.md`，不会覆盖已有地图。将本次信号地图写入 `<StatusRoot>\Extra_SignalMap.md`，地图至少包含：扫描元数据、三层定义、Source/Sink、关注路径组（左右信号）、层级审计、命名审计/重命名表、循环与 bypass 风险、静态分析盲区和后续行动。
7. **最终汇报必须分层**：先给 EqualAnalyzer PATH 统计，再给三层映射和违规项，随后给 Source（可靠性分析入口）与 Sink（改动影响域入口），最后给驾驶舱文件链接。若 EqualAnalyzer、命名审计或驾驶舱落盘失败，整体结果标记为未完成，不得声称“信号方案已闭环”。

安全重命名脚本：`scripts/apply-signal-renames.ps1`。默认只预览；只有用户确认重命名表后才传入 `-Apply`。详细字段和地图章节见 `references/复杂信号业务分析.md`。

## 信号消费行为审计（强制）

在 EqualAnalyzer PATH 分析之后、写入 `Extra_SignalMap.md` 之前，运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/audit-signal-consumption.ps1" `
  -SourceRoot "D:\Work\Project" `
  -EquationFile "D:\Work\result\equations.txt" `
  -VariablesFile "D:\Work\result\variables.tsv" `
  -SignalOnly `
  -OutputFile "D:\Work\result\signal-consumption-audit.txt" `
  -JsonFile "D:\Work\result\signal-consumption-audit.json"
```

该脚本以多语言保守词法规则识别 `&&`、`||`、`!`、`and`、`or`、`not` 及其括号组合，覆盖 C#、GDScript、Rust、TypeScript/JavaScript、Python、Java/Kotlin、Go、C/C++ 和 SQL 常见文件扩展名，并对每条结果标记绝对文件路径、行号、上下文、操作符和信号名。提供 `variables.tsv` 时，`-SignalOnly` 只输出涉及已知信号的表达式；不加该开关仍会把全量表达式保留到 JSON。字符串和注释会尽量屏蔽；结果是静态审计线索，仍需结合语言子 skill 复核。

消费约束：

- 消费点（条件判断、`return`、调用实参、分发/执行入口）不得现场执行布尔组合；出现上述操作符时标记为违规候选。
- 布尔运算必须在消费前提前完成，并写入含义明确、符合三层前缀的信号变量，再由消费点读取该变量。
- 赋值行中的布尔运算仅视为“预计算候选”，必须检查左值是否是描述能力清晰的 `ORIGIN_`、`MODELVIEW_` 或 `SIGNAL_` 信号，不能用临时变量掩盖业务含义。

双缓冲约束：

- 在 `Tick`、`Update`、`_process`、`_physics_process` 等帧函数内，同一状态/信号既被读取又被写入时，报告为潜在单缓冲污染和计算顺序依赖。
- 设计必须提供 `current/next`、`read/write`、snapshot 或等价双缓冲：一个 Tick 只读快照，计算结果写入下一缓冲，Tick 末尾统一提交/交换。
- 审计结果必须记录文件、Tick 函数、信号、读取行和写入行；无法证明双缓冲时不能标记为通过。

将布尔审计条目和双缓冲风险原样写入 `Extra_SignalMap.md` 的 `Consumption audit`、`Double-buffer audit` 或等价章节；没有发现也要写明扫描范围和“未检测到（启发式）”，不能省略。

## 自动选择规则

- `.sln/.csproj` 强化 C# 判定。
- `project.godot` 强化 Godot 判定。
- `Cargo.toml`、`package.json`、`src-tauri`、`tauri.conf.json/json5` 强化 Rust+Tauri 判定。
- `.dsc/.dec/.inf/.fdf`、EDK2 包目录和 `Uefi.h/PiPei.h` 强化 C-UEFI 判定；仅有 `.c/.h` 不足以把普通 C 路由为 UEFI。
- UEFI 固件树内常包含辅助 C#、Rust 或第三方源码；明确的 UEFI 元数据拥有工程根路由优先权。若同时发现 Godot 或 Tauri 强标记，仍按歧义处理。
- 如果只有一种受支持源码扩展名，直接选择对应子 skill。
- `project.godot` 对常见的 Godot+C# 混合工程拥有 Godot 路由优先权。Godot 与 Cargo/Tauri 同时出现，或独立 C# 与 Cargo/Tauri 同时出现时返回退出码 5；没有强标记时再按源码扩展名评分。歧义时不调用任何分析器。
- 普通 `.c/.h/.cc/.cpp/.cxx/.hh/.hpp/.hxx` 路由为 Lacpp；明确 UEFI 元数据继续优先选择 Uefi。没有任何支持源码时返回退出码 3。

## 退出码

- `0`：子 skill 扫描成功。
- `2`：参数或根目录错误。
- `3`：没有受支持源码，或强制语言与源码不匹配。
- `4`：检测或子分析器异常。
- `5`：语言/工程范围歧义，需要缩小根目录或显式指定语言。

不要把不同语言子 skill 的信号结果自动拼成跨语言调用图。Rust+Tauri 子 skill 虽统一扫描后端与前端，但当前不自动连接 Tauri `invoke` 和 Rust command。
