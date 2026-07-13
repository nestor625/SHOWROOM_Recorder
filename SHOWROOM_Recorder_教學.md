# SHOWROOM Recorder 中文教學

呢個App可以幫你錄製日本偶像既SHOWROOM直播！

---

## 📥 第一步：下載同安裝

### 安裝 Streamlink（必需要）

**手動安裝：**
1. 去呢度：https://streamlink.github.io/
2. 按 **Windows Installer**
3. 跟住setup指示安裝

Streamlink係錄影既核心軟件，冇佢就錄唔到！

### 2. 下載SHOWROOM Recorder
1. 去GitHub：https://github.com/nestor625/SHOWROOM_Recorder
2. 去 **Releases** 度
3. 下載 **SHOWROOM_Recorder_Win.zip**
4. 解壓縮個zip file

---

## 🎮 第二步：開始使用

### 1. 打開App
解壓縮之後，應該會見到呢啲files：
- `SHOWROOM Recorder.bat` ← **Double-click呢個**

### 2. 應該會見到呢個畫面
```
┌──────────────────────────────────────────────┐
│ 📺  SHOWROOM Recorder                          │ ← 標題列（粉紅色）
├──────────────────────────────────────────────┤
│ 💾 Save Location                               │
│   [C:\Recordings          ]    [📁 Browse…]    │
├──────────────────────────────────────────────┤
│ ➕ Add Channel                                 │
│   URL:[https://...]  Name:[山本杏奈]  [Add]    │
├──────────────────────────────────────────────┤
│ 🎬 Channels (3)                                │
│   ┌──────────────────────────────────────────┐│
│   │ (你加入既channel會喺度顯示)              ││
│   └──────────────────────────────────────────┘│
│   [🔴 Record] [🔴 Record All] [🗑 Delete]      │
├────────────────────────┬─────────────────────┤
│ ⏰ Schedule            │ 📡 Now Recording     │
│  Date:[..] Time:[..]   │  ┌─────────┐ ┌────┐  │
│  [⏰ Schedule]         │  │ (錄緊)  │ │ ⏹  │  │
│  [📅 View Scheduled]   │  └─────────┘ │Stop│  │
│                        │              └────┘  │
├────────────────────────┴─────────────────────┤
│  Ready                                         │ ← 狀態列
└──────────────────────────────────────────────┘
```

---

## 📝 第三步：加入Channel

### 咩係Channel？
每個偶像都有一個專屬既URL，例如：
- 山本杏奈：`https://www.showroom-live.com/r/LOVE_ANNA_YAMAMOTO`

### 加入步驟：
1. **URL** 欄位：貼上偶像既SHOWROOM連結
2. **Name** 欄位：例如輸入「山本杏奈」
3. 按 **Add** button
4. Channel就會加入下面既list度

---

## 🎬 第四步：開始錄影

### 錄單一個：
1. Click channel既名字（要highlighted）
2. 按 **🔴 Record** button（或者直接double-click個channel）

### 錄曬所有：
1. 按 **🔴 Record All** button

### 停止錄影：
1. 喺 **📡 Now Recording** 度選擇要停既recording
2. 按 **⏹ Stop** button，只會停止你選擇嗰一個recording
3. **Stop All** 係獨立按鈕，要明確按下並確認，先會停止全部recording

### Auto Check（背景監察）

**Auto Check 預設關閉**。喺 channel list 揀 **一次一個 channel**，再按
**📡 Auto Check** 開／關該 channel。開啟後會見到 **📡** 標記；每個 channel
都有自己獨立既worker，所以多個已開啟既 channel 可以 **同時錄影**。

關閉 GUI 後 Auto Check 仍然會繼續運作，並會喺下次登入時重新開始。worker 每隔
**60 seconds** 檢查一次，所以 channel 開始直播後，最遲大約一分鐘先開始錄影。
停止由 Auto Check 開始既錄影時，亦會 **停用該 channel** 既 Auto Check monitor。
只有你明確想停止全部錄影時，先使用 **Stop All**。

### Auto Check 設定、狀態、工作同紀錄檔

Windows 既 channel、儲存位置同 Auto Check 設定喺以下位置：

```
%APPDATA%\SHOWROOMRecorder\channels.json
%APPDATA%\SHOWROOMRecorder\settings.json
%APPDATA%\SHOWROOMRecorder\auto-check.json
```

每個已啟用 channel 都會有一個 Windows Task Scheduler 工作，名稱格式係
`SHOWROOM_AUTO_<id>`。產生既 worker、狀態檔同 log 喺以下位置：

```
%APPDATA%\SHOWROOMRecorder\jobs\auto-<id>.ps1
%APPDATA%\SHOWROOMRecorder\status\auto-<id>.json
%APPDATA%\SHOWROOMRecorder\logs\auto-<id>.log
```

channel 旁邊既 **📡** 標記同 **📡 Now Recording** 會顯示目前狀態。如果某個
worker 出錯，先揀該 channel 按 **📡 Auto Check** 停用，然後打開相同 id 既
`logs\auto-<id>.log` 檢查錯誤，再決定要唔要重新啟用。

---

## 📂 錄影檔案去邊？

預設位置：**`C:\Recordings\`**

Filename格式：
`名字-SHOWROOM-年月日_時間.mp4`

例如：
`山本杏奈-SHOWROOM-2026-03-04_22_00.mp4`

### 點樣改儲存位置？
1. Click **Browse** button
2. 揀你想要既folder
3. 得咗！

Windows 檔名時間格式係 `yyyy-MM-dd_HH_mm`；Mac 係 `%Y-%m-%d_%H%M`。
兩個平台既 timestamp 格式維持不同，唔需要相同。

---

## 💾 資料儲存位置

### Channels (你加入既channel)
```
%APPDATA%\SHOWROOMRecorder\channels.json
```

即係：
```
C:\Users\你的用户名\AppData\Roaming\SHOWROOMRecorder\channels.json
```

### 設定 (Save Location)
```
%APPDATA%\SHOWROOMRecorder\settings.json
```

Auto Check 開關設定：
```
%APPDATA%\SHOWROOMRecorder\auto-check.json
```

---

## ⏰ 預設錄影（定時錄）

### 想錄定時既野？
1. 選擇channel
2. 設定日期同時間
3. 按 **Schedule** button

到時會自動開始錄！

### 查看schedule：
1. 按 **📅 View Scheduled** button
2. 會顯示所有預設咗既錄影

---

## ❓ 常見問題

### Q1: 點解錄唔到？
- 確保Streamlink已經安裝
- 確保channel係直播緊
- 確保 `streamlink` 喺 `PATH` 入面。Auto Check 出錯時，先停用該 channel，
  再檢查 `logs\auto-<id>.log`。

### Q2: 錄既時候可以熄機？
❌ 唔可以，要部電腦開著

### Q3: 畫質可以點改？
預設1080p，如果想改可以去Google搵點改streamlink settings

### Q4: 有咩問題點算？
可以去GitHub開Issue或者搵我地幫手

### Windows 執行驗證範圍

Windows PowerShell 5.1 同 WinForms 唔可以喺 macOS 執行，所以 Windows GUI 同
scheduled worker 唔可以喺 Mac 做 runtime validation。要喺真正 Windows 電腦
雙擊 `SHOWROOM Recorder.bat` 驗證；Mac 上既 source contracts 同 Bash syntax
checks 唔代替 Windows runtime check。

---

## 📞 搵我地

有問題既話可以開GitHub Issue：
https://github.com/nestor625/SHOWROOM_Recorder/issues

---
Made with ❤️ for SHOWROOM fans
