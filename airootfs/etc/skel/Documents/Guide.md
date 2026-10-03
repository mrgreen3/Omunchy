 Omunchy Guide

Welcome to Omunchy, a lightweight Arch-based Wayland live ISO built around sway.

Note: Do not post Omunchy issues on the Arch Linux forums.

---

ABOUT OMUNCHY

Omunchy is Arch-based. The desktop is sway + waybar (bar) + mako
(notifications) + rofi (launcher) + foot (terminal), all from the official
Arch repos. It is delivered as a live ISO that runs from RAM/overlay;
persistent changes require the installer, obinstall.

- Live or installed: test for /run/archiso/airootfs.
  Present  = live: user "live", hostname "omunchy", passwordless sudo,
             changes are lost on reboot unless the system is installed.
  Absent   = installed: sudo asks for a password; changes persist.

- Configs: ~/.config/sway (config + binds + looknfeel + theme includes),
  ~/.config/{waybar,rofi,mako,foot}, ~/.config/opencode (settings, AGENTS.md,
  skills), ~/Documents (Guide, Keybindings, About), ~/Backgrounds.

- Theme: one fixed theme (omunchy-forest palette) in ~/.config/sway/theme;
  wallpaper set by swaybg in ~/.config/sway/looknfeel. There is no
  theme-switch command in the shipped scripts.

- Scripts: ~/Scripts is on PATH. obinstall (installer), fix-keys (pacman
  keyring), omunchy-welcome (live-session network report), screenshot,
  powermenu, omunchy-lock, updates.sh.

- Keybindings: full list in ~/Documents/Keybindings; Super+K opens it in rofi
  from inside the desktop. Super = Windows key.

---

PACMAN (LIVE SESSION)

Network required for pacman or browser use in the live session.

- Wired connections work automatically.
- Wireless: left-click the network icon in waybar, select network, enter password.

---

WORKSPACES AND LAYOUTS

sway arranges windows automatically in a tiling layout.

Switch workspaces with Super+1 through Super+5.
Toggle a window between floating and tiling with Super+T.

---

AI SETUP (OPENCODE)

The AI setup assistant is OpenCode. Open it from the rofi menu (Super+Space,
entry "OpenCode") or run:

opencode --standalone

It needs a network connection; it cannot reach its models offline. On the live
ISO, omunchy-welcome shows connection hints when offline, reports when a
connection appears, and — if started with AUTORUN=1 — opens OpenCode
automatically once online.

- If OpenCode answers with 401 / Invalid credential, run:

opencode auth login

  (browser login), or set OPENCODE_API_KEY in your own terminal, then retry.

- Rules the assistant follows (its config: ~/.config/opencode):

  - runs as `opencode --standalone` on this system
  - pacman: official repos only; never `pacman -Sy` alone (partial upgrade)
  - explains every command and asks before any sudo use
  - sudo has no terminal to ask on, so it is always written `sudo -A <cmd>`:
    a themed password box (rofi) opens for the user and the password goes
    straight to sudo, never through chat. See SUDO FROM OPENCODE below
  - no global npm/nodejs; user-local tools install under ~/.local or ~/.pi
    with their own installers (no sudo for those)
  - never pipes curl into a shell: downloads to /tmp, then runs
  - never runs chained destructive commands; never asks for API keys or
    passwords in chat
  - installers that need a real terminal (they read /dev/tty or ask
    questions: Pi, Hermes) are NEVER run in OpenCode's own shell, which has
    no terminal and makes them fail. Download to /tmp first, then open a
    foot window that runs the installer, and tell the user to answer its
    prompts there (see RUNNING AN INTERACTIVE INSTALLER in APPS)

- With no specific request, or when asked what can be set up, list the APPS
  subsections plus PACKAGES (BASIC PACKAGE USAGE), ask which one the user
  wants, one question at a time, and do nothing until they answer.
- Before any install: confirm the network is up, say what will be installed,
  roughly how big it is and whether it needs sudo, and warn that on the live
  ISO installs run from RAM and are lost on reboot.
- Per-app setup steps are in the APPS section below; the assistant reaches
  them via its omunchy-guide skill and follows this Guide.

---

APPS

One subsection per tool. Install methods come only from each tool's own
official sources. Fields marked TODO: verify have no verified source yet —
they are not guesses; do not fill them from memory.

RUNNING AN INTERACTIVE INSTALLER

Some installers need a real terminal: they read /dev/tty, ask questions or
show a menu. OpenCode's own shell has no terminal, so running them there
fails. For any app whose entry below says "Terminal: own foot window":

1. Download the installer to /tmp in OpenCode's shell (no terminal needed).
2. Open a new foot window that runs it, detached so OpenCode is not blocked:

  setsid -f foot -T "Install <APP>" sh -c 'sh /tmp/<installer>.sh; echo; echo "Finished. Press Enter to close this window."; read _'

   (use bash instead of sh where the entry says bash)
