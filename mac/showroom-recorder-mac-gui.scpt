-- SHOWROOM Recorder Pro (v3.0 — macOS)
-- Records SHOWROOM live streams via streamlink.
-- Feature parity with the Windows edition: record / record-all / stop /
-- live status / add / delete / schedule (launchd) / view schedule /
-- change save location — all from one consolidated, polished menu.

global streamlinkPath, homePath, dataDir, channelsFile, savePathFile, jobsDir, agentsDir, schedulesFile, autoCheckFile, autoStatusDir, autoLogsDir

-- ---------------------------------------------------------------- Setup
set homePath to do shell script "echo $HOME"
set dataDir to homePath & "/.showroom_data"
set channelsFile to dataDir & "/channels.txt"
set savePathFile to dataDir & "/save_path.txt"
set jobsDir to dataDir & "/jobs"
set schedulesFile to dataDir & "/schedules.txt"
set autoCheckFile to dataDir & "/auto_check.txt"
set autoStatusDir to dataDir & "/status"
set autoLogsDir to dataDir & "/logs"
set agentsDir to homePath & "/Library/LaunchAgents"

set streamlinkPath to ""
try
	set streamlinkPath to do shell script "command -v streamlink || echo /opt/homebrew/bin/streamlink"
	do shell script "test -x " & quoted form of streamlinkPath
on error
	display dialog "❌  Streamlink not found." & return & return & "Install it first with:" & return & "    brew install streamlink" buttons {"Quit"} default button "Quit" with icon stop with title "SHOWROOM Recorder"
	return
end try

do shell script "mkdir -p " & quoted form of (homePath & "/Recordings") & " " & quoted form of dataDir & " " & quoted form of jobsDir & " " & quoted form of autoStatusDir & " " & quoted form of autoLogsDir & " " & quoted form of agentsDir & "; touch " & quoted form of channelsFile & " " & quoted form of schedulesFile & " " & quoted form of autoCheckFile

-- ---------------------------------------------------------------- Menu loop
repeat
	set savePath to my getSavePath()
	set chData to my readChannels()
	set chNames to item 1 of chData
	set chURLs to item 2 of chData
	my reconcileAutoChecks(chNames, chURLs)
	set autoURLs to my readAutoURLs()
	set autoCount to count of autoURLs
	set recCount to my countRunning()

	set mRecord to "🔴  Record…"
	set mRecordAll to "🔴  Record ALL"
	set mStop to "⏹  Stop recording…"
	set mStatus to "📡  Live status"
	set mAuto to "📡  Auto Check…"
	set mAdd to "➕  Add channel"
	set mDelete to "🗑  Delete channel…"
	set mSchedule to "⏰  Schedule recording…"
	set mScheduled to "📅  View scheduled…"
	set mOpen to "📂  Open recordings folder"
	set mLocation to "📁  Change save location…"
	set mEdit to "📝  Edit channel list (raw)"
	set mQuit to "❌  Quit"

	set menuItems to {mRecord, mRecordAll, mStop, mStatus, mAuto, mAdd, mDelete, mSchedule, mScheduled, mOpen, mLocation, mEdit, mQuit}
	set headline to "📂 Save to:  " & savePath & return & "🎬 Channels: " & (count of chNames) & "     📡 Auto: " & autoCount & "     🔴 Recording: " & recCount

	activate
	set picked to choose from list menuItems with title "📺  SHOWROOM Recorder" with prompt headline default items {mRecord} OK button name "Select" cancel button name "Quit"
	if picked is false then exit repeat
	set action to item 1 of picked

	if action is mQuit then
		exit repeat

	else if action is mRecord then
		if (count of chNames) is 0 then
			my info("No channels yet", "Add a channel first with ➕ Add channel.", "caution")
		else
			activate
				set chosen to choose from list chNames with title "Select channels" with prompt "Choose one or more channels to record:" OK button name "Record 🔴" cancel button name "Back" with multiple selections allowed
				if chosen is not false then
					set skippedNames to {}
					repeat with nm in chosen
						set idx to my indexOf(nm as text, chNames)
						if idx > 0 then
							if my indexOf(item idx of chURLs, autoURLs) > 0 then
								set end of skippedNames to item idx of chNames
							else
								my startRecording(item idx of chURLs, item idx of chNames)
							end if
						end if
					end repeat
					if (count of skippedNames) > 0 then my info("Auto Check already active", "Skipped monitored channel(s): " & (skippedNames as text), "note")
				end if
		end if

	else if action is mRecordAll then
		if (count of chNames) is 0 then
			my info("No channels yet", "Add a channel first with ➕ Add channel.", "caution")
		else
			set proceed to true
			try
				activate
				display dialog "Start recording ALL " & (count of chNames) & " channels?" & return & "(one Terminal window each)" buttons {"Cancel", "Record ALL 🔴"} default button "Record ALL 🔴" with icon caution with title "Record ALL"
			on error number -128
				set proceed to false
			end try
			if proceed then
				set skippedNames to {}
				repeat with i from 1 to count of chNames
					if my indexOf(item i of chURLs, autoURLs) > 0 then
						set end of skippedNames to item i of chNames
					else
						my startRecording(item i of chURLs, item i of chNames)
					end if
				end repeat
				if (count of skippedNames) > 0 then my info("Auto Check already active", "Skipped monitored channel(s): " & (skippedNames as text), "note")
			end if
		end if

	else if action is mStop then
		my stopRecording()

	else if action is mStatus then
		my liveStatus()

	else if action is mAuto then
		my autoCheckFlow(chNames, chURLs)

	else if action is mAdd then
		my addChannel()

	else if action is mDelete then
		my deleteChannel(chNames, chURLs)

	else if action is mSchedule then
		my scheduleFlow(chNames, chURLs)

	else if action is mScheduled then
		my viewScheduled()

	else if action is mOpen then
		do shell script "open " & quoted form of savePath

	else if action is mLocation then
		my changeLocation()

	else if action is mEdit then
		do shell script "open -e " & quoted form of channelsFile
	end if
