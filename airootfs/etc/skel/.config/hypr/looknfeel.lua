-- =============================================================================
-- Omunchy — look & feel, input, autostart, window rules (Hyprland 0.56 Lua).
-- Omarchy looknfeel parity; every option verified in Hyprland 0.56
-- src/config/values/ConfigValues.cpp. Option name mapping: hyprlang '-' -> '_'.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LOOK & FEEL (translated from Omarchy default/hypr/looknfeel.lua)
-- -----------------------------------------------------------------------------
hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 2,
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },
    decoration = {
        rounding = 0,
        shadow   = { enabled = false },
        blur     = { enabled = false },
    },
    group = {
        groupbar = {
            font_size   = 12,
            font_family = "monospace",
            gradients   = true,
        },
    },
    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },
    misc = {
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        disable_scale_notification = true,
        focus_on_activate          = true,
        anr_missed_pings           = 3,
        on_focus_under_fullscreen  = 1,
        initial_workspace_tracking = 0,
        allow_session_lock_restore = true,
    },
    cursor = {
        hide_on_key_press       = true,
        warp_on_change_workspace = 1,
    },
    binds = {
        hide_special_on_workspace_change = true,
    },
    animations = { enabled = true },
})

-- -----------------------------------------------------------------------------
-- ANIMATIONS (exact Omarchy speeds/curves)
-- -----------------------------------------------------------------------------
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1.0 }, { 0.32, 1.0 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1.0 } } })
hl.curve("linear",         { type = "bezier", points = { { 0.0, 0.0 },  { 1.0, 1.0 }  } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },  { 0.75, 1.0 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0.0 }, { 0.1, 1.0 }  } })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch",    enabled = false })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = false })

-- -----------------------------------------------------------------------------
-- INPUT (kb_layout kept on its own line — abinstall rewrites it with sed)
-- -----------------------------------------------------------------------------
hl.config({
    input = {
        kb_layout       = "us",
        repeat_rate     = 25,
        repeat_delay    = 600,
        numlock_by_default = false,
        touchpad = {
            tap_to_click         = true,
            natural_scroll       = false,
            disable_while_typing = true,
        },
    },
})

-- gestures{} is gone in 0.56: workspace swiping is an hl.gesture() now
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- -----------------------------------------------------------------------------
-- AUTOSTART (hl.on("hyprland.start") + exec-once semantics)
-- -----------------------------------------------------------------------------
hl.on("hyprland.start", function()
    -- Privilege-escalation prompts (in packages.x86_64; Hyprland ships no polkit agent)
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hyprpaper")
    -- Hyprpaper 0.8 has no preload/unload IPC — one wallpaper call is the whole API.
    -- The sleep guard goes on the spawned command (keybind handlers and the
    -- hyprland.start callback must not block — wiki binds warning).
    -- MARKER: omunchy-bg-set rewrites ONLY the exec_cmd line below.
    hl.exec_cmd("sleep 1 && hyprctl hyprpaper wallpaper \",$HOME/Backgrounds/aesthetic.jpg\"") -- WALLPAPER_MARKER
end)

-- NOTE: the old `exec-once = dbus-update-activation-environment --systemd …`
-- line is gone: Hyprland 0.56's CExecutor::onStart already exports
-- WAYLAND_DISPLAY / XDG_CURRENT_DESKTOP / PATH etc. into the systemd user
-- environment + dbus activation env before spawning exec-once commands.

-- -----------------------------------------------------------------------------
-- WINDOW RULES (omunchy launchers — see config/tuis.conf)
-- -----------------------------------------------------------------------------
hl.window_rule({
    name  = "omunchy-tui-float",
    match = { class = "^(omunchy\\.TUI\\.float)$" },
    float = true,
})
hl.window_rule({
    name  = "omunchy-installer",
    match = { class = "^(omunchy\\.Installer)$" },
    float = true,
})