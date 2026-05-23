#!/bin/bash
# Genindlæs ændret side i Safari med tom cache

PROJECT_ROOT="/Users/steensonderup/Documents/udvikling/minhave"
PORT=8766

# Læs tool-info fra stdin
TOOL_INFO=$(cat)

# Kun for Edit og Write
TOOL_NAME=$(echo "$TOOL_INFO" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''))
except:
    print('')
" 2>/dev/null)

if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
    exit 0
fi

# Hent filsti
FILE_PATH=$(echo "$TOOL_INFO" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Kun for projektfiler
if [[ "$FILE_PATH" != "$PROJECT_ROOT"* ]]; then
    exit 0
fi

# Map filsti til URL
REL_PATH="${FILE_PATH#$PROJECT_ROOT}"
if [[ "$REL_PATH" == */index.html ]]; then
    URL_PATH="${REL_PATH%index.html}"
elif [[ "$REL_PATH" == *.html ]]; then
    URL_PATH="$REL_PATH"
else
    # CSS, JS o.l.: genindlæs forældremappe
    URL_PATH="$(dirname "$REL_PATH")/"
fi
TARGET_URL="http://localhost:${PORT}${URL_PATH}"

# Aktivér Safari, tøm caches og genindlæs
osascript << APPLESCRIPT
-- Aktivér Safari
tell application "Safari"
    activate
    -- Find localhost-fane og naviger til ændret side
    set found to false
    repeat with w in every window
        repeat with t in every tab of w
            try
                if URL of t contains "localhost:$PORT" then
                    set URL of t to "$TARGET_URL"
                    set current tab of w to t
                    set found to true
                    exit repeat
                end if
            end try
        end repeat
        if found then exit repeat
    end repeat
end tell

delay 0.3

-- Tøm buffere (Cmd+Option+E)
tell application "System Events"
    tell process "Safari"
        keystroke "e" using {command down, option down}
    end tell
end tell

delay 0.2

-- Hård genindlæsning fra oprindelse (Cmd+Option+R)
tell application "System Events"
    tell process "Safari"
        keystroke "r" using {command down, option down}
    end tell
end tell

delay 0.5

-- Giv fokus tilbage til Terminal
tell application "Terminal"
    activate
end tell
APPLESCRIPT

exit 0
