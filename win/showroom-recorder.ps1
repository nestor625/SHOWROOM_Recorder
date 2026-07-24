# SHOWROOM Recorder — Windows GUI (v2.0, redesigned UI/UX)
# Record & schedule SHOWROOM live streams via streamlink.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------------------------------------------------------- Palette
$clrBg       = [System.Drawing.Color]::FromArgb(245, 246, 248)
$clrHeader   = [System.Drawing.Color]::FromArgb(198, 40, 89)   # SHOWROOM pink
$clrRecord   = [System.Drawing.Color]::FromArgb(229, 57, 53)   # red
$clrStop     = [System.Drawing.Color]::FromArgb(239, 108, 0)   # orange
$clrDelete   = [System.Drawing.Color]::FromArgb(108, 117, 125) # gray
$clrSchedule = [System.Drawing.Color]::FromArgb(94, 96, 206)   # indigo
$clrView     = [System.Drawing.Color]::FromArgb(73, 80, 87)    # slate
$clrAdd      = [System.Drawing.Color]::FromArgb(46, 160, 67)   # green
$clrBrowse   = [System.Drawing.Color]::FromArgb(108, 117, 125) # gray
$clrText     = [System.Drawing.Color]::FromArgb(60, 64, 72)

# ---------------------------------------------------------------- Helpers
function Darken($c, $amt) {
    if (-not $amt) { $amt = 0.85 }
    return [System.Drawing.Color]::FromArgb($c.A, [int]($c.R * $amt), [int]($c.G * $amt), [int]($c.B * $amt))
}

function Style-Btn($btn, $bg) {
    $hover = Darken $bg 0.85
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $bg
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Add_MouseEnter({ $btn.BackColor = $hover }.GetNewClosure())
    $btn.Add_MouseLeave({ $btn.BackColor = $bg }.GetNewClosure())
}

function Set-Status($text, $kind) {
    $statusLabel.Text = "   $text"
    switch ($kind) {
        'rec'  { $statusLabel.BackColor = [System.Drawing.Color]::FromArgb(33, 150, 83);  $statusLabel.ForeColor = [System.Drawing.Color]::White }
        'err'  { $statusLabel.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69);  $statusLabel.ForeColor = [System.Drawing.Color]::White }
        'ok'   { $statusLabel.BackColor = [System.Drawing.Color]::FromArgb(52, 58, 64);   $statusLabel.ForeColor = [System.Drawing.Color]::White }
        default { $statusLabel.BackColor = [System.Drawing.Color]::FromArgb(52, 58, 64);  $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 205, 210) }
    }
}

function ConvertTo-WindowsCommandLineArgument([AllowEmptyString()][string]$argument) {
    if ($argument -notmatch '[\s"]') { return $argument }

    $quoted = New-Object System.Text.StringBuilder
    [void]$quoted.Append('"')
    $backslashCount = 0
    foreach ($character in $argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashCount++
            continue
        }
        if ($character -eq '"') {
            [void]$quoted.Append('\' * ($backslashCount * 2 + 1))
            [void]$quoted.Append('"')
        } else {
            [void]$quoted.Append('\' * $backslashCount)
            [void]$quoted.Append($character)
        }
        $backslashCount = 0
    }
    [void]$quoted.Append('\' * ($backslashCount * 2))
    [void]$quoted.Append('"')
    return $quoted.ToString()
}

function Join-WindowsCommandLine([string[]]$arguments) {
    return (($arguments | ForEach-Object { ConvertTo-WindowsCommandLineArgument ([string]$_) }) -join ' ')
}

function Update-ChannelHeader {
    $autoCheckCount = @(Get-AutoCheckUrls).Count
    $gChannels.Text = "  🎬  Channels  ($($global:channels.Count))  •  Auto Check: $autoCheckCount"
}

function Get-ChannelId([string]$url) {
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
        $digest = $hash.ComputeHash($bytes)
        return (([BitConverter]::ToString($digest) -replace '-', '').Substring(0, 16).ToLowerInvariant())
    } finally {
        $hash.Dispose()
    }
}

function Ensure-AutoDirectories {
    foreach ($path in @($dataDir, $autoJobsDir, $autoStatusDir, $autoLogsDir)) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

function Get-AutoCheckUrls {
    if (-not (Test-Path -LiteralPath $autoCheckFile)) { return @() }

    try {
        $savedUrls = Get-Content -LiteralPath $autoCheckFile -Raw -Encoding UTF8 | ConvertFrom-Json
        return @($savedUrls | Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) })
    } catch {
        Write-Host "Error loading auto-check settings: $_"
        return @()
    }
}

