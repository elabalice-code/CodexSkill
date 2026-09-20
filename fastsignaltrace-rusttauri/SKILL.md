---
name: fastsignaltrace-rusttauri
description: 使用内置单文件 CLI 联合扫描 Rust 后端和 Tauri TypeScript/TSX 前端，发现 static/const/struct 字段、模块/类状态和 Zustand 泛型状态字段，标记生产消费角色并生成 if/match/switch 标准方程。适用于 Rust+Tauri 项目信号地图、状态读写审计和 AI agent 自动化验证；不要用于 C#、GDScript、React hook 局部状态或完整跨语言调用链推断。
---

# FastSignalTrace Rust+Tauri

使用 skill 自带的 `assets/fastsignaltrace-rusttauri.exe` 1.0.0。它同时扫描 `.rs`、`.ts`、`.tsx`，默认排除 `target`、`node_modules`、`dist` 等生成目录。

## 执行流程

1. 确认输入是一个 Rust+Tauri 工程根目录，不要与其他 Harness 混扫。
2. 同时输出方程和变量 TSV：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" `
  -SourceRoot "D:\Work\TauriProject" `
  -EquationOutput "D:\Work\result\equations.txt" `
  -VariablesOutput "D:\Work\result\variables.tsv" `
  -Detailed
```

3. 退出码为 0 后，分别报告 Rust 与 TS/TSX 文件数、Rust/TypeScript 状态数、控制域和方程数。
4. 验证方程格式，确认所有方程信号存在于 TSV，并抽样回到相对路径和行号。
5. 明确说明当前输出没有把前端 `invoke` 自动连接到 Rust `#[tauri::command]`；不要把统一列表误称为完整跨语言调用图。

## 语义约束

- Rust：模块/关联 `static`、`static mut`、`const` 和具名 `struct` 字段；排除参数、`let` 和函数内局部 `const`。
- TypeScript/TSX：模块变量、具体类字段、Zustand `create<State>` 数据字段；排除函数型 action、普通函数和 React hook 局部变量。
- Rust 控制域为 `if/match`，TypeScript 为 `if/switch`；支持块、多行条件和常见单行结构。
- 宏展开、复杂类型推断、别名、动态键、复杂跨行 setter 和跨函数传播采用保守策略。
- 需要详细语言边界和格式时读取 `references/使用手册.md`。

## 退出码

- `0`：成功。
- `2`：参数或路径错误。
- `3`：没有 `.rs/.ts/.tsx` 文件。
- `4`：分析异常。
