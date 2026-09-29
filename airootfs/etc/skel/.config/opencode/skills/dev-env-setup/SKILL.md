---
name: dev-env-setup
description: Set up a development environment on Omunchy — git, a compiler toolchain, and language runtimes (node, python, go, rust, ruby, ...) installed user-local through mise. Use when the user asks to set up a dev environment, install a language or runtime, "get me coding", or needs build tools.
---

# dev-env-setup

Goal: a working dev environment with as little system change as possible.
System tools (git, compiler) come from pacman; language runtimes come from
`mise` into `~/.local`, so no nodejs/npm/python packages and nothing global.
Upstream: https://mise.jdx.dev

## 1. Find out what they need

Ask one question: which languages or tools? Offer: node, python, go, rust,
ruby, or "just git and a compiler". Do not install a language nobody asked for.

## 2. Check the ground

- Confirm network.
- Live ISO: warn that installs are lost on reboot unless Omunchy is on disk,
  and that runtimes are large (node ~100 MB, go ~250 MB, rust ~1 GB).
- Check what exists: `command -v git gcc make mise`, `mise --version`.

## 3. System basics (pacman, needs sudo)

Only what is missing. Follow `pacman-helper`: `pacman -Si` for sizes, show the
exact command, get a yes.

- `git` — version control.
- `base-devel` — gcc, make, and friends; needed to build native extensions and
  AUR-style packages. Skip if the user only wants interpreted languages.

## 4. mise (user-local, no sudo)

Skip if `mise` is already installed.

    curl -fsSL https://mise.run -o /tmp/mise-install.sh
    less /tmp/mise-install.sh   # offer the user a look
    sh /tmp/mise-install.sh

Download first, then run; do not pipe into a shell. It installs to
`~/.local/bin/mise`. Ensure `~/.local/bin` is on PATH, and activate mise in
new shells after a yes:

    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

In the current session call `~/.local/bin/mise` by full path.

## 5. Runtimes

Per requested language, state the download size, then:

    mise use --global node@lts
    mise use --global python@latest
    mise use --global go@latest
    mise use --global rust@latest

`mise use --global` writes `~/.config/mise/config.toml`. Pinned per-project
versions belong in the project: run `mise use <tool>@<ver>` inside its folder.
Use `mise ls-remote <tool>` to show available versions if asked.

## 6. Git identity (optional)

Ask for name and email in chat, then set them; these are not secrets:

    git config --global user.name "<name>"
    git config --global user.email "<email>"

For GitHub/Codeberg auth, point the user at `ssh-keygen -t ed25519` and let
them add the public key themselves. Never ask them to paste tokens or private
keys.

## Verify

Run `<tool> --version` for each installed runtime (via `mise exec -- <tool>
--version` if the shell is not activated yet) and report the exact output.

## Rules

- No sudo without showing the command and getting a yes.
- No nodejs/npm/python/go/rust packages from pacman; runtimes go through mise.
- No AUR. Never `pacman -Sy` alone.
