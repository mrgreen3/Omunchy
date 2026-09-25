-- =============================================================================
-- Omunchy — Hyprland configuration (Lua, Hyprland 0.56+).
--
-- Omarchy-parity bindings on the waybar/foot/mako/rofi stack. Since Hyprland
-- 0.55 hyprlang (.conf) is deprecated; this file loads INSTEAD of any
-- hyprland.conf. Reload after editing: omunchy hypr reload  (hyprctl reload)
--
-- Split into modules via require(): each require is an error-isolated Lua
-- scope, so a typo in one file cannot kill the whole config.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- MONITOR
-- -----------------------------------------------------------------------------
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- -----------------------------------------------------------------------------
-- ENVIRONMENT + PORTALS
-- -----------------------------------------------------------------------------
hl.env("XDG_CURRENT_DESKTOP", "Hyprland", true)
hl.env("XDG_SESSION_TYPE", "wayland", true)
hl.env("XDG_SESSION_DESKTOP", "Hyprland", true)
hl.env("XCURSOR_THEME", "Adwaita", true)
hl.env("XCURSOR_SIZE", "24", true)
hl.env("MOZ_ENABLE_WAYLAND", "1", true)
hl.env("GDK_BACKEND", "wayland,x11", true)

-- -----------------------------------------------------------------------------
-- MODULES (each require is an error-isolated scope)
-- -----------------------------------------------------------------------------
require("looknfeel")
require("binds")
require("theme")