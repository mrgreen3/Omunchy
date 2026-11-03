 Omunchy Guide

Welcome to Omunchy, a lightweight Arch-based Wayland live ISO built around mango.

Note: Do not post Omunchy issues on the Arch Linux forums.

---

ABOUT OMUNCHY

Omunchy is Arch-based. The desktop is mango + waybar (bar) + noctalia
(notifications, launcher) + foot (terminal), all from the official
Arch repos. It is delivered as a live ISO that runs from RAM/overlay;
persistent changes require the installer, obinstall.

- Live or installed: test for /run/archiso/airootfs.
  Present  = live: user "live", hostname "omunchy", passwordless sudo,
             changes are lost on reboot unless the system is installed.
  Absent   = installed: sudo asks for a password; changes persist.

- Configs: ~/.config/mango/config.conf,
  ~/.config/{waybar,noctalia,foot}, ~/.config/opencode (settings),
  ~/.config/omunchy/skills (the omunchy-guide skill, shared by opencode, pi,
  Gemini CLI and Claude Code; it points them at this Guide), ~/Documents (Guide, Keybindings, About), ~/Backgrounds.

- Theme: colours follow the wallpaper. Change the wallpaper in noctalia and the
  bar, panels, rofi, window borders and new foot windows re-colour to match
  (noctalia [theme] source = "wallpaper" in ~/.config/noctalia/config.toml).
  Default wallpaper: [wallpaper.default] in the same file; more in ~/Backgrounds.

- Updating: omunchy-update (or Super+Alt+Space > Update > Omunchy) pulls
  Omunchy's own files from github.com/mrgreen3/Omunchy, runs any one-off
  migrations, adds new wallpapers, then updates packages (pacman -Syu).
  Installed system only. Never edit files in ~/.local/share/omunchy: local
  edits block the update; put your own versions in ~/Scripts.
  omunchy-update --no-packages skips pacman; the waybar update badge runs
  only the pacman step.

- Omunchy menu: Super+Alt+Space (or omunchy-menu) reaches every Omunchy
  action: apps, install, remove, update, setup, system. On the live ISO it
  offers "Install Omunchy" and hides installs and AI agents.

- Commands: Omunchy's own commands are omunchy-* in ~/.local/share/omunchy/bin
  (on PATH, a git checkout updated by omunchy-update). ~/Scripts is also on
  PATH and is the user's own: put personal scripts there. obinstall (the
  installer, live only) is in /usr/local/bin.

- Keybindings: full list in ~/Documents/Keybindings; Super+K opens it in the launcher
  from inside the desktop. Super = Windows key.

---

PACMAN (LIVE SESSION)

Network required for pacman or browser use in the live session.

- Wired connections work automatically.
- Wireless: left-click the network icon in waybar, select network, enter password.

---

WORKSPACES AND LAYOUTS

mango arranges windows automatically in a dwindle tiling layout.

Switch workspaces (tags) with Super+1 through Super+5.
Toggle a window between floating and tiling with Super+T.

---

AI SETUP (OPENCODE)

The AI setup assistant is OpenCode. It is not on the ISO and is offered on the
installed system only (installed live, it would be lost on reboot). Once
connected: "Install AI Agent" in the launcher (Super+Space), or
Super+Alt+Space > Install > AI agent, or run:

omunchy-install-ai opencode

It installs with mise like the other agents (see MISE) and adds an "OpenCode"
entry to the launcher (Super+Space), or run `opencode --standalone`.

On the live ISO, omunchy-welcome shows connection hints when offline.

- If OpenCode answers with 401 / Invalid credential, run:

opencode auth login

  (browser login), or set OPENCODE_API_KEY in your own terminal, then retry.

- Rules every AI assistant follows (opencode, pi, Claude Code, Gemini CLI;
  this Guide is their only instructions file; opencode settings: ~/.config/opencode):

  - runs as `opencode --standalone` on this system
  - pacman: official repos only; never `pacman -Sy` alone (partial upgrade)
  - explains every command and asks before any sudo use
  - sudo has no terminal to ask on, so it is always written `sudo -A <cmd>`:
    a themed password box (rofi) opens for the user and the password goes
    straight to sudo, never through chat. See SUDO FROM OPENCODE below
  - no global npm/nodejs; user-local tools install under ~/.local or ~/.pi
    with their own installers (no sudo for those)
  - never pipes curl into a shell: downloads to /tmp, then runs
  - installs each app the way its APPS entry says, even when yay is
    installed (yay/AUR only when the user explicitly asks for the AUR); if
    that method fails, says so and asks, never falls back to the AUR
  - never runs chained destructive commands; never asks for API keys or
    passwords in chat
  - installers that need a real terminal (they read /dev/tty or ask
    questions, e.g. `hermes setup`) are NEVER run in OpenCode's own shell, which has
    no terminal and makes them fail. Download to /tmp first, then open a
    foot window that runs the installer, and tell the user to answer its
    prompts there (see RUNNING AN INTERACTIVE INSTALLER in APPS)

