# music — Code to Music

用代码生成音乐的项目。每首作品通过两套技术方案实现，并可在 GitHub Actions
上自动渲染音频产物。

- **Strudel**：浏览器端音乐编程环境（Web Audio），适合网页播放与快速原型。
- **SuperCollider**：原生音频平台，适合高质量合成、复杂配器和 WAV 母版。

详细的方案对比与选型建议见
[CODE_TO_MUSIC_COMPARISON.md](CODE_TO_MUSIC_COMPARISON.md)。

## 目录结构

```text
.
├── canon/                        # 《D 大调卡农》项目
│   ├── strudel.html              # Strudel 网页播放器（Pattern 乐谱）
│   ├── main.scd                  # SuperCollider 编排（SynthDef + Pattern）
│   ├── export_wav.scd            # SuperCollider 命令行 WAV 导出入口
│   ├── project.json              # 项目名称、速度和渲染时长
│   └── README.md                 # canon 使用说明
├── liangzhu/                     # 《化蝶清梦》原创五声音阶项目
│   ├── project.json              # 项目名称、速度和渲染时长
│   ├── strudel.html              # Strudel 网页播放器
│   ├── main.scd                  # SuperCollider 室内乐编排
│   ├── export_wav.scd            # WAV 导出入口
│   └── README.md                 # liangzhu 使用说明
├── scripts/
│   └── render_strudel.mjs        # 共享 Puppeteer 无头录制脚本（WebM）
├── .github/workflows/
│   ├── strudel.yml               # CI：Strudel → MP3（按标签解析项目）
│   └── render.yml                # CI：SuperCollider → WAV + MP3（按标签解析项目）
└── package.json                  # npm 脚本（Puppeteer 录制）
```

## 添加新项目

每个项目一个目录（如 `canon/`），包含：

- `strudel.html` — Strudel 网页版乐谱
- `main.scd` — SuperCollider 编排（`export_wav.scd` 会自动加载同目录的它）
- `export_wav.scd` — 可直接复制 `canon/` 的入口，或按需调整默认时长
- `project.json` — 项目元数据、正式渲染时长和冒烟测试时长

新项目可沿用双轨渲染，无需改动任何 workflow。**项目目录名**只能包含字母、
数字和下划线（如 `canon`、`bach_partita`），发布时推送
**`<项目目录名>-<版本号>`** 标签（如 `canon-1.0.0`）：标签中的 `-` 是唯一
分隔符，版本号为纯数字点分形式（`1.0.0`，**不带** `-beta` 等预发布后缀）。
两个 workflow 会自动从标签解析项目名并渲染，格式非法时快速失败。

## 快速开始

### Strudel（浏览器）

先运行 `npm ci`，再打开 `canon/strudel.html` 并点击 **Play**。乐谱使用 Strudel Pattern 编写，
音色为内置合成器（三角波钢琴、锯齿波小提琴）。

### SuperCollider（本地）

1. 安装 [SuperCollider](https://supercollider.github.io/)。
2. 打开 `canon/main.scd` 并整体运行，服务器启动后自动开始演奏。
3. 停止演奏：`~stopCanon.()`。

命令行导出 WAV：

```bash
cd canon
sclang export_wav.scd            # 默认输出 canon_in_d.wav（137.2 秒）
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

项目结构检查：

```bash
npm run check -- canon
```

## 自动化渲染（GitHub Actions）

两个工作流均监听**任意 `*-*` 标签**（如 `canon-1.0.0`），从标签中解析出
项目名（`-` 之前的部分）与版本号（`-` 之后，须为纯数字点分形式），
校验通过后渲染对应目录；产物均以项目名为前缀，互不冲突。
也可在 Actions 页手动运行并填写 `project` 输入。

| 工作流 | 产物（以 `<proj>` 为例） |
| --- | --- |
| `render.yml` | `<proj>.wav` + `<proj>.mp3`（SuperCollider 母版） |
| `strudel.yml` | `<proj>_strudel.mp3`（Strudel 网页版） |

产物以 GitHub Actions Artifact 形式提供，保留 14 天。

推送 `<proj>-<version>` 标签发布时，两个工作流还会把各自的产物自动上传到
**GitHub Release**（若 Release 不存在则自动创建，并生成发布说明），例如
`canon-1.0.0` 的 Release 包含：

- `canon.wav` / `canon.mp3` — SuperCollider 母版
- `canon_strudel.mp3` — Strudel 网页版

## 许可

MIT，见 [LICENSE](LICENSE)。