end repeat

-- ---------------------------------------------------------------- Data
on getSavePath()
	global savePathFile, homePath
	set p to homePath & "/Recordings"
	try
		set stored to do shell script "cat " & quoted form of savePathFile
		if stored is not "" then set p to stored
	end try
	return p
end getSavePath

on readChannels()
	global channelsFile
	set nameList to {}
	set urlList to {}
	set raw to ""
	try
		set raw to do shell script "cat " & quoted form of channelsFile
	end try
	if raw is not "" then
		set oldD to AppleScript's text item delimiters
		repeat with ln in paragraphs of raw
			set s to contents of ln
			if s contains "|" then
				set AppleScript's text item delimiters to "|"
				set parts to text items of s
				set AppleScript's text item delimiters to oldD
				set end of urlList to item 1 of parts
				set end of nameList to item 2 of parts
			end if
		end repeat
		set AppleScript's text item delimiters to oldD
	end if
	return {nameList, urlList}
end readChannels

on writeAllChannels(nameList, urlList)
	global channelsFile
	set txt to ""
	repeat with i from 1 to count of nameList
		set txt to txt & (item i of urlList) & "|" & (item i of nameList) & linefeed
	end repeat
	my writeFile(channelsFile, txt)
end writeAllChannels

on writeFile(posixPath, txt)
	set fh to open for access (POSIX file posixPath) with write permission
	try
		set eof fh to 0
		write txt to fh as «class utf8»
		close access fh
	on error e
		try
			close access fh
		end try
		error e
	end try
end writeFile

on readAutoURLs()
	global autoCheckFile
	set urls to {}
	set raw to ""
	try
		set raw to do shell script "cat " & quoted form of autoCheckFile
	end try
	if raw is not "" then
		repeat with ln in paragraphs of raw
			set theURL to contents of ln
			if theURL is not "" then set end of urls to theURL
		end repeat
	end if
	return urls
end readAutoURLs

on writeAutoURLs(urlList)
	global autoCheckFile
	set txt to ""
	repeat with theURL in urlList
		set txt to txt & (contents of theURL) & linefeed
	end repeat
	my writeFile(autoCheckFile, txt)
end writeAutoURLs

on isAutoEnabled(theURL)
	return (my indexOf(theURL, my readAutoURLs())) > 0
end isAutoEnabled

on channelId(theURL)
	return do shell script "printf %s " & quoted form of theURL & " | shasum -a 256 | cut -c1-16"
end channelId

-- ---------------------------------------------------------------- Recording
on startRecording(theURL, theName)
	global streamlinkPath, jobsDir
	set savePath to my getSavePath()
	set ts to do shell script "date +%Y-%m-%d_%H%M"
	set outFile to savePath & "/" & theName & "-SHOWROOM-" & ts & ".mp4"
	set quotedName to quoted form of theName
	set titleCmd to "printf '\\033]0;🔴 %s\\007' " & quotedName
	set startMessage to quoted form of ("🔴  Recording " & theName & " …  (close window or press Ctrl-C to stop)")
	set finishMessage to quoted form of ("⏹  Finished: " & theName)
	set markerDir to jobsDir & "/manual"
	set markerID to do shell script "uuidgen | tr -d '-'"
	set markerPath to markerDir & "/" & markerID & ".pid"
	do shell script "mkdir -p " & quoted form of markerDir
	tell application "Terminal"
		activate
		do script titleCmd & "; printf '%s\\n' " & startMessage & "; " & quoted form of streamlinkPath & " " & quoted form of theURL & " best -o " & quoted form of outFile & " --force --retry-streams 30 & streamPID=$!; printf '%s|%s' \"$streamPID\" \"$(/bin/ps -p \\\"$streamPID\\\" -o lstart=)\" > " & quoted form of markerPath & "; wait \"$streamPID\"; rm -f " & quoted form of markerPath & "; printf '\\n%s\\n' " & finishMessage & "; exit"
	end tell
end startRecording

on countRunning()
	set recs to my runningRecordings()
	return count of (item 2 of recs)
end countRunning

on runningRecordings()
	global autoStatusDir, jobsDir
	set pids to {}
	set labels to {}
	set owners to {}
	set statusFiles to {}
	try
		set raw to do shell script "find " & quoted form of autoStatusDir & " -type f -name 'auto-*.status' -print"
		if raw is not "" then set statusFiles to paragraphs of raw
	end try
	repeat with statusPath in statusFiles
		set statusRecord to my readAutoStatus(contents of statusPath)
		set statusPID to item 1 of statusRecord
		set statusURL to item 2 of statusRecord
		set statusOutput to item 3 of statusRecord
		if statusPID is not "" and statusURL is not "" and statusOutput is not "" and my statusPIDMatchesURL(statusPID, statusURL, statusOutput) then
			if my indexOf(statusPID, pids) is 0 then
				set end of pids to statusPID
				set end of owners to "auto|" & (contents of statusPath) & "|" & statusPID
				if statusOutput is not "" then
					set end of labels to my baseName(statusOutput) & "  [PID " & statusPID & "]"
				else
					set end of labels to "📡  " & statusURL & "  [PID " & statusPID & "]"
				end if
			end if
		end if
	end repeat

	set markerFiles to {}
	try
		set raw to do shell script "find " & quoted form of (jobsDir & "/manual") & " -type f -name '*.pid' -print"
		if raw is not "" then set markerFiles to paragraphs of raw
	end try
	repeat with markerPath in markerFiles
		set marker to contents of markerPath
		set manualPID to ""
		try
			set markerContents to do shell script "cat " & quoted form of marker
			set oldD to AppleScript's text item delimiters
			set AppleScript's text item delimiters to "|"
			set markerParts to text items of markerContents
			set AppleScript's text item delimiters to oldD
			set manualPID to item 1 of markerParts
			set manualStart to item 2 of markerParts
			set commandLine to do shell script "/bin/ps -p " & quoted form of manualPID & " -o command= 2>/dev/null"
			set commandStart to do shell script "/bin/ps -p " & quoted form of manualPID & " -o lstart= 2>/dev/null"
			if manualPID is not "" and manualStart is commandStart and commandLine contains "streamlink" and commandLine contains " best -o " and my indexOf(manualPID, pids) is 0 then
				set outputPath to ""
				try
					set outputPath to do shell script "printf '%s' " & quoted form of commandLine & " | sed -n 's/.*-o[[:space:]]\\(.*\\.mp4\\).*/\\1/p'"
				end try
					set end of pids to manualPID
					set end of owners to "manual|" & marker & "|" & manualPID & "|" & manualStart
				if outputPath is not "" then
					set end of labels to my baseName(outputPath) & "  [PID " & manualPID & "]"
				else
					set end of labels to "🔴  Manual recording  [PID " & manualPID & "]"
				end if
			else if commandLine is "" then
				do shell script "rm -f " & quoted form of marker
			end if
			end try
	end repeat
	return {pids, labels, owners}
