# SHOWROOM Recorder GUI

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "SHOWROOM Recorder"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

# Set icon
$iconPath = Join-Path $PSScriptRoot "app.ico"
if (Test-Path $iconPath) {
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
}

# Light Mode
$form.BackColor = [System.Drawing.Color]::White
$form.ForeColor = [System.Drawing.Color]::Black

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 15)
$label.Size = New-Object System.Drawing.Size(750, 30)
$label.Text = "SHOWROOM Recorder - Record Japanese Idol Streams"
$label.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

$saveLabel = New-Object System.Windows.Forms.Label
$saveLabel.Location = New-Object System.Drawing.Point(20, 55)
$saveLabel.Size = New-Object System.Drawing.Size(100, 20)
$saveLabel.Text = "Save Location:"
$form.Controls.Add($saveLabel)

$saveBox = New-Object System.Windows.Forms.TextBox
$saveBox.Location = New-Object System.Drawing.Point(120, 55)
$saveBox.Size = New-Object System.Drawing.Size(500, 25)
$saveBox.Text = "C:\Recordings"
if (Test-Path "$env:APPDATA\SHOWROOMRecorder\savepath.txt") {
    $savedPath = Get-Content "$env:APPDATA\SHOWROOMRecorder\savepath.txt"
    if (Test-Path $savedPath) { $saveBox.Text = $savedPath }
}
$form.Controls.Add($saveBox)

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Location = New-Object System.Drawing.Point(630, 53)
$browseBtn.Size = New-Object System.Drawing.Size(100, 28)
$browseBtn.Text = "Browse..."
$browseBtn.Add_Click({
    $folder = New-Object System.Windows.Forms.FolderBrowserDialog
    $folder.Description = "Select folder to save recordings"
    if ($folder.ShowDialog() -eq "OK") {
        $saveBox.Text = $folder.SelectedPath
        $saveBox.Text | Set-Content "$env:APPDATA\SHOWROOMRecorder\savepath.txt"
    }
})
$form.Controls.Add($browseBtn)

$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Location = New-Object System.Drawing.Point(20, 95)
$inputLabel.Size = New-Object System.Drawing.Size(300, 20)
$inputLabel.Text = "Add Channel (URL + Japanese Name):"
$form.Controls.Add($inputLabel)

$urlLabel = New-Object System.Windows.Forms.Label
$urlLabel.Location = New-Object System.Drawing.Point(30, 125)
$urlLabel.Size = New-Object System.Drawing.Size(40, 20)
$urlLabel.Text = "URL:"
$form.Controls.Add($urlLabel)

$urlBox = New-Object System.Windows.Forms.TextBox
$urlBox.Location = New-Object System.Drawing.Point(70, 125)
$urlBox.Size = New-Object System.Drawing.Size(350, 25)
$urlBox.Text = "https://www.showroom-live.com/r/"
$form.Controls.Add($urlBox)

$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Location = New-Object System.Drawing.Point(430, 125)
$nameLabel.Size = New-Object System.Drawing.Size(50, 20)
$nameLabel.Text = "Name:"
$form.Controls.Add($nameLabel)

$nameBox = New-Object System.Windows.Forms.TextBox
$nameBox.Location = New-Object System.Drawing.Point(480, 125)
$nameBox.Size = New-Object System.Drawing.Size(200, 25)
$nameBox.Text = ""
$form.Controls.Add($nameBox)

