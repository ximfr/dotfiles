#!/bin/bash

FIFO_PATH="/tmp/cava.fifo"

# Create FIFO if not present
[ -p "$FIFO_PATH" ] || mkfifo "$FIFO_PATH"

# Start cava if not already running
pgrep -x cava >/dev/null || cava -p ~/.config/cava/config > "$FIFO_PATH" &

# Read cava output
while read -r line; do
    # Each number = one bar height
    bars=""
    for num in $line; do
        level=$((num / 10))
        bars+="$(printf '█%.0s' $(seq 1 $level)) "
    done
    echo "{\"text\":\"$bars\"}"
done < "$FIFO_PATH"

