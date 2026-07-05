-- SHOWROOM Recorder Pro (v3.0 — macOS)
-- Records SHOWROOM live streams via streamlink.
-- Feature parity with the Windows edition: record / record-all / stop /
-- live status / add / delete / schedule (launchd) / view schedule /
-- change save location — all from one consolidated, polished menu.

global streamlinkPath, homePath, dataDir, channelsFile, savePathFile, jobsDir, agentsDir, schedulesFile

-- ---------------------------------------------------------------- Setup
set homePath to do shell script "echo $HOME"
set dataDir to homePath & "/.showroom_data"
set channelsFile to dataDir & "/channels.txt"
set savePathFile to dataDir & "/save_path.txt"
set jobsDir to dataDir & "/jobs"
set schedulesFile to dataDir & "/schedules.txt"
set agentsDir to homePath & "/Library/LaunchAgents"

set streamlinkPath to ""
try
	set streamlinkPath to do shell script "command -v streamlink || echo /opt/homebrew/bin/streamlink"
	do shell script "test -x " & quoted form of streamlinkPath
on error
	display dialog "❌  Streamlink not found." & return & return & "Install it first with:" & return & "    brew install streamlink" buttons {"Quit"} default button "Quit" with icon stop with title "SHOWROOM Recorder"
	return
end try

do shell script "mkdir -p " & quoted form of (homePath & "/Recordings") & " " & quoted form of dataDir & " " & quoted form of jobsDir & " " & quoted form of agentsDir & "; touch " & quoted form of channelsFile & " " & quoted form of schedulesFile

-- ---------------------------------------------------------------- Menu loop
repeat
	set savePath to my getSavePath()
	set chData to my readChannels()
	set chNames to item 1 of chData
	set chURLs to item 2 of chData
	set recCount to my countRunning()

	set mRecord to "🔴  Record…"
	set mRecordAll to "🔴  Record ALL"
	set mStop to "⏹  Stop recording…"
	set mStatus to "📡  Live status"
	set mAdd to "➕  Add channel"
	set mDelete to "🗑  Delete channel…"
	set mSchedule to "⏰  Schedule recording…"
	set mScheduled to "📅  View scheduled…"
	set mOpen to "📂  Open recordings folder"
	set mLocation to "📁  Change save location…"
	set mEdit to "📝  Edit channel list (raw)"
	set mQuit to "❌  Quit"

	set menuItems to {mRecord, mRecordAll, mStop, mStatus, mAdd, mDelete, mSchedule, mScheduled, mOpen, mLocation, mEdit, mQuit}
	set headline to "📂 Save to:  " & savePath & return & "🎬 Channels: " & (count of chNames) & "     🔴 Recording: " & recCount

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
				repeat with nm in chosen
					set idx to my indexOf(nm as text, chNames)
					if idx > 0 then my startRecording(item idx of chURLs, item idx of chNames)
				end repeat
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
				repeat with i from 1 to count of chNames
					my startRecording(item i of chURLs, item i of chNames)
				end repeat
			end if
		end if

	else if action is mStop then
		my stopRecording()

	else if action is mStatus then
		my liveStatus()

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

-- ---------------------------------------------------------------- Recording
on startRecording(theURL, theName)
	global streamlinkPath
	set savePath to my getSavePath()
	set ts to do shell script "date +%Y-%m-%d_%H%M"
	set outFile to savePath & "/" & theName & "-SHOWROOM-" & ts & ".mp4"
	set titleCmd to "printf '\\033]0;🔴 " & theName & "\\007'"
	tell application "Terminal"
		activate
		do script titleCmd & "; echo '🔴  Recording " & theName & " …  (close window or press Ctrl-C to stop)'; " & quoted form of streamlinkPath & " " & quoted form of theURL & " best -o " & quoted form of outFile & " --force --retry-streams 30; echo; echo '⏹  Finished: " & theName & "'; exit"
	end tell
end startRecording

on countRunning()
	set n to 0
	try
		set n to (do shell script "ps -Axo command= | grep -c '[s]treamlink' || true") as integer
	end try
	return n
end countRunning

on runningRecordings()
	set pids to {}
	set labels to {}
	set raw to ""
	try
		set raw to do shell script "ps -Axo pid=,command= | grep '[s]treamlink' | sed -n 's/^[[:space:]]*\\([0-9][0-9]*\\)[[:space:]].*-o[[:space:]]\\(.*\\.mp4\\).*/\\1|\\2/p'"
	end try
	if raw is not "" then
		set oldD to AppleScript's text item delimiters
		repeat with ln in paragraphs of raw
			set s to contents of ln
			if s contains "|" then
				set AppleScript's text item delimiters to "|"
				set parts to text items of s
				set AppleScript's text item delimiters to oldD
				set end of pids to item 1 of parts
				set end of labels to my baseName(item 2 of parts)
			end if
		end repeat
		set AppleScript's text item delimiters to oldD
	end if
	return {pids, labels}
end runningRecordings

on stopRecording()
	set recs to my runningRecordings()
	set pids to item 1 of recs
	set labels to item 2 of recs
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
		do shell script "pkill -f streamlink || true"
		my info("Stopped", "All recordings have been stopped.", "note")
	else
		set idx to my indexOf(sel, labels)
		if idx > 0 then
			do shell script "kill " & (item idx of pids) & " || true"
			my info("Stopped", "Stopped: " & sel, "note")
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
	repeat with i from 1 to count of chNames
		if my indexOf((item i of chNames) as text, chosen) is 0 then
			set end of newNames to item i of chNames
			set end of newURLs to item i of chURLs
		end if
	end repeat
	my writeAllChannels(newNames, newURLs)
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
