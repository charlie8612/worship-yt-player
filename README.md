# Worship YT Player

教會敬拜用的 YouTube 播放工具。把詩歌切段、編排播放順序、做無縫 crossfade，
像現場指揮司琴一樣操控 YT 詩歌。

最終形態是 **Edge 擴充功能 + Native Helper**，目前處於 Phase 0（HTML 原型驗證
核心播放體驗）。詳細規劃見 [PROJECT.md](./PROJECT.md)。

## 快速開始（Phase 0 原型）

```bash
# 1. 下載本機平台的 yt-dlp + ffmpeg binary（零系統污染）
./scripts/fetch-binaries.sh

# 2. 抓一首詩歌的音訊跟字幕到 test/
./helper/bin/darwin-arm64/yt-dlp \
  --ffmpeg-location ./helper/bin/darwin-arm64/ffmpeg \
  -x --audio-format mp3 \
  --write-sub --sub-lang en-US \
  -o "test/song.%(ext)s" \
  "https://www.youtube.com/watch?v=..."

# 3. 開本地 http server
cd test && python3 -m http.server 8765

# 4. 瀏覽器開 http://localhost:8765/player.html
```

## 主要功能（已實作）

- 從字幕自動偵測歌曲段落（intro / verse / chorus / interlude / outro）
- 手動命名 / 微調段落時間 / 插入新段落
- 拼演奏順序：同一段可以加入多次（副歌 ×3 沒問題）
- Sequence 每一格可獨立調整 start / end / crossfade
- 兩個時間軸（來源音訊 + 演奏成品）可拖拉跳轉
- sample-accurate crossfade（Web Audio API）
- 匯出整段演奏成 WAV 檔案

## License & 版權

- 本工具的程式碼採 MIT。
- 工具本身不附帶任何詩歌音訊或字幕——使用者需自行從 YT 下載供個人 / 教會內部使用，
  版權風險由使用者承擔。
- 不建議將本工具用於商業用途或公開散佈下載的音訊內容。
