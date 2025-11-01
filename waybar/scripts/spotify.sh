#!/bin/bash
# Rofi Spotify Controller - Minimal 3-Button Layout

# Use absolute path for robustness
PLAYERCTL="/usr/bin/playerctl" 
PLAYER="spotify"

# --- Font Awesome Codes ---
FA_PLAY=""
FA_PAUSE=""
FA_NEXT=""
FA_PREVIOUS=""
# --------------------------

# --- Rofi Theme Configuration (Black/White/White Text) ---
# Note: The 'inputbar' is disabled, and only selectable elements are listed.
ROFI_THEME_STR="
  * {
    background-color: black;
    foreground: white;
    border-color: #333333;
    font: \"Iosevka Nerd Font 10\"; 
  }
  window {
    width: 600px;
    padding: 10px;
    border: 1px;
  }
  listview {
    border: 0px;
    padding: 5px;
  }
  element {
    padding: 8px;
    spacing: 10px;
  }
  element selected {
    background-color: white;
    text-color: black;
  }
  element-text {
    background-color: black;
    text-color: white;
  }
  inputbar {
    enabled: false;
  }
"

# --- Helper Functions ---

get_media_info() {
    STATUS=$("$PLAYERCTL" -p "$PLAYER" status 2>/dev/null)
    ARTIST=$("$PLAYERCTL" -p "$PLAYER" metadata artist 2>/dev/null)
    TITLE=$("$PLAYERCTL" -p "$PLAYER" metadata title 2>/dev/null)
    
    if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
        if [[ "$STATUS" == "Playing" ]]; then
            STATUS_ICON="$FA_PAUSE PAUSING" 
        else
            STATUS_ICON="$FA_PLAY PLAYING" 
        fi
        
        # This is the non-selectable header row
        CURRENT_SONG="\0markup-rows\0nonselectable\x1f$STATUS_ICON: $ARTIST - $TITLE"
        echo "$CURRENT_SONG"
    else
        echo "\0markup-rows\0nonselectable\x1f💤 No Media Active"
    fi
}

generate_menu() {
    # 1. Output the single non-selectable header line with song info
    echo -e "$(get_media_info)\n"
    
    CURRENT_STATUS=$("$PLAYERCTL" -p "$PLAYER" status 2>/dev/null)
    if [[ "$CURRENT_STATUS" == "Playing" ]]; then
        PLAY_PAUSE_TEXT="$FA_PAUSE Pause"
    else
        PLAY_PAUSE_TEXT="$FA_PLAY Play"
    fi

    # 2. Output only the three core action buttons
    echo "$FA_PREVIOUS Previous"
    echo "$PLAY_PAUSE_TEXT"
    echo "$FA_NEXT Next"
}

handle_action() {
    if [[ -n "$1" ]]; then
        # Use awk to grab the action word ('Previous', 'Play', 'Pause', 'Next')
        SELECTED_TEXT=$(echo "$1" | awk '{print $2}') 

        case "$SELECTED_TEXT" in
            "Previous")
                PLAYERCTL_COMMAND="previous"
                ;;
            "Pause" | "Play")
                PLAYERCTL_COMMAND="play-pause"
                ;;
            "Next")
                PLAYERCTL_COMMAND="next"
                ;;
            *)
                return 1
                ;;
        esac
        
        "$PLAYERCTL" -p "$PLAYER" "$PLAYERCTL_COMMAND" 2>/dev/null
    fi
}

# --- Main Logic ---

run_rofi_menu() {
    generate_menu | rofi -dmenu \
        -p "Spotify Control" \
        -i \
        -theme-str "$ROFI_THEME_STR" \
        -format 's' 
}

while true; do
    SELECTION=$(run_rofi_menu)
    EXIT_CODE=$?

    if [[ $EXIT_CODE -eq 0 ]]; then
        handle_action "$SELECTION"
        continue
    else
        break
    fi
done
