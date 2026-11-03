# omunchy

An Omarchy-inspired Arch live ISO built on [ArchBang](https://archbang.org). Boot it, try it from RAM,
and install it to disk offline with `obinstall`.

## Stack

All from the official Arch repos:

- **Compositor:** [mango](https://github.com/mangowm/mango) (dwl-based Wayland), dwindle tiling, `Super+V` toggles split
- **Bar:** Waybar
- **Shell services:** noctalia (notifications, launcher, control centre, lock, wallpaper and theme)
- **Menus:** Rofi (Omunchy menu, keybinds, AI agents, radio picker)
- **Terminal:** foot
- **Browser / web apps:** Firefox (web apps via `omunchy-webapp`, Firefox's built-in Taskbar Tabs)

Colours follow the wallpaper: noctalia re-themes the bar, panels, rofi, borders and foot.

## Omarchy-style layout

Like Omarchy, the system's own files are a git checkout in the user's home: `~/.local/share/omunchy`,
a shallow clone of this repo that the ISO build bakes in (no network needed to install). Its `bin/`
is on PATH and holds every `omunchy-*` command; `~/Scripts` is left empty for the user's own scripts.

- `omunchy-menu` (`Super+Alt+Space`): apps, install, remove, update, setup, system. On the live ISO it
  offers "Install Omunchy" instead of install/remove/update.
- `omunchy-update`: pulls `main` from GitHub, runs new `migrations/*.sh` once each
  (`omunchy-migrate`), adds new wallpapers, then updates packages (`omunchy-update-system`).
  Local edits in the checkout block it; it never touches them.
- `omunchy-install-*`: `gpu`, `snapper`, `yay`, and `ai <id>` for AI agents.
- `omunchy-install-ai` / `omunchy-remove-ai` / `omunchy-launch-ai`: AI agents from
  `default/agents.tsv` (Claude Code, OpenCode, Pi), installed user-local with mise, no npm.
  Users add rows in `~/.config/omunchy/agents.tsv`.
- `omunchy-pkg-add` / `-missing` / `-present`: pacman helpers for scripts.

## Usage

`obinstall` (in `/usr/local/bin`, live only) installs the running system:

```
omunchy-welcome            # live-boot network report (started by mango)
obinstall                  # install Omunchy to disk (copies this live system; no network needed)
obinstall --dry-run --config FILE   # print every step, touch nothing
```

`obinstall` is a gum wizard (keyboard, account, hostname, timezone, disk, optional LUKS2) with a
summary screen before anything is touched. It partitions the disk (GPT, 1 GiB ESP, btrfs with
`@ @home @log @pkg @snapshots`), copies the running live system to it
(tar | pv | tar, kernel from the ISO media, live-session changes synced), then converts the copy
into an installed system: user rename, mkinitcpio (systemd hooks, `sd-encrypt` for LUKS), greetd,
GRUB. It re-runs itself through sudo, so no need to prefix it. Source: `airootfs/usr/local/lib/obinstall/`.
The wizard's one password is used for the user, root and (if enabled) the LUKS disk. Encrypted installs
auto-login through greetd, so the disk passphrase at boot is the only gate to the session.
The installer builds a fresh pacman keyring offline (the live one is a tmpfs, so the copy has none).
If pacman later reports signature errors, run `omunchy-fix-keys` with a network connection (it also updates `archlinux-keyring`).

- **AI.** No agent is on the ISO: they install on the installed system only
  (`omunchy-install-ai opencode|claude|pi`, or the menu). `~/Documents/Guide.md` is the only
  instructions file for every agent (no AGENTS.md/CLAUDE.md); the `omunchy-guide` skill in
  `~/.config/omunchy/skills`, linked into `~/.agents/skills`, `~/.claude/skills` and
  `~/.config/opencode/skills`, points opencode, pi, Gemini CLI and Claude Code at it.
- **Live session.** `omunchy-welcome` (started by mango) shows a Super+K keybinds hint at login and a
  persistent warning with connection hints when offline, closing itself once a connection appears.

## Keybindings

The shipped `~/.config/mango/config.conf` mirrors Omarchy's bindings:
`Super+Return` foot, `Super+Space` launcher, `Super+Q` close,
`Super+Shift+F` fullscreen, `Super+T` float, `Super+V` toggle split, `Super+P` screenshot, `Super+L` lock,
`Super+Shift+E` power menu, `Super+Alt+Space` Omunchy menu, `Super+1..5` tags (workspaces),
XF86 audio/brightness via noctalia. The full list lives in
`Documents/Keybindings` (`Super+K` shows it in the launcher).

## Repo layout

```
bin/            omunchy-* commands (become ~/.local/share/omunchy/bin)
default/        shipped data, e.g. agents.tsv
migrations/     one-off upgrade steps run by omunchy-update (YYYYMMDD-HHMM-what.sh, rerun-safe)
airootfs/       archiso skeleton: skel configs, /usr/local/{bin,lib}/obinstall
build           vendored mkarchiso; bakes the bin/ checkout into skel (committed HEAD only)
docs/           design notes (rework-spec.md)
```

## Status

Release candidate. Installer verified in VMs (LUKS on BIOS and UEFI, non-LUKS UEFI); untested on real
hardware, so try it in a VM first.

## License

Omunchy is licensed under the [GNU General Public License v3.0](LICENSE).

It includes code adapted from [Omarchy](https://github.com/basecamp/omarchy)
(MIT, see [LICENSES/Omarchy-MIT.txt](LICENSES/Omarchy-MIT.txt)), and
`omunchy-install-gpu` is based on EndeavourOS's
[eos-hwtool](https://github.com/endeavouros-team/PKGBUILDS/tree/master/eos-hwtool) (GPL-3.0).