- With no specific request, or when asked what can be set up, list the APPS
  subsections plus PACKAGES (BASIC PACKAGE USAGE), ask which one the user
  wants, one question at a time, and do nothing until they answer.
- Before any install: run `omunchy-netcheck` to confirm the network is up (exit 0 and
  "Network OK"; otherwise it says what is wrong: no route, DNS failing, no
  internet, or a login page to sign in to). Never test with curl against one
  site such as archlinux.org. Then say what will be installed,
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

MISE (AI AGENTS)

Claude Code, OpenCode and Pi install with mise, which ships with Omunchy:
`omunchy-install-ai <claude|opencode|pi>` (or "Install AI Agent" in the
launcher, or Super+Alt+Space > Install > AI agent) and `omunchy-remove-ai <id>`. The table of agents is
~/.local/share/omunchy/default/agents.tsv; the user can add rows (same
tab-separated format) in ~/.config/omunchy/agents.tsv. The other agents below
(Codex, Hermes, Crush, Goose, Copilot) also install with mise, by hand, as
their entry says. Everything goes into the user's home
(~/.local/share/mise, list in ~/.config/mise/config.toml): no sudo, no system
files, no nodejs/npm (OpenCode uses mise's aqua backend, not npm). Gemini CLI
is the exception: pacman.

Installed system only: on the live ISO the installs fill RAM and are lost on
reboot (check with `[ -d /run/archiso/airootfs ]`; if it exists, say the
agents are available after installing Omunchy with obinstall, and stop).

- mise puts tools on PATH through the activate line in ~/.bashrc: after an
  install, the user opens a new terminal (or runs `exec bash`).
- First run and login (`claude`, `pi`, ... ) need a real terminal: tell the
  user to run it in a foot window, not in OpenCode's shell.
- Logins and API keys are entered inside each tool, never in chat. Each tool
  keeps its own settings (~/.claude, ~/.pi, ~/.codex, ...): leave those unless
  the user asks to delete them.
- Launcher: each agent installed with omunchy-install-ai gets its own entry in
  the launcher (Super+Space), named after it (omunchy-ai-<id>.desktop);
  omunchy-remove-ai removes it. "Install AI Agent" in the launcher lists the
  agents not installed yet.
- `mise ls` lists what is installed; `mise upgrade` updates them all.
- Sizes: Codex is the largest (about 200 MB download). After installing, `mise cache clear` frees the download cache.

CLAUDE CODE

Anthropic's coding CLI for AI coding in the terminal.

What:   "claude" in the terminal; user wants an AI coding agent.
Install:  omunchy-install-ai claude (mise, installed system only; see MISE;
          same as: mise use -g claude@latest)
Command:  claude
Needs:    network; login inside Claude Code (run `claude`, then /login — subscription
          or API key, entered in the tool)
Verify:   claude --version
Update:   mise upgrade claude
Remove:   omunchy-remove-ai claude (keeps its own settings)

PI (PI.DEV)

Pi, the coding agent from pi.dev.

What:   a second/multi-provider AI coding agent run from the terminal.
Install:  omunchy-install-ai pi (mise, installed system only; see MISE;
          same as: mise use -g pi@latest)
Command:  pi
Needs:    network; provider login inside pi (/login)
Verify:   pi --version
Update:   mise upgrade pi
Remove:   omunchy-remove-ai pi (keeps its own settings)

CODEX

OpenAI's coding agent for the terminal.

What:   ChatGPT/OpenAI-powered coding agent.
Install:  mise (installed system only; see MISE):
  mise use -g codex@latest
Command:  codex
Needs:    network; ChatGPT sign-in or OpenAI API key, inside codex
Verify:   codex --version
Update:   mise upgrade codex
Remove:
  mise unuse -g codex
  mise uninstall codex

CRUSH

Charm's terminal AI coding agent (multi-provider).

What:   a polished TUI coding agent; works with many providers.
Install:  mise (installed system only; see MISE):
  mise use -g crush@latest
Command:  crush
Needs:    network; provider API key, entered inside crush
Verify:   crush --version
Update:   mise upgrade crush
Remove:
  mise unuse -g crush
  mise uninstall crush

GOOSE

Goose, an open-source extensible AI agent (originally from Block).

What:   local-first agent with extensions (MCP); many providers.
Install:  mise (installed system only; see MISE):
  mise use -g goose-agent@latest
Command:  goose
Needs:    network; provider setup inside goose (`goose configure`)
Verify:   goose --version
Update:   mise upgrade goose-agent
Remove:
  mise unuse -g goose-agent
  mise uninstall goose-agent

GITHUB COPILOT CLI

GitHub's Copilot coding agent for the terminal.

What:   Copilot in the terminal; needs a GitHub Copilot plan.
Install:  mise (installed system only; see MISE):
  mise use -g copilot@latest
Command:  copilot
Needs:    network; GitHub sign-in inside copilot (/login)
Verify:   copilot --version
Update:   mise upgrade copilot
Remove:
  mise unuse -g copilot
  mise uninstall copilot

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
AUR alternative: ONLY if the user explicitly asks for the AUR version (yay -S cliamp-bin),
never just because yay is installed.
If the installer URL fails, check https://cliamp.stream; do not improvise.

DEV ENVIRONMENT

git and a compiler, plus whichever language the user asks for, all from the
official repos. Ask which languages are wanted (node, python, go, rust, ruby,
or just git and a compiler); install nothing nobody asked for. Runtimes are
large: say so, especially on the live ISO.

Install:  sudo pacman -S --needed base-devel     (git is already installed; base-devel
          is only for real source builds)
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
it. Having yay installed does NOT change that: it is not a request to install
other apps from the AUR. Use each app's own Install line in this Guide (its
official installer, or pacman) even when yay is present; reach for yay only
when the user asks for a specific package from the AUR. If the Guide's method
fails, report it and ask, do not fall back to the AUR.

