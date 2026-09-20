# Callme audit
- Notification ID: 6bb5608f-96d2-482d-b6b9-bae28d3aff6d
- Sender: NAS333 dispatch
- Local time: 2026-09-01T15:04:43.7015368+08:00
- UTC time: 2026-09-01T07:04:43.7015368Z
- Target thread: 01a05b99-8b5b-7022-a45c-4f7be4e15e4f

## Exact prompt

请针对你已认领的 NAS 任务设计并验证自己的问题猜想：可通过复刻问题，或重新编译后验证修复，形成一套可重复的调试工作流。

已知服务器版本为 1.5.5：

- 若要验证 OTA 升级前的行为问题，请使用：

```powershell
workspace\0_Codes\NASClient\build.ps1 -OverrideVersion '1.5.0'
```

- 若是基本功能验证，应规避 OTA 对软件测试的阻塞，请使用高版本编译：

```powershell
workspace\0_Codes\NASClient\build.ps1 -OverrideVersion '1.5.255'
```

工作流根目录（`workspace` 的上一级代号目录）目前没有流程设计，但可复用测试资源位于 `workspace\00_STATUS\debug_workflow`。

先设计工作流，并将设计以 Markdown 写入工作流根目录；再依据该工作流开展调试和验证。请在驾驶舱文档中记录关键证据、使用的版本和结果。
