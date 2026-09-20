---
name: fastwavcombine
description: "音频拼接工具(fastwavcombine.exe · self-contained 单文件 72MB,.NET,目标机免装运行时)。何时调用——★首要触发:把多段音频按顺序合并成一个 wav(如把多个 KWS 测试语音段拼成一条回归 wav、intro+body 拼完整音频)。①合并 2 个或更多 wav/音频文件;②离线测试语音组装;③需保证输出格式统一(以第一段为准自动重采样/声道转换,输出 16-bit PCM wav)。"
---

# fastwavcombine — 音频拼接

`fastwavcombine.exe` 把两段音频按顺序拼接成单个 wav(file2 自动重采样/声道转换对齐 file1,输出 16-bit PCM)。

## 何时调用
- **★首要触发**:多段音频合并成一个 wav(测试语音组装、片段拼接)。
- 需要输出格式统一:file2 自动对齐 file1 的采样率/声道。
- 输入支持 Windows 媒体框架可解码格式(wav/mp3/mp4 音轨等),输出统一 wav。

## 入口
```powershell
$FWC = 'C:\Users\PC\.codex\skills\fastwavcombine\fastwavcombine.exe'
Test-Path -LiteralPath $FWC  # 确认存在
```

## 命令格式
```powershell
& $FWC <file1.wav> <file2.wav> <output.wav>
```
- `file1`:第一段,**其采样率/声道决定输出格式**。
- `file2`:第二段,拼在 file1 之后(自动重采样到 file1 格式)。
- `output`:输出 wav(16-bit PCM)。

## 链式拼接(>2 段)
工具每次只拼 2 段,多段用链式(或两两合并减少中间产物):
```powershell
& $FWC seg1.wav seg2.wav t1.wav
& $FWC t1.wav   seg3.wav t2.wav
& $FWC t2.wav   seg4.wav final.wav
```

## 注意
- **AIA `--wav` 离线回放**:输出若用于 KWS/Deck 管线,确保 file1 为 **16kHz 单声道**(其余段会自动对齐)。
- **段间静音**:相邻段若会话需复位(如 Thanks 关闭后下一段 Hey 重新唤醒),自己生成一段 silence wav 插入链中:
  `ffmpeg -f lavfi -i anullsrc=r=16000:cl=mono -t 10 -c:a pcm_s16le silence.wav`
- self-contained 单文件 exe,目标机免装运行时;发布目录原则上只保留 exe + 本说明。

## 示例:4 段 TC 拼接(段间 10s 静音)
```powershell
& $FWC TC1.wav silence.wav t1.wav
& $FWC t1.wav  TC2A.wav    t2.wav
& $FWC t2.wav  silence.wav t3.wav
& $FWC t3.wav  TC2B.wav    t4.wav
& $FWC t4.wav  TC2C.wav    kws_test.wav
```
