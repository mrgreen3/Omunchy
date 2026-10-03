# omunchy

A lightweight, Omarchy-inspired desktop installer for [ArchBang](https://archbang.org).

Omunchy is an all-in installer script — not a standalone distro — that layers a lean Wayland desktop and app-launching setup on top of an existing ArchBang install.

## Stack

- **Compositor:** [sway](https://swaywm.org) — from the official Arch repos (i3-compatible Wayland; whole stack official-repo)
- **Tiling:** [autotiling](https://github.com/nwg-piotr/autotiling) — dwindle-style split-orientation switching (Hyprland dwindle parity), toggle in the menu
- **Bar:** Waybar
- **Launcher:** Rofi
- **Notifications:** Mako
- **Terminal:** foot
- **Browser / web apps:** Firefox

This stack was chosen specifically to avoid the RAM overhead of a full shell daemon (e.g. quickshell) on constrained hardware such as Chromebooks. sway is among the leanest full Wayland compositors (idle desktop within ~tens of MB of a bare compositor); everything else stays file-configured with no daemons. The Omarchy-exact animation set was dropped — see `SWAY_PORT.md`.

## Features

Pattern-for-pattern with Omarchy (see `docs/omarchy-parity.md` for the full 42-row analysis):

- **Kept:** the bar/launcher/notification apps as plain configs, grim+slurp screenshots, the keybind-cheatsheet doc, thunar, fastfetch, adw-gtk theming.
- **Lean replacements:** one fixed theme and wallpaper, a one-script update (reflector → pacman → yay → orphan prune) instead of the 22-cmd update system with snapper/migrations/channels.
- **Stripped:** Omarchy's branded extras, per-app theming, protocol handlers, first-boot provisioning, plymouth/limine/snapper, plugin ecosystem, release channels, the CLI dispatcher and web app/TUI installers.

## Usage

Helper scripts live in `~/Scripts` (on PATH):

```
omunchy-welcome            # live-boot network report (started by sway)
obinstall                  # install Omunchy to disk (copies this live system; no network needed)
obinstall --dry-run --config FILE   # print every step, touch nothing
```

`obinstall` is a gum wizard (keyboard, account, hostname, timezone, disk, optional LUKS2) with a
summary screen before anything is touched. It partitions the disk (GPT, 1 GiB ESP, btrfs with
`@ @home @log @pkg`), copies the running live system to it
(tar | pv | tar, kernel from the ISO media, live-session changes synced), then converts the copy
into an installed system: user rename, mkinitcpio (systemd hooks, `sd-encrypt` for LUKS), greetd,
GRUB. It re-runs itself through sudo, so no need to prefix it. Source: `airootfs/usr/local/lib/obinstall/`.
Untested on real hardware: try it in a VM first.

- **AI setup assistant.** `opencode` ships in `packages.x86_64`. On the live ISO
  `omunchy-welcome` (started from sway's `looknfeel`) shows a Super+K keybinds
  hint at login, and a persistent warning with connection hints when offline,
  which closes itself once a connection appears (watched for 30 minutes). OpenCode runs as
  `opencode --standalone` (cloud-only, but free models work with no login) on the single `omunchy-guide` skill, which reads
  `~/Documents/Guide.md` (the human Guide doubles as the assistant's reference: ABOUT, AI SETUP, APPS, packages). The skill lives in
  `~/.config/opencode/skills`; the user-local tools in the Guide use each tool's own installer into `~/.local`, so no
  nodejs/npm packages and nothing global. Opt in to opening the assistant
  automatically once online by starting the welcome with `AUTORUN=1`
  (e.g. `exec env AUTORUN=1 ~/Scripts/omunchy-welcome` in `looknfeel`).

## Keybindings

The shipped `~/.config/sway/config` (+ `binds`/`looknfeel`/`theme` includes)
mirrors Omarchy's bindings as i3-style sway config: `Super+Return` foot,
`Super+Space` rofi, `Super+Q` close, `Super+F` fullscreen, `Super+T` float,
`Super+V` split, `Super+P` screenshot, `Super+L` swaylock,
`Super+Shift+E` power menu, `Super+1..5` workspaces,
XF86 audio/brightness via pamixer/brightnessctl. The full list lives in
`Documents/Keybindings` (`Super+K` shows it in rofi).

## Layout

```
airootfs/etc/skel/Scripts/omunchy-welcome   live-boot network report via mako
airootfs/                      archbang-derived archiso skeleton (sway skel config included)
```

## Known issues

- **Workspace pill left-click:** fixed by the sway port — the waybar 0.15
  breakage (`hyprland/workspaces` + Hyprland's Lua config parser, see
  `docs/waybar-hyprland-compat.md`) does not exist on sway; the
  `sway/workspaces` module takes the standard click path. Scroll on the
  pills, keyboard binds, urgent highlighting, and window counts all work;
  `Super+1..5` and `Super+Tab` cover navigation. Full audit matrix in that
  doc.

## Status

Entry generation, interactive installers, removal, sync, the sway session,
theme/wallpaper switching, the update flow, and the base-stack installer are
working. Dispatcher aliases/group descriptions are a possible next step.

## License

TBD