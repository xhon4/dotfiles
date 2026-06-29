-- r4chi-dotfiles · by occhi

------------------------------------------------------------
-- MONITOR
------------------------------------------------------------
hl.monitor({
    output   = "HDMI-A-2",
    mode     = "1920x1080@75",
    position = "auto",
    scale    = 1,
})

------------------------------------------------------------
-- AUTOSTART
------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("dunst")
    hl.exec_cmd("waybar")
    hl.exec_cmd("~/.config/hypr/scripts/waybar-fullscreen.sh")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && awww img /usr/share/backgrounds/reiwal.png")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("~/.config/hypr/scripts/gcal-sync.sh")
end)

------------------------------------------------------------
-- OPCIONES
------------------------------------------------------------
hl.config({
    input = {
        follow_mouse = 1,
        sensitivity  = 0,
        kb_layout    = "latam",
    },

    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 1,
        col = {
            inactive_border = "rgba(3d3d3dff)",
            active_border   = "rgba(c0c0c0ff)",
        },
        layout        = "dwindle",
        allow_tearing = true,
    },

    decoration = {
        rounding = 0,
        blur = { enabled = false },
        shadow = {
            enabled      = true,
            range        = 8,
            render_power = 2,
            color        = "rgba(00000088)",
        },
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        focus_on_activate        = true,
    },

    dwindle = {
        preserve_split         = true,
        split_width_multiplier = 1.0,
    },

    animations = { enabled = true },
})

------------------------------------------------------------
-- ANIMACIONES
------------------------------------------------------------
hl.curve("snappy", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "snappy" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "snappy", style = "slidevert" })

------------------------------------------------------------
-- WINDOW RULES
------------------------------------------------------------
hl.window_rule({
    match     = { class = "^(steam_app_.*)$" },
    immediate = true,
    no_blur   = true,
    no_anim   = true,
})

------------------------------------------------------------
-- WORKSPACES
------------------------------------------------------------
for i = 1, 9 do
    hl.workspace_rule({ workspace = i, persistent = true })
end

------------------------------------------------------------
-- KEYBINDS
------------------------------------------------------------
local mod = "SUPER"

-- Apps
hl.bind(mod .. " + Return",    hl.dsp.exec_cmd("alacritty"))
hl.bind(mod .. " + BackSpace", hl.dsp.exec_cmd("~/.config/hypr/scripts/power_menu.sh"))
hl.bind(mod .. " + period",    hl.dsp.exec_cmd("~/.config/rofi/scripts/emote-picker.sh"))
hl.bind(mod .. " + A",         hl.dsp.exec_cmd("rofi -show drun"))

-- Ventanas
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + V", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 800, y = 600 }))
end)

-- Foco
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Swap
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))

hl.bind(mod .. " + I",         hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Workspaces
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Sistema
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | tee ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy"))
hl.bind(mod .. " + D",         hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_desktop.sh"))

-- Mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

------------------------------------------------------------
-- GAMING
------------------------------------------------------------
-- require("gaming")
