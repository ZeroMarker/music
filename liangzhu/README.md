# liangzhu — Butterfly Lovers · Reverie

以中国五声音阶、越剧气质与化蝶意象创作的原创代码音乐项目。它不是《梁祝》
协奏曲的逐音复刻。

## 下载

当前完整版本：[`liangzhu-1.2.0`](https://github.com/ZeroMarker/music/releases/tag/liangzhu-1.2.0)

- [liangzhu.wav](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu.wav) — SuperCollider 无损母版
- [liangzhu.mp3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu.mp3) — SuperCollider MP3
- [liangzhu_strudel.mp3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu_strudel.mp3) — Strudel 网页版 MP3
- [liangzhu_csound.wav](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu_csound.wav) — Csound 无损版
- [liangzhu_csound.mp3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu_csound.mp3) — Csound MP3
- [liangzhu_fluidsynth.mp3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu_fluidsynth.mp3) — MIDI + FluidSynth MP3

`1.2.0` 新增 MIDI + FluidSynth 采样版本，并细化乐句力度（小节重音、乐句末尾减弱）。

`1.1.0` 重做编曲，统一三套引擎的有限乐谱，并修正声像、包络和拨弦泛音力度。

`1.0.0` 只包含 Strudel 资产；SuperCollider 语法问题已在 `1.0.1` 修复，
请使用 `1.0.1` 或更新版本。

## 编排

- 速度：72 BPM
- 调式材料：以 D 为中心的中国五声音阶
- Strudel：低音、拨弦、洞箫应答与二胡旋律，使用本地合成音色
- SuperCollider：月琴、洞箫、二胡和低音声部的合成室内乐
- Csound：月琴（wgpluck2）、洞箫（呼吸长笛）、二胡（弓弦）与低音
- 结构：引子 → 洞箫应答 → 二胡主题 → 留白 → 展开 → 回归 → 主音收束
- 最后一个 D 主音和弦在 120 秒进入，乐谱在 123.33 秒结束
- 正式渲染时长：128 秒，包含尾音；SuperCollider 导出另保留 4 秒

四个引擎的音符、力度、起始时间和音长都从
`../scripts/rebuild_scores.mjs` 生成。修改后在根目录执行
`npm run rebuild:music`，再执行 `npm run check`。网页音色是合成近似，
并非真实乐器采样。

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
git tag -a liangzhu-1.2.0 -m "Liangzhu 1.1.0"
git push origin liangzhu-1.2.0
```

发布前可执行 `npm run check -- liangzhu`，并用短时渲染检查网页音频。