3. Tell the user a terminal window has opened, that they answer its prompts
   there, and to say when it has finished. Do not type into it for them and
   do not ask for keys or passwords in chat.
4. When the user confirms, run the entry's Verify command in OpenCode's shell.

If the foot window closes immediately or shows an error, ask the user to read
the message to you; do not retry blindly.

CLAUDE CODE

Anthropic's coding CLI for AI coding in the terminal. Not in the Arch repos.

What:   "claude" in the terminal; user wants an AI coding agent.
Install:  official installer — no Node, never with sudo (the script refuses):
  curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh
Terminal: own foot window — its setup step can draw a terminal UI, and the
          first run/login needs a real terminal too, so do not run it in
          OpenCode's own shell. Run it as in RUNNING AN INTERACTIVE INSTALLER:
  setsid -f foot -T "Install Claude Code" sh -c 'bash /tmp/claude-install.sh; echo; echo "Finished. Press Enter to close this window."; read _'
Location: ~/.local/bin/claude (files under ~/.local/share/claude/versions/;
          the installer downloads to ~/.claude/downloads first)
Needs:    network; roughly 512 MB of free memory to install (on the live ISO
          that is RAM: check free -m first and say so); first login inside
          Claude Code (run `claude` in a terminal, then /login — subscription
          or API key, entered in the tool, not in chat)
Verify:   claude --version
Update:   claude update
Remove:
  rm ~/.local/bin/claude
  rm -r ~/.local/share/claude
  (~/.claude holds settings, history and credentials: leave it unless the
  user asks to delete it)

PI (PI.DEV)

Pi, the coding agent from pi.dev. Not in the Arch repos.

What:   a second/multi-provider AI coding agent run from the terminal.
Install:  official installer — it bootstraps its own Node; do NOT install
          nodejs/npm:
  curl -fsSL https://pi.dev/install.sh -o /tmp/pi-install.sh
Terminal: own foot window — it reads /dev/tty, so running it directly in
          OpenCode fails. Run it as in RUNNING AN INTERACTIVE INSTALLER:
  setsid -f foot -T "Install Pi" sh -c 'sh /tmp/pi-install.sh; echo; echo "Finished. Press Enter to close this window."; read _'
Location: launcher on PATH (on Omunchy: ~/.local/bin/pi); package under
          ~/.pi/agent/install; bundled Node under ~/.local/share/pi-node
Needs:    network; provider login inside pi (/login)
Verify:   pi --version
Remove:
  rm -f ~/.local/bin/pi
  rm -r ~/.pi/agent ~/.local/share/pi-node

TUIOS

The tuios terminal window manager. Not in the Arch repos.
Upstream: https://github.com/Gaurav-Gosain/tuios

What:   IDE-like window management inside one terminal.
Install:  official installer (verifies the release against its checksums.txt):
  curl -fsSL https://raw.githubusercontent.com/Gaurav-Gosain/tuios/main/install.sh -o /tmp/tuios-install.sh
  bash /tmp/tuios-install.sh
Location: ~/.local/bin/tuios
Needs:    network; no login; config in ~/.config/tuios/
Verify:   tuios --version
Update:   tuios update
Remove:
  rm ~/.local/bin/tuios

HERDR

Herdr, the terminal workspace manager for coding agents. Not in the Arch repos.
Upstream: https://github.com/herdrdev/herdr

