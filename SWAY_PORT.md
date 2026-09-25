# Hyprland → sway port (2026-09-25)

Omunchy was converted from the Hyprland compositor to sway (Wayland,
i3-compatible). Branch: `sway-port`. This file records what was translated,
what was dropped or approximated, and what needs testing on a real sway
session. The `docs/*` research notes are historical records of the Hyprland
era and are left as written (each carries a dated header note).

## Mapping used everywhere

| Hyprland side | sway side |
|---|---|
| `hyprctl` IPC | `swaymsg` IPC |
| `hyprctl reload` | `swaymsg reload` |
| `~/.config/hypr/*.lua` (hl.bind/hl.config/hl.dsp) | `~/.config/sway/{config,binds,looknfeel,theme}` (i3-style) |
| `omunchy-hypr-reload` (`omunchy hypr reload`) | `omunchy-sway-reload` (`omunchy sway reload`) |
| hyprpaper (IPC wallpaper) | swaybg (`exec swaybg -i <img> -m fill`, restart on change) |
| hyprlock | swaylock (already in packages.x86_64) |
| hyprsunset (+ `hyprsunset.conf` profile) | wlsunset (`-T <K>`; identity = not running) |
| xdg-desktop-portal-hyprland | xdg-desktop-portal-wlr |
| waybar `hyprland/*` modules | `sway/*` modules (workspaces, language) |
| dwindle layout | `autotiling` (nwg-piotr) via `exec_always omunchy-autotile start` (pkill-then-start wrapper, reload-safe) |
| window rule `class = ^omunchy\.TUI\.float$` | `for_window [app_id="^omunchy\.TUI\.float$"] floating enable` |
| `hl.window_rule` float for `omunchy.Installer` | same mechanism, app_id `omunchy.Installer` |
| `env =` exports + Hyprland's own systemd/dbus export | `.bash_profile` exports before `exec sway`; `exec_always systemctl --user set-environment` + `dbus-update-activation-environment` in the sway config |
| Super+Tab `workspace e+1/e-1` | `workspace next` / `workspace prev` |
| `hyprctl dispatch exit` (Lua `hl.dsp.exit()`) | `swaymsg exit` |
| kb_layout `us` (abinstall sed target) | `xkb_layout us` (same sed-able own-line position) |
| `hyprctl switchxkblayout current next` (bar click) | `swaymsg input '*' xkb_switch_layout next` |
| greetd `environments`: "Hyprland" | "sway" |

## Dropped or approximated (Hyprland-only, no sway equivalent)

- **Dwindle layout** — approximated with the `autotiling` package (added
  2026-09-25): it flips the focused container's split orientation to match
  its shape, which is the behaviour Hyprland's dwindle gave. Not exact:
  no depth/balance rules, just shape-following splits (`-l` can emulate a
  master-stack feel). Started from the sway `looknfeel` via
  `exec_always omunchy-autotile start`; the wrapper pkills first, so
  `swaymsg reload` never stacks duplicates, and a user-toggled off state
  (`omunchy autotile toggle`, also in the rofi menu) survives reload.
- **Animations** — dropped entirely. The Omarchy-exact animation set
  (bezier curves easeOutQuint/easeInOutCubic/quick, per-animation speeds,
  `windowsIn popin 87%`, layer fades) has no sway counterpart; sway draws
  workspaces/windows instantly. Visual behaviour change, accepted.
- **Blur / shadows / rounding** — not available in sway; they were already
  disabled in the Hyprland config (`rounding = 0`, shadow off, blur off),
  so nothing visible is lost.
