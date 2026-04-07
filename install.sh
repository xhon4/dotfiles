#!/bin/bash

# ================================================================
#   OXH BRUTALIST INSTALLER v5.0
#   Arch Linux / Hyprland dotfiles - Full automated setup
# ================================================================

# --- COLORES ---
BOLD="$(tput bold)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
CYAN="$(tput setaf 6)"
RESET="$(tput sgr0)"

# --- HELPERS ---
info()    { echo -e "${BLUE}${BOLD}[>]${RESET} $1"; }
success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $1"; }
step()    { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${RESET}"; }

# --- VERIFICAR QUE SE CORRE DESDE EL REPO ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || { error "No se pudo acceder al directorio del script."; exit 1; }

if [[ ! -d "configs/pc" || ! -d "configs/laptop" ]]; then
    error "Corré el script desde la raíz del repo dotfiles."
    exit 1
fi

# --- VERIFICAR QUE NO SE CORRE COMO ROOT ---
if [[ "$EUID" -eq 0 ]]; then
    error "No corras el script como root. Usá tu usuario normal."
    exit 1
fi

# ================================================================
#   PANTALLA DE BIENVENIDA Y ELECCIÓN DE PERFIL
# ================================================================
clear
echo "${BLUE}${BOLD}"
echo "  ██████╗ ██╗  ██╗██╗  ██╗"
echo "  ██╔══██╗╚██╗██╔╝██║  ██║"
echo "  ██║  ██║ ╚███╔╝ ███████║"
echo "  ██║  ██║ ██╔██╗ ██╔══██║"
echo "  ██████╔╝██╔╝ ██╗██║  ██║"
echo "  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
echo "${RESET}"
echo "${BOLD}  OXH BRUTALIST INSTALLER v5.0${RESET}"
echo "  ─────────────────────────────────────────"
echo ""
warn "Esto va a sobreescribir tu ~/.config/ actual."
echo ""

# Elegir perfil
echo "${BOLD}  ¿Qué perfil querés instalar?${RESET}"
echo ""
echo "  ${CYAN}[1]${RESET} PC        — resolución estándar, sin módulo de batería"
echo "  ${CYAN}[2]${RESET} Laptop    — 1366x768, módulo de batería en Waybar"
echo ""
read -p "  Perfil [1/2]: " profile_choice

case "$profile_choice" in
    1) PROFILE="pc";     PROFILE_LABEL="PC" ;;
    2) PROFILE="laptop"; PROFILE_LABEL="Laptop" ;;
    *) error "Opción inválida."; exit 1 ;;
esac

echo ""
echo "  Perfil seleccionado: ${GREEN}${BOLD}$PROFILE_LABEL${RESET}"
echo ""
read -p "  ¿Confirmás la instalación? [y/N]: " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && echo "  Abortado." && exit 0

# ================================================================
#   SUDO KEEP-ALIVE
# ================================================================
sudo -v || { error "No se pudo obtener privilegios sudo."; exit 1; }
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!

# ================================================================
#   STEP 1 — ACTUALIZACIÓN DEL SISTEMA
# ================================================================
step "1/9 — Actualizando sistema"
sudo pacman -Syu --noconfirm
success "Sistema actualizado."

# ================================================================
#   STEP 2 — INSTALAR YAY (AUR Helper)
# ================================================================
step "2/9 — AUR Helper (yay)"
if ! command -v yay &>/dev/null; then
    info "Instalando yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    (cd /tmp/yay-build && makepkg -si --noconfirm)
    success "yay instalado."
else
    success "yay ya está instalado."
fi

# ================================================================
#   STEP 3 — PAQUETES
# ================================================================
step "3/9 — Instalando paquetes"

PACMAN_PKGS=(
    # Wayland / Hyprland core
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "qt5-wayland"
    "qt6-wayland"
    "polkit-kde-agent"

    # Hyprland ecosystem
    "hypridle"
    "hyprlock"
    "hyprpaper"

    # Display Manager
    "sddm"

    # Bar, launcher, notifs
    "waybar"
    "dunst"
    "libnotify"

    # Terminal y shell
    "alacritty"
    "zsh"
    "zsh-completions"

    # Audio (Pipewire stack completo)
    "pipewire"
    "pipewire-pulse"
    "pipewire-alsa"
    "pipewire-jack"
    "wireplumber"
    "pavucontrol"
    "pamixer"
    "playerctl"

    # Bluetooth
    "bluez"
    "bluez-utils"
    "blueman"

    # Red
    "networkmanager"
    "network-manager-applet"

    # CLI tools
    "fastfetch"
    "yazi"
    "btop"
    "cava"
    "eza"
    "bat"
    "fzf"
    "fd"
    "ripgrep"
    "jq"
    "p7zip"
    "rsync"
    "git"
    "curl"
    "wget"
    "unzip"
    "wl-clipboard"
    "wtype"
    "grim"
    "slurp"

    # Fuentes
    "noto-fonts"
    "noto-fonts-cjk"
    "noto-fonts-emoji"
    "ttf-font-awesome"
    "ttf-jetbrains-mono-nerd"
)