What:   run, organize and restore coding-agent sessions from one place.
Install:  official installer (manifest + SHA-256 check, https://herdr.dev/latest.json):
  curl -fsSL https://herdr.dev/install.sh -o /tmp/herdr-install.sh
  sh /tmp/herdr-install.sh
Location: ~/.local/bin/herdr
Needs:    network; no login; config in ~/.config/herdr/config.toml
Verify:   herdr --version
Update:   herdr update
Remove:
  rm ~/.local/bin/herdr

CLIAMP

Retro Winamp-style terminal music player. Not in the official repos.

What:   play local music and streams from the terminal.
Install:  vendor installer (verifies checksums, no sudo):
  curl -fsSL https://cliamp.stream/install.sh -o /tmp/cliamp-install.sh
  bash /tmp/cliamp-install.sh
Location: ~/.local/bin/cliamp, plus desktop entry, cliamp:// handler and icon
          under ~/.local/share
Needs:    network; ~/.local/bin on PATH. On an installed system, if a library
          is missing: sudo pacman -S --needed alsa-lib flac libvorbis libogg
          mpg123 ffmpeg yt-dlp (and pipewire-alsa for sound routing)
Verify:   cliamp --version
Update:   re-run the installer
Remove:
  rm -f ~/.local/bin/cliamp ~/.local/share/applications/cliamp.desktop \
        ~/.local/share/applications/cliamp-url-handler.desktop
  update-desktop-database ~/.local/share/applications
AUR alternative (only if the user asks for it): yay -S cliamp-bin
If the installer URL fails, check https://cliamp.stream; do not improvise.

DEV ENVIRONMENT

git and a compiler, plus whichever language the user asks for, all from the
official repos. Ask which languages are wanted (node, python, go, rust, ruby,
or just git and a compiler); install nothing nobody asked for. Runtimes are
large: say so, especially on the live ISO.

Install:  sudo pacman -S --needed git base-devel     (base-devel only for builds)
  then the runtime, e.g. sudo pacman -S nodejs npm | python | go | rust
Needs:    network
Verify:   <tool> --version
Git identity (optional; name and email are not secrets):
  git config --global user.name "<name>"
  git config --global user.email "<email>"
  For GitHub/Codeberg, the user makes a key with ssh-keygen -t ed25519 and
  adds the public key themselves. Never ask for tokens or private keys.

YAY / AUR

Only when the user explicitly asks for AUR support. Nothing in Omunchy needs
it. AUR packages are community-built and unreviewed by Arch: review the
PKGBUILD, never answer prompts blindly. On the live ISO, building needs
base-devel + git (hundreds of MB in RAM) and is lost on reboot.

Install:  ~/Scripts/install-yay   (use the full path; the user can run it, or
          the assistant can on the live ISO). It checks the network, installs base-devel and git with
          pacman, builds yay from the AUR, then removes the go package it
          needed for the build (so a go installed earlier is removed too).
Needs:    network; sudo for the pacman and makepkg steps
On an installed system sudo asks for a password, which the assistant cannot
type: the user runs ~/Scripts/install-yay themselves in a terminal.
Verify:   yay --version
Remove:
  sudo pacman -Rns yay        (then base-devel/git if nothing else needs them)

GEMINI CLI

Google's open-source coding agent for the terminal. A Google account sign-in
includes a free usage allowance (limits are Google's and can change).

What:   Gemini-powered coding assistant; a good free option to try.
Install:  pacman, official repo (extra); it pulls in nodejs as a dependency:
  sudo pacman -S gemini-cli
Location: /usr/bin/gemini
Needs:    network; Google account sign-in on first run (browser), or a
          GEMINI_API_KEY entered in your own terminal
Verify:   gemini --version
Update:   with the system (pacman -Syu)
Remove:
  sudo pacman -Rns gemini-cli

HERMES

A self-hosted agent harness (Nous Research) with memory, scheduled jobs and a
messaging gateway. It runs background services, so install it on an INSTALLED
system only. Do not set it up in the live session: everything is lost on
reboot and the services have nothing persistent to run on.

What:   long-running personal agent with tools, memory and a gateway.
Install:  official installer, user-local, interactive (it asks questions
          and sets up a gateway service):
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh -o /tmp/hermes-install.sh
Terminal: own foot window — run it as in RUNNING AN INTERACTIVE INSTALLER:
  setsid -f foot -T "Install Hermes" sh -c 'bash /tmp/hermes-install.sh; echo; echo "Finished. Press Enter to close this window."; read _'
Location: ~/.hermes (checkout in ~/.hermes/hermes-agent, config in
          ~/.hermes/config.yaml, keys in ~/.hermes/.env); command in
          ~/.local/bin
Needs:    network; an LLM provider key entered inside Hermes setup
Verify:   command -v hermes
Update:   TODO: verify
Remove:   TODO: verify (do not delete ~/.hermes blindly: it holds your
          memory, sessions and keys; stop its gateway service first)

ADD A NEW APP — use this template; fill only from the tool's official docs:

<APP NAME> (<one line: what it is, when a user wants it>)
Install:  official installer URL or pacman package (never curl-into-shell:
          download to /tmp first, then run)
Terminal: only if it reads /dev/tty or asks questions: "own foot window" and
          the setsid -f foot command (see RUNNING AN INTERACTIVE INSTALLER)
Location: exact install path (user-local, e.g. ~/.local/bin; ~/.pi for pi)
Needs:    network, login/API key (entered only inside the tool), PATH edits
Verify:   one command that proves it worked (usually --version)
Remove:   exact removal from the same paths the installer used

Fields without a verified official source stay marked TODO: verify.

---

INSTALLATION

The installer (obinstall) is a step-by-step wizard and shows a summary before
it touches anything. Open a terminal (foot) and run:

obinstall

It asks for root itself (sudo). obinstall is interactive and will erase the
disk you select. Run it yourself, and back up first.

Note: the older right-click / rofi-menu "Install" route is not currently
available — no installer .desktop file ships with the system.

---

POST-INSTALLATION

SUDO

Installed system requires password for sudo. Live session used passwordless sudo
for convenience — installed system does not.

SUDO FROM OPENCODE

OpenCode's shell has no terminal, so plain sudo cannot ask for the password.
Use sudo's askpass mode: SUDO_ASKPASS is already set (via /etc/environment) to
/usr/local/bin/omunchy-askpass, which opens a password box for the user.

  sudo -A pacman -S <package>

If SUDO_ASKPASS is empty in the current shell, give it explicitly:

  SUDO_ASKPASS=/usr/local/bin/omunchy-askpass sudo -A pacman -S <package>

Rules:
- State the exact command and why, and get a yes, BEFORE running it. The
  password box also shows the command sudo is about to run (read from sudo
  itself, so it cannot differ from what really runs); ask the user to check it
  matches what was agreed. The box only appears when sudo needs a password:
  inside the five-minute window below there is no box and no check.
- Tell the user a password box is about to appear. They type the password into
  it; it never goes through chat, and the assistant never sees it.
- sudo remembers a successful password for about five minutes: further
  `sudo -A` commands in that window will not prompt. Treat each one as needing
  the same care and say so.
- Never run /usr/local/bin/omunchy-askpass directly (it refuses unless sudo
  calls it) and never try to read, print or work around the password.
- If the user cancels the box (Esc) or it does not appear, stop and ask; do
  not retry blindly.
- On the live ISO (passwordless sudo) `sudo -A` simply runs without a prompt.
- Long or interactive root commands can still be run in a foot window instead
  (see RUNNING AN INTERACTIVE INSTALLER).

---

INITIALIZE PACMAN

The live session sets up pacman keys automatically (part of archiso). On a
newly installed system, set up the keys and keyring afresh before first use:

fix-keys

This creates keys, refreshes the package cache, and updates archlinux-keyring.
It is the one exception to the "no `pacman -Sy` alone" rule: it installs
archlinux-keyring itself.

---

BASIC PACKAGE USAGE

Official Arch repos only. Show the exact command, explain it, and get a yes
before any sudo command (passwordless sudo on live does not remove that).
In OpenCode write sudo as `sudo -A` (see SUDO FROM OPENCODE); the commands
below are shown as plain sudo for readability.
No --noconfirm unless agreed for that command. Never pacman -Sy alone; full
updates only (-Syu). The live ISO runs from RAM: warn before large installs.

Search:   pacman -Ss <package-name>   (no sudo needed to search)
Inspect:  pacman -Si <package-name>   (repo, dependencies, download and
          installed size; state the size before installing)
Install:  sudo pacman -S <package-name>
Confirm:  pacman -Q <package-name>
Installed: pacman -Qs <term>   pacman -Qi <package-name>   pacman -Q
File owner: sudo pacman -Fy (needs network), then pacman -F <path-or-name>
Remove:   check pacman -Qi / pacman -Qii <package-name> ("Required By"), then
          sudo pacman -Rns <package-name>
Orphans:  pacman -Qdt; remove only after showing the list and getting a yes:
          sudo pacman -Rns $(pacman -Qdtq)
Update:   sudo pacman -Syu. Review: new kernel (reboot), removed packages,
          conflicts, .pacnew files (find /etc -name '*.pacnew'). If a conflict
          cannot be resolved, stop and report it; do not force it.
Cache:    paccache -d (dry run), sudo paccache -r (keep newest 3),
          sudo pacman -Sc (more aggressive; explain first)
Log:      less /var/log/pacman.log    grep <term> /var/log/pacman.log
Keys:     if signature checks fail, run fix-keys (see INITIALIZE PACMAN)
AUR:      only on explicit request; see YAY / AUR.

---

CONSOLE KEYBOARD LAYOUT

obinstall sets the raw tty console (rescue mode, the disk-unlock prompt,
before sway starts) to the keyboard layout chosen in its wizard, and sway's
layout is derived from the same choice. To change the console layout afterwards:

sudo nano /etc/vconsole.conf   # set KEYMAP=<layout>, e.g. KEYMAP=uk
sudo mkinitcpio -P             # regenerate initramfs to pick it up

List available layouts with: localectl list-keymaps

---

MICROCODE

Omunchy includes both intel-ucode and amd-ucode. You only need one.

If you remove the unused one after installation, update your bootloader config
(regenerate GRUB or edit loader.conf) before rebooting.

---

INTEL GRAPHICS

Omunchy uses Wayland with sway, which relies on kernel modesetting via Mesa.
No additional Intel drivers needed — built-in kernel drivers handle acceleration.

---

LIVE SESSION DISK SPACE

If the live session runs out of space:

sudo mount -o remount,size=8G /run/archiso/cowspace

---

NEED HELP?

Arch Wiki: https://wiki.archlinux.org

---

Copyright 2025 Omunchy
