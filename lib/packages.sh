#!/usr/bin/env bash
# ================================================================
#  ricectl package management (pacman + yay)
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core.sh" 2>/dev/null || true

# Check if a package is installed
pkg_installed() {
    pacman -Qq "$1" &>/dev/null
}

# Install packages via pacman (idempotent)
install_pacman() {
    local to_install=()
    for pkg in "$@"; do
        if pkg_installed "$pkg"; then
            success "$pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Installing ${#to_install[@]} pacman packages..."
        run "sudo pacman -S --noconfirm --needed ${to_install[*]}"
    fi
}

# Install packages via yay/AUR (idempotent)
install_aur() {
    ensure_yay

    local to_install=()
    for pkg in "$@"; do
        if pkg_installed "$pkg"; then
            success "$pkg (AUR) already installed"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Installing ${#to_install[@]} AUR packages..."
        run "yay -S --noconfirm --needed ${to_install[*]}"
    fi
}

# Ensure yay is installed
ensure_yay() {
    if ! command -v yay &>/dev/null; then
        info "Installing yay (AUR helper)..."
        run "sudo pacman -S --needed --noconfirm base-devel git"
        local tmpdir
        tmpdir="$(mktemp -d)"
        run "git clone https://aur.archlinux.org/yay.git '$tmpdir/yay'"
        run "cd '$tmpdir/yay' && makepkg -si --noconfirm"
        rm -rf "$tmpdir"
    fi
}

# Install from a module's package lists
install_module_packages() {
    local module_yaml="$1"
    local prefix="mod"

    parse_yaml "$module_yaml" "$prefix"

    # Pacman packages
    local pacman_pkgs
    pacman_pkgs=($(yaml_list "$prefix" "pacman"))
    if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
        install_pacman "${pacman_pkgs[@]}"
    fi

    # AUR packages
    local aur_pkgs
    aur_pkgs=($(yaml_list "$prefix" "aur"))
    if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
        install_aur "${aur_pkgs[@]}"
    fi
}

# Enable systemd services (idempotent)
enable_services() {
    for service in "$@"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            success "Service $service already enabled"
        else
            info "Enabling service: $service"
            run "sudo systemctl enable $service"
        fi
    done
}
