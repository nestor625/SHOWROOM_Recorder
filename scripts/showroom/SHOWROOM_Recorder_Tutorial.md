# SHOWROOM Recorder Tutorial

This tool automatically records Japanese idol live streams on SHOWROOM.

---

## 📋 Table of Contents

1. [Installation](#1-installation)
2. [Basic Operation](#2-basic-operation)
3. [Adding Channels](#3-adding-channels)
4. [Starting Recording](#4-starting-recording)
5. [Stopping Recording](#5-stopping-recording)
6. [FAQ](#6-faq)

---

## 1. Installation

### 1.1 Install Streamlink
Streamlink is the core recording tool.

**Method A: Windows Store (Recommended)**
```
Open Microsoft Store
Search "Streamlink"
Install
```

**Method B: Manual Install**
1. Go to https://streamlink.github.io/
2. Download Windows installer
3. Install

### 1.2 Check Python
```
Open PowerShell / CMD
Type: python --version
```
If it shows a version number, you're good. Otherwise, download from https://www.python.org/

---

## 2. Basic Operation

### 2.1 Launch App
```
Extract the zip file

Double-click:
SHOWROOM Recorder.bat
```

### 2.2 Interface

```
┌─────────────────────────────────────────────┐
│  SHOWROOM Recorder                          │
├─────────────────────────────────────────────┤
│  Save Location: [C:\Recordings ] [Browse]  │
├─────────────────────────────────────────────┤
│  Add Channel:                              │
│  URL:   [https://www.showroom-live.com/r/]│
│  Name:  [Hana Ogi                         ]│
│                              [Add]          │
├─────────────────────────────────────────────┤
│  Channels:                                  │
│  □ ME_HANA_OGI    Hana Ogi                 │
│  □ ME_SAYA_T...   Saya Tanizaki            │
├─────────────────────────────────────────────┤
│  [Record Selected] [Record All] [Stop All] │
├─────────────────────────────────────────────┤
│  Schedule Recording:                        │
│  Date & Time: [2026-03-05 19:00    ]       │
│                    [Schedule] [View Sched.] │
├─────────────────────────────────────────────┤
│  Currently Recording:                      │
│  - Hana Ogi                                │
└─────────────────────────────────────────────┘
```

---

## 3. Adding Channels

### Step 1: Find SHOWROOM URL
Example: https://www.showroom-live.com/r/ME_HANA_OGI

### Step 2: Enter Details
- **URL**: Paste the SHOWROOM link
- **Name**: Enter a display name (can be in Chinese/Japanese/English)

### Step 3: Click Add
The channel will appear in the list below.

---

## 4. Starting Recording

### Method A: Record Selected Channel
1. Click to select the channel(s) you want to record
2. Click **[Record Selected]**

### Method B: Record All
Click **[Record All]** - will record all added channels

### Confirmation
- The name will appear under "Currently Recording:"
- A CMD window will pop up - just leave it

---

## 5. Stopping Recording

### Stop Single Recording
1. Select the recording you want to stop under "Currently Recording:"
2. Click **[Stop Selected]**

### Stop All
Click **[Stop All]**

---

## 6. FAQ

### Q1: Where are the recordings saved?
Default: `C:\Recordings\`

Filename format:
`ME_HANA_OGI-SHOWROOM-2026-03-04_15_50.mp4`

### Q2: How to change quality?
Default is 1080p (best)

To change, run in PowerShell:
```bash
streamlink "URL" 720p -o "output.mp4"
```
Options: 1080p / 720p / 480p / 360p

### Q3: Can I turn off the PC while recording?
❌ No - the PC must stay on

### Q4: How to schedule automatic recording?
Use the **Schedule Recording** section in the app:
1. Select a channel
2. Pick date & time
3. Click **Schedule**

The app will create a Windows Task Scheduler job to auto-record at the set time.

### Q5: streamlink command not found?
Make sure Streamlink is installed correctly and added to PATH.

---

For issues, contact the maintainer
