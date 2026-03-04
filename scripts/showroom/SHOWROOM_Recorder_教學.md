# SHOWROOM 錄影工具教學

呢個工具可以自動錄製日本偶像既 SHOWROOM 直播。

---

## 📋 目錄

1. [安裝準備](#1-安裝準備)
2. [基本操作](#2-基本操作)
3. [加入Channel](#3-加入channel)
4. [開始錄影](#4-開始錄影)
5. [停止錄影](#5-停止錄影)
6. [常見問題](#6-常見問題)

---

## 1. 安裝準備

### 1.1 安裝 Streamlink
Streamlink 係錄影既核心工具。

**方法 A：Windows Store (推薦)**
```
打開 Microsoft Store
搜尋 "Streamlink"
Install
```

**方法 B：手動安裝**
1. 去 https://streamlink.github.io/
2. Download Windows installer
3. Install

### 1.2 確保 Python 已安裝
```
打開 PowerShell / CMD
輸入：python --version
```
如果顯示版本號就 OK，冇既要去 https://www.python.org/ download。

---

## 2. 基本操作

### 2.1 開啟 App
```
雙擊：
SHOWROOM Recorder.bat
```

### 2.2 界面介紹

```
┌─────────────────────────────────────────────┐
│  SHOWROOM Recorder                          │
├─────────────────────────────────────────────┤
│  Save Location: [C:\Recordings] [Browse] │
├─────────────────────────────────────────────┤
│  Add Channel:                              │
│  URL:   [https://www.showroom-live.com/r/]│
│  Name:  [はなちゃん                        ]│
│                              [Add]          │
├─────────────────────────────────────────────┤
│  Channels:                                  │
│  □ ME_HANA_OGI    はなちゃん                │
│  □ ME_SAYA_...    谷崎早耶                 │
├─────────────────────────────────────────────┤
│  [Record Selected] [Record All] [Stop All] │
├─────────────────────────────────────────────┤
│  定時錄影:                                  │
│  日期時間: [2026-03-05 19:00    ]          │
│                    [設定定時] [查看定時]     │
├─────────────────────────────────────────────┤
│  Currently Recording:                      │
│  - はなちゃん                               │
└─────────────────────────────────────────────┘
```

---

## 3. 加入 Channel

### Step 1: 搵 SHOWROOM URL
例如：https://www.showroom-live.com/r/ME_HANA_OGI

### Step 2: 輸入資料
- **URL** 欄位：貼上SHOWROOM link
- **Name** 欄位：輸入你想顯示既名（可以用中文/日文）

### Step 3: Click Add
channel會加入下面既list度。

---

## 4. 開始錄影

### 方法 A：錄製指定channel
1. 係 Channel List 度 Click 選中你想錄既channel
2. Click **[Record Selected]**

### 方法 B：錄製全部
Click **[Record All]** - 會錄曬所有加入左既channels

### 確認開始
- 「Currently Recording:」下面會顯示緊錄既名
- 會有CMD window彈出，唔洗理佢

---

## 5. 停止錄影

### 停單一個
1. 係 「Currently Recording」度揀你想停既
2. Click **[Stop Selected]**

### 停曬所有
Click **[Stop All]**

---

## 6. 常見問題

### Q1: 錄既片去邊？
預設：`C:\Recordings\`

Filename格式：
`ME_HANA_OGI-SHOWROOM-2026-03-04_15_50.mp4`

### Q2: 畫質可以點改？
預設1080p (best)

如果要改，去 PowerShell 度直接run：
```bash
streamlink "URL" 720p -o "output.mp4"
```
720p / 480p / 360p 得多種選擇。

### Q3: 錄既時候可以關機？
❌唔可以 - 要部機開著先錄到

### Q4: 點樣定時自動錄？
用App內既 **定時錄影** 功能：
1. 選擇channel
2. 設定日期時間
3. 撳 **設定定時**

App會用Windows Task Scheduler自動set時間，到時會自動開始錄影。

### Q5: streamlink command not found點算？
確保 Streamlink 已正確安裝同埋加咗入 PATH。

---

如有問題，搵 maintainer