function Save-AutoCheckUrls([string[]]$urls) {
    Ensure-AutoDirectories
    $normalizedUrls = @($urls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    $temporaryPath = Join-Path $dataDir ("auto-check-{0}.tmp" -f [System.Guid]::NewGuid().ToString('N'))
    try {
        $json = ConvertTo-Json -InputObject @($normalizedUrls)
        [System.IO.File]::WriteAllText($temporaryPath, $json, (New-Object System.Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $temporaryPath -Destination $autoCheckFile -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Add-AutoCheckUrl([string]$url) {
    if ([string]::IsNullOrWhiteSpace($url)) { return }

    $enabledUrls = @(Get-AutoCheckUrls)
    if ($enabledUrls -notcontains $url) {
        Save-AutoCheckUrls @($enabledUrls + $url)
    }
}

function Test-AutoCheckEnabled([string]$url) {
    return (Get-AutoCheckUrls) -contains $url
}

function Get-AutoCheckPaths([string]$url) {
    $channelId = Get-ChannelId $url
    return [pscustomobject]@{
        id = $channelId
        url = $url
        taskName = "SHOWROOM_AUTO_$channelId"
        worker = Join-Path $autoJobsDir "auto-$channelId.ps1"
        status = Join-Path $autoStatusDir "auto-$channelId.json"
        log = Join-Path $autoLogsDir "auto-$channelId.log"
    }
}

function Read-AutoStatus([string]$url) {
    $statusPath = (Get-AutoCheckPaths $url).status
    if (-not (Test-Path -LiteralPath $statusPath)) { return $null }

    try {
        return Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-ProcessCommandLine([int]$processId) {
    try {
        $cimProcess = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $processId" -ErrorAction Stop
        return [string]$cimProcess.CommandLine
    } catch {
        return $null
    }
}

function Get-InteractiveTaskPrincipal {
    $userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    return New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
}

function Wait-ProcessExit($process, [int]$timeoutMilliseconds = 5000) {
    if (-not $process) { return $true }
    try {
        if ($process.HasExited) { return $true }
        [void]$process.WaitForExit($timeoutMilliseconds)
        return $process.HasExited
    } catch {
        return -not (Get-Process -Id $process.Id -ErrorAction SilentlyContinue)
    }
}

function Wait-ScheduledTaskStopped([string]$taskName, [int]$timeoutMilliseconds = 5000) {
    $deadline = [DateTime]::UtcNow.AddMilliseconds($timeoutMilliseconds)
    do {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if (-not $task -or $task.State -ne 'Running') { return $true }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}

function Test-StatusRecordingProcess($status) {
    if (-not $status -or $status.state -ne 'recording' -or -not $status.processId -or -not $status.streamStartUtc -or -not $status.url -or -not $status.output) { return $false }

    try {
        $recordedStartTime = [DateTime]::Parse([string]$status.streamStartUtc)
        $process = Get-Process -Id ([int]$status.processId) -ErrorAction SilentlyContinue
        if (-not $process) { return $false }
        if ($process.StartTime.ToUniversalTime().Ticks -ne $recordedStartTime.ToUniversalTime().Ticks) { return $false }
        $expectedArguments = Join-WindowsCommandLine @([string]$status.url, 'best', '-o', [string]$status.output, '--force', '--retry-streams', '30')
        $commandLine = Get-ProcessCommandLine $process.Id
        return $commandLine -and $commandLine.EndsWith($expectedArguments, [System.StringComparison]::Ordinal)
    } catch {
        return $false
    }
}

function Stop-StatusRecording($status) {
    if (-not $status -or -not $status.processId) { return $true }

    $process = Get-Process -Id ([int]$status.processId) -ErrorAction SilentlyContinue
    if (-not $process) { return $true }
    if (-not (Test-StatusRecordingProcess $status)) { return $false }
    try {
        $process.Kill()
        return Wait-ProcessExit $process
    } catch {
        return $false
    }
}

function Test-StatusWorkerProcess($status, $paths) {
    if (-not $status -or -not $status.workerProcessId -or -not $status.workerStartUtc -or -not $status.workerPath) { return $false }
    if ([string]$status.workerPath -ne [string]$paths.worker) { return $false }

    try {
        $recordedStartTime = [DateTime]::Parse([string]$status.workerStartUtc)
        $workerProcess = Get-Process -Id ([int]$status.workerProcessId) -ErrorAction SilentlyContinue
        if (-not $workerProcess) { return $false }
        if ($workerProcess.StartTime.ToUniversalTime().Ticks -ne $recordedStartTime.ToUniversalTime().Ticks) { return $false }
        if ($workerProcess.ProcessName -ine 'powershell') { return $false }
        $expectedArguments = Join-WindowsCommandLine @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', [string]$paths.worker)
        $commandLine = Get-ProcessCommandLine $workerProcess.Id
        return $commandLine -and $commandLine.EndsWith($expectedArguments, [System.StringComparison]::OrdinalIgnoreCase)
    } catch {
        return $false
    }
}

function Stop-StatusWorker($status) {
    if (-not $status -or -not $status.workerProcessId) { return $true }

    $workerProcess = Get-Process -Id ([int]$status.workerProcessId) -ErrorAction SilentlyContinue
    if (-not $workerProcess) { return $true }
    $statusPaths = [pscustomobject]@{ worker = [string]$status.workerPath }
    if (-not (Test-StatusWorkerProcess $status $statusPaths)) { return $false }
    try {
        $workerProcess.Kill()
        return Wait-ProcessExit $workerProcess
    } catch {
        return $false
    }
}

function Get-AutoCheckWorkerArgument($paths) {
    return Join-WindowsCommandLine @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', [string]$paths.worker)
}

function Test-AutoCheckTaskHealthy($task, $paths) {
    if (-not $task -or $task.State -eq 'Disabled' -or $task.State -ne 'Running') { return $false }
    if (-not (Test-Path -LiteralPath $paths.worker)) { return $false }
    $actions = @($task.Actions)
    if ($actions.Count -ne 1) { return $false }
    if ([System.IO.Path]::GetFileName([string]$actions[0].Execute) -ine 'powershell.exe') { return $false }
    if ([string]$actions[0].Arguments -ne (Get-AutoCheckWorkerArgument $paths)) { return $false }
    $status = Read-AutoStatus ([string]$paths.url)
    return (Test-StatusWorkerProcess $status $paths)
}

function New-AutoCheckWorker($ch, $paths, [string]$streamlinkPath) {
    $encodedUrl = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$ch.url))
    $encodedName = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$ch.name))
    $encodedSavePath = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$saveBox.Text))
    $encodedStatusPath = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$paths.status))
    $encodedLogPath = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$paths.log))
    $encodedStreamlinkPath = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($streamlinkPath))
    $encodedWorkerPath = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$paths.worker))

    $workerContent = @'
$ErrorActionPreference = 'Stop'
$url = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__URL__'))
$name = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__NAME__'))
$savePath = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__SAVE_PATH__'))
$statusPath = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__STATUS_PATH__'))
$logPath = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__LOG_PATH__'))
$streamlink = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__STREAMLINK_PATH__'))
$workerPath = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__WORKER_PATH__'))

