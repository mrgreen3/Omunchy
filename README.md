# omunchy

A lightweight, Omarchy-inspired desktop installer for [ArchBang](https://archbang.org).

Omunchy is an all-in installer script — not a standalone distro — that layers a lean Wayland desktop and app-launching setup on top of an existing ArchBang install.

## Stack

- **Compositor:** [Hyprland](https://hypr.land) — from the official Arch repos (MangoWC was the only AUR dep; two network tools remain from AUR)
- **Bar:** Waybar
- **Launcher:** Rofi
- **Notifications:** Mako
- **Terminal:** foot
- **Web apps:** Chromium, locked down, using the `--app=` / PWA install mechanism for per-app windows rather than a full browser

This stack was chosen specifically to avoid the RAM overhead of a full shell daemon (e.g. quickshell) on constrained hardware such as Chromebooks. Hyprland costs ~150 MB of idle RAM over a minimal compositor — accepted deliberately for exact Omarchy behaviour (hyprctl, animations, effects); everything else stays file-configured with no daemons.

## Features

Pattern-for-pattern with Omarchy (see `docs/omarchy-parity.md` for the full 42-row analysis):

- **Kept:** the metadata-header CLI dispatcher, webapp/TUI installers, `sync`, the bar/launcher/notification apps as plain configs, grim+slurp screenshots, the keybind-cheatsheet doc, thunar, btop/fastfetch, adw-gtk theming.
- **Lean replacements:** a two-file theme system + wallpaper switcher instead of Omarchy's 34 theme commands, a rofi menu instead of the quickshell menu daemon, a one-script update (reflector → pacman → yay → orphan prune) instead of the 22-cmd update system with snapper/migrations/channels.
- **Stripped:** Omarchy's branded extras, per-app theming, protocol handlers, first-boot provisioning, plymouth/limine/snapper, plugin ecosystem, release channels — the CLI verb shape is inherited, the bloat is not.

## Usage

The CLI follows Omarchy's pattern: `bin/omunchy` is a dispatcher that auto-discovers
self-describing `bin/omunchy-*` scripts (each declares its own summary/args/examples
via metadata comments), so every file is a subcommand:

```
omunchy webapp install Gmail https://mail.google.com gmail   # one-off web app
omunchy tui install htop htop float utilities-system-monitor # one-off TUI launcher
omunchy webapp remove                                        # picker (fzf / numbered list)
omunchy webapp remove all                                    # bulk removal
omunchy tui remove all                                       # bulk removal
omunchy sync                                                 # batch from config/
omunchy theme set omunchy-light                              # switch colour theme
omunchy bg set ~/Backgrounds/kanagawa.jpg                    # switch wallpaper
omunchy menu                                                 # rofi launcher menu
omunchy hypr reload                                          # hyprctl reload
omunchy update                                               # reflector + pacman -Syu + orphans
omunchy help                                                 # everything, with examples
```

- `omunchy sync` reads `config/webapps.conf` (`Name|URL|Icon`) and `config/tuis.conf`
  (`Name|Command|Style|Icon`) and generates `.desktop` entries for every line.
  It also links `bin/omunchy-*` into `~/.local/bin` so `Exec=` references resolve.
  Missing icons are fetched from the site's favicon (apple-touch-icon → well-known
  path → Google favicon service) with a generic icon as last resort.
- `omunchy sync` also installs two launcher menu entries — **Add Web App** and
  **Add TUI** — that run the interactive installers in a terminal (emulating
  Omarchy's install.webapp/install.tui menu items), using the best available
  terminal emulator (xdg-terminal-exec, foot, alacritty, or kitty).
- `omunchy webapp remove` / `omunchy tui remove` mirror Omarchy's remove flow:
  they index the installed `omunchy-*` launchers, pick one (fzf, or a numbered
  list when fzf is absent), delete the `.desktop` and its omunchy-fetched icon,
  and warn when the app is still defined in `config/*.conf` (or `sync` would
  recreate it on the next run). The `remove all` variants grep for the omunchy
  launcher pattern (`Exec=…omunchy-launch-webapp`, TUI app-id `omunchy.TUI.*`)
  and bulk-remove exactly those — including one-off installer entries sync
  knows nothing about.
- Web app entries launch through `bin/omunchy-launch-webapp` (Chromium `--app=` mode,
  Wayland), so there is one place to later add launch-or-focus behaviour.
- TUI entries run via `xdg-terminal-exec` with app-id `omunchy.TUI.float` /
  `omunchy.TUI.tile`, so Hyprland window rules can target floating/tiled TUIs
  (the shipped `hyprland.conf` floats `omunchy.TUI.float`).
- `omunchy theme set <name>` applies a theme from `config/themes/<name>.conf` —
  plain shell-sourceable `NAME=hex` fragments, no Lua, no per-app theming —
  rewriting the colour lines in foot/waybar/mako/rofi configs and the Hyprland
  border colours, then restarting the bar and reloading Hyprland. Two ship:
  `omunchy-dark` (default, warm dark like ArchBang) and `omunchy-light`.
- `omunchy bg set <image>` rewrites the hyprpaper `exec-once` line in
  `~/.config/hypr/hyprland.conf` and applies it to the running session.
- `omunchy update` refreshes mirrors with reflector (best-rated 5, skipped when
  offline), runs `pacman -Syu`, updates AUR packages via yay only when any are
  installed, and prompts to prune orphans — guarded by a lock so two updates
  cannot interleave.

## Keybindings

The shipped `~/.config/hypr/hyprland.conf` mirrors Omarchy's bindings in plain
Hyprland conf (no Lua): `Super+Return` foot, `Super+Space` rofi, `Super+Q` close,
`Super+F` fullscreen, `Super+T` float, `Super+V` split, `Super+P` screenshot,
`Super+L` hyprlock, `Super+Shift+E` power menu, `Super+1..9` workspaces,
XF86 audio/brightness via pamixer/brightnessctl. The full list lives in
`Documents/Keybindings` (`Super+K` shows it in rofi).

## Layout

```
bin/omunchy                    dispatcher (emulates Omarchy's bin/omarchy)
bin/omunchy-sync               batch-generate entries from config/ + link bins + menu entries
bin/omunchy-webapp-install     create a web app launcher (interactive when run bare)
bin/omunchy-tui-install        create a TUI launcher (interactive when run bare)
bin/omunchy-webapp-remove      remove a web app launcher (fzf or numbered picker)
bin/omunchy-tui-remove         remove a TUI launcher (fzf or numbered picker)
bin/omunchy-webapp-remove-all  remove every omunchy web app launcher
bin/omunchy-tui-remove-all     remove every omunchy TUI launcher
bin/omunchy-launch-webapp      Chromium --app= launcher used by web app entries
bin/omunchy-hypr-reload        reload the Hyprland session config
bin/omunchy-theme-set          switch the desktop colour theme
bin/omunchy-bg-set             switch the wallpaper (rewrites the hyprpaper line)
bin/omunchy-menu               rofi launcher menu (apps / web apps / TUIs / keybinds / power)
bin/omunchy-update             mirrors -> pacman -> yay -> orphan prune, lock-guarded
config/webapps.conf            Name|URL|Icon per line
config/tuis.conf               Name|Command|Style|Icon per line
config/themes/*.conf           theme palettes (omunchy-dark, omunchy-light)
install.sh                     bootstrap: base stack + configs + sync
airootfs/                      archbang-derived archiso skeleton (Hyprland skel config included)
docs/omarchy-parity.md         Omarchy feature parity analysis and decisions
.reference/                    upstream Omarchy scripts kept for reference (not committed)
```

## Status

Entry generation, interactive installers, removal, sync, the Hyprland session,
theme/wallpaper switching, the update flow, and the base-stack installer are
working. Dispatcher aliases/group descriptions are a possible next step.

## License

TBD