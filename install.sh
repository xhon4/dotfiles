#!/usr/bin/env bash
# r4chi-dotfiles · by occhi
set -euo pipefail

# ==================================================================
#  PALETA
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
#  ARTE + UI
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
#  SANIDAD
# ==================================================================
if [[ $EUID -eq 0 ]]; then
    err "No ejecutes este script como root. Corrélo como tu usuario; pedira sudo cuando haga falta."
    exit 1
fi

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly DOTFILES_DIR
readonly PKG_FILE="$DOTFILES_DIR/packages.txt"
[[ -f "$PKG_FILE" ]] || { err "No se encontro packages.txt junto a install.sh."; exit 1; }

clear 2>/dev/null || true
banner
printf '\n %sRepo:%s    %s\n' "$MUTED" "$RESET" "$DOTFILES_DIR"
printf ' %sDestino:%s ~/.config · ~/.zshrc · /usr/share · /etc (sudo)\n' "$MUTED" "$RESET"
warn "Esto instalara paquetes y SOBREESCRIBIRA tus configs de Hyprland/Waybar/etc."
pause "ENTER para comenzar (Ctrl-C para abortar)..."

info "Solicitando sudo (para pacman y configs globales)..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &
readonly SUDO_PID=$!
trap 'kill "$SUDO_PID" 2>/dev/null || true' EXIT

# ==================================================================
#  1 · ACTUALIZAR EL SISTEMA
# ==================================================================
step 1 "Actualizando el sistema (pacman -Syu)"
sudo pacman -Syu --noconfirm
ok "Sistema al dia."

# ==================================================================
#  2 · YAY (AUR helper)
# ==================================================================
step 2 "AUR helper (yay)"
if command -v yay &>/dev/null; then
    ok "yay ya esta instalado."
else
    info "Compilando yay desde AUR..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmp="$(mktemp -d)"
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
    ( cd "$tmp/yay" && makepkg -si --noconfirm )
    rm -rf "$tmp"
    ok "yay instalado."
fi

# ==================================================================
#  3 · VERIFICAR E INSTALAR PAQUETES + FUENTES
# ==================================================================
step 3 "Paquetes y fuentes (verificar lo que falta e instalar)"

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