function ConvertTo-WindowsCommandLineArgument([AllowEmptyString()][string]$argument) {
    if ($argument -notmatch '[\s"]') { return $argument }

    $quoted = New-Object System.Text.StringBuilder
    [void]$quoted.Append('"')
    $backslashCount = 0
    foreach ($character in $argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashCount++
            continue
        }
        if ($character -eq '"') {
            [void]$quoted.Append('\' * ($backslashCount * 2 + 1))
            [void]$quoted.Append('"')
        } else {
            [void]$quoted.Append('\' * $backslashCount)
            [void]$quoted.Append($character)
        }
        $backslashCount = 0
    }
    [void]$quoted.Append('\' * ($backslashCount * 2))
    [void]$quoted.Append('"')
    return $quoted.ToString()
}

function Join-WindowsCommandLine([string[]]$arguments) {
    return (($arguments | ForEach-Object { ConvertTo-WindowsCommandLineArgument ([string]$_) }) -join ' ')
}

function Write-AutoWorkerStatus($status) {
    $temporaryPath = "$statusPath.$([System.Guid]::NewGuid().ToString('N')).tmp"
    $status.updatedUtc = [DateTime]::UtcNow.ToString('o')
    $json = $status | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($temporaryPath, $json, (New-Object System.Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporaryPath -Destination $statusPath -Force
}

function Write-AutoWorkerLog([string]$message) {
    $line = "$(Get-Date -Format 'o') $message"
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    if ((Test-Path -LiteralPath $logPath) -and (Get-Item -LiteralPath $logPath).Length -gt 1048576) {
        Move-Item -LiteralPath $logPath -Destination "$logPath.1" -Force
    }
}

New-Item -ItemType Directory -Path $savePath -Force | Out-Null
$workerProcess = [System.Diagnostics.Process]::GetCurrentProcess()
while ($true) {
    try {
        Write-AutoWorkerStatus ([ordered]@{ url = $url; name = $name; state = 'waiting'; output = $null; processId = $null; streamStartUtc = $null; workerProcessId = $workerProcess.Id; workerStartUtc = $workerProcess.StartTime.ToUniversalTime().ToString("o"); workerPath = $workerPath; lastError = $null })
        $probe = Start-Process -FilePath $streamlink -ArgumentList (Join-WindowsCommandLine @($url, 'best', '--stream-url')) -Wait -PassThru -WindowStyle Hidden
        if ($probe.ExitCode -ne 0) {
            Start-Sleep -Seconds 60
            continue
        }

        do {
            $timestamp = Get-Date -Format 'yyyy-MM-dd_HH_mm'
            $output = Join-Path $savePath "$name-SHOWROOM-$timestamp.mp4"
            if (Test-Path -LiteralPath $output) { Start-Sleep -Seconds 60 }
        } while (Test-Path -LiteralPath $output)

        # Keep the worker equivalent to: streamlink URL best -o OUTPUT --force --retry-streams 30
        $recording = Start-Process -FilePath $streamlink -ArgumentList (Join-WindowsCommandLine @($url, 'best', '-o', $output, '--force', '--retry-streams', '30')) -PassThru -WindowStyle Hidden
        Write-AutoWorkerStatus ([ordered]@{
            url = $url
            name = $name
            state = 'recording'
            output = $output
            processId = $recording.Id
            streamStartUtc = $recording.StartTime.ToUniversalTime().ToString("o")
            workerProcessId = $workerProcess.Id
            workerStartUtc = $workerProcess.StartTime.ToUniversalTime().ToString("o")
            workerPath = $workerPath
            lastError = $null
        })
        $recording.WaitForExit()
        Write-AutoWorkerLog "Recording exited with code $($recording.ExitCode): $output"
    } catch {
        Write-AutoWorkerLog "$_"
        Write-AutoWorkerStatus ([ordered]@{ url = $url; name = $name; state = 'error'; output = $null; processId = $null; streamStartUtc = $null; workerProcessId = $workerProcess.Id; workerStartUtc = $workerProcess.StartTime.ToUniversalTime().ToString("o"); workerPath = $workerPath; lastError = [string]$_ })
    }
    Start-Sleep -Seconds 60
}
'@

    $workerContent = $workerContent.Replace('__URL__', $encodedUrl).Replace('__NAME__', $encodedName).Replace('__SAVE_PATH__', $encodedSavePath).Replace('__STATUS_PATH__', $encodedStatusPath).Replace('__LOG_PATH__', $encodedLogPath).Replace('__STREAMLINK_PATH__', $encodedStreamlinkPath).Replace('__WORKER_PATH__', $encodedWorkerPath)
    [System.IO.File]::WriteAllText($paths.worker, $workerContent, (New-Object System.Text.UTF8Encoding($false)))
}

function Remove-AutoCheckArtifacts($paths) {
    foreach ($path in @($paths.worker, $paths.status, $paths.log, "$($paths.log).1")) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}

function Enable-AutoCheck($ch) {
    if (-not $ch -or [string]::IsNullOrWhiteSpace([string]$ch.url) -or [string]::IsNullOrWhiteSpace([string]$ch.name)) { return $false }

    Ensure-AutoDirectories
    $paths = Get-AutoCheckPaths ([string]$ch.url)
    $taskName = $paths.taskName
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask -and (Test-AutoCheckTaskHealthy $existingTask $paths)) {
        if (-not (Test-AutoCheckEnabled ([string]$ch.url))) {
            Add-AutoCheckUrl ([string]$ch.url)
        }
        return $true
    }

    $streamlinkCommand = Get-Command streamlink -ErrorAction SilentlyContinue
    if (-not $streamlinkCommand) { throw "Streamlink not found. Install it and ensure it is on PATH." }
    $streamlinkPath = if ($streamlinkCommand.Path) { [string]$streamlinkCommand.Path } else { [string]$streamlinkCommand.Source }

    try {
        if ($existingTask) {
            if (-not (Disable-AutoCheck ([string]$ch.url))) {
                throw "Could not safely replace stale Auto Check task $taskName."
            }
        } else {
            $staleStatus = Read-AutoStatus ([string]$ch.url)
            if (-not (Stop-StatusWorker $staleStatus) -or -not (Stop-StatusRecording $staleStatus)) {
                throw "Could not safely stop stale Auto Check processes for $($ch.url)."
            }
            Remove-AutoCheckArtifacts $paths
        }
        New-AutoCheckWorker $ch $paths $streamlinkPath
        if ($env:SHOWROOM_RECORDER_TEST -eq '1') {
            Add-AutoCheckUrl ([string]$ch.url)
            return $true
        }

        $workerArgument = Get-AutoCheckWorkerArgument $paths
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $workerArgument
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -ExecutionTimeLimit (New-TimeSpan -Seconds 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
        $principal = Get-InteractiveTaskPrincipal
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Auto-check $($ch.name)" -Force -ErrorAction Stop | Out-Null
        Start-ScheduledTask -TaskName $taskName -ErrorAction Stop

        if (-not (Test-AutoCheckEnabled ([string]$ch.url))) {
            Add-AutoCheckUrl ([string]$ch.url)
        }
        return $true
    } catch {
        $registrationError = $_
        if (-not (Disable-AutoCheck ([string]$ch.url))) {
            throw "Auto Check setup failed and shutdown could not be verified for $($ch.url): $registrationError"
        }
        throw $registrationError
    }
}

function Disable-AutoCheck([string]$url, $expectedStatus = $null) {
    if ([string]::IsNullOrWhiteSpace($url)) { return $false }

    $paths = Get-AutoCheckPaths $url
    $status = if ($null -ne $expectedStatus) { $expectedStatus } else { Read-AutoStatus $url }
    if ($status -and ([string]$status.url -ne $url -or ([string]$status.workerPath -and [string]$status.workerPath -ne [string]$paths.worker))) {
        Write-Host "Auto-check status mismatch for $url (expected URL/path does not match). Cleaning up task and artifacts directly."
        $status = $null
    }
    try {
        $task = Get-ScheduledTask -TaskName $paths.taskName -ErrorAction SilentlyContinue
        if ($task) {
            Stop-ScheduledTask -TaskName $paths.taskName -ErrorAction Stop
            if (-not (Wait-ScheduledTaskStopped $paths.taskName)) { return $false }
        }
    } catch {
        return $false
    }

    if (-not (Stop-StatusWorker $status)) { return $false }
    if (-not (Stop-StatusRecording $status)) { return $false }
    if ($task) {
        try {
            Unregister-ScheduledTask -TaskName $paths.taskName -Confirm:$false -ErrorAction Stop
        } catch {
            return $false
        }
    }
    Remove-AutoCheckArtifacts $paths
    Save-AutoCheckUrls @((Get-AutoCheckUrls) | Where-Object { $_ -ne $url })
    return $true
}

function Reconcile-AutoChecks([switch]$RebuildWorkers) {
    $channelsByUrl = @{}
    foreach ($ch in $global:channels) { $channelsByUrl[[string]$ch.url] = $ch }

    $enabledUrls = @(Get-AutoCheckUrls)
    foreach ($url in $enabledUrls) {
        try {
            if (-not $channelsByUrl.ContainsKey([string]$url)) {
                if (-not (Disable-AutoCheck ([string]$url))) {
                    throw "Disable did not complete."
                }
            } else {
                if ($RebuildWorkers) {
                    if (-not (Disable-AutoCheck ([string]$url))) {
                        throw "Could not stop the existing worker for rebuild."
                    }
                }
                Enable-AutoCheck $channelsByUrl[[string]$url] | Out-Null
            }
        } catch {
            Write-Host "Auto-check reconciliation failed for $url`: $_"
        }
    }

    $enabledUrls = @(Get-AutoCheckUrls)
    $managedIds = @($enabledUrls | ForEach-Object { Get-ChannelId ([string]$_) })
    foreach ($task in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'SHOWROOM_AUTO_*' })) {
        $taskId = $task.TaskName.Substring('SHOWROOM_AUTO_'.Length)
        if ($taskId -notmatch '^[0-9a-f]{16}$' -or $managedIds -notcontains $taskId) {
            try {
                $orphanPaths = [pscustomobject]@{ worker = Join-Path $autoJobsDir "auto-$taskId.ps1"; status = Join-Path $autoStatusDir "auto-$taskId.json"; log = Join-Path $autoLogsDir "auto-$taskId.log" }
                $orphanStatus = if ($taskId -match '^[0-9a-f]{16}$' -and (Test-Path -LiteralPath $orphanPaths.status)) { Get-Content -LiteralPath $orphanPaths.status -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
                if ($orphanStatus -and $orphanStatus.url -and (Get-ChannelId ([string]$orphanStatus.url)) -eq $taskId) {
                    if (-not (Disable-AutoCheck ([string]$orphanStatus.url))) { throw "Disable did not complete." }
                    continue
                }
                Stop-ScheduledTask -TaskName $task.TaskName -ErrorAction Stop
                if (-not (Wait-ScheduledTaskStopped $task.TaskName)) { throw "Task did not stop." }
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
                if ($taskId -match '^[0-9a-f]{16}$') { Remove-AutoCheckArtifacts $orphanPaths }
            } catch {
                Write-Host "Auto-check reconciliation failed for $($task.TaskName)`: $_"
            }
        }
    }
}

function Refresh-ChannelList {
    $channelList.Items.Clear()
    $global:channelRows = @()
    foreach ($ch in $global:channels) {
        $global:channelRows += $ch
        $isAutoChecked = Test-AutoCheckEnabled ([string]$ch.url)
        $display = if ($isAutoChecked) { "📡  $($ch.name)" } else { [string]$ch.name }
        $channelList.Items.Add($display) | Out-Null
    }
    Refresh-AutoCheckList
}

function Refresh-AutoCheckList {
    if (-not $autoCheckList) { return }

    $selectedUrl = if ($autoCheckList.SelectedIndex -ge 0) { [string]$global:autoCheckRows[$autoCheckList.SelectedIndex].url } else { $null }
    $autoCheckList.Items.Clear()
    $global:autoCheckRows = @()
    foreach ($ch in $global:channels) {
        if (Test-AutoCheckEnabled ([string]$ch.url)) {
            $global:autoCheckRows += $ch
            $autoCheckList.Items.Add("📡  $($ch.name)") | Out-Null
        }
    }
    if ($selectedUrl) {
        for ($index = 0; $index -lt $global:autoCheckRows.Count; $index++) {
            if ([string]$global:autoCheckRows[$index].url -eq $selectedUrl) {
                $autoCheckList.SelectedIndex = $index
                break
            }
        }
    }
}

function Start-Recording($ch) {
    if (Test-AutoCheckEnabled ([string]$ch.url)) {
        Set-Status "Already auto-checking: $($ch.name)" 'ok'
        return $false
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH_mm"
    $filename  = "$($ch.name)-SHOWROOM-$timestamp.mp4"
    $output    = Join-Path $saveBox.Text $filename
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "streamlink"
        $psi.Arguments = Join-WindowsCommandLine @(
            [string]$ch.url,
            'best',
            '-o',
            $output,
            '--force',
            '--retry-streams',
            '30'
        )
        $psi.UseShellExecute = $false
        $process = [System.Diagnostics.Process]::Start($psi)
        $display = "$($ch.name)  [PID $($process.Id)]"
        $global:manualRecordings[[string]$process.Id] = [pscustomobject]@{
            processId = $process.Id
            process = $process
            name = [string]$ch.name
            url = [string]$ch.url
            display = $display
            kind = 'manual'
        }
        Refresh-RecordingList
        Set-Status "Recording: $($ch.name)" 'rec'
        return $true
    } catch {
        Set-Status "Streamlink not found — install from streamlink.github.io" 'err'
        [System.Windows.Forms.MessageBox]::Show("Could not start streamlink. Is it installed and on your PATH?`n`n$($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return $false
    }
}

function Stop-RecordingByProcessId([int]$processId) {
    $entry = $global:manualRecordings[[string]$processId]
    if (-not $entry) { return $false }
    try {
        if ($entry.process.HasExited) {
            $global:manualRecordings.Remove([string]$processId)
            return $false
        }
        if (-not $entry.process.HasExited) {
            $entry.process.Kill()
        }
        if (-not (Wait-ProcessExit $entry.process)) { return $false }
        $global:manualRecordings.Remove([string]$processId)
        return $true
    } catch {
        return $false
    }
}

function Stop-RecordingEntry($entry) {
    if (-not $entry) { return $false }
    try {
        if ($entry.kind -eq 'auto') {
            return (Disable-AutoCheck ([string]$entry.url) $entry.status)
        }
        return (Stop-RecordingByProcessId ([int]$entry.processId))
    } catch {
        return $false
    }
}

function Refresh-RecordingList {
    $selectedDisplay = if ($recordingList.SelectedIndex -ge 0) { [string]$recordingList.SelectedItem } else { $null }
    foreach ($key in @($global:manualRecordings.Keys)) {
        $entry = $global:manualRecordings[$key]
        if ($entry.process.HasExited) {
            $global:manualRecordings.Remove($key)
        }
    }

    $global:autoRecordings = @{}
    foreach ($url in @(Get-AutoCheckUrls)) {
        $status = Read-AutoStatus ([string]$url)
        if (Test-StatusRecordingProcess $status) {
            $processId = [string]$status.processId
            $global:autoRecordings[$processId] = [pscustomobject]@{
                processId = [int]$status.processId
                name = [string]$status.name
                url = [string]$status.url
                display = "$(($status.name))  [PID $($status.processId)]"
                kind = 'auto'
                status = $status
            }
        }
    }

    $global:recordingRows = @($global:manualRecordings.Values) + @($global:autoRecordings.Values)
    $recordingList.Items.Clear()
    foreach ($entry in $global:recordingRows) {
        $recordingList.Items.Add($entry.display) | Out-Null
    }
    if ($selectedDisplay) { $recordingList.SelectedItem = $selectedDisplay }
}

# ---------------------------------------------------------------- Data
$global:channels = @()
$global:manualRecordings = @{}
$global:autoRecordings = @{}
$global:channelRows = @()
$global:autoCheckRows = @()
$global:recordingRows = @()

$dataDir = Join-Path $env:APPDATA 'SHOWROOMRecorder'
$channelsFile = Join-Path $dataDir 'channels.json'
$settingsFile = Join-Path $dataDir 'settings.json'
$autoCheckFile = Join-Path $dataDir "auto-check.json"
$autoJobsDir = Join-Path $dataDir 'jobs'
$autoStatusDir = Join-Path $dataDir 'status'
$autoLogsDir = Join-Path $dataDir 'logs'
if (Test-Path $channelsFile) {
    try {
        $savedChannels = Get-Content $channelsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($savedChannels) {
            if ($savedChannels -is [Array]) {
                $global:channels = $savedChannels
            } else {
                $global:channels = @($savedChannels)
            }
        }
    } catch {
        Write-Host "Error loading channels: $_"
    }
}

$defaultSavePath = "C:\Recordings"
if (Test-Path $settingsFile) {
    try {
        $settings = Get-Content $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($settings.savePath) { $defaultSavePath = $settings.savePath }
    } catch {
        Write-Host "Error loading settings: $_"
    }
}

# ---------------------------------------------------------------- Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SHOWROOM Recorder"
$form.ClientSize = New-Object System.Drawing.Size(864, 590)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.BackColor = $clrBg
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# --- Header bar
$header = New-Object System.Windows.Forms.Panel
$header.Dock = [System.Windows.Forms.DockStyle]::Top
$header.Height = 60
$header.BackColor = $clrHeader
$form.Controls.Add($header)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 9)
$titleLabel.AutoSize = $true
$titleLabel.Text = "📺  SHOWROOM Recorder"
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$header.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Location = New-Object System.Drawing.Point(24, 40)
$subtitleLabel.AutoSize = $true
$subtitleLabel.Text = "Record & schedule SHOWROOM live streams"
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 214, 230)
$subtitleLabel.BackColor = [System.Drawing.Color]::Transparent
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$header.Controls.Add($subtitleLabel)

# --- Status bar (bottom)
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$statusLabel.Height = 28
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($statusLabel)
Set-Status "Ready" 'idle'

# ---------------------------------------------------------------- Save location
$gSave = New-Object System.Windows.Forms.GroupBox
$gSave.Text = "  💾  Save Location"
$gSave.Location = New-Object System.Drawing.Point(16, 72)
$gSave.Size = New-Object System.Drawing.Size(832, 58)
$gSave.ForeColor = $clrText
$gSave.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($gSave)

$saveBox = New-Object System.Windows.Forms.TextBox
$saveBox.Location = New-Object System.Drawing.Point(14, 22)
$saveBox.Size = New-Object System.Drawing.Size(610, 25)
$saveBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$saveBox.Text = if ($defaultSavePath) { $defaultSavePath } else { "C:\Recordings" }
$gSave.Controls.Add($saveBox)

$saveBrowseBtn = New-Object System.Windows.Forms.Button
$saveBrowseBtn.Location = New-Object System.Drawing.Point(636, 21)
$saveBrowseBtn.Size = New-Object System.Drawing.Size(180, 27)
$saveBrowseBtn.Text = "📁  Browse…"
Style-Btn $saveBrowseBtn $clrBrowse
$saveBrowseBtn.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.SelectedPath = $saveBox.Text
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $saveBox.Text = $folderBrowser.SelectedPath
        Ensure-AutoDirectories
        $settings = @{savePath = $saveBox.Text} | ConvertTo-Json
        Set-Content $settingsFile $settings -Encoding UTF8
        try {
            Reconcile-AutoChecks -RebuildWorkers
        } catch {
            Write-Host "Auto-check reconciliation failed after changing save location: $_"
        }
        Set-Status "Save location updated" 'ok'
    }
})
$gSave.Controls.Add($saveBrowseBtn)

