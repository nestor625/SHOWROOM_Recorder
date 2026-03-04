-- SHOWROOM Recorder Pro (v2.6 - Smart Input Fix)

set streamlinkPath to ""
try
    set streamlinkPath to do shell script "which streamlink || echo '/opt/homebrew/bin/streamlink'"
    do shell script "test -f " & streamlinkPath
on error
    display dialog "❌ Streamlink Not Found" buttons {"Quit"} with icon stop
    return
end try

do shell script "mkdir -p ~/Recordings && mkdir -p ~/.showroom_data && touch ~/.showroom_data/channels.txt"

repeat
    activate
    set mainScreen to display dialog "📺 SHOWROOM RECORDER" & return & "——————————————————" buttons {"Settings ⚙️", "Add Channel ➕", "RECORD 🔴"} default button "RECORD 🔴" with title "Showroom Control" with icon posix file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AirDrop.icns"
    
    set action to button returned of mainScreen
    
    if action is "RECORD 🔴" then
        set channelData to do shell script "cat ~/.showroom_data/channels.txt"
        if length of (channelData) is 0 then
            display dialog "⚠️ List is empty!" buttons {"Back"} with icon caution
        else
            set chList to {}
            set urlList to {}
            set AppleScript's text item delimiters to "|"
            repeat with ln in paragraphs of channelData
                if ln contains "|" then
                    set parts to text items of ln
                    set end of urlList to item 1 of parts
                    set end of chList to item 2 of parts
                end if
            end repeat
            set AppleScript's text item delimiters to ""
            
            set chosen to choose from list chList with title "Select" OK button name "Start" cancel button name "Back"
            if chosen is not false then
                set selectedName to item 1 of chosen
                set itemIdx to 1
                repeat with i from 1 to count of chList
                    if item i of chList is selectedName then
                        set itemIdx to i
                        exit repeat
                    end if
                end repeat
                set finalUrl to item itemIdx of urlList
                set ts to do shell script "date +%Y-%m-%d_%H%M"
                set outFile to (do shell script "echo $HOME") & "/Recordings/" & selectedName & "_" & ts & ".mp4"
                tell application "Terminal"
                    activate
                    do script "printf '\\033]2;" & selectedName & "\\007'; " & streamlinkPath & " " & quoted form of finalUrl & " best -o " & quoted form of outFile & " --force --retry-streams 30; exit"
                end tell
            end if
        end if
        
    else if action is "Add Channel ➕" then
        try
            set clipContent to ""
            try
                set clipContent to (the clipboard as text)
            end try
            
            -- 過濾邏輯：如果剪貼簿內容太長或不含 showroom，則重設為預設值
            if (length of clipContent > 200) or (clipContent does not contain "showroom-live.com") then
                set clipContent to "https://www.showroom-live.com/r/"
            end if
            
            activate
            set inputUrl to text returned of (display dialog "Paste URL:" default answer clipContent with icon posix file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns")
            
            activate
            set targetName to text returned of (display dialog "Display Name:" default answer "My Idol" with icon posix file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserIcon.icns")
            
            if inputUrl is not "" and targetName is not "" then
                do shell script "echo " & quoted form of (inputUrl & "|" & targetName) & " >> ~/.showroom_data/channels.txt"
            end if
        on error
        end try
        
    else if action is "Settings ⚙️" then
        activate
        set setAction to display dialog "Management" buttons {"Quit App ❌", "Open Folder 📂", "Edit List 📝"} default button "Open Folder 📂" with icon posix file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarCustomizeIcon.icns"
        
        if button returned of setAction is "Quit App ❌" then
            return
        else if button returned of setAction is "Open Folder 📂" then
            do shell script "open ~/Recordings"
        else if button returned of setAction is "Edit List 📝" then
            do shell script "open -e ~/.showroom_data/channels.txt"
        end if
    end if
end repeat
