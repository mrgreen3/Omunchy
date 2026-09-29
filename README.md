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
- **Web apps:** Chromium, locked down, using the `--app=` / PWA install mechanism for per-app windows rather than a full browser

This stack was chosen specifically to avoid the RAM overhead of a full shell daemon (e.g. quickshell) on constrained hardware such as Chromebooks. sway is among the leanest full Wayland compositors (idle desktop within ~tens of MB of a bare compositor); everything else stays file-configured with no daemons. The Omarchy-exact animation set was dropped — see `SWAY_PORT.md`.

## Features

Pattern-for-pattern with Omarchy (see `docs/omarchy-parity.md` for the full 42-row analysis):

- **Kept:** the metadata-header CLI dispatcher, webapp/TUI installers, `sync`, the bar/launcher/notification apps as plain configs, grim+slurp screenshots, the keybind-cheatsheet doc, thunar, fastfetch, adw-gtk theming.
- **Lean replacements:** a two-file theme system + wallpaper switcher instead of Omarchy's 34 theme commands, a rofi menu instead of the quickshell menu daemon, a one-script update (reflector → pacman → yay → orphan prune) instead of the 22-cmd update system with snapper/migrations/channels.
- **Stripped:** Omarchy's branded extras, per-app theming, protocol handlers, first-boot provisioning, plymouth/limine/snapper, plugin ecosystem, release channels — the CLI verb shape is inherited, the bloat is not.

## Usage

The CLI follows Omarchy's pattern: `Scripts/omunchy` is a dispatcher that auto-discovers
self-describing `Scripts/omunchy-*` scripts (each declares its own summary/args/examples
via metadata comments), so every file is a subcommand:

```
omunchy webapp install Gmail https://mail.google.com gmail   # one-off web app
omunchy tui install htop htop float utilities-system-monitor # one-off TUI launcher
omunchy webapp remove                                        # picker (fzf / numbered list)
omunchy webapp remove all                                    # bulk removal
omunchy tui remove all                                       # bulk removal
omunchy sync                                                 # batch from config/
omunchy theme set omunchy-forest                             # switch colour theme
omunchy bg set ~/Backgrounds/mountain-moon.jpg                    # switch wallpaper + recolour from it
omunchy bg set --no-theme <image>                            # wallpaper only, keep colours
omunchy theme wallpaper <image>                              # recolour from an image (matugen)
omunchy menu                                                 # rofi launcher menu
omunchy sway reload                                         # swaymsg reload
omunchy pi install                                           # launch pi (installs it first if missing)
omunchy update                                               # reflector + pacman -Syu + orphans
omunchy autotile toggle                                      # dwindle-style autotiling on/off
omunchy help                                                 # everything, with examples
```

- `omunchy sync` reads `config/webapps.conf` (`Name|URL|Icon`) and `config/tuis.conf`
  (`Name|Command|Style|Icon`) and generates `.desktop` entries for every line.
  It also links `Scripts/omunchy-*` into `~/.local/bin` so `Exec=` references resolve.
  Missing icons are fetched from the site's favicon (apple-touch-icon → well-known
  path → Google favicon service) with a generic icon as last resort.
- New web apps and TUIs are added from a terminal with `omunchy webapp install`
  and `omunchy tui install` (no app-menu entries for these; `omunchy sync`
  removes the old "Add Web App" / "Add TUI" launchers if present).
- All conf-derived launchers ship as static `.desktop` entries in the ISO skel
  (Gmail/YouTube/GitHub web apps with favicon PNGs, the `dgop` TUI from the
  official-repo package listed in `packages.x86_64`). The Exec lines resolve
  `omunchy-launch-webapp` / the command via `~/Scripts` on PATH, so they work
  for any user without a login-time sync. `omunchy sync` regenerates identical
  entries from `config/*.conf` when run manually.
- `omunchy pi install` launches the pi coding agent in a floating foot
  window, installing it first if missing (the official installer runs
  unattended and bootstraps node/npm itself). The shipped "Pi" desktop entry
  execs into the same script, so it keeps working as a launcher forever.
