#!/usr/bin/env bash
# ================================================================
#  OXH Dotfiles-as-a-Platform — Bootstrap Installer
#  Usage: curl -sL https://raw.githubusercontent.com/xhon4/dotfiles/main/install.sh | bash
#  Or:    ./install.sh [--profile=NAME] [--variant=pc|laptop]
# ================================================================

set -euo pipefail

# Colors
C_RESET='\e[0m'; C_BLUE='\e[34m'; C_GREEN='\e[32m'; C_YELLOW='\e[33m'; C_RED='\e[31m'; C_BOLD='\e[1m'; C_CYAN='\e[36m'

info()    { echo -e "${C_BLUE}[>]${C_RESET} $1"; }
success() { echo -e "${C_GREEN}[✓]${C_RESET} $1"; }
warn()    { echo -e "${C_YELLOW}[!]${C_RESET} $1"; }
error()   { echo -e "${C_RED}[✗]${C_RESET} $1"; exit 1; }

# ================================================================
# BANNER
# ================================================================

echo -e "${C_BOLD}${C_CYAN}"
cat <<'BANNER'

   ██████╗ ██╗  ██╗██╗  ██╗
  ██╔═══██╗╚██╗██╔╝██║  ██║
  ██║   ██║ ╚███╔╝ ███████║
  ██║   ██║ ██╔██╗ ██╔══██║
  ╚██████╔╝██╔╝ ██╗██║  ██║
   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
   Dotfiles as a Platform

BANNER
echo -e "${C_RESET}"

# ================================================================
# OS CHECK
# ================================================================

if [[ ! -f /etc/os-release ]]; then
    error "Cannot detect OS"
fi

source /etc/os-release

if [[ "$ID" != "arch" ]]; then
    error "This installer requires Arch Linux (detected: $ID)"
fi

success "Arch Linux detected ($PRETTY_NAME)"

# ================================================================
# USER CHECK
# ================================================================

if [[ $EUID -eq 0 ]]; then
    error "Do not run as root. Use a normal user with sudo access."
fi

# ================================================================
# INTERNET CHECK
# ================================================================

if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
    error "No internet connection"
fi

success "Internet connection OK"

# ================================================================
# DEPENDENCIES
# ================================================================

info "Installing bootstrap dependencies..."
sudo pacman -S --needed --noconfirm git rsync curl base-devel

# ================================================================
# CLONE / UPDATE REPO
# ================================================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
REPO_URL="${REPO_URL:-https://github.com/xhon4/dotfiles.git}"

if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles repo found at $DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    git pull --rebase || warn "Git pull failed, using existing version"
else
    info "Cloning dotfiles repo..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
fi

success "Dotfiles ready at $DOTFILES_DIR"

# ================================================================
# HAND OFF TO RICECTL
# ================================================================

chmod +x "$DOTFILES_DIR/ricectl"

info "Launching ricectl..."
echo ""

exec "$DOTFILES_DIR/ricectl" install "$@"
