TODO_FILE="$HOME/.todo.md"
TASK_LINES=$(grep '^- ' "$TODO_FILE" | sed 's/^- //')
TASK_COUNT=$(echo "$TASK_LINES" | wc -l)
TOOLTIP=$(echo "$TASK_LINES" | sed 's/^/\\u2022 /' | sed ':a;N;$!ba;s/\n/\\n/g')

echo "{\"text\": \"$TASK_COUNT\", \"tooltip\": \"$TOOLTIP\"}"
