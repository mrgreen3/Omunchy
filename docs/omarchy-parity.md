# Omarchy → Omunchy parity & bloat analysis

Researched 2026-09-24 from `github.com/omacom/omarchy` @ branch `quattro`
(`main` 404s). Raw files via `https://raw.githubusercontent.com/omacom/omarchy/quattro/<path>`,
listings via `https://api.github.com/repos/omacom/omarchy/contents/<path>?ref=quattro`.
Package lists cached at `/tmp/omarchy-base.txt` (155 pkgs) and `/tmp/omarchy-other.txt` (75 pkgs).
**Compositor decision (2026-09-24, user): Hyprland — closest visual/feature parity wins over raw
leanness. MangoWC is out.** See §4.

## 1. Omarchy feature inventory

### 1.1 CLI dispatcher (`bin/omarchy`)
- 459 files in `bin/`, 458 subcommand scripts + the dispatcher itself, 74 route groups.
- Same self-describing metadata-header pattern Omunchy copied: `# omarchy:summary=`, `# omarchy:args=`,
  `# omarchy:examples=`, plus `# omarchy:group=`, `# omarchy:name=`, `# omarchy:alias=`,
  `# omarchy:requires-sudo=true`, `# omarchy:hidden=true` (scan capped at 80 header lines,
  `METADATA_SCAN_LIMIT=80` in `bin/omarchy`). Route = filename minus `omarchy-` prefix, dashes → spaces.
- Dispatcher extras Omunchy does not have yet: route collision detection, alias routing
  (e.g. `omarchy up` → `omarchy update`), `--json` flag detection, sudo-prompt metadata,
  hidden commands, group descriptions (74 entries in `GROUP_DESCRIPTIONS`).

### 1.2 Route groups (all 74, with counts)
agent (7), apply (3), ascii (1), audio (9), bar (2), battery (3), bluetooth (2), branding (3),
brightness (5), capture (8), channel (2), chromium (2), clipboard (3), cmd (3), crash (2),
debug (2), default (4), dev (11), disk (1), display (1), dns (1), done (1), drive (3), file (1),
font (3), games (2), git (1), hibernation (3), hook (2), hw (28), hyprland (24), install (40),
installed (2), launch (24), menu (14), migrate (2), mise (1), monitor (1), network (5),
notification (6), openclaw (1), osd (1), pkg (9), plugin (9), plymouth (7), power (1),
powerprofiles (3), provision (3), refresh (12), reinstall (3), reminder (1), remove (30),
restart (16), screensaver (1), setup (5), shell (2), show (2), snapshot (1), state (1), sudo (3),
system (11), tailscale (2), theme (34), toggle (14), transcode (2), tui (3), update (22),
upgrade (1), upload (1), version (4), voxtype (5), weather (3), webapp (5), windows (2).

Full inventory highlights (verbs Omunchy must decide on):
- **webapp (5)**: `webapp-install`, `webapp-remove`, `webapp-remove-all`,
  `webapp-handler-hey`, `webapp-handler-zoom` (protocol-link handlers, e.g. `zoommtg://` → web app).
- **tui (3)**: `tui-install`, `tui-remove`, `tui-remove-all`. TUIs launch via
  `xdg-terminal-exec --app-id=TUI.float|TUI.tile -e <cmd>`; `tui-remove-all` greps for that
  app-id pattern to find what it installed.
- **theme (34)**: set/list/install/remove/update/switcher + per-app theming
  (`theme-set-foot`, `-gnome`, `-browser`, `-browser-policy`, `-tmux`, `-vscode`, `-obsidian`,
  `-keyboard*`, `-claude`, `-hermes`, …) + background set (`theme-bg-set/next/switcher/cache`).
  Themes live in `$OMARCHY_PATH/themes` + `~/.config/omarchy/themes`; current theme state in
  `~/.local/state/omarchy/current/theme`. Theme-installed Lua is security-filtered
  (`alacritty.toml foot.ini ghostty.conf kitty.conf vscode.json` denied — they run code).
- **update (22)**: `update` orchestrates pkg-prune → snapper snapshot (skips if absent, exit 127)
  → stay-awake → dev → keyring → system-pkgs → migrate → post-update hook → aur-pkgs → mise →
  orphan-pkgs → log analysis → status → restart. Guarded by `update-lock`, logs via `script` to
  `/tmp/omarchy-update.log`, `-y` unattended mode, free-space check, pacman guard.
- **pkg (9)**: add/drop/install/remove/missing/present/aur-add/aur-install/aur-accessible.
- **system (11)**: lock/logout/reboot/shutdown/sleep-lock/sleep-monitor/lid-close/stats/wake +
  `system-factory-reset` (btrfs @factory snapshot swap + LUKS re-key; ISO-install only).
- **hyprland (24)**: monitor (clamshell/scaling/mirror/laptop), window (width/pop/gaps/
  transparency/tiled-fullscreen toggles), focus-app, reload-guard, session-locked, toggles.
- **hw (28)**: per-vendor fixups (asus/dell/framework/surface/t2/nvidia/intel) + generic
  (touchpad, touchscreen, webcam, fingerprint, hybrid-gpu, clamshell, vulkan, display).
- **install/remove (40+30)**: optional app installers — ai (chatgpt/claude/hermes/openclaw/t3-code),
  editors (emacs/helix/vscode/zed), gaming (steam/lutris/heroic/battlenet/retroarch/geforce-now/
  xbox), services (1password/dropbox/nordvpn/signal/spotify/sunshine/tailscale), dev-env,
  docker-dbs, browsers, fonts, terminals.
- **launch (24)**: launch-or-focus for apps/TUIs/webapps, nautilus (cwd), terminal (+tmux),
  shell (quickshell IPC), screensaver, config-editor.
- **menu (14)**: menu is a quickshell plugin (`omarchy.menu`) driven over IPC
  (`omarchy-shell shell toggle omarchy.menu '{menu:"..."}'`); submenus: emoji, clipboard,
  images, file, input, keybindings, plugin, select, share, timezone.
- **shell (2)**: `omarchy-shell` = IPC client to the quickshell daemon; `shell.json` config
  defines bar layout (left: menu+workspaces; center: indicators/clock/keyboard/weather/
  system-update; right: tray/agents/bluetooth/network/audio/monitor/power), idle timers
  (screensaver 150s, lock 300s), plugins.
- **toggle (14)**: bar, idle, nightlight, notification-silencing, screensaver, suspend,
  touchpad, touchscreen, hybrid-gpu, fullscreen-desktop, input-device, crash-capture.
- **provision (3) / migrate (2) / hook (2)**: first-boot owner setup (`omarchy-provision-owner`
  on tty1, armed by `/var/lib/omarchy/provisioning/pending`), migrations runner, user hooks.
- **capture (8)**: screenshot/region/text (OCR via tesseract)/QR/screenrecording(+webcam)/webcam.
- **Others**: audio (9), brightness (5), battery (3), bluetooth (2), network (5), weather (3),
  notification (6), plymouth (7), channel (2) + version (4) (release channels), plugin (9)
  (bar-widget ecosystem), voxtype (5) (dictation), windows (2) (VM), tailscale (2), games (2),
  default (4) (browser/editor/terminal/agent), font (3), dns, hibernation (3), drive (3),
  powerprofiles (3), sudo (3), restart (16), refresh (12).

### 1.3 Theme / wallpaper system
- State: `~/.local/state/omarchy/current/{theme,theme.name,next-theme,background}`;
  transition cache `~/.cache/omarchy/background-transitions`; per-theme background memory in
  `~/.local/state/omarchy/theme-backgrounds`. Source: `bin/omarchy-theme-set`.
- Applies to: Hyprland (theme ships `hyprland.lua`), foot, tmux, vscode, obsidian, gnome/gtk
  (Adwaita-dark + Yaru-blue icons via gsettings), Chromium (policy + device color-scheme),
  keyboard RGB (asus/framework), plus OS-level (plymouth via `theme-set-by-theme`).
- Video wallpapers supported (`owe` + `owe-lockfeed` own video backgrounds & lock-screen frames).

### 1.4 Update system
- See update (22) above. Extras: `update-available` (check-only), `update-confirm` (gum),
  `update-restart` (reboot prompt), `update-stay-awake` (logind inhibitor), `update-keyring`,
  `update-firmware` (fwupd), `update-time` (last-update stamp), `update-user-notify`.
- Release channels: `channel-current/channel-set`, `version-branch/channel/pkgs`,
  `upgrade-to-quattro`. AUR updates via `update-aur-pkgs` (yay).

### 1.5 Webapp + TUI system
- `webapp-install [name url icon [custom-exec] [mime-types]]`: icon fetch order
  apple-touch-icon → `/apple-touch-icon.png` well-known → Google favicon service; URL
  normalization (schemeless → https), refuses non-http(s) + whitespace + `/` in name;
  Chromium `--app=` windows. Omunchy's `omunchy-webapp-install` mirrors this.
- `tui-install [name command window-style icon]`: writes
  `Exec=xdg-terminal-exec --app-id=TUI.float|TUI.tile -e $APP_EXEC`, icon via URL/file/bundled
  name. Omunchy prefixes app-ids `omunchy.TUI.float/tile` (good — collision-free).
- Protocol handlers (`webapp-handler-zoom/hey`) map `zoommtg://`-style links into web apps.

### 1.6 Default apps & UI stack
- Base packages (`install/omarchy-base.packages`, 155): hyprland + guiutils + preview-share-picker
  + hyprpicker + hyprsunset, foot, waybar (via quickshell — Omarchy's bar is quickshell, not
  waybar), mako, uwsm, chromium, nautilus (+python), mpv, nvim (omarchy-nvim), tmux, btop, fzf,
  eza, bat, ripgrep, fd, zoxide, starship, gum, yay, grim/slurp/wl-clipboard/wtype, imv, evince,
  pinta, xournalpp, noto-fonts (+cjk+emoji), yaru-icon-theme, gnome-themes-extra, gnome-keyring,
  networkmanager, bluez*, pipewire stack (in other.list), ufw, docker suite, libreoffice-fresh,
  obs-studio, obsidian, kdenlive, sddm, plymouth, snapper, owe/omacalc/omacut/omasnap/omawrite,
  herdr, quickshell, mise-bin, lua51/luarocks/ruby/llvm/clang, tesseract, moonlight-qt, localsend.
- Other (`install/omarchy-other.packages`, 75): linux-omarchy kernel, limine (+snapper sync),
  nvidia/asus/dell/framework/t2/surface dkms packs, vulkan drivers, zram-generator, thermald.
- Editors/terminals config dirs: `config/{foot,ghostty,kitty,alacritty}` shipped but foot is
  the default; `config/{hypr,btop,chromium,git,starship.toml,tmux,wireplumber,fcitx5,imv,
  lazygit,obsidian,xournalpp,opencode,herdr,omarchy}`.
- Hyprland config is Lua: `~/.config/hypr/hyprland.lua` requires
  `$OMARCHY_PATH/default/hypr/bootstrap.lua` + `require("default.hypr.omarchy")` (defaults:
  bindings split into media/clipboard/tiling/utilities/voxtype/applications), then user files
  (`hypr/{monitors,input,bindings,looknfeel,autostart}`). Bindings API: `o.bind("SUPER + K", …)`.

### 1.7 Login / greeter & first boot
- Login: **SDDM** (`install/login/sddm.sh` strips `pam_gnome_keyring.so` lines from
  `/etc/pam.d/sddm` so password logins don't create a conflicting keyring).
- Boot: **plymouth** (7 commands manage themes) + **limine** bootloader on btrfs+snapper.
- First boot: `install/provisioning/omarchy-provision-owner.service` — oneshot on tty1
  **before SDDM starts**, gated by `ConditionPathExists=/var/lib/omarchy/provisioning/pending`,
  runs `omarchy-provision-owner` (gum-based form from `install/provisioning/setup-form.sh`:
  keyboard layout / username / password / full name / email / hostname / timezone, with
  validation regexes and reserved-username list).
- First-run scripts (`install/user/first-run/`): welcome notification
  ("Super + K cheatsheet / Super + Space menu"), enable user units (bt-agent, owed,
  omarchy-sleep-lock, omarchy-crash-watch, fcitx5, migrate-notify), gnome theme gsettings,
  gtk primary paste, audio speaker tuning, wifi, agent/fingerprint hooks.
- ISO-side: `install/config/all.sh` (theme-system, browser-policy, lockout-limit,
  lockscreen-pam, ssh keepalive, docker, snapper, locate, services, firewall ufw).

### 1.8 Omunchy current state (for the parity table)
- Dispatcher `bin/omunchy`: same metadata pattern (summary/args/examples), longest-prefix
  routing, `help <group>`, -h interception. No aliases/groups/collision detection/sudo metadata.
- Scripts: `omunchy-{sync,webapp-install,webapp-remove,tui-install,tui-remove,launch-webapp}`.
- `config/webapps.conf` (`Name|URL|Icon`), `config/tuis.conf` (`Name|Command|Style|Icon`).
- `install.sh` skeleton with TODOs; README still says MangoWC + "avoid quickshell overhead".

## 2. Parity table

| # | Omarchy feature | Omunchy equivalent | Verdict |
|---|---|---|---|
| 1 | `bin/omarchy` dispatcher (458 routes, 74 groups) | `bin/omunchy` dispatcher (6 routes) | **keep** — same pattern; add aliases/group descriptions later, skip sudo/hidden/json metadata |
| 2 | `omarchy webapp install/remove/remove-all` | `omunchy webapp-install/-remove` (+sync from conf) | **keep**; add `remove-all` (grep `Exec=.*omunchy-launch-webapp`) — trivial |
| 3 | `omarchy tui install/remove/remove-all` (`xdg-terminal-exec --app-id=TUI.*`) | `omunchy tui-install/-remove` (app-id `omunchy.TUI.*`) | **keep**; add `tui-remove-all` copying the grep-for-app-id approach |
| 4 | Protocol handlers (`webapp-handler-zoom/hey`) | none | **strip** (Kev has no Zoom/Hey usage; add later if needed) |
| 5 | `omarchy sync`-style batch config | `omunchy sync` (webapps.conf + tuis.conf → .desktop) | **keep** — already Omunchy-native |
| 6 | Theme system (34 cmds, per-app theming, video bgs via owe) | none | **replace with minimal**: static Hyprland/foot/waybar/mako colour files + `omunchy theme-set <name>` + `theme-bg-set <img>` (swaybg/hyprpaper); no Lua themes, no owe, no per-app theming |
| 7 | Wallpaper switching (`theme-bg-*`) | swaybg in Mango config, static | **keep as minimal** `omunchy-bg-set` (single command, rewrites swaybg/hyprpaper exec line) |
| 8 | Update system (`update` + 21 helpers, snapper, migrations, channels) | none | **replace with lean**: `omunchy-update` = reflector → pacman -Syu → yay -ua (if AUR pkgs) → orphan prune prompt; no snapper/migrations/channels/stay-awake |
| 9 | Pkg helpers (`pkg-add/install/aur-*`) | none (raw pacman/yay) | **strip** — ArchBang users know pacman; one optional `omunchy pkg-install` wrapper if wanted |
| 10 | Optional app installers (ai/gaming/services/editors, 40) | none | **strip** — bloat by definition; user installs what they want with yay |
| 11 | Menu system (quickshell `omarchy.menu` + 14 cmds) | rofi menus (rofi/config.rasi + archbang-menu script) | **replace** — rofi-based `omunchy-menu` (apps, webapps, keybinds); no quickshell daemon |
| 12 | Bar (quickshell `omarchy-shell` IPC, shell.json layout) | waybar (already configured in airootfs) | **keep waybar** — no daemon, config-file driven; no IPC parity needed |
| 13 | Notifications (mako + 6 helper cmds) | mako (configured) | **keep mako**; helpers only if a keybind needs them |
| 14 | Screenshot/recording (`capture-*`, 8) | Scripts/screenshot (grim+slurp) | **keep** — maybe promote to `omunchy-capture-screenshot/-region`; screenrecording optional (wf-recorder) |
| 15 | Clipboard helpers (3) + wl-clipboard | wl-clipboard in pkg list | **keep pkg**; scripts optional |
| 16 | Audio/brightness/battery/bluetooth/network/weather cmds (~25) | pamixer, brightnessctl in pkg list | **keep pkgs**; keybinds call binaries directly (pamixer/brightnessctl), no wrapper scripts |
| 17 | `system-lock/logout/reboot/shutdown` | Scripts/powermenu (existing) | **keep** existing powermenu, no new scripts |
| 18 | Idle/screensaver (screensaver 150s / lock 300s) | none | **replace minimal**: swayidle or hyprland `bind = , switch:on`-less — one idle config with lock; or strip (Kev's call) |
| 19 | SDDM greeter | greetd + gtkgreet + cage (in packages.x86_64, abinstall wires it) | **keep greetd** — far leaner than SDDM; not an Omarchy-parity item |
| 20 | plymouth boot theme (7 cmds) | none (syslinux/grub splash only) | **strip** |
| 21 | limine bootloader + snapper/btrfs snapshots | grub (in packages.x86_64) | **keep grub**; strip snapper |
| 22 | Factory reset (btrfs @factory swap) | none | **strip** — requires Omarchy ISO plumbing |
| 23 | First-boot provisioning (tty1 owner setup, gum form) | abinstall + skel files | **keep existing** ArchBang install flow; no gum form |
| 24 | Welcome notification (first-run) | none | **keep-as-tiny**: one mako call from install.sh ("read Keybindings doc") — optional |
| 25 | Keybinding cheat-sheet (`menu keybindings`) | Documents/Keybindings (existing skel file) | **keep** — static doc is enough |
| 26 | Migrations (`omarchy-migrate`, dev-add-migration) | none | **strip** |
| 27 | User hooks (`omarchy-hook`) | none | **strip** |
| 28 | Plugin system (bar widgets, 9 cmds) | none | **strip** — waybar config is hand-edited |
| 29 | Release channels/versions (channel-*, version-*, upgrade-to-quattro) | git pull of Omunchy repo | **strip** |
| 30 | HW fixup scripts (28 hw cmds, vendor dkms) | laptop-detect + broadcom-wl in list | **strip** — target hardware is Chromebook-class Intel; keep broadcom-wl for old WiFi |
| 31 | Hibernation/disk/drive/powerprofiles/dns helpers | none | **strip** |
| 32 | AI agent integration (agent-*, install-ai-*, 7+5 cmds) | none | **strip** — out of scope for a desktop layer |
| 33 | Voxtype dictation (5) | none | **strip** |
| 34 | Windows VM (2), tailscale (2), games (2) | none | **strip** |
| 35 | Docker TUI/launchers (`launch-docker-tui`, docker suite in base) | none | **strip** — docker excluded (see §3) |
| 36 | Chromium integration (`refresh-chromium`, copy-url, ytdlp-host, browser-policy) | Chromium in pkg list; `omunchy-launch-webapp` uses `--app=` | **keep pkg + --app mode**; strip host integrations |
| 37 | OCR (`capture-text` via tesseract) | none | **strip** (tesseract is heavy for occasional use) |
| 38 | File manager (nautilus + sushi + gvfs-*) | thunar + gvfs (in packages.x86_64) | **keep thunar** |
| 39 | Editors (nvim+omarchy-nvim, GUI editors via install-*) | vim + l3afpad (in list) | **keep**; nvim optional user choice |
| 40 | fastfetch/inxi/btop monitoring | btop + fastfetch (in list) | **keep** |
| 41 | Fonts: noto + emoji + jetbrains mono nerd + ia-writer | noto + noto-emoji + jetbrains-mono-nerd (in list) | **keep** |
| 42 | GTK theming (adw-gtk3, Yaru icons, gnome-themes-extra) | adw-gtk-theme + adwaita-icon-theme (in list) | **keep** |

Legend — **keep**: exists or trivially derived; **replace**: Omunchy-native lean substitute;
**strip**: out of Omunchy scope per bloat definition.

## 3. Bloat exclusion list (Kev's definition, with justifications)

| Excluded from Omunchy | Why |
|---|---|
| 1Password (+ `omarchy-launch-1password`, `install-service-1password`) | Kev doesn't use it; `keepassxc` or browser storage if ever needed |
| Spotify + demo launchers preinstalled (`launch-spotify`, `install-service-spotify`) | Demo content, not a feature |
| LibreOffice (`libreoffice-fresh`, ~500MB) | Kev uses lighter tooling; add manually if needed |
| kdenlive | Video editing not in scope |
| obs-studio | gpu-screen-recorder-class tooling not wanted |
| obsidian (+ `theme-set-obsidian`) | Not Kev's note tool |
| docker/docker-compose/buildx/ufw-docker + docker dbs installer | Server workload, not desktop |
| dotnet-runtime, mariadb-libs, postgresql-libs | Language/db runtimes dragged in by Omarchy apps; dead weight on a desktop layer |
| cups + cups-filters + cups-pk-helper + system-config-printer | No printers targeted (Chromebook-class) |
| ruby, lua51, luarocks, llvm, clang (+ tree-sitter-cli) | Language toolchains only nvim/plugin infra needs |
| Omarchy's own tools: omacalc, omawrite, omacut, omasnap, owe, owe-lockfeed, tobi-try, ttfx, cliamp, aether, elsewhen, usage, herdr | Omarchy-branded extras — parity is in the patterns, not the branded binaries; no branding per project rule |
| quickshell (+ omarchy-shell IPC, bar, menu plugins) | The whole reason Omunchy exists: waybar/rofi instead of a shell daemon |
| sddm | greetd+gtkgreet chosen (leaner); Omarchy parity not required for login |
| plymouth (+ 7 cmds) | Boot splash = cosmetic |
| limine + limine-* + snapper + btrfs defaults | ArchBang/grub + ext4 path; snapshots out of scope |
| nvidia/t2/framework/asus/dell dkms hardware packs + hw-* scripts | Target is Intel iGPU Chromebook-class hardware |
| mise-bin + mise wrappers | Dev-env manager, not desktop |
| voxtype | Dictation out of scope |
| windows-vm/windows-key, qemu-user-static-binfmt | VM stack out of scope |
| moonlight-qt, localsend, sunshine | Streaming/sharing extras not requested |
| evince, pinta, xournalpp, imv (keep imv only if needed) | Document/image apps beyond lean set |
| tesseract + tesseract-data-eng | OCR rarely used, heavy |
| fcitx5 + gtk/qt bindings | Single keyboard-layout use case |
| noto-fonts-cjk | Space; add per-user if needed |
| gvfs-mtp/nfs/smb, gnome-keyring, libsecret (keep libsecret) | Network shares/keyring extras not targeted |
| Omarchy branding/trademarks (name, logos, "omarchy-*" names, omarchy.org links) | Project rule: no branding; the CLI verb shape is the only thing inherited |

## 4. Compositor: Hyprland (decided)

**Decision 2026-09-24 (user): Hyprland wins — closest visual/feature parity with Omarchy beats
raw leanness. MangoWC is out.** The comparison below is retained as supporting rationale.

### 4.1 Factual RAM comparison (Wayland compositors, idle desktop)

| Compositor | Idle RAM (measured, same test) | Packaging |
|---|---|---|
| dwl | 328 MB | AUR |
| Sway | 332 MB | extra |
| Niri | 353 MB | extra |
| River | 353 MB | extra |
| Mango (mangowm) | 380 MB | AUR (`mangowm-git`) |
| Hyprland | 532 MB | extra |

Source: community RAM measurement, "Wayland Compositors RAM Usage Comparison"
(reddit.com/r/linux/comments/1njecy5) — bare tty baseline ≈320 MB, so compositor-only deltas are
≈8–212 MB above tty. Corroborating anecdotes: minimal Hyprland setups report ~400–450 MB total
(r/hyprland 1lt030e) and ~39–180 MB compositor-only (r/hyprland 1md6nuu), i.e. Hyprland's own
process is small; the 532 MB figure includes typical desktop services. On 4–8 GB Chromebook-class
hardware both fit: with a browser open (1–2 GB), Hyprland leaves ~2.5–6.5 GB free on 4/8 GB.
The Hyprland delta over Mango is real (~150 MB) but not decisive above 4 GB.

### 4.2 Feature comparison

| Feature | Hyprland | Mango (mangowm) |
|---|---|---|
| Base | wlroots fork (aquamarine) | dwl (tinywl-style) |
| Layouts | dwindle + master | master-stack, monocle, dwindle, grid, scroller, more |
| Window states | floating/tiling, fullscreen, pseudo-tile | swallow, minimize, maximize, global, overlay, fakefullscreen |
| Effects | blur, shadows, rounding, opacity, animations | blur/shadow/rounding/opacity via scenefx |
| Animations | yes, rich | yes (window open/move/close, tag transitions) |
| IPC | hyprctl socket, extensive | own IPC (send/receive messages) |
| Hot-reload config | yes | yes |
| XWayland | yes, mature | yes ("excellent", scale without blurring) |
| Input methods | text-input v1/v3, IME mature | text-input v2/v3 |
| Scratchpad | no built-in | named scratchpad |
| Overview | plugin ecosystem | hycov-style overview built-in |
| Tags vs workspaces | workspaces | tags (per-tag layout memory) |
| Ecosystem/docs/wiki | very large (hypr.land wiki, huge rice community) | smaller, growing |
| Omarchy support | first-class — Omarchy is built on it (24 hyprland-* helpers, Lua config) | none |

### 4.3 Parity implications of choosing Hyprland (concrete changes)

1. **Package set** — add to `packages.x86_64` (all present in Omarchy's
   `install/omarchy-base.packages`): `hyprland`, `hyprland-guiutils`, `hyprpicker`,
   `hyprsunset`, `uwsm`, `xdg-desktop-portal-hyprland`. Keep `xdg-desktop-portal-gtk`.
   Remove: `mangowm`, `wlr-randr` (hyprctl replaces it), `swaybg` (Hyprland has built-in
   wallpaper via `hyprctl hyprpaper` — hyprpaper is part of hyprland; or keep swaybg, works
   fine under Hyprland too), `swaylock` (replace with `hyprlock` for Omarchy-style lock,
   or keep swaylock — both work).
2. **Config** — replace `airootfs/etc/skel/.config/mango/config.conf` with a fresh
   `airootfs/etc/skel/.config/hypr/hyprland.lua` (Hyprland 0.55+ deprecated hyprlang
   `.conf`; Omunchy now ships Lua — see §5.1 note), Omarchy-style:
   - autostart via `hl.on("hyprland.start", …)` + `hl.exec_cmd`: waybar, mako, hyprpaper
   - window rules for `omunchy.TUI.float|tile` app-ids (`hl.window_rule{ match = { class = … }, float = true }`)
   - binds: SUPER+Return foot, SUPER+SPACE rofi, SUPER+K keybind cheatsheet (rofi or wofish),
     SUPER+Q close, SUPER+F fullscreen, SUPER+T float toggle, audio/brightness via
     pamixer/brightnessctl, screenshot SUPER+P grim+slurp
   - `hl.monitor` defaults, gestures (`hl.gesture`), gaps/animations (Omarchy looknfeel parity:
     `default/hypr/looknfeel.lua`)
   - note: Omarchy ships its config as **Lua** (`config/hypr/hyprland.lua` requiring
     `$OMARCHY_PATH/default/hypr/*.lua`) — Omunchy now does the same (error-isolated
     `require()` modules: hyprland.lua → looknfeel/binds/theme), mirroring the
     resulting bindings.
3. **Flag for review** (Mango-specific bits that need a decision):
   - `airootfs/etc/skel/.config/networkmanager-dmenu/config.ini` — rofi dmenu backend is
     compositor-agnostic (keep), but check whether Kev wants `nm-connection-editor` or a
     rofi-only flow under Hyprland.
   - any `mango`/`mangowm`-named window rules, autostarts, or scripts elsewhere in airootfs
     (`Scripts/archbang-menu`, `Scripts/powermenu` reference the compositor indirectly —
     verify their rofi invocation still fits Hyprland's session, it does: rofi is
     compositor-agnostic).
   - `xdg-desktop-portal-wlr` in packages.x86_64 is Mango's portal; under Hyprland use
     `xdg-desktop-portal-hyprland` (screencast/screenshot portals differ) — keep both only if
     something else needs wlr.
   - `tuis.conf` Style field comment references "MangoWC window rules" — reword to
     "Hyprland window rules" (comment-only change, no code).
4. **Keybind/UX parity deltas vs Omarchy**: Hyprland gives Omunchy everything Omarchy's
   24 hyprland-* helpers do (monitor toggles, window-width, gaps toggle) as native
   `hyprctl` dispatchers or config — no helper scripts needed. Omarchy's Lua binding API
   (`o.bind`) has no Omunchy equivalent and doesn't need one.

## 5. Recommendation

1. **Adopt Hyprland as decided**: swap the mango package/config for the 6-package Hyprland set
   and a Lua `~/.config/hypr/hyprland.lua` (hyprlang `.conf` is deprecated in Hyprland 0.55+;
   updated 2026-09-25 — Omunchy ships Lua modules, not plain conf) with Omarchy-parity bindings
   wired to the existing waybar/rofi/mako/foot stack. Cost vs Mango: ~150 MB idle RAM —
   acceptable on 4–8 GB, and it buys Omarchy's exact compositor behaviour (hyprctl,
   animations, effects).
2. **Keep the Omunchy CLI exactly as-is** (dispatcher + webapp/tui verbs): it already mirrors
   Omarchy's metadata-header dispatcher. Add only `webapp-remove-all`, `tui-remove-all`, and a
   lean `omunchy theme-set`/`bg-set` + `omunchy-menu` (rofi). Everything else Omarchy has is
   either already in Omunchy's path or deliberately stripped per §3.
3. **Strip the §3 list unconditionally** — it removes ~60 packages from Omarchy's base list
   and all branded/binary extras; the Omunchy base stays roughly the current
   `packages.x86_64` plus the Hyprland set.
4. **Do not chase Omarchy parity on**: login (keep greetd), boot (no plymouth/limine),
   snapshots (no snapper), bar/menu IPC (no quickshell), first-boot provisioning (keep the
   ArchBang flow). Those are distro-level features Omunchy deliberately doesn't inherit.