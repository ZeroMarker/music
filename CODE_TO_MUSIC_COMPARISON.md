# Code to Music 方案对比

本仓库用共享乐谱为《D 大调卡农》和原创五声音阶作品《化蝶清梦》生成四套引擎的编排，并通过 GitHub Actions 渲染音频。已有作品的使用与发布方式见 [README](README.md)。

## 从描述到音频

Code → Music 让 Agent 根据自然语言描述编写或修改作曲程序，由程序编排乐谱、合成音色并渲染可播放的音乐。把编曲、音色和输出拆开后，同一首曲子可以换音色，同一套合成器也可以渲染不同乐谱。

```text
自然语言描述 → 曲目参数（速度、调式、配器、段落）
            → 编曲规则（和声、主题、贝斯、鼓组）
            → 以拍为单位的乐谱事件
                 ├─ 合成器或采样器 → 混音与效果 → WAV → MP3
                 ├─ 标准 MIDI → DAW 编辑，或用 FluidSynth 加载 SoundFont 渲染
                 └─ 节拍与段落标记 → 可选的 HyperFrames 时间轴
```

乐谱事件至少记录声部、起拍、音高、时值和力度。固定速度下，秒数等于拍数乘以 `60 / BPM`。MIDI 是乐谱事件的交换格式，可携带速度、音色编号和控制消息。合成器、采样库和混音都会影响最终声音。直接用 DSP 渲染时，可以从同一份乐谱事件生成 WAV 和 MIDI。 [标准 MIDI 文件规范](https://midi.org/standard-midi-files)

| 方向 | 适用任务 |
| --- | --- |
| A · 直接生成完整音乐 | 让 Agent 编写编曲与合成代码，离线交付源码、WAV、MP3 和 MIDI。首个原型采用这条路线。 |
| B · Live Coding | 在 Strudel 或 Sonic Pi 中边播放边修改节奏、音色和结构。 |
| C · Agent 驱动制作 | 用乐谱生成器和 MIDI 制作可编辑工程，再在 DAW 中替换音色、细化演奏与混音。 |
| D · 音乐与视频共用时间轴 | 将同一份节拍和段落标记交给音乐渲染器与 HyperFrames，以便修改速度后重新对齐。 |

## 仓库现有方案对比

| 引擎 | 编排与音色 | 仓库中的渲染方式 | 适用任务 |
| --- | --- | --- | --- |
| Strudel | JavaScript Pattern、Web Audio 合成器和采样 | Chromium 实时录制 WebM，再转 MP3 | 网页试听、教学、快速编辑与现场演奏 |
| SuperCollider | `sclang` Pattern、SynthDef、自定义效果链 | `scsynth` 录制 WAV，CI 使用 JACK，再转 MP3 | 自定义乐器、复杂音色与制作母版 |
| Csound | `.csd` 调度事件、物理建模与效果 opcode | 命令行非实时写 WAV，再转 MP3 | 批量离线导出、CI 冒烟测试、物理建模 |
| MIDI + FluidSynth | 标准 MIDI、General MIDI SoundFont、每声部一轨 | 命令行非实时写 WAV，CI 再转 MP3 | DAW 交换、采样参考版、快速离线渲染 |

## 方案一：Strudel

相关文件：

- `<project>/strudel.html`：网页播放器和乐曲 Pattern。
- `scripts/render_strudel.mjs`：基于 Puppeteer 的自动录音脚本。
- `.github/workflows/strudel.yml`：自动生成 MP3 的工作流。

### 优点

- 浏览器即可运行，用户体验直接。
- Pattern 表达紧凑，适合快速编写节奏、旋律和循环。
- 容易集成按钮、日志、可视化等网页功能。
- 适合教学、作品展示和 Live Coding。
- 前端开发者不需要先掌握专业音频服务器。

### 局限

- 浏览器录音属于实时录制，渲染时间基本等于作品时长。
- 自动化依赖 Chromium 和 Web Audio，环境变量较多。
- Chromium 或 Strudel 依赖升级可能影响录音行为。
- 使用基础波形时，真实乐器质感有限。
- 高负载作品可能受到浏览器性能和定时精度影响。

### 当前自动化流程

```text
strudel.html
    → Headless Chromium 播放
    → MediaRecorder 录制 WebM
    → ffmpeg 转换 MP3
    → GitHub Actions Artifact
```

## 方案二：SuperCollider

相关文件：

- `<project>/main.scd`：配器、合成器、乐谱和播放逻辑。
- `<project>/export_wav.scd`：命令行导出入口。
- `.github/workflows/render.yml`：自动生成 WAV 和 MP3 的工作流。

### 优点

- 声音合成能力强，可精细控制音色和效果链。
- Pattern、Routine 和音频总线适合复杂生成式音乐。
- 可以直接录制无损 WAV，适合作为后续制作的母版。
- 不依赖浏览器页面或用户交互。
- 更适合复杂配器、长时间生成和批量导出。

### 局限

- 学习曲线明显高于 Strudel。
- 本地运行需要安装 SuperCollider，并正确配置音频设备。
- Linux 无头环境通常需要 JACK 等额外音频基础设施。
- 默认缺少适合普通用户的网页播放和编辑界面。
- SynthDef 与 Pattern 代码量较大，维护门槛更高。

### 当前自动化流程

```text
export_wav.scd
    → 加载 main.scd
    → SuperCollider + JACK 渲染 WAV
    → ffmpeg 转换 MP3
    → GitHub Actions Artifact
```

## 方案三：Csound

相关文件：

- `<project>/main.csd`：单文件编排（乐器 + 调度器 + score）。
- `scripts/render_csound.sh`：共享命令行渲染脚本。
- `.github/workflows/csound.yml`：自动生成 WAV 和 MP3 的工作流。

### 实现思路

`main.csd` 是完全自包含的单个文件：

- 共享乐谱生成 `instr 1` 的 `schedule` 调用，包含以秒为单位的起始时间和时值。
- `DURATION` 控制渲染窗口，命令行可用 `--smacro:DURATION` 覆盖。
- 乐器 instrument 只负责音色：拨弦（`wgpluck2`）、弓弦（`wgbow`）、
  呼吸长笛（`poscil` + 噪声气息）、柔和钢琴（噪声锤击 + 部分音）。
- 全局混响母线（instr 99）：`freeverb` + 淡出 + 软限幅，唯一输出点。

### 优点

- **非实时渲染**：`csound -o out.wav main.csd` 直接写 WAV，
  渲染时间取决于曲目复杂度与运行环境，无需音频设备或浏览器。
- CI 通过 Csound 写 WAV、FFmpeg 编码 MP3，项目时长由 `jq` 从 JSON 读取。
- 单文件自包含，音符数据、调度与音色都在一个可 diff 的文件里。
- 物理建模 opcode（`wgpluck2`、`wgbow`）音色表现力强。
- `--smacro:DURATION` 控制渲染时长，便于冒烟测试与正式渲染复用同一文件。

### 局限

- 学习曲线陡峭，语法与现代语言差异大。
- 展开后的 `schedule` 事件较密集，编曲调整从共享乐谱生成脚本入手。
- 默认缺少网页播放界面（但可配合 csound~ / wasm 方案）。
- 音色需自行设计，无内置“乐器库”可直接调用。

### 当前自动化流程

```text
render_csound.sh
    → 读取 project.json 时长
    → csound --smacro:DURATION=... 渲染 WAV
    → ffmpeg 转换 MP3
    → GitHub Actions Artifact
```

## 方案四：MIDI + FluidSynth

相关文件：

- `<project>/score.mid`：由 `scripts/rebuild_scores.mjs` 生成的标准 MIDI（每声部一轨）。
- `scripts/midi.mjs`：无依赖的 MIDI 写入器（速度、音色、声像、混响发送）。
- `scripts/render_fluidsynth.sh`：共享命令行渲染脚本。
- `.github/workflows/fluidsynth.yml`：自动生成 WAV 和 MP3 的工作流。

### 优点

- 非实时渲染。命令行脚本使用 FluidSynth、SoundFont、FFmpeg 和 `jq`。
- 真实乐器采样：钢琴、小提琴、中提琴、大提琴；化蝶使用低音提琴、筝（Koto）、
  尺八（Shakuhachi，近似洞箫）、Fiddle（近似二胡）。
- 通过 `MUSIC_SOUNDFONT` 更换采样库，同一份乐谱可以渲染不同音色。
- `score.mid` 可直接导入 DAW、MuseScore，用于精修或输出五线谱。

### 局限

- 音色受 SoundFont 质量限制，General MIDI 中没有真正的洞箫和二胡。
- 表现力（揉弦、滑音）不如 SuperCollider / Csound 的自定义合成。

### 当前自动化流程

```text
rebuild_scores.mjs → score.mid
    → fluidsynth -F 非实时渲染
    → ffmpeg 裁剪时长、淡出、限幅 → WAV
    → ffmpeg 转换 MP3
    → GitHub Actions Artifact
```

## 卡农新增方案

| 方案 | 入口 | 产物 |
| --- | --- | --- |
| Tone.js | `npm run render:tone` | Chromium 非实时生成的 44.1 kHz 立体声 WAV |
| Sonic Pi | 打开 `canon/sonic_pi.rb` | 五声部实时演奏，可在应用内录音 |
| Python DSP | `python canon/render_python.py` | NumPy 加法合成的 44.1 kHz 立体声 WAV |
| music21 | `python canon/export_music21.py` | 从共享 MIDI 量化导出的 MusicXML |

Tone.js 与 Python 从同一份 `canon/score.json` 调度音符，Sonic Pi 的播放器内嵌由共享乐谱生成的事件，music21 则读取同源 MIDI。运行方式和依赖见 [卡农使用说明](canon/README.md)。

## 其他候选技术

以下技术可用于扩展现有编曲、合成或交互能力。

| 技术 | 类型 | 运行环境 | 离线渲染 | 优势 | 局限 | 适合场景 |
| --- | --- | --- | --- | --- | --- | --- |
| Tone.js（卡农已实现） | JS 音频框架 | Web Audio | `Tone.Offline` 离线渲染 | 提供乐器、效果器和 Transport 调度 | 迁移时需重写 Pattern 或增加事件适配层 | 浏览器合成、交互播放和导出 |
| Sonic Pi（卡农已实现） | Ruby 风格的音乐 DSL | 桌面与 Web | 常用工作流为播放与录制 | 适合边演奏边修改代码 | 批量交付需另行设计渲染流程 | 教学、Live Coding 演出 |
| TidalCycles | Haskell Pattern DSL（底层 SuperDirt） | GHC + SuperCollider | 仅实时录制 | 用 Pattern 表达节奏与变奏，Strudel 继承了其模式语言 | 安装链长，依赖 Haskell 与 SC | 节奏型 Live Coding |
| ChucK | 强时序音频语言 | 命令行 / WebChucK | `--silent` 可非实时写 WAV | 采样级精确定时，语法类 C | 社区较小，音色库有限 | 精确时序、算法作曲 |
| Faust | 函数式 DSP 语言 | 编译为 C++/WASM/插件 | 依赖宿主 | 生成高效 DSP，可导出 VST/WebAudio | 只负责音色与效果，不负责编曲 | 自定义合成器、跨平台音色 |
| Pure Data / Max | 可视化数据流 | 桌面应用（Pd 可 `-nogui -batch`） | Pd batch 模式可离线 | 可视化补丁，交互装置成熟 | 补丁难以 diff 和代码审查 | 装置艺术、实时交互 |
| music21（卡农已实现）/ LilyPond | 乐理工具与乐谱排版 | Python / 命令行 | 导出 MIDI 或排版乐谱 | 和弦分析、音符与乐谱对象 | 音频交给独立合成器渲染 | 算法编曲、乐理校验、五线谱 |

项目文档提供入门示例和 API 说明。 [Strudel](https://strudel.cc/workshop/getting-started/) · [SuperCollider](https://supercollider.github.io/) · [Csound](https://csound.com/) · [FluidSynth](https://www.fluidsynth.org/) · [Tone.js](https://tonejs.github.io/) · [Sonic Pi](https://sonic-pi.net/) · [music21](https://music21.org/music21docs/)

## 本项目推荐

建议保留当前的四轨架构：

- **SuperCollider 作为制作与发布主引擎**，负责高质量 WAV、MP3 和复杂音色。
- **Strudel 作为网页交互版本**，负责试听、教学、分享和快速修改。
- **Csound 作为批量渲染引擎**，负责 CI 冒烟测试、长时长/批量导出，
  并提供一个不依赖 JACK/浏览器的稳定渲染路径。
- **MIDI + FluidSynth 作为采样音色与交换格式**，提供真实乐器参考版本，
  并把乐谱交给 DAW / 打谱软件。

[共享乐谱生成脚本](scripts/rebuild_scores.mjs)把两首曲目的速度、和弦和主题编成有限时长的声部事件。
`npm run rebuild:music` 从这些事件重新生成 Strudel Pattern、SuperCollider Pattern、Csound 调度数据和 `score.mid`。编曲改动从生成脚本入手，音色和录制设置仍由各引擎的播放器或乐器定义负责。当前生成脚本列出了两首曲目，加入新曲目需要登记乐谱及各引擎对应的声部。

## 快速决策

| 需求 | 推荐方案 |
| --- | --- |
| 浏览器直接播放 | Strudel |
| 快速编写音乐原型 | Strudel |
| Live Coding 或教学 | Strudel |
| 自定义复杂音色 | SuperCollider / Csound |
| 物理建模音色 | Csound |
| 输出高质量 WAV | SuperCollider / Csound |
| 离线 CI / 批量渲染 | Csound |
| 正式制作和自动发布 | SuperCollider |
| 同时兼顾展示与音质 | 四轨架构 |
| 真实乐器采样、轻量离线渲染 | MIDI + FluidSynth |
| 网页内快速离线导出 | Tone.js |
| 五线谱输出 | LilyPond / music21 |
| 自定义 DSP 或插件 | Faust |
| 课堂教学 | Sonic Pi |

## Code → Music 与 Suno

| 维度 | Code → Music | Suno |
| --- | --- | --- |
| 创作入口 | 描述转为可审查的编曲代码与曲目参数 | 用提示词、歌词或音频素材生成歌曲 |
| 音符与速度 | 直接设定 BPM、和弦、起拍、时值与力度 | 通过输入、段落编辑和重新生成来调整结果 |
| 音色与人声 | 自选合成器或采样库，歌声需要额外的合成或录制流程 | 可生成带歌词和人声的歌曲 |
| 复现与编辑 | 保存事件、代码、种子、依赖版本和音色配置，可复现编曲及后续修改 | 可拆分音轨、调整段落或转换为 MIDI，编辑从已生成的结果出发 |
| 适用目标 | 固定节拍、逐音编辑、版本差异审查、批量变体 | 快速探索歌曲风格、人声与完整编曲 |

对比基于两种流程的输入和编辑方式。 [Suno Song Editor](https://help.suno.com/en/articles/6141505) · [Suno MCP 功能说明](https://help.suno.com/en/articles/14551361)

## Agent Skill 与同步案例

- Claude Code 的 `code-to-music` 示例把电子合成与传统 SoundFont 渲染写成两条制作流程，适合参考如何描述输入、依赖和输出。 [claude-skills-base 源码](https://github.com/Cam10001110101/claude-skills-base) · [Skill 条目](https://skillselion.com/skills/aiskillstore/marketplace/code-to-music)
- 像素游戏短片案例展示了如何用同一份节拍表安排鼓点和画面事件。仓库后续可从乐谱导出 `tempoBpm`、以零为起点的 `startBeat`、段落名与重点节拍，把 WAV 作为 HyperFrames 音轨，并将拍点换算成动画时间。音轨的时间范围包含结尾尾音，画面可按段落标记安排切换。 [制作案例](https://meetreference.com/v/30-second-vertical-pixel-game-rhythm/) · [HyperFrames 音频文档](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/voice-and-audio.mdx)

## 首个原型规格

计划用 Python 编写一首原创纯器乐氛围电子乐，在本地完成作曲、DSP 合成、混音和导出。以 `90 BPM`、`4/4`、A 小调和固定随机种子起步。默认 22 小节等于 88 拍，演奏窗口约 `58.67` 秒，再留约 `1.33` 秒的混响尾音，WAV 总长约 `60` 秒。改变 BPM 时保留小节数，按新速度计算演奏窗口。

| 段落 | 小节 | 进入时间 | 编排 |
| --- | --- | --- | --- |
| 引子 | 1–4 | `0.00 s` | 缓慢起音的铺底和弦，引出短动机 |
| 展开 | 5–12 | `10.67 s` | 加入低音与轻鼓组，旋律以疏密变化回应动机 |
| 高潮 | 13–18 | `32.00 s` | 增加琶音和节奏密度，保留旋律的空间 |
| 收束 | 19–22 | `48.00 s` | 逐层撤出鼓和贝斯，最后两小节以 `E7 → Am` 收束 |

### 编曲、音色与交付

1. **编曲。** 用 `Am7 → Fmaj7 → Cmaj7 → G6` 建立和声循环，从短动机生成答句。旋律强拍优先使用和弦音，贝斯用根音与少量经过音。鼓组由底鼓、轻军鼓和闭镲组成。将 BPM、调式、随机种子设为可调参数，以音级表示和弦与旋律，确保改调式时能重新构造音高。速度变化改变拍到秒的换算，种子变化影响动机变体和力度细节。
2. **乐谱事件。** 保存 `voice`、`startBeat`、`durationBeats`、`midiNote` 与 `velocity`。鼓组按打击乐器映射处理。将同一份事件分别交给 DSP 渲染与 MIDI 导出，把合成器参数留在独立配置里。若之后接入现有 Strudel 生成逻辑，需处理同一声部同拍的和弦事件，现有网格每个声部每步只容纳一个音符。
3. **合成与混音。** 使用 NumPy 生成波形和噪声，给铺底音色加低通和慢包络，给主旋律加短延迟，给底鼓加快速下滑的正弦波。各声部先调电平和声像，再加共用混响与尾音淡出，合并为 44.1 kHz 立体声 WAV。将乐谱随机数与噪声合成随机数分开管理，并固定依赖版本。 [NumPy 随机数文档](https://numpy.org/doc/stable/reference/random/generator.html) · [SciPy WAV 写入接口](https://docs.scipy.org/doc/scipy/reference/generated/scipy.io.wavfile.write.html)
4. **导出。** 交付生成源码、曲目参数、乐谱事件、可编辑的 `score.mid`、混音 `mix.wav` 和分享用 `mix.mp3`。MP3 由 WAV 编码。后续若进入 DAW，可以用 MIDI 换音色，也可按需导出分轨 WAV 保留合成器和效果的声音。

### 验收标准

- 默认参数生成约 60 秒的 WAV，允许尾音与采样取整误差不超过 `0.1 s`。检查 WAV 和 MP3 的流信息、左右声道、非静音及峰值。MP3 时长可因编码填充略有差异。 [ffprobe 文档](https://ffmpeg.org/ffprobe.html) · [FFmpeg 音频滤镜](https://ffmpeg.org/ffmpeg-filters.html)
- MIDI 可在 DAW 打开，包含 `90 BPM` 速度和可区分的乐器声部。MIDI 与 WAV 的事件起点以同一份事件表为准，允许各自的时钟量化误差。
- 在同一运行环境和版本下重复生成，同一配置得到相同的乐谱事件与 WAV PCM。测试 `75 BPM` 或 `105 BPM` 时，段落起点和总时长随速度变化。切换调式时，音高遵循相应调式与终止规则。只换种子时，段落长度与和声骨架一致，动机或力度至少有一处变化。
- 试听检验动机可辨、段落有起伏、声部层次清楚且尾音自然。文本指标验证格式与信号，试听验证音乐表现。
