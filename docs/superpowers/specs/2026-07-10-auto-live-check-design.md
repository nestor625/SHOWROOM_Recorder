# Per-Channel Auto Live Check Design

## Goal

Add opt-in automatic live monitoring to the Mac and Windows SHOWROOM Recorder apps. A user can enable monitoring independently for each channel. Monitoring continues after the GUI closes, records every future broadcast, and remains enabled until the user disables it.

Multiple enabled channels may record simultaneously. Existing manual recording and scheduling behavior remains available.

## User Experience

Auto-check is off by default for every existing and newly added channel.

On Mac, the main menu gains `Auto Check...`. The user selects one channel and enables or disables monitoring. On Windows, the channel panel gains an `Auto Check` button that toggles monitoring for the single selected channel. Enabled channels display an auto-check marker in channel lists, and the main status shows how many channels are monitored.

The Now Recording view includes recordings started by background workers as well as recordings started manually. Each entry represents one exact recording process.

Stopping a selected recording stops only that recording. If it belongs to an auto-checked channel, the app first disables that channel's auto-check worker and then stops its recording, preventing it from restarting while the channel remains live. Windows receives a separate explicit Stop All action; no-selection behavior must not silently stop all Streamlink processes.

Deleting a channel disables and removes its auto-check worker before deleting the channel. Manual Record does not launch a duplicate Streamlink process for a channel already monitored automatically. Record All skips monitored channels and reports how many channels were already covered by auto-check.

## Persistent Data

Existing channel and settings formats remain unchanged.

Mac stores enabled channel URLs, one per line, in `~/.showroom_data/auto_check.txt`. Windows stores an array of enabled channel URLs in `%APPDATA%\SHOWROOMRecorder\auto-check.json`. Missing files mean no channels are enabled.

The URL is the persistent channel identity because it is already unique enough for the current app model and avoids changing shipped channel records. Job, worker, status, and log names use a filesystem-safe hash of the URL rather than the display name. Names therefore cannot inject shell syntax or create invalid scheduler identifiers.

Disabling or deleting a channel removes its URL from the auto-check settings and removes its generated worker artifacts. On startup, each GUI reconciles enabled URLs against existing channels and background jobs: stale settings are removed and missing jobs for valid enabled channels are recreated.

## Background Workers

Each enabled channel owns one independent background worker.

Mac creates a generated worker under `~/.showroom_data/jobs/` and a persistent LaunchAgent under `~/Library/LaunchAgents/`. Windows creates a generated worker under `%APPDATA%\SHOWROOMRecorder\jobs\` and a Scheduled Task with the `SHOWROOM_AUTO_` prefix. The Windows task starts at user logon and runs hidden.

Each worker checks the channel once every 60 seconds without downloading video:

```text
streamlink "<url>" best --stream-url
```

An unsuccessful probe means the channel is offline and the worker waits for the next interval. After a successful probe, the worker generates the timestamp and output path at the actual detection time, then starts the normal recording command:

```text
streamlink "<url>" best -o "<output>" --force --retry-streams 30
```

The short recording retry closes the race where a broadcast changes state between probing and starting the recorder. Streamlink exits when that broadcast ends. The worker then waits briefly and starts monitoring for the next broadcast. Independent workers allow multiple live channels to record concurrently and isolate a failure to one channel.

Worker creation is idempotent. Enabling an already enabled channel does not create a duplicate job. The output filename keeps the existing platform-specific timestamp format. Before starting a new recording, a worker avoids overwriting an existing filename generated within the same minute by waiting for a new timestamp.

## Runtime State

Each worker writes a small status record under the application's data directory. The record contains the channel URL and name, state (`waiting`, `recording`, or `error`), worker identity, current Streamlink PID when recording, output path when known, last error when applicable, and update time.

Status updates use a temporary file followed by an atomic replacement so the GUI does not read a partially written record. The GUI ignores malformed or stale status records and can repair them by reconciling the corresponding scheduler job.

Manual Windows recordings are retained in an in-memory map keyed by their exact process ID. The Now Recording list stores enough identity to stop the selected PID rather than calling `Stop-Process` for every process named `streamlink`. Auto-check recordings use the worker status record to identify their exact PID and owning channel.

## Enable, Disable, and Stop Ordering

Enabling follows this order:

1. Validate that Streamlink is available.
2. Generate the worker and scheduler definition using safely quoted values.
3. Register and start the background job.
4. Persist the channel URL as enabled.
5. Refresh the UI.

If any step before persistence fails, generated partial artifacts are cleaned up and the channel remains disabled.

Disabling follows the reverse ownership order: unload or unregister the job, stop that worker and its child recording if present, remove generated artifacts and status, remove the enabled URL, and refresh the UI. Repeating disable is safe.

Stopping a selected auto recording uses the same disable flow before terminating its child PID. Stopping a selected manual recording terminates only its stored PID and removes only its list entry. Stop All requires an explicit action and confirmation; it stops all tracked recordings and disables active auto-check workers so they do not immediately restart.

## Errors and Recovery

The GUI shows registration and persistence failures immediately. A channel is displayed as enabled only after its background job has been successfully registered and started.

Workers log missing Streamlink, network failures, plugin failures, and recording exits to a per-channel log. Recoverable failures wait 60 seconds and retry. Worker logs are bounded or truncated periodically so indefinite monitoring does not create unbounded files.

Scheduler definitions quote every URL, name, and path. Channel display names never appear as executable shell fragments. A worker failure does not stop other channels.

At login or GUI startup, scheduler restart behavior restores enabled workers. Reconciliation repairs missing jobs, removes orphaned jobs whose channels no longer exist, and leaves unrelated launchd jobs, Scheduled Tasks, and Streamlink processes untouched.

## Compatibility

The implementation adds no runtime dependencies beyond the existing Streamlink requirement and native OS tools. It preserves:

- Mac `channels.txt`, `save_path.txt`, and schedule files.
- Windows `channels.json` and `settings.json`.
- Mac `%Y-%m-%d_%H%M` output timestamps.
- Windows `yyyy-MM-dd_HH_mm` output timestamps.
- The existing `streamlink <url> best -o <output> --force` command shape.
- Windows PowerShell UTF-8-with-BOM encoding.

## Verification

Because the repository has no existing automated test suite, implementation begins with focused regression checks that fail before the feature exists. The checks cover the new per-channel settings paths, independent task identifiers, 60-second probe timing, use of `--stream-url`, the normal recording arguments, exact-PID selected-stop behavior, explicit Stop All behavior, and preservation of existing channel formats.

Mac verification includes AppleScript syntax checking where the local environment permits it, `bash -n` for generated worker fixtures and the existing shell fallback, and `plutil -lint` for generated LaunchAgent fixtures. Generated workers are exercised with a fake Streamlink executable and temporary data directory to verify waiting, recording state, retry, and independent channel behavior without contacting SHOWROOM.

Windows verification includes source-level regression checks, generated Scheduled Task argument inspection, and UTF-8 BOM verification. A real Windows machine must confirm WinForms interaction, Scheduled Task registration at login, simultaneous recordings, selected PID stopping, disable behavior, and recovery after restart because this Mac environment does not provide Windows PowerShell 5.1 or WinForms.

Documentation updates cover enabling and disabling one channel, background behavior after closing the GUI, concurrent recordings, stop semantics, data locations, and troubleshooting logs.
