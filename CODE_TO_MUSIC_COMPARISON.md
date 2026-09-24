# Code to Music 方案对比

本项目实现了三种通过代码生成音乐的方案：

- **Strudel**：运行在浏览器中的音乐编程环境，基于 Web Audio。
- **SuperCollider**：面向声音合成和算法作曲的原生音频平台。
- **Csound**：经典音频编程语言，单文件 orchestra + score，命令行确定性渲染。

当前包含《D 大调卡农》和原创五声音阶作品《化蝶清梦》两个项目，均可通过
GitHub Actions 自动渲染音频。

## 总体对比

| 维度 | Strudel | SuperCollider | Csound |
| --- | --- | --- | --- |
| 运行环境 | 浏览器、Node.js、Web Audio | `sclang`、`scsynth`、原生音频服务 | `csound` 命令行（单 .csd 文件） |
| 上手难度 | 较低，语法简洁 | 较高，需要理解服务器、SynthDef 和 Pattern | 较高，需要理解 orchestra/score 与调度 |
| 编曲方式 | Pattern 和链式 API | Pattern、SynthDef、Routine 和音频总线 | ftable 音符表 + 调度器 instrument |
| 实时交互 | 优秀，适合网页和 Live Coding | 优秀，但默认缺少网页界面 | 弱，主要面向离线渲染（也可实时） |
| 音色设计 | 适合快速使用内置合成器和采样 | 可深入控制振荡器、滤波器、包络和效果器 | 物理建模（wgpluck2/wgbow）、丰富的 opcode 库 |
| 当前配器 | 卡农：钢琴、小提琴、中提琴、大提琴；化蝶：低音、丝弦与旋律声部 | 卡农：钢琴与弦乐四声部；化蝶：月琴、洞箫、二胡与低音 | 卡农：钢琴、小提琴、中提琴、大提琴；化蝶：月琴、洞箫、二胡、低音 |
| 当前音色 | 三角波、锯齿波等基础合成音色 | 自定义钢琴、弦乐、琴体共振和混响 | 拨弦（wgpluck2）、弓弦（wgbow）、呼吸长笛、freeverb 混响 |
| 离线产物 | 浏览器实时录制 WebM，再转 MP3 | 直接录制 WAV，再转 MP3 | **非实时直写 WAV**（秒级完成），再转 MP3 |
| 自动化复杂度 | Node.js、Chromium、Puppeteer、ffmpeg | SuperCollider、JACK、ffmpeg | 仅 csound + ffmpeg，最简单 |
| 构建稳定性 | 受浏览器、页面加载和 Web Audio 行为影响 | 音频环境配置更复杂，但渲染流程更直接 | 高，纯命令行确定性渲染 |
| 分享方式 | 网页打开即可播放 | 通常需要安装 SuperCollider 或分享导出音频 | 分享导出音频，或配合 csound 运行 |
| 适合场景 | 在线体验、教学、原型、现场编码 | 正式制作、复杂合成、算法作曲、批量渲染 | 批量渲染、确定性 CI、音色物理建模、长时长生成 |

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
- 浏览器、CDN或第三方包升级可能影响行为。
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

- 顶部用 `ftgen` 定义 MIDI 音符表（旋律、和弦分解、低音等）。
- 一个调度器 instrument（instr 1）在 i-time 用 `schedule` 按节奏生成全部事件，
  直到 `DURATION` 宏指定的时长（默认取项目渲染时长，`--smacro:DURATION` 可覆盖）。
- 乐器 instrument 只负责音色：拨弦（`wgpluck2`）、弓弦（`wgbow`）、
  呼吸长笛（`poscil` + 噪声气息）、柔和钢琴（噪声锤击 + 部分音）。
- 全局混响母线（instr 99）：`freeverb` + 淡出 + 软限幅，唯一输出点。

### 优点

- **确定性非实时渲染**：`csound -o out.wav main.csd` 直接写 WAV，
  137 秒的作品秒级完成，无需音频设备或浏览器。
- CI 依赖最轻：只需 `apt install csound ffmpeg`，不需要 JACK/Chromium。
- 单文件自包含，音符数据、调度与音色都在一个可 diff 的文件里。
- 物理建模 opcode（`wgpluck2`、`wgbow`）音色表现力强。
- `--smacro:DURATION` 控制渲染时长，便于冒烟测试与正式渲染复用同一文件。

### 局限

- 学习曲线陡峭，语法与现代语言差异大。
- 乐谱以 ftable 数字表 + 手动调度器表达，大规模乐谱不如 Pattern 直观。
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

## 选型建议

### 选择 Strudel

适用于以下目标：

- 希望用户打开网页即可播放。
- 主要制作循环、节奏或较轻量的生成音乐。
- 需要在线教学、代码演示或现场编码。
- 更重视开发和分享效率，而不是复杂音色设计。

### 选择 SuperCollider

适用于以下目标：

- 需要高质量 WAV 母版。
- 需要自定义乐器、复杂配器或专业效果链。
- 需要算法作曲、生成式音乐或批量渲染。
- 更重视声音控制能力和长期扩展性。

### 选择 Csound

适用于以下目标：

- 需要纯命令行、确定性的离线渲染（CI 友好）。
- 需要秒级渲染长时长作品，或大量批量生成。
- 想用物理建模音色（拨弦、弓弦、吹管）。
- 希望乐谱、调度与音色都在单一文件里，便于版本管理。

## 本项目推荐

建议保留当前的三轨架构：

- **SuperCollider 作为制作与发布主引擎**，负责高质量 WAV、MP3 和复杂音色。
- **Strudel 作为网页交互版本**，负责试听、教学、分享和快速修改。
- **Csound 作为确定性批量渲染引擎**，负责 CI 冒烟测试、长时长/批量导出，
  并提供一个不依赖 JACK/浏览器的稳定渲染路径。

后续可以将速度、和弦、旋律、段落等乐谱信息抽取成共享数据，再分别转换为
Strudel Pattern、SuperCollider Pattern 和 Csound ftable/调度器。这样既能保留
多种方案的优势，也能减少多份乐谱独立维护造成的差异。

## 快速决策

| 需求 | 推荐方案 |
| --- | --- |
| 浏览器直接播放 | Strudel |
| 快速编写音乐原型 | Strudel |
| Live Coding 或教学 | Strudel |
| 自定义复杂音色 | SuperCollider / Csound |
| 物理建模音色 | Csound |
| 输出高质量 WAV | SuperCollider / Csound |
| 确定性 CI / 批量渲染 | Csound |
| 正式制作和自动发布 | SuperCollider |
| 同时兼顾展示与音质 | 三轨架构 |
