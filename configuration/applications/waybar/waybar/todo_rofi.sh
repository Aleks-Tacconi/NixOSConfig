TODO_FILE="$HOME/.todo.md"

mapfile -t tasks < <(grep '^- ' "$TODO_FILE" | sed 's/^- //')

ICON_NAME="emblem-checked"

entries=""
for t in "${tasks[@]}"; do
    entries+="$t\0icon\x1f$ICON_NAME\n"
done

chosen=$(printf '%b' "$entries" | rofi -dmenu -i -p "Todo:" -show-icons \
  -theme-str 'listview { columns: 1; } entry { placeholder: "Remove / Add task"; }')
chosen="$(echo -e "${chosen}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [[ -z "$chosen" ]]; then
    exit 0
fi

exists=0
for t in "${tasks[@]}"; do
    if [[ "$t" == "$chosen" ]]; then
        exists=1
        break
    fi
done

if [[ $exists -eq 1 ]]; then
    escaped=$(printf '%s\n' "$chosen" | sed 's/[][\/.^$*]/\\&/g')
    sed -i "/^- $escaped$/d" "$TODO_FILE"
else
    if [ -w "$TODO_FILE" ] || [ ! -e "$TODO_FILE" ]; then
        echo "- $chosen" >> "$TODO_FILE"
    else
        echo "Error: Cannot write to $TODO_FILE" >&2
        exit 1
    fi
fi

pkill waybar && waybar &
