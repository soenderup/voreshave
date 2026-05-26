#!/bin/bash
# Skriv besked til terminal når index.html ændres
# Safari-auto-reload er deaktiveret — tryk Cmd+R manuelt

PROJECT_ROOT="/Users/steensonderup/Documents/udvikling/VoresHave"

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

# Kun for index.html
if [[ "$FILE_PATH" != "$PROJECT_ROOT/index.html" ]]; then
    exit 0
fi

echo "↻  index.html ændret — tryk Cmd+R i Safari"

exit 0