end runningRecordings

on stopOwnedRecording(owner, expectedPID)
	set oldD to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "|"
	set ownerParts to text items of owner
	set AppleScript's text item delimiters to oldD
	if (count of ownerParts) < 3 then return false
	set ownerType to item 1 of ownerParts
	set ownerPath to item 2 of ownerParts
	set ownerPID to item 3 of ownerParts
	if ownerPID is not expectedPID then return false
	if ownerType is "auto" then
		set statusRecord to my readAutoStatus(ownerPath)
		if (item 1 of statusRecord) is not expectedPID then return false
		set ownerURL to item 2 of statusRecord
		if ownerURL is "" then return false
		return my disableAutoCheck(ownerURL, expectedPID)
	else if ownerType is "manual" then
		if (count of ownerParts) < 4 then return false
		set ownerStart to item 4 of ownerParts
		try
			set markerContents to do shell script "cat " & quoted form of ownerPath
			set oldD to AppleScript's text item delimiters
			set AppleScript's text item delimiters to "|"
			set markerParts to text items of markerContents
			set AppleScript's text item delimiters to oldD
			set markerPID to item 1 of markerParts
			set markerStart to item 2 of markerParts
			set currentStart to do shell script "/bin/ps -p " & quoted form of expectedPID & " -o lstart= 2>/dev/null"
			set commandLine to do shell script "/bin/ps -p " & quoted form of expectedPID & " -o command= 2>/dev/null"
			if markerPID is not expectedPID or markerStart is not ownerStart or currentStart is not ownerStart then return false
			if commandLine does not contain "streamlink" or commandLine does not contain " best -o " then return false
			if my stopPID(expectedPID) then
				do shell script "rm -f " & quoted form of ownerPath
				return true
			end if
		end try
	end if
	return false
end stopOwnedRecording

on stopRecording()
	set recs to my runningRecordings()
	set pids to item 1 of recs
	set labels to item 2 of recs
	set owners to item 3 of recs
	if (count of labels) is 0 then
		my info("Nothing recording", "There are no active recordings.", "note")
		return
	end if
	set opts to labels & {"⏹  STOP ALL"}
	activate
	set chosen to choose from list opts with title "Stop recording" with prompt "Select a recording to stop:" OK button name "Stop" cancel button name "Back"
	if chosen is false then return
	set sel to item 1 of chosen
	if sel is "⏹  STOP ALL" then
		set allStopped to true
		repeat with i from 1 to count of pids
			if (my stopOwnedRecording(item i of owners, item i of pids)) is false then set allStopped to false
		end repeat
		if allStopped then
			my info("Stopped", "All recordings have been stopped.", "note")
		else
			my info("Stop failed", "One or more Auto Check recordings could not be stopped.", "stop")
		end if
	else
		set idx to my indexOf(sel, labels)
		if idx > 0 then
			set thePID to item idx of pids
			set stopSucceeded to my stopOwnedRecording(item idx of owners, thePID)
			if stopSucceeded then
				my info("Stopped", "Stopped: " & sel, "note")
			else
				my info("Stop failed", "Couldn't stop: " & sel, "stop")
			end if
		end if
	end if
end stopRecording

on liveStatus()
	set recs to my runningRecordings()
	set labels to item 2 of recs
	if (count of labels) is 0 then
		my info("Live status", "Nothing is recording right now.", "note")
	else
		set oldD to AppleScript's text item delimiters
		set AppleScript's text item delimiters to (return & "   🔴 ")
		set body to "   🔴 " & (labels as text)
		set AppleScript's text item delimiters to oldD
		my info("Live status — " & (count of labels) & " recording", body, "note")
	end if
end liveStatus

-- ---------------------------------------------------------------- Channels
on addChannel()
	global channelsFile
	try
		set clip to ""
		try
			set clip to (the clipboard as text)
		end try
		if (length of clip > 200) or (clip does not contain "showroom-live.com") then
			set clip to "https://www.showroom-live.com/r/"
		end if
		activate
		set inputUrl to text returned of (display dialog "➕  Paste the SHOWROOM channel URL:" default answer clip buttons {"Cancel", "Next"} default button "Next" with title "Add channel" with icon note)
		activate
		set targetName to text returned of (display dialog "🎬  Display name for this channel:" default answer "" buttons {"Cancel", "Add"} default button "Add" with title "Add channel" with icon note)
		if inputUrl is not "" and targetName is not "" then
			do shell script "printf '%s\\n' " & quoted form of (inputUrl & "|" & targetName) & " >> " & quoted form of channelsFile
			my info("Added", "✅  " & targetName & " has been added.", "note")
		end if
	on error errMsg number errNum
		if errNum is not -128 then my info("Error", errMsg, "stop")
	end try
end addChannel

