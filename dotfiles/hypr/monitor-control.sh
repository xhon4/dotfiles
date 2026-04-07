#!/bin/bash
# monitor-control.sh — Apaga la pantalla tras 5 min de inactividad
# Wayland replacement: usa hypridle (recomendado) o swayidle
#
# OPCIÓN A — hypridle (nativo de Hyprland, config en ~/.config/hypr/hypridle.conf)
# OPCIÓN B — swayidle (más universal, este script)
#
# Dependencias: swayidle, playerctl, hyprctl
# Instalación:  pacman -S swayidle playerctl

IDLE_LIMIT=300  # segundos (5 minutos)

swayidle -w \
    timeout $IDLE_LIMIT '
        if ! playerctl status 2>/dev/null | grep -q "Playing"; then
            hyprctl dispatch dpms off
        fi
    ' \
    resume 'hyprctl dispatch dpms on'
