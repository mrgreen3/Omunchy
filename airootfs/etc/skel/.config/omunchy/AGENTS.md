# Omunchy system

Arch Linux, MangoWC (Wayland), noctalia shell + waybar, foot, rofi. This is the
user's machine; act quickly on read-only checks, ask before changing anything.

## Where things are
- Mango: ~/.config/mango/config.conf (reload after edits: `mmsg dispatch reload_config`)
- Noctalia: ~/.config/noctalia; waybar: ~/.config/waybar; foot: ~/.config/foot; rofi: ~/.config/rofi
- Omunchy commands: ~/.local/share/omunchy/bin (on PATH); user tables in ~/.config/omunchy
- Full reference: ~/Documents/Guide.md (app installs via the omunchy-guide skill)
- Live ISO if /run/archiso/airootfs exists: you are read-only there (no edits, sudo blocked); diagnose and explain, the user runs fixes. Everything is lost on reboot

## Commands (prefer these over hand-rolled equivalents)
- `omunchy-netcheck` network check; run before any install, never curl one site
- `omunchy-update` pull Omunchy, run migrations, update packages
- `omunchy-pkg-present|missing <pkg...>` exit-code checks; `omunchy-pkg-add <pkg...>` install missing
- `omunchy-opencode [--web]` OpenCode in terminal or browser
- `omunchy-agents` / `omunchy-install-ai <id>` / `omunchy-remove-ai <id>` AI agents via mise
- `omunchy-extras` / `omunchy-install-extras <pkg>` / `omunchy-remove-extras <pkg>` curated Omarchy pkgs
- `omunchy-install-gpu`, `omunchy-install-snapper`, `omunchy-install-yay` one-shot setups
- `omunchy-webapp`, `omunchy-radio`, `omunchy-menu` (Super+Alt+Space), `omunchy-menu-keybinds` (Super+K)
- `omunchy-theme-refresh` re-render colours from noctalia's palette
- `mmsg` mango IPC: `mmsg get all-clients` / `get all-tags` state, `mmsg dispatch <action>,<args>`

## Rules
- Read-only inspection (pacman -Q, systemctl status, journalctl, lsblk, ip, mmsg get): just run it.
- Before any change: state the exact command and why, get a yes.
- sudo: always `sudo -A <cmd>`; a password box opens for the user. Never ask for passwords or keys in chat.
- pacman: official repos only; never `pacman -Sy` alone. AUR/yay only if the user asks.
- No global npm; no curl | sh (download to /tmp, then run).
- Interactive installers run in a new foot window, not this shell.
- Edit configs in place with a minimal diff; back up first (`cp f f.bak`) if replacing whole files.
- Never touch disks (dd, mkfs, wipefs, parted) or chain destructive commands.
