# liangzhu — Butterfly Lovers · Reverie

以中国五声音阶、越剧气质与化蝶意象创作的原创代码音乐项目。它不是《梁祝》
协奏曲的逐音复刻。

## 下载

当前完整版本：[`liangzhu-1.0.1`](https://github.com/ZeroMarker/music/releases/tag/liangzhu-1.0.1)

- [liangzhu.wav](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.0.1/liangzhu.wav) — SuperCollider 无损母版
- [liangzhu.mp3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.0.1/liangzhu.mp3) — SuperCollider MP3
- [liangzhu_strudel.mp3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.0.1/liangzhu_strudel.mp3) — Strudel 网页版 MP3

`1.0.0` 只包含 Strudel 资产；SuperCollider 语法问题已在 `1.0.1` 修复，
请使用 `1.0.1` 或更新版本。

## 编排

- 速度：72 BPM
- 调式材料：以 D 为中心的中国五声音阶
- Strudel：低音脉冲、丝弦拨奏与化蝶旋律
- SuperCollider：月琴、洞箫、二胡和低音声部的合成室内乐
- Csound：月琴（wgpluck2）、洞箫（呼吸长笛）、二胡（弓弦）与低音
- 正式渲染时长：128 秒，随后保留约 5 秒效果尾音

## Strudel

在仓库根目录运行 `npm ci`，打开 `strudel.html`，点击 **Play**。

命令行短时渲染：

```bash
MUSIC_PROJECT_DIR=liangzhu \
MUSIC_RECORD_PATH=liangzhu/liangzhu_strudel.webm \
MUSIC_RECORD_DURATION=8 \
npm run render:strudel
```

## SuperCollider

打开 `main.scd` 并整体运行。停止播放：

```supercollider
~stopLiangzhu.()
```

导出 WAV：

```bash
cd liangzhu
sclang export_wav.scd
```

默认输出 `liangzhu.wav`，时长 128 秒。可通过 `MUSIC_RECORD_PATH` 和
`MUSIC_RECORD_DURATION` 覆盖。

## Csound

`main.csd` 为单文件编排：音符表（MIDI）、调度器、四件乐器（月琴、洞箫、
二胡与低音）和混响母线。命令行渲染 WAV（需要 csound）：

```bash
cd liangzhu
csound -o liangzhu_csound.wav main.csd
```

默认时长 128 秒（文件内 `#ifndef DURATION` 提供默认值），也可用
`--smacro:DURATION` 覆盖。使用共享脚本更省心：

```bash
MUSIC_PROJECT_DIR=liangzhu MUSIC_RECORD_DURATION=8 \
MUSIC_RECORD_PATH=/tmp/liangzhu_test.wav \
bash scripts/render_csound.sh
```

## 发布

推送 `<项目>-<版本>` 标签会并行生成 Strudel MP3、SuperCollider WAV/MP3
与 Csound WAV/MP3，并上传至同一个 GitHub Release：

```bash
git tag -a liangzhu-1.0.2 -m "Liangzhu 1.0.2"
git push origin liangzhu-1.0.2
```

发布前可执行 `npm run check -- liangzhu`，并用短时渲染检查网页音频。