# ---------------------------------------------------------------- Add channel
$gAdd = New-Object System.Windows.Forms.GroupBox
$gAdd.Text = "  ➕  Add Channel"
$gAdd.Location = New-Object System.Drawing.Point(16, 138)
$gAdd.Size = New-Object System.Drawing.Size(832, 66)
$gAdd.ForeColor = $clrText
$gAdd.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($gAdd)

$urlLabel = New-Object System.Windows.Forms.Label
$urlLabel.Location = New-Object System.Drawing.Point(14, 30)
$urlLabel.Size = New-Object System.Drawing.Size(38, 20)
$urlLabel.Text = "URL:"
$urlLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gAdd.Controls.Add($urlLabel)

$urlBox = New-Object System.Windows.Forms.TextBox
$urlBox.Location = New-Object System.Drawing.Point(54, 27)
$urlBox.Size = New-Object System.Drawing.Size(420, 25)
$urlBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$urlBox.Text = "https://www.showroom-live.com/r/"
$gAdd.Controls.Add($urlBox)

$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Location = New-Object System.Drawing.Point(486, 30)
$nameLabel.Size = New-Object System.Drawing.Size(50, 20)
$nameLabel.Text = "Name:"
$nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gAdd.Controls.Add($nameLabel)

$nameBox = New-Object System.Windows.Forms.TextBox
$nameBox.Location = New-Object System.Drawing.Point(538, 27)
$nameBox.Size = New-Object System.Drawing.Size(160, 25)
$nameBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gAdd.Controls.Add($nameBox)

