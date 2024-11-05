#!/bin/bash
# gets license average usage (rounded up) and provides total

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$SCRIPTS_DIR/twistlock-callapi.sh"

echo -n "License Count: "

TOTAL=0
if eval "$SCRIPT" 'stats/license' license-info.json > /dev/null; then
  NUM=$(jq '.avg | ceil' license-info.json)
else
  NUM=0
fi
TOTAL=$(( "$TOTAL" + "$NUM" ))
echo "$TOTAL"
rm license-info.json
