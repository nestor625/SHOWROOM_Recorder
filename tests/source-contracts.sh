#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
win="$root/win/showroom-recorder.ps1"
mac="$root/mac/showroom-recorder-mac-gui.scpt"

require_literal() {
  local file=$1 text=$2
  grep -Fq -- "$text" "$file" || {
    printf 'missing required text in %s: %s\n' "$file" "$text" >&2
    return 1
  }
}

reject_literal() {
  local file=$1 text=$2
  if grep -Fq -- "$text" "$file"; then
    printf 'forbidden text in %s: %s\n' "$file" "$text" >&2
    return 1
  fi
}

windows_stop_contract() {
  require_literal "$win" '$global:manualRecordings = @{}'
  require_literal "$win" '$process = [System.Diagnostics.Process]::Start($psi)'
  require_literal "$win" 'process = $process'
  require_literal "$win" 'processId = $process.Id'
  require_literal "$win" 'function Stop-RecordingByProcessId([int]$processId)'
  require_literal "$win" '$entry = $global:manualRecordings[[string]$processId]'
  require_literal "$win" 'if ($entry.process.HasExited) {'
  require_literal "$win" 'if (-not $entry.process.HasExited) {'
  require_literal "$win" '$entry.process.Kill()'
  require_literal "$win" '$stopAllBtn.Text = "Stop All"'
  reject_literal "$win" 'Get-Process -Name streamlink -ErrorAction SilentlyContinue | Stop-Process -Force'
  selected_stop_orders_selection_before_refresh
}

windows_auto_contract() {
  require_literal "$win" '$autoCheckFile = Join-Path $dataDir "auto-check.json"'
  require_literal "$win" 'function Enable-AutoCheck'
  require_literal "$win" 'function Disable-AutoCheck'
  require_literal "$win" 'SHOWROOM_AUTO_'
  require_literal "$win" '--stream-url'
  require_literal "$win" '--retry-streams 30'
  require_literal "$win" 'New-ScheduledTaskTrigger -AtLogOn'
  require_literal "$win" 'function Get-InteractiveTaskPrincipal'
  require_literal "$win" 'New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited'
  require_literal "$win" '$autoCheckBtn.Text = "📡  Auto Check"'
  require_literal "$win" 'function Get-ChannelId'
  require_literal "$win" '[System.Security.Cryptography.SHA256]::Create()'
  require_literal "$win" '.Substring(0, 16).ToLowerInvariant()'
  require_literal "$win" '[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('
  require_literal "$win" 'Move-Item -LiteralPath $temporaryPath -Destination $autoCheckFile -Force'
  reject_literal "$win" 'Move-Item -LiteralPath $temporaryPath -Destination $Path -Force'
  require_literal "$win" 'Start-ScheduledTask -TaskName $taskName'
  require_literal "$win" 'Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal'
  require_literal "$win" 'Start-ScheduledTask -TaskName $taskName -ErrorAction Stop'
  require_literal "$win" '-ExecutionTimeLimit (New-TimeSpan -Seconds 0)'
  require_literal "$win" 'ConvertTo-Json -InputObject @($normalizedUrls)'
  reject_literal "$win" 'New-ScheduledTaskAction -Execute "cmd.exe"'
  require_literal "$win" 'function ConvertTo-WindowsCommandLineArgument'
  require_literal "$win" 'function Join-WindowsCommandLine'
  require_literal "$win" "-ArgumentList (Join-WindowsCommandLine @(\$url, 'best', '--stream-url'))"
  require_literal "$win" "-ArgumentList (Join-WindowsCommandLine @(\$url, 'best', '-o', \$output, '--force', '--retry-streams', '30'))"
  require_literal "$win" '$psi.Arguments = Join-WindowsCommandLine @('
  require_literal "$win" 'Start-Sleep -Seconds 60'
  require_literal "$win" 'streamStartUtc = $recording.StartTime.ToUniversalTime().ToString("o")'
  require_literal "$win" 'workerStartUtc = $workerProcess.StartTime.ToUniversalTime().ToString("o")'
  require_literal "$win" '$process.StartTime.ToUniversalTime().Ticks -ne $recordedStartTime.ToUniversalTime().Ticks'
  require_literal "$win" '$global:autoRecordings = @{}'
  require_literal "$win" '$global:channelRows = @()'
  require_literal "$win" '$global:recordingRows = @()'
  require_literal "$win" '$refreshTimer.Interval = 5000'
  require_literal "$win" 'Test-AutoCheckEnabled ([string]$ch.url)'
  require_literal "$win" 'Disable-AutoCheck ([string]$entry.url)'
  require_literal "$win" '$global:recordingRows[$recordingList.SelectedIndex]'
  reject_literal "$win" 'Get-Process -Name streamlink'
  windows_process_id_contract
  windows_argument_quoting_contract
  windows_enabled_ownership_contract
  windows_task_health_contract
  windows_disable_lifecycle_contract
  windows_reconciliation_error_contract
}

