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
## ✦ ART CREDITS!!! ^

>Wallpaper is a screenshot of [雨予報、君と / 足立レイ](https://www.youtube.com/watch?v=attdDLZGN_8&list=RDattdDLZGN_8&start_radio=1) by 現世欠落.

>Lockscreen wallpaper drawed by [@Geobook2_da](https://x.com/Geobook2_da/status/1993224758696329319/photo/1) on twt

## ✦ Preview
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b07d83a1-33ac-485b-b080-3a993ef084ea" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2be1b0a5-aa71-4998-a03b-2caa8440597d" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/9187f297-884c-41dd-b2b9-0ff9b33d2f0c" />

<img width="605" height="584" alt="image" src="https://github.com/user-attachments/assets/adee7398-b56f-4d25-a4d4-5fa40e229fcc" />

<img width="457" height="308" alt="image" src="https://github.com/user-attachments/assets/ce6ea9d0-09bb-473c-a137-e54cca8386a0" />



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

---

<div align="center">

by **occhi**

</div>
