# SHOWROOM Recorder 中文教學 (Mac版)

呢個App可以幫你錄製日本偶像既SHOWROOM直播！

---

## 📥 第一步：下載同安裝

### 1. 安裝 Homebrew
打開 **Terminal** (應該喺Application > Utilities 度)， copy呢段code貼上去：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. 安裝 Streamlink
喺Terminal度打：

```bash
brew install streamlink
```

### 3. 下載SHOWROOM Recorder
1. 去GitHub：https://github.com/nestor625/SHOWROOM_Recorder
2. 去 **Releases** 度
3. 下載 **SHOWROOM_Recorder_Mac.zip**
4. 解壓縮個zip file

---

## 🎮 第二步：Mac App

### 方法好簡單：
1. 去release嗰度下載個Mac嘅zip
2. 打開個folder
3. click `SHOWROOM-Recorder.app`

---

## 📝 第三步：使用方法

打開整好既 `SHOWROOM Recorder.app`

主Menu頂會顯示：錄影儲存位置、有幾多個channel、而家有幾多個正在錄影。

### Menu有呢啲選擇：
- **🔴 Record…** - 揀一個或多個channel開始錄影
- **🔴 Record ALL** - 一次過錄晒所有channel
- **⏹ Stop recording…** - 停止其中一個；**Stop All** 要明確揀選並確認
- **📡 Live status** - 睇而家有咩正在錄緊
- **📡 Auto Check…** - 每個channel獨立開／關背景監察
- **➕ Add channel** - 加入channel
- **🗑 Delete channel…** - 揀走唔要既channel
- **⏰ Schedule recording…** - 設定時間，夾時自動錄
- **📅 View scheduled…** - 睇／取消已設定既定時錄影
- **📂 Open recordings folder** - 打開錄影folder
- **📁 Change save location…** - 揀錄影儲存去邊
- **📝 Edit channel list (raw)** - 直接編輯channel清單
- **❌ Quit** - 離開

### 加入Channel：
1. 揀 **➕ Add channel**
2. URL，例如：`https://www.showroom-live.com/r/LOVE_ANNA_YAMAMOTO`
3. Name，例如：`山本杏奈`
4. OK

### 開始錄影：
1. 揀 **🔴 Record…**
2. 揀你想錄既channel（可以㨂多過一個）
3. 會彈Terminal開始錄

### Auto Check（背景監察）：

**Auto Check 預設關閉**。喺清單度揀 **一次一個 channel**，再揀
**📡 Auto Check…** 開／關該 channel。開啟後會見到 **📡** 標記；每個 channel
都有自己既 launchd worker，所以多個已開啟既 channel 可以 **同時錄影**。

關閉 GUI 後 Auto Check 仍然會繼續運作，並會喺下次登入時重新開始。worker 每隔
**60 seconds** 檢查一次，所以 channel 開始直播後，最遲大約一分鐘先開始錄影。
停止由 Auto Check 開始既錄影時，亦會 **停用該 channel** 既 Auto Check monitor。
**Stop All** 係一個要明確揀選並確認既操作，只有想停止全部錄影時先使用。

### Auto Check 設定、狀態、工作同紀錄檔

Mac 既 channel、儲存位置同 Auto Check 設定喺：

```
~/.showroom_data/channels.txt
~/.showroom_data/save_path.txt
~/.showroom_data/auto_check.txt
```

每個已啟用 channel 會有以下獨立檔案。狀態、工作同 log 可以用 channel id
對照：

```
~/.showroom_data/jobs/auto-<id>.sh
~/.showroom_data/status/auto-<id>.status
~/.showroom_data/logs/auto-<id>.log
~/Library/LaunchAgents/com.showroom.auto.<id>.plist
```

**📡 Live status** 會顯示目前錄影；channel 名稱旁邊既 **📡** 代表 Auto Check
已啟用。如果某個worker出錯，先揀該 channel 開 **📡 Auto Check…** 停用，然後
檢查相同 id 既 `~/.showroom_data/logs/auto-<id>.log`，修正 Streamlink 或路徑
問題後先重新啟用。

### 定時錄影：
1. 揀 **⏰ Schedule recording…**
2. 揀channel
3. 打入時間（格式：`YYYY-MM-DD HH:MM`，例如 `2026-07-05 22:00`）
4. 夾到時間會自動開始錄（Mac要開著；就算screen sleep都會照錄）
5. 可以喺 **📅 View scheduled…** 度睇返或者取消

---

## 📂 錄影檔案去邊？

預設位置：**`~/Recordings/`**

Filename格式：
`名字-SHOWROOM-年月日_時間.mp4`

Mac 檔名時間格式係 `%Y-%m-%d_%H%M`；Windows 係 `yyyy-MM-dd_HH_mm`。
兩個平台既 timestamp 格式維持不同，唔需要相同。

---

## ❓ 常見問題

### Q1: 點解錄唔到？
- 確保Streamlink已經install成功 (`brew install streamlink`)
- 確保 `streamlink` 喺 `PATH` 入面。Auto Check 出錯時，先停用該 channel，
  再檢查 `~/.showroom_data/logs/auto-<id>.log`。

### Q2: 錄既時候可以熄機？
❌ 唔可以，要Mac開著

### Q3: Automator打唔開？
去Application度搵，或者Search都得

---

## 📞 搵我地

有問題可以去GitHub開Issue：
https://github.com/nestor625/SHOWROOM_Recorder/issues

---
Made with ❤️ for SHOWROOM fans
