#!/bin/bash
# Oprydning: stop server, luk Terminal-vindue
# Kaldes KUN fra baggrundsvagten (watcher) — IKKE fra Stop-hook
# Stop-hook er fjernet da den fyrer efter hvert svar, ikke kun ved exit

TMP_DIR="/tmp/voreshave_dev"
PORT=8766

# Tjek session-token hvis givet — forhindrer gammel watcher i at rydde ny session op
EXPECTED_TOKEN="$1"
if [ -n "$EXPECTED_TOKEN" ]; then
    STORED_TOKEN=$(cat "$TMP_DIR/session.token" 2>/dev/null)
    if [ "$STORED_TOKEN" != "$EXPECTED_TOKEN" ]; then
        # En nyere session er startet — vi rydder ikke op
        exit 0
    fi
fi

# Stop HTTP server
pkill -f "http.server $PORT" 2>/dev/null || true

# Stop baggrundsvagt (sig selv — men det er OK)
if [ -f "$TMP_DIR/watcher.pid" ]; then
    kill "$(cat "$TMP_DIR/watcher.pid")" 2>/dev/null || true
fi

# Luk Terminal-vinduet med forsinkelse så caffeinate og claude når at stoppe
# (caffeinate køres af Claude Code og lukkes når Claude lukker — giv 4 sek.)
TERM_WIN_ID=$(cat "$TMP_DIR/terminal_win_id.txt" 2>/dev/null | tr -d '[:space:]')

if [ -n "$TERM_WIN_ID" ] && [[ "$TERM_WIN_ID" =~ ^[0-9]+$ ]]; then
    nohup bash -c "
        sleep 4
        osascript -e \"
        tell application \\\"Terminal\\\"
            try
                close (first window whose id is $TERM_WIN_ID)
            on error
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
rm -f "$TMP_DIR/terminal_win_id.txt" "$TMP_DIR/server.pid" "$TMP_DIR/claude.pid" "$TMP_DIR/watcher.pid" "$TMP_DIR/session.token"