AUR packages are community-built and unreviewed by Arch: review the PKGBUILD,
never answer prompts blindly. On the live ISO, installs are lost on reboot.

Install:  ~/.local/share/omunchy/bin/omunchy-install-yay   (use the full path). It installs yay-bin, the
          prebuilt upstream release of yay (its checksum is pinned in the AUR
          PKGBUILD). It first installs base-devel and git, which building any
          AUR package needs (a few hundred MiB, mostly gcc); yay itself is not
          compiled, no go.
          ~/.local/share/omunchy/bin/omunchy-install-yay --source builds yay from source instead: it
          also needs go (about 0.75 GiB of RAM at peak on the live ISO) and
          removes go afterwards only if the script itself added it.
Needs:    network; sudo. Run without a terminal (as the assistant does), the
          script uses `sudo -A` itself, so the password goes into the askpass
          box (see SUDO FROM OPENCODE): say first which pacman commands will
          run as root; the password is remembered for about five minutes, so
          usually the box appears once. Run in a terminal, it just asks in
          that terminal. This is mostly needed on an installed system, where
          sudo asks for a password.
Verify:   yay --version
Remove:
  sudo pacman -Rns yay-bin      (yay, if it was built with --source)

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
messaging gateway. Installed system only (see MISE).

What:   long-running personal agent with tools, memory and a gateway.
Install:  mise, from PyPI (needs uv, also via mise):
  mise use -g uv@latest
  mise use -g pipx:hermes-agent@latest
Setup:    interactive: open a new foot window and run `hermes setup` there
          (provider key and optional gateway are entered in Hermes, not chat)
Location: data, config and keys in ~/.hermes (config.yaml, .env)
Needs:    network; an LLM provider key entered inside Hermes setup
Verify:   hermes --version
Update:   mise upgrade pipx:hermes-agent
Remove:   stop its gateway service first if set up; then
  mise unuse -g pipx:hermes-agent
  mise uninstall pipx:hermes-agent
  (do not delete ~/.hermes blindly: it holds memory, sessions and keys)

WEB APPS

Sites as launchable apps, using Firefox's built-in web apps in one shared
profile. Ships with Omunchy; nothing to install.

What:   each app opens in its own window with its own app id
        (firefox.webapp-<id>); the main Firefox profile is not touched.
Use:
  omunchy-webapp presets        (Arch News, Arch Wiki, Arch Packages, Omunchy;
                                 list in ~/.config/omunchy-webapp/presets.conf)
  omunchy-webapp add <name> <url> [icon]
  omunchy-webapp list
  omunchy-webapp remove <name>
Location: ~/.local/share/omunchy/bin/omunchy-webapp; launchers in ~/.local/share/applications/
          (omunchy-webapp-*.desktop), shared profile and icons in
          ~/.local/share/omunchy-webapp/
