#!/bin/bash
# Oprydning: luk Safari-vindue, stop server, luk Terminal-vindue

TMP_DIR="/tmp/voreshave_dev"
PORT=8766

# Stop HTTP server (matcher både "python3" og "Python" med fuld sti)
pkill -f "http.server $PORT" 2>/dev/null || true

# Stop baggrundsvagt
if [ -f "$TMP_DIR/watcher.pid" ]; then
    kill "$(cat "$TMP_DIR/watcher.pid")" 2>/dev/null || true
fi

# Luk Safari localhost-faner (ingen vindues-nulstilling — crasher Safari)
osascript << 'APPLESCRIPT'
tell application "Safari"
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
end tell
APPLESCRIPT

# Luk Terminal-vinduet med en kort forsinkelse.
# Forsinkelsen er vigtig: Stop-hook'en kører mens Claude Code stadig lukker ned.
# Uden forsinkelse viser Terminal "terminate processes"-dialogen fordi claude-processen
# stadig er aktiv. Med 2 sekunders forsinkelse er Claude fuldt afsluttet.
TERM_WIN_ID=$(cat "$TMP_DIR/terminal_win_id.txt" 2>/dev/null | tr -d '[:space:]')

if [ -n "$TERM_WIN_ID" ] && [[ "$TERM_WIN_ID" =~ ^[0-9]+$ ]]; then
    # Udfør Terminal-luk i baggrunden med forsinkelse
    nohup bash -c "
        sleep 2
        osascript -e \"
        tell application \\\"Terminal\\\"
            try
                close (first window whose id is $TERM_WIN_ID)
            on error
                -- Fallback: luk front-vindue hvis ID ikke matcher
                try
                    if (count of windows) > 0 then
                        close front window
                    end if
                end try
            end try
            delay 0.3
            if (count of windows) is 0 then
                quit
            end if
        end tell
        \"
    " &>/dev/null &
    disown
fi

# Ryd op
rm -f "$TMP_DIR/terminal_win_id.txt" "$TMP_DIR/server.pid" "$TMP_DIR/claude.pid" "$TMP_DIR/watcher.pid"
