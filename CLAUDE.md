# CLAUDE.md

The full guidance for working in this repo lives in **[AGENTS.md](AGENTS.md)** —
project overview, layout, conventions/invariants, platform gotchas, and how to verify
changes. Read it first.

## Quick reminders (see AGENTS.md for details)

- Two independent implementations of the same app: `mac/showroom-recorder-mac-gui.scpt`
  (AppleScript) and `win/showroom-recorder.ps1` (PowerShell/WinForms). A change to one
  usually needs a mirrored change to the other, plus the relevant `SHOWROOM_Recorder_*.md`
  tutorial.
- **`win/showroom-recorder.ps1` must stay UTF-8 with BOM** (emoji/em-dashes break under
  Windows PowerShell 5.1 otherwise). Verify: `head -c3 win/showroom-recorder.ps1 | xxd -p`
  → `efbbbf`.
- No build system / package manager / CI. Keep it dependency-free (only `streamlink` at
  runtime). Preserve on-disk data formats. Commit only when asked.
- Verify AppleScript edits with `osacompile -o /tmp/sr.scpt mac/showroom-recorder-mac-gui.scpt`;
  WinForms can't run on macOS, so review the `.ps1` and confirm on real Windows.
