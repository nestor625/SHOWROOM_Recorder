# SHOWROOM Recorder GUI with Scheduling

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "SHOWROOM Recorder"
$form.Size = New-Object System.Drawing.Size(850, 650)
$form.StartPosition = "CenterScreen"

$global:channels = @()

# Load saved channels
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

# Load saved location
$settingsFile = "$env:APPDATA\SHOWROOMRecorder\settings.json"
$defaultSavePath = "C:\Recordings"
if (Test-Path $settingsFile) {
    try {
        $settings = Get-Content $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($settings.savePath) {
            $defaultSavePath = $settings.savePath
        }
    } catch {
        Write-Host "Error loading settings: $_"
    }
}

# Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(300, 30)
$titleLabel.Text = "SHOWROOM Recorder"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($titleLabel)

# Save location
$saveLabel = New-Object System.Windows.Forms.Label
$saveLabel.Location = New-Object System.Drawing.Point(20, 55)
$saveLabel.Size = New-Object System.Drawing.Size(100, 20)
$saveLabel.Text = "Save Location:"
$form.Controls.Add($saveLabel)

$saveBox = New-Object System.Windows.Forms.TextBox
$saveBox.Location = New-Object System.Drawing.Point(120, 53)
$saveBox.Size = New-Object System.Drawing.Size(400, 25)
if ($defaultSavePath) {
    $saveBox.Text = $defaultSavePath
} else {
    $saveBox.Text = "C:\Recordings"
}
$form.Controls.Add($saveBox)

$saveBrowseBtn = New-Object System.Windows.Forms.Button
$saveBrowseBtn.Location = New-Object System.Drawing.Point(530, 52)
$saveBrowseBtn.Size = New-Object System.Drawing.Size(80, 25)
$saveBrowseBtn.Text = "Browse"
$saveBrowseBtn.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.SelectedPath = $saveBox.Text
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $saveBox.Text = $folderBrowser.SelectedPath
        
        # Save location
        $settingsFile = "$env:APPDATA\SHOWROOMRecorder\settings.json"
        $settings = @{savePath=$saveBox.Text} | ConvertTo-Json
        Set-Content $settingsFile $settings -Encoding UTF8
    }
})
$form.Controls.Add($saveBrowseBtn)

# Add channel
$addLabel = New-Object System.Windows.Forms.Label
$addLabel.Location = New-Object System.Drawing.Point(20, 95)
$addLabel.Size = New-Object System.Drawing.Size(100, 20)
$addLabel.Text = "Add Channel:"
$form.Controls.Add($addLabel)

$urlLabel = New-Object System.Windows.Forms.Label
$urlLabel.Location = New-Object System.Drawing.Point(20, 120)
$urlLabel.Size = New-Object System.Drawing.Size(40, 20)
$urlLabel.Text = "URL:"
$form.Controls.Add($urlLabel)

$urlBox = New-Object System.Windows.Forms.TextBox
$urlBox.Location = New-Object System.Drawing.Point(60, 118)
$urlBox.Size = New-Object System.Drawing.Size(350, 25)
$urlBox.Text = "https://www.showroom-live.com/r/"
$form.Controls.Add($urlBox)

$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Location = New-Object System.Drawing.Point(420, 120)
$nameLabel.Size = New-Object System.Drawing.Size(50, 20)
$nameLabel.Text = "Name:"
$form.Controls.Add($nameLabel)

$nameBox = New-Object System.Windows.Forms.TextBox
$nameBox.Location = New-Object System.Drawing.Point(470, 118)
$nameBox.Size = New-Object System.Drawing.Size(150, 25)
$form.Controls.Add($nameBox)