$addBtn = New-Object System.Windows.Forms.Button
$addBtn.Location = New-Object System.Drawing.Point(714, 26)
$addBtn.Size = New-Object System.Drawing.Size(102, 28)
$addBtn.Text = "Add"
Style-Btn $addBtn $clrAdd
$addBtn.Add_Click({
    if ($urlBox.Text -and $nameBox.Text) {
        $global:channels += @{url = $urlBox.Text; name = $nameBox.Text}

        Ensure-AutoDirectories
        $global:channels | ConvertTo-Json -Depth 10 | Out-File -FilePath $channelsFile -Encoding UTF8
        Refresh-ChannelList

        Set-Status "Added: $($nameBox.Text)" 'ok'
        $urlBox.Text = "https://www.showroom-live.com/r/"
        $nameBox.Text = ""
        Update-ChannelHeader
    } else {
        Set-Status "Enter both a URL and a name" 'err'
    }
})
$gAdd.Controls.Add($addBtn)

# ---------------------------------------------------------------- Channels
$gChannels = New-Object System.Windows.Forms.GroupBox
$gChannels.Text = "  🎬  Channels"
$gChannels.Location = New-Object System.Drawing.Point(16, 212)
$gChannels.Size = New-Object System.Drawing.Size(832, 214)
$gChannels.ForeColor = $clrText
$gChannels.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($gChannels)

