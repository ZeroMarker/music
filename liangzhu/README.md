# liangzhu — Butterfly Lovers · Reverie

以中国五声音阶、越剧气质与化蝶意象创作的原创代码音乐项目。它不是《梁祝》
协奏曲的逐音复刻。

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