on deleteChannel(chNames, chURLs)
	if (count of chNames) is 0 then
		my info("No channels", "There's nothing to delete.", "caution")
		return
	end if
	activate
	set chosen to choose from list chNames with title "Delete channels" with prompt "Select channels to delete:" OK button name "Delete 🗑" cancel button name "Back" with multiple selections allowed
	if chosen is false then return
	set newNames to {}
	set newURLs to {}
	set removedURLs to {}
	repeat with i from 1 to count of chNames
		if my indexOf((item i of chNames) as text, chosen) is 0 then
			set end of newNames to item i of chNames
			set end of newURLs to item i of chURLs
		else if my isAutoEnabled(item i of chURLs) then
			set end of removedURLs to item i of chURLs
		end if
	end repeat
	repeat with theURL in removedURLs
		if my disableAutoCheck(contents of theURL, "") is false then
			my info("Delete stopped", "Couldn't safely disable Auto Check for " & contents of theURL & ".", "stop")
			return
		end if
	end repeat
	my writeAllChannels(newNames, newURLs)
	my reconcileAutoChecks(newNames, newURLs)
	my info("Deleted", "🗑  Removed " & ((count of chNames) - (count of newNames)) & " channel(s).", "note")
end deleteChannel

-- ---------------------------------------------------------------- Save location
on changeLocation()
	global savePathFile
	try
		activate
		set newFolder to choose folder with prompt "Choose where recordings are saved:"
		set newPath to POSIX path of newFolder
		if newPath ends with "/" and (length of newPath) > 1 then set newPath to text 1 thru -2 of newPath
		my writeFile(savePathFile, newPath)
		my info("Save location", "📁  Recordings will be saved to:" & return & newPath, "note")
	on error number -128
		-- cancelled
	end try
end changeLocation

-- ---------------------------------------------------------------- Auto Check (persistent launchd workers)
on enableAutoCheck(theURL, theName)
	global streamlinkPath, savePathFile, jobsDir, agentsDir, autoCheckFile, autoStatusDir, autoLogsDir
	set ident to my channelId(theURL)
	set label to "com.showroom.auto." & ident
	set workerPath to jobsDir & "/auto-" & ident & ".sh"
	set plistPath to agentsDir & "/" & label & ".plist"
	set statusPath to autoStatusDir & "/auto-" & ident & ".status"
	set logPath to autoLogsDir & "/auto-" & ident & ".log"
	set userID to do shell script "id -u"
	try
		set serviceState to my autoServiceState(label, userID)
	on error errMsg
		my info("Auto Check failed", "Couldn't inspect Auto Check for " & theName & "." & return & return & errMsg, "stop")
		return false
	end try
	set artifactsArePresent to (do shell script "test -f " & quoted form of workerPath & " && test -f " & quoted form of plistPath & " && echo yes || echo no") is "yes"
	set artifactsAreValid to false
	if artifactsArePresent then set artifactsAreValid to my plistIsValid(plistPath)
	if serviceState is "loaded" and artifactsAreValid and (my isAutoEnabled(theURL)) then return true

	if serviceState is "loaded" then
		try
			my bootoutAutoService(label, userID)
		on error errMsg
			my info("Auto Check failed", "Couldn't replace Auto Check for " & theName & "." & return & return & errMsg, "stop")
			return false
		end try
	end if

	try
		set worker to "#!/bin/bash" & linefeed
		set worker to worker & "set -u" & linefeed
		set worker to worker & "streamlink=" & quoted form of streamlinkPath & linefeed
		set worker to worker & "url=" & quoted form of theURL & linefeed
		set worker to worker & "name=" & quoted form of theName & linefeed
		set worker to worker & "save_path_file=" & quoted form of savePathFile & linefeed
		set worker to worker & "status_path=" & quoted form of statusPath & linefeed
		set worker to worker & "log=" & quoted form of logPath & linefeed
		set worker to worker & "stream_pid=\"\"" & linefeed & "cleaned_up=0" & linefeed
		set worker to worker & "encode_field() { printf %s \"$1\" | /usr/bin/base64 | /usr/bin/tr -d '\\n'; }" & linefeed
		set worker to worker & "write_status() {" & linefeed
		set worker to worker & "  local state=\"$1\" pid=\"$2\" output=\"$3\" encoded_url encoded_name encoded_output updated tmp" & linefeed
		set worker to worker & "  encoded_url=$(encode_field \"$url\")" & linefeed
		set worker to worker & "  encoded_name=$(encode_field \"$name\")" & linefeed
		set worker to worker & "  encoded_output=$(encode_field \"$output\")" & linefeed
		set worker to worker & "  updated=$(/bin/date +%s)" & linefeed
		set worker to worker & "  tmp=\"$status_path.tmp.$$\"" & linefeed
		set worker to worker & "  printf '%s|%s|%s|%s|%s|%s\\n' \"$state\" \"$pid\" \"$encoded_url\" \"$encoded_name\" \"$encoded_output\" \"$updated\" > \"$tmp\"" & linefeed
		set worker to worker & "  /bin/mv \"$tmp\" \"$status_path\"" & linefeed
		set worker to worker & "}" & linefeed
		set worker to worker & "trim_log() {" & linefeed
		set worker to worker & "  local size" & linefeed
		set worker to worker & "  size=$(/usr/bin/stat -f %z \"$log\" 2>/dev/null || printf 0)" & linefeed
		set worker to worker & "  if [ \"$size\" -gt 1048576 ]; then /usr/bin/tail -c 1048576 \"$log\" > \"$log.tmp\" && /bin/mv \"$log.tmp\" \"$log\"; fi" & linefeed
		set worker to worker & "}" & linefeed
		set worker to worker & "cleanup() {" & linefeed
		set worker to worker & "  if [ \"$cleaned_up\" -eq 1 ]; then return; fi" & linefeed
		set worker to worker & "  cleaned_up=1" & linefeed
		set worker to worker & "  if [ -n \"$stream_pid\" ] && /bin/kill -0 \"$stream_pid\" 2>/dev/null; then /bin/kill \"$stream_pid\" 2>/dev/null || true; fi" & linefeed
		set worker to worker & "  write_status stopped \"\" \"\"" & linefeed
		set worker to worker & "}" & linefeed
		set worker to worker & "on_signal() { cleanup; exit 0; }" & linefeed
		set worker to worker & "trap on_signal TERM INT" & linefeed & "trap cleanup EXIT" & linefeed
		set worker to worker & "while :; do" & linefeed
		set worker to worker & "  write_status waiting \"\" \"\"" & linefeed
		set worker to worker & "  trim_log" & linefeed
		set worker to worker & "  if \"$streamlink\" \"$url\" best --stream-url >/dev/null 2>>\"$log\"; then" & linefeed
		set worker to worker & "    save_path=$(/bin/cat \"$save_path_file\" 2>/dev/null || true)" & linefeed
		set worker to worker & "    if [ -z \"$save_path\" ]; then save_path=\"$HOME/Recordings\"; fi" & linefeed
		set worker to worker & "    /bin/mkdir -p \"$save_path\"" & linefeed
		set worker to worker & "    timestamp=$(/bin/date +%Y-%m-%d_%H%M)" & linefeed
		set worker to worker & "    output=\"$save_path/$name-SHOWROOM-$timestamp.mp4\"" & linefeed
		set worker to worker & "    while [ -e \"$output\" ]; do /bin/sleep 5; timestamp=$(/bin/date +%Y-%m-%d_%H%M); output=\"$save_path/$name-SHOWROOM-$timestamp.mp4\"; done" & linefeed
		set worker to worker & "    \"$streamlink\" \"$url\" best -o \"$output\" --force --retry-streams 30 >>\"$log\" 2>&1 &" & linefeed
		set worker to worker & "    stream_pid=$!" & linefeed
		set worker to worker & "    write_status recording \"$stream_pid\" \"$output\"" & linefeed
		set worker to worker & "    wait \"$stream_pid\" || true" & linefeed
		set worker to worker & "    stream_pid=\"\"" & linefeed
		set worker to worker & "    write_status waiting \"\" \"\"" & linefeed
		set worker to worker & "    trim_log" & linefeed
		set worker to worker & "  fi" & linefeed
		set worker to worker & "  /bin/sleep 60" & linefeed
		set worker to worker & "done" & linefeed
		my writeFile(workerPath, worker)
		do shell script "chmod +x " & quoted form of workerPath

		set p to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & linefeed
		set p to p & "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" & linefeed
		set p to p & "<plist version=\"1.0\">" & linefeed & "<dict>" & linefeed
		set p to p & "  <key>Label</key><string>" & label & "</string>" & linefeed
		set p to p & "  <key>ProgramArguments</key><array><string>/bin/bash</string><string>" & workerPath & "</string></array>" & linefeed
		set p to p & "  <key>RunAtLoad</key><true/>" & linefeed
		set p to p & "  <key>KeepAlive</key><true/>" & linefeed
		set p to p & "  <key>ThrottleInterval</key><integer>60</integer>" & linefeed
		set p to p & "</dict>" & linefeed & "</plist>" & linefeed
		my writeFile(plistPath, p)

		do shell script "/usr/bin/plutil -lint " & quoted form of plistPath
		do shell script "/bin/launchctl bootstrap " & quoted form of ("gui/" & userID) & " " & quoted form of plistPath
		do shell script "/bin/launchctl kickstart -k " & quoted form of (my autoServiceTarget(label, userID))
		set urls to my readAutoURLs()
		if (my indexOf(theURL, urls)) is 0 then set end of urls to theURL
		my writeAutoURLs(urls)
	on error errMsg
		set cleanupMsg to ""
		try
			my cleanupAutoCheck(label, userID, workerPath, plistPath, statusPath)
		on error cleanupErr
			set cleanupMsg to return & return & "Cleanup also failed: " & cleanupErr
		end try
		my info("Auto Check failed", "Couldn't enable Auto Check for " & theName & "." & return & return & errMsg & cleanupMsg, "stop")
		return false
	end try
	return true
