#!/bin/bash

# SHOWROOM Recorder for macOS

RECORDINGS_DIR="$HOME/Recordings"
mkdir -p "$RECORDINGS_DIR"

echo "========================================="
echo "   SHOWROOM Recorder for macOS"
echo "========================================="

if ! command -v streamlink &> /dev/null; then
    echo "Streamlink not found!"
    echo "Please install: brew install streamlink"
    exit 1
fi

min_streamlink=8.6.2
streamlink_version=$(streamlink --version 2>/dev/null | awk 'NR==1 { print $2; exit }')
if ! { printf '%s' "$streamlink_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' && awk -v v="$streamlink_version" -v m="$min_streamlink" 'BEGIN { n = split(v, a, "."); split(m, b, "."); for (i = 1; i <= 3; i++) { av = (i <= n ? a[i] + 0 : 0); bv = b[i] + 0; if (av < bv) exit 1; if (av > bv) exit 0 } exit 0 }'; }; then
    echo "Streamlink 8.6.2 or newer is required (installed: ${streamlink_version:-unknown})."
    echo "Streamlink 8.6.1 and older can be tricked into reading local files (GHSA-j7pf-m7gx-jr33)."
    echo "Upgrade with: brew upgrade streamlink"
    exit 1
fi

record_channel() {
    local url=$1
    local name=$2
    local timestamp=$(date +"%Y-%m-%d_%H_%M")
    local output="$RECORDINGS_DIR/${name}-SHOWROOM-${timestamp}.mp4"
    
    echo "Recording: $name"
    streamlink "$url" best -o "$output" --force
}

echo "1. Record new URL"
echo "2. List saved channels"
echo "3. Record from saved"
read -p "Select: " option

case $option in
    1)
        echo "Enter URL:"
        read -r url
        echo "Enter name:"
        read -r name
        record_channel "$url" "$name"
        ;;
    2)
        if [ -f "$HOME/.showroom_channels.txt" ]; then
            cat "$HOME/.showroom_channels.txt"
        else
            echo "No saved channels"
        fi
        ;;
    3)
        echo "Enter channel name:"
        read -r name
        url=$(grep "|$name|" "$HOME/.showroom_channels.txt" | cut -d'|' -f1)
        if [ -n "$url" ]; then
            record_channel "$url" "$name"
        else
            echo "Channel not found"
        fi
        ;;
esac
