#!/bin/bash
# r4chi-dotfiles · by occhi

HYPR_SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

socat -U - "UNIX-CONNECT:$HYPR_SOCK" | while read -r event; do
    case "$event" in
        "fullscreen>>"*)
            pkill -SIGUSR1 waybar
            ;;
    esac
done
