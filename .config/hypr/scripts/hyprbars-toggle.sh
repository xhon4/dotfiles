#!/bin/bash
# r4chi-dotfiles · by occhi


while true; do
    active=$(hyprctl activewindow -j)

    floating=$(echo "$active" | jq '.floating')

    if [ "$floating" = "true" ]; then
        hyprctl setprop active hyprbars:bar 1
    else
        hyprctl setprop active hyprbars:bar 0
    fi

    sleep 0.2
done
