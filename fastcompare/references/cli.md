# fastcompare.exe 使用手册

FastTool 系列 · 行级文本差分工具。单文件自包含 exe,免装运行时,拷到目标机即可用。

## 两种模式

| 两个参数都是 | 模式 |
|---|---|
| 文件 | 行级差分(下文"快速开始") |
| 目录 | 路径比较(见"路径比较"一节) |

## 快速开始(文件差分)

```bat
fastcompare.exe file1.txt file2.txt
```

输出 git diff 风格的行级差分:

```diff
--- file1.txt
+++ file2.txt
@@ -2,3 +2,3 @@
 line2
-line3
+CHANGED3
 line4
```

## 调用语法

```
fastcompare.exe <file1> <file2> [options]
```

| 选项 | 说明 |
|---|---|
| `-U <n>` / `--context <n>` | 每个变更块上下保留 n 行上下文,默认 3;`-U0` 只显示变更行 |
| `-q` / `--quiet` | 不打印差分,仅用退出码表示是否不同 |
| `-s` / `--stat` | 只打印增删行数汇总(目录模式打印文件计数) |
| `--content` | 仅目录模式:对两目录共有的文件做字节级比较,差异标 `~` |
| `--no-color` | 关闭 ANSI 彩色输出(重定向到文件时自动关闭) |
| `-h` / `--help` | 显示用法 |

## 退出码(自动化判定的核心)

| 退出码 | 含义 |
|---|---|
| 0 | 内容相同(行尾空白与换行风格差异不影响判定;换行风格不同时输出 Note 提示) |
| 1 | 内容不同 |
| 2 | 错误(参数不对 / 文件不存在 / 差分规模超限) |

## 输出格式

与 `git diff` 的 unified diff 一致:

- `--- ` / `+++ `:两个文件路径
- `@@ -起始行,行数 +起始行,行数 @@`:变更块(hunk)定位;行数为 1 时省略 `,1`,为 0 时形如 `-10,0`(纯插入)
- 行前缀:`+` 新增(绿)、`-` 删除(红)、空格 上下文
- 两个变更块之间间隔 ≤ 2×上下文行数时自动合并为一个 hunk(与 git 行为相同)

## 编码与换行处理

- 自动识别 BOM:UTF-8 / UTF-16 LE / UTF-16 BE
- 无 BOM 时先按严格 UTF-8 解码,失败则回退 GB18030(覆盖 GBK/GB2312)
- 文件前 8000 字节含 NUL 视为二进制,输出 `Binary files ... differ`,不做行差分

## 路径比较(目录模式)

```bat
fastcompare.exe dirA dirB [--content]
```

递归枚举两目录的全部文件,按相对路径(忽略大小写)比较:

```
--- dirA
+++ dirB
-onlyA/x.txt          只在 dirA
-sub/deep/n1.txt
~common_diff.txt      两边都有但字节不同(需 --content)
+onlyB/y.txt          只在 dirB
+sub/deep/n2.txt
```

- 退出码:0=文件集合相同(且 `--content` 下共有文件字节也相同),1=有差异,2=错误
- 枚举用 Win32 `FindFirstFileExW`(`FindExInfoBasic` + `FIND_FIRST_EX_LARGE_FETCH`)+ 显式栈递归,不走 `Directory.GetFiles` 的全数组物化;实测 2×2 万文件枚举 0.17s
- 符号链接/junction(reparse point)跳过,防止环;隐藏/系统文件包含在内
- 长路径(>260 字符)通过 `\\?\` 扩展路径前缀支持
- `--content` 的字节比较先比文件大小再分块比对,适合"两个目录树是否一致"的快速判定;需要看具体行差异时,对报出的 `~` 文件再单独跑文件差分模式

## 自动忽略的噪声差异

| 差异类型 | 行为 |
|---|---|
| 行尾空白:`"    \r\n"` vs `"\r\n"`、`"foo  "` vs `"foo"` | 静默忽略,不算变更(类似 git `--ignore-space-at-eol`);行首/行内空白仍参与比较 |
| 换行风格:CRLF vs LF | 不会表现为逐行变更;改为输出一行显式提示(见下);文件末尾有无换行同样不影响比较 |

换行风格提示示例(内容其余完全相同时,退出码仍为 0):

```
# Note: line endings differ: a.txt = CRLF, b.txt = LF
```

内容确有差异时,该提示插在 `---/+++` 头之后、hunk 之前。`-q` 模式下提示不输出,仅以退出码表达内容异同。风格统计按文件主导换行判定,文件内混用时报 `mixed`。

## 自动化 / AI agent 典型用法

```bat
:: 判定是否相同,只看退出码
fastcompare.exe -q config_old.txt config_new.txt && echo SAME || echo CHANGED

:: 机器可读的汇总
fastcompare.exe -s --no-color a.txt b.txt
:: 输出: 3 lines added, 1 lines removed

:: 抓取完整差分到文件
fastcompare.exe --no-color a.txt b.txt > output.diff
```

## 限制

- 单文件上限约 200 万行;两文件差异过大(编辑距离过高)时会以退出码 2 报 `files too dissimilar to diff`
- 不做空白忽略(无 `-w`)、不做文件改名检测;只比较传入的两个文件
- 性能参考:2 万行文件、少量变更,全量差分 < 0.2 s

## 版本

- v1.2.0 (2026-10-21):新增路径比较模式(目录 vs 目录),Win32 快速枚举,`--content` 字节级共有文件比较
- v1.1.0 (2026-10-20):行尾空白差异自动忽略;CRLF/LF 差异不进差分,改为显式 Note 提示
- v1.0.0 (2026-10-20):首次发布,行级 unified diff,git diff 兼容格式
