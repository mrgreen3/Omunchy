# Omunchy bar research: what can mimic Omarchy's bar, without a shell daemon?

> **2026-09-25: note.** Since the sway port the waybar modules in use are
> the sway equivalents (`sway/workspaces`, `sway/language`) — same
> in-tree native-module situation as the hyprland/* modules analysed
> below. Hyprland references describe Omarchy's own bar and the modules
> considered during the original research.

Researched 2026-09-24.
Researched 2026-09-24. Companion to `docs/omarchy-parity.md` — this doc stress-tests
parity-table row 12 ("keep waybar, no IPC parity needed").

All Omarchy claims below were verified against the **live repo**,
`github.com/omacom/omarchy` @ branch `quattro`, fetched via
`https://raw.githubusercontent.com/omacom/omarchy/quattro/<path>`. Exact paths fetched
are listed under each claim. Community RAM numbers are anecdotes, labelled as such.

---

## 1. What Omarchy's bar actually is (verified from the quattro tree)

Fetched from the live repo: `config/omarchy/shell.json`, `shell/README.md`,
`manual/05-the-top-bar.md`, `shell/plugins/bar/widgets/{Workspaces,ActiveWindow,Tray,Indicators,SystemUpdate}.qml`,
`shell/plugins/notifications/Service.qml`, `shell/plugins/services/{media/BarWidget,battery/Service}.qml`,
`bin/omarchy-bar`, `shell/services/BarWidgetRegistry.qml`, `shell/plugins/bar/manifest.json`.

- Omarchy v4 ("quattro") has **no waybar at all**. The desktop is **one long-lived
  Quickshell process** ("the Omarchy shell"); the bar, panels, menus, notification toasts,
  OSD, lock screen are plugins hosted by `shell.qml` — `shell/README.md` states: "The
  Omarchy desktop runs in one long-lived Quickshell process. Its bar, panels, overlays,
  menus, and services are plugins hosted by `shell.qml`." Codetocloud's quattro writeup
  confirms what was removed in 4.0: "Waybar. Walker. Mako. SwayOSD. hyprlock. hypridle.
  swaybg. polkit-gnome. Eight separate programs…".
- **Omarchy's notifications are not mako** — the shell claims the D-Bus notification
  daemon itself (`shell/plugins/notifications/Service.qml` imports
  `Quickshell.Services.Notifications` and implements `NotificationServer`; toasts persist
  to `~/.local/state/omarchy/notifications/`). Mako is *not* in
  `install/omarchy-base.packages` (grep: only `quickshell` matches; no `mako`, no `waybar`
  line). **Implication for Omunchy:** keeping mako means the bar never needs a
  notification widget of its own.
- The bar layout lives in `config/omarchy/shell.json` (verified verbatim):

| section | widget id | what it does |
|---|---|---|
| left | `omarchy.menu` | logo → Omarchy menu (rofi-equivalent for Omunchy) |
| left | `omarchy.workspaces` | 1–10 workspace pills, occupied/focused styling (`Workspaces.qml` uses `Quickshell.Hyprland` IPC directly; focus via `hyprctl dispatch "hl.dsp.focus(...)"`) |
| center | `omarchy.indicators` | hover-reveal pill: Dictation, ScreenRecording, Reminder, NightLight, Dnd, StayAwake (`Indicators.qml`) |
| center | `omacom.elsewhen` | plugin (timer) |
| center | `omarchy.clock` | `dddd HH:mm` + calendar popup + timezone picker |
| center | `omarchy.keyboard-layout` | shown only if >1 layout configured |
| center | `omarchy.weather` | forecast popup |
| center | `omarchy.system-update` | badge appears only when updates pending (`SystemUpdate.qml` polls `omarchy-update-available` every 6h) |
| right | `omarchy.tray` | SNI system tray with hover-drawer + pin/hide manager (`Tray.qml`) |
| right | `omarchy.agents` | AI-agent usage panel (appears only when usage exists) |
| right | `omarchy.bluetooth` | panel + radio toggle |
| right | `omarchy.network` | panel (Wi-Fi scan/connect) |
| right | `omarchy.audio` | panel (per-app mixer, output picker) |
| right | `omarchy.monitor` | brightness/display panel (not a CPU/RAM readout) |
| right | `omarchy.power` | battery panel via UPower (`shell/plugins/services/battery/Service.qml`) |
| (opt-in) | `omarchy.media` | MPRIS now-playing w/ play-pause + cover popup (off by default) |
| (opt-in) | `omarchy.active-window` | window title, elided at 280px (`ActiveWindow.qml`) |
| (opt-in) | `omarchy.microphone` | mic mute widget (off by default) |

`manual/05-the-top-bar.md` confirms the interactive model: "Nearly every widget does
something on left, right, and middle click, and several respond to scrolling", and
documents click-panels for audio/network/bluetooth/display/power/clock with hotkeys.

### Widget→waybar mapping (for the config sketch in §5)

| Omarchy widget (quattro) | Waybar module | Fidelity |
|---|---|---|
| `omarchy.workspaces` | `hyprland/workspaces` | full — dedicated native module[14] |
| `omarchy.active-window` | `hyprland/window` | full[15] |
| `omarchy.tray` | `tray` | full — SNI tray with `icon-size`, per-app icon overrides, ordering; mature[16][40] |
| `omarchy.audio` | `pulseaudio` | full[13] |
| `omarchy.bluetooth` | `bluetooth` | full[13] |
| `omarchy.network` | `network` | full[13] |
| `omarchy.power` (battery) | `battery` | full[13] |
| `omarchy.power` (power-profiles) | `power-profiles-daemon` | full[13] |
| `omarchy.monitor` (brightness) | `backlight` | full[13] |
| `omarchy.media` | `mpris` | full[13] |
| `omarchy.indicators` (DnD/night-light/ScreenRecording/StayAwake) | `idle_inhibitor` (StayAwake) + `custom/` scripts for the rest | partial[18] |
| `omarchy.keyboard-layout` | `hyprland/language` | full[13] |
| `omarchy.clock` | `clock` | full (calendar popup — Waybar Clock module wiki[41]) |
| `omarchy.system-update` | `custom/updates` script | near-full (`checkupdates`, signal-refresh)[17] |
| `omarchy.menu` | `custom/launcher` | full (exec rofi)[17] |
| `omarchy.agents` | `custom/agents` script (JSON via signal) | waybar-only approximation |
| notification toggle | `custom/swaync` pattern or `mako` D-Bus script | mako has no `swaync-client`-style CLI; needs a small script or `makoctl` calls |
| CPU/RAM/temp gauges (row-12 mention) | `cpu`, `memory`, `temperature` | full — but **Omarchy quattro's default bar has no CPU/RAM/temp widgets** (shell.json layout above); Omarchy's own `omarchy-sysmon` plugin README confirms "There is no built-in readout for CPU, memory, or network throughput" in the default bar |

**Note on "keep waybar" wording:** parity row 12 says "no IPC parity needed" — this
research **agrees with the verdict** but shows the *reason* is slightly different from
"waybar is simpler": Omarchy's bar isn't just a widget strip, it's also the notification
daemon host, the panel system, and the menu host. Omunchy substitutes rofi for the menu
and mako for toasts, so the residual bar-surface comparison is widgets-only, and waybar
covers those one-for-one.

---

## 2. Candidate comparison

Maturity data fetched 2026-09-24 from each repo's GitHub API (`api.github.com/repos/<owner>/<repo>`).

| | **Waybar** (incumbent) | **Ironbar** | **AGS/Astal** | **Quickshell** (what Omarchy uses) | **nwg-panel** | **eww** | **ashell** | **HyprPanel** |
|---|---|---|---|---|---|---|---|---|
| Language / toolkit | C++ / GTK3 | Rust / GTK4 | TS+JS / GTK3+GTK4 via Astal | C++ / Qt6+QtQuick | Python / GTK3 | Rust / GTK3 | Rust / iced (wgpu) | TS / AGS→Astal |
| Hyprland integration | first-class: `hyprland/workspaces`, `hyprland/window`, `hyprland/language`, `hyprland/submap` — all native, in-tree[13][14][15] | first-class[23] | via AstalHyprland lib[32] | native `Quickshell.Hyprland` — Omarchy's own widgets use it (e.g. `Workspaces.qml` imports `Quickshell.Hyprland`)[4] | first-class (`Hyprland workspaces` + `Hyprland taskbar`)[27] | none built-in; needs bash+jq+socat+awk+python scripts[12] | first-class[31] | first-class |
| Workspaces pills | ✅[14] | ✅ | ✅ (user-built) | ✅ (Omarchy's own)[4] | ✅[27] | ✅ (scripted)[12] | ✅[31] | ✅ |
| Active window title | ✅ `hyprland/window`[15] | ✅ | ✅ (user-built) | ✅ (Omarchy's own, elide-capable)[5] | ✅ (workspaces module shows focused window details)[27] | ✅ (scripted)[12] | ✅[31] | ✅ |
| System tray | ✅ `tray` (SNI; mature; per-app icon overrides, ordering)[16][40] | ✅ `tray` module w/ popup menus[24][25] | ⚠️ AstalTray exists but bar-level integration is user-built[32] | ✅ (Omarchy's own Tray.qml)[6] | ✅[27] | ⚠️ needs scripts (no native tray module) | ✅[31] | ✅ |
| MPRIS media | ✅ `mpris`[13] | ✅ | ⚠️ user-built (AstalMpris exists) | ✅ (Omarchy's own)[10] | ✅ Playerctl[27] | ⚠️ scripted | ✅[31] | ✅ |
| Notifications | ⚠️ no built-in daemon — Omunchy keeps **mako**, so N/A for Omunchy (swaync users add a custom module)[17] | ⚠️ via swaync module[26] | ⚠️ user-built (AstalNotifd) | ✅ (Omarchy's own; *is the daemon*)[9] | ⚠️ via SwayNC integration[27] | ❌ | ✅ built-in toast manager + grouping[31] | ✅ via AGS notifications |
| CPU/RAM/temp | ✅ `cpu`,`memory`,`temperature`[13] | ✅ `sys_info` (sysinfo crate, CPU+RAM+temp+disk+net, ironvar exposure)[13] | ⚠️ user-built | ⚠️ user-built (community `omarchy-sysmon`, `cpu-net` plugins exist; Omarchy's `omarchy.monitor` widget is brightness/display controls, **not** a CPU/RAM readout) | ✅ via `Executor` scripts (psutil) | ⚠️ scripted | ✅ SystemInfo (CPU/RAM/Temp/Disk/Net)[31] | ✅ |
| Config format | JSON/CSS | TOML+CSS+Cairo+Lua(optional) | TypeScript/JSX + SCSS/CSS | QML | Python-driven config UI (TOML-ish) | Yuck(lisp)+SCSS | TOML | TSX/SCSS (Astal) |
| Startup | ~instant (GTK3 C++) | moderate (Rust+GTK4) | moderate (GTK3/4 + JS engine) | slow (Qt6 QML engine) | moderate (Python GTK3) | slow-ish (Rust+GTK3) | moderate (iced/wgpu) | slow |
| Idle RAM (see §3) | **40–75 MB**[19][20][21][22] | ~26 MB binary w/ all features, <5 MB stripped (author, r/hyprland 1qkx1wm[38]); runtime RAM unmeasured | ⚠️ unmeasured (no published benchmarks; GTK+JS implies heavier than waybar) | **140–400 MB** depending on config complexity[19][20][21][37] | ⚠️ unmeasured (no first-party or credible community numbers) | **~50–64 MB** typical[20] (but see leak issue[29]) | **~100–130 MB** (maintainer-confirmed)[30] | ~150 MB (community report)[34] |
| Maturity / maintenance (as of 2026-09-24) | **active** — pushed 2026-09-24, 12.0k★, 0.15.0 (2026-02-06), 0.14.0 (2025-08-08), 0.13.0 (2025-06-23) | **active** — pushed 2026-09-22, 1.5k★, 0.19.0 on docs.rs, active release cadence (0.17.0 Sep 2025 "huge release") | **active** — pushed 2026-04-08, 3.1k★ (AGS v3/Astal; Aylur still active but slow) | **active** — pushed 2026-09-21, 3.1k★, v0.3.1 (2026-08-21), v0.3.0 (2026-05-04), v0.2.1 (2025-10-12) | **active** — pushed 2026-09-24, 782★, 0.10.15 (2026-07) | **active** — pushed 2026-07-17, 12.7k★ (but low commit frequency; known leak history) | **active** — pushed 2026-09-24, 1.1k★, v0.9.0 | active (jas-singhfsu/HyprPanel; AGS v2/Astal migration in progress, new features paused per README) |
| Reproduces Omarchy bar *look* (rounded pill sections, popup panels, hover-reveal, theme tokens from wallpaper) | partial — pill styling via CSS, no wallpaper-derived theming engine, no popup panels (tooltips only); `group/drawer` gives hover-reveal[39] | partial — CSS theming + popups, no wallpaper theming, no Omarchy pill styling out of box | high (it's the same tech class as quickshell — QML/JSX widgets, popups, any look) | **exact** (it IS the Omarchy stack) | partial (GTK3 look, less themable) | low (custom widgets, no panel system) | partial (pre-styled panels, close-ish look, no wallpaper theming) | high (most "Omarchy-adjacent" look among non-quickshell bars) |
| Reproduces Omarchy bar *widget set* | ~85% (see §1 mapping) | ~75% | ~95% (you write the widgets) | 100% (it's Omarchy's) | ~70% | ~50% | ~85% | ~90% |
| Config surface | JSON + CSS (hand-edit) | TOML + CSS | TypeScript (code-first) | QML (code) | GUI config tool | Yuck+SCSS | TOML | TSX + GUI |
| Deps weight | 1 binary, ~15 shared libs | Rust binary + GTK4 (26 MB w/ all features, 5 MB stripped) | gjs + GTK3/4 + Astal libs + your code | Qt6 stack (heavy) | **27 deps** incl. python, python-gobject, python-i3ipc, playerctl[28] | Rust + GTK3 | iced/wgpu stack | AGS/Astal + waybar-substitutes |

**Not carried forward** (rationale):
- **Riftbar** (new GTK4 Rust bar, AUR `riftbar-bin`, ~3 MB binary): interesting but
  single-maintainer, "except tray" for now (author's own comment in r/hyprland 1qkx1wm);
  Omunchy needs tray. Too immature for a distro default.
- **fabric / Ax-Shell** (GTK+Python, GNOME-shell-flavoured): niche, no mature
  quickshell-class bar project, no measured numbers, smaller ecosystem than AGS.
  Not viable as a *default* for a lean distro.
- **sfbar / other new entrants**: nothing found in search with the module surface or
  traction needed for a distro default (checked 2026-09-24; happy to re-check on request).
- **Noctalia / DankMaterialShell / Caelestia / Anomshell / ChillPill-Shell**: all
  quickshell-based full shells. Omunchy's bloat definition explicitly excludes shell
  daemons, so they're out by rule, not by merit. (Noctalia 5's C++ rewrite is notable —
  ~6× less memory per monitor than its Qt version — but still a full shell, not a bar.)

---

## 3. Measured idle RAM + startup cost

Sources for numbers: community measurements and maintainer statements, not first-party
benchmarks — no bar project publishes rigorous RAM numbers, so all figures below are
anecdotal but directionally consistent across multiple independent reports.

| Bar | Idle RAM | Source |
|---|---|---|
| **Waybar** | **40–75 MB** typical; ~50–60 MB "for a general config"[19]; "waybar consumes something like 75M"[22]; "50-70mb"[21]; "~40 mb"[20] | multiple independent r/hyprland reports (1poxtsg, 1rma4j7, 1q9yndh, 1lt030e) |
| **quickshell** (Omarchy's stack) | **140–400 MB**, most reports land 200–300 MB idle; "base with all the qt libs is around 160 mb"[20]; "200mb-300mb... just it running none of your things"[20]; ChillPill-Shell (quickshell) reports RAM 200–500 MB avg 380[37]; Omarchy 4's own claim: whole shell "under 300 MB of runtime memory once shared libraries are accounted for"[36] | multiple r/hyprland + project READMEs |
| **HyprPanel** | ~150 MB idle (waybar ~75 MB on same machine)[34] | r/hyprland 1ls9sbq |
| **ashell** | ~100 MB at start, ~130 MB with a full config; maintainers: "in a normal situation, we're around 100Mb"; wgpu empty app takes >50 MB; `tiny-skia` CPU renderer option could save ~80 MB | MalpenZibo/ashell issue #529 (maintainer responses) |
| **eww** | ~50–64 MB typical[20]; **but** documented growth bug: "Eww daemon starts at 49 megs... grows to 400 (and over) megs over time" with the Hyprland wiki's own workspaces widget (issue #794, 2023, open) | elkowar/eww#794 |
| **nwg-panel** | no credible first-party or community measurement found (searches 2026-09-24 returned nothing; Python+GTK3 with 27 runtime deps suggests a middle-of-pack footprint — flagging as *unmeasured*, not *light*) | — |
| **Ironbar** | binary size: **26 MB** with all features, **<5 MB** stripped (author statement in r/hyprland 1qkx1wm); *runtime RAM*: no credible published measurement found — flagging as unmeasured | r/hyprland 1qkx1wm |
| **AGS/Astal** | no published measurements; GTK+JS implies heavier than waybar, lighter than Qt quickshell; flagging as *unmeasured* | — |

Startup cost: none of the candidates publish startup-latency numbers. Qualitatively,
waybar (C++/GTK3) and ironbar (Rust/GTK4) start fastest; quickshell (Qt6 QML engine) and
AGS (JS engine + GTK) are noticeably slower to first paint. On Chromebook-class hardware
this is a minor but real differentiator in favour of waybar.

---

## 4. Verdict for Omunchy (lean, 4–8 GB Chromebook-class, no shell daemons, waybar already configured)

### 🥇 Waybar — keep, extend config

**Decisive reasons:**
1. **Cheapest bar that can render the widget set.** 40–75 MB[19][20][21][22] vs
   140–400 MB for quickshell[19][20][21][37] — the very stack Omarchy runs on. On a
   4 GB Chromebook that's a 100–300 MB saving for zero functional loss on the widgets
   Omunchy actually needs.
2. **Native Hyprland modules cover Omarchy's core bar one-for-one** (`hyprland/workspaces`,
   `hyprland/window`, `hyprland/language`) — no scripting, no polling, event-driven via the
   Hyprland IPC module[13][14][15].
3. **Zero new daemons** — matches Omunchy's bloat definition exactly. quickshell,
   HyprPanel, DankMaterialShell, Noctalia are all out of scope by rule.
4. **Already configured in Omunchy's airootfs** (parity row 12) — switching bars costs
   work and gains nothing Omunchy actually wants.
5. **Extremely mature** — pushed 2026-09-24, 12.0k★, 3 releases in 15 months[13]. Waybar's
   Hyprland modules are in-tree upstream (the old waybar-hyprland fork is historical; the
   `hyprland/*` modules ship in the standard waybar package on Arch[14][15]).
6. **Tray is mature**, with per-app icon customization, ordering, and passive-item
   control[16][40] — enough to approximate Omarchy's drawer behaviour with `group/drawer`.

### 🥈 Ironbar — the credible "if waybar ever isn't enough" fallback
1. **Rust + GTK4, active, feature-rich**: `sys_info` module (CPU/RAM/temp/disk/net),
   `tray`, `clock` (calendar popup), `script`/`custom` modules for anything missing,
   CSS theming with hot-reload, `on-click`/`on-click-middle`/`on-click-right` on modules,
   IPC for external control — closer to Omarchy's *interaction model* than waybar's
   click-only modules[23][26].
2. **Scales down**: with all features disabled it's <5 MB binary (author
   statement[38]); feature-flags let Omunchy compile only the modules it wants.
3. **Why not #1**: no measured idle-RAM numbers (only binary size), fewer Hyprland-native
   niceties than waybar's `hyprland/*` modules (workspaces are good but the active-window
   and language modules are less configurable), no Omarchy-like notification center, and
   the widget-level *look* (rounded pill sections, animated reveals) requires more CSS
   gymnastics than waybar's already-documented pill styling.

**Everything else is worse for Omunchy on at least two axes** (memory, or daemon-per-bloat-rule, or unmeasured, or stale).

---

## 5. Omarchy bar config sketch for Omunchy (waybar, module-for-module)

This is the exact widget surface Omarchy quattro ships in `shell.json`'s `bar.layout`,
mapped to waybar modules. Omunchy's defaults should mirror the *default* shell.json layout
(menu, workspaces, indicators, clock, keyboard, weather, update, tray, agents, BT,
network, audio, monitor, power) with the Omunchy substitutions in §5.3.

### 5.1 `~/.config/waybar/config.jsonc` (Omarchy-parity layout)

```jsonc
{
  "layer": "top",
  "position": "top",
  "height": 34,
  "spacing": 4,
  "margin-top": 6,
  "margin-left": 10,
  "margin-right": 10,

  "modules-left":   ["custom/menu", "hyprland/workspaces"],
  "modules-center": ["custom/indicators", "clock", "hyprland/language", "custom/weather", "custom/updates"],
  "modules-right":  ["tray", "custom/agents", "bluetooth", "network", "pulseaudio", "backlight", "battery", "power-profiles-daemon", "custom/power", "mpris"],

  "custom/menu": {
    "format": " omunchy",
    "on-click": "omunchy-menu",           // rofi launcher (Omunchy's omunchy-menu)
    "on-click-right": "foot",             // Omarchy's menu right-click = new terminal
    "tooltip": false
  },

  "hyprland/workspaces": {
    "format": "{icon}",
    "on-click": "activate",
    "format-icons": {
      "active": "󱓻",
      "default": "{id}"
    },
    "on-scroll-up": "hyprctl dispatch 'hl.dsp.focus({workspace=\"e+1\"})'",
    "on-scroll-down": "hyprctl dispatch 'hl.dsp.focus({workspace=\"e-1\"})'"
  },

  "custom/indicators": {
    "format": "{}",
    "exec": "~/.config/omunchy/bar/indicators.sh",   // DnD / NightLight / Recording / StayAwake
    "return-type": "json",
    "interval": 5,
    "on-click": "omunchy indicators-toggle",
    "tooltip": false
  },

  "clock": {
    "format": "{:%a %d %b  %H:%M}",                  // Omarchy uses dddd HH:mm
    "tooltip-format": "<big>{:%A, %d %B %Y}</big>\n<tt><small>{calendar}</small></tt>",
    "on-click": "omunchy-menu-calendar"              // optional; or omit for plain clock
  },

  "hyprland/language": {
    "format": "{}",
    "format-en": "US",
    "on-click": "hyprctl switchxkblayout current next"
  },

  "custom/updates": {
    "format": "{} ",
    "exec": "~/.config/omunchy/bar/updates.sh",      // prints N or '' when 0
    "return-type": "json",
    "interval": 21600,                                // Omarchy's SystemUpdate polls every 6h
    "on-click": "foot -e omunchy-update",
    "signal": 8
  },

  "tray": {
    "icon-size": 16,
    "spacing": 6,
    "show-passive-items": false
  },

  "custom/agents": {
    "format": " {}",
    "exec": "~/.config/omunchy/bar/agents.sh",       // '' when no usage data; else token
    "return-type": "json",
    "interval": 900,
    "on-click": "omunchy-menu-agents"                // or omit entirely if Kev has no agents
  },

  "bluetooth": {
    "format": "{icon}",
    "format-icons": { "enabled": "󰂯", "disabled": "󰂲", "connected": "󰂱" },
    "on-click": "omunchy-menu-bluetooth"             // rofi bluetooth menu (KISS)
  },

  "network": {
    "format": "{icon}",
    "format-icons": { "wifi": "󰤨", "ethernet": "󰈀", "disconnected": "󰤭" },
    "tooltip-format": "{essid} ({signalStrength}%)",
    "on-click": "rofi -show network -modi \"network:nm-dmenu\""
  },

  "pulseaudio": {
    "format": "{icon} {volume:2}%",
    "format-muted": "󰝟",
    "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
    "on-click": "pamixer -t",                        // Omarchy audio right-click = mute
    "on-click-middle": "pavucontrol",
    "on-scroll-up": "pamixer -i 5",
    "on-scroll-down": "pamixer -d 5"
  },

  "backlight": {
    "format": "{icon} {percent}%",
    "format-icons": ["󰃞", "󰃟", "󰃠"],
    "on-scroll-up": "brightnessctl set +5%",
    "on-scroll-down": "brightnessctl set 5%-"
  },

  "battery": {
    "format": "{icon} {capacity}%",
    "format-icons": ["󰁺", "󰁼", "󰁾", "󰂀", "󰂂"],
    "format-charging": "󰂄 {capacity}%",
    "states": { "warning": 20, "critical": 10 },
    "interval": 60
  },

  "power-profiles-daemon": {
    "format": "{icon}",
    "tooltip-format": "Power profile: {profile}",
    "format-icons": { "power-saver": "󰌪", "balanced": "󰾅", "performance": "󰓅" }
  },

  "custom/power": {
    "format": "󰐥",
    "on-click": "~/.config/omunchy/bin/powermenu"    // existing Omunchy powermenu (parity row 17)
  },

  "mpris": {
    "format": "{player_icon} {dynamic}",
    "format-paused": "{status_icon} {dynamic}",
    "player-icons": { "default": "󰏥", "spotify": "󰓇", "mpv": "󰦖" },
    "status-icons": { "paused": "󰐊" },
    "dynamic-order": ["title", "artist"],
    "max-length": 40,
    "tooltip": false
  }
}
```

Note `custom/updates` uses `"signal": 8` + `"interval": 21600` — matching Omarchy's
SystemUpdate.qml, which polls `omarchy-update-available` every 6 h (21600000 ms) and
launches the update on click.

### 5.2 `~/.config/waybar/style.css` (Omarchy-look starter)

```css
* { font-family: "JetBrainsMono Nerd Font"; font-size: 13px; min-height: 0; }

window#waybar {
  background: alpha(@theme_bg_color, 0.85);
  color: @theme_fg_color;
  border-radius: 10px;
}

.modules-left > widget > box,
.modules-right > widget > box {
  background: alpha(@theme_fg_color, 0.06);
  border-radius: 8px;
  padding: 2px 10px;
  margin: 2px 1px;
}

#workspaces button { color: alpha(@theme_fg_color, 0.5); padding: 0 6px; border-radius: 6px; }
#workspaces button.occupied { color: alpha(@theme_fg_color, 0.8); }
#workspaces button.active  { color: @theme_fg_color; background: alpha(@theme_fg_color, 0.12); }
#clock, #tray, #pulseaudio, #battery { color: @theme_fg_color; }
#custom-updates { color: @theme_urgent_color; }
```

### 5.3 Module-to-widget mapping summary

| Omarchy quattro widget | Waybar module used above | Notes |
|---|---|---|
| `omarchy.menu` | `custom/menu` | Omunchy substitutes rofi (`omunchy-menu`) for quickshell's menu plugin |
| `omarchy.workspaces` | `hyprland/workspaces` | exact feature parity; active/occupied styling via CSS classes |
| `omarchy.indicators` | `custom/indicators` script | DnD/nightlight/recording/stay-awake as a small shell script emitting JSON |
| `omarchy.clock` | `clock` | `{calendar}` tooltip gives the month-grid popup equivalent |
| `omarchy.keyboard-layout` | `hyprland/language` | hidden when only one layout configured (`format-en` etc.) |
| `omarchy.weather` | `custom/weather` (optional, not sketched) | Omunchy parity row 16 keeps weather CLI only — bar widget optional |
| `omarchy.system-update` | `custom/updates` | signal-driven, 6 h poll, click → `omunchy-update` |
| `omarchy.tray` | `tray` | SNI tray, per-app icon overrides, ordering |
| `omarchy.agents` | `custom/agents` | Omunchy-specific; omit if no agents |
| `omarchy.bluetooth` | `bluetooth` | panel-equivalent via rofi or `blueman-manager` |
| `omarchy.network` | `network` | nm-applet/nm-dmenu handles the panel-equivalent |
| `omarchy.audio` | `pulseaudio` | right-click mute, scroll volume; panel-equivalent via `pavucontrol` |
| `omarchy.monitor` (brightness) | `backlight` | the CPU/RAM/temp part isn't in Omarchy's default bar anyway |
| `omarchy.power` | `battery` + `power-profiles-daemon` | Omunchy can also omit p-d if not wanted |
| `omarchy.media` (opt-in) | `mpris` | built-in module, no scripting |
| `omarchy.active-window` (opt-in) | `hyprland/window` | built-in module |

---

## 6. What Omarchy's bar does that NO standalone bar replicates

Honest deltas (each verified against quattro source):

1. **It is not just a bar** — it's the host for the menu, the notification toasts+history,
   the OSD, the lock screen, and the AI-agent usage panel, all sharing one Qt6 process
   and one theme engine (`shell/README.md`: "The Omarchy desktop runs in one long-lived
   Quickshell process. Its bar, panels, overlays, menus, and services are plugins hosted
   by `shell.qml`"). No standalone bar bundles a menu, toasts, lock screen and OSD.
   Omunchy covers this with rofi + mako + a lock-screen of its choice — deliberately
   separate processes, per Kev's bloat definition.

2. **Theme-coupled rendering** — bar widgets, panels, toasts and menus share a Color
   singleton (`shell/Commons/Color.qml`) so everything restyles instantly on theme change
   and matches the wallpaper-derived palette. A standalone bar with CSS can *look* right
   after manual tuning, but it cannot auto-derive its palette from the wallpaper or
   restyle popups with the same engine. Omunchy's planned static theme files are the
   correct lean substitute.

3. **Rich in-bar click-panels** (`manual/05-the-top-bar.md`: audio panel has per-app
   mixer and output picker; network panel does Wi-Fi scan/connect; bluetooth lists
   devices with battery levels; display panel has per-monitor scaling presets; power
   panel switches power profiles). Waybar modules are *indicators with tooltips*, not
   popup panels — Omunchy approximates each panel with rofi menus or a helper app
   (`pavucontrol`, `nm-connection-editor`, `blueman-manager`), which is fine but is a
   different UX than Omarchy's in-bar popups.

4. **Tray drawer with pin/hide manager** (`Tray.qml` implements hover-reveal + per-item
   pin/hide persistence). Waybar's `tray` shows icons statically and supports per-app
   icon overrides and ordering, but no hover-drawer. `group/drawer` gives a *group-level*
   hover-reveal (hide all but one module until hover), not a per-tray-icon drawer. Close
   enough visually; not a 1:1 interaction.

5. **Bar-widget plugin API with IPC** (`shell/services/BarWidgetRegistry.qml` +
   `PluginBarWidgetRegistryApi.qml` + `bin/omarchy-bar put/remove`): third-party widgets
   install dynamically and register over IPC at runtime. Parity row 28 strips this for
   Omunchy ("waybar config is hand-edited") — correct decision, but it means Omunchy
   users don't get Omarchy's community widget ecosystem. Any new widget in Omunchy means
   a hand-edited JSON/CSS pair, not an installable plugin.

6. **Center section "anchor" + hover-reveal behaviour** (`shell.json`'s
   `centerAnchor: omarchy.clock`; `Indicators.qml`'s hover-reveal logic is a custom
   `Indicators` widget, not a generic group). No standalone bar has this exact
   anchor-then-reveal interaction; waybar's `group/drawer` is the closest analogue but
   different semantics.

7. **Idle integration in shell.json** (`idle.screensaver` 150s / `idle.lock` 300s live
   alongside the bar config). No standalone bar owns idle state; Omunchy needs
   `hypridle` (or `swayidle`) configured separately — worth noting because Omarchy gets
   it "for free" inside the same config file.

---

## 7. Confidence & gaps

- **Waybar module coverage**: verified against Arch man pages[14][15][16][17][18] and the
  Waybar README compositor-support table[13]. Solid.
- **Idle-RAM numbers**: all from community reports or maintainer statements, never
  first-party benchmarks. nwg-panel, ironbar runtime, AGS runtime have **no credible
  published measurements** — I did not fabricate numbers for them.
- **Hyprland-module-in-upstream check**: verified `hyprland/workspaces`,
  `hyprland/window`, `hyprland/language` are all shipped in the standard waybar package
  (man pages exist upstream at man.archlinux.org for waybar 0.15.0[14][15]; the old
  third-party `waybar-hyprland` fork is historical). Parity row 12's implicit assumption
  "the waybar Hyprland integration is already upstream" is **correct**.
- **What I did not verify**: exact RAM of Omarchy's full quickshell bar on
  Chromebook-class hardware (only community numbers); ashell/ironbar startup latency;
  whether `omarchy.agents` panel has any waybar-reachable equivalent (it's Omarchy-IPC
  specific, so no).

## Sources

[4] https://raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/bar/widgets/Workspaces.qml — Omarchy Workspaces.qml
[5] https://raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/bar/widgets/ActiveWindow.qml — Omarchy ActiveWindow.qml
[6] https://raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/bar/widgets/Tray.qml — Omarchy Tray.qml
[9] https://raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/notifications/Service.qml — Omarchy notifications Service.qml
[10] https://raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/services/media/BarWidget.qml — Omarchy media BarWidget.qml
[12] https://wiki.hypr.land/Useful-Utilities/Status-Bars — Hyprland Wiki: Status bars
[13] https://github.com/Alexays/Waybar — Waybar GitHub README (compositor support table)
[14] https://man.archlinux.org/man/extra/waybar/waybar-hyprland-workspaces.5.en — waybar-hyprland-workspaces(5)
[15] https://man.archlinux.org/man/extra/waybar/waybar-hyprland-window.5.en — waybar-hyprland-window(5)
[16] https://man.archlinux.org/man/extra/waybar/waybar-tray.5.en — waybar-tray(5)
[17] https://man.archlinux.org/man/extra/waybar/waybar-custom.5.en — waybar-custom(5)
[18] https://man.archlinux.org/man/extra/waybar/waybar-idle-inhibitor.5.en — waybar-idle-inhibitor(5)
[19] https://www.reddit.com/r/hyprland/comments/1poxtsg/themes_configuration_quickshell_and_matugen_in — Reddit: quickshell ~200MB vs waybar 50-60MB
[20] https://www.reddit.com/r/hyprland/comments/1rma4j7/waybar — Reddit r/hyprland Waybar thread (quickshell 200-300MB base)
[21] https://www.reddit.com/r/hyprland/comments/1q9yndh/hyprland_quickshell — Reddit: waybar 50-70MB vs quickshell 140-170MB
[22] https://www.reddit.com/r/hyprland/comments/1lt030e/idle_ram_usage_on_a_minimal_setup — Reddit: minimal Hyprland idle 400-450MB, waybar ~75MB
[23] https://github.com/JakeStanger/ironbar — Ironbar GitHub README
[24] https://ironb.ar/modules/tray — Ironbar tray module docs
[25] https://github.com/JakeStanger/ironbar/releases — Ironbar releases (gtk4 port, tray)
[26] https://docs.rs/crate/ironbar/latest — ironbar 0.19.0 docs.rs (feature flags, philosophy)
[27] https://github.com/nwg-piotr/nwg-panel — nwg-panel GitHub README
[28] https://archlinux.org/packages/extra/any/nwg-panel — Arch package: nwg-panel (27 deps)
[29] https://github.com/elkowar/eww/issues/794 — eww issue #794: RAM growth/leak
[30] https://github.com/MalpenZibo/ashell/issues/529 — ashell issue #529: memory usage ~100-130MB
[31] https://malpenzibo.github.io/ashell/docs/intro — ashell docs: features
[32] https://github.com/Aylur/ags — AGS GitHub (pushed 2026-04)
[34] https://www.reddit.com/r/hyprland/comments/1ls9sbq/noob_trying_to_pick_between_waybar_and_hyprpanel — Reddit: hyprpanel ~150MB vs waybar ~75MB idle
[36] https://codetocloud.io/blog/omarchy-4-quattro-whats-new — codetocloud: Omarchy 4 Quattro (quickshell <300MB, replaces waybar+mako+...)
[37] https://github.com/LUCKYS1NGHH/ChillPill-Shell — ChillPill-Shell (quickshell, RAM 200-500MB avg 380)
[38] https://www.reddit.com/r/hyprland/comments/1qkx1wm/riftbar_waybar_replacement_written_with_rust_and — Reddit 1qkx1wm: ironbar author 26MB / <5MB stripped, riftbar thread
[39] https://man.archlinux.org/man/waybar.5.txt — waybar(5) group/drawer
[40] https://github.com/Alexays/Waybar/wiki/Module:-Tray — Waybar Tray module wiki
[41] https://github.com/Alexays/Waybar/wiki/Module:-Clock — Waybar Clock module wiki
