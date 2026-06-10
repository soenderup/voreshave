#!/bin/bash
# Oprydning: stop server, luk Safari og Terminal helt.

TMP_DIR="/tmp/voreshave_dev"
PORT=8081
mkdir -p "$TMP_DIR"

# SessionEnd-hooket sender JSON på stdin med et "reason"-felt. /clear (og /compact)
# afslutter IKKE processen - de rydder bare konteksten, og en ny SessionStart følger
# straks efter i SAMME proces. Lukker vi ned her, venter vi forgæves på at den
# (stadig levende) Claude-PID dør og river til sidst terminalen ned midt i sessionen
# -> "vil du tillade at terminalen lukkes"-advarslen. Luk derfor KUN ned ved en
# rigtig afslutning. Baggrundsvagten kalder uden stdin (tom payload) -> luk ned
# (vagten fyrer kun når Claude faktisk er død).
INPUT=""
[ -t 0 ] || INPUT=$(cat 2>/dev/null)
if printf '%s' "$INPUT" | grep -Eq '"reason"[[:space:]]*:[[:space:]]*"(clear|compact)"'; then
    exit 0
fi

# Kun én oprydning ad gangen. Både SessionEnd-hooket og baggrundsvagten kan
# kalde dette script næsten samtidig. mkdir er atomart og fungerer som lås.
# Låsen frigives af den detachede oprydning nedenfor (ikke her), så den holder
# helt til oprydningen er færdig. dev-start.sh rydder evt. stale lås.
LOCK="$TMP_DIR/stop.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
    exit 0
fi

CLAUDE_PID=$(cat "$TMP_DIR/claude.pid" 2>/dev/null)

# Hele oprydningen detaches fra den kaldende proces og venter til Claude er helt
# død, FØR den lukker noget. To grunde:
#   1) SessionEnd-hooket kalder dette mens Claude stadig kører i terminalvinduet.
#      Lukker vi vinduet da, viser Terminal sin "der kører stadig processer i
#      vinduet"-advarsel. Venter vi til Claude er væk, er vinduet rent og lukker
#      uden advarsel.
#   2) Rives terminalen (og dermed dette script) ned midt i osascript, afbrydes
#      Safaris quit: vinduet lukkes, men Safari-processen overlever. Detach +
#      vent gør quit uafbrudt, så Safari afsluttes helt.
nohup bash -c '
TMP_DIR="$1"; PORT="$2"; LOCK="$3"; CLAUDE_PID="$4"
trap "rmdir \"$LOCK\" 2>/dev/null" EXIT

# Diagnostik-log: så en mislykket exit efterlader spor vi kan inspicere bagefter
# (ellers står vi igen og igen med "Safari overlevede" uden at vide hvor i
# sekvensen det gik galt). Overskrives ved hver nedlukning.
LOG="$TMP_DIR/stop.log"
log() { echo "[$(date "+%H:%M:%S")] $*" >> "$LOG"; }
: > "$LOG"
log "dev-stop start. CLAUDE_PID=$CLAUDE_PID PORT=$PORT PPID=$PPID self=$$"

# Vent til Claude-processen er helt død (op til ~10 s).
if [ -n "$CLAUDE_PID" ] && [ "$CLAUDE_PID" -gt 1 ] 2>/dev/null; then
    for i in $(seq 1 50); do
        kill -0 "$CLAUDE_PID" 2>/dev/null || break
        sleep 0.2
    done
    if kill -0 "$CLAUDE_PID" 2>/dev/null; then
        log "ADVARSEL: Claude-PID $CLAUDE_PID lever stadig efter 10 s ventetid"
    else
        log "Claude-PID $CLAUDE_PID er død - fortsætter oprydning"
    fi
fi

# Stop HTTP-serveren (fast port - uanset servertype).
lsof -ti tcp:$PORT 2>/dev/null | xargs kill -9 2>/dev/null || true
log "devserver paa port $PORT stoppet (lsof-kill koert)"

# Ejerskab afgør alt: dev-start skrev "yes" hvis VI startede Safari, "no" hvis den
# kørte i forvejen. Ejer vi den, lukkes Safari helt - også hvis localhost-vinduet
# er forsvundet (det er præcis dét der ellers efterlader en skjult zombie-proces).
# Ejer vi den ikke, lukkes kun localhost-vinduerne, og processen røres aldrig.
OWNED=$(cat "$TMP_DIR/safari_owned.txt" 2>/dev/null)
log "Safari-ejerskab: OWNED=[$OWNED]"

