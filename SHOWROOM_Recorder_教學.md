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
┌─────────────────────────────────────────┐
│  SHOWROOM Recorder                      │
├─────────────────────────────────────────┤
│  Save Location: [C:\Recordings ] [Browse] │
├─────────────────────────────────────────┤
│  Add Channel:                          │
│  URL:   [https://www.showroom-live.com/r/] │
│  Name:  [例如：山本杏奈              ] │
│                              [Add]      │
├─────────────────────────────────────────┤
│  Channels:                              │
│  (呢度會顯示你加入既channel)           │
├─────────────────────────────────────────┤
│  [Record] [All] [Stop] [Delete] [View]│
├─────────────────────────────────────────┤
│  Currently Recording:                   │
│  (呢度會顯示緊錄緊既channel)           │
└─────────────────────────────────────────┘
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
2. 按 **Record** button

### 錄曬所有：
1. 按 **All** button

### 停止錄影：
1. 選擇要停既recording
2. 按 **Stop** button

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

---

## ⏰ 預設錄影（定時錄）

### 想錄定時既野？
1. 選擇channel
2. 設定日期同時間
3. 按 **Schedule** button

到時會自動開始錄！

### 查看schedule：
1. 按 **View** button
2. 會顯示所有預設咗既錄影

---

## ❓ 常見問題

### Q1: 點解錄唔到？
- 確保Streamlink已經安裝
- 確保channel係直播緊

### Q2: 錄既時候可以熄機？
❌ 唔可以，要部電腦開著

### Q3: 畫質可以點改？
預設1080p，如果想改可以去Google搵點改streamlink settings

### Q4: 有咩問題點算？
可以去GitHub開Issue或者搵我地幫手

---

## 📞 搵我地

有問題既話可以開GitHub Issue：
https://github.com/nestor625/SHOWROOM_Recorder/issues

---
Made with ❤️ for SHOWROOM fans
