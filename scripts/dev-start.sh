#!/bin/bash
# Starter dev-miljø: server, vinduer og branch-info

PROJECT_DIR="/Users/steensonderup/Documents/udvikling/VoresHave"
PORT=8766
TMP_DIR="/tmp/voreshave_dev"
mkdir -p "$TMP_DIR"

# Slå eksisterende watcher ihjel
if [ -f "$TMP_DIR/watcher.pid" ]; then
    kill "$(cat "$TMP_DIR/watcher.pid")" 2>/dev/null || true
fi

# Stop eksisterende server (matcher både "python3" og "Python" med fuld sti)
pkill -f "http.server $PORT" 2>/dev/null || true
sleep 0.3

# Start HTTP server
cd "$PROJECT_DIR"
python3 -m http.server $PORT &>/dev/null &
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

# Gem vindues-ID og placér Terminal (venstre 67%)
TERM_WIN_ID=$(osascript -e "
tell application \"Terminal\"
    set bounds of front window to {0, 0, $TERM_W, $SCREEN_H}
    return id of front window
end tell")
echo "$TERM_WIN_ID" > "$TMP_DIR/terminal_win_id.txt"

# Åbn Safari med localhost (ingen AppleScript — crasher Safari)
open -a Safari "http://localhost:$PORT"
sleep 0.5

# Giv fokus tilbage til Terminal
osascript -e 'tell application "Terminal" to activate'

# Gem Claude-processens PID (= PPID for dette script = direkte forælder)
CLAUDE_PID=$PPID
echo "$CLAUDE_PID" > "$TMP_DIR/claude.pid"

# Start baggrundsvagt: lukker vinduer når Claude Code afsluttes (ikke ved /clear)
# Bemærk: setsid bruges IKKE — det er Linux-only og findes ikke på macOS
nohup bash -c '
TMP_DIR="/tmp/voreshave_dev"
PROJECT_DIR="/Users/steensonderup/Documents/udvikling/VoresHave"
CLAUDE_PID='"$CLAUDE_PID"'

if [ -n "$CLAUDE_PID" ] && [ "$CLAUDE_PID" -gt 1 ]; then
    while kill -0 "$CLAUDE_PID" 2>/dev/null; do
        sleep 2
    done
    # Claude Code er lukket — kør oprydning
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

echo "{\"systemMessage\": \"Dev klar: http://localhost:$PORT | Safari: højre 33% | Terminal: venstre 67%\"}"