$channelList = New-Object System.Windows.Forms.ListBox
$channelList.Location = New-Object System.Drawing.Point(14, 24)
$channelList.Size = New-Object System.Drawing.Size(496, 118)
$channelList.SelectionMode = "MultiExtended"
$channelList.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$channelList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$gChannels.Controls.Add($channelList)

$autoCheckListLabel = New-Object System.Windows.Forms.Label
$autoCheckListLabel.Location = New-Object System.Drawing.Point(520, 24)
$autoCheckListLabel.Size = New-Object System.Drawing.Size(298, 18)
$autoCheckListLabel.Text = "Auto Check Enabled"
$autoCheckListLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$gChannels.Controls.Add($autoCheckListLabel)

$autoCheckList = New-Object System.Windows.Forms.ListBox
$autoCheckList.Location = New-Object System.Drawing.Point(520, 44)
$autoCheckList.Size = New-Object System.Drawing.Size(298, 98)
$autoCheckList.SelectionMode = "One"
$autoCheckList.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$autoCheckList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$gChannels.Controls.Add($autoCheckList)

Refresh-ChannelList

$recordSelectedBtn = New-Object System.Windows.Forms.Button
$recordSelectedBtn.Location = New-Object System.Drawing.Point(14, 152)
$recordSelectedBtn.Size = New-Object System.Drawing.Size(150, 36)
$recordSelectedBtn.Text = "🔴  Record"
Style-Btn $recordSelectedBtn $clrRecord
$gChannels.Controls.Add($recordSelectedBtn)

$recordAllBtn = New-Object System.Windows.Forms.Button
$recordAllBtn.Location = New-Object System.Drawing.Point(172, 152)
$recordAllBtn.Size = New-Object System.Drawing.Size(150, 36)
$recordAllBtn.Text = "🔴  Record All"
Style-Btn $recordAllBtn $clrRecord
$gChannels.Controls.Add($recordAllBtn)

$removeBtn = New-Object System.Windows.Forms.Button
$removeBtn.Location = New-Object System.Drawing.Point(330, 152)
$removeBtn.Size = New-Object System.Drawing.Size(120, 36)
$removeBtn.Text = "🗑  Delete"
Style-Btn $removeBtn $clrDelete
$gChannels.Controls.Add($removeBtn)

$autoCheckBtn = New-Object System.Windows.Forms.Button
$autoCheckBtn.Location = New-Object System.Drawing.Point(458, 152)
$autoCheckBtn.Size = New-Object System.Drawing.Size(150, 36)
$autoCheckBtn.Text = "📡  Auto Check"
Style-Btn $autoCheckBtn $clrSchedule
$gChannels.Controls.Add($autoCheckBtn)

$disableAutoCheckBtn = New-Object System.Windows.Forms.Button
$disableAutoCheckBtn.Location = New-Object System.Drawing.Point(616, 152)
$disableAutoCheckBtn.Size = New-Object System.Drawing.Size(202, 36)
$disableAutoCheckBtn.Text = "Disable Selected"
Style-Btn $disableAutoCheckBtn $clrDelete
$gChannels.Controls.Add($disableAutoCheckBtn)

# ---------------------------------------------------------------- Schedule
$gSchedule = New-Object System.Windows.Forms.GroupBox
$gSchedule.Text = "  ⏰  Schedule"
$gSchedule.Location = New-Object System.Drawing.Point(16, 434)
$gSchedule.Size = New-Object System.Drawing.Size(410, 120)
$gSchedule.ForeColor = $clrText
$gSchedule.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($gSchedule)

$scheduleDateLabel = New-Object System.Windows.Forms.Label
$scheduleDateLabel.Location = New-Object System.Drawing.Point(14, 30)
$scheduleDateLabel.Size = New-Object System.Drawing.Size(40, 20)
$scheduleDateLabel.Text = "Date:"
$scheduleDateLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gSchedule.Controls.Add($scheduleDateLabel)

$scheduleDatePicker = New-Object System.Windows.Forms.DateTimePicker
$scheduleDatePicker.Location = New-Object System.Drawing.Point(56, 27)
$scheduleDatePicker.Size = New-Object System.Drawing.Size(150, 25)
$scheduleDatePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$scheduleDatePicker.Value = (Get-Date).AddHours(1)
$gSchedule.Controls.Add($scheduleDatePicker)

