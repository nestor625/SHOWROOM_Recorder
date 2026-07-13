# SHOWROOM Recorder Tutorial

This app helps you record Japanese idol live streams from SHOWROOM!

---

## Step 1: Download & Install

### Install Streamlink (Required)

1. Go to: https://streamlink.github.io/
2. Click **Windows Installer**
3. Follow the installation wizard

Streamlink is required for recording!

### Download SHOWROOM Recorder
1. Go to GitHub: https://github.com/nestor625/SHOWROOM_Recorder
2. Go to **Releases**
3. Download **SHOWROOM_Recorder_Win.zip**
4. Extract the zip file

---

## Step 2: How to Use

### Open the App
After extracting, you will see:
- `SHOWROOM Recorder.bat` ← **Double-click this!**

---

## Step 3: Add a Channel

### What's a Channel?
Each idol has their own URL, for example:
- Anna Yamamoto: `https://www.showroom-live.com/r/LOVE_ANNA_YAMAMOTO`

### How to Add:
1. **URL** field: Paste the idol's SHOWROOM link
2. **Name** field: Type a name (e.g., "Anna")
3. Click **Add** button
4. Channel will appear in the list below

---

## Step 4: Start Recording

### Record Single:
1. Click on the channel name (to highlight it)
2. Click **🔴 Record** button (or just double-click the channel)

### Record All:
1. Click **🔴 Record All** button

### Stop Recording:
1. In the **📡 Now Recording** panel, select the recording you want to stop
2. Click **⏹ Stop**. This stops only the selected recording.
3. **Stop All** is separate, explicit, and confirmed before it stops every tracked recording.

### Auto Check (background monitoring)

**Auto Check is off by default.** Select exactly **one channel at a time**, then click
**📡 Auto Check** to enable or disable monitoring for that channel. An enabled channel
shows the **📡** marker. Each enabled channel has its own worker, so multiple enabled
channels can record simultaneously.

Auto Check continues after closing the GUI and starts again at next login. Its worker
checks the channel every **60 seconds**, so recording can begin up to about one minute
after a channel goes live. Stopping an Auto Check recording disables that channel's
monitor. Use **Stop All** only when you explicitly want every recording
stopped.

### Auto Check files and status

Windows stores the channel and save-location settings here:

```
%APPDATA%\SHOWROOMRecorder\channels.json
%APPDATA%\SHOWROOMRecorder\settings.json
%APPDATA%\SHOWROOMRecorder\auto-check.json
```

Each enabled channel uses a Windows Task Scheduler task named `SHOWROOM_AUTO_<id>`.
Generated workers, status files, and logs are stored here:

```
%APPDATA%\SHOWROOMRecorder\jobs\auto-<id>.ps1
%APPDATA%\SHOWROOMRecorder\status\auto-<id>.json
%APPDATA%\SHOWROOMRecorder\logs\auto-<id>.log
```

The **📡** marker and **Now Recording** panel show the current status. To stop a failing
worker, select that channel and toggle **Auto Check** off, then inspect its matching log
file in `logs` before enabling it again.

---

## Where are the recordings?

Default location: **`C:\Recordings\`**

Filename format:
`name-SHOWROOM-yyyy-MM-dd_HH_mm.mp4`

Example:
`Anna-SHOWROOM-2026-03-04_22_00.mp4`

### How to change save location?
1. Click **📁 Browse…** button
2. Choose your preferred folder
3. Done!

Windows uses `yyyy-MM-dd_HH_mm` in filenames. Mac uses `%Y-%m-%d_%H%M`; these
timestamp formats remain platform-specific.

---

## 💾 Data Storage

### Channels
```
%APPDATA%\SHOWROOMRecorder\channels.json
```

### Settings (Save Location)
```
%APPDATA%\SHOWROOMRecorder\settings.json
```

---

## Schedule Recording (Timer)

### Want to record at a specific time?
1. Select channel
2. Set date and time
3. Click **Schedule** button

It will automatically start recording at the set time!

### View schedules:
1. Click **📅 View Scheduled** button
2. Shows all scheduled recordings

---

## FAQ

### Q1: Why can't I record?
- Make sure Streamlink is installed
- Make sure the channel is live
- Confirm `streamlink` is available on `PATH`. If Auto Check is failing, disable that
  channel, inspect its `logs\auto-<id>.log` file, and try again.

### Q2: Can I turn off the PC while recording?
❌ No - the PC must stay on

### Q3: How to change quality?
Default is 1080p

### Q4: Where to get help?
Open an issue on GitHub:
https://github.com/nestor625/SHOWROOM_Recorder/issues

### Windows validation boundary

Windows PowerShell 5.1 and WinForms cannot run on macOS. The Windows GUI and scheduled
workers therefore cannot be runtime-validated on macOS. Validate Windows behavior on a
real Windows machine by double-clicking `SHOWROOM Recorder.bat`; local source contracts
and Bash checks do not replace that runtime check.

---

## Contact

Questions? Open a GitHub Issue:
https://github.com/nestor625/SHOWROOM_Recorder/issues

---
Made with ❤️ for SHOWROOM fans
