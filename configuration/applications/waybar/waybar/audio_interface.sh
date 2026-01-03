MAX_LEN=20

mapfile -t sink_ids < <(pactl list short sinks | awk '{print $2}')
mapfile -t sink_descs < <(pactl list sinks | awk -F': ' '/Description:/{print $2}')

current=$(pactl info | awk -F': ' '/Default Sink/{print $2}')

current_index=-1
for i in "${!sink_ids[@]}"; do
    if [ "${sink_ids[$i]}" = "$current" ]; then
        current_index=$i
        break
    fi
done

if [ "$current_index" -ge 0 ]; then
    name="${sink_descs[$current_index]}"
    if [ ${#name} -gt $MAX_LEN ]; then
        name="${name:0:$MAX_LEN}..."
    fi
    echo "󱀞   $name"
fi

if [ "$1" = "click" ]; then
    next_index=$(( (current_index + 1) % ${#sink_ids[@]} ))
    next_sink="${sink_ids[$next_index]}"
    pactl set-default-sink "$next_sink"
    for stream in $(pactl list short sink-inputs | awk '{print $1}'); do
        pactl move-sink-input "$stream" "$next_sink"
    done
fi

