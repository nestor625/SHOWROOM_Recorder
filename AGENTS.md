# AGENTS.md

Guidance for AI coding agents working in this repo. Human-facing usage docs live in
the `SHOWROOM_Recorder_*.md` tutorials — this file is about *how to change the code safely*.

## What this is

A small, dependency-light **SHOWROOM live-stream recorder**. It's a thin GUI wrapper
around the [`streamlink`](https://streamlink.github.io/) CLI — the GUI just collects a
channel URL + name, builds a `streamlink <url> best -o <file> --force` command, and
launches/ schedules it. There is **no build system, no package manager, and no CI**.

## Layout

| Path | What it is |
|------|-----------|
| `mac/showroom-recorder-mac-gui.scpt` | **Primary Mac app** — AppleScript GUI (dialogs). |
| `mac/showroom-recorder-mac.sh` | Minimal Bash CLI fallback for Mac. |
| `win/showroom-recorder.ps1` | **Primary Windows app** — PowerShell + WinForms GUI. |
| `win/SHOWROOM Recorder.bat` | Launcher that runs the `.ps1` with `-ExecutionPolicy Bypass`. |
| `win/channels.json`, `win/settings.json` | Sample data shipped with the repo. |
| `SHOWROOM_Recorder_Tutorial.md` / `_教學.md` / `_教學_Mac.md` | End-user docs (EN / 繁中 / 繁中 Mac). |

The two platforms are **independent implementations** of the same idea. A change to one
usually needs a mirrored change to the other, plus the relevant tutorial(s).

## Runtime dependency

`streamlink` must be on `PATH`. Mac installs via `brew install streamlink`; Windows via
the official installer. Recording code should fail *gracefully* when it's missing (show a
message, don't crash the UI).

## Conventions & invariants — read before editing

- **Recording command** is always: `streamlink "<url>" best -o "<output>" --force`
  (optionally `--retry-streams 30` to wait for a stream to go live). Keep both platforms
  in sync.
- **Output filename**: `<name>-SHOWROOM-<timestamp>.mp4`. ⚠️ The timestamp format is
  *not identical* across platforms today — Mac uses `%Y-%m-%d_%H%M` (`2026-07-05_2200`),
  Windows uses `yyyy-MM-dd_HH_mm` (`2026-07-05_22_00`). Don't "unify" one silently;
  if you change it, change both and update the tutorials.
- **Data locations** (do not relocate without migrating existing users):
  - Mac: `~/.showroom_data/` — `channels.txt` (`url|name` per line), `save_path.txt`,
    `schedules.txt`, `jobs/` (generated wrapper scripts).
  - Windows: `%APPDATA%\SHOWROOMRecorder\` — `channels.json` (array of `{name,url}`),
    `settings.json` (`{savePath}`).
- **Scheduling** uses each OS's native scheduler, both survive display sleep:
  - Mac → per-job `launchd` LaunchAgent in `~/Library/LaunchAgents/com.showroom.rec.*`,
    a one-shot that records then unloads + deletes itself.
  - Windows → `Register-ScheduledTask` with name prefix `SHOWROOM_REC_`.
- Default save dir: `~/Recordings` (Mac) / `C:\Recordings` (Windows).

## Platform gotchas (these have bitten us)

- **Windows `.ps1` MUST be saved as UTF-8 *with BOM*.** The script contains emoji and
  em-dashes in string literals; Windows PowerShell 5.1 reads BOM-less files as the ANSI
  codepage and renders them as mojibake (e.g. `ðŸ"´ Record`). After any edit, verify:
  `head -c3 win/showroom-recorder.ps1 | xxd -p` → must be `efbbbf`.
  Re-add if lost: `printf '\xEF\xBB\xBF' | cat - f > f.tmp && mv f.tmp f`.
- **AppleScript** file is stored as *plain text* `.scpt` (not compiled). It's fine to edit
  as text. Emoji/`«class utf8»`/`≤`/`¬` are intentional — preserve them.
- WinForms buttons/GroupBoxes use emoji labels for parity with the Mac menu; expect
  monochrome glyph fallback on some Windows versions — that's acceptable.

## How to verify a change (no test suite exists)

- **Mac AppleScript — syntax check without running the GUI:**
  `osacompile -o /tmp/sr.scpt mac/showroom-recorder-mac-gui.scpt` (must print no error).
  Full check = run it: `osascript mac/showroom-recorder-mac-gui.scpt`.
- **Mac shell:** `bash -n mac/showroom-recorder-mac.sh` for a syntax check.
- **Windows PowerShell:** there is usually **no `pwsh` on the Mac dev box**, and WinForms
  can't run on macOS regardless — validate by close code review here, then confirm on a
  real Windows machine by double-clicking `win/SHOWROOM Recorder.bat`.
- **Generated `launchd` plists:** `plutil -lint <file>` when touching Mac scheduling.

## Scope / etiquette

- Keep it **dependency-free** — no new frameworks, package managers, or build steps.
- Preserve existing on-disk data formats so current users keep their channels/settings.
- Only `git commit`/push when the user asks.