Needs:    network for the site and its icon; close all web app windows
          before add or remove
Verify:   omunchy-webapp list
Notes:    web apps share one profile, so a login in one is a login in all
          and separate from the main Firefox. Links to other sites open in
          a normal window of that profile.

RADIO

Internet radio player in the terminal (fzf + mpv). Ships with Omunchy;
nothing to install. Super+M drops it down (again to hide), or
Super+Space > Radio, or run "omunchy-radio".

Use (in the app):
  type          filter the station list
  enter         play the selected station
  ctrl-s        stop
  ctrl-a        add a station: give it a name, then the stream URL
  ctrl-d        delete the selected station
  ctrl-f        search the radio-browser.info directory (online); enter
                adds the station and plays it
  esc           close the app; the station keeps playing
Use (command line):
  omunchy-radio play "<name>"   omunchy-radio stop | now | list
Add stations by hand: edit ~/.config/radio/stations, one per line as
  Name|URL
  e.g. SomaFM Space Station Soma|https://somafm.com/spacestation.pls
  The URL can be a direct stream (http/https), a .pls or a .m3u link —
  most station websites list one under "listen" or "player links".
Location: ~/.local/share/omunchy/bin/omunchy-radio; stations in ~/.config/radio/stations
Needs:    network; mpv (installed)
Verify:   omunchy-radio list
Notes:    playback shows in the media controls with the current song.

KEW

Local music player in the terminal: album art, visualiser, gapless
playback. Ships with Omunchy; nothing to install. Plays files only, not
internet streams (use RADIO for those). Launcher: Super+Space > kew.

Use:
  kew                   open the library (~/Music)
  kew <artist|album|song>   play the first match from ~/Music
  kew all               shuffle the whole library
In the app: space play/pause, left/right previous/next, +/- volume,
  F2 playlist, F3 library, F4 track view, F5 search, F6 help, q quit.
Location: /usr/bin/kew; config in ~/.config/kew/kewrc
Needs:    music files in ~/Music (change with: kew path <folder>)
Verify:   kew --version

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
it touches anything. Press Super+I, pick "Install Omunchy" in the Omunchy
menu (Super+Alt+Space), or open a terminal (foot) and run:

obinstall

obinstall opens its own opaque foot window so the wizard text is easy to read
(normal terminals stay translucent), then asks for root itself (sudo). It is
interactive and will erase the disk you select. Run it yourself, and back up
first.

Note: the older right-click / launcher "Install" route is not currently
available — no installer .desktop file ships with the system.

---

POST-INSTALLATION

SUDO

Installed system requires password for sudo. Live session used passwordless sudo
for convenience — installed system does not.

SUDO FROM OPENCODE

OpenCode's shell has no terminal, so plain sudo cannot ask for the password.
Use sudo's askpass mode: SUDO_ASKPASS is already set (by ~/.bash_profile) to
~/.local/share/omunchy/bin/omunchy-askpass, which opens a password box for the user.

  sudo -A pacman -S <package>

If SUDO_ASKPASS is empty in the current shell, give it explicitly:

  SUDO_ASKPASS=~/.local/share/omunchy/bin/omunchy-askpass sudo -A pacman -S <package>

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
- Never run ~/.local/share/omunchy/bin/omunchy-askpass directly (it refuses unless sudo
  calls it) and never try to read, print or work around the password.
- If the user cancels the box (Esc) or it does not appear, stop and ask; do
  not retry blindly.
- On the live ISO (passwordless sudo) `sudo -A` simply runs without a prompt.
- Long or interactive root commands can still be run in a foot window instead
  (see RUNNING AN INTERACTIVE INSTALLER).

---

INITIALIZE PACMAN

The live session sets up pacman keys automatically (part of archiso), and the
installer builds a fresh keyring on the installed system. If pacman reports
signature errors (e.g. after a long gap between updates), set up the keys and
keyring afresh with a network connection:

omunchy-fix-keys

This recreates keys, refreshes the package cache, and updates archlinux-keyring.
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
Keys:     if signature checks fail, run omunchy-fix-keys (see INITIALIZE PACMAN)
AUR:      only on explicit request; see YAY / AUR.

---

CONSOLE KEYBOARD LAYOUT

obinstall sets the raw tty console (rescue mode, the disk-unlock prompt,
before mango starts) to the keyboard layout chosen in its wizard, and mango's
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

Omunchy uses Wayland with mango, which relies on kernel modesetting via Mesa.
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
