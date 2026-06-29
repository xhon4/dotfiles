#!/usr/bin/env bash
# r4chi-dotfiles · by occhi
set -euo pipefail

# ==================================================================
#  PALETTE
# ==================================================================
readonly RESET=$'\e[0m'
readonly BOLD=$'\e[1m'
readonly ACCENT=$'\e[38;2;245;88;45m'
readonly ACCENT2=$'\e[38;2;246;89;46m'
readonly TEXT=$'\e[38;2;203;226;230m'
readonly MUTED=$'\e[38;2;170;140;117m'
readonly BLUE=$'\e[38;2;78;108;146m'
readonly DIM=$'\e[38;2;142;158;161m'
readonly GREEN=$'\e[38;2;170;200;150m'

# ==================================================================
#  ART + UI
# ==================================================================
banner() {
    printf '%s' "$ACCENT"
    cat <<'ART'

   ██████╗  ██╗  ██╗  ██████╗ ██╗  ██╗ ██╗
   ██╔══██╗ ██║  ██║ ██╔════╝ ██║  ██║ ██║
   ██████╔╝ ███████║ ██║      ███████║ ██║
   ██╔══██╗ ╚════██║ ██║      ██╔══██║ ██║
   ██║  ██║      ██║ ╚██████╗ ██║  ██║ ██║
   ╚═╝  ╚═╝      ╚═╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝
ART
    printf '%s' "$RESET"
    printf '%s        h y p r l a n d   r i c i n g   ·   by occhi%s\n' "$DIM" "$RESET"
}

rule() {
    printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$MUTED" "$RESET"
}

readonly STEP_TOTAL=10
STEP_CUR=0

progress_bar() {
    local cur=$1 total=$2 width=34
    local filled=$(( cur * width / total ))
    local empty=$(( width - filled ))
    local bar="" i
    for (( i = 0; i < filled; i++ )); do bar+="█"; done
    for (( i = 0; i < empty;  i++ )); do bar+="░"; done
    printf '   %s%s%s %s%d%%%s\n' "$ACCENT" "$bar" "$RESET" "$MUTED" $(( cur * 100 / total )) "$RESET"
}

step() {
    STEP_CUR=$1; shift
    printf '\n'
    rule
    printf ' %s%s[%02d/%02d]%s %s%s%s\n' "$BOLD" "$ACCENT" "$STEP_CUR" "$STEP_TOTAL" "$RESET" "$TEXT$BOLD" "$*" "$RESET"
    progress_bar "$STEP_CUR" "$STEP_TOTAL"
}

info() { printf '   %s›%s %s\n'  "$BLUE"   "$RESET" "$*"; }
ok()   { printf '   %s✓%s %s\n'  "$GREEN"  "$RESET" "$*"; }
warn() { printf '   %s▲%s %s\n'  "$ACCENT" "$RESET" "$*"; }
err()  { printf '   %s✗ %s%s\n'  "$ACCENT2" "$*" "$RESET" >&2; }

pause() { printf '\n %s↵ %s %s' "$MUTED" "$*" "$RESET"; read -r _; }

ask_yn() {
    local reply
    printf '\n %s?%s %s %s[y/N]%s ' "$ACCENT" "$RESET" "$1" "$DIM" "$RESET"
    read -r reply
    [[ "$reply" =~ ^[YySs]$ ]]
}

spin() {
    local pid=$1 msg=$2
    local frames='⣾⣽⣻⢿⡿⣟⣯⣷' i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 8 ))
        printf '\r   %s%s%s %s' "$ACCENT" "${frames:$i:1}" "$RESET" "$msg"
        sleep 0.1
    done
    printf '\r   %s✓%s %s\n' "$GREEN" "$RESET" "$msg"
}

# ==================================================================
#  SANITY
# ==================================================================
if [[ $EUID -eq 0 ]]; then
    err "Do not run this script as root. Run it as your user; it will ask for sudo when needed."
    exit 1
