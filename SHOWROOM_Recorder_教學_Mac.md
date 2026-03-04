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

### Menu有呢啲選擇：
- **Add Channel** - 加入channel
- **Record** - 開始錄影
- **View Scheduled** - 睇定時錄影
- **Open Recordings Folder** - 開recordings folder
- **Setting -
- **Quit** - 離開 -
- **Open Folder** - 睇錄影 -
- **Edit List** - 加／睇返showroom link 

### 加入Channel：
1. 揀 **Add Channel**
2. URL，例如：`https://www.showroom-live.com/r/LOVE_ANNA_YAMAMOTO`
3. Name，例如：`山本杏奈`
4. OK

### 開始錄影：
1. 揀 **Record**
2. 揀你想錄既channel
3. 會彈Terminal開始錄

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
