---
name: tuios-setup
description: Install the tuios terminal window manager on an Omunchy live or installed system. Use when the user asks to set up, install, or update tuios. Covers the official installer and the manual release-binary route with checksum verification, PATH, and verification.
---

# tuios-setup

tuios is a single binary and is not in the Arch repos.
Upstream: https://github.com/Gaurav-Gosain/tuios
It installs to `~/.local/bin/tuios` and needs no auth.

## 1. Check the ground

- Confirm network.
- Existing install: `command -v tuios && tuios --version`.
- Live ISO: warn that the install is lost on reboot unless Omunchy is on disk.

## 2. Preferred route — official installer

The project's script downloads a release, verifies it against the release's
`checksums.txt`, and installs to `~/.local/bin`.

    curl -fsSL https://raw.githubusercontent.com/Gaurav-Gosain/tuios/main/install.sh -o /tmp/tuios-install.sh
    bash /tmp/tuios-install.sh

Download first, then run; do not pipe into `bash`.

## 3. Manual route — release binary + checksum

Use this when the user wants to see every step, or the installer fails.

1. Find the latest tag from https://github.com/Gaurav-Gosain/tuios/releases.
   For x86_64 the asset is `tuios_<version>_Linux_x86_64.tar.gz`.
2. Download that tarball and `checksums.txt` from the same release into a temp
   directory.
3. Verify before installing:
   `grep 'tuios_.*_Linux_x86_64.tar.gz' checksums.txt | sha256sum -c -`
   Do not continue if it fails.
4. Extract just the binary and install it:
   `tar -xzf <tarball> tuios && install -Dm755 tuios ~/.local/bin/tuios`

## PATH

`~/.local/bin` must be on PATH. Check:

    case ":$PATH:" in *":$HOME/.local/bin:"*) echo ok;; *) echo missing;; esac

If missing, add this to `~/.bashrc` after a yes:

    export PATH="$HOME/.local/bin:$PATH"

New terminals pick it up; on the live ISO it is lost on reboot. In the current
session, call `tuios` by full path if PATH is not updated yet.

## Verify

Run `tuios --version` and report the exact output.

## First run

- The user runs `tuios`; it starts its daemon and TUI. No login or API key.
- Config lives in `~/.config/tuios/`.
- Optional: `tuios integration install <claude-code|codex|...>` wires a coding
  agent into tuios state tracking.

## Update

`tuios update` installs the newest release over the current binary.