AUR_PKGS=(
    "rofi-wayland"
    "ttf-terminus-font"
    "hyprshot"
    "wlogout"
)

# Motor de instalación
install_pkgs() {
    local manager="$1"; shift
    local failed=()
    for pkg in "$@"; do
        if pacman -Qq "$pkg" &>/dev/null; then
            echo "  ${GREEN}[✓]${RESET} $pkg"
        else
            echo "  ${YELLOW}[→]${RESET} Instalando $pkg..."
            if ! $manager -S --noconfirm --needed "$pkg" &>/dev/null; then
                error "  Falló: $pkg"
                failed+=("$pkg")
            else
                success "  $pkg instalado."
            fi
        fi
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        warn "Paquetes que fallaron: ${failed[*]}"
    fi
}

info "Pacman packages..."
install_pkgs "sudo pacman" "${PACMAN_PKGS[@]}"

info "AUR packages..."
install_pkgs "yay" "${AUR_PKGS[@]}"

success "Paquetes instalados."

# ================================================================
#   STEP 4 — SERVICIOS DEL SISTEMA
# ================================================================
step "4/9 — Habilitando servicios"

services=(
    "sddm.service"
    "NetworkManager.service"
    "bluetooth.service"
)

for svc in "${services[@]}"; do
    if systemctl is-enabled "$svc" &>/dev/null; then
        success "$svc ya habilitado."
    else
        sudo systemctl enable "$svc" && success "$svc habilitado." || warn "No se pudo habilitar $svc"
    fi
done

# Pipewire se habilita a nivel de usuario
user_services=(
    "pipewire.service"
    "pipewire-pulse.service"
    "wireplumber.service"
)

for svc in "${user_services[@]}"; do
    if systemctl --user is-enabled "$svc" &>/dev/null; then
        success "$svc (user) ya habilitado."
    else
        systemctl --user enable "$svc" && success "$svc (user) habilitado." || warn "No se pudo habilitar $svc"
    fi
done

# Habilitar Bluetooth en el config
if [[ -f /etc/bluetooth/main.conf ]]; then
    sudo sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
    success "Bluetooth AutoEnable activado."
fi

# ================================================================
#   STEP 5 — DEPLOY DE DOTFILES
# ================================================================
step "5/9 — Desplegando configs ($PROFILE_LABEL)"

mkdir -p "$HOME/.config"

# Backup de la config existente si hay algo
if [[ -d "$HOME/.config" && "$(ls -A "$HOME/.config" 2>/dev/null)" ]]; then
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    warn "Haciendo backup de ~/.config/ en $BACKUP_DIR"
    cp -r "$HOME/.config" "$BACKUP_DIR"
fi

rsync -ah --delete --info=progress2 "configs/$PROFILE/" "$HOME/.config/"
success "Configs desplegados desde configs/$PROFILE/"

# Hacer ejecutables todos los scripts
find "$HOME/.config" -name "*.sh" -exec chmod +x {} +
success "Permisos de scripts aplicados."

# ================================================================
#   STEP 6 — CONFIGURACIÓN DE ZSH
# ================================================================
step "6/9 — Configurando Zsh"

# Cambiar shell a zsh
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Cambiando shell por defecto a zsh..."
    sudo chsh -s "$(which zsh)" "$USER" && success "Shell cambiado a zsh." || warn "No se pudo cambiar shell automáticamente. Corré: chsh -s \$(which zsh)"
else
    success "zsh ya es el shell por defecto."
fi

# Copiar archivos zsh al HOME
[[ -f ".zshrc" ]]   && cp .zshrc "$HOME/"   && success ".zshrc copiado."
[[ -f ".p10k.zsh" ]] && cp .p10k.zsh "$HOME/" && success ".p10k.zsh copiado."

# Instalar Zinit si no está
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    info "Instalando Zinit..."
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" && success "Zinit instalado."
else
    success "Zinit ya está instalado."
fi

# Pre-instalar plugins de Zinit (Powerlevel10k + plugins principales)
info "Pre-instalando plugins zsh (p10k, autosuggestions, syntax-highlighting)..."
ZINIT_PLUGINS_DIR="${HOME}/.local/share/zinit/plugins"

clone_plugin() {
    local url="$1"
    local dir="$2"
    if [[ ! -d "$dir" ]]; then
        git clone --depth=1 "$url" "$dir" &>/dev/null && success "Plugin: $(basename $dir)" || warn "Falló clonar: $url"
    else
        success "Plugin ya presente: $(basename $dir)"
    fi
}

