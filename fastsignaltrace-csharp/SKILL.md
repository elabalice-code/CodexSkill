---
name: fastsignaltrace-csharp
description: 使用内置单文件 CLI 扫描 C# 源码树中的类型级字段，标记 Producer、Consumer、Producer+Consumer、Unused，并从 if/else/switch 控制域生成标准信号方程。适用于 C# 项目的信号地图建立、字段生产消费审计、fork 同名文件区分、自动化回归和 AI agent 快速静态验证；不要用于 GDScript、Rust、TypeScript、属性或函数局部变量分析。
---

# FastSignalTrace CSharp

使用 skill 自带的 `assets/fastsignaltrace-csharp.exe` 1.2.0。不要依赖源码工程、系统 .NET 或外部 DLL。

## 执行流程

1. 确认输入根目录是单一 C# 工程或用户明确要求的统一扫描范围。一次验证不要混入其他 Harness。
2. 优先同时指定方程文件和变量 TSV，避免把成百上千条方程直接灌入对话。
3. 运行封装脚本：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" `
  -SourceRoot "D:\Work\Project" `
  -EquationOutput "D:\Work\result\equations.txt" `
  -VariablesOutput "D:\Work\result\variables.tsv" `
  -Detailed
```

4. 检查退出码，再读取统计和少量样例。退出码 0 才表示扫描成功；3 表示没有 `.cs` 文件，不要把它描述为空结果成功。
5. 验证每条方程满足 `<域名>:<输入+输入>=<输出>`，并确认所有输入/输出都存在于 TSV 的 `Signal` 列。
6. 报告文件数、字段数、方程数、语法错误、输出路径和静态分析边界。不要仅凭数量宣称语义准确率。

## 语义约束

- 信号是类型级 `IFieldSymbol`，包括私有/公有、静态/实例字段；排除参数、局部变量和属性。
- 角色方向按字段读取为 Producer、字段写入为 Consumer；两者兼具为中间商。
- 方程输入包括赋值右侧字段和控制条件字段；无真实输入时不伪造方程。
- 域名使用相对路径和起始行，路径分隔符、空格和点转换为下划线。
- 更完整的命令、格式和限制只在需要时读取 `references/使用手册.md`。

## 退出码

- `0`：成功，包括成功但没有方程。
- `2`：参数错误或根目录不存在。
- `3`：没有可分析的 `.cs` 文件。
- `4`：分析异常。