windows_ui_contract() {
  local auto_handler selected_handler all_handler delete_handler save_handler add_handler stop_handler disable_auto_handler refresh_channels

  require_literal "$win" '$autoCheckBtn.Location = New-Object System.Drawing.Point(458, 152)'
  require_literal "$win" '$autoCheckBtn.Size = New-Object System.Drawing.Size(150, 36)'
  require_literal "$win" 'Style-Btn $autoCheckBtn $clrSchedule'
  require_literal "$win" '$gChannels.Controls.Add($autoCheckBtn)'
  require_literal "$win" '$global:autoCheckRows = @()'
  require_literal "$win" 'function Refresh-AutoCheckList'
  require_literal "$win" '$autoCheckList = New-Object System.Windows.Forms.ListBox'
  require_literal "$win" '$disableAutoCheckBtn.Text = "Disable Selected"'
  require_literal "$win" '$gChannels.Controls.Add($autoCheckList)'
  require_literal "$win" '$gChannels.Controls.Add($disableAutoCheckBtn)'
  require_literal "$win" '$display = if ($isAutoChecked) { "📡  $($ch.name)" } else { [string]$ch.name }'
  require_literal "$win" '$channelList.Items.Add($display) | Out-Null'
  require_literal "$win" '$autoCheckCount = @(Get-AutoCheckUrls).Count'
  require_literal "$win" 'Auto Check: $autoCheckCount'

  auto_handler=$(awk '
    /^\$autoCheckBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  selected_handler=$(awk '
    /^\$recordSelectedBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  all_handler=$(awk '
    /^\$recordAllBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  delete_handler=$(awk '
    /^\$removeBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  save_handler=$(awk '
    /^\$saveBrowseBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  add_handler=$(awk '
    /^\$addBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  stop_handler=$(awk '
    /^\$stopBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  disable_auto_handler=$(awk '
    /^\$disableAutoCheckBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  refresh_channels=$(awk '
    /^function Refresh-ChannelList/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")

  printf '%s\n' "$auto_handler" | grep -Fq '$channelList.SelectedIndices.Count -ne 1' || {
    printf 'Auto Check must require exactly one selected channel\n' >&2
    return 1
  }
  printf '%s\n' "$auto_handler" | grep -Fq '$ch = $global:channelRows[$channelList.SelectedIndex]' || {
    printf 'Auto Check must map the selected row back to its channel entry\n' >&2
    return 1
  }
  printf '%s\n' "$auto_handler" | grep -Fq 'Disable-AutoCheck ([string]$ch.url)' || {
    printf 'Auto Check must disable the selected channel by URL\n' >&2
    return 1
  }
  printf '%s\n' "$auto_handler" | grep -Fq 'Enable-AutoCheck $ch' || {
    printf 'Auto Check must enable the selected channel entry\n' >&2
    return 1
  }
  printf '%s\n' "$disable_auto_handler" | grep -Fq '$autoCheckList.SelectedIndices.Count -ne 1' || {
    printf 'Auto Check list must require exactly one selected channel\n' >&2
    return 1
  }
  printf '%s\n' "$disable_auto_handler" | grep -Fq '$ch = $global:autoCheckRows[$autoCheckList.SelectedIndex]' || {
    printf 'Auto Check list must map the selected row back to its channel entry\n' >&2
    return 1
  }
  printf '%s\n' "$disable_auto_handler" | grep -Fq 'Disable-AutoCheck ([string]$ch.url)' || {
    printf 'Auto Check list must disable the selected channel by URL\n' >&2
    return 1
  }
  printf '%s\n' "$refresh_channels" | grep -Fq 'Refresh-AutoCheckList' || {
    printf 'Channel refresh must also refresh the enabled Auto Check list\n' >&2
    return 1
  }

  printf '%s\n' "$selected_handler" | grep -Fq '$skippedAutoCheckCount' || {
    printf 'Record Selected must count Auto Check channels it skips\n' >&2
    return 1
  }
  printf '%s\n' "$all_handler" | grep -Fq '$skippedAutoCheckCount' || {
    printf 'Record All must count Auto Check channels it skips\n' >&2
    return 1
  }
  printf '%s\n' "$selected_handler" | grep -Fq 'Test-AutoCheckEnabled ([string]$ch.url)' || {
    printf 'Record Selected must skip Auto Check channels by URL\n' >&2
    return 1
  }

  printf '%s\n' "$delete_handler" | grep -Fq '$failedIndices' || {
    printf 'Delete must retain channels whose Auto Check disable fails\n' >&2
    return 1
  }
  printf '%s\n' "$delete_handler" | grep -Fq 'if (Test-AutoCheckEnabled ([string]$ch.url) -and -not (Disable-AutoCheck ([string]$ch.url)))' || {
    printf 'Delete must disable selected Auto Check channels before removal\n' >&2
    return 1
  }
  printf '%s\n' "$delete_handler" | grep -Fq 'Reconcile-AutoChecks' || {
    printf 'Delete must reconcile Auto Check tasks after channel changes\n' >&2
    return 1
  }
  printf '%s\n' "$save_handler" | grep -Fq 'Reconcile-AutoChecks' || {
    printf 'Save-location changes must reconcile Auto Check tasks\n' >&2
    return 1
  }
  if printf '%s\n' "$add_handler" | grep -Fqi 'AutoCheck'; then
    printf 'Adding a channel must not mutate existing Auto Check state\n' >&2
    return 1
  fi
  printf '%s\n' "$stop_handler" | grep -Fq 'Stop-RecordingEntry $entry' || {
    printf 'selected Stop must use the Auto Check-aware stop path\n' >&2
    return 1
  }
}

windows_auto_check_append_contract() {
  local enable helper_calls

  require_literal "$win" 'function Add-AutoCheckUrl([string]$url)'
  require_literal "$win" '$enabledUrls = @(Get-AutoCheckUrls)'
  require_literal "$win" 'Save-AutoCheckUrls @($enabledUrls + $url)'
  reject_literal "$win" 'Save-AutoCheckUrls (@((Get-AutoCheckUrls) + [string]$ch.url))'

  enable=$(awk '
    /^function Enable-AutoCheck/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  helper_calls=$(printf '%s\n' "$enable" | grep -Fc 'Add-AutoCheckUrl ([string]$ch.url)')
  [ "$helper_calls" -eq 3 ] || {
    printf 'Enable-AutoCheck must use array-safe persistence for every successful enable path\n' >&2
    return 1
  }
}

windows_process_id_contract() {
  if grep -Eiq '\$pid([^[:alnum:]_]|$)|\.pid([^[:alnum:]_]|$)|(^|[[:space:];{])pid[[:space:]]*=' "$win"; then
    printf 'PowerShell process identifiers must not collide with the automatic $PID variable\n' >&2
    return 1
  fi
  require_literal "$win" 'processId = $recording.Id'
  require_literal "$win" 'workerProcessId = $workerProcess.Id'
  require_literal "$win" '$global:autoRecordings[$processId]'
}

windows_argument_quoting_contract() {
  local helper manual worker helper_count

  helper_count=$(grep -Fc 'function ConvertTo-WindowsCommandLineArgument' "$win")
  [ "$helper_count" -eq 2 ] || {
    printf 'Windows argument quoting helper must exist in the GUI and generated worker\n' >&2
    return 1
  }

  helper=$(awk '
    /^function ConvertTo-WindowsCommandLineArgument/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  manual=$(awk '
    /^function Start-Recording\(\$ch\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  worker=$(awk '
    /^    \$workerContent = @'\''$/ { in_worker = 1; next }
    in_worker && /^'\''@$/ { exit }
    in_worker { print }
  ' "$win")

  printf '%s\n' "$helper" | grep -Fq "if (\$argument -notmatch '[\\s\"]')" || {
    printf 'Windows argument helper must quote whitespace and double quotes\n' >&2
    return 1
  }
  printf '%s\n' "$helper" | grep -Fq '$backslashCount * 2 + 1' || {
    printf 'Windows argument helper must escape backslashes before embedded quotes\n' >&2
    return 1
  }
  printf '%s\n' "$helper" | grep -Fq '$backslashCount * 2' || {
    printf 'Windows argument helper must double trailing backslashes\n' >&2
    return 1
  }
  printf '%s\n' "$manual" | grep -Fq '$psi.Arguments = Join-WindowsCommandLine @(' || {
    printf 'manual Streamlink launch must use Windows argument quoting\n' >&2
    return 1
  }
  printf '%s\n' "$manual" | grep -Fq '[string]$ch.url' || {
    printf 'manual Streamlink launch must pass the URL as a distinct argument\n' >&2
    return 1
  }
  printf '%s\n' "$manual" | grep -Fq '$output' || {
    printf 'manual Streamlink launch must pass output as a distinct argument\n' >&2
    return 1
  }
  printf '%s\n' "$worker" | grep -Fq -- "-ArgumentList (Join-WindowsCommandLine @(\$url, 'best', '--stream-url'))" || {
    printf 'worker probe must use Windows argument quoting\n' >&2
    return 1
  }
  printf '%s\n' "$worker" | grep -Fq -- "-ArgumentList (Join-WindowsCommandLine @(\$url, 'best', '-o', \$output, '--force', '--retry-streams', '30'))" || {
    printf 'worker recording must use Windows argument quoting\n' >&2
    return 1
  }
}

windows_enabled_ownership_contract() {
  local reconcile

  reconcile=$(awk '
    /^function Reconcile-AutoChecks/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")

  printf '%s\n' "$reconcile" | grep -Fq '$enabledUrls = @(Get-AutoCheckUrls)' || {
    printf 'reconciliation must take managed ownership from enabled URLs\n' >&2
    return 1
  }
  printf '%s\n' "$reconcile" | grep -Fq '$managedIds = @($enabledUrls | ForEach-Object { Get-ChannelId ([string]$_) })' || {
    printf 'reconciliation must not retain tasks for configured-but-disabled channels\n' >&2
    return 1
  }
  if printf '%s\n' "$reconcile" | grep -Fq '$managedIds = @($global:channels'; then
    printf 'configured channels alone must not own Auto Check tasks\n' >&2
    return 1
  fi
}

windows_task_health_contract() {
  local health enable

  health=$(awk '
    /^function Test-AutoCheckTaskHealthy/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  enable=$(awk '
    /^function Enable-AutoCheck/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")

  [ -n "$health" ] || {
    printf 'missing Auto Check task health validation\n' >&2
    return 1
  }
  printf '%s\n' "$health" | grep -Fq '$task.State -eq '\''Disabled'\''' || {
    printf 'Auto Check health must reject disabled tasks\n' >&2
    return 1
  }
  printf '%s\n' "$health" | grep -Fq '$paths.worker' || {
    printf 'Auto Check health must validate the expected worker path\n' >&2
    return 1
  }
  printf '%s\n' "$health" | grep -Fq 'Test-StatusWorkerProcess' || {
    printf 'Auto Check health must reject stale worker processes\n' >&2
    return 1
  }
  printf '%s\n' "$enable" | grep -Fq 'Test-AutoCheckTaskHealthy $existingTask $paths' || {
    printf 'Enable-AutoCheck must validate existing tasks before accepting them\n' >&2
    return 1
  }
}

windows_disable_lifecycle_contract() {
  local disable stop_task stop_worker stop_recording unregister remove persist

  disable=$(awk '
    /^function Disable-AutoCheck/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")

  printf '%s\n' "$disable" | grep -Fq 'Stop-ScheduledTask -TaskName $paths.taskName -ErrorAction Stop' || {
    printf 'Disable-AutoCheck must surface Scheduled Task stop errors\n' >&2
    return 1
  }
  if printf '%s\n' "$disable" | grep -Fq 'Stop-ScheduledTask -TaskName $paths.taskName -ErrorAction SilentlyContinue'; then
    printf 'Disable-AutoCheck must not hide Scheduled Task stop errors\n' >&2
    return 1
  fi
  printf '%s\n' "$disable" | grep -Fq 'Stop-StatusWorker $status' || {
    printf 'Disable-AutoCheck must stop and verify the owned worker process\n' >&2
    return 1
  }
  printf '%s\n' "$disable" | grep -Fq 'Stop-StatusRecording $status' || {
    printf 'Disable-AutoCheck must stop and verify the owned recording process\n' >&2
    return 1
  }

  stop_task=$(printf '%s\n' "$disable" | grep -nF 'Stop-ScheduledTask -TaskName $paths.taskName -ErrorAction Stop' | head -n1 | cut -d: -f1)
  stop_worker=$(printf '%s\n' "$disable" | grep -nF 'Stop-StatusWorker $status' | head -n1 | cut -d: -f1)
  stop_recording=$(printf '%s\n' "$disable" | grep -nF 'Stop-StatusRecording $status' | head -n1 | cut -d: -f1)
  unregister=$(printf '%s\n' "$disable" | grep -nF 'Unregister-ScheduledTask' | head -n1 | cut -d: -f1)
  remove=$(printf '%s\n' "$disable" | grep -nF 'Remove-AutoCheckArtifacts $paths' | head -n1 | cut -d: -f1)
  persist=$(printf '%s\n' "$disable" | grep -nF 'Save-AutoCheckUrls' | head -n1 | cut -d: -f1)
  [ -n "$stop_task" ] && [ -n "$stop_worker" ] && [ -n "$stop_recording" ] && [ -n "$unregister" ] && [ -n "$remove" ] && [ -n "$persist" ] || {
    printf 'Disable-AutoCheck must stop task/runtime before unregistering, cleanup, and persistence\n' >&2
    return 1
  }
  if [ "$stop_task" -ge "$stop_worker" ] || [ "$stop_worker" -ge "$stop_recording" ] || [ "$stop_recording" -ge "$unregister" ] || [ "$unregister" -ge "$remove" ] || [ "$remove" -ge "$persist" ]; then
    printf 'Disable-AutoCheck must preserve settings/artifacts until every stop succeeds\n' >&2
    return 1
  fi
}

windows_reconciliation_error_contract() {
  local reconcile startup

  reconcile=$(awk '
    /^function Reconcile-AutoChecks/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  startup=$(awk '
    /^try \{$/ { candidate = 1; block = $0 ORS; next }
    candidate { block = block $0 ORS }
    candidate && /^}$/ {
      if (block ~ /Reconcile-AutoChecks/) { print block; exit }
      candidate = 0; block = ""
    }
  ' "$win")

  printf '%s\n' "$reconcile" | grep -Fq 'foreach ($url in $enabledUrls) {' || {
    printf 'reconciliation must iterate enabled channels explicitly\n' >&2
    return 1
  }
  printf '%s\n' "$reconcile" | grep -Fq 'catch {' || {
    printf 'reconciliation must catch failures per managed channel\n' >&2
    return 1
  }
  printf '%s\n' "$reconcile" | grep -Fq 'Write-Host "Auto-check reconciliation failed for $url' || {
    printf 'reconciliation must identify the failed channel and continue\n' >&2
    return 1
  }
  printf '%s\n' "$startup" | grep -Fq 'Reconcile-AutoChecks' || {
    printf 'GUI startup must contain reconciliation failures\n' >&2
    return 1
  }
  printf '%s\n' "$startup" | grep -Fq 'catch {' || {
    printf 'GUI startup must catch reconciliation failures\n' >&2
    return 1
  }
}

windows_task_3b_review_fixes_contract() {
  local disable stop_by_id stop_entry reconcile save_handler selected_handler all_handler startup start
  local worker_stop recording_stop first_try first_exit startup_reconcile startup_refresh

  disable=$(awk '
    /^function Disable-AutoCheck/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  stop_by_id=$(awk '
    /^function Stop-RecordingByProcessId/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  stop_entry=$(awk '
    /^function Stop-RecordingEntry/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  reconcile=$(awk '
    /^function Reconcile-AutoChecks/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  save_handler=$(awk '
    /^\$saveBrowseBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  selected_handler=$(awk '
    /^\$recordSelectedBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  all_handler=$(awk '
    /^\$recordAllBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")
  start=$(awk '
    /^function Start-Recording\(\$ch\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^}$/ { exit }
  ' "$win")
  startup=$(tail -n 40 "$win")

  printf '%s\n' "$disable" | grep -Fq 'function Disable-AutoCheck([string]$url, $expectedStatus = $null)' || {
    printf 'Disable-AutoCheck must accept the selected row\047s captured status\n' >&2
    return 1
  }
  printf '%s\n' "$disable" | grep -Fq '$status = if ($null -ne $expectedStatus) { $expectedStatus } else { Read-AutoStatus $url }' || {
    printf 'Disable-AutoCheck must use captured status instead of rereading a newer recording\n' >&2
    return 1
  }
  printf '%s\n' "$stop_entry" | grep -Fq 'Disable-AutoCheck ([string]$entry.url) $entry.status' || {
    printf 'selected Auto Stop must preserve the captured status through Disable-AutoCheck\n' >&2
    return 1
  }
  worker_stop=$(printf '%s\n' "$disable" | grep -nF 'Stop-StatusWorker $status' | head -n1 | cut -d: -f1)
  recording_stop=$(printf '%s\n' "$disable" | grep -nF 'Stop-StatusRecording $status' | head -n1 | cut -d: -f1)
  [ -n "$worker_stop" ] && [ -n "$recording_stop" ] && [ "$worker_stop" -lt "$recording_stop" ] || {
    printf 'Disable-AutoCheck must stop the captured worker before its captured recording\n' >&2
    return 1
  }

  first_try=$(printf '%s\n' "$stop_by_id" | grep -nF 'try {' | head -n1 | cut -d: -f1)
  first_exit=$(printf '%s\n' "$stop_by_id" | grep -nF 'if ($entry.process.HasExited) {' | head -n1 | cut -d: -f1)
  [ -n "$first_try" ] && [ -n "$first_exit" ] && [ "$first_try" -lt "$first_exit" ] || {
    printf 'Stop-RecordingByProcessId must catch HasExited races before inspecting the process\n' >&2
    return 1
  }
  printf '%s\n' "$stop_by_id" | grep -Fq 'catch {' || {
    printf 'Stop-RecordingByProcessId must catch process-exit races\n' >&2
    return 1
  }
  printf '%s\n' "$stop_by_id" | grep -Fq 'return $false' || {
    printf 'Stop-RecordingByProcessId must propagate process-exit failure\n' >&2
    return 1
  }
  printf '%s\n' "$stop_entry" | grep -Fq 'try {' || {
    printf 'Stop-RecordingEntry must catch downstream stop failures\n' >&2
    return 1
  }
  printf '%s\n' "$stop_entry" | grep -Fq 'catch {' || {
    printf 'Stop-RecordingEntry must return false on stop failure\n' >&2
    return 1
  }
  printf '%s\n' "$stop_entry" | grep -Fq 'return $false' || {
    printf 'Stop-RecordingEntry must propagate false on stop failure\n' >&2
    return 1
  }

  printf '%s\n' "$reconcile" | grep -Fq 'function Reconcile-AutoChecks([switch]$RebuildWorkers)' || {
    printf 'reconciliation must support a worker rebuild mode\n' >&2
    return 1
  }
  printf '%s\n' "$reconcile" | grep -Fq 'if ($RebuildWorkers) {' || {
    printf 'reconciliation must disable enabled workers before rebuilding them\n' >&2
    return 1
  }
  printf '%s\n' "$save_handler" | grep -Fq 'Reconcile-AutoChecks -RebuildWorkers' || {
    printf 'save-location changes must rebuild enabled Auto Check workers\n' >&2
    return 1
  }

  printf '%s\n' "$start" | grep -Fq 'return $true' || {
    printf 'Start-Recording must return true only after Streamlink launches\n' >&2
    return 1
  }
  printf '%s\n' "$start" | grep -Fq 'return $false' || {
    printf 'Start-Recording must return false when it cannot launch\n' >&2
    return 1
  }
  printf '%s\n' "$selected_handler" | grep -Fq 'if (Start-Recording $ch) {' || {
    printf 'Record Selected must count only successful starts\n' >&2
    return 1
  }
  printf '%s\n' "$all_handler" | grep -Fq 'if (Start-Recording $ch) {' || {
    printf 'Record All must count only successful starts\n' >&2
    return 1
  }
  printf '%s\n' "$selected_handler" | grep -Fq '$failedStartCount' || {
    printf 'Record Selected must report failed starts\n' >&2
    return 1
  }
  printf '%s\n' "$all_handler" | grep -Fq '$failedStartCount' || {
    printf 'Record All must report failed starts\n' >&2
    return 1
  }
  startup_reconcile=$(printf '%s\n' "$startup" | grep -nF 'Reconcile-AutoChecks' | head -n1 | cut -d: -f1)
  startup_refresh=$(printf '%s\n' "$startup" | grep -nF 'Refresh-ChannelList' | tail -n1 | cut -d: -f1)
  [ -n "$startup_reconcile" ] && [ -n "$startup_refresh" ] && [ "$startup_reconcile" -lt "$startup_refresh" ] || {
    printf 'startup must refresh channel markers after Auto Check reconciliation\n' >&2
    return 1
  }
}

mac_auto_contract() {
  require_literal "$mac" 'set autoCheckFile to dataDir & "/auto_check.txt"'
  require_literal "$mac" 'set mAuto to "📡  Auto Check…"'
  require_literal "$mac" 'on enableAutoCheck(theURL, theName)'
  require_literal "$mac" 'on disableAutoCheck(theURL, expectedPID)'
  require_literal "$mac" ' best --stream-url'
  require_literal "$mac" ' --force --retry-streams 30'
  require_literal "$mac" 'ThrottleInterval'
  require_literal "$mac" '<integer>60</integer>'
  reject_literal "$mac" 'StartInterval'
  reject_literal "$mac" 'pkill -f streamlink || true'
  strict_process_ownership_contract
  disable_auto_lifecycle_contract
  launchctl_target_contract
  enable_and_reconciliation_lifecycle_contract
  managed_artifact_contract
  recording_identity_contract
  mac_manual_auto_contract
  stop_recording_lifecycle_contract
  recording_count_contract
}

strict_process_ownership_contract() {
  local matcher ps_count

  matcher=$(awk '
    /^on statusPIDMatchesURL\(thePID, theURL, expectedOutput\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end statusPIDMatchesURL$/ { exit }
  ' "$mac")
  disable_handler=$(awk '
    /^on disableAutoCheck\(theURL, expectedPID\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end disableAutoCheck$/ { exit }
  ' "$mac")

  [ -n "$matcher" ] || {
    printf 'missing status PID ownership matcher in %s\n' "$mac" >&2
    return 1
  }
  [ -n "$disable_handler" ] || {
    printf 'missing disableAutoCheck handler in %s\n' "$mac" >&2
    return 1
  }

  printf '%s\n' "$matcher" | grep -Fq 'case ' || {
    printf 'status PID ownership matcher must keep numeric PID sanitization\n' >&2
    return 1
  }
  printf '%s\n' "$matcher" | grep -Fq 'set urlPattern to quoted form of' || {
    printf 'status PID ownership matcher must require the exact streamlink URL argument\n' >&2
    return 1
  }
  printf '%s\n' "$matcher" | grep -Fq 'commandLine=$(/bin/ps -p ' || {
    printf 'status PID ownership matcher must inspect the process command once\n' >&2
    return 1
  }
  printf '%s\n' "$matcher" | grep -Fq 'set outputPattern to quoted form of (" -o " & expectedOutput & " --force")' || {
    printf 'status PID ownership matcher must require the expected output path\n' >&2
    return 1
  }
  printf '%s\n' "$matcher" | grep -Fq 'grep -F -- streamlink' || {
    printf 'status PID ownership matcher must require a Streamlink process\n' >&2
    return 1
  }
  ps_count=$(printf '%s\n' "$matcher" | grep -Foc '/bin/ps -p ' || true)
  if [ "$ps_count" -ne 1 ]; then
    printf 'status PID ownership matcher must inspect one fresh command line\n' >&2
    return 1
  fi
}

mac_manual_auto_contract() {
  local recordings_handler delete_handler selected_skip all_skip removed disable write

  recordings_handler=$(awk '
    /^on runningRecordings\(\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end runningRecordings$/ { exit }
  ' "$mac")
  delete_handler=$(awk '
    /^on deleteChannel\(chNames, chURLs\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end deleteChannel\(chNames, chURLs\)$/ { exit }
  ' "$mac")

  printf '%s\n' "$recordings_handler" | grep -Fq 'jobsDir & "/manual"' || {
    printf 'Mac recording discovery must use app-owned manual PID markers\n' >&2
    return 1
  }
  require_literal "$mac" 'printf '\''%s|%s'\'' \"$streamPID\"'
  printf '%s\n' "$recordings_handler" | grep -Fq 'set manualStart to item 2 of markerParts' || {
    printf 'Mac recording discovery must read the manual process start token\n' >&2
    return 1
  }
  printf '%s\n' "$recordings_handler" | grep -Fq 'set commandStart to do shell script' || {
    printf 'Mac recording discovery must compare the current process start token\n' >&2
    return 1
  }
  selected_skip=$(grep -nF 'if my indexOf(item idx of chURLs, autoURLs) > 0 then' "$mac" | head -n1 | cut -d: -f1)
  all_skip=$(grep -nF 'if my indexOf(item i of chURLs, autoURLs) > 0 then' "$mac" | head -n1 | cut -d: -f1)
  [ -n "$selected_skip" ] && [ -n "$all_skip" ] || {
    printf 'Mac manual recording flows must skip Auto Check channels\n' >&2
    return 1
  }
  removed=$(printf '%s\n' "$delete_handler" | grep -nF 'set removedURLs to {}' | cut -d: -f1)
  disable=$(printf '%s\n' "$delete_handler" | grep -nF 'my disableAutoCheck(contents of theURL, "")' | cut -d: -f1)
  write=$(printf '%s\n' "$delete_handler" | grep -nF 'my writeAllChannels(newNames, newURLs)' | cut -d: -f1)
  [ -n "$removed" ] && [ -n "$disable" ] && [ -n "$write" ] && [ "$disable" -lt "$write" ] || {
    printf 'Mac delete must disable Auto Check before removing channel data\n' >&2
    return 1
  }
}

disable_auto_lifecycle_contract() {
  local disable_handler state_handler bootout_handler bootout error_handler ownership stop remove persist

  disable_handler=$(awk '
    /^on disableAutoCheck\(theURL, expectedPID\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end disableAutoCheck$/ { exit }
  ' "$mac")
  state_handler=$(awk '
    /^on autoServiceState\(label, userID\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end autoServiceState$/ { exit }
  ' "$mac")
  bootout_handler=$(awk '
    /^on bootoutAutoService\(label, userID\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end bootoutAutoService$/ { exit }
  ' "$mac")

  [ -n "$disable_handler" ] && [ -n "$state_handler" ] && [ -n "$bootout_handler" ] || {
    printf 'missing Auto Check launchd lifecycle handlers in %s\n' "$mac" >&2
    return 1
  }
  printf '%s\n' "$state_handler" | grep -Fq 'if errMsg contains "Could not find service"' || {
    printf 'Auto Check lifecycle must confirm an absent service explicitly\n' >&2
    return 1
  }
  printf '%s\n' "$state_handler" | grep -Fq 'error errMsg' || {
    printf 'Auto Check lifecycle must surface launchd state errors\n' >&2
    return 1
  }
  printf '%s\n' "$bootout_handler" | grep -Fq 'my autoServiceState(label, userID)' || {
    printf 'Auto Check bootout must branch on actual launchd state\n' >&2
    return 1
  }
  if printf '%s\n' "$bootout_handler" | grep -Fq '|| true'; then
    printf 'Auto Check bootout must not hide launchctl failures\n' >&2
    return 1
  fi

  bootout=$(printf '%s\n' "$disable_handler" | grep -nF 'my bootoutAutoService(label, userID)' | head -n1 | cut -d: -f1 || true)
  error_handler=$(printf '%s\n' "$disable_handler" | grep -nF 'my info("Auto Check failed"' | head -n1 | cut -d: -f1 || true)
  ownership=$(printf '%s\n' "$disable_handler" | grep -nF 'my statusPIDMatchesURL(statusPID, statusURL, statusOutput)' | head -n1 | cut -d: -f1 || true)
  stop=$(printf '%s\n' "$disable_handler" | grep -nF 'my stopPID(statusPID)' | head -n1 | cut -d: -f1 || true)
  remove=$(printf '%s\n' "$disable_handler" | grep -nF 'my removeAutoArtifacts(workerPath, plistPath, statusPath)' | head -n1 | cut -d: -f1 || true)
  persist=$(printf '%s\n' "$disable_handler" | grep -nF 'my writeAutoURLs(kept)' | head -n1 | cut -d: -f1 || true)
  [ -n "$bootout" ] && [ -n "$error_handler" ] && [ -n "$ownership" ] && [ -n "$stop" ] && [ -n "$remove" ] && [ -n "$persist" ] || {
    printf 'disableAutoCheck must report bootout failure before validated stopping and cleanup\n' >&2
    return 1
  }
  if [ "$bootout" -ge "$error_handler" ] || [ "$error_handler" -ge "$ownership" ] || [ "$ownership" -ge "$stop" ] || [ "$stop" -ge "$remove" ] || [ "$remove" -ge "$persist" ]; then
    printf 'disableAutoCheck must unload, validate, stop, remove artifacts, then update persistence\n' >&2
    return 1
  fi
}

launchctl_target_contract() {
  local state_handler bootout_handler enable_handler

  state_handler=$(awk '
    /^on autoServiceState\(label, userID\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end autoServiceState$/ { exit }
  ' "$mac")
  bootout_handler=$(awk '
    /^on bootoutAutoService\(label, userID\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end bootoutAutoService$/ { exit }
  ' "$mac")
  enable_handler=$(awk '
    /^on enableAutoCheck\(theURL, theName\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end enableAutoCheck$/ { exit }
  ' "$mac")

  [ -n "$state_handler" ] && [ -n "$bootout_handler" ] && [ -n "$enable_handler" ] || {
    printf 'missing Auto Check launchctl handlers in %s\n' "$mac" >&2
    return 1
  }
  require_literal "$mac" 'on autoServiceTarget(label, userID)'
  printf '%s\n' "$state_handler" | grep -Fq 'quoted form of (my autoServiceTarget(label, userID))' || {
    printf 'Auto Check lifecycle must quote the exact launchd service target\n' >&2
    return 1
  }
  printf '%s\n' "$state_handler" | grep -Fq ' 2>&1' || {
    printf 'Auto Check lifecycle must capture launchctl print diagnostics\n' >&2
    return 1
  }
  if printf '%s\n' "$state_handler" | grep -Fq '>/dev/null'; then
    printf 'Auto Check lifecycle must not discard launchctl print diagnostics\n' >&2
    return 1
  fi
  printf '%s\n' "$state_handler" | grep -Fq 'if errMsg contains "Could not find service" or errMsg contains "No such process" then return "absent"' || {
    printf 'Auto Check lifecycle must limit absent state to known diagnostics\n' >&2
    return 1
  }
  printf '%s\n' "$bootout_handler" | grep -Fq 'quoted form of (my autoServiceTarget(label, userID))' || {
    printf 'Auto Check bootout must quote the exact launchd service target\n' >&2
    return 1
  }
  printf '%s\n' "$enable_handler" | grep -Fq 'quoted form of ("gui/" & userID)' || {
    printf 'Auto Check bootstrap must quote the launchd user domain\n' >&2
    return 1
  }
  printf '%s\n' "$enable_handler" | grep -Fq 'quoted form of (my autoServiceTarget(label, userID))' || {
    printf 'Auto Check kickstart must quote the exact launchd service target\n' >&2
    return 1
  }
}

enable_and_reconciliation_lifecycle_contract() {
  local enable_handler reconcile_handler state check bootstrap kickstart persist cleanup

  enable_handler=$(awk '
    /^on enableAutoCheck\(theURL, theName\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end enableAutoCheck$/ { exit }
  ' "$mac")
  reconcile_handler=$(awk '
    /^on reconcileAutoChecks\(chNames, chURLs\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end reconcileAutoChecks$/ { exit }
  ' "$mac")

  [ -n "$enable_handler" ] && [ -n "$reconcile_handler" ] || {
    printf 'missing Auto Check enable/reconciliation handlers in %s\n' "$mac" >&2
    return 1
  }
  printf '%s\n' "$enable_handler" | grep -Fq 'set serviceState to my autoServiceState(label, userID)' || {
    printf 'enableAutoCheck must use actual launchd state, not files alone\n' >&2
    return 1
  }
  printf '%s\n' "$enable_handler" | grep -Fq 'my plistIsValid(plistPath)' || {
    printf 'enableAutoCheck must validate an existing plist\n' >&2
    return 1
  }
  printf '%s\n' "$enable_handler" | grep -Fq 'my cleanupAutoCheck(label, userID, workerPath, plistPath, statusPath)' || {
    printf 'enableAutoCheck must clean up generated artifacts after failure\n' >&2
    return 1
  }
  state=$(printf '%s\n' "$enable_handler" | grep -nF 'set serviceState to my autoServiceState(label, userID)' | head -n1 | cut -d: -f1 || true)
  check=$(printf '%s\n' "$enable_handler" | grep -nF 'if serviceState is "loaded" and artifactsAreValid and (my isAutoEnabled(theURL)) then return true' | head -n1 | cut -d: -f1 || true)
  bootstrap=$(printf '%s\n' "$enable_handler" | grep -nF 'quoted form of ("gui/" & userID)' | head -n1 | cut -d: -f1 || true)
  kickstart=$(printf '%s\n' "$enable_handler" | grep -nF 'quoted form of (my autoServiceTarget(label, userID))' | head -n1 | cut -d: -f1 || true)
  persist=$(printf '%s\n' "$enable_handler" | grep -nF 'my writeAutoURLs(urls)' | head -n1 | cut -d: -f1 || true)
  cleanup=$(printf '%s\n' "$enable_handler" | grep -nF 'my cleanupAutoCheck(label, userID, workerPath, plistPath, statusPath)' | head -n1 | cut -d: -f1 || true)
  [ -n "$state" ] && [ -n "$check" ] && [ -n "$bootstrap" ] && [ -n "$kickstart" ] && [ -n "$persist" ] && [ -n "$cleanup" ] || {
    printf 'enableAutoCheck must validate state, bootstrap/kickstart, persist, and clean up failures\n' >&2
    return 1
  }
  if [ "$state" -ge "$check" ] || [ "$check" -ge "$bootstrap" ] || [ "$bootstrap" -ge "$kickstart" ] || [ "$kickstart" -ge "$persist" ] || [ "$persist" -ge "$cleanup" ]; then
    printf 'enableAutoCheck must persist after kickstart inside its cleanup boundary\n' >&2
    return 1
  fi

  require_literal "$mac" 'on managedAutoArtifactIDs()'
  require_literal "$mac" "-name 'com.showroom.auto.*.plist'"
  require_literal "$mac" "-name 'auto-*.sh'"
  require_literal "$mac" 'on removeOrphanAutoCheck(ident)'
  printf '%s\n' "$reconcile_handler" | grep -Fq 'set artifactIDs to my managedAutoArtifactIDs()' || {
    printf 'reconciliation must scan managed launchd and worker artifacts\n' >&2
    return 1
  }
  printf '%s\n' "$reconcile_handler" | grep -Fq 'my enableAutoCheck(urlText, item idx of chNames)' || {
    printf 'reconciliation must recreate valid enabled jobs\n' >&2
    return 1
  }
  printf '%s\n' "$reconcile_handler" | grep -Fq 'my removeOrphanAutoCheck(contents of artifactID)' || {
    printf 'reconciliation must remove unmanaged Auto Check artifacts\n' >&2
    return 1
  }
  if printf '%s\n' "$reconcile_handler" | grep -Fq 'set isComplete'; then
    printf 'reconciliation must not treat worker/plist files as loaded-service proof\n' >&2
    return 1
  fi
}

managed_artifact_contract() {
  local managed_handler invalid_remover orphan_remover invalid_check label

  managed_handler=$(awk '
    /^on managedAutoArtifactIDs\(\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end managedAutoArtifactIDs$/ { exit }
  ' "$mac")
  invalid_remover=$(awk '
    /^on removeInvalidAutoArtifact\(artifactPath\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end removeInvalidAutoArtifact$/ { exit }
  ' "$mac")
  orphan_remover=$(awk '
    /^on removeOrphanAutoCheck\(ident\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end removeOrphanAutoCheck$/ { exit }
  ' "$mac")

  [ -n "$managed_handler" ] && [ -n "$invalid_remover" ] && [ -n "$orphan_remover" ] || {
    printf 'missing managed-artifact cleanup handlers in %s\n' "$mac" >&2
    return 1
  }
  require_literal "$mac" 'on isValidAutoArtifactID(ident)'
  require_literal "$mac" "grep -Eq '^[0-9a-f]{16}$'"
  printf '%s\n' "$managed_handler" | grep -Fq 'if my isValidAutoArtifactID(ident) then' || {
    printf 'managed Auto Check artifacts must validate IDs before reconciliation\n' >&2
    return 1
  }
  printf '%s\n' "$managed_handler" | grep -Fq 'my removeInvalidAutoArtifact(contents of artifactPath)' || {
    printf 'managed invalid Auto Check artifacts must be removed by their file path\n' >&2
    return 1
  }

  printf '%s\n' "$invalid_remover" | grep -Fq '/bin/rm -f ' || {
    printf 'invalid Auto Check artifacts must be removed\n' >&2
    return 1
  }
  printf '%s\n' "$invalid_remover" | grep -Fq 'quoted form of artifactPath' || {
    printf 'invalid Auto Check artifacts must be safely quoted\n' >&2
    return 1
  }
  if printf '%s\n' "$invalid_remover" | grep -Fq '/bin/launchctl'; then
    printf 'invalid Auto Check artifacts must not be sent to launchctl\n' >&2
    return 1
  fi
  invalid_check=$(printf '%s\n' "$orphan_remover" | grep -nF 'if not (my isValidAutoArtifactID(ident)) then return false' | head -n1 | cut -d: -f1 || true)
  label=$(printf '%s\n' "$orphan_remover" | grep -nF 'set label to "com.showroom.auto." & ident' | head -n1 | cut -d: -f1 || true)
  [ -n "$invalid_check" ] && [ -n "$label" ] && [ "$invalid_check" -lt "$label" ] || {
    printf 'orphan cleanup must validate artifact IDs before constructing a launchd label\n' >&2
    return 1
  }
}

recording_identity_contract() {
  local recordings_handler stop_handler

  recordings_handler=$(awk '
    /^on runningRecordings\(\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end runningRecordings$/ { exit }
  ' "$mac")
  stop_handler=$(awk '
    /^on stopRecording\(\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end stopRecording$/ { exit }
  ' "$mac")

  printf '%s\n' "$recordings_handler" | grep -Fq '[PID "' || {
    printf 'recording labels must include their exact PID\n' >&2
    return 1
  }
  printf '%s\n' "$stop_handler" | grep -Fq 'set thePID to item idx of pids' || {
    printf 'selected Stop must map the unique label back to its PID\n' >&2
    return 1
  }
  printf '%s\n' "$stop_handler" | grep -Fq 'set owners to item 3 of recs' || {
    printf 'selected Stop must retain the displayed ownership token\n' >&2
    return 1
  }
  printf '%s\n' "$stop_handler" | grep -Fq 'my stopOwnedRecording(item idx of owners, thePID)' || {
    printf 'selected Stop must validate the displayed ownership token before killing\n' >&2
    return 1
  }
}

stop_recording_lifecycle_contract() {
  local stop_handler all_result selected_result selected_success selected_failure all_success all_failure

  stop_handler=$(awk '
    /^on stopRecording\(\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end stopRecording$/ { exit }
  ' "$mac")

  [ -n "$stop_handler" ] || {
    printf 'missing stopRecording handler in %s\n' "$mac" >&2
    return 1
  }
  all_result=$(printf '%s\n' "$stop_handler" | grep -nF 'if (my stopOwnedRecording(item i of owners, item i of pids)) is false then set allStopped to false' | head -n1 | cut -d: -f1 || true)
  selected_result=$(printf '%s\n' "$stop_handler" | grep -nF 'set stopSucceeded to my stopOwnedRecording(item idx of owners, thePID)' | head -n1 | cut -d: -f1 || true)
  selected_success=$(printf '%s\n' "$stop_handler" | grep -nF 'if stopSucceeded then' | head -n1 | cut -d: -f1 || true)
  selected_failure=$(printf '%s\n' "$stop_handler" | grep -nF 'my info("Stop failed"' | tail -n1 | cut -d: -f1 || true)
  all_success=$(printf '%s\n' "$stop_handler" | grep -nF 'if allStopped then' | head -n1 | cut -d: -f1 || true)
  all_failure=$(printf '%s\n' "$stop_handler" | grep -nF 'my info("Stop failed"' | head -n1 | cut -d: -f1 || true)
  [ -n "$all_result" ] && [ -n "$selected_result" ] && [ -n "$selected_success" ] && [ -n "$selected_failure" ] && [ -n "$all_success" ] && [ -n "$all_failure" ] || {
    printf 'Stop selected and Stop All must propagate Auto Check disable failures\n' >&2
    return 1
  }
  if [ "$all_result" -ge "$all_success" ] || [ "$all_success" -ge "$all_failure" ] || [ "$selected_result" -ge "$selected_success" ] || [ "$selected_success" -ge "$selected_failure" ]; then
    printf 'Stop selected and Stop All must report success only after Auto Check disable succeeds\n' >&2
    return 1
  fi
}

recording_count_contract() {
  local count_handler

  count_handler=$(awk '
    /^on countRunning\(\)/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^end countRunning$/ { exit }
  ' "$mac")

  printf '%s\n' "$count_handler" | grep -Fq 'set recs to my runningRecordings()' || {
    printf 'countRunning must count only app-owned recordings\n' >&2
    return 1
  }
  if printf '%s\n' "$count_handler" | grep -Fq 'ps -Axo'; then
    printf 'countRunning must not scan unrelated system-wide Streamlink processes\n' >&2
    return 1
  fi

  require_literal "$mac" 'on stopPID(thePID)'
  require_literal "$mac" '/bin/kill '
}

mac_channel_storage_contract() {
  require_literal "$mac" "set AppleScript's text item delimiters to \"|\""
  require_literal "$mac" 'set parts to text items of s'
  require_literal "$mac" 'set end of urlList to item 1 of parts'
  require_literal "$mac" 'set end of nameList to item 2 of parts'
}

windows_channel_storage_contract() {
  local add_handler

  add_handler=$(awk '
    /^\$addBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")

  printf '%s\n' "$add_handler" | grep -Fq '$global:channels += @{url = $urlBox.Text; name = $nameBox.Text}' || {
    printf 'Windows channel creation must keep the existing url/name object shape\n' >&2
    return 1
  }
  printf '%s\n' "$add_handler" | grep -Fq '$global:channels | ConvertTo-Json -Depth 10 | Out-File -FilePath $channelsFile -Encoding UTF8' || {
    printf 'Windows channel persistence must serialize the existing channel objects\n' >&2
    return 1
  }
  if grep -Eiq 'autoCheck[[:space:]]*=' "$win"; then
    printf 'Windows channel objects must not require autoCheck properties\n' >&2
    return 1
  fi
}

documentation_contract() {
  local windows_doc="$root/SHOWROOM_Recorder_Tutorial.md"
  local zh_doc="$root/SHOWROOM_Recorder_教學.md"
  local mac_doc="$root/SHOWROOM_Recorder_教學_Mac.md"
  local changelog="$root/CHANGELOG.md"

  require_literal "$windows_doc" 'Auto Check is off by default'
  require_literal "$windows_doc" 'one channel at a time'
  require_literal "$windows_doc" 'after closing the GUI'
  require_literal "$windows_doc" 'at next login'
  require_literal "$windows_doc" '60 seconds'
  require_literal "$windows_doc" 'record simultaneously'
  require_literal "$windows_doc" 'disables that channel'
  require_literal "$windows_doc" 'Stop All'
  require_literal "$windows_doc" 'SHOWROOM_AUTO_'
  require_literal "$windows_doc" 'Windows PowerShell 5.1'
  require_literal "$windows_doc" 'cannot be runtime-validated on macOS'
  require_literal "$windows_doc" 'yyyy-MM-dd_HH_mm'
  require_literal "$windows_doc" '%Y-%m-%d_%H%M'
  require_literal "$windows_doc" '%APPDATA%\SHOWROOMRecorder\auto-check.json'
  reject_literal "$windows_doc" 'name-SHOWROOM-YYYY-MM-DD_HH_MM.mp4'
  reject_literal "$windows_doc" 'Windows uses `YYYY-MM-DD_HH_mm`'

  require_literal "$zh_doc" 'Auto Check'
  require_literal "$zh_doc" '預設關閉'
  require_literal "$zh_doc" '一次一個 channel'
  require_literal "$zh_doc" '關閉 GUI 後'
  require_literal "$zh_doc" '下次登入'
  require_literal "$zh_doc" '60 seconds'
  require_literal "$zh_doc" '同時錄影'
  require_literal "$zh_doc" '停用該 channel'
  require_literal "$zh_doc" 'Stop All'
  require_literal "$zh_doc" 'Windows PowerShell 5.1'
  require_literal "$zh_doc" 'yyyy-MM-dd_HH_mm'
  require_literal "$zh_doc" '%Y-%m-%d_%H%M'
  require_literal "$zh_doc" '%APPDATA%\SHOWROOMRecorder\auto-check.json'

  require_literal "$mac_doc" 'Auto Check'
  require_literal "$mac_doc" '預設關閉'
  require_literal "$mac_doc" '一次一個 channel'
  require_literal "$mac_doc" '關閉 GUI 後'
  require_literal "$mac_doc" '下次登入'
  require_literal "$mac_doc" '60 seconds'
  require_literal "$mac_doc" '同時錄影'
  require_literal "$mac_doc" '停用該 channel'
  require_literal "$mac_doc" 'Stop All'
  require_literal "$mac_doc" '%Y-%m-%d_%H%M'
  require_literal "$mac_doc" 'yyyy-MM-dd_HH_mm'
  require_literal "$mac_doc" '~/.showroom_data/auto_check.txt'

  require_literal "$changelog" '**Auto Check (Mac and Windows):**'
  require_literal "$changelog" 'background monitoring is off by default'
  require_literal "$changelog" 'enabled per channel'
  require_literal "$changelog" 'at next login'
  require_literal "$changelog" 'record simultaneously'
  require_literal "$changelog" 'Selected **Stop** now stops only the selected recording'
}

selected_stop_orders_selection_before_refresh() {
  local handler selection_check selected_display entry_lookup stop refresh

  handler=$(awk '
    /^\$stopBtn\.Add_Click\(\{/ { in_handler = 1 }
    in_handler { print }
    in_handler && /^\}\)$/ { exit }
  ' "$win")

  [ -n "$handler" ] || {
    printf 'missing selected Stop handler in %s\n' "$win" >&2
    return 1
  }

  selection_check=$(printf '%s\n' "$handler" | grep -nF 'if ($recordingList.SelectedIndex -lt 0) {' | head -n1 | cut -d: -f1)
  selected_display=$(printf '%s\n' "$handler" | grep -nF '$selectedDisplay = [string]$recordingList.SelectedItem' | head -n1 | cut -d: -f1)
  entry_lookup=$(printf '%s\n' "$handler" | grep -nF '$entry = $global:recordingRows[$recordingList.SelectedIndex]' | head -n1 | cut -d: -f1)
  stop=$(printf '%s\n' "$handler" | grep -nF 'Stop-RecordingEntry $entry' | head -n1 | cut -d: -f1)
  refresh=$(printf '%s\n' "$handler" | grep -nF 'Refresh-RecordingList' | head -n1 | cut -d: -f1)

  [ -n "$selection_check" ] && [ -n "$selected_display" ] && [ -n "$entry_lookup" ] && [ -n "$stop" ] && [ -n "$refresh" ] || {
    printf 'selected Stop handler must validate selection, capture its entry, stop it, then refresh\n' >&2
    return 1
  }

  if [ "$selection_check" -ge "$selected_display" ] || [ "$selected_display" -ge "$entry_lookup" ] || [ "$entry_lookup" -ge "$stop" ] || [ "$stop" -ge "$refresh" ]; then
    printf 'selected Stop handler must capture selection before any refresh\n' >&2
    return 1
  fi
}

case "${1:-all}" in
  windows-stop) windows_stop_contract ;;
  windows-auto) windows_auto_contract ;;
  windows-auto-append) windows_auto_check_append_contract ;;
  windows-ui) windows_ui_contract ;;
  windows-review-fixes) windows_task_3b_review_fixes_contract ;;
  mac-auto) mac_auto_contract ;;
  mac-service) launchctl_target_contract ;;
  mac-artifacts) managed_artifact_contract ;;
  mac-stop) stop_recording_lifecycle_contract ;;
  mac-count) recording_count_contract ;;
  all) windows_stop_contract; windows_auto_contract; windows_auto_check_append_contract; windows_ui_contract; windows_task_3b_review_fixes_contract; mac_auto_contract; mac_channel_storage_contract; windows_channel_storage_contract; documentation_contract ;;
  *) printf 'unknown contract: %s\n' "$1" >&2; exit 2 ;;
esac
