---
name: setup-menu
description: Entry point for the Omunchy live-session setup assistant. Use at the start of a session, or when the user says "setup", "what can you do", "help me set up", or otherwise asks what is available. Presents a numbered menu, then hands off to the matching skill.
---

# setup-menu

You are the entry point. Show the options, find out what the user wants, then
load the matching skill. Ask one question at a time.

## Present the menu

Say what you can help install or configure, as a numbered list:

1. **Claude Code** — Anthropic's coding CLI (`claude-code-setup`)
2. **Pi** — the Pi coding agent (`pi-setup`)
3. **tuios** — terminal window manager (`tuios-setup`)
4. **Herdr** — workspace manager for coding agents (`herdr-setup`)
5. **Packages** — install, search, remove, update, clean, keyring (`pacman-helper`)
6. **Something else** — let the user describe it

Then ask which one they want. Do not act until they answer.

## Before doing anything

- Confirm the network is up (`ping -c1 -W2 1.1.1.1` or a quick `curl`).
- Say plainly: this is a live ISO, installs run from RAM/overlay and are lost
  on reboot unless Omunchy is installed to disk.
- Explain what will be installed, roughly how big it is, and whether it needs
  sudo. Get sizes from `pacman -Si <pkg>` for repo packages, or state the
  tool's own download size for a release binary.
- For anything with sudo, show the exact command and get an explicit yes.

## Hand off

- Load the chosen skill and follow its steps. Never improvise root commands
  when a skill covers the task.
- If the user already named a tool ("install pi"), skip the menu and go
  straight to that skill.
- "Something else": ask one question to learn the goal. Do what official repos
  and safe user-space installs allow; say clearly what you cannot do.

## Rules

- Never ask for API keys, passwords, or tokens in chat. Point the user at the
  tool's own login step.
- Never pipe `curl` into a shell: download the installer to /tmp, then run it.
- User-local tools (claude-code, pi, tuios, herdr) install into the home
  directory with their own installers: no sudo, no nodejs/npm.
- pacman: official repos only unless the user explicitly asks for AUR.
- Never `pacman -Sy` alone.
