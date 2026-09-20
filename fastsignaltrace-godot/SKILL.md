---
name: fastsignaltrace-godot
description: 使用内置单文件 CLI 扫描 Godot/GDScript 源码树中的脚本和嵌套类成员，标记生产者/消费者角色，并从 if/elif/else/match 缩进控制域生成标准信号方程。适用于 Godot 项目信号地图、脚本成员读写审计、控制依赖梳理和 AI agent 自动化验证；不要用于 C#、Rust、TypeScript、运行时节点实例或函数局部变量分析。
---

# FastSignalTrace Godot

使用 skill 自带的 `assets/fastsignaltrace-godot.exe` 1.0.0。工具为 Windows x64 自包含单文件，不要求安装 Godot 或 .NET。

## 执行流程

1. 确认根目录属于一个 Godot/GDScript 工程。一次验证只扫描用户指定的一个 Harness。
2. 为方程和变量 TSV 指定独立输出路径：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" `
  -SourceRoot "D:\Work\GodotProject" `
  -EquationOutput "D:\Work\result\equations.txt" `
  -VariablesOutput "D:\Work\result\variables.tsv" `
  -Detailed
```

3. 退出码为 0 后，检查方程语法、TSV 信号闭包和少量可回源的路径+行号样例。
4. 汇报 `.gd` 文件数、脚本成员数、方程数、结构警告和输出路径；把结果称为保守静态摘要，不称为运行时轨迹。
5. 退出码 3 表示没有 `.gd` 文件，应明确报告语言不匹配且不产生伪结果。

## 语义约束

- 扫描 `var`、`const`、`static var`、`@export var`、`@onready var` 等脚本/类成员。
- 排除 `func` 与属性 `set/get` 体内局部变量和参数。
- 普通赋值为写，复合赋值与已知集合变更方法为读+写。
- `if/elif/else` 和 `match` 通过缩进确定控制域；嵌套控制域独立命名。
- 动态属性、字符串 `get/set`、反射、运行时脚本加载和完整跨函数传播不保证还原。
- 需要完整选项和样例时读取 `references/使用手册.md`。

## 退出码

- `0`：成功。
- `2`：参数或路径错误。
- `3`：没有可分析的 `.gd` 文件。
- `4`：分析异常。