end enableAutoCheck

on disableAutoCheck(theURL, expectedPID)
	global jobsDir, agentsDir, autoStatusDir
	set ident to my channelId(theURL)
	set label to "com.showroom.auto." & ident
	set workerPath to jobsDir & "/auto-" & ident & ".sh"
	set plistPath to agentsDir & "/" & label & ".plist"
	set statusPath to autoStatusDir & "/auto-" & ident & ".status"
	set userID to do shell script "id -u"
	set statusRecord to my readAutoStatus(statusPath)
	set statusPID to item 1 of statusRecord
	set statusURL to item 2 of statusRecord
	set statusOutput to item 3 of statusRecord
	if expectedPID is not "" and statusPID is not expectedPID then return false
	-- Unload first so the worker cannot create a new recording while its status is examined.
	try
		my bootoutAutoService(label, userID)
	on error errMsg
		my info("Auto Check failed", "Couldn't disable Auto Check for " & theURL & "." & return & return & errMsg, "stop")
		return false
	end try
	if statusPID is not "" and statusURL is theURL then
		if my statusPIDMatchesURL(statusPID, statusURL, statusOutput) then
			if my stopPID(statusPID) is false then return false
		end if
	end if
	try
		my removeAutoArtifacts(workerPath, plistPath, statusPath)
	on error errMsg
		my info("Auto Check failed", "Auto Check stopped, but its generated files couldn't be removed." & return & return & errMsg, "stop")
		return false
	end try

	set kept to {}
	repeat with storedURL in my readAutoURLs()
		if (contents of storedURL) is not theURL then set end of kept to contents of storedURL
	end repeat
	try
		my writeAutoURLs(kept)
	on error errMsg
		my info("Auto Check failed", "Auto Check stopped, but its enabled-channel setting couldn't be updated." & return & return & errMsg, "stop")
		return false
	end try
	return true
end disableAutoCheck

on autoServiceState(label, userID)
	try
		do shell script "/bin/launchctl print " & quoted form of (my autoServiceTarget(label, userID)) & " 2>&1"
		return "loaded"
	on error errMsg
		if errMsg contains "Could not find service" or errMsg contains "No such process" then return "absent"
		error errMsg
	end try
