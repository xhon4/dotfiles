#!/usr/bin/env bash
# ================================================================
#  ricectl OS detection
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core.sh" 2>/dev/null || true

detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

detect_os_pretty() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$PRETTY_NAME"
    else
        echo "Unknown OS"
    fi
}

require_arch() {
    local os
    os="$(detect_os)"
    if [[ "$os" != "arch" ]]; then
        error "This system requires Arch Linux (detected: $os)"
        exit 1
    fi
}

detect_gpu() {
    if lspci 2>/dev/null | grep -qi "amd.*vga\|radeon"; then
        echo "amd"
    elif lspci 2>/dev/null | grep -qi "nvidia"; then
        echo "nvidia"
    elif lspci 2>/dev/null | grep -qi "intel.*vga\|intel.*graphics"; then
        echo "intel"
    else
        echo "unknown"
    fi
}

detect_chassis() {
    local chassis
    chassis="$(hostnamectl chassis 2>/dev/null || echo "unknown")"
    case "$chassis" in
        laptop|notebook|portable|tablet) echo "laptop" ;;
        desktop|server|tower)            echo "pc" ;;
        *)                               echo "unknown" ;;
    esac
}

is_wayland() {
    [[ -n "${WAYLAND_DISPLAY:-}" ]]
}

get_hostname() {
    hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown"
}
