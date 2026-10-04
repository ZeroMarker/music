# music — Code to Music

用代码生成音乐的项目。每首作品通过三套技术方案实现，并可在 GitHub Actions
上自动渲染音频产物。

- **Strudel**：浏览器端音乐编程环境（Web Audio），适合网页播放与快速原型。
- **SuperCollider**：原生音频平台，适合高质量合成、复杂配器和 WAV 母版。
- **Csound**：经典音频语言，单文件 orchestra + score，纯命令行确定性渲染。

详细的方案对比与选型建议见
[CODE_TO_MUSIC_COMPARISON.md](CODE_TO_MUSIC_COMPARISON.md)。

## 目录结构

```text
.
├── canon/                        # 《D 大调卡农》项目
│   ├── strudel.html              # Strudel 网页播放器（Pattern 乐谱）
│   ├── main.scd                  # SuperCollider 编排（SynthDef + Pattern）
│   ├── export_wav.scd            # SuperCollider 命令行 WAV 导出入口
│   ├── main.csd                  # Csound 编排（orchestra + 调度器 + score）
│   ├── project.json              # 项目名称、速度和渲染时长
│   └── README.md                 # canon 使用说明
├── liangzhu/                     # 《化蝶清梦》原创五声音阶项目
│   ├── project.json              # 项目名称、速度和渲染时长
│   ├── strudel.html              # Strudel 网页播放器
│   ├── main.scd                  # SuperCollider 室内乐编排
│   ├── export_wav.scd            # WAV 导出入口
│   ├── main.csd                  # Csound 编排
│   └── README.md                 # liangzhu 使用说明
├── scripts/
│   ├── render_strudel.mjs        # 共享 Puppeteer 无头录制脚本（WebM）
│   ├── render_csound.sh          # 共享 Csound 命令行渲染脚本（WAV）
│   └── validate_projects.mjs     # 自动发现并校验项目结构与配置
├── .github/workflows/
│   ├── strudel.yml               # CI：Strudel → MP3（按标签解析项目）
│   ├── render.yml                # CI：SuperCollider → WAV + MP3（按标签解析项目）
│   ├── csound.yml                # CI：Csound → WAV + MP3（按标签解析项目）
│   └── validate.yml              # CI：全部项目的短时 Strudel/Csound 冒烟测试
└── package.json                  # npm 脚本（Puppeteer 录制）
```

## 重做编排

两首作品已重新编排，版本分别为卡农 `1.2.0` 和《化蝶清梦》`1.1.0`。
卡农采用逐层进入、中段减奏和 D 大调终止式；《化蝶清梦》采用洞箫与二胡
交替领奏、长短句和主音收尾。三套引擎从同一份有限乐谱生成，速度分别为
84 BPM 和 72 BPM，渲染时长包含自然尾音。

```bash
npm run rebuild:music           # 从 scripts/rebuild_scores.mjs 生成三套乐谱
npm run check                   # 检查全曲及停止后的静音
```

## 添加新项目

每个项目一个目录（如 `canon/`），包含：

- `strudel.html` — Strudel 网页版乐谱
- `main.scd` — SuperCollider 编排（`export_wav.scd` 会自动加载同目录的它）
- `export_wav.scd` — 可直接复制 `canon/` 的入口，或按需调整默认时长
- `main.csd` — Csound 编排（`render_csound.sh` 会自动加载同目录的它）
- `project.json` — 项目元数据、正式渲染时长和冒烟测试时长

新项目可沿用三轨渲染，无需改动任何 workflow。**项目目录名**只能包含字母、
数字和下划线（如 `canon`、`bach_partita`），发布时推送
**`<项目目录名>-<版本号>`** 标签（如 `canon-1.0.0`）：标签中的 `-` 是唯一
分隔符，版本号为纯数字点分形式（`1.0.0`，**不带** `-beta` 等预发布后缀）。
三个 workflow 会自动从标签解析项目名并渲染，格式非法时快速失败。

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

