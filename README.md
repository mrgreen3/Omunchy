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

## What the script does

- Installs and configures the base stack (MangoWC, Waybar, Rofi, Mako)
- Generates `.desktop` entries for web apps from a simple config (name, URL, icon)
- Wraps TUI apps in `.desktop` entries (with `Terminal=true` or an explicit terminal exec line) so they appear in Rofi alongside GUI apps
- Sets up a sane default keybind configuration

## Status

Early stages — design and scope still settling. Details will be fleshed out here as the script takes shape.

## License

TBD