# Luk localhost-vinduer. Ejer vi Safari, gøres ét localhost-vindue 80%-centreret
# FØR lukning (så Safari husker 80% til næste manuelle åbning); selve quit sker på
# shell-siden bagefter. Vi opretter aldrig et nyt vindue.
DID_QUIT=$(OWNED="$OWNED" osascript << "APPLESCRIPT"
set ownSafari to (do shell script "echo $OWNED")
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
    set toClose to {}
    repeat with w in every window
        set hasLocal to false
        try
            repeat with t in tabs of w
                if (URL of t) contains "localhost:" then
                    set hasLocal to true
                    exit repeat
                end if
            end repeat
        end try
        if hasLocal then set end of toClose to w
    end repeat

    if ownSafari is "yes" then
        -- Vi startede Safari -> luk den helt. Findes der et localhost-vindue, gøres
        -- det første 80%-centreret og lukkes til sidst (så geometrien huskes); de
        -- øvrige localhost-vinduer lukkes først. Er der intet localhost-vindue
        -- (zombie uden vindue), springes lukningen over - quit sker alligevel på
        -- shell-siden. Vi kalder bevidst IKKE quit her inde i tell-blokken: det
        -- ville afbryde Safaris Apple-event-forbindelse, så "QUIT" aldrig returneres.
        if (count of toClose) is greater than 0 then
            set keepWin to item 1 of toClose
            set bounds of keepWin to {winX, winY, winX + winW, winY + winH}
            repeat with w in toClose
                if w is not keepWin then close w
            end repeat
            delay 0.2
            close keepWin
        end if
        return "QUIT"
    else
        -- Safari kørte før os: luk kun localhost-vinduer, rør aldrig processen.
        repeat with w in toClose
            close w
        end repeat
        return "KEEP"
    end if
end tell
APPLESCRIPT
)
log "AppleScript-resultat (DID_QUIT)=[$DID_QUIT]"

# Afslut Safari på shell-siden, hvis vi ejer den. AppleScript har lukket vinduerne
# men kalder bevidst IKKE quit selv (det ville afbryde dens egen Apple-event-
# forbindelse). Her er vi en uafhængig proces, så quit kan ikke afbryde os; går
# quit-eventet alligevel tabt, tvinges processen ned med killall. Betingelsen er
# OWNED (ikke DID_QUIT), så Safari lukkes selv hvis osascript fejlede og returnerede
# tomt - ejer vi Safari, må den aldrig overleve. Ejer vi den ikke, røres den aldrig.
if [ "$OWNED" = "yes" ]; then
    log "QUIT-gren: Safari-PID foer quit=[$(pgrep -x Safari | tr "\n" " ")]"
    osascript -e "tell application \"Safari\" to quit" 2>>"$LOG" || log "osascript quit fejlede"
    for i in $(seq 1 15); do
        pgrep -x Safari >/dev/null 2>&1 || break
        sleep 0.2
    done
    if pgrep -x Safari >/dev/null 2>&1; then
        log "Safari lever stadig efter osascript-quit -> killall"
        killall Safari 2>>"$LOG" || log "killall fejlede"
        sleep 0.5
        if pgrep -x Safari >/dev/null 2>&1; then
            log "Safari lever STADIG efter killall -> kill -9"
            pgrep -x Safari | xargs kill -9 2>>"$LOG" || true
        fi
    fi
    log "QUIT-gren faerdig: Safari-PID efter=[$(pgrep -x Safari | tr "\n" " ")]"
else
    log "Ikke QUIT-gren (brugeren havde egne vinduer, eller ingen localhost) - Safari roeres ikke"
fi

# Luk terminalvinduet (Claude er nu død -> ingen kørende-proces-advarsel).
TERM_WIN_ID=$(cat "$TMP_DIR/terminal_win_id.txt" 2>/dev/null)
if [ -n "$TERM_WIN_ID" ] && [ "$TERM_WIN_ID" -gt 0 ] 2>/dev/null; then
    osascript -e "tell application \"Terminal\"
        try
            close (first window whose id is $TERM_WIN_ID)
        end try
        if (count of windows) is 0 then quit
    end tell" 2>/dev/null || true
fi

log "Terminalvindue lukket. Oprydning faerdig."
rm -f "$TMP_DIR/terminal_win_id.txt" "$TMP_DIR/server.pid" "$TMP_DIR/claude.pid" "$TMP_DIR/watcher.pid"
' _ "$TMP_DIR" "$PORT" "$LOCK" "$CLAUDE_PID" &>/dev/null &
disown
exit 0
