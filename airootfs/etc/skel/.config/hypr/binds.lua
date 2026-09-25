-- =============================================================================
-- Omunchy — keybinds (Hyprland 0.56 Lua). Omarchy-parity bindings.
-- Keys are xkbcommon keysyms; modifiers: SUPER/SHIFT/ALT/CTRL.
-- =============================================================================

local terminal = "foot"

-- --- Apps ---
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + SPACE",  hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("SUPER + A",      hl.dsp.exec_cmd("omunchy menu"))
hl.bind("SUPER + B",      hl.dsp.exec_cmd("chromium"))
hl.bind("SUPER + E",      hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + S",      hl.dsp.exec_cmd("foot -e dgop top"))
hl.bind("SUPER + K", hl.dsp.exec_cmd(
    "bash -c 'grep -E \"(Super|Ctrl|Vol|Mute|Bright)\" ~/Documents/Keybindings | rofi -dmenu -p Keybinds -theme-str \"listview { lines: 18; columns: 2; }\"'"))

-- --- Windows ---
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + V", hl.dsp.layout("togglesplit"))

-- --- Focus & movement ---
hl.bind("SUPER + left",        hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right",       hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up",          hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down",        hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + TAB",        hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))

-- --- Workspaces 1-9 (switch / send window) ---
for i = 1, 9 do
    hl.bind("SUPER + " .. i,          hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i }))
end

-- --- Monitors ---
hl.bind("SUPER + ALT + left",  hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + ALT + right", hl.dsp.focus({ monitor = "r" }))

-- --- Audio & brightness ---
-- (no leading mod = no modifier; the conf's `bind = , XF86…` form maps to this)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pamixer -i 5"),    { repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("pamixer -d 5"),    { repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pamixer -t"),      { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s +5%"),  { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"),  { repeating = true })

-- --- Session ---
hl.bind("SUPER + P",        hl.dsp.exec_cmd("~/Scripts/screenshot"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("~/Scripts/screenshot -r"))
hl.bind("SUPER + L",        hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + R",        hl.dsp.reload_config())
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("~/Scripts/powermenu"))