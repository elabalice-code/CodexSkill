---
name: fastsignaltrace-uefi
description: 使用内置单文件 CLI 扫描 EDK2/PI/UEFI 的 C 源码，把 Protocol、PPI、PCD、HOB、Event/Notify、Runtime Variable、UEFI Service、协议实例方法和相连的 C 状态生成标准信号方程与角色 TSV。适用于固件信号地图、生产消费审计和 UEFI 跨模块承担者追踪；不要用于普通 C 或 C++ 项目。
---

# FastSignalTrace UEFI

使用 Skill 自带的 `assets/fastsignaltrace-uefi.exe` 1.0.0。它是 C-UEFI 专用分析器，不依赖源码工程可编译，也不把普通 C/C++ 当作 UEFI 猜测处理。

## 执行

1. 输入单个 EDK2/PI/UEFI 源码根目录；默认从顶层 `$fastsignaltrace` 自动路由。
2. 方程和变量表必须同时落盘，避免把大型固件树的结果直接写入对话：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" `
  -SourceRoot "D:\Firmware\PlatformPkg" `
  -EquationOutput "D:\Result\equations.txt" `
  -VariablesOutput "D:\Result\variables.tsv" `
  -Detailed
```

3. 退出码为 0 后，验证每条方程满足 `<域>:<输入+输入>=<输出>`，且全部信号存在于 TSV。
4. 汇报 `.c/.h` 文件数、各类 UEFI 信号、方程数、结构警告、输出路径和静态边界。

## 语义

- Protocol/PPI 的安装是写入，定位/打开是读取；已定位实例的 `->Method` 关联回对应 GUID。
- PCD Get/Set、GUID HOB Build/Get、Runtime Variable Get/Set分别形成稳定的 Token/GUID/名称信号。
- Event Group/句柄与 Notify 回调形成显式派发关系；环只作为事件反馈线索。
- 未归入专用规则的 gBS/gRT/gDS/PEI 调用保留为 `UEFI.Service.*`。
- 角色方向沿用 FastSignalTrace：读取是 Producer，写入是 Consumer。
- 详细命令、Scope 表和边界仅在需要时读取 `references/使用手册.md`。

## 退出码

- `0`：成功，包括没有形成方程。
- `2`：参数错误或根目录不存在。
- `3`：没有 `.c/.h` 文件。
- `4`：分析异常。
