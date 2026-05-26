#!/bin/bash
# Oprydning: luk Safari-vindue, stop server, luk Terminal-vindue

TMP_DIR="/tmp/voreshave_dev"
PORT=8766

# Stop HTTP server
pkill -f "python3 -m http.server $PORT" 2>/dev/null || true

# Luk Safari localhost-vinduer og nulstil vinduesstørrelse
osascript << 'APPLESCRIPT'
tell application "Finder"
    set screenBounds to bounds of window of desktop
    set screenW to item 3 of screenBounds
    set screenH to item 4 of screenBounds
end tell

set winW to round (screenW * 0.8)
set winH to round (screenH * 0.8)
set winX to round ((screenW - winW) / 2)
set winY to round ((screenH - winH) / 2)

tell application "Safari"
    -- Luk localhost-vinduer
    set toClose to {}
    repeat with w in every window
        try
            if URL of current tab of w contains "localhost:" then
                set end of toClose to w
            end if
        end try
    end repeat
    repeat with w in toClose
        close w
    end repeat

    -- Nulstil Safari's vindueshukommelse og quit hvis ingen andre vinduer er åbne
    if (count of windows) is 0 then
        make new document
        set bounds of front window to {winX, winY, winX + winW, winY + winH}
        delay 0.3
        quit
    end if
end tell
APPLESCRIPT

# Luk Terminal-vinduet der kørte Claude Code, quit hvis ingen andre vinduer
TERM_WIN_ID=$(cat "$TMP_DIR/terminal_win_id.txt" 2>/dev/null)
if [ -n "$TERM_WIN_ID" ] && [ "$TERM_WIN_ID" -gt 0 ] 2>/dev/null; then
    osascript -e "
    tell application \"Terminal\"
        try
            close (first window whose id is $TERM_WIN_ID)
        end try
        if (count of windows) is 0 then
            quit
        end if
    end tell
    "
fi

# Ryd op
rm -f "$TMP_DIR/terminal_win_id.txt" "$TMP_DIR/server.pid" "$TMP_DIR/claude.pid" "$TMP_DIR/watcher.pid"
