# omunchy

A lightweight, Omarchy-inspired desktop installer for [ArchBang](https://archbang.org).

Omunchy is an all-in installer script — not a standalone distro — that layers a lean Wayland desktop and app-launching setup on top of an existing ArchBang install.

## Stack

- **Compositor:** [MangoWC](https://github.com/DreamMaoMao/mango)
- **Bar:** Waybar
- **Launcher:** Rofi
- **Notifications:** Mako
- **Web apps:** Chromium, locked down, using the `--app=` / PWA install mechanism for per-app windows rather than a full browser

This stack was chosen specifically to avoid the RAM overhead of a full shell daemon (e.g. quickshell) on constrained hardware such as Chromebooks.

## Usage

The CLI follows Omarchy's pattern: `bin/omunchy` is a dispatcher that auto-discovers
self-describing `bin/omunchy-*` scripts (each declares its own summary/args/examples
via metadata comments), so every file is a subcommand:

```
omunchy webapp install Gmail https://mail.google.com gmail   # one-off web app
omunchy tui install htop htop float utilities-system-monitor # one-off TUI launcher
omunchy webapp remove                                        # picker (fzf / numbered list)
omunchy sync                                                 # batch from config/
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
  recreate it on the next run). One-off entries created through the installer
  are never touched by `sync` and can only be removed with these commands.
- Web app entries launch through `bin/omunchy-launch-webapp` (Chromium `--app=` mode,
  Wayland), so there is one place to later add launch-or-focus behaviour for MangoWC.
- TUI entries run via `xdg-terminal-exec` with app-id `omunchy.TUI.float` /
  `omunchy.TUI.tile`, so MangoWC window rules can target floating/tiled TUIs.

`install.sh` installs the base stack (not yet implemented) and then runs `omunchy sync`.

## Layout

```
bin/omunchy                 dispatcher (emulates Omarchy's bin/omarchy)
bin/omunchy-sync            batch-generate entries from config/ + link bins + menu entries
bin/omunchy-webapp-install  create a web app launcher (interactive when run bare)
bin/omunchy-tui-install     create a TUI launcher (interactive when run bare)
bin/omunchy-webapp-remove   remove a web app launcher (fzf or numbered picker)
bin/omunchy-tui-remove      remove a TUI launcher (fzf or numbered picker)
bin/omunchy-launch-webapp   Chromium --app= launcher used by web app entries
config/webapps.conf         Name|URL|Icon per line
config/tuis.conf            Name|Command|Style|Icon per line
install.sh                  bootstrap: base stack + sync
.reference/                 upstream Omarchy scripts kept for reference (not committed)
```

## Status

Early stages — entry generation, interactive installers, removal, and sync are
working; base stack install and keybinds are next.

## License

TBD