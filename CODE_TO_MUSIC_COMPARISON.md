# Code to Music 方案对比

本项目实现了两种通过代码生成音乐的方案：

- **Strudel**：运行在浏览器中的音乐编程环境，基于 Web Audio。
- **SuperCollider**：面向声音合成和算法作曲的原生音频平台。

当前示例均用于演奏《D 大调卡农》，并可通过 GitHub Actions 自动渲染音频。

## 总体对比

| 维度 | Strudel | SuperCollider |
| --- | --- | --- |
| 运行环境 | 浏览器、Node.js、Web Audio | `sclang`、`scsynth`、原生音频服务 |
| 上手难度 | 较低，语法简洁 | 较高，需要理解服务器、SynthDef 和 Pattern |
| 编曲方式 | Pattern 和链式 API | Pattern、SynthDef、Routine 和音频总线 |
| 实时交互 | 优秀，适合网页和 Live Coding | 优秀，但默认缺少网页界面 |
| 音色设计 | 适合快速使用内置合成器和采样 | 可深入控制振荡器、滤波器、包络和效果器 |
| 当前配器 | 钢琴、小提琴 | 钢琴、小提琴、中提琴、大提琴 |
| 当前音色 | 三角波、锯齿波等基础合成音色 | 自定义钢琴、弦乐、琴体共振和混响 |
| 离线产物 | 浏览器实时录制 WebM，再转 MP3 | 直接录制 WAV，再转 MP3 |
| 自动化复杂度 | Node.js、Chromium、Puppeteer、ffmpeg | SuperCollider、JACK、ffmpeg |
| 构建稳定性 | 受浏览器、页面加载和 Web Audio 行为影响 | 音频环境配置更复杂，但渲染流程更直接 |
| 分享方式 | 网页打开即可播放 | 通常需要安装 SuperCollider 或分享导出音频 |
| 适合场景 | 在线体验、教学、原型、现场编码 | 正式制作、复杂合成、算法作曲、批量渲染 |

## 方案一：Strudel

相关文件：

- `canon/strudel.html`：网页播放器和乐曲 Pattern。
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

- `canon/main.scd`：配器、合成器、乐谱和播放逻辑。
- `canon/export_wav.scd`：命令行导出入口。
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

## 本项目推荐

建议保留当前的双轨架构：

- **SuperCollider 作为制作与发布主引擎**，负责高质量 WAV、MP3 和复杂音色。
- **Strudel 作为网页交互版本**，负责试听、教学、分享和快速修改。

后续可以将速度、和弦、旋律、段落等乐谱信息抽取成共享数据，再分别转换为 Strudel Pattern 和 SuperCollider Pattern。这样既能保留两种方案的优势，也能减少两份乐谱独立维护造成的差异。

## 快速决策

| 需求 | 推荐方案 |
| --- | --- |
| 浏览器直接播放 | Strudel |
| 快速编写音乐原型 | Strudel |
| Live Coding 或教学 | Strudel |
| 自定义复杂音色 | SuperCollider |
| 输出高质量 WAV | SuperCollider |
| 正式制作和自动发布 | SuperCollider |
| 同时兼顾展示与音质 | 双轨架构 |