end autoServiceState

on autoServiceTarget(label, userID)
	return "gui/" & userID & "/" & label
end autoServiceTarget

on bootoutAutoService(label, userID)
	if (my autoServiceState(label, userID)) is "absent" then return true
	do shell script "/bin/launchctl bootout " & quoted form of (my autoServiceTarget(label, userID))
	return true
end bootoutAutoService

on plistIsValid(plistPath)
	try
		do shell script "/usr/bin/plutil -lint " & quoted form of plistPath
		return true
	on error
		return false
	end try
end plistIsValid

on removeAutoArtifacts(workerPath, plistPath, statusPath)
	do shell script "/bin/rm -f " & quoted form of workerPath & " " & quoted form of plistPath & " " & quoted form of statusPath
end removeAutoArtifacts

on cleanupAutoCheck(label, userID, workerPath, plistPath, statusPath)
	my bootoutAutoService(label, userID)
	my removeAutoArtifacts(workerPath, plistPath, statusPath)
end cleanupAutoCheck

on readAutoStatus(statusPath)
	set statusPID to ""
	set statusURL to ""
	set statusOutput to ""
	set raw to ""
	try
		set raw to do shell script "cat " & quoted form of statusPath
	end try
	if raw is not "" then
		set oldD to AppleScript's text item delimiters
		set AppleScript's text item delimiters to "|"
		set parts to text items of raw
		set AppleScript's text item delimiters to oldD
		if (count of parts) ≥ 6 then
			set statusPID to item 2 of parts
			try
				set statusURL to my decodeStatusField(item 3 of parts)
				set statusOutput to my decodeStatusField(item 5 of parts)
			end try
		end if
	end if
	return {statusPID, statusURL, statusOutput}
end readAutoStatus

on decodeStatusField(encodedValue)
	return do shell script "printf %s " & quoted form of encodedValue & " | /usr/bin/base64 -D"
end decodeStatusField

on statusPIDMatchesURL(thePID, theURL, expectedOutput)
	try
		set urlPattern to quoted form of (" " & theURL & " best -o ")
		set quotedURLPattern to quoted form of ("\"" & theURL & "\" best -o ")
		set outputPattern to quoted form of (" -o " & expectedOutput & " --force")
		set quotedOutputPattern to quoted form of (" -o \"" & expectedOutput & "\" --force")
		do shell script "case " & quoted form of thePID & " in (''|*[!0-9]*) exit 1 ;; esac; commandLine=$(/bin/ps -p " & quoted form of thePID & " -o command=); printf '%s' \"$commandLine\" | /usr/bin/grep -F -e " & urlPattern & " -e " & quotedURLPattern & " >/dev/null; printf '%s' \"$commandLine\" | /usr/bin/grep -F -e " & outputPattern & " -e " & quotedOutputPattern & " >/dev/null; printf '%s' \"$commandLine\" | /usr/bin/grep -F -- streamlink >/dev/null"
		return true
	on error
		return false
	end try
end statusPIDMatchesURL

on stopPID(thePID)
	try
		do shell script "case " & quoted form of thePID & " in (''|*[!0-9]*) exit 1 ;; esac; /bin/kill " & quoted form of thePID & " 2>/dev/null"
		return true
	on error
		return false
	end try
end stopPID

on autoURLForPID(thePID)
	global autoStatusDir
	set statusFiles to {}
	try
		set raw to do shell script "find " & quoted form of autoStatusDir & " -type f -name 'auto-*.status' -print"
		if raw is not "" then set statusFiles to paragraphs of raw
	end try
	repeat with statusPath in statusFiles
		set statusRecord to my readAutoStatus(contents of statusPath)
		set statusPID to item 1 of statusRecord
		set statusURL to item 2 of statusRecord
		set statusOutput to item 3 of statusRecord
		if statusPID is thePID and statusURL is not "" and statusOutput is not "" and my statusPIDMatchesURL(thePID, statusURL, statusOutput) then return statusURL
	end repeat
	return ""
end autoURLForPID

on reconcileAutoChecks(chNames, chURLs)
	set expectedIDs to {}
	repeat with theURL in my readAutoURLs()
		set urlText to contents of theURL
		set idx to my indexOf(urlText, chURLs)
		if idx is 0 then
			my disableAutoCheck(urlText, "")
		else
			set ident to my channelId(urlText)
			if (my indexOf(ident, expectedIDs)) is 0 then set end of expectedIDs to ident
			my enableAutoCheck(urlText, item idx of chNames)
		end if
	end repeat
	set artifactIDs to my managedAutoArtifactIDs()
	repeat with artifactID in artifactIDs
		if (my indexOf(contents of artifactID, expectedIDs)) is 0 then my removeOrphanAutoCheck(contents of artifactID)
	end repeat
end reconcileAutoChecks

on managedAutoArtifactIDs()
	global jobsDir, agentsDir, autoStatusDir
	set ids to {}
	set raw to ""
	try
		set raw to do shell script "/usr/bin/find " & quoted form of jobsDir & " " & quoted form of agentsDir & " " & quoted form of autoStatusDir & " -type f \\( -name 'auto-*.sh' -o -name 'auto-*.status' -o -name 'com.showroom.auto.*.plist' \\) -print"
	end try
	if raw is not "" then
		repeat with artifactPath in paragraphs of raw
			set ident to my autoArtifactID(contents of artifactPath)
			if ident is not "" then
				if my isValidAutoArtifactID(ident) then
					if (my indexOf(ident, ids)) is 0 then set end of ids to ident
				else
					my removeInvalidAutoArtifact(contents of artifactPath)
				end if
			end if
		end repeat
	end if
	return ids
end managedAutoArtifactIDs

