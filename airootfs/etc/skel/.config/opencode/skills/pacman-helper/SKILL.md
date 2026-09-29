---
name: pacman-helper
description: Safe pacman operations on Omunchy — install, search, remove, update, clean the cache, find file owners, check orphans, fix the keyring, and read the pacman log. Use when the user asks to install, remove, update, search for, or clean up packages, or when a pacman command fails.
---

# pacman-helper

Official Arch repos only. Never AUR, yay, or paru unless the user explicitly
asks for AUR — and confirm before continuing if they do.

## Hard rules

- Show the exact command, explain what it does, and get an explicit yes before
  any `sudo` command. Passwordless sudo does not remove the need to ask.
- Never add `--noconfirm` unless the user said yes to that specific command.
- Never run `pacman -Sy` alone. Partial upgrades break systems. Full updates
  only: `-Syu`.
- The live ISO runs from RAM: installs are lost on reboot unless Omunchy is
  installed to disk, and free space is limited. Warn before large installs.

## Install

1. Search: `pacman -Ss <term>`.
2. Inspect: `pacman -Si <pkg>` for version, repo, dependencies, download and
   installed size.
3. State the size and what will change, then get a yes.
4. Install: `sudo pacman -S <pkg>` (space-separate multiple packages).
5. Confirm: `pacman -Q <pkg>` and report the version.

## Search and inspect

- Installed: `pacman -Qs <term>`, `pacman -Qi <pkg>`.
- File owner: `sudo pacman -Fy` (syncs the file DB, needs network), then
  `pacman -F <path-or-name>`.
- Everything installed: `pacman -Q`.

## Remove

- Check impact first: `pacman -Qi <pkg>`, and `pacman -Qii <pkg>` for
  "Required By".
- Remove with dependencies and config: `sudo pacman -Rns <pkg>`.
- Orphans: list with `pacman -Qdt`. Remove only after showing the list and
  getting a yes: `sudo pacman -Rns $(pacman -Qdtq)`.

## Update

- Always a full sync + upgrade: `sudo pacman -Syu`. Never `-Sy` alone.
- Review the output: new kernel (reboot needed), packages removed, conflicts,
  and `.pacnew` files (`find /etc -name '*.pacnew'`).
- If pacman reports a conflict it cannot resolve, stop and report it; do not
  force it through.

## Cache

- `paccache -d` — dry run, shows what would be removed (no sudo).
- `paccache -r` — removes cached versions beyond the newest 3 (sudo).
- `sudo pacman -Sc` — removes cached packages no longer installed. Explain it
  is more aggressive and makes downgrades harder before running it.

## Keyring

If signature checks fail:

1. `sudo pacman-key --init`
2. `sudo pacman-key --populate archlinux`
3. `sudo pacman -Sy archlinux-keyring` — the one narrow exception to the
   no-`-Sy` rule: it installs a package, not a partial upgrade. `~/Scripts/fix-keys`
   does steps 1-3 if the user prefers.

If it still fails, report the exact error.

## Log

- `less /var/log/pacman.log` to read history.
- `grep <term> /var/log/pacman.log` to search it.
