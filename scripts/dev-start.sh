#!/bin/bash
# Starter dev-miljø: server, vinduer og branch-info

PROJECT_DIR="/Users/steensonderup/Documents/udvikling/VoresHave"
PORT=8081
TMP_DIR="/tmp/voreshave_dev"
mkdir -p "$TMP_DIR"

# Slå eksisterende watcher ihjel
if [ -f "$TMP_DIR/watcher.pid" ]; then
    kill "$(cat "$TMP_DIR/watcher.pid")" 2>/dev/null || true
fi

# Fast port: dræb evt. gammel server (uanset type) og start forfra
lsof -ti tcp:$PORT 2>/dev/null | xargs kill -9 2>/dev/null || true
sleep 0.3

# Start no-cache HTTP server (forhindrer delt browser-cache på tværs af projekter)
cd "$PROJECT_DIR"
python3 "$PROJECT_DIR/scripts/devserver.py" $PORT &>/dev/null &
echo $! > "$TMP_DIR/server.pid"
sleep 0.5

# Hent skærmstørrelse dynamisk
SCREEN_INFO=$(osascript -e '
tell application "Finder"
    set b to bounds of window of desktop
    return (item 3 of b as string) & "," & (item 4 of b as string)
end tell')
SCREEN_W=$(echo "$SCREEN_INFO" | cut -d, -f1)
SCREEN_H=$(echo "$SCREEN_INFO" | cut -d, -f2)
TERM_W=$(python3 -c "print(int($SCREEN_W * 0.67))")
SAFARI_X=$TERM_W

# Placér Terminal (venstre 67%)
TERM_WIN_ID=$(osascript -e "
tell application \"Terminal\"
    set bounds of front window to {0, 0, $TERM_W, $SCREEN_H}
    return id of front window
end tell")
echo "$TERM_WIN_ID" > "$TMP_DIR/terminal_win_id.txt"

# Åbn Safari (højre 33%) med app, dokumentation og produktion
DOC_URL="http://localhost:8081/dokumentation.html?key=fFKqvN687VDqCye6kxoD"
osascript << APPLESCRIPT
tell application "Safari"
    close every window
    make new document with properties {URL:"http://localhost:8081"}
    delay 0.3
    set bounds of front window to {$SAFARI_X, 0, $SCREEN_W, $SCREEN_H}
    tell front window
        make new tab with properties {URL:"$DOC_URL"}
        make new tab with properties {URL:"https://voreshave.soenderup.dk"}
    end tell
    tell front window
        set current tab to tab 1
    end tell
    activate
end tell
APPLESCRIPT

# Giv fokus tilbage til Terminal
osascript -e 'tell application "Terminal" to activate'

# Baggrundsvagt: lukker vinduer når Claude Code afsluttes
nohup bash -c '
TMP_DIR="/tmp/voreshave_dev"
PROJECT_DIR="/Users/steensonderup/Documents/udvikling/VoresHave"

TARGET_PID=""
pid='"$PPID"'
for i in $(seq 1 20); do
    [ -z "$pid" ] || [ "$pid" -le 1 ] && break
    cmd=$(ps -p "$pid" -o args= 2>/dev/null | head -1)
    if echo "$cmd" | grep -qi "claude"; then
        TARGET_PID=$pid
        break
    fi
    pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d " ")
done

if [ -z "$TARGET_PID" ]; then
    TARGET_PID=$(pgrep -n -f "node.*claude" 2>/dev/null || true)
fi

echo "${TARGET_PID:-0}" > "$TMP_DIR/claude.pid"

if [ -n "$TARGET_PID" ] && [ "$TARGET_PID" -gt 1 ]; then
    while kill -0 "$TARGET_PID" 2>/dev/null; do
        sleep 2
    done
    "$PROJECT_DIR/scripts/dev-stop.sh"
fi
' &>/dev/null &
echo $! > "$TMP_DIR/watcher.pid"
disown

# Vis git branch-info
echo ""
echo "=== Git branches ==="
cd "$PROJECT_DIR"
CURRENT=$(git branch --show-current 2>/dev/null || echo "unknown")
ALL=$(git branch 2>/dev/null)
OTHER=$(echo "$ALL" | grep -v "^\* main$" | grep -v "^  main$" | sed 's/^[* ]*//' | grep -v "^$")

if [ -n "$OTHER" ] || [ "$CURRENT" != "main" ]; then
    echo "Aktuel branch: $CURRENT"
    echo "$ALL"
else
    echo "Branch: main (ingen andre branches)"
fi
echo ""

echo "{\"systemMessage\": \"Dev klar: http://localhost:8081 | Safari: højre 33% | Terminal: venstre 67%\"}"
