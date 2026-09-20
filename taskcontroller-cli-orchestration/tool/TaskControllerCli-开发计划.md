# TaskControllerCli 开发任务清单

## 当前任务完成进度：73/78

## 使用说明

- 当前所有任务状态均为：未开始。
- 完成任务后将 `- [ ] 未开始` 改为 `- [x] 已完成`，进行中的任务改为 `- [ ] 进行中`。
- 写入数据的命令默认采用预览模式，只有明确实现并验证 `--write` 后才允许修改源文件。

## 控制舱对齐（2026-08-31）

- 北极星已登记为“完整 WinForms 到 CLI 转化”；本清单的 Phase 4、Phase 5 及最终验收均为必交付内容。
- 当前 CLI 已完成 54/78 项；仍需完成框架/部署决策、WinForms 等价基线、格式兼容策略及最终交付验收。
- 脱敏样例位于 `TaskControllerCli/samples/basic`；每次变更应运行 `build-cli.ps1` 及相应样例回归。

## Phase 0：范围确认与基线

- [x] 已完成：确认部署操作系统、运行时安装权限，以及 .NET Framework 4.8 / .NET 8 的目标要求。
- [x] 已完成：确认现有 `TaskControllerCli/TaskControllerCli.sln` 空 Console 宿主的保留策略。
- [x] 已完成：决定采用现有 .NET Framework 4.8 兼容 MVP，还是迁移为 SDK-style / .NET 8 项目。
- [x] 已完成：准备一份脱敏的样例数据目录，包含 `data.json`、`TaskRelyData.json`、`TaskBlocks.json`、`dict.txt` 和 `staff.txt`。
- [x] 已完成：记录 WinForms 版本在样例数据上的任务数量、状态分布、依赖关系和排程结果。
- [x] 已完成：盘点 JSON 字段、状态名称、分隔符、文件编码和默认文件名。
- [x] 已完成：确定 MVP 是否包含 Excel 导出；确定方程分析、图形导出和树编辑的后续优先级。
- [x] 已完成：形成兼容性清单、基线结果和框架决策记录。

## Phase 1：抽离领域核心

- [x] 已完成：建立 `TaskController.Core` 项目并加入解决方案。
- [x] 已完成：迁移 `TaskUnit`、`TaskNodeStatus`、`TreeNode<string>` 和依赖元素模型。
- [x] 已完成：移除核心模型对 WinForms、控制台、具体路径和进程启动 API 的引用。
- [x] 已完成：实现任务树遍历、叶节点查找、名称索引和父子引用重建。
- [x] 已完成：将名称规范化、输入/输出去重和关系对称化提取为领域服务。
- [x] 已完成：将 `ReconcileTaskRelationsAndStatuses` 改造成无 UI 副作用的状态协调服务。
- [x] 已完成：将自动排程算法提取为可注入策略，支持 clever 和 random 两种策略。
- [x] 已完成：为随机排程增加显式随机种子，保证测试可重复。
- [x] 已完成：实现任务名唯一性、空名称、非法数值和状态范围校验。
- [x] 已完成：实现自环、祖先/后代依赖和循环依赖检测，并返回完整路径。
- [x] 已完成：在 WinForms 中增加适配层，确保原项目仍可编译运行。
- [x] 已完成：完成核心库单元测试并与 WinForms 基线结果对比。

## Phase 2：文件与格式基础设施

- [x] 已完成：建立 `TaskController.Infrastructure` 项目并加入解决方案。
- [x] 已完成：实现 `--data-dir` 数据目录解析和默认文件查找。
- [x] 已完成：实现现有 `data.json` 的兼容读取，并保留 `Task_Unit` 字段命名。
- [x] 已完成：实现 `TaskRelyData.json`、`TaskBlocks.json` 的读取和写回。
- [x] 已完成：实现 DTO 与领域模型之间的转换，允许未来字段重命名。
- [x] 已完成：定义 `schemaVersion` 和未知字段处理策略。
- [x] 已完成：支持 UTF-8（含 BOM / 无 BOM），并确定旧本地编码的检测或 `--encoding` 选项。
- [x] 已完成：实现临时文件写入、原子替换和可选 `.bak` 备份。
- [x] 已完成：定义 CSV 列顺序、转义、编码和换行规范。
- [x] 已完成：迁移并验证 Excel/OpenXML 导出能力；若未纳入 MVP，记录延期项。
- [x] 已完成：完成 JSON、CSV、Excel 的读写往返和异常场景测试。

## Phase 3：CLI 外壳与 MVP 命令