- **Hyprland Lua config** — gone by design. The error-isolated `require()`
  module system (a typo in one file can't kill the session) becomes plain
  `include`s; a bad line in an included file makes `swaymsg reload` fail
  loudly with file/line instead of silently skipping the module.
- **`hyprctl eval` live keyword application** — theme-set wrote the border
  colours live via `hyprctl eval`. sway has no eval: `omunchy theme set`
  now writes `~/.config/sway/theme` and runs `swaymsg reload` (whole-config
  reload, safe for sway).
- **hyprpaper / hyprsunset IPC** — no equivalents. Wallpaper changes kill +
  re-exec swaybg through the IPC; night light is wlsunset started/stopped as
  a process (state read from its `-T` argument by the bar indicator).
  `hyprsunset.conf` was dropped — wlsunset needs no profile file; its
  "no tint" state is simply not running.
- **hyprpicker** — dropped (no script used it; re-add on demand).
- **`uwsm`** — dropped; sway is exec'd straight from the login shell
  (.bash_profile), no session-management wrapper.
- **`misc`/`cursor` niceties** — `focus_on_activate`,
  `anr_missed_pings`, `on_focus_under_fullscreen`,
  `initial_workspace_tracking`, `cursor.warp_on_change_workspace`,
  `cursor.hide_on_key_press` have no sway equivalents. Closest
  approximations: none needed for daily use; cursor warping can be added
  later via a workspace switch `exec` hook if it bothers anyone.
- **Special workspaces** (`hide_special_on_workspace_change`) — unused in
  the shipped binds; not carried over. sway named workspaces cover the need
  if it ever returns.
- **Group bar (tabbed groups)** — Hyprland's window-group bar with gradients
  has no sway equivalent; sway's own `tabbed`/`stacked` layouts replace it.
- **Workspace swipe** — approximated: `hl.gesture` 3-finger horizontal →
  `bindgesture swipe:3:left/right workspace prev/next` (sway 1.8+).
- **`workspace e±1` semantics** — sway's `workspace next/prev` wraps within
  the current output; behaviour is close but not identical.

## Files changed

- Added: `airootfs/etc/skel/.config/sway/{config,binds,looknfeel,theme}`,
  `bin/omunchy-sway-reload`, `bin/omunchy-autotile` (dwindle-style
  autotiling wrapper; airootfs mirror too), this file.
- Removed: `airootfs/etc/skel/.config/hypr/*` (5 Lua files),
  `bin/omunchy-hypr-reload` + its airootfs mirror.
- Converted: waybar config (`sway/workspaces`, `sway/language`, swaymsg
  scroll/layout actions, `#sway-language` CSS), bin/ + airootfs mirrors
  (theme-set, bg-set, menu, tui-install), bar `indicators.sh` (wlsunset),
  theme palettes (`SWAY_ACTIVE_BORDER`/`SWAY_INACTIVE_BORDER`),
  `packages.x86_64` (sway stack), `install.sh`, `abinstall` (keyboard
  layout sed, wallpaper extraction, greeter, welcome text),
  `.bash_profile` (session env + `exec sway`), skel theme copies,
  `powermenu`, `tuis.conf`, `gtkgreet.css`, README, docs header notes.

## Needs testing on a real sway session

1. Boot: `.bash_profile` env exports + `exec sway` on tty1 (live ISO
   autologin path unchanged).
2. `omunchy sway reload` and Super+R reload — config syntax passes
   `sway -C` on the build box (not installed here), but runtime reload
   with running clients is untested.
3. Wallpaper: `omunchy bg set` end-to-end (marker rewrite + swaybg restart),
   and first-boot `WALLPAPER_MARKER` exec timing (sleep 1 guard).
4. Theme switch: borders (client.* lines), waybar/mako/rofi restarts.
5. Night light: indicators `toggle-night` with wlsunset (start/stop, state
   read from process args; brightness/temperature defaults may need tuning
   per-device — `-l`/`-t` day/night temps not set, wlsunset defaults apply).
6. waybar sway modules: workspaces pill click (the waybar 0.15 Hyprland
   Lua-parser click bug does not exist here; sway's module uses the standard
   click path) + scroll + language click.
7. TUI float rules: `omunchy tui install htop htop float` → app_id rule
   floats the window (verify `for_window` matcher with `swaymsg -t
   get_tree`).
8. greeter: cage + gtkgreet with session list entry "sway".
9. Screenshot, swaylock (Super+L), power menu logout (`swaymsg exit`).
10. swayidle: shipped in packages but no config is installed — decide
    whether to add a lock-on-idle config or drop the package (lean rule).
11. autotiling: `exec_always omunchy-autotile start` opens a tall window,
    then narrow ones (split flips h/v with the window shape); `swaymsg
    reload` twice → still exactly one `autotiling` process (check
    `pgrep -ax autotiling`); menu toggle off → reload → stays off.