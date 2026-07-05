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
- **⏹ Stop recording…** - 停止其中一個，或者全部停
- **📡 Live status** - 睇而家有咩正在錄緊
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

---

## ❓ 常見問題

### Q1: 點解錄唔到？
- 確保Streamlink已經install成功 (`brew install streamlink`)

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
