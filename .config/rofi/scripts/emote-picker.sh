#!/bin/bash
# r4chi-dotfiles · by occhi


EMOTE_FILE="$HOME/.config/rofi/emotes.txt"
STATS_FILE="$HOME/.config/rofi/scripts/emote_stats.txt"

touch "$STATS_FILE"

TOP_5=$(sort -rn "$STATS_FILE" | head -n 5 | cut -d'|' -f2-)
ALL_EMOTES=$(cat "$EMOTE_FILE")
MENU_CONTENT=$(echo -e "$TOP_5\n$ALL_EMOTES" | awk '!x[$0]++')

SELECTED=$(echo -e "$MENU_CONTENT" | rofi -dmenu \
    -p " r4chi " \
    -i \
    -theme-str '
        window { 
            width: 450px; 
            border: 0px 0px 0px 3px; 
            border-color: #fe6e08; 
            background-color: #0B0B0B;
        }
        mainbox { padding: 5px; }
        inputbar { enabled: false; }
        listview { 
            columns: 5; 
            lines: 4; 
            cycle: false; 
            dynamic: true; 
            layout: vertical;
            fixed-columns: true;
            spacing: 3px;
        }
        element {
            orientation: vertical;
            padding: 8px 2px;
            border-radius: 2px;
            background-color: #0B0B0B;
        }
        element-text {
            horizontal-align: 0.5;
            font: "JetBrainsMono Nerd Font 9.3";
            color: #979291;
        }
        element selected {
            background-color: #fe6e08;
            border: 0px;
            border-color: #B69F64;
        }
        element-text selected {
            color: #0B0B0B;
        }
    ')

if [ -n "$SELECTED" ]; then
    echo -n "$SELECTED" | wl-copy
    if command -v wtype &> /dev/null; then
        sleep 0.1 && wtype "$SELECTED"
    fi

    if grep -q "|$SELECTED$" "$STATS_FILE"; then
        sed -i "s/^\([0-9]*\)|$SELECTED$/echo \$((\1+1))|$SELECTED/e" "$STATS_FILE"
    else
        echo "1|$SELECTED" >> "$STATS_FILE"
    fi
fi
