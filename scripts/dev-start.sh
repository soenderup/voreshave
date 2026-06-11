#!/bin/bash
# Starter dev-miljø: server, vinduer og branch-info

PROJECT_DIR="/Users/steensonderup/Documents/udvikling/VoresHave"
PORT=8081
TMP_DIR="/tmp/voreshave_dev"
mkdir -p "$TMP_DIR"

# SessionStart-hooket sender JSON på stdin med et "source"-felt. Ved /clear og
# /compact kører vi videre i SAMME proces - server, vinduer og faner findes allerede.
# Genopbyg derfor ikke miljøet (det ville lukke alle Safari-vinduer, genåbne faner og
# flytte rundt på vinduerne midt i en session). Kør kun fuld opsætning ved "startup"
# og "resume" (ny proces -> intet miljø endnu).
INPUT=""
[ -t 0 ] || INPUT=$(cat 2>/dev/null)
if printf '%s' "$INPUT" | grep -Eq '"source"[[:space:]]*:[[:space:]]*"(clear|compact)"'; then
    exit 0
fi

# Ryd evt. stale oprydnings-lås (hvis en tidligere dev-stop blev dræbt før den
# nåede at frigive den - ellers ville næste nedlukning tro en anden allerede kører)
rmdir "$TMP_DIR/stop.lock" 2>/dev/null || true

# Zombie-tjek: efterlod forrige nedlukning en Safari den burde have dræbt?
# stop.log overskrives ved hver nedlukning, så den afspejler sidste session.
# Linjen "Safari-PID efter=[...]" skrives kun i QUIT-grenen (OWNED=yes). Er den
# ikke tom, overlevede en Safari vi ejede = en zombie der stadig kører nu.
SAFARI_WARN=""
SAFARI_ZOMBIE=""
STOPLOG="$TMP_DIR/stop.log"
if [ -f "$STOPLOG" ]; then
    LEFTOVER=$(grep "Safari-PID efter=\[" "$STOPLOG" | tail -1 | sed -E 's/.*efter=\[(.*)\].*/\1/')
    if [ -n "${LEFTOVER// /}" ]; then
        SAFARI_ZOMBIE="$LEFTOVER"
    fi
fi

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
# Ønsket: Safari = højre ~33%. MEN Safari har en minimumsbredde; bliver de 33%
# smallere end den, klamper Safari sin egen bredde og skubber højre kant ud over
# skærmen. Derfor placeres Terminal IKKE her - først åbner vi Safari på den
# ønskede X, måler dens FAKTISKE bredde, flytter den flush mod højre kant, og
# lader så Terminalen fylde resten (op til Safaris venstre kant). Splittet
# tilpasser sig dermed automatisk til skærmstørrelse og Safaris minimum.
WANT_SAFARI_X=$(python3 -c "print(int($SCREEN_W * 0.67))")

# Ejerskab: kørte Safari FØR vi startede den? Skriv en flag-fil som dev-stop
# læser. Ejer vi Safari (vi startede den), lukker dev-stop den helt - også hvis
# vores localhost-vindue er forsvundet (ellers efterlades en skjult zombie-proces
# uden vindue). Kørte Safari allerede, lukker dev-stop kun localhost-vinduerne.
if ! pgrep -x Safari >/dev/null 2>&1; then
    # Safari kørte ikke -> vi starter den -> vi ejer den.
    echo "yes" > "$TMP_DIR/safari_owned.txt"
elif [ -n "$SAFARI_ZOMBIE" ]; then
    # Safari kører, OG forrige nedlukning efterlod en zombie vi ejede: den
    # kørende Safari ER den zombie. Adoptér den, så DENNE sessions nedlukning
    # rydder den op (ellers ville "no" gøre at den aldrig blev dræbt igen).
    echo "yes" > "$TMP_DIR/safari_owned.txt"
    SAFARI_WARN=" | Bemaerk: forrige nedlukning efterlod en Safari-zombie (PID $SAFARI_ZOMBIE) - den er nu adopteret og lukkes ved exit"
else
    # Safari kørte i forvejen (brugerens egen) -> vi ejer den ikke.
    echo "no" > "$TMP_DIR/safari_owned.txt"
fi

# Åbn Safari (højre 33%) med app, dokumentation og produktion
DOC_URL="http://localhost:8081/dokumentation.html"
SAFARI_LEFT=$(osascript << APPLESCRIPT
tell application "Safari"
    close every window
    make new document with properties {URL:"http://localhost:8081"}
    delay 0.3
    set bounds of front window to {$WANT_SAFARI_X, 0, $SCREEN_W, $SCREEN_H}
    delay 0.1
    set b to bounds of front window
    set actualW to (item 3 of b) - (item 1 of b)
    set newX to $SCREEN_W - actualW
    if newX < 0 then set newX to 0
    set bounds of front window to {newX, 0, $SCREEN_W, $SCREEN_H}
    tell front window
        make new tab with properties {URL:"$DOC_URL"}
        make new tab with properties {URL:"https://voreshave.soenderup.dk"}
    end tell
    tell front window
        set current tab to tab 1
    end tell
    activate
    return newX as string
end tell
APPLESCRIPT
)

# Placér Terminal (venstre) op til Safaris faktiske venstre kant - intet overlap,
# intet hul. Falder tilbage til 67% hvis målingen mod forventning fejlede.
TERM_W=${SAFARI_LEFT:-$WANT_SAFARI_X}
TERM_WIN_ID=$(osascript -e "
tell application \"Terminal\"
    set bounds of front window to {0, 0, $TERM_W, $SCREEN_H}
    return id of front window
end tell")
echo "$TERM_WIN_ID" > "$TMP_DIR/terminal_win_id.txt"

# Gå i Responsiv Designfunktion (iPhone-visning) på app- og evt. live-fanen,
# men IKKE dokumentationsfanen. Safari har ingen AppleScript-kommando til dette;
# det udløses via tastetrykket Ctrl-Cmd-R gennem System Events. Kræver:
#   1) Safaris Develop-menu (Indstillinger > Avanceret > "Vis funktioner for webudviklere")
#   2) Tilgængeligheds-tilladelse til Terminal (Systemindstillinger > Anonymitet & sikkerhed)
# Mangler en af delene, gør 'try' at dev-start ellers kører videre uforstyrret.
osascript << 'APPLESCRIPT'
try
    tell application "Safari" to activate
    delay 0.3
    tell application "Safari" to set tabURLs to URL of every tab of front window
    repeat with i from 1 to count of tabURLs
        if (item i of tabURLs) does not contain "dokumentation" then
            tell application "Safari" to set current tab of front window to tab i of front window
            delay 0.3
            tell application "System Events" to keystroke "r" using {control down, command down}
            delay 0.5
        end if
    end repeat
    -- Vis app-fanen (localhost) til sidst
    tell application "Safari" to set current tab of front window to tab 1 of front window
end try
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

echo "{\"systemMessage\": \"Dev klar: http://localhost:8081 | Safari: højre 33% | Terminal: venstre 67%$SAFARI_WARN\"}"
