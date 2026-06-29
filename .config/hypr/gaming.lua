-- r4chi-dotfiles · by occhi

------------------------------------------------------------
-- MONITOR
------------------------------------------------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

------------------------------------------------------------
-- ENV
------------------------------------------------------------
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

hl.env("MESA_SHADER_CACHE_MAX_SIZE", "12G")
hl.env("RADV_PERFTEST", "gpl,sam")
hl.env("AMD_VULKAN_ICD", "RADV")

------------------------------------------------------------
-- OPTIONS
------------------------------------------------------------
hl.config({
    general = {
        allow_tearing = true,
    },

    misc = {
        vrr = 2,
    },

    cursor = {
        no_hardware_cursors = false,
        hide_on_key_press   = true,
        hide_on_touch       = true,
    },
})

------------------------------------------------------------
-- WINDOW RULES
------------------------------------------------------------
hl.window_rule({ match = { class = "^(steam_app_).*" }, immediate = true })
hl.window_rule({ match = { class = "^(gamescope)$" },   immediate = true })
hl.window_rule({ match = { class = "^(cs2)$" },         immediate = true })
hl.window_rule({ match = { class = "^(.*\\.exe)$" },    immediate = true })

hl.window_rule({
    match       = { fullscreen = true },
    immediate   = true,
    no_anim     = true,
    no_shadow   = true,
    border_size = 0,
})

hl.window_rule({ match = { class = "^(steam)$" },  workspace = "9" })
hl.window_rule({ match = { class = "^(lutris)$" }, workspace = "9" })

hl.window_rule({ match = { title = "^(MangoHud)$" }, float = true, pin = true })