mkdir -p "$ZINIT_PLUGINS_DIR"
clone_plugin "https://github.com/romkatv/powerlevel10k" "$ZINIT_PLUGINS_DIR/romkatv---powerlevel10k"
clone_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$ZINIT_PLUGINS_DIR/zsh-users---zsh-autosuggestions"
clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "$ZINIT_PLUGINS_DIR/zsh-users---zsh-syntax-highlighting"
clone_plugin "https://github.com/zsh-users/zsh-completions" "$ZINIT_PLUGINS_DIR/zsh-users---zsh-completions"

# ================================================================
#   STEP 7 — ASSETS (Wallpaper)
# ================================================================
step "7/9 — Wallpaper"

sudo mkdir -p /usr/share/backgrounds
if [[ -f "assets/wallpaper.jpg" ]]; then
    sudo cp "assets/wallpaper.jpg" /usr/share/backgrounds/oxh-wallpaper.jpg
    success "Wallpaper desplegado en /usr/share/backgrounds/oxh-wallpaper.jpg"
else
    warn "No se encontró assets/wallpaper.jpg"
fi

# ================================================================
#   STEP 8 — SDDM TEMA
# ================================================================
step "8/9 — SDDM Theme"

SDDM_THEME_DIR="/usr/share/sddm/themes/oxh-sddm"

if [[ -d "system/sddm-theme" ]]; then
    sudo mkdir -p "$SDDM_THEME_DIR"
    sudo cp -r system/sddm-theme/* "$SDDM_THEME_DIR/"
    success "Tema SDDM copiado."

    # Escribir config de SDDM para que use el tema
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<EOF
[Theme]
Current=oxh-sddm
EOF
    success "SDDM configurado para usar oxh-sddm."
else
    warn "No se encontró system/sddm-theme/"
fi

# ================================================================
#   STEP 9 — GTK / APARIENCIA
# ================================================================
step "9/9 — Apariencia GTK"

# Directorio de settings GTK
mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/gtk-4.0"

# Settings GTK básicos (ajustá a tu gusto)
cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-cursor-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
EOF

cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
success "Settings GTK dark mode aplicados."

# Variables de entorno Wayland / Hyprland (en /etc/environment)
info "Configurando variables de entorno Wayland..."
sudo tee /etc/environment > /dev/null <<EOF
# Wayland
WAYLAND_DISPLAY=wayland-1
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=qt5ct
GDK_BACKEND=wayland
SDL_VIDEODRIVER=wayland
CLUTTER_BACKEND=wayland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
XDG_CURRENT_DESKTOP=Hyprland

# AMD / Mesa (desde tu .zshrc)
RADV_PERFTEST=aco,ngg
AMD_VULKAN_ICD=RADV
mesa_glthread=true
MESA_GL_VERSION_OVERRIDE=4.6
EOF
success "Variables de entorno configuradas."

# ================================================================
#   RESUMEN FINAL
# ================================================================
kill $SUDO_PID 2>/dev/null

echo ""
echo "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${GREEN}${BOLD}  INSTALACIÓN COMPLETA — Perfil: $PROFILE_LABEL${RESET}"
echo "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "  Lo que se hizo:"
echo "   ${GREEN}✓${RESET} Sistema actualizado"
echo "   ${GREEN}✓${RESET} yay instalado"
echo "   ${GREEN}✓${RESET} Todos los paquetes instalados (incluido Hyprland, Pipewire, Bluetooth)"
echo "   ${GREEN}✓${RESET} Servicios habilitados (SDDM, NetworkManager, Bluetooth, Pipewire)"
echo "   ${GREEN}✓${RESET} Configs desplegados ($PROFILE_LABEL)"
echo "   ${GREEN}✓${RESET} Zsh configurado como shell por defecto"
echo "   ${GREEN}✓${RESET} Zinit y plugins zsh pre-instalados"
echo "   ${GREEN}✓${RESET} Wallpaper desplegado"
echo "   ${GREEN}✓${RESET} SDDM tema configurado"
echo "   ${GREEN}✓${RESET} GTK dark mode y variables Wayland"
echo ""
echo "  ${YELLOW}${BOLD}Próximos pasos:${RESET}"
echo "   → Reiniciá el sistema para aplicar todos los cambios"
echo "   → Al primer login en zsh, Zinit puede tardar unos segundos en terminar de configurarse"
echo "   → Si Bluetooth no conecta, corré: ${CYAN}bluetoothctl power on${RESET}"
echo ""
echo "${BLUE}${BOLD}  reboot? [y/N]:${RESET} " && read -r do_reboot
[[ "$do_reboot" =~ ^[Yy]$ ]] && sudo reboot