$scheduleTimeLabel = New-Object System.Windows.Forms.Label
$scheduleTimeLabel.Location = New-Object System.Drawing.Point(218, 30)
$scheduleTimeLabel.Size = New-Object System.Drawing.Size(42, 20)
$scheduleTimeLabel.Text = "Time:"
$scheduleTimeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gSchedule.Controls.Add($scheduleTimeLabel)

$scheduleTimePicker = New-Object System.Windows.Forms.DateTimePicker
$scheduleTimePicker.Location = New-Object System.Drawing.Point(260, 27)
$scheduleTimePicker.Size = New-Object System.Drawing.Size(110, 25)
$scheduleTimePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Time
$scheduleTimePicker.ShowUpDown = $true
$scheduleTimePicker.Value = (Get-Date).AddHours(1)
$gSchedule.Controls.Add($scheduleTimePicker)

$scheduleBtn = New-Object System.Windows.Forms.Button
$scheduleBtn.Location = New-Object System.Drawing.Point(14, 68)
$scheduleBtn.Size = New-Object System.Drawing.Size(180, 36)
$scheduleBtn.Text = "⏰  Schedule"
Style-Btn $scheduleBtn $clrSchedule
$gSchedule.Controls.Add($scheduleBtn)

$viewScheduleBtn = New-Object System.Windows.Forms.Button
$viewScheduleBtn.Location = New-Object System.Drawing.Point(202, 68)
$viewScheduleBtn.Size = New-Object System.Drawing.Size(180, 36)
$viewScheduleBtn.Text = "📅  View Scheduled"
Style-Btn $viewScheduleBtn $clrView
$viewScheduleBtn.Add_Click({
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "SHOWROOM_REC_*" }
    if ($tasks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No scheduled recordings", "Scheduled Recordings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } else {
        $taskInfo = @()
        foreach ($t in $tasks) {
            $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -ErrorAction SilentlyContinue
            $taskInfo += "$($t.TaskName) - Next: $($info.NextRunTime)"
        }
        [System.Windows.Forms.MessageBox]::Show(($taskInfo -join "`n"), "Scheduled Recordings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
})
$gSchedule.Controls.Add($viewScheduleBtn)

# ---------------------------------------------------------------- Now recording
$gRecording = New-Object System.Windows.Forms.GroupBox
$gRecording.Text = "  📡  Now Recording"
$gRecording.Location = New-Object System.Drawing.Point(438, 434)
$gRecording.Size = New-Object System.Drawing.Size(410, 120)
$gRecording.ForeColor = $clrText
$gRecording.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($gRecording)

$recordingList = New-Object System.Windows.Forms.ListBox
$recordingList.Location = New-Object System.Drawing.Point(14, 24)
$recordingList.Size = New-Object System.Drawing.Size(220, 80)
$recordingList.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$recordingList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$gRecording.Controls.Add($recordingList)

$stopBtn = New-Object System.Windows.Forms.Button
$stopBtn.Location = New-Object System.Drawing.Point(242, 24)
$stopBtn.Size = New-Object System.Drawing.Size(74, 36)
$stopBtn.Text = "⏹ Stop"
Style-Btn $stopBtn $clrStop
$gRecording.Controls.Add($stopBtn)

$stopAllBtn = New-Object System.Windows.Forms.Button
$stopAllBtn.Location = New-Object System.Drawing.Point(322, 24)
$stopAllBtn.Size = New-Object System.Drawing.Size(74, 36)
$stopAllBtn.Text = "Stop All"
Style-Btn $stopAllBtn $clrDelete
$gRecording.Controls.Add($stopAllBtn)

# ---------------------------------------------------------------- Actions
$recordSelectedBtn.Add_Click({
    if ($channelList.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Nothing selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    $recordedCount = 0
    $failedStartCount = 0
    $skippedAutoCheckCount = 0
    foreach ($idx in $channelList.SelectedIndices) {
        $ch = $global:channelRows[$idx]
        if (Test-AutoCheckEnabled ([string]$ch.url)) {
            $skippedAutoCheckCount++
            continue
        }
        if (Start-Recording $ch) {
            $recordedCount++
        } else {
            $failedStartCount++
        }
    }
    if ($recordedCount -gt 0) {
        $message = "Recording $recordedCount channel(s)"
        if ($skippedAutoCheckCount -gt 0) { $message += "; skipped $skippedAutoCheckCount auto-checking" }
        if ($failedStartCount -gt 0) {
            Set-Status "$message; failed to start $failedStartCount" 'err'
        } else {
            Set-Status $message 'rec'
        }
    } elseif ($failedStartCount -gt 0) {
        $message = "Could not start $failedStartCount selected channel(s)"
        if ($skippedAutoCheckCount -gt 0) { $message += "; skipped $skippedAutoCheckCount auto-checking" }
        Set-Status $message 'err'
    } else {
        Set-Status "Skipped $skippedAutoCheckCount auto-checking channel(s)" 'ok'
    }
})

$channelList.Add_DoubleClick({
    if ($channelList.SelectedIndex -ge 0) {
        Start-Recording $global:channelRows[$channelList.SelectedIndex]
    }
})

$recordAllBtn.Add_Click({
    if ($global:channels.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No channels added", "Nothing to record", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    $manualChannels = @($global:channels | Where-Object { -not (Test-AutoCheckEnabled ([string]$_.url)) })
    $skippedAutoCheckCount = $global:channels.Count - $manualChannels.Count
    $recordedCount = 0
    $failedStartCount = 0
    foreach ($ch in $manualChannels) {
        if (Start-Recording $ch) {
            $recordedCount++
        } else {
            $failedStartCount++
        }
    }
    if ($recordedCount -gt 0) {
        $message = "Recording all $recordedCount eligible channel(s)"
        if ($skippedAutoCheckCount -gt 0) { $message += "; skipped $skippedAutoCheckCount auto-checking" }
        if ($failedStartCount -gt 0) {
            Set-Status "$message; failed to start $failedStartCount" 'err'
        } else {
            Set-Status $message 'rec'
        }
    } elseif ($failedStartCount -gt 0) {
        $message = "Could not start $failedStartCount channel(s)"
        if ($skippedAutoCheckCount -gt 0) { $message += "; skipped $skippedAutoCheckCount auto-checking" }
        Set-Status $message 'err'
    } else {
        Set-Status "Skipped $skippedAutoCheckCount auto-checking channel(s)" 'ok'
    }
})

$stopBtn.Add_Click({
    if ($recordingList.SelectedIndex -lt 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select a recording first", "Nothing selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $selectedDisplay = [string]$recordingList.SelectedItem
    $entry = $global:recordingRows[$recordingList.SelectedIndex]
    $stopped = $false
    try {
        $stopped = Stop-RecordingEntry $entry
    } catch {
        $stopped = $false
    }
    if ($stopped) {
        Refresh-RecordingList
        Set-Status "Stopped: $($entry.name)" 'ok'
    } else {
        Set-Status "Could not stop: $($entry.name)" 'err'
    }
})

$stopAllBtn.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Stop all tracked recordings?", "Stop All", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning) -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    $allStopped = $true
    foreach ($entry in @($global:recordingRows)) {
        try {
            if (-not (Stop-RecordingEntry $entry)) { $allStopped = $false }
        } catch {
            $allStopped = $false
        }
    }
    Refresh-RecordingList
    if ($allStopped) {
        Set-Status "Stopped all recordings" 'ok'
    } else {
        Set-Status "Some recordings could not be stopped" 'err'
    }
})

$removeBtn.Add_Click({
    if ($channelList.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Nothing selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    $selectedIndices = @($channelList.SelectedIndices)
    $failedIndices = @()
    foreach ($idx in $selectedIndices) {
        $ch = $global:channelRows[$idx]
        if (Test-AutoCheckEnabled ([string]$ch.url) -and -not (Disable-AutoCheck ([string]$ch.url))) {
            $failedIndices += $idx
        }
    }
    $newChannels = @()
    for ($i = 0; $i -lt $global:channelRows.Count; $i++) {
        if ($selectedIndices -notcontains $i -or $failedIndices -contains $i) {
            $newChannels += $global:channelRows[$i]
        }
    }
    $global:channels = $newChannels

    Refresh-ChannelList

    Ensure-AutoDirectories
    $global:channels | ConvertTo-Json -Depth 10 | Out-File -FilePath $channelsFile -Encoding UTF8
    try {
        Reconcile-AutoChecks
    } catch {
        Write-Host "Auto-check reconciliation failed after deleting channels: $_"
    }

    $deletedCount = $selectedIndices.Count - $failedIndices.Count
    if ($failedIndices.Count -gt 0) {
        Set-Status "Deleted $deletedCount channel(s); retained $($failedIndices.Count) because Auto Check could not stop" 'err'
    } else {
        Set-Status "Deleted $deletedCount channel(s)" 'ok'
    }
    Update-ChannelHeader
})

$autoCheckBtn.Add_Click({
    if ($channelList.SelectedIndices.Count -ne 1) {
        [System.Windows.Forms.MessageBox]::Show("Select exactly one channel to enable or disable Auto Check", "Select one channel", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $ch = $global:channelRows[$channelList.SelectedIndex]
    try {
        if (Test-AutoCheckEnabled ([string]$ch.url)) {
            if (-not (Disable-AutoCheck ([string]$ch.url))) { throw "Could not disable Auto Check for $($ch.name)." }
            Set-Status "Auto Check disabled: $($ch.name)" 'ok'
        } else {
            if (-not (Enable-AutoCheck $ch)) { throw "Could not enable Auto Check for $($ch.name)." }
            Set-Status "Auto Check enabled: $($ch.name)" 'ok'
        }
    } catch {
        Set-Status "Auto Check failed: $($ch.name)" 'err'
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Auto Check", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    Refresh-ChannelList
    Update-ChannelHeader
    Refresh-RecordingList
})

$disableAutoCheckBtn.Add_Click({
    if ($autoCheckList.SelectedIndices.Count -ne 1) {
        [System.Windows.Forms.MessageBox]::Show("Select one enabled channel to disable Auto Check", "Select one channel", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $ch = $global:autoCheckRows[$autoCheckList.SelectedIndex]
    try {
        if (-not (Disable-AutoCheck ([string]$ch.url))) { throw "Could not disable Auto Check for $($ch.name)." }
        Set-Status "Auto Check disabled: $($ch.name)" 'ok'
    } catch {
        Set-Status "Auto Check failed: $($ch.name)" 'err'
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Auto Check", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    Refresh-ChannelList
    Update-ChannelHeader
    Refresh-RecordingList
})

$scheduleBtn.Add_Click({
    try {
        if ($channelList.SelectedIndex -eq -1) {
            [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Nothing selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }

        $scheduleDate = $scheduleDatePicker.Value.Date
        $scheduleTime = $scheduleTimePicker.Value.TimeOfDay
        $scheduleDateTime = $scheduleDate.Add($scheduleTime)

        if ($scheduleDateTime -lt (Get-Date)) {
            [System.Windows.Forms.MessageBox]::Show("Cannot schedule in the past", "Invalid time", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }

        $scheduleTimeStr = $scheduleDateTime.ToString("yyyy-MM-dd HH:mm")

        foreach ($idx in $channelList.SelectedIndices) {
            $ch = $global:channelRows[$idx]
            $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH_mm")
            $filename = "$($ch.name)-SHOWROOM-$timestamp.mp4"
            $outputPath = Join-Path $saveBox.Text $filename

            $taskName = "SHOWROOM_REC_$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
           $streamlinkCommand = Get-Command streamlink -ErrorAction Stop
            $streamlinkPath = if ($streamlinkCommand.Path) { [string]$streamlinkCommand.Path } else { [string]$streamlinkCommand.Source }
            $streamlinkArguments = Join-WindowsCommandLine @([string]$ch.url, 'best', '-o', [string]$outputPath, '--force')
            $action = New-ScheduledTaskAction -Execute $streamlinkPath -Argument $streamlinkArguments
            $trigger = New-ScheduledTaskTrigger -Once -At $scheduleDateTime
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            $principal = Get-InteractiveTaskPrincipal

            Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Principal $principal -Description "Record $($ch.name)" -Force -ErrorAction Stop | Out-Null

            Set-Status "Scheduled: $($ch.name) at $scheduleTimeStr" 'ok'
        }

        [System.Windows.Forms.MessageBox]::Show("Recording scheduled for $scheduleTimeStr", "Scheduled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

try {
    Reconcile-AutoChecks
} catch {
    Write-Host "Auto-check startup reconciliation failed: $_"
}

Refresh-ChannelList

$refreshTimer = New-Object System.Windows.Forms.Timer
$refreshTimer.Interval = 5000
$refreshTimer.Add_Tick({ Refresh-RecordingList })
$refreshTimer.Start()

Refresh-RecordingList
Update-ChannelHeader
$form.ShowDialog() | Out-Null
