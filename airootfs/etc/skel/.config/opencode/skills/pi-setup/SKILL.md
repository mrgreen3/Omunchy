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

Run the shipped installer script in its own foot window (detached, so the tool
call returns). It downloads the official installer, answers its prompts with
the defaults, bootstraps Node into the user's home if missing, and adds the PATH
lines. The user only watches; no input needed.

    setsid -f foot -e ~/Scripts/install-pi

Wait for the user to say the window has finished (it waits for a keypress at the
end), then verify. Installs to `~/.pi/agent/bin` and its own Node under
`~/.local/share/pi-node`. Remove by deleting `~/.pi/agent/bin` and
`~/.local/share/pi-node`.

## PATH

`install-pi` persists the PATH changes to `~/.bashrc`. They apply to new
terminals; until then call `~/.pi/agent/bin/pi` directly.

## Verify

Run `pi --version` and report the exact output.

## First run and auth

The user starts `pi` themselves and runs `/login` to connect a provider.
Never ask for keys in chat. Config lives in `~/.pi/agent`
(override `PI_CODING_AGENT_DIR`).

## Update

`install-pi` only reports the version when pi is already installed. To update, check `pi --help` for pi's own update command.
