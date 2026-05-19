# Worship YT Player

教會敬拜用的 YT 播放工具。把 YouTube 詩歌變成可以「像指揮司琴一樣」操控的素材——
跳段、重複、漸入漸出、無縫銜接、匯出成完整音檔。

最終形態：**Edge 擴充功能（教會 Windows 電腦）+ Native Helper（負責下載）**。

---

## 一、為什麼做這個

- 敬拜現場沒司琴時靠 YT 播放，但 YT 只能從頭播到尾
- 沒辦法在現場控制「副歌再來一次」、「進間奏」、「漸弱結束」
- 不同詩歌之間切換有空檔，整體體驗不像現場有人指揮
- 想做一個工具讓帶敬拜的人**事先編排**好播放順序、**現場觸發**段落切換

---

## 二、技術可行性決策

評估過五個方案，最後選 **Extension + Native Helper**：

| 方案 | 結論 |
|---|---|
| 單一 YT IFrame Player + `seekTo` | ❌ buffer gap 100~800ms，敬拜不能接受 |
| 雙 YT IFrame Player 預載交叉淡接 | ❌ 仍受 buffer 影響、無 sample-accurate、廣告風險 |
| tabCapture 抓 YT 分頁音訊 | ❌ 無法預先 buffer 兩段做 crossfade |
| 後端伺服器下載 | ❌ 要部署、版權公開化 |
| **Extension + Native Helper（下載音訊本地播）** | ✅ sample-accurate < 1ms、可離線、影片下架不影響 |

**核心理由**：敬拜現場容錯率為 0。Web Audio API 的離線/預載 + sample-accurate scheduling
是唯一能保證「永遠順」的選項。

---

## 三、目前進度

**Phase 0：核心想法驗證（HTML 原型）— 進行中**

不直接開始做插件，因為先要驗證「Web Audio crossfade 對下載下來的 YT 音訊，到底能不能做出順
的接段體驗」。這個問題的答案跟「是不是插件」完全無關，先用一個 HTML 把核心引擎調順。

當前檔案：`test/player.html` + `test/song.mp3` + `test/song.en-US.vtt`

### 已實作功能

- ✅ 載入本地 mp3（從 yt-dlp 下載）
- ✅ 來源音訊 scrubber：點擊跳轉、Preview from marker
- ✅ 字幕 (VTT) 解析 + **自動偵測段落**（依「沒歌詞的長空白」找段落邊界）
  - intro / outro / interlude 自動命名
  - verse / chorus / verse' 用「歌詞重複」粗略 heuristic 命名
- ✅ **Section palette（段落庫）**：自動產出後可手動命名、改 start/end、刪除、插入空白段
- ✅ **Sequence（演奏順序）**：從 palette 點 `+ Sequence` 加入；同一段可加多次（副歌 x3 沒問題）
- ✅ Sequence 每列獨立 start/end（同一段不同次可以播不同範圍），含 `↺ reset`
- ✅ Sequence 排序、刪除、每列預覽
- ✅ **Sequence timeline**：藍色 band + 紅色 crossfade 重疊區，可點擊跳轉
- ✅ 播放：`▶ Play from start` / `▶ Play from marker`（跳進序列任一點）
- ✅ **⤓ Export WAV**：OfflineAudioContext 渲染整段序列成 WAV 下載
  （跟現場播放是同一份程式邏輯 → 匯出的 WAV 就是聽到的演奏）

### 心智模型

```
原始音訊 (mp3)
    ↓ Auto-detect from VTT
Section Palette  ← 編輯素材：名字、start、end
    ↓ + Sequence
Sequence  ← 拼出實際演奏順序，每段可獨立微調時間、crossfade
    ↓ ▶ Play  /  ⤓ Export WAV
```

---

## 四、之後要做

### Phase 1 收尾（HTML 原型）
- [ ] 匯出 JSON 編排檔（palette + sequence 存檔，下次能 load 同一首歌）
- [ ] 多首歌串成一份 set list
- [ ] 匯出 MP3（lamejs，~50KB 編碼器）

### Phase 2：包裝成 Edge 擴充功能
- [ ] Native Messaging Host (Node.js)，stdio JSON 協議
- [ ] yt-dlp + ffmpeg 抽出到本地 binary（零系統污染：所有依賴都在專案目錄）
- [ ] Extension MV3 manifest + popup / side panel
- [ ] 把 HTML 原型的播放引擎搬進 extension（程式碼可直接複用）

### Phase 3：跨平台部署
- [ ] Windows 端 binary 下載腳本
- [ ] Node helper 用 `pkg` 編譯成單一 `.exe`
- [ ] Inno Setup / NSIS 做 Windows 安裝包
- [ ] 安裝包自動寫入 registry 註冊 native messaging host

### Phase 4：現場操作 UI
- [ ] 大字體「下一段」「重複本段」「淡出結束」按鈕
- [ ] 鍵盤快捷鍵（敬拜現場可能用筆電上台）
- [ ] 預覽模式 vs 正式模式區分

---

## 五、零系統污染原則

不用 brew、不用 conda、不用 venv、不需要使用者裝 Python。所有外部依賴：

- `yt-dlp`：standalone binary（GitHub Releases）放在 `helper/bin/<platform>/`
- `ffmpeg`：靜態編譯版 binary 放在同處
- Helper 寫成 Node.js，最終用 `pkg` 打包成單一 `.exe`，使用者連 Node 都不用裝

---

## 六、跨平台策略

開發：macOS arm64。部署目標：Windows x64（教會電腦）。

**真正會有差異的地方只在三處：**
1. binary 檔名（`yt-dlp` vs `yt-dlp.exe`）—— 一行 `process.platform` 解
2. Native Messaging Host 註冊位置（檔案 vs registry）—— 只影響安裝腳本
3. 安裝包格式（`.pkg` vs `.exe`）—— Phase 3 才處理

**95% 程式碼跨平台**，所以策略是「先在 Mac 把功能做完做穩，最後再處理 Windows 那 5%」。

---

## 七、版權聲明

- YT ToS 禁止下載音訊。本工具僅供教會內部使用、不公開散佈。
- **不會上架 Edge Add-ons 商店**，僅以 unpacked extension / 私下分享方式安裝。
- 詩歌版權通常透過 CCLI 在教會敬拜場合已授權；下載音訊用於現場演奏屬於灰色地帶，
  風險由使用者承擔。

---

## 八、目錄結構（目前）

```
ytplayer/
├── PROJECT.md              ← 本文件
├── test/                   ← Phase 0 原型
│   ├── player.html         ← 主程式
│   ├── song.mp3            ← 測試音檔（從 YT 下載）
│   └── song.en-US.vtt      ← 字幕（自動偵測段落用）
├── helper/
│   └── bin/darwin-arm64/   ← yt-dlp + ffmpeg（已下載）
├── scripts/
│   └── fetch-binaries.sh   ← Mac 端下載 binary
├── extension/              ← Phase 2 才會用到
└── docs/                   ← 規劃文件
```
