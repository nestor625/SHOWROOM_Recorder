# Changelog

All notable changes to SHOWROOM Recorder are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

**Mac app** (`mac/showroom-recorder-mac-gui.scpt`, v3.0) — feature parity with Windows:
- Record multiple channels at once (multi-select) and **Record ALL**.
- **Stop recording** — stop a single recording or all of them.
- **Live status** — see which channels are currently recording.
- **Delete channel** from the UI (previously only by hand-editing the list file).
- **Schedule recording** via native `launchd` agents (survives display sleep); fires once
  then cleans itself up.
- **View / cancel scheduled** recordings.
- **Change save location** with a folder picker.
- Consolidated main menu now shows a live header: save path, channel count, and how many
  channels are recording.

**Windows app** (`win/showroom-recorder.ps1`, v2.0):
- Double-click a channel to record it.
- Graceful error handling when `streamlink` is missing/not on PATH (was a silent failure).
- Live channel count in the Channels section header.
- Color-coded status bar (recording / error / success).

**Docs:**
- `AGENTS.md` and `CLAUDE.md` — contributor/agent guidance.

### Changed

- **Windows GUI fully restyled** — SHOWROOM-pink header bar, sectioned GroupBoxes
  (Save Location / Add Channel / Channels / Schedule / Now Recording), flat color-coded
  buttons with hover states, and consistent Segoe UI typography.
- **Mac GUI** replaced the three-dialog flow with a single scrollable menu; dropped fragile
  system `.icns` icon references for standard note/caution/stop icons.
- Recording now uses `--retry-streams 30` on both platforms, so an early "Record" waits for
  the stream to go live.
- Tutorials updated to match the new UI (button labels, Mac menu list, Windows layout mockup).

### Fixed

- **Mac:** Cancel actions and scheduling failures no longer crash the menu loop.
- **Windows:** `win/showroom-recorder.ps1` is now saved as **UTF-8 with BOM** so emoji and
  em-dashes render correctly under Windows PowerShell 5.1 (BOM-less files were read as the
  ANSI codepage → mojibake).

### Known differences

- Output filename timestamp differs by platform: Mac `<name>-SHOWROOM-YYYY-MM-DD_HHMM.mp4`
  vs Windows `<name>-SHOWROOM-YYYY-MM-DD_HH_mm.mp4`. Not yet unified.

## [1.0.0] - 2026-07-05

- Initial release with Windows (PowerShell/WinForms) and Mac (AppleScript + Bash) recorders,
  channel management, save-location settings, and scheduled recording. Includes sample
  channel data.
