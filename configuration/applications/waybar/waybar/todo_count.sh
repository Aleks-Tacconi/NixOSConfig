#!/usr/bin/env bash

TODO_FILE="$HOME/.todo.md"

if [ ! -f "$TODO_FILE" ]; then
    echo '{"text": "0", "tooltip": "No tasks"}'
    exit 0
fi

TASK_LINES=$(grep '^- ' "$TODO_FILE" | sed 's/^- //')
TASK_COUNT=$(grep -c '^- ' "$TODO_FILE")

if [ "$TASK_COUNT" -eq 0 ]; then
    TOOLTIP="No tasks"
else
    TOOLTIP=$(echo "$TASK_LINES" | sed 's/^/\\u2022 /' | sed ':a;N;$!ba;s/\n/\\n/g')
fi

echo "{\"text\": \"$TASK_COUNT\", \"tooltip\": \"$TOOLTIP\"}"
