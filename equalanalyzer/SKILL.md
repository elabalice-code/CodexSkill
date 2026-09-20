---
name: equalanalyzer
description: 解析 FastSignalTrace 标准方程文件，打印 Root/End 信号 Trace PATH，将闭环自动压缩为 Loop(...) 节点，报告循环，并执行 IO 角色反查。适用于用户要求分析方程组、生成信号链路、追踪信号或方程上下游、检查黑洞/白洞式终端环节点、检测循环/死锁线索，或用 variables.tsv 复核 Producer/Consumer 标签的场景。输入应是单个标准方程文件；只有源码目录而没有方程时，先调用 fastsignaltrace 生成方程。
---

# EqualAnalyzer

使用内置的 Windows x64 单文件程序解析一份方程清单。不要修改用户方程，不要把多个工程的方程静默合并。

## 标准流程

1. 确认输入是单个 UTF-8 方程文件，行格式为 `Name:Input.A+Input.B=Output.C`。
2. 调用脚本。默认启用严格模式，PATH 自动打印，不需要 PATH 开关：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" `
  -EquationFile "D:\Work\equations.txt" `
  -OutputFile "D:\Work\equation-report.txt" `
  -JsonFile "D:\Work\equation-graph.json"
```

3. 检查退出码，并汇报有效/非法方程、依赖边、循环和 Signal paths 数量。
4. 从报告 `[Paths]` 原样引用关键路径。`Loop(A|B)` 表示闭环已节点化；没有 Root 或 End 的路径边界是有意省略，不补写占位词。
5. 需要完整 CLI、协议和 JSON 字段时读取 `references/使用手册.md`。

## IO 标签反查

用户提供 FastSignalTrace 变量 TSV 或要求检查生产/消费标签时执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" `
  -EquationFile "D:\Work\equations.txt" `
  -VariablesFile "D:\Work\variables.tsv" `
  -IoAnalysis `
  -OutputFile "D:\Work\io-report.txt"
```

按工具契约解释结果：方程左侧要求 `Producer`，右侧要求 `Consumer`，两侧均出现要求 `Producer+Consumer`。`CompatibleSuperset` 不是错误；重点报告 `Mismatch`、`MissingDeclaration` 和歧义声明。

## 定向追踪

按信号或方程组查询时二选一：

```powershell
...\invoke.ps1 -EquationFile equations.txt -TraceSignal "Type.Signal"
...\invoke.ps1 -EquationFile equations.txt -TraceEquation "File_cs_120"
```

即使执行定向查询，完整 PATH 和循环报告仍会生成。

## 退出码

- `0`：成功。
- `2`：参数或文件路径错误。
- `3`：严格模式发现非法方程或没有有效方程。
- `4`：未处理异常。
- `5`：定向追踪目标不存在。

内置程序版本为 1.2.0。资产 SHA-256：`CEB0C20FB43D0C3608952DF4F3A40CD71F4CC878732D47B96B5274F3F1E9F92B`。
