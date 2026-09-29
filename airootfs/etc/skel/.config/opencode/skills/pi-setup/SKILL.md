---
name: pi-setup
description: Install the Pi coding agent ("pi") into the user's home directory with the official pi.dev installer. Use when the user asks to set up, install, or update Pi. No root, nothing outside the home directory.
---

# pi-setup

Pi is not in the Arch repos. Use the project's own installer from https://pi.dev;
it bootstraps the Node runtime it needs by itself, in the user's home, so do
not install `nodejs` or `npm`.

## 1. Check the ground

- Confirm network: `curl -fsS --max-time 6 -o /dev/null https://pi.dev`.
- Existing install: `command -v pi || ls ~/.pi/agent/bin/pi`, then
  `pi --version`. If it works and the user only wants an update, jump to "Update".
- On the live ISO, say the install is lost on reboot unless the system is
  installed to disk.

## 2. Install

    curl -fsSL https://pi.dev/install.sh -o /tmp/pi-install.sh
    sh /tmp/pi-install.sh

The installer reads its prompts from `/dev/tty`, so run it in the user's
terminal (not a captured subprocess) and let the user answer. It installs to
`~/.pi/agent/bin` and its own Node under `~/.local/share/pi-node`. Remove by
deleting `~/.pi/agent/bin` and `~/.local/share/pi-node`.

## PATH

The install is not on the current shell's PATH until a new login. Add after a
yes, to `~/.bashrc`:

    export PATH="$HOME/.pi/agent/bin:$HOME/.local/share/pi-node/current/bin:$PATH"

Until then call `~/.pi/agent/bin/pi` directly.

## Verify

Run `pi --version` and report the exact output.

## First run and auth

The user starts `pi` themselves and runs `/login` to connect a provider.
Never ask for keys in chat. Config lives in `~/.pi/agent`
(override `PI_CODING_AGENT_DIR`).

## Update

Re-run the installer, then `pi --version`.