on autoArtifactID(artifactPath)
	set fileName to do shell script "/usr/bin/basename " & quoted form of artifactPath
	if fileName starts with "auto-" and fileName ends with ".sh" then
		set endIndex to (length of fileName) - (length of ".sh")
		if endIndex ≥ 6 then return text 6 thru endIndex of fileName
	else if fileName starts with "auto-" and fileName ends with ".status" then
		set endIndex to (length of fileName) - (length of ".status")
		if endIndex ≥ 6 then return text 6 thru endIndex of fileName
	else if fileName starts with "com.showroom.auto." and fileName ends with ".plist" then
		set startIndex to (length of "com.showroom.auto.") + 1
		set endIndex to (length of fileName) - (length of ".plist")
		if endIndex ≥ startIndex then return text startIndex thru endIndex of fileName
	end if
	return ""
end autoArtifactID

on isValidAutoArtifactID(ident)
	try
		do shell script "printf %s " & quoted form of ident & " | /usr/bin/grep -Eq '^[0-9a-f]{16}$'"
		return true
	on error
		return false
	end try
end isValidAutoArtifactID

on removeInvalidAutoArtifact(artifactPath)
	try
		do shell script "/bin/rm -f " & quoted form of artifactPath
	end try
end removeInvalidAutoArtifact

on removeOrphanAutoCheck(ident)
	global jobsDir, agentsDir, autoStatusDir
	if not (my isValidAutoArtifactID(ident)) then return false
	set label to "com.showroom.auto." & ident
	set workerPath to jobsDir & "/auto-" & ident & ".sh"
	set plistPath to agentsDir & "/" & label & ".plist"
	set statusPath to autoStatusDir & "/auto-" & ident & ".status"
	set userID to do shell script "id -u"
	try
		my bootoutAutoService(label, userID)
		on error errMsg
		my info("Auto Check cleanup failed", "Couldn't remove an orphaned Auto Check job." & return & return & errMsg, "stop")
		return false
	end try
	try
		my removeAutoArtifacts(workerPath, plistPath, statusPath)
	on error errMsg
		my info("Auto Check cleanup failed", "An orphaned Auto Check job stopped, but its files couldn't be removed." & return & return & errMsg, "stop")
		return false
	end try
	return true
end removeOrphanAutoCheck

on autoCheckFlow(chNames, chURLs)
	if (count of chNames) is 0 then
		my info("No channels", "Add a channel first.", "caution")
		return
	end if
	set displays to {}
	repeat with i from 1 to count of chNames
		set theURL to item i of chURLs
		set displayLabel to (item i of chNames) & "   —   " & theURL
		if my isAutoEnabled(theURL) then set displayLabel to "📡 " & displayLabel
		set end of displays to displayLabel
	end repeat
	activate
	set chosen to choose from list displays with title "Auto Check" with prompt "Choose one channel to enable or disable Auto Check:" OK button name "Select" cancel button name "Back"
	if chosen is false then return
	set idx to my indexOf(item 1 of chosen, displays)
	if idx is 0 then return
	set theURL to item idx of chURLs
	set theName to item idx of chNames
	if my isAutoEnabled(theURL) then
		if my disableAutoCheck(theURL, "") then my info("Auto Check disabled", "📡  Disabled Auto Check for " & theName & ".", "note")
	else if my enableAutoCheck(theURL, theName) then
		my info("Auto Check enabled", "📡  Auto Check will keep watching " & theName & ".", "note")
	end if
end autoCheckFlow

-- ---------------------------------------------------------------- Scheduling (launchd)
on scheduleFlow(chNames, chURLs)
	if (count of chNames) is 0 then
		my info("No channels", "Add a channel first.", "caution")
		return
	end if
	activate
	set chosen to choose from list chNames with title "Schedule recording" with prompt "Choose channel(s) to schedule:" OK button name "Next" cancel button name "Back" with multiple selections allowed
	if chosen is false then return

	set defaultDT to do shell script "date -v+1H +'%Y-%m-%d %H:%M'"
	try
		activate
		set dtStr to text returned of (display dialog "⏰  Start recording at:" & return & "(format:  YYYY-MM-DD HH:MM)" default answer defaultDT buttons {"Cancel", "Schedule"} default button "Schedule" with title "Schedule recording" with icon note)
	on error number -128
		return
	end try

	set parsed to ""
	try
		set parsed to do shell script "date -j -f '%Y-%m-%d %H:%M' " & quoted form of dtStr & " +'%M|%H|%d|%m|%s'"
	on error
		my info("Invalid time", "Couldn't read that date/time." & return & "Use the format:  YYYY-MM-DD HH:MM", "stop")
		return
	end try

	set nowEpoch to (do shell script "date +%s") as integer
	set oldD to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "|"
	set pParts to text items of parsed
	set AppleScript's text item delimiters to oldD
	set theMin to item 1 of pParts
	set theHour to item 2 of pParts
	set theDay to item 3 of pParts
	set theMonth to item 4 of pParts
	set targetEpoch to (item 5 of pParts) as integer
	if targetEpoch ≤ nowEpoch then
		my info("Invalid time", "That time is in the past.", "stop")
		return
	end if

	repeat with nm in chosen
		set idx to my indexOf(nm as text, chNames)
		if idx > 0 then my createScheduledJob(item idx of chURLs, item idx of chNames, theMin, theHour, theDay, theMonth, dtStr)
	end repeat
	my info("Scheduled", "⏰  Recording scheduled for:" & return & dtStr, "note")
end scheduleFlow