$addBtn = New-Object System.Windows.Forms.Button
$addBtn.Location = New-Object System.Drawing.Point(630, 116)
$addBtn.Size = New-Object System.Drawing.Size(80, 28)
$addBtn.Text = "Add"
$addBtn.Add_Click({
    if ($urlBox.Text -and $nameBox.Text) {
        $global:channels += @{url=$urlBox.Text; name=$nameBox.Text}
        $channelList.Items.Add("$($nameBox.Text)")
        
        # Save channels
        $channelsFile = "$env:APPDATA\SHOWROOMRecorder\channels.json"
        if (!(Test-Path (Split-Path $channelsFile -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $channelsFile -Parent) -Force | Out-Null
        }
        $global:channels | ConvertTo-Json -Depth 10 | Out-File -FilePath $channelsFile -Encoding UTF8
        
        $urlBox.Text = "https://www.showroom-live.com/r/"
        $nameBox.Text = ""
    }
})
$form.Controls.Add($addBtn)

# Channel list
$channelLabel = New-Object System.Windows.Forms.Label
$channelLabel.Location = New-Object System.Drawing.Point(20, 155)
$channelLabel.Size = New-Object System.Drawing.Size(100, 20)
$channelLabel.Text = "Channels:"
$form.Controls.Add($channelLabel)

$channelList = New-Object System.Windows.Forms.ListBox
$channelList.Location = New-Object System.Drawing.Point(20, 180)
$channelList.Size = New-Object System.Drawing.Size(700, 120)
$channelList.SelectionMode = "MultiExtended"
$form.Controls.Add($channelList)

# Populate saved channels
foreach ($ch in $global:channels) {
    $channelList.Items.Add($ch.name)
}

# Record buttons
$recordSelectedBtn = New-Object System.Windows.Forms.Button
$recordSelectedBtn.Location = New-Object System.Drawing.Point(20, 310)
$recordSelectedBtn.Size = New-Object System.Drawing.Size(100, 35)
$recordSelectedBtn.Text = "Record"
$recordSelectedBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$recordSelectedBtn.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($recordSelectedBtn)

$recordAllBtn = New-Object System.Windows.Forms.Button
$recordAllBtn.Location = New-Object System.Drawing.Point(130, 310)
$recordAllBtn.Size = New-Object System.Drawing.Size(100, 35)
$recordAllBtn.Text = "All"
$recordAllBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$recordAllBtn.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($recordAllBtn)

$stopBtn = New-Object System.Windows.Forms.Button
$stopBtn.Location = New-Object System.Drawing.Point(240, 310)
$stopBtn.Size = New-Object System.Drawing.Size(80, 35)
$stopBtn.Text = "Stop"
$stopBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$stopBtn.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($stopBtn)

$removeBtn = New-Object System.Windows.Forms.Button
$removeBtn.Location = New-Object System.Drawing.Point(330, 310)
$removeBtn.Size = New-Object System.Drawing.Size(80, 35)
$removeBtn.Text = "Delete"
$removeBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$removeBtn.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($removeBtn)

$viewScheduleBtn = New-Object System.Windows.Forms.Button
$viewScheduleBtn.Location = New-Object System.Drawing.Point(420, 310)
$viewScheduleBtn.Size = New-Object System.Drawing.Size(80, 35)
$viewScheduleBtn.Text = "View"
$viewScheduleBtn.Add_Click({
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "SHOWROOM_REC_*" }
    if ($tasks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No scheduled recordings", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        $taskInfo = @()
        foreach ($t in $tasks) {
            $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -ErrorAction SilentlyContinue
            $taskInfo += "$($t.TaskName) - Next: $($info.NextRunTime)"
        }
        [System.Windows.Forms.MessageBox]::Show(($taskInfo -join "`n"), "Scheduled Recordings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})
$form.Controls.Add($viewScheduleBtn)

# Schedule Section
$scheduleLabel = New-Object System.Windows.Forms.Label
$scheduleLabel.Location = New-Object System.Drawing.Point(20, 360)
$scheduleLabel.Size = New-Object System.Drawing.Size(200, 20)
$scheduleLabel.Text = "Schedule Recording:"
$scheduleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($scheduleLabel)

$scheduleDateLabel = New-Object System.Windows.Forms.Label
$scheduleDateLabel.Location = New-Object System.Drawing.Point(20, 385)
$scheduleDateLabel.Size = New-Object System.Drawing.Size(50, 20)
$scheduleDateLabel.Text = "Date:"
$form.Controls.Add($scheduleDateLabel)

$scheduleDatePicker = New-Object System.Windows.Forms.DateTimePicker
$scheduleDatePicker.Location = New-Object System.Drawing.Point(70, 383)
$scheduleDatePicker.Size = New-Object System.Drawing.Size(150, 25)
$scheduleDatePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$scheduleDatePicker.Value = (Get-Date).AddHours(1)
$form.Controls.Add($scheduleDatePicker)

$scheduleTimeLabel = New-Object System.Windows.Forms.Label
$scheduleTimeLabel.Location = New-Object System.Drawing.Point(230, 385)
$scheduleTimeLabel.Size = New-Object System.Drawing.Size(50, 20)
$scheduleTimeLabel.Text = "Time:"
$form.Controls.Add($scheduleTimeLabel)

$scheduleTimePicker = New-Object System.Windows.Forms.DateTimePicker
$scheduleTimePicker.Location = New-Object System.Drawing.Point(280, 383)
$scheduleTimePicker.Size = New-Object System.Drawing.Size(100, 25)
$scheduleTimePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Time
$scheduleTimePicker.ShowUpDown = $true
$scheduleTimePicker.Value = (Get-Date).AddHours(1)
$form.Controls.Add($scheduleTimePicker)

$scheduleBtn = New-Object System.Windows.Forms.Button
$scheduleBtn.Location = New-Object System.Drawing.Point(390, 381)
$scheduleBtn.Size = New-Object System.Drawing.Size(100, 28)
$scheduleBtn.Text = "Schedule"
$scheduleBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
$scheduleBtn.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($scheduleBtn)

# Recording status
$recLabel = New-Object System.Windows.Forms.Label
$recLabel.Location = New-Object System.Drawing.Point(20, 420)
$recLabel.Size = New-Object System.Drawing.Size(150, 20)
$recLabel.Text = "Currently Recording:"
$form.Controls.Add($recLabel)

$recordingList = New-Object System.Windows.Forms.ListBox
$recordingList.Location = New-Object System.Drawing.Point(20, 445)
$recordingList.Size = New-Object System.Drawing.Size(700, 80)
$form.Controls.Add($recordingList)

# Status
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 535)
$statusLabel.Size = New-Object System.Drawing.Size(500, 20)
$statusLabel.Text = "Ready"
$form.Controls.Add($statusLabel)

# Record Selected button
$recordSelectedBtn.Add_Click({
    if ($channelList.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    foreach ($idx in $channelList.SelectedIndices) {
        $ch = $global:channels[$idx]
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH_mm"
        $filename = "$($ch.name)-SHOWROOM-$timestamp.mp4"
        $output = Join-Path $saveBox.Text $filename
        
        $statusLabel.Text = "Recording: $($ch.name)"
        
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "streamlink"
        $psi.Arguments = "`"$($ch.url)`" best -o `"$output`" --force"
        $psi.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        
        $recordingList.Items.Add($ch.name)
    }
})

# Record All button
$recordAllBtn.Add_Click({
    if ($global:channels.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No channels added", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    foreach ($ch in $global:channels) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH_mm"
        $filename = "$($ch.name)-SHOWROOM-$timestamp.mp4"
        $output = Join-Path $saveBox.Text $filename
        
        $statusLabel.Text = "Recording: $($ch.name)"
        
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "streamlink"
        $psi.Arguments = "`"$($ch.url)`" best -o `"$output`" --force"
        $psi.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        
        $recordingList.Items.Add($ch.name)
    }
})

# Stop button
$stopBtn.Add_Click({
    if ($recordingList.SelectedIndex -ge 0) {
        $selectedName = $recordingList.SelectedItem
        # Kill streamlink processes
        Get-Process -Name streamlink -ErrorAction SilentlyContinue | Stop-Process -Force
        $recordingList.Items.RemoveAt($recordingList.SelectedIndex)
        $statusLabel.Text = "Stopped: $selectedName"
    } else {
        Get-Process -Name streamlink -ErrorAction SilentlyContinue | Stop-Process -Force
        $recordingList.Items.Clear()
        $statusLabel.Text = "Stopped all"
    }
})

# Delete button
$removeBtn.Add_Click({
    if ($channelList.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $selectedIndices = @($channelList.SelectedIndices)
    [array]::Reverse($selectedIndices)
    
    $newChannels = @()
    for ($i = 0; $i -lt $global:channels.Count; $i++) {
        if ($selectedIndices -notcontains $i) {
            $newChannels += $global:channels[$i]
        }
    }
    $global:channels = $newChannels
    
    # Refresh list
    $channelList.Items.Clear()
    foreach ($ch in $global:channels) {
        $channelList.Items.Add($ch.name)
    }
    
    # Save channels
    $channelsFile = "$env:APPDATA\SHOWROOMRecorder\channels.json"
    $global:channels | ConvertTo-Json -Depth 10 | Out-File -FilePath $channelsFile -Encoding UTF8
    
    $statusLabel.Text = "Channel(s) deleted"
})

# Schedule button
$scheduleBtn.Add_Click({
    try {
        if ($channelList.SelectedIndex -eq -1) {
            [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $scheduleDate = $scheduleDatePicker.Value.Date
        $scheduleTime = $scheduleTimePicker.Value.TimeOfDay
        $scheduleDateTime = $scheduleDate.Add($scheduleTime)
        
        if ($scheduleDateTime -lt (Get-Date)) {
            [System.Windows.Forms.MessageBox]::Show("Cannot schedule in the past", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
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
            
            $statusLabel.Text = "Scheduled: $($ch.name) at $scheduleTimeStr"
        }
        
        [System.Windows.Forms.MessageBox]::Show("Recording scheduled for $scheduleTimeStr", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$form.ShowDialog()
