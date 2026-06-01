#!/bin/bash
# Genindlæser localhost-fanen i Safari, så indholdet altid er friskt efter
# hver ændring. Kaldes af Stop-hook (fyrer når Claude er færdig med et svar).
# Sætter fanens URL til sig selv = reload UDEN at aktivere Safari, så fokus
# bliver i Terminal. Dokumentationsfanen (krypteret) røres ikke.

PORT=8080

osascript <<APPLESCRIPT 2>/dev/null
tell application "Safari"
    repeat with w in windows
        repeat with t in tabs of w
            try
                if (URL of t) contains "localhost:$PORT" and (URL of t) does not contain "dokumentation" then
                    set URL of t to (URL of t)
                end if
            end try
        end repeat
    end repeat
end tell
APPLESCRIPT

exit 0
