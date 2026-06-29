<div align="center">

```
   ██████╗  ██╗  ██╗  ██████╗ ██╗  ██╗ ██╗
   ██╔══██╗ ██║  ██║ ██╔════╝ ██║  ██║ ██║
   ██████╔╝ ███████║ ██║      ███████║ ██║
   ██╔══██╗ ╚════██║ ██║      ██╔══██║ ██║
   ██║  ██║      ██║ ╚██████╗ ██║  ██║ ██║
   ╚═╝  ╚═╝      ╚═╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝
```

**r4chi** · un ricing de Hyprland para Arch Linux

`Hyprland 0.55` · `Waybar` · `Rofi` · `Alacritty` · `Zsh + p10k` · `Yazi` · `SDDM`

</div>

---

## ✦ Vista previa

> _Agregá tus screenshots acá_ — `assets/preview.png`

---

## ✦ Stack

| Pieza | Programa |
|---|---|
| Compositor | **Hyprland** (config en Lua, 0.55+) |
| Barra | **Waybar** |
| Lanzador | **Rofi** (tema `r4chi` propio) |
| Terminal | **Alacritty** |
| Shell | **Zsh** + **Powerlevel10k** (vía zinit) |
| Archivos | **Yazi** |
| Login | **SDDM** (tema `r4chi-sddm`) |
| Wallpaper | **awww** |
| Notificaciones | **dunst** |

---

## ✦ Instalación

```bash
git clone <este-repo> r4chi
cd r4chi
./install.sh
```

El instalador es **idempotente** y copia todo a su destino final: **tras instalar podés borrar el repo sin romper nada.**

### Qué hace `install.sh`

1. `pacman -Syu` — actualiza el sistema
2. Instala **yay** (AUR helper)
3. Verifica e instala lo que falte de `packages.txt` (pacman + yay) y detecta **PipeWire vs PulseAudio**
4. Re-verifica que todo quedó instalado
5. Copia configs → `~/.config`, `~/.zshrc`, tema SDDM, wallpapers (global, con sudo)
6. Verifica que cada archivo quedó en su lugar
7. `chmod +x` a los scripts del ricing
8. Detecta la **resolución**; si no es 1920×1080 escala rofi y waybar
9. Chequeo general + `fc-cache`
10. Ofrece reiniciar

---

## ✦ Paleta

| Color | Hex |
|---|---|
| Fondo | `#0A0708` |
| Texto | `#cbe2e6` |
| Acento | `#F5582D` / `#F6592E` |
| Azul | `#0D2E8F` / `#243083` |
| Tan | `#AA8C75` |

## ✦ Fuentes

`Terminus` · `JetBrainsMono Nerd Font` · `Iosevka Nerd Font` · `Inconsolata` · `Departure Mono` · `Material Design Icons` · `Font Awesome`

---

## ✦ Keybinds (mod = `SUPER`)

| Tecla | Acción |
|---|---|
| `mod + Return` | Alacritty |
| `mod + A` | Rofi (drun) |
| `mod + .` | Selector de emotes |
| `mod + BackSpace` | Power menu |
| `mod + Q` | Cerrar ventana |
| `mod + F` / `mod + Shift + M` | Fullscreen / Maximizar |
| `mod + V` | Flotar + 800×600 |
| `mod + H/J/K/L` | Mover foco |
| `mod + Shift + H/J/K/L` | Intercambiar ventanas |
| `mod + I` | Toggle split |
| `mod + 1..9` | Ir a workspace |
| `mod + Shift + 1..9` | Mover ventana a workspace |
| `mod + Shift + S` | Screenshot (región) |
| `mod + Shift + R` | Recargar Hyprland |
| `mod + D` | Toggle escritorio |

---

## ✦ Estructura

```
.config/
├── alacritty/      terminal
├── hypr/           hyprland.lua · gaming.lua · hypridle · scripts
├── rofi/           config + tema r4chi + scripts
├── waybar/         config + style + scripts
├── yazi/ btop/ fastfetch/
└── .zshrc
usr/share/
├── backgrounds/    wallpapers
└── sddm/           tema r4chi-sddm
install.sh · packages.txt
```

---

## ✦ Notas

- **Sin lockscreen propio**: el bloqueo va por SDDM / `loginctl`, no se usa Hyprlock.
- **Powerlevel10k** se autoinstala con zinit al abrir zsh por primera vez (usa los colores de la terminal).
- **awww** reemplaza a swww (en repos oficiales de Arch).
- El perfil de **gaming** (VRR, tearing, reglas) está en `hypr/gaming.lua`; activalo con `require("gaming")` desde `hyprland.lua`.

---

<div align="center">

by **occhi**

</div>
