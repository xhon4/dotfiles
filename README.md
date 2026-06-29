<div align="center">

```
   ██████╗  ██╗  ██╗  ██████╗ ██╗  ██╗ ██╗
   ██╔══██╗ ██║  ██║ ██╔════╝ ██║  ██║ ██║
   ██████╔╝ ███████║ ██║      ███████║ ██║
   ██╔══██╗ ╚════██║ ██║      ██╔══██║ ██║
   ██║  ██║      ██║ ╚██████╗ ██║  ██║ ██║
   ╚═╝  ╚═╝      ╚═╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝
```

**r4chi** · a Hyprland rice for Arch Linux

`Hyprland 0.55` · `Waybar` · `Rofi` · `Alacritty` · `Zsh + p10k` · `Yazi` · `SDDM`

</div>

---

## ✦ Preview

> _Add your screenshots here_ — `assets/preview.png`

---

## ✦ Stack

| Component | Program |
|---|---|
| Compositor | **Hyprland** (Lua config, 0.55+) |
| Bar | **Waybar** |
| Launcher | **Rofi** (custom `r4chi` theme) |
| Terminal | **Alacritty** |
| Shell | **Zsh** + **Powerlevel10k** (via zinit) |
| Files | **Yazi** |
| Login | **SDDM** (`r4chi-sddm` theme) |
| Wallpaper | **awww** |
| Notifications | **dunst** |

---

## ✦ Installation

```bash
git clone <this-repo> r4chi
cd r4chi
./install.sh
```

The installer is **idempotent** and copies everything to its final destination: **after installing you can delete the repo without breaking anything.**

### What `install.sh` does

1. `pacman -Syu` — updates the system
2. Installs **yay** (AUR helper)
3. Checks and installs missing packages from `packages.txt` (pacman + yay); detects **PipeWire vs PulseAudio**
4. Re-verifies all packages are installed
5. Copies configs → `~/.config`, `~/.zshrc`, SDDM theme, wallpapers (global, via sudo)
6. Verifies each file landed in the right place
7. `chmod +x` for rice scripts
8. Detects the **resolution**; if not 1920×1080, scales rofi and waybar
9. General check + `fc-cache`
10. Offers to restart

---

## ✦ Monitors

The default config applies a generic catch-all that works on any connected output:

```lua
hl.monitor({
    output   ="",           -- empty = all monitors
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
```

To pin a specific resolution per host, edit the `hl.monitor` block in `.config/hypr/hyprland.lua` with a real output name from `hyprctl monitors`:

```lua
hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "auto", scale = 1 })
```

---

## ✦ Palette

| Color | Hex |
|---|---|
| Background | `#0A0708` |
| Text | `#cbe2e6` |
| Accent | `#F5582D` / `#F6592E` |
| Blue | `#0D2E8F` / `#243083` |
| Tan | `#AA8C75` |

## ✦ Fonts

`Terminus` · `JetBrainsMono Nerd Font` · `Iosevka Nerd Font` · `Inconsolata` · `Departure Mono` · `Material Design Icons` · `Font Awesome`

---

## ✦ Keybinds (mod = `SUPER`)

| Key | Action |
|---|---|
| `mod + Return` | Alacritty |
| `mod + A` | Rofi (drun) |
| `mod + .` | Emoji picker |
| `mod + BackSpace` | Power menu |
| `mod + Q` | Close window |
| `mod + F` / `mod + Shift + M` | Fullscreen / Maximize |
| `mod + V` | Float + 800×600 |
| `mod + H/J/K/L` | Move focus |
| `mod + Shift + H/J/K/L` | Swap windows |
| `mod + I` | Toggle split |
| `mod + 1..9` | Go to workspace |
| `mod + Shift + 1..9` | Move window to workspace |
| `mod + Shift + S` | Screenshot (region) |
| `mod + Shift + R` | Reload Hyprland |
| `mod + D` | Toggle desktop |

---

## ✦ Structure

```
.config/
├── alacritty/      terminal
├── hypr/           hyprland.lua · gaming.lua · hypridle · scripts
├── rofi/           config + r4chi theme + scripts
├── waybar/         config + style + scripts
├── yazi/ btop/ fastfetch/
└── .zshrc
usr/share/
├── backgrounds/    wallpapers
└── sddm/           r4chi-sddm theme
install.sh · packages.txt
```

---

## ✦ Notes

- **No lockscreen**: locking goes through SDDM / `loginctl`, no Hyprlock used.
- **Powerlevel10k** auto-installs via zinit on first zsh launch (uses terminal colors).
- **awww** replaces swww (in Arch official repos).
- The **gaming** profile (VRR, tearing, rules) lives in `hypr/gaming.lua`; enable it with `require("gaming")` from `hyprland.lua`.

---

<div align="center">

by **occhi**

</div>
