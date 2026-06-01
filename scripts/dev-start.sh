#!/bin/bash
# Starter dev-miljø: server, vinduer og branch-info

PROJECT_DIR="/Users/steensonderup/Documents/udvikling/VoresHave"
PORT=8080
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
SAFARI_W=$(python3 -c "print(int($SCREEN_W * 0.33))")

# Gem vindues-ID og placér Terminal (venstre 67%)
TERM_WIN_ID=$(osascript -e "
tell application \"Terminal\"
    set bounds of front window to {0, 0, $TERM_W, $SCREEN_H}
    return id of front window
end tell")
echo "$TERM_WIN_ID" > "$TMP_DIR/terminal_win_id.txt"

# Åbn Safari med localhost
open -a Safari "http://localhost:$PORT"
sleep 2.0

# Placér Safari (højre 33%) — brug Safari's eget AppleScript med bounds (én operation)
SAFARI_RIGHT=$(python3 -c "print(int($TERM_W + $SAFARI_W))")
osascript -e "
tell application \"Safari\"
    activate
    delay 0.3
    set bounds of window 1 to {$TERM_W, 0, $SAFARI_RIGHT, $SCREEN_H}
end tell" 2>/dev/null || true

# Slå Responsivt design-visning til (kun hvis den ikke allerede er aktiv)
sleep 0.5
osascript -e '
tell application "Safari" to activate
delay 0.3
tell application "System Events"
    tell process "Safari"
        try
            click menu item "Start responsiv designfunktion" of menu "Udvikler" of menu bar 1
        end try
    end tell
end tell' 2>/dev/null || true

# Åbn dokumentation som baggrundsfaneblad (appen forbliver i fokus)
sleep 0.3
osascript -e "
tell application \"Safari\"
    tell window 1
        set newTab to make new tab with properties {URL:\"http://localhost:$PORT/dokumentation.html?key=fFKqvN687VDqCye6kxoD\"}
        set current tab of window 1 to tab 1 of window 1
    end tell
end tell" 2>/dev/null || true

# Giv fokus tilbage til Terminal
osascript -e 'tell application "Terminal" to activate'

# Find den faktiske Claude-proces ved at gå op ad process-træet
# (PPID er ikke altid direkte Claude — der kan være et mellemliggende shell)
CLAUDE_PID=""
CURRENT_PID=$$
for i in $(seq 1 10); do
    PARENT=$(ps -p "$CURRENT_PID" -o ppid= 2>/dev/null | tr -d ' ')
    [ -z "$PARENT" ] || [ "$PARENT" = "1" ] && break
    PNAME=$(ps -p "$PARENT" -o comm= 2>/dev/null | tr -d ' ')
    if [[ "$PNAME" == *"claude"* ]] || [[ "$PNAME" == *"node"* ]]; then
        CLAUDE_PID=$PARENT
        break
    fi
    CURRENT_PID=$PARENT
done

# Fallback: brug PPID hvis træ-søgningen fejlede
if [ -z "$CLAUDE_PID" ]; then
    CLAUDE_PID=$PPID
fi

echo "$CLAUDE_PID" > "$TMP_DIR/claude.pid"

# Skriv session-token for at undgå race conditions
SESSION_TOKEN="$$-$(date +%s)"
echo "$SESSION_TOKEN" > "$TMP_DIR/session.token"

# Start baggrundsvagt: lukker vinduer når Claude Code afsluttes
# Stop-hooken er FJERNET — kun watcher'en håndterer oprydning ved exit
# Årsag: Stop-hooken fyrer efter HVERT svar (ikke kun ved exit),
#         hvilket dræbte serveren og viste Terminal-dialog under aktiv session
nohup bash -c '
TMP_DIR="/tmp/voreshave_dev"
PROJECT_DIR="/Users/steensonderup/Documents/udvikling/VoresHave"
CLAUDE_PID='"$CLAUDE_PID"'
SESSION_TOKEN='"$SESSION_TOKEN"'

if [ -n "$CLAUDE_PID" ] && [ "$CLAUDE_PID" -gt 1 ]; then
    while kill -0 "$CLAUDE_PID" 2>/dev/null; do
        sleep 2
    done
    # Claude Code er lukket — tjek at det er vores session (ikke en nyere)
    STORED_TOKEN=$(cat "$TMP_DIR/session.token" 2>/dev/null)
    if [ "$STORED_TOKEN" = "$SESSION_TOKEN" ]; then
        "$PROJECT_DIR/scripts/dev-stop.sh" "$SESSION_TOKEN"
    fi
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
