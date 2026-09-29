---
name: herdr-setup
description: Install the Herdr terminal workspace manager ("herdr") on an Omunchy live or installed system. Use when the user asks to set up, install, or update Herdr. Covers the official installer and the manual release-binary route with checksum verification, PATH, and verification.
---

# herdr-setup

Herdr is a single binary and is not in the Arch repos.
Upstream: https://herdr.dev and https://github.com/herdrdev/herdr
It installs to `~/.local/bin/herdr` and needs no auth.

## 1. Check the ground

- Confirm network.
- Existing install: `command -v herdr && herdr --version`.
- Live ISO: warn that the install is lost on reboot unless Omunchy is on disk.
- Package-manager installs exist on Homebrew, mise, and Nix, but not on
  Omunchy — use the routes below.

## 2. Preferred route — official installer

The installer fetches the release manifest from `https://herdr.dev/latest.json`,
verifies the download against its SHA-256, and installs to `~/.local/bin`
(override the location with `HERDR_INSTALL_DIR`).

    curl -fsSL https://herdr.dev/install.sh -o /tmp/herdr-install.sh
    sh /tmp/herdr-install.sh

Download first, then run; do not pipe into `sh`.

## 3. Manual route — release binary + checksum

1. Read `https://herdr.dev/latest.json`: take the `linux-x86_64` asset URL and
   its `sha256` value.
2. Download the asset, e.g.
   `curl -fLo /tmp/herdr https://github.com/herdrdev/herdr/releases/download/v<version>/herdr-linux-x86_64`
3. Verify before installing:
   `echo "<sha256>  /tmp/herdr" | sha256sum -c -`
   Do not continue if it fails.
4. `install -Dm755 /tmp/herdr ~/.local/bin/herdr`

## PATH

`~/.local/bin` must be on PATH. Check:

    case ":$PATH:" in *":$HOME/.local/bin:"*) echo ok;; *) echo missing;; esac

If missing, add this to `~/.bashrc` after a yes:

    export PATH="$HOME/.local/bin:$PATH"

New terminals pick it up; on the live ISO it is lost on reboot. In the current
session, call `herdr` by full path if PATH is not updated yet.

## Verify

Run `herdr --version` and report the exact output.

## First run

- The user runs `herdr` to launch or attach; no login or API key.
- Config: `~/.config/herdr/config.toml`.
- Optional: `herdr integration install claude` adds native session restore for
  Claude Code. Full guide: https://herdr.dev/docs/install/

## Update

`herdr update` (stable channel by default).