on createScheduledJob(theURL, theName, theMin, theHour, theDay, theMonth, dtStr)
	global streamlinkPath, jobsDir, agentsDir, schedulesFile
	set savePath to my getSavePath()
	set label to "com.showroom.rec." & (do shell script "date +%s") & (random number from 1000 to 9999)
	set plistPath to agentsDir & "/" & label & ".plist"
	set wrapperPath to jobsDir & "/" & label & ".sh"
	set fnTs to do shell script "date -j -f '%Y-%m-%d %H:%M' " & quoted form of dtStr & " +'%Y-%m-%d_%H%M'"
	set outFile to savePath & "/" & theName & "-SHOWROOM-" & fnTs & ".mp4"

	-- Wrapper: records once, then unloads + deletes itself.
	set wrapper to "#!/bin/bash" & linefeed
	set wrapper to wrapper & quoted form of streamlinkPath & " " & quoted form of theURL & " best -o " & quoted form of outFile & " --force --retry-streams 30" & linefeed
	set wrapper to wrapper & "/bin/launchctl unload " & quoted form of plistPath & " 2>/dev/null" & linefeed
	set wrapper to wrapper & "/bin/rm -f " & quoted form of plistPath & " " & quoted form of wrapperPath & linefeed
	my writeFile(wrapperPath, wrapper)
	do shell script "chmod +x " & quoted form of wrapperPath

	-- launchd agent (fires once at the target minute; wrapper cleans up).
	set p to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & linefeed
	set p to p & "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" & linefeed
	set p to p & "<plist version=\"1.0\">" & linefeed & "<dict>" & linefeed
	set p to p & "  <key>Label</key><string>" & label & "</string>" & linefeed
	set p to p & "  <key>ProgramArguments</key>" & linefeed & "  <array>" & linefeed
	set p to p & "    <string>/bin/bash</string>" & linefeed
	set p to p & "    <string>" & wrapperPath & "</string>" & linefeed
	set p to p & "  </array>" & linefeed
	set p to p & "  <key>StartCalendarInterval</key>" & linefeed & "  <dict>" & linefeed
	set p to p & "    <key>Minute</key><integer>" & (theMin as integer) & "</integer>" & linefeed
	set p to p & "    <key>Hour</key><integer>" & (theHour as integer) & "</integer>" & linefeed
	set p to p & "    <key>Day</key><integer>" & (theDay as integer) & "</integer>" & linefeed
	set p to p & "    <key>Month</key><integer>" & (theMonth as integer) & "</integer>" & linefeed
	set p to p & "  </dict>" & linefeed
	set p to p & "  <key>RunAtLoad</key><false/>" & linefeed
	set p to p & "</dict>" & linefeed & "</plist>" & linefeed
	my writeFile(plistPath, p)
	try
		do shell script "/bin/launchctl unload " & quoted form of plistPath & " 2>/dev/null; /bin/launchctl load " & quoted form of plistPath
	on error errMsg
		-- Registration failed: clean up so nothing dangles, then report.
		do shell script "/bin/rm -f " & quoted form of plistPath & " " & quoted form of wrapperPath
		my info("Schedule failed", "Couldn't register the scheduled recording for " & theName & "." & return & return & errMsg, "stop")
		return
	end try

	do shell script "printf '%s\\n' " & quoted form of (label & "|" & theName & "|" & dtStr) & " >> " & quoted form of schedulesFile
end createScheduledJob

on viewScheduled()
	global schedulesFile, agentsDir, jobsDir
	set raw to ""
	try
		set raw to do shell script "cat " & quoted form of schedulesFile
	end try
	set labels to {}
	set displays to {}
	if raw is not "" then
		set oldD to AppleScript's text item delimiters
		repeat with ln in paragraphs of raw
			set s to contents of ln
			if s contains "|" then
				set AppleScript's text item delimiters to "|"
				set parts to text items of s
				set AppleScript's text item delimiters to oldD
				set lab to item 1 of parts
				set nm to item 2 of parts
				set dt to item 3 of parts
				if (do shell script "test -f " & quoted form of (agentsDir & "/" & lab & ".plist") & " && echo yes || echo no") is "yes" then
					set end of labels to lab
					set end of displays to "⏰ " & dt & "   —   " & nm
				end if
			end if
		end repeat
		set AppleScript's text item delimiters to oldD
	end if
	if (count of displays) is 0 then
		my info("Scheduled recordings", "No upcoming scheduled recordings.", "note")
		return
	end if
	activate
	set chosen to choose from list displays with title "Scheduled recordings" with prompt "Select a schedule to CANCEL, or press Done:" OK button name "Cancel schedule 🗑" cancel button name "Done" with multiple selections allowed
	if chosen is false then return
	repeat with d in chosen
		set idx to my indexOf(d as text, displays)
		if idx > 0 then
			set lab to item idx of labels
			do shell script "/bin/launchctl unload " & quoted form of (agentsDir & "/" & lab & ".plist") & " 2>/dev/null; /bin/rm -f " & quoted form of (agentsDir & "/" & lab & ".plist") & " " & quoted form of (jobsDir & "/" & lab & ".sh")
		end if
	end repeat
	my pruneSchedules()
	my info("Cancelled", "🗑  Cancelled " & (count of chosen) & " scheduled recording(s).", "note")
end viewScheduled

on pruneSchedules()
	global schedulesFile, agentsDir
	set raw to ""
	try
		set raw to do shell script "cat " & quoted form of schedulesFile
	end try
	set kept to ""
	if raw is not "" then
		set oldD to AppleScript's text item delimiters
		repeat with ln in paragraphs of raw
			set s to contents of ln
			if s contains "|" then
				set AppleScript's text item delimiters to "|"
				set parts to text items of s
				set AppleScript's text item delimiters to oldD
				set lab to item 1 of parts
				if (do shell script "test -f " & quoted form of (agentsDir & "/" & lab & ".plist") & " && echo yes || echo no") is "yes" then set kept to kept & s & linefeed
			end if
		end repeat
		set AppleScript's text item delimiters to oldD
	end if
	my writeFile(schedulesFile, kept)
end pruneSchedules

-- ---------------------------------------------------------------- Helpers
on indexOf(theItem, theList)
	repeat with i from 1 to count of theList
		if (item i of theList) as text is theItem then return i
	end repeat
	return 0
end indexOf

on baseName(p)
	set oldD to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "/"
	set b to last text item of p
	set AppleScript's text item delimiters to oldD
	return b
end baseName

on info(theTitle, theBody, iconType)
	set ic to note
	if iconType is "caution" then set ic to caution
	if iconType is "stop" then set ic to stop
	activate
	display dialog theBody buttons {"OK"} default button "OK" with title theTitle with icon ic
end info