fi

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly DOTFILES_DIR
readonly PKG_FILE="$DOTFILES_DIR/packages.txt"
[[ -f "$PKG_FILE" ]] || { err "packages.txt not found next to install.sh."; exit 1; }

clear 2>/dev/null || true
banner
printf '\n %sRepo:%s    %s\n' "$MUTED" "$RESET" "$DOTFILES_DIR"
printf ' %sTarget:%s ~/.config · ~/.zshrc · /usr/share · /etc (sudo)\n' "$MUTED" "$RESET"
warn "This will install packages and OVERWRITE your Hyprland/Waybar/etc. configs."
pause "ENTER to start (Ctrl-C to abort)..."

info "Requesting sudo (for pacman and global configs)..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &
readonly SUDO_PID=$!
trap 'kill "$SUDO_PID" 2>/dev/null || true' EXIT

# ==================================================================
#  1 · UPDATE THE SYSTEM
# ==================================================================
step 1 "Updating the system (pacman -Syu)"
sudo pacman -Syu --noconfirm
ok "System up to date."

# ==================================================================
#  2 · YAY (AUR helper)
# ==================================================================
step 2 "AUR helper (yay)"
if command -v yay &>/dev/null; then
    ok "yay already installed."
else
    info "Building yay from AUR..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmp="$(mktemp -d)"
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
    ( cd "$tmp/yay" && makepkg -si --noconfirm )
    rm -rf "$tmp"
    ok "yay installed."
fi

# ==================================================================
#  3 · VERIFY & INSTALL PACKAGES + FONTS
# ==================================================================
step 3 "Packages and fonts (check missing and install)"

official_pkgs=(); aur_pkgs=(); target="official"
while IFS= read -r raw; do
    if [[ "$(printf '%s' "$raw" | xargs)" == "### AUR ###" ]]; then target="aur"; continue; fi
    line="${raw%%#*}"; line="$(printf '%s' "$line" | xargs)"
    [[ -z "$line" ]] && continue
    if [[ "$target" == "official" ]]; then official_pkgs+=("$line"); else aur_pkgs+=("$line"); fi
done < "$PKG_FILE"

pending_official=(); pending_aur=()
for p in "${official_pkgs[@]}"; do
    if pacman -Qq "$p" &>/dev/null; then printf '   %s✓%s %s\n' "$GREEN" "$RESET" "$p"
    else printf '   %s+%s %s %s(pacman)%s\n' "$ACCENT" "$RESET" "$p" "$DIM" "$RESET"; pending_official+=("$p"); fi
done
for p in "${aur_pkgs[@]}"; do
    if pacman -Qq "$p" &>/dev/null; then printf '   %s✓%s %s\n' "$GREEN" "$RESET" "$p"
    else printf '   %s+%s %s %s(yay/AUR)%s\n' "$ACCENT2" "$RESET" "$p" "$DIM" "$RESET"; pending_aur+=("$p"); fi
done