- [x] 已完成：建立 `TaskController.Cli` 项目，并让现有 `TaskControllerCli` 宿主作为入口。
- [x] 已完成：实现命令解析、帮助信息、版本信息和全局选项。
- [x] 已完成：实现 `--data-dir`、`--format table|json`、`--no-color`、`--quiet`、`--yes`。
- [x] 已完成：实现 `status`，输出文件存在性、任务总数、状态统计和数据版本。
- [x] 已完成：实现 `validate` 和 `validate --strict`，输出文件、任务、字段级错误。
- [x] 已完成：实现 `task list`，支持按状态和执行人过滤。
- [x] 已完成：实现 `task show <name>`，输出完整任务属性和依赖关系。
- [x] 已完成：实现 `task set-status <name> <status>`，默认只预览变更。
- [x] 已完成：实现 `relation list` 和 `relation set`。
- [x] 已完成：实现 `reconcile`，区分默认预览与 `--write` 写回。
- [x] 已完成：实现 `plan --strategy clever|random`，支持执行人过滤、随机种子和 `--write`。
- [x] 已完成：实现 `export schedule --output <file.csv>`。
- [x] 已完成：实现 `export excel --output <file.xlsx>`，或明确记录为 Phase 4 任务。
- [x] 已完成：统一 stdout、stderr 输出边界，日志和进度不得污染 JSON stdout。
- [x] 已完成：实现稳定退出码：`0` 成功、`1` 参数错误、`2` 文件/格式错误、`3` 校验失败、`4` 业务冲突、`5` 写入/导出失败、`10` 内部错误。
- [x] 已完成：为每条 MVP 命令补充 table 和 JSON 输出示例。

## Phase 4：高级能力与兼容增强

- [x] 已完成：实现 `task tree add|rename|remove` 树结构维护命令。
- [x] 已完成：实现 `equation generate|paths` 方程、根信号、终点信号和路径分析。
- [x] 已完成：实现闭环、黑洞/白洞式终端和非法关系报告。
- [x] 已完成：实现 `visualize drawio|visio`，并隔离图形和外部程序依赖。
- [x] 已完成：实现 `dict list|add` 词典维护命令。
- [x] 已完成：实现 `staff list|add|remove` 执行人维护命令。
- [x] 已完成：实现批量导入/导出，并提供冲突处理策略。
- [x] 已完成：完善重复任务名、缺失依赖、未知状态和非法数值的 `--strict` 规则。
- [x] 已完成：评估稳定任务 ID，降低任务重命名对依赖关系的影响。
- [x] 已完成：确认 CLI 默认不启动外部 GUI 程序，不依赖桌面会话。

## Phase 5：测试、打包与交付

- [x] 已完成：补齐树操作、状态推导、依赖闭环、排程排序和工时计算单元测试。
- [x] 已完成：补齐中文、特殊字符、空文件、损坏 JSON、缺失文件等集成测试。
- [x] 已完成：补齐原子写入、备份恢复、覆盖确认和写入失败测试。
- [x] 已完成：补齐 CLI 参数、退出码、stdout/stderr 分流和 JSON 快照测试。
- [x] 已完成：使用黄金文件对比 WinForms 与 CLI 的状态、排程和导出结果。
- [ ] 未开始：在无 WinForms、无 Visual Studio 的干净环境中验证启动和 `--help`。
- [x] 已完成：确定 framework-dependent 或 self-contained 发布模式。
- [x] 已完成：提供 Windows PowerShell 启动脚本、版本信息和示例配置。
- [x] 已完成：在 CI 中执行 restore、build、test、publish 和发布包冒烟测试。
- [x] 已完成：确保构建产物输出到独立 `artifacts/`，不污染源码目录。
- [x] 已完成：编写 README、命令参考、数据格式说明和迁移说明。
- [x] 已完成：完成发布包、验收记录和版本标签。

## MVP 验收任务

- [x] 已完成：验证 `status --format json` 可被 PowerShell/CI 稳定解析。
- [x] 已完成：验证 `validate --strict` 能定位重复名称、缺失依赖、自环和完整环路，并返回退出码 `3`。
- [x] 已完成：验证 `reconcile` 默认不写文件，`reconcile --write` 通过校验后才原子写回并生成备份。
- [x] 已完成：验证相同输入、策略和随机种子下 `plan` 结果可重复。
- [x] 已完成：验证 `export schedule` 生成可被 Excel 和脚本读取的 UTF-8 CSV。
- [ ] 未开始：验证 CLI 在干净环境中可启动，并正确显示 `--help` 和 `--version`。

## 当前迭代建议

- [ ] 未开始：优先完成 Phase 0～3，先交付“只读查询、校验、状态协调预览和 CSV 排程导出”。
- [ ] 未开始：核心库稳定后再实现树编辑、方程分析、图形导出和 Excel 扩展。
- [ ] 未开始：每完成一个阶段，就更新本清单状态并提交对应 Git 变更。