### 命令行渲染 Strudel（需要 Node.js 22+）

```bash
npm ci
npm run render:strudel           # 默认输出 canon/strudel.webm（137.2 秒）
```

可通过环境变量指定项目与输出路径：

```bash
MUSIC_PROJECT_DIR=canon \
MUSIC_RECORD_PATH=canon/canon_strudel.webm \
npm run render:strudel
```

渲染器默认从项目的 `project.json` 读取时长，也可用
`MUSIC_RECORD_DURATION` 覆盖。旧的 `CANON_*` 变量仍兼容。Strudel 浏览器包由
npm 锁定并从本地提供，自动渲染不依赖第三方 CDN。

自动发现并检查全部项目（项目元数据 + 离线求值每个 `strudel.html` 的
Pattern，乐谱有语法或结构错误会在无头渲染前失败）：

```bash
npm run check
```

也可以只检查指定项目的元数据：`npm run check -- liangzhu`。

### 命令行渲染 Csound（需要 Csound 6+）

```bash
npm run render:csound --   # 或 bash scripts/render_csound.sh
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

两个工作流均监听**任意 `*-*` 标签**（如 `canon-1.0.0`），从标签中解析出
项目名（`-` 之前的部分）与版本号（`-` 之后，须为纯数字点分形式），
校验通过后渲染对应目录；产物均以项目名为前缀，互不冲突。
也可在 Actions 页手动运行并填写 `project` 输入。

| 工作流 | 产物（以 `<proj>` 为例） |
| --- | --- |
| `render.yml` | `<proj>.wav` + `<proj>.mp3`（SuperCollider 母版） |
| `csound.yml` | `<proj>_csound.wav` + `<proj>_csound.mp3`（Csound 版） |
| `strudel.yml` | `<proj>_strudel.mp3`（Strudel 网页版） |

产物以 GitHub Actions Artifact 形式提供，保留 14 天。

推送 `<proj>-<version>` 标签发布时，三个工作流还会把各自的产物自动上传到
**GitHub Release**（若 Release 不存在则自动创建，并生成发布说明），例如
`canon-1.0.0` 的 Release 包含：

- `canon.wav` / `canon.mp3` — SuperCollider 母版
- `canon_csound.wav` / `canon_csound.mp3` — Csound 版
- `canon_strudel.mp3` — Strudel 网页版

## 已发布作品

| 作品 | 版本 | 音频 |
| --- | --- | --- |
| D 大调卡农（Canon in D） | [`canon-1.2.0`](https://github.com/ZeroMarker/music/releases/tag/canon-1.2.0) | [WAV 母版](https://github.com/ZeroMarker/music/releases/download/canon-1.2.0/canon.wav) · [SuperCollider MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.2.0/canon.mp3) · [Csound MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.2.0/canon_csound.mp3) · [Strudel MP3](https://github.com/ZeroMarker/music/releases/download/canon-1.2.0/canon_strudel.mp3) |
| 化蝶清梦（Butterfly Lovers · Reverie） | [`liangzhu-1.1.0`](https://github.com/ZeroMarker/music/releases/tag/liangzhu-1.1.0) | [WAV 母版](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.1.0/liangzhu.wav) · [SuperCollider MP3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.1.0/liangzhu.mp3) · [Strudel MP3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.1.0/liangzhu_strudel.mp3) · [Csound MP3](https://github.com/ZeroMarker/music/releases/download/liangzhu-1.1.0/liangzhu_csound.mp3) |

卡农 `1.1.0` 修正了 Strudel 版的半速问题（此前实为 42 BPM，现与 project.json
及其他引擎一致为 84 BPM），并加入分声部进入、随机力度与结尾淡出；
`npm run check` 起会在渲染前离线求值全部 Strudel 乐谱。

梁祝项目以 `1.0.1` 为首个完整双引擎版本；`1.0.0` 仅生成了 Strudel 资产，
不建议作为完整版本使用。

## 许可

MIT，见 [LICENSE](LICENSE)。