info "Missing: ${#pending_official[@]} official, ${#pending_aur[@]} from AUR."
if (( ${#pending_official[@]} + ${#pending_aur[@]} > 0 )); then
    pause "ENTER to install missing packages..."
    (( ${#pending_official[@]} > 0 )) && sudo pacman -S --needed --noconfirm "${pending_official[@]}"
    (( ${#pending_aur[@]} > 0 ))      && yay -S --needed --noconfirm "${pending_aur[@]}"
    ok "Package installation complete."
else
    ok "All packages already installed."
fi

info "Detecting audio backend..."
audio_backend="unknown"
if   pactl info 2>/dev/null | grep -qi 'PipeWire';   then audio_backend="pipewire"
elif pactl info 2>/dev/null | grep -qi 'PulseAudio'; then audio_backend="pulseaudio"
elif pacman -Qq pipewire &>/dev/null;                then audio_backend="pipewire"
elif pacman -Qq pulseaudio &>/dev/null;              then audio_backend="pulseaudio"
fi
case "$audio_backend" in
    pulseaudio)
        info "PulseAudio detected."
        sudo pacman -S --needed --noconfirm pulseaudio pulseaudio-alsa ;;
    *)
        if [[ "$audio_backend" == "unknown" ]]; then
            audio_backend="pipewire"; warn "No clear audio backend -> defaulting to PipeWire (Arch default)."
        else
            info "PipeWire detected."
        fi
        sudo pacman -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber ;;
esac
ok "Audio (${audio_backend}) ready."

# ==================================================================
#  4 · RE-VERIFY INSTALL
# ==================================================================
step 4 "Verifying all packages are installed"
want=( "${official_pkgs[@]}" "${aur_pkgs[@]}" )
attempt=1
while :; do
    missing=()
    for p in "${want[@]}"; do pacman -Qq "$p" &>/dev/null || missing+=("$p"); done
    if (( ${#missing[@]} == 0 )); then
        ok "All packages present — loop closed."
        break
    fi
    warn "Missing (${#missing[@]}): ${missing[*]}"
    if (( attempt >= 2 )); then
        warn "Packages still missing after retry. Check manually."
        break
    fi
    info "Retry ${attempt}/1..."
    for p in "${missing[@]}"; do
        if printf '%s\n' "${aur_pkgs[@]}" | grep -qx "$p"; then yay -S --needed --noconfirm "$p" || true
        else sudo pacman -S --needed --noconfirm "$p" || true; fi
    done
    attempt=$(( attempt + 1 ))
done

# ==================================================================
#  5 · MOVE FILES INTO PLACE
# ==================================================================
step 5 "Copying files to their destination"
mkdir -p "$HOME/.config"

if [[ -d "$HOME/.config" ]]; then
    backup="$HOME/.config-r4chi-backup-$(date +%Y%m%d-%H%M%S)"
    cp -r "$HOME/.config" "$backup" 2>/dev/null || true
    [[ -f "$HOME/.zshrc" ]] && cp -f "$HOME/.zshrc" "$backup/.zshrc.bak" 2>/dev/null || true
    ok "Safety backup: $backup"
fi

user_configs=(alacritty btop dunst fastfetch hypr rofi waybar yazi)
for cfg in "${user_configs[@]}"; do
    if [[ -d "$DOTFILES_DIR/.config/$cfg" ]]; then
        rm -rf "${HOME:?}/.config/$cfg"
        cp -r "$DOTFILES_DIR/.config/$cfg" "$HOME/.config/$cfg"
        ok ".config/$cfg"
    fi
done
[[ -f "$DOTFILES_DIR/.config/.zshrc" ]] && { cp -f "$DOTFILES_DIR/.config/.zshrc" "$HOME/.zshrc"; ok ".zshrc"; }
face_src="$DOTFILES_DIR/usr/share/sddm/faces/root.face.icon"
if [[ -f "$face_src" ]]; then
    cp -f "$face_src" "$HOME/.face.icon"
    ok "Avatar -> ~/.face.icon"
else
    warn "Avatar source not found ($face_src); skipping."
fi
mkdir -p "$HOME/Pictures/Screenshots"

info "Global configs (sudo)..."
if [[ -d "$DOTFILES_DIR/usr/share/backgrounds" ]]; then
    sudo install -d /usr/share/backgrounds
    sudo cp -f "$DOTFILES_DIR/usr/share/backgrounds/"* /usr/share/backgrounds/
    ok "Wallpapers -> /usr/share/backgrounds/"
fi
if [[ -d "$DOTFILES_DIR/usr/share/sddm/themes/r4chi-sddm" ]]; then
    sudo rm -rf /usr/share/sddm/themes/r4chi-sddm
    sudo cp -r "$DOTFILES_DIR/usr/share/sddm/themes/r4chi-sddm" /usr/share/sddm/themes/
    sudo install -d /etc/sddm.conf.d
    printf '[Theme]\nCurrent=r4chi-sddm\n' | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
    ok "SDDM theme r4chi-sddm installed and activated."
fi
if [[ -f "$DOTFILES_DIR/usr/share/zsh/site-functions/_awww" ]]; then
    sudo install -Dm644 "$DOTFILES_DIR/usr/share/zsh/site-functions/_awww" /usr/share/zsh/site-functions/_awww
    ok "awww zsh completion."
fi
systemctl list-unit-files sddm.service &>/dev/null && { sudo systemctl enable sddm.service >/dev/null 2>&1; ok "SDDM enabled."; }

zsh_path="$(command -v zsh || true)"
if [[ -n "$zsh_path" && "${SHELL:-}" != "$zsh_path" ]]; then
    if chsh -s "$zsh_path"; then ok "Default shell -> zsh"; else warn "Change shell manually: chsh -s $zsh_path"; fi
fi

rpc="$HOME/.config/hypr/scripts"
if [[ -f "$rpc/audacious_discord.py" ]]; then
    python -m venv "$rpc/audacious-rpc-env" &
    spin $! "Creating Audacious RPC venv..."
    "$rpc/audacious-rpc-env/bin/pip" install --quiet --upgrade pip pypresence &
    spin $! "Installing pypresence..."
fi

# ==================================================================
#  6 · VERIFY FILE LOCATIONS
# ==================================================================
step 6 "Verifying file locations"
check() { if [[ -e "$1" ]]; then ok "$2"; else err "MISSING: $2 ($1)"; FILE_ERR=1; fi; }
FILE_ERR=0
check "$HOME/.config/hypr/hyprland.lua"            "Hyprland (Lua)"
check "$HOME/.config/waybar/config.jsonc"          "Waybar config"
check "$HOME/.config/rofi/themes/r4chi.rasi"       "Rofi r4chi theme"
check "$HOME/.config/alacritty/alacritty.toml"     "Alacritty"
check "$HOME/.config/yazi/theme.toml"              "Yazi"
check "$HOME/.zshrc"                                "Zsh rc"
check "/usr/share/backgrounds/reiwal.png"          "Wallpaper"
check "/usr/share/sddm/themes/r4chi-sddm/Main.qml" "SDDM theme"
check "/etc/sddm.conf.d/10-theme.conf"             "SDDM activated"
check "$HOME/.config/dunst/dunstrc"                "Dunst config"
if (( FILE_ERR == 0 )); then ok "All files in place."; else warn "Some file is missing (see above)."; fi

# ==================================================================
#  7 · EXECUTE PERMISSIONS
# ==================================================================
step 7 "Execution permissions for scripts"
n=0
while IFS= read -r -d '' f; do chmod +x "$f"; n=$(( n + 1 )); done \
    < <(find "$HOME/.config/hypr" "$HOME/.config/rofi" "$HOME/.config/waybar" -type f \( -name '*.sh' -o -name '*.py' \) -print0 2>/dev/null)
ok "chmod +x applied to $n scripts."

# ==================================================================
#  8 · RESOLUTION & SCALING
# ==================================================================
step 8 "Screen resolution and scaling"
res=""
if command -v hyprctl &>/dev/null && hyprctl monitors -j &>/dev/null; then
    res="$(hyprctl monitors -j 2>/dev/null | grep -oE '"width": [0-9]+|"height": [0-9]+' | grep -oE '[0-9]+' | paste -sd x - | cut -d x -f1-2)"
fi
[[ -z "$res" ]] && res="$(cat /sys/class/drm/*/modes 2>/dev/null | head -n1)"
res_w="${res%x*}"; res_w="${res_w//[!0-9]/}"
res_h="${res#*x}"; res_h="${res_h//[!0-9]/}"

if [[ -z "$res_w" ]]; then
    warn "Could not detect resolution; leaving default scaling (1080p)."
else
    info "Detected resolution: ${res_w}x${res_h}"
    factor=""
    if   (( res_w == 1920 )); then factor=""
    elif (( res_w >= 3840 )); then factor="1.5"
    elif (( res_w >= 2560 )); then factor="1.25"
    elif (( res_w <= 1600 )); then factor="0.85"
    else factor=""; fi

    if [[ -z "$factor" ]]; then
        ok "Standard resolution (1920x1080) or close — no scaling."
    else
        info "Applying x${factor} scaling to rofi and waybar..."
        wstyle="$HOME/.config/waybar/style.css"; wcfg="$HOME/.config/waybar/config.jsonc"
        [[ -f "$wstyle" ]] && awk -v f="$factor" '{
            if ($0 ~ /font-size:[ \t]*[0-9]+px/ && match($0,/[0-9]+px/)) {
                n=substr($0,RSTART,RLENGTH-2)+0
                $0=substr($0,1,RSTART-1) int(n*f+0.5) "px" substr($0,RSTART+RLENGTH)
            } print
        }' "$wstyle" > "$wstyle.tmp" && mv "$wstyle.tmp" "$wstyle"
        [[ -f "$wcfg" ]] && awk -v f="$factor" '{
            if ($0 ~ /"height"[ \t]*:[ \t]*[0-9]+/ && match($0,/[0-9]+/)) {
                n=substr($0,RSTART,RLENGTH)+0
                $0=substr($0,1,RSTART-1) int(n*f+0.5) substr($0,RSTART+RLENGTH)
            } print
        }' "$wcfg" > "$wcfg.tmp" && mv "$wcfg.tmp" "$wcfg"

        for rf in "$HOME/.config/rofi/config.rasi" "$HOME/.config/rofi/themes/r4chi.rasi"; do
            [[ -f "$rf" ]] && awk -v f="$factor" '{
                if ($0 ~ /font:/) {
                    out=""; rest=$0
                    while (match(rest, /[0-9]+[,"]/)) {
                        pre=substr(rest,1,RSTART-1); tok=substr(rest,RSTART,RLENGTH)
                        d=substr(tok,length(tok),1); num=substr(tok,1,length(tok)-1)+0
                        out=out pre int(num*f+0.5) d; rest=substr(rest,RSTART+RLENGTH)
                    }
                    $0=out rest
                } print
            }' "$rf" > "$rf.tmp" && mv "$rf.tmp" "$rf"
        done
        ok "Rofi and waybar scaled (font/height x${factor})."
    fi
fi

# ==================================================================
#  9 · GENERAL CHECK
# ==================================================================
step 9 "General check"
GEN_OK=1
need() {
    if command -v "$1" &>/dev/null; then
        ok "$2 present"
    else
        if [[ "${3:-}" == "warn" ]]; then warn "$2 not found"; else err "$2 not found"; fi
        GEN_OK=0
    fi
}
need hyprland "hyprland"
need waybar   "waybar"
need awww     "awww" warn
need sddm     "sddm"
if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then ok "Hyprland config in place"; else err "hyprland.lua not found"; GEN_OK=0; fi
fc-cache -f >/dev/null 2>&1 || true
ok "Font cache rebuilt."
if (( GEN_OK == 1 )); then ok "General check: ALL OK."; else warn "General check with warnings (see above)."; fi

# ==================================================================
#  10 · DONE
# ==================================================================
printf '\n'; rule
printf ' %s%s  ✓  r4chi INSTALL COMPLETE  %s\n' "$BOLD" "$GREEN" "$RESET"
rule
printf '   %s•%s Everything copied: you can safely delete this repo.\n' "$ACCENT" "$RESET"
printf '   %s•%s p10k auto-installs via zinit on first zsh launch.\n' "$ACCENT" "$RESET"
printf '   %s•%s Audio backend: %s%s%s\n' "$ACCENT" "$RESET" "$TEXT" "$audio_backend" "$RESET"

if ask_yn "Restart now to boot into SDDM/Hyprland?"; then
    info "Restarting..."
    sleep 1
    sudo systemctl reboot
else
    ok "Done. Restart whenever you are ready: 'sudo systemctl reboot'."
fi