$addBtn = New-Object System.Windows.Forms.Button
$addBtn.Location = New-Object System.Drawing.Point(690, 123)
$addBtn.Size = New-Object System.Drawing.Size(80, 28)
$addBtn.Text = "Add"
$addBtn.Add_Click({
    try {
        $url = $urlBox.Text
        $jname = $nameBox.Text
        if ($url -match 'showroom-live\.com/r/([^/\?]+)') {
            $channel = $Matches[1]
            $newChannel = @{
                url = $url
                channel = $channel
                name = if ($jname) { $jname } else { $channel }
            }
            [void]$global:channels.Add($newChannel)
            UpdateChannelList
            # Save to file with UTF-8 BOM
            $json = @()
            foreach ($ch in $global:channels) { $json += $ch }
            $utf8Bom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText("$env:APPDATA\SHOWROOMRecorder\channels.json", ($json | ConvertTo-Json -Depth 10), $utf8Bom)
            $urlBox.Text = "https://www.showroom-live.com/r/"
            $nameBox.Text = ""
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please enter valid SHOWROOM URL", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($addBtn)

$listLabel = New-Object System.Windows.Forms.Label
$listLabel.Location = New-Object System.Drawing.Point(20, 160)
$listLabel.Size = New-Object System.Drawing.Size(200, 20)
$listLabel.Text = "Channels to Record:"
$form.Controls.Add($listLabel)

$channelList = New-Object System.Windows.Forms.ListView
$channelList.Location = New-Object System.Drawing.Point(20, 185)
$channelList.Size = New-Object System.Drawing.Size(750, 200)
$channelList.View = [System.Windows.Forms.View]::Details
$channelList.Columns.Add("Channel ID", 180)
$channelList.Columns.Add("Japanese Name", 280)
$channelList.Columns.Add("URL", 280)
$channelList.FullRowSelect = $true
$form.Controls.Add($channelList)

$global:channels = [System.Collections.ArrayList]@()

function UpdateChannelList {
    $channelList.Items.Clear()
    for ($i = 0; $i -lt $global:channels.Count; $i++) {
        $ch = $global:channels[$i]
        $item = New-Object System.Windows.Forms.ListViewItem($ch.channel)
        $item.SubItems.Add($ch.name)
        $item.SubItems.Add($ch.url)
        $channelList.Items.Add($item)
    }
}

$recordSelectedBtn = New-Object System.Windows.Forms.Button
$recordSelectedBtn.Location = New-Object System.Drawing.Point(20, 395)
$recordSelectedBtn.Size = New-Object System.Drawing.Size(160, 35)
$recordSelectedBtn.Text = "Record Selected"
$recordSelectedBtn.BackColor = [System.Drawing.Color]::LightGreen
$recordSelectedBtn.Add_Click({
    foreach ($item in $channelList.SelectedItems) {
        $ch = $global:channels[$item.Index]
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH_mm"
        $filename = "$($ch.name)-SHOWROOM-$timestamp.mp4"
        $output = Join-Path $saveBox.Text $filename
        
        $statusLabel.Text = "Recording: $($ch.name)"
        
        # Start streamlink process
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "streamlink"
        $psi.Arguments = "`"$($ch.url)`" best -o `"$output`" --force"
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $false
        $psi.RedirectStandardError = $false
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        
        $recordingList.Items.Add($ch.name)
    }
})
$form.Controls.Add($recordSelectedBtn)

$recordAllBtn = New-Object System.Windows.Forms.Button
$recordAllBtn.Location = New-Object System.Drawing.Point(190, 395)
$recordAllBtn.Size = New-Object System.Drawing.Size(160, 35)
$recordAllBtn.Text = "Record All"
$recordAllBtn.BackColor = [System.Drawing.Color]::LightGreen
$recordAllBtn.Add_Click({
    foreach ($ch in $global:channels) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH_mm"
        $filename = "$($ch.name)-SHOWROOM-$timestamp.mp4"
        $output = Join-Path $saveBox.Text $filename
        
        $statusLabel.Text = "Recording: $($ch.name)"
        
        # Start streamlink process
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "streamlink"
        $psi.Arguments = "`"$($ch.url)`" best -o `"$output`" --force"
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $false
        $psi.RedirectStandardError = $false
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        
        $recordingList.Items.Add($ch.name)
    }
})
$form.Controls.Add($recordAllBtn)

# Schedule Section
$scheduleLabel = New-Object System.Windows.Forms.Label
$scheduleLabel.Location = New-Object System.Drawing.Point(20, 445)
$scheduleLabel.Size = New-Object System.Drawing.Size(200, 20)
$scheduleLabel.Text = "Schedule Recording:"
$scheduleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($scheduleLabel)

# Show scheduled count
$scheduleCountLabel = New-Object System.Windows.Forms.Label
$scheduleCountLabel.Location = New-Object System.Drawing.Point(640, 445)
$scheduleCountLabel.Size = New-Object System.Drawing.Size(150, 20)
$scheduleFile = "$env:APPDATA\SHOWROOMRecorder\scheduled.json"
if (Test-Path $scheduleFile) {
    try {
        $schedules = Get-Content $scheduleFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($schedules -is [Array]) {
            $scheduleCountLabel.Text = "$($schedules.Count) scheduled"
        } else {
            $scheduleCountLabel.Text = "1 scheduled"
        }
    } catch {
        $scheduleCountLabel.Text = ""
    }
} else {
    $scheduleCountLabel.Text = ""
}
$form.Controls.Add($scheduleCountLabel)

$scheduleDateLabel = New-Object System.Windows.Forms.Label
$scheduleDateLabel.Location = New-Object System.Drawing.Point(20, 470)
$scheduleDateLabel.Size = New-Object System.Drawing.Size(80, 20)
$scheduleDateLabel.Text = "Date:"
$form.Controls.Add($scheduleDateLabel)

$scheduleDatePicker = New-Object System.Windows.Forms.DateTimePicker
$scheduleDatePicker.Location = New-Object System.Drawing.Point(100, 468)
$scheduleDatePicker.Size = New-Object System.Drawing.Size(150, 25)
$scheduleDatePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$scheduleDatePicker.Value = (Get-Date).AddHours(1)
$form.Controls.Add($scheduleDatePicker)

$scheduleTimeLabel = New-Object System.Windows.Forms.Label
$scheduleTimeLabel.Location = New-Object System.Drawing.Point(260, 470)
$scheduleTimeLabel.Size = New-Object System.Drawing.Size(50, 20)
$scheduleTimeLabel.Text = "Time:"
$form.Controls.Add($scheduleTimeLabel)

$scheduleTimePicker = New-Object System.Windows.Forms.DateTimePicker
$scheduleTimePicker.Location = New-Object System.Drawing.Point(310, 468)
$scheduleTimePicker.Size = New-Object System.Drawing.Size(100, 25)
$scheduleTimePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Time
$scheduleTimePicker.ShowUpDown = $true
$scheduleTimePicker.Value = (Get-Date).AddHours(1)
$form.Controls.Add($scheduleTimePicker)

$scheduleBtn = New-Object System.Windows.Forms.Button
$scheduleBtn.Location = New-Object System.Drawing.Point(420, 466)
$scheduleBtn.Size = New-Object System.Drawing.Size(100, 28)
$scheduleBtn.Text = "Schedule"
$scheduleBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
$scheduleBtn.ForeColor = [System.Drawing.Color]::White
$scheduleBtn.Add_Click({
    try {
        if ($channelList.SelectedItems.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select a channel first", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        # Combine date and time
        $scheduleDate = $scheduleDatePicker.Value.Date
        $scheduleTime = $scheduleTimePicker.Value.TimeOfDay
        $scheduleDateTime = $scheduleDate.Add($scheduleTime)
        
        if ($scheduleDateTime -lt (Get-Date)) {
            [System.Windows.Forms.MessageBox]::Show("Cannot schedule in the past", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $scheduleTimeStr = $scheduleDateTime.ToString("yyyy-MM-dd HH:mm")
        $selectedItems = @()
        foreach ($item in $channelList.SelectedItems) {
            $selectedItems += $global:channels[$item.Index]
        }
        
        foreach ($ch in $selectedItems) {
            $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH_mm")
            $filename = "$($ch.name)-SHOWROOM-$timestamp.mp4"
            $outputPath = Join-Path $saveBox.Text $filename
            
            # Create scheduled task
            $taskName = "SHOWROOM_REC_$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
            $cmd = "streamlink `"$($ch.url)`" best -o `"$outputPath`" --force"
            
            $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /MIN $cmd"
            $trigger = New-ScheduledTaskTrigger -Once -At $scheduleDateTime
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            
            Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Description "Record $($ch.name)" -Force | Out-Null
            
            # Save to JSON file
            $scheduleData = @{
                taskName = $taskName
                channelName = $ch.name
                channelUrl = $ch.url
                scheduleTime = $scheduleDateTime.ToString("yyyy-MM-dd HH:mm")
                outputPath = $outputPath
                createdAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            
            $scheduleFile = "$env:APPDATA\SHOWROOMRecorder\scheduled.json"
            if (!(Test-Path (Split-Path $scheduleFile -Parent))) {
                New-Item -ItemType Directory -Path (Split-Path $scheduleFile -Parent) -Force | Out-Null
            }
            
            $existingSchedules = @()
            if (Test-Path $scheduleFile) {
                try {
                    $existingSchedules = Get-Content $scheduleFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($existingSchedules -isnot [Array]) { $existingSchedules = @($existingSchedules) }
                } catch {}
            }
            $existingSchedules += $scheduleData
            $existingSchedules | ConvertTo-Json -Depth 10 | Set-Content $scheduleFile -Encoding UTF8
            
            $statusLabel.Text = "Scheduled: $($ch.name) at $scheduleTimeStr"
        }
        
        [System.Windows.Forms.MessageBox]::Show("Recording scheduled for $scheduleTimeStr", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($scheduleBtn)

$viewScheduledBtn = New-Object System.Windows.Forms.Button
$viewScheduledBtn.Location = New-Object System.Drawing.Point(530, 466)
$viewScheduledBtn.Size = New-Object System.Drawing.Size(100, 28)
$viewScheduledBtn.Text = "View"
$viewScheduledBtn.Add_Click({
    $scheduleFile = "$env:APPDATA\SHOWROOMRecorder\scheduled.json"
    if (!(Test-Path $scheduleFile)) {
        [System.Windows.Forms.MessageBox]::Show("No scheduled recordings", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    try {
        $schedules = Get-Content $scheduleFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($schedules -isnot [Array]) { $schedules = @($schedules) }
        
        $taskInfo = @()
        foreach ($s in $schedules) {
            $taskInfo += "$($s.channelName) - $($s.scheduleTime)`n  Output: $($s.outputPath)"
        }
        [System.Windows.Forms.MessageBox]::Show(($taskInfo -join "`n`n"), "Scheduled Recordings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error loading schedules: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($viewScheduledBtn)

$stopBtn = New-Object System.Windows.Forms.Button
$stopBtn.Location = New-Object System.Drawing.Point(360, 395)
$stopBtn.Size = New-Object System.Drawing.Size(80, 35)
$stopBtn.Text = "Stop All"
$stopBtn.BackColor = [System.Drawing.Color]::LightCoral
$stopBtn.Add_Click({
    Get-Process -Name "streamlink" -ErrorAction SilentlyContinue | Stop-Process -Force
    $recordingList.Items.Clear()
    $statusLabel.Text = "All stopped"
})
$form.Controls.Add($stopBtn)

$stopSelectedBtn = New-Object System.Windows.Forms.Button
$stopSelectedBtn.Location = New-Object System.Drawing.Point(445, 395)
$stopSelectedBtn.Size = New-Object System.Drawing.Size(80, 35)
$stopSelectedBtn.Text = "Stop Selected"
$stopSelectedBtn.BackColor = [System.Drawing.Color]::Orange
$stopSelectedBtn.Add_Click({
    # Get selected channel names and stop their processes
    $selected = @()
    foreach ($item in $recordingList.SelectedItems) {
        $selected += $item.Text
    }
    if ($selected.Count -gt 0) {
        # Find and stop matching streamlink processes
        $procs = Get-Process -Name "streamlink" -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            # Try to match by window title or command line
            try {
                $cmdline = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)").CommandLine
                foreach ($name in $selected) {
                    if ($cmdline -like "*$name*") {
                        $p | Stop-Process -Force
                        $recordingList.Items.RemoveByKey($name)
                    }
                }
            } catch {}
        }
        # Also remove from list
        $toRemove = @()
        foreach ($item in $recordingList.SelectedItems) {
            $toRemove += $item
        }
        foreach ($item in $toRemove) {
            $recordingList.Items.Remove($item)
        }
        $statusLabel.Text = "Stopped $($selected.Count) recording(s)"
    }
})
$form.Controls.Add($stopSelectedBtn)

$removeBtn = New-Object System.Windows.Forms.Button
$removeBtn.Location = New-Object System.Drawing.Point(530, 395)
$removeBtn.Size = New-Object System.Drawing.Size(160, 35)
$removeBtn.Text = "Remove Selected"
$removeBtn.Add_Click({
    try {
        $selected = @()
        foreach ($item in $channelList.SelectedItems) {
            $selected += $item.Index
        }
        if ($selected.Count -gt 0) {
            $selected = $selected | Sort-Object -Descending
            foreach ($idx in $selected) {
                [void]$global:channels.RemoveAt($idx)
            }
            UpdateChannelList
            # Save to file with UTF-8 BOM
            $json = @()
            foreach ($ch in $global:channels) { $json += $ch }
            $utf8Bom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText("$env:APPDATA\SHOWROOMRecorder\channels.json", ($json | ConvertTo-Json -Depth 10), $utf8Bom)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($removeBtn)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 530)
$statusLabel.Size = New-Object System.Drawing.Size(750, 25)
$statusLabel.Text = "Ready - Add channels and click Record"
$form.Controls.Add($statusLabel)

$recLabel = New-Object System.Windows.Forms.Label
$recLabel.Location = New-Object System.Drawing.Point(20, 535)
$recLabel.Size = New-Object System.Drawing.Size(200, 20)
$recLabel.Text = "Currently Recording:"
$form.Controls.Add($recLabel)

$recordingList = New-Object System.Windows.Forms.ListBox
$recordingList.Location = New-Object System.Drawing.Point(20, 560)
$recordingList.Size = New-Object System.Drawing.Size(750, 80)
$form.Controls.Add($recordingList)

$configFile = "$env:APPDATA\SHOWROOMRecorder\channels.json"
if (Test-Path $configFile) {
    try {
        $loaded = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $global:channels = [System.Collections.ArrayList]@()
        if ($loaded -is [Array]) {
            foreach ($item in $loaded) { [void]$global:channels.Add($item) }
        } else {
            [void]$global:channels.Add($loaded)
        }
        UpdateChannelList
    } catch {
        $global:channels = [System.Collections.ArrayList]@()
    }
}

$form.Add_FormClosing({
    try {
        $configPath = "$env:APPDATA\SHOWROOMRecorder"
        if (!(Test-Path $configPath)) { New-Item -ItemType Directory -Path $configPath -Force }
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText("$configPath\channels.json", ($global:channels | ConvertTo-Json -Depth 10), $utf8Bom)
    } catch {}
})

$form.ShowDialog()
