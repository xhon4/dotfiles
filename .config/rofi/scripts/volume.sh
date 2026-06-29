#!/bin/bash
# r4chi-dotfiles · by occhi

notify() {
    dunstify -u low -h string:x-dunst-stack-tag:cvolum "$@"
}

get_volume() {
    status=$(pamixer --get-volume-human)
    if [ "$status" = "muted" ]; then
        echo "muted"
    else
        echo "$status" | sed 's/%//'
    fi
}

get_glyph() {
    current_vol=$(get_volume)
    if [ "$current_vol" = "muted" ] || [ "$current_vol" -eq 0 ] 2>/dev/null; then
        glyph="󰖁"
    elif [ "$current_vol" -le 33 ] 2>/dev/null; then
        glyph="󰕿"
    elif [ "$current_vol" -le 66 ] 2>/dev/null; then
        glyph="󰖀"
    else
        glyph="󰕾"
    fi
}

show_notification() {
    get_glyph
    message="Volume: $(get_volume)"
    echo "$message" | grep -q "muted" || message="${message}%"
    notify "$glyph  $message"
}

adjust_volume() {
    pamixer --unmute
    pamixer --allow-boost --set-limit 150 "$@"
    show_notification
}

toggle_mute() {
    pamixer --toggle-mute
    get_glyph
    if [ "$(pamixer --get-mute)" = "true" ]; then
        message="󰖁  Muted"
    else
        message="$glyph  Unmuted"
    fi
    notify "$message"
}

case $1 in
    --get)      get_volume ;;
    --inc)      adjust_volume -i 5 ;;
    --dec)      adjust_volume -d 5 ;;
    --toggle)   toggle_mute ;;
    *)          echo "$(get_volume)%" ;;
esac
