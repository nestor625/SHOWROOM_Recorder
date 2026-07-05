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

function Update-ChannelHeader {
    $gChannels.Text = "  🎬  Channels  ($($global:channels.Count))"
}

function Start-Recording($ch) {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH_mm"
    $filename  = "$($ch.name)-SHOWROOM-$timestamp.mp4"
    $output    = Join-Path $saveBox.Text $filename
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "streamlink"
        $psi.Arguments = "`"$($ch.url)`" best -o `"$output`" --force --retry-streams 30"
        $psi.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        $recordingList.Items.Add($ch.name)
        Set-Status "Recording: $($ch.name)" 'rec'
    } catch {
        Set-Status "Streamlink not found — install from streamlink.github.io" 'err'
        [System.Windows.Forms.MessageBox]::Show("Could not start streamlink. Is it installed and on your PATH?`n`n$($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

# ---------------------------------------------------------------- Data
$global:channels = @()

$channelsFile = "$env:APPDATA\SHOWROOMRecorder\channels.json"
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

$settingsFile = "$env:APPDATA\SHOWROOMRecorder\settings.json"
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
        $settingsFile = "$env:APPDATA\SHOWROOMRecorder\settings.json"
        if (!(Test-Path (Split-Path $settingsFile -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $settingsFile -Parent) -Force | Out-Null
        }
        $settings = @{savePath = $saveBox.Text} | ConvertTo-Json
        Set-Content $settingsFile $settings -Encoding UTF8
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
        $channelList.Items.Add("$($nameBox.Text)")

        $channelsFile = "$env:APPDATA\SHOWROOMRecorder\channels.json"
        if (!(Test-Path (Split-Path $channelsFile -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $channelsFile -Parent) -Force | Out-Null
        }
        $global:channels | ConvertTo-Json -Depth 10 | Out-File -FilePath $channelsFile -Encoding UTF8

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
$channelList.Size = New-Object System.Drawing.Size(804, 118)
$channelList.SelectionMode = "MultiExtended"
$channelList.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$channelList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$gChannels.Controls.Add($channelList)

foreach ($ch in $global:channels) { $channelList.Items.Add($ch.name) }

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

$hintLabel = New-Object System.Windows.Forms.Label
$hintLabel.Location = New-Object System.Drawing.Point(466, 160)
$hintLabel.AutoSize = $true
$hintLabel.Text = "Tip: double-click a channel to record it"
$hintLabel.ForeColor = [System.Drawing.Color]::FromArgb(140, 145, 150)
$hintLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Italic)
$gChannels.Controls.Add($hintLabel)

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
$recordingList.Size = New-Object System.Drawing.Size(280, 80)
$recordingList.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$recordingList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$gRecording.Controls.Add($recordingList)

$stopBtn = New-Object System.Windows.Forms.Button
$stopBtn.Location = New-Object System.Drawing.Point(302, 24)
$stopBtn.Size = New-Object System.Drawing.Size(94, 80)
$stopBtn.Text = "⏹`nStop"
Style-Btn $stopBtn $clrStop
$gRecording.Controls.Add($stopBtn)

# ---------------------------------------------------------------- Actions
$recordSelectedBtn.Add_Click({
    if ($channelList.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Nothing selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    foreach ($idx in $channelList.SelectedIndices) {
        Start-Recording $global:channels[$idx]
    }
})

$channelList.Add_DoubleClick({
    if ($channelList.SelectedIndex -ge 0) {
        Start-Recording $global:channels[$channelList.SelectedIndex]
    }
})

$recordAllBtn.Add_Click({
    if ($global:channels.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No channels added", "Nothing to record", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    foreach ($ch in $global:channels) { Start-Recording $ch }
    Set-Status "Recording all $($global:channels.Count) channels" 'rec'
})

$stopBtn.Add_Click({
    if ($recordingList.SelectedIndex -ge 0) {
        $selectedName = $recordingList.SelectedItem
        Get-Process -Name streamlink -ErrorAction SilentlyContinue | Stop-Process -Force
        $recordingList.Items.RemoveAt($recordingList.SelectedIndex)
        Set-Status "Stopped: $selectedName" 'ok'
    } else {
        Get-Process -Name streamlink -ErrorAction SilentlyContinue | Stop-Process -Force
        $recordingList.Items.Clear()
        Set-Status "Stopped all recordings" 'ok'
    }
})

$removeBtn.Add_Click({
    if ($channelList.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Nothing selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    $selectedIndices = @($channelList.SelectedIndices)
    [array]::Reverse($selectedIndices)

    $newChannels = @()
    for ($i = 0; $i -lt $global:channels.Count; $i++) {
        if ($selectedIndices -notcontains $i) { $newChannels += $global:channels[$i] }
    }
    $global:channels = $newChannels

    $channelList.Items.Clear()
    foreach ($ch in $global:channels) { $channelList.Items.Add($ch.name) }

    $channelsFile = "$env:APPDATA\SHOWROOMRecorder\channels.json"
    $global:channels | ConvertTo-Json -Depth 10 | Out-File -FilePath $channelsFile -Encoding UTF8

    Set-Status "Channel(s) deleted" 'ok'
    Update-ChannelHeader
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
            $ch = $global:channels[$idx]
            $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH_mm")
            $filename = "$($ch.name)-SHOWROOM-$timestamp.mp4"
            $outputPath = Join-Path $saveBox.Text $filename

            $taskName = "SHOWROOM_REC_$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
            $cmd = "streamlink `"$($ch.url)`" best -o `"$outputPath`" --force"

            $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /MIN $cmd"
            $trigger = New-ScheduledTaskTrigger -Once -At $scheduleDateTime
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

            Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Description "Record $($ch.name)" -Force | Out-Null

            Set-Status "Scheduled: $($ch.name) at $scheduleTimeStr" 'ok'
        }

        [System.Windows.Forms.MessageBox]::Show("Recording scheduled for $scheduleTimeStr", "Scheduled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

Update-ChannelHeader
$form.ShowDialog() | Out-Null
