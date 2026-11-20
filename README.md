# music — Code to Music

用代码生成音乐的项目。两首已发布作品共用四套渲染方案，并可在 GitHub Actions
上自动生成音频产物。《D 大调卡农》另有 Tone.js、Sonic Pi、Python DSP 和
music21 乐谱导出。卡农也可用录制的钢琴和弦乐样本渲染，见[卡农使用说明](canon/README.md#recorded-instruments)。

- **Strudel**：浏览器端音乐编程环境（Web Audio），适合网页播放与快速原型。
- **SuperCollider**：原生音频平台，适合高质量合成、复杂配器和 WAV 母版。
- **Csound**：经典音频语言，单文件 orchestra + score，纯命令行非实时渲染。
- **MIDI + FluidSynth**：共享乐谱导出标准 MIDI，用 General MIDI SoundFont 离线渲染乐器采样。

从自然语言到乐谱、MIDI 与音频的流程，以及引擎选型和 90 BPM 原型规格，见
[Code → Music 方案对比](CODE_TO_MUSIC_COMPARISON.md)。

## 目录结构

```text
.
├── canon/                        # 《D 大调卡农》项目
│   ├── strudel.html              # Strudel 网页播放器（Pattern 乐谱）
│   ├── main.scd                  # SuperCollider 编排（SynthDef + Pattern）
│   ├── export_wav.scd            # SuperCollider 命令行 WAV 导出入口
│   ├── main.csd                  # Csound 编排（orchestra + 调度器 + score）
│   ├── score.mid                 # 标准 MIDI 乐谱（供 FluidSynth 与 DAW 使用）
│   ├── score.json                # Tone.js / Python 共用的乐谱事件
│   ├── sonic_pi.rb               # Sonic Pi 实时演奏
│   ├── render_python.py          # NumPy 离线合成 WAV
│   ├── render_samples.py         # 用实录乐器样本渲染 WAV
│   ├── export_music21.py         # 从 MIDI 导出 MusicXML
│   ├── requirements.txt          # 卡农 Python 工具依赖
│   ├── project.json              # 项目名称、速度和渲染时长
│   └── README.md                 # canon 使用说明
├── liangzhu/                     # 《化蝶清梦》原创五声音阶项目
│   ├── project.json              # 项目名称、速度和渲染时长
│   ├── strudel.html              # Strudel 网页播放器
│   ├── main.scd                  # SuperCollider 室内乐编排
│   ├── export_wav.scd            # WAV 导出入口
│   ├── main.csd                  # Csound 编排
│   ├── score.mid                 # 标准 MIDI 乐谱
│   └── README.md                 # liangzhu 使用说明
├── scripts/
│   ├── render_strudel.mjs        # 共享 Puppeteer 无头录制脚本（WebM）
│   ├── render_tone.mjs           # 卡农 Tone.js 离线渲染（WAV）
│   ├── render_sonic_pi.py        # 卡农 Sonic Pi 无头录制（WAV）
│   ├── check_audio.sh           # 校验音频峰值并拦截静音
│   ├── render_csound.sh          # 共享 Csound 命令行渲染脚本（WAV）
│   ├── render_fluidsynth.sh      # 共享 FluidSynth 命令行渲染脚本（WAV）
│   ├── rebuild_scores.mjs        # 共享有限乐谱，生成四套引擎的乐谱
│   ├── midi.mjs                  # 无依赖的标准 MIDI 文件写入器
│   └── validate_projects.mjs     # 自动发现并校验项目结构与配置
├── .github/workflows/
│   ├── strudel.yml               # CI：Strudel → MP3（按标签解析项目）
│   ├── render.yml                # CI：SuperCollider → WAV + MP3（按标签解析项目）
│   ├── csound.yml                # CI：Csound → WAV + MP3（按标签解析项目）
│   ├── fluidsynth.yml            # CI：MIDI + FluidSynth → WAV + MP3（按标签解析项目）
│   ├── canon-alternatives.yml    # CI：卡农新增音频与乐谱发布
│   └── validate.yml              # CI：共享引擎与卡农新增方案的冒烟测试
└── package.json                  # npm 脚本（Puppeteer 录制）
```

## 共享乐谱与编排

当前发布版本为卡农 `1.5.0` 和《化蝶清梦》`1.2.0`。
卡农采用逐层进入、中段减奏和 D 大调终止式；《化蝶清梦》采用洞箫与二胡
交替领奏、长短句和主音收尾。四套引擎从同一份有限乐谱生成，速度分别为
84 BPM 和 72 BPM，渲染时长包含自然尾音。各引擎的 BPM 和默认渲染时长从各曲目的 `project.json` 同步。

```bash
npm run rebuild:music           # 从共享乐谱与项目配置生成各引擎的编排
npm run check                   # 检查项目文件、Strudel Pattern 和生成文件是否过期
```

## 添加新项目

每个项目使用一个目录（如 `canon/`），校验脚本要求以下文件。

- `strudel.html` — Strudel 网页版乐谱
- `main.scd` — SuperCollider 编排（`export_wav.scd` 会自动加载同目录的它）
- `export_wav.scd` — 可直接复制 `canon/` 的入口，或按需调整默认时长
- `main.csd` — Csound 编排（`render_csound.sh` 从项目目录加载）
- `score.mid` — 标准 MIDI 乐谱，供 FluidSynth 与 DAW 使用
- `project.json` — 项目元数据、正式渲染时长和冒烟测试时长

若沿用共享乐谱生成器，在 `scripts/rebuild_scores.mjs` 中登记曲目与声部，并为各引擎
准备对应的播放、合成和导出入口。具备上列文件后可复用渲染工作流。若要运行 CI 短音频
测试，还需把目录名加入 `.github/workflows/validate.yml` 的项目矩阵。

**项目目录名**只能包含字母、数字和下划线（如 `canon`、`bach_partita`），发布时推送
**`<项目目录名>-<版本号>`** 标签（如 `canon-1.0.0`）：标签中的 `-` 是唯一
分隔符，版本号为纯数字点分形式（`1.0.0`，**不带** `-beta` 等预发布后缀）。
各 workflow 会自动从标签解析项目名并渲染，格式非法时快速失败。

## 快速开始

### Strudel（浏览器）

先运行 `npm ci`，再打开项目的 `strudel.html` 并点击 **Play**。例如：

- `canon/strudel.html`：钢琴、小提琴、中提琴与大提琴四声部的《D 大调卡农》
- `liangzhu/strudel.html`：五声音阶原创作品《化蝶清梦》

### SuperCollider（本地）

1. 安装 [SuperCollider](https://supercollider.github.io/)。
2. 打开 `canon/main.scd` 并整体运行，服务器启动后自动开始演奏。
3. 停止演奏：`~stopCanon.()`。

命令行导出 WAV：

```bash
cd canon
sclang export_wav.scd            # 默认输出 canon.wav（137.2 秒）
```

可用环境变量覆盖输出路径与时长：

```bash
MUSIC_RECORD_PATH=canon_test.wav MUSIC_RECORD_DURATION=5 sclang export_wav.scd
```

### MIDI + FluidSynth（命令行）

```bash
sudo apt-get install fluidsynth fluid-soundfont-gm ffmpeg jq
MUSIC_PROJECT_DIR=canon npm run render:fluidsynth  # 输出 canon/canon_fluidsynth.wav
MUSIC_PROJECT_DIR=liangzhu MUSIC_SOUNDFONT=/path/to/your.sf2 npm run render:fluidsynth
```

`score.mid` 由 `npm run rebuild:music` 生成，可直接导入 DAW 或 MuseScore 编辑、出谱。

### 命令行渲染 Strudel（需要 Node.js 22.12+）

```bash
npm ci
MUSIC_PROJECT_DIR=canon npm run render:strudel  # 输出 canon/strudel.webm（137.2 秒）
```

可通过环境变量指定项目与输出路径：

```bash
MUSIC_PROJECT_DIR=canon \
MUSIC_RECORD_PATH=canon/canon_strudel.webm \
npm run render:strudel
```

渲染器默认从项目的 `project.json` 读取时长，也可用
`MUSIC_RECORD_DURATION` 覆盖。旧的 `CANON_*` 变量仍兼容。Strudel 浏览器包由
npm 锁定并从本地提供，自动渲染不依赖第三方 CDN。若 Puppeteer 找不到浏览器，
可用 `PUPPETEER_EXECUTABLE_PATH` 指向已安装的 Chrome 或 Chromium 可执行文件。

自动发现并检查全部项目（项目元数据 + 离线求值每个 `strudel.html` 的
Pattern，乐谱有语法或结构错误会在无头渲染前失败）：

```bash
npm run check
```

只检查指定项目的文件和元数据可运行 `node scripts/validate_projects.mjs liangzhu`。
只检查该项目的 Strudel Pattern 可运行 `node scripts/check_strudel_pattern.mjs liangzhu`。

### 命令行渲染 Csound（需要 Csound 6+）

```bash
sudo apt-get install csound jq
MUSIC_PROJECT_DIR=canon npm run render:csound  # 输出 canon/canon_csound.wav
```

默认渲染当前目录下的 `main.csd`（时长取自 `project.json`），输出
`<项目名>_csound.wav`。可通过环境变量指定项目、时长与输出路径：

```bash
MUSIC_PROJECT_DIR=canon \
MUSIC_RECORD_PATH=canon/canon_csound.wav \
MUSIC_RECORD_DURATION=8 \
bash scripts/render_csound.sh
```

也可直接调用 csound（`#ifndef DURATION` 提供文件内默认时长，可用
`--smacro:DURATION` 覆盖）：

```bash
cd canon
csound --smacro:DURATION=8 -o canon_csound.wav main.csd
```

## 自动化渲染（GitHub Actions）

四个渲染工作流均监听**任意 `*-*` 标签**（如 `canon-1.0.0`），从标签中解析出
项目名（`-` 之前的部分）与版本号（`-` 之后，须为纯数字点分形式），
校验通过后渲染对应目录。GitHub Release 附件使用 `曲目-版本-技术.扩展名`，
例如 `canon-1.5.0-supercollider.wav`。
也可在 Actions 页手动运行并填写 `project` 输入。

| 工作流 | Release 附件（`<tag>` 包含曲目与版本） |
| --- | --- |
| `render.yml` | `<tag>-supercollider.wav` 与 `<tag>-supercollider.mp3` |
| `csound.yml` | `<tag>-csound.wav` 与 `<tag>-csound.mp3` |
| `strudel.yml` | `<tag>-strudel.mp3` |
| `fluidsynth.yml` | `<tag>-fluidsynth.wav` 与 `<tag>-fluidsynth.mp3` |
| `canon-alternatives.yml` | 卡农 Tone.js、Python DSP、Sonic Pi、VSCO 2 实录采样的 WAV 与 MP3，以及 MIDI、MusicXML 和 Sonic Pi 源码 |

卡农专用工作流监听 `canon-<version>` 标签，也可手动运行。所有渲染工作流的 GitHub Actions Artifact 保留 14 天。

推送版本标签时，对应工作流把各自的产物上传到 GitHub Release。常规 CI 会验证
卡农的 Tone.js、Python DSP 和 Sonic Pi 短渲染，以及 music21 的乐谱导出。

## 已发布作品

| 作品 | 版本 | 音频 |
| --- | --- | --- |
| D 大调卡农（Canon in D） | [`canon-1.5.0`](https://github.com/ZeroMarker/music/releases/tag/canon-1.5.0) | [实录采样 WAV](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-vsco2-samples.wav) · [实录采样 MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-vsco2-samples.mp3) · [SuperCollider MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-supercollider.mp3) · [Csound MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-csound.mp3) · [FluidSynth MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-fluidsynth.mp3) · [Strudel MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-strudel.mp3) · [Tone.js MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-tonejs.mp3) · [Python DSP MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-python-dsp.mp3) · [Sonic Pi MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-sonic-pi.mp3) · [MIDI](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-midi.mid) · [MusicXML](https://github.com/ZeroMarker/music/releases/download/canon-1.5.0/canon-1.5.0-music21.musicxml) |
| 化蝶清梦（Butterfly Lovers · Reverie） | [`liangzhu-1.2.0`](https://github.com/ZeroMarker/music/releases/tag/liangzhu-1.2.0) | [WAV 母版](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu.wav) · [SuperCollider MP3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu.mp3) · [Strudel MP3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu_strudel.mp3) · [Csound MP3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu_csound.mp3) · [FluidSynth MP3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.2.0/liangzhu_fluidsynth.mp3) |

卡农 `1.1.0` 修正了 Strudel 版的半速问题（此前实为 42 BPM，现与 project.json
及其他引擎一致为 84 BPM），并加入分声部进入、随机力度与结尾淡出；
`npm run check` 起会在渲染前离线求值全部 Strudel 乐谱。

梁祝项目以 `1.0.1` 为首个完整双引擎版本；`1.0.0` 仅生成了 Strudel 资产，
不建议作为完整版本使用。

## 许可

MIT，见 [LICENSE](LICENSE)。