info "Faltan: ${#pending_official[@]} oficiales, ${#pending_aur[@]} de AUR."
if (( ${#pending_official[@]} + ${#pending_aur[@]} > 0 )); then
    pause "ENTER para instalar lo que falta..."
    (( ${#pending_official[@]} > 0 )) && sudo pacman -S --needed --noconfirm "${pending_official[@]}"
    (( ${#pending_aur[@]} > 0 ))      && yay -S --needed --noconfirm "${pending_aur[@]}"
    ok "Instalacion de paquetes completada."
else
    ok "Ya tenias todos los paquetes."
fi

info "Detectando backend de audio..."
audio_backend="desconocido"
if   pactl info 2>/dev/null | grep -qi 'PipeWire';   then audio_backend="pipewire"
elif pactl info 2>/dev/null | grep -qi 'PulseAudio'; then audio_backend="pulseaudio"
elif pacman -Qq pipewire &>/dev/null;                then audio_backend="pipewire"
elif pacman -Qq pulseaudio &>/dev/null;              then audio_backend="pulseaudio"
fi
case "$audio_backend" in
    pulseaudio)
        info "PulseAudio detectado."
        sudo pacman -S --needed --noconfirm pulseaudio pulseaudio-alsa ;;
    *)
        if [[ "$audio_backend" == "desconocido" ]]; then
            audio_backend="pipewire"; warn "Sin backend claro -> uso PipeWire (default Arch)."
        else
            info "PipeWire detectado."
        fi
        sudo pacman -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber ;;
esac
ok "Audio (${audio_backend}) listo."

# ==================================================================
#  4 · RE-VERIFICAR INSTALACION
# ==================================================================
step 4 "Verificando que todo quedo instalado"
want=( "${official_pkgs[@]}" "${aur_pkgs[@]}" )
attempt=1
while :; do
    missing=()
    for p in "${want[@]}"; do pacman -Qq "$p" &>/dev/null || missing+=("$p"); done
    if (( ${#missing[@]} == 0 )); then
        ok "Todos los paquetes presentes — bucle cerrado."
        break
    fi
    warn "Faltan (${#missing[@]}): ${missing[*]}"
    if (( attempt >= 2 )); then
        warn "Persisten faltantes tras reintentar. Revisalos a mano."
        break
    fi
    info "Reintento ${attempt}/1..."
    for p in "${missing[@]}"; do
        if printf '%s\n' "${aur_pkgs[@]}" | grep -qx "$p"; then yay -S --needed --noconfirm "$p" || true
        else sudo pacman -S --needed --noconfirm "$p" || true; fi
    done
    attempt=$(( attempt + 1 ))
done

# ==================================================================
#  5 · MOVER ARCHIVOS A SU POSICION
# ==================================================================
step 5 "Copiando archivos a su lugar"
mkdir -p "$HOME/.config"

if [[ -d "$HOME/.config" ]]; then
    backup="$HOME/.config-r4chi-backup-$(date +%Y%m%d-%H%M%S)"
    cp -r "$HOME/.config" "$backup" 2>/dev/null || true
    [[ -f "$HOME/.zshrc" ]] && cp -f "$HOME/.zshrc" "$backup/.zshrc.bak" 2>/dev/null || true
    ok "Backup de seguridad: $backup"
fi

user_configs=(alacritty btop fastfetch hypr rofi waybar yazi)
for cfg in "${user_configs[@]}"; do
    if [[ -d "$DOTFILES_DIR/.config/$cfg" ]]; then
        rm -rf "${HOME:?}/.config/$cfg"
        cp -r "$DOTFILES_DIR/.config/$cfg" "$HOME/.config/$cfg"
        ok ".config/$cfg"
    fi
done
[[ -f "$DOTFILES_DIR/.config/.zshrc" ]] && { cp -f "$DOTFILES_DIR/.config/.zshrc" "$HOME/.zshrc"; ok ".zshrc"; }
[[ -f "$DOTFILES_DIR/usr/share/sddm/faces/.face.icon" ]] && cp -f "$DOTFILES_DIR/usr/share/sddm/faces/.face.icon" "$HOME/.face.icon"
mkdir -p "$HOME/Pictures/Screenshots"

info "Configuraciones globales (sudo)..."
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
    ok "Tema SDDM r4chi-sddm instalado y activado."
fi
if [[ -f "$DOTFILES_DIR/usr/share/zsh/site-functions/_awww" ]]; then
    sudo install -Dm644 "$DOTFILES_DIR/usr/share/zsh/site-functions/_awww" /usr/share/zsh/site-functions/_awww
    ok "Completion zsh de awww."
fi
systemctl list-unit-files sddm.service &>/dev/null && { sudo systemctl enable sddm.service >/dev/null 2>&1; ok "SDDM habilitado."; }

zsh_path="$(command -v zsh || true)"
if [[ -n "$zsh_path" && "${SHELL:-}" != "$zsh_path" ]]; then
    if chsh -s "$zsh_path"; then ok "Shell por defecto -> zsh"; else warn "Cambia la shell a mano: chsh -s $zsh_path"; fi
fi

rpc="$HOME/.config/hypr/scripts"
if [[ -f "$rpc/audacious_discord.py" ]]; then
    python -m venv "$rpc/audacious-rpc-env" &
    spin $! "Creando venv de Audacious RPC..."
    "$rpc/audacious-rpc-env/bin/pip" install --quiet --upgrade pip pypresence &
    spin $! "Instalando pypresence..."
fi

# ==================================================================
#  6 · VERIFICAR UBICACION DE LOS ARCHIVOS
# ==================================================================
step 6 "Verificando ubicacion de los archivos"
check() { if [[ -e "$1" ]]; then ok "$2"; else err "FALTA: $2 ($1)"; FILE_ERR=1; fi; }
FILE_ERR=0
check "$HOME/.config/hypr/hyprland.lua"            "Hyprland (Lua)"
check "$HOME/.config/waybar/config.jsonc"          "Waybar config"
check "$HOME/.config/rofi/themes/r4chi.rasi"       "Rofi tema r4chi"
check "$HOME/.config/alacritty/alacritty.toml"     "Alacritty"
check "$HOME/.config/yazi/theme.toml"              "Yazi"
check "$HOME/.zshrc"                                "Zsh rc"
check "/usr/share/backgrounds/reiwal.png"          "Wallpaper"
check "/usr/share/sddm/themes/r4chi-sddm/Main.qml" "Tema SDDM"
check "/etc/sddm.conf.d/10-theme.conf"             "SDDM activado"
if (( FILE_ERR == 0 )); then ok "Todos los archivos en su lugar."; else warn "Algun archivo falto (ver arriba)."; fi

# ==================================================================
#  7 · PERMISOS chmod +x
# ==================================================================
step 7 "Permisos de ejecucion a los scripts"
n=0
while IFS= read -r -d '' f; do chmod +x "$f"; n=$(( n + 1 )); done \
    < <(find "$HOME/.config/hypr" "$HOME/.config/rofi" "$HOME/.config/waybar" -type f \( -name '*.sh' -o -name '*.py' \) -print0 2>/dev/null)
ok "chmod +x aplicado a $n scripts."

# ==================================================================
#  8 · RESOLUCION Y ESCALADO
# ==================================================================
step 8 "Resolucion de pantalla y escalado"
res=""
if command -v hyprctl &>/dev/null && hyprctl monitors -j &>/dev/null; then
    res="$(hyprctl monitors -j 2>/dev/null | grep -oE '"width": [0-9]+|"height": [0-9]+' | grep -oE '[0-9]+' | paste -sd x - | cut -d x -f1-2)"
fi
[[ -z "$res" ]] && res="$(cat /sys/class/drm/*/modes 2>/dev/null | head -n1)"
res_w="${res%x*}"; res_w="${res_w//[!0-9]/}"
res_h="${res#*x}"; res_h="${res_h//[!0-9]/}"

if [[ -z "$res_w" ]]; then
    warn "No pude detectar la resolucion; dejo escalado por defecto (1080p)."
else
    info "Resolucion detectada: ${res_w}x${res_h}"
    factor=""
    if   (( res_w == 1920 )); then factor=""
    elif (( res_w >= 3840 )); then factor="1.5"
    elif (( res_w >= 2560 )); then factor="1.25"
    elif (( res_w <= 1600 )); then factor="0.85"
    else factor=""; fi

    if [[ -z "$factor" ]]; then
        ok "Resolucion estandar (1920x1080) o cercana — sin escalado."
    else
        info "Aplicando escalado x${factor} a rofi y waybar..."
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
        ok "Rofi y waybar escalados (font/height x${factor})."
    fi
fi

# ==================================================================
#  9 · CHEQUEO GENERAL
# ==================================================================
step 9 "Chequeo general"
GEN_OK=1
need() {
    if command -v "$1" &>/dev/null; then
        ok "$2 presente"
    else
        if [[ "${3:-}" == "warn" ]]; then warn "$2 ausente"; else err "$2 ausente"; fi
        GEN_OK=0
    fi
}
need hyprland "hyprland"
need waybar   "waybar"
need awww     "awww" warn
need sddm     "sddm"
if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then ok "config Hyprland en su lugar"; else err "falta hyprland.lua"; GEN_OK=0; fi
fc-cache -f >/dev/null 2>&1 || true
ok "Cache de fuentes regenerada."
if (( GEN_OK == 1 )); then ok "Chequeo general: TODO OK."; else warn "Chequeo general con observaciones (ver arriba)."; fi

# ==================================================================
#  10 · FIN
# ==================================================================
printf '\n'; rule
printf ' %s%s  ✓  INSTALACION r4chi COMPLETA  %s\n' "$BOLD" "$GREEN" "$RESET"
rule
printf '   %s•%s Todo fue copiado: ya podes borrar este repo.\n' "$ACCENT" "$RESET"
printf '   %s•%s p10k se autoinstala con zinit al abrir zsh por primera vez.\n' "$ACCENT" "$RESET"
printf '   %s•%s Backend de audio: %s%s%s\n' "$ACCENT" "$RESET" "$TEXT" "$audio_backend" "$RESET"

if ask_yn "Reiniciar ahora para entrar por SDDM a Hyprland?"; then
    info "Reiniciando..."
    sleep 1
    sudo systemctl reboot
else
    ok "Listo. Reinicia cuando quieras: 'sudo systemctl reboot'."
fi