- **AI setup assistant.** `opencode` ships in `packages.x86_64`. On the live ISO
  `omunchy-welcome` (started from sway's `looknfeel`) reports the network state
  through mako, warns with connection hints when offline, and keeps watching for
  30 minutes. `Super+A` (or the "AI Setup Assistant" entry in the launcher, or
  `omunchy opencode setup`) runs `omunchy-opencode-setup`: a network check, then
  `opencode --standalone` (cloud-only, but free models work with no login) on the `setup-menu` skill. Skills live in
  `~/.config/opencode/skills` (`setup-menu`, `pacman-helper`, `claude-code-setup`,
  `pi-setup`, `tuios-setup`, `herdr-setup`, `dev-env-setup`); the Claude Code, pi, tuios and herdr
  skills use each tool's own installer into `~/.local` / `~/.pi`, so no
  nodejs/npm packages and nothing global. Opt in to opening the assistant
  automatically once online by starting the welcome with `AUTORUN=1`
  (e.g. `exec env AUTORUN=1 ~/Scripts/omunchy-welcome` in `looknfeel`).
- `omunchy webapp remove` / `omunchy tui remove` mirror Omarchy's remove flow:
  they index the installed `omunchy-*` launchers, pick one (fzf, or a numbered
  list when fzf is absent), delete the `.desktop` and its omunchy-fetched icon,
  and warn when the app is still defined in `config/*.conf` (or `sync` would
  recreate it on the next run). The `remove all` variants grep for the omunchy
  launcher pattern (`Exec=…omunchy-launch-webapp`, TUI app-id `omunchy.TUI.*`)
  and bulk-remove exactly those — including one-off installer entries sync
  knows nothing about.
- Web app entries launch through `Scripts/omunchy-launch-webapp` (Chromium `--app=` mode,
  Wayland), so there is one place to later add launch-or-focus behaviour.
- TUI entries run via `xdg-terminal-exec` with app-id `omunchy.TUI.float` /
  `omunchy.TUI.tile`, so sway window rules can target floating/tiled TUIs
  (the shipped `looknfeel` floats `omunchy.TUI.float`).
- `omunchy theme set <name>` applies a theme from `config/themes/<name>.conf` —
  plain shell-sourceable `NAME=hex` fragments, no Lua, no per-app theming —
  rewriting the colour lines in foot/waybar/mako/rofi configs and the sway
  border colours, then restarting the bar and reloading sway. One ships:
  `omunchy-forest` (default, green from the shipped wallpaper); add your own
  as `~/.config/omunchy/themes/<name>.conf`.
- `omunchy bg set <image>` rewrites the swaybg exec line (WALLPAPER_MARKER)
  in `~/.config/sway/looknfeel`, applies it to the running session, then
  recolours the desktop from the image: `omunchy theme wallpaper` runs matugen
  (dark scheme), writes `~/.config/omunchy/themes/wallpaper.conf` and applies it
  like any other theme. `--no-theme` skips the recolour; without matugen the
  wallpaper still changes. `omunchy theme set omunchy-forest` goes
  back to a fixed palette.
- `omunchy update` refreshes mirrors with reflector (best-rated 5, skipped when
  offline), runs `pacman -Syu`, updates AUR packages via yay only when any are
  installed, and prompts to prune orphans — guarded by a lock so two updates
  cannot interleave.

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
airootfs/etc/skel/Scripts/omunchy                    dispatcher (emulates Omarchy's bin/omarchy)
airootfs/etc/skel/Scripts/omunchy-sync               batch-generate entries from config/ + link bins
airootfs/etc/skel/Scripts/omunchy-webapp-install     create a web app launcher (interactive when run bare)
airootfs/etc/skel/Scripts/omunchy-tui-install        create a TUI launcher (interactive when run bare)
airootfs/etc/skel/Scripts/omunchy-webapp-remove      remove a web app launcher (fzf or numbered picker)
airootfs/etc/skel/Scripts/omunchy-tui-remove         remove a TUI launcher (fzf or numbered picker)
airootfs/etc/skel/Scripts/omunchy-webapp-remove-all  remove every omunchy web app launcher
airootfs/etc/skel/Scripts/omunchy-tui-remove-all     remove every omunchy TUI launcher
airootfs/etc/skel/Scripts/omunchy-launch-webapp      Chromium --app= launcher used by web app entries
airootfs/etc/skel/Scripts/omunchy-sway-reload        reload the sway session config
airootfs/etc/skel/Scripts/omunchy-theme-set          switch the desktop colour theme
airootfs/etc/skel/Scripts/omunchy-bg-set             switch the wallpaper (rewrites the swaybg line)
airootfs/etc/skel/Scripts/omunchy-menu               rofi launcher menu (apps / web apps / TUIs / keybinds / autotiling / power)
airootfs/etc/skel/Scripts/omunchy-autotile           dwindle-style autotiling: start (exec_always) / toggle
airootfs/etc/skel/Scripts/omunchy-update             mirrors -> pacman -> yay -> orphan prune, lock-guarded
config/webapps.conf            Name|URL|Icon per line
config/tuis.conf               Name|Command|Style|Icon per line
config/themes/*.conf           theme palettes (omunchy-forest)
install.sh                     bootstrap: base stack + configs + sync (symlinks Scripts/omunchy* from the skel)
airootfs/                      archbang-derived archiso skeleton (sway skel config included)
docs/omarchy-parity.md         Omarchy feature parity analysis and decisions
.reference/                    upstream Omarchy scripts kept for reference (not committed)
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