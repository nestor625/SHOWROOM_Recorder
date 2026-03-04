-- SHOWROOM Recorder for macOS

try
    do shell script "which streamlink"
on error
    display dialog "Please run: brew install streamlink" buttons {"OK"} with icon caution
    return
end try

do shell script "mkdir -p ~/Recordings"

set choice to choose from list {"Add Channel", "Record", "Open Recordings"} with prompt "SHOWROOM Recorder"

if choice is false then return
set selected to item 1 of choice

if selected is "Add Channel" then
    set url to text returned of (display dialog "Enter SHOWROOM URL:" default answer "https://www.showroom-live.com/r/")
    set name to text returned of (display dialog "Enter name:" default answer "My Idol")
    do shell script "mkdir -p ~/.showroom_data"
    do shell script "echo " & quoted form of (url & "|" & name) & " >> ~/.showroom_data/channels.txt"
    display dialog "Added: " & name buttons {"OK"}
    
else if selected is "Record" then
    try
        set channels to do shell script "cat ~/.showroom_data/channels.txt"
    on error
        display dialog "No channels! Add one first." buttons {"OK"}
        return
    end try
    
    set chList to {}
    set urlList to {}
    
    repeat with ln in paragraphs of channels
        if ln contains "|" then
            set AppleScript's text item delimiters to "|"
            set parts to text items of ln
            set end of chList to item 2 of parts
            set end of urlList to item 1 of parts
            set AppleScript's text item delimiters to ""
        end if
    end repeat
    
    if (count of chList) = 0 then
        display dialog "No channels!" buttons {"OK"}
        return
    end if
    
    set chosen to choose from list chList with prompt "Select channel:"
    if chosen is false then return
    
    set i to 0
    repeat with x in chList
        set i to i + 1
        if x is (item 1 of chosen) then exit repeat
    end repeat
    
    set theUrl to item i of urlList
    set ts to do shell script "date +%Y-%m-%d_%H_%M"
    set outFile to (do shell script "echo $HOME") & "/Recordings/" & (item 1 of chosen) & "-SHOWROOM-" & ts & ".mp4"
    
    display dialog "Recording: " & (item 1 of chosen) buttons {"OK"} giving up after 2
    
    tell application "Terminal"
        do script "streamlink " & quoted form of theUrl & " best -o " & quoted form of outFile & " --force"
    end tell
    
else if selected is "Open Recordings" then
    tell application "Finder"
        open (do shell script "echo $HOME") & "/Recordings"
    end tell
end if
