# waybar 0.15.0 × Hyprland 0.56.2 (Lua config) — IPC compatibility matrix

> **2026-09-25: superseded.** Omunchy now uses sway with waybar's
> `sway/workspaces` module; the Lua-parser click breakage documented here
> (hyprland/workspaces pill clicks) does not exist on sway — the sway
> module takes the standard AModule click path. Kept as a historical
> record of the Hyprland era.

Audited 2026-09-25
Audited 2026-09-25 against waybar tag `0.15.0` (Arch extra 0.15.0-3) and
Hyprland `0.56.2` (source at `/tmp/hyprland-src`, commit efb50993).
Method: every socket1 string waybar (or our scripts) sends was replayed through
`lua5.4 load()` exactly as Hyprland's `CConfigManager::eval()` does
(`luaL_loadstring("return " .. code)`, raw retry) against the real `hl` API
surface read from Hyprland 0.56.2 source.

## Background: why anything breaks

With a `.lua` config, Hyprland 0.56.2's socket1 `dispatch` handler
(`src/debug/HyprCtl.cpp:1132`) rewrites:

```
dispatch <args>   →   return hl.dispatch(<args>)     # eval'd as Lua
```

`hl.dispatch` (`src/config/lua/bindings/LuaBindingsToplevel.cpp:347`) accepts
**only a dispatcher closure** — the value returned by a `hl.dsp.*` factory call.
Legacy hyprlang dispatch strings (`workspace 5`) become `hl.dispatch(workspace 5)`
→ Lua **syntax error** (`')' expected`), or `nil global` errors.

`hyprctl keyword` is **removed** under the Lua parser
(`dispatchKeyword`: *"keyword can't work with non-legacy parsers. Use eval."*).
`hyprctl eval <lua>` is the live-apply path. `hyprctl dispatch "hl.dsp...."`
works because `dispatchRequest` passes strings containing `(` through
(`in.contains("(")`).

## Matrix

| # | Interaction | Waybar 0.15 internal string (socket1) | Lua-parser verdict | Workaround / owner |
|---|---|---|---|---|
| 1 | Workspace pill click → normal ws (`id>0`) | `dispatch workspace N` | **BROKEN** — syntax error (`')' expected near 'N'`) | upstream-internal, not config-fixable (see §waybar-internal) |
| 2 | Pill click → normal ws, `move-to-monitor: true` | `dispatch focusworkspaceoncurrentmonitor N` | **BROKEN** — same syntax error | not used by our config (`move-to-monitor` unset → false) |
| 3 | Pill click → named/persistent ws | `dispatch workspace name:X` | **BROKEN** — syntax error | same as #1 |
| 4 | Pill click → special ws (named) | `dispatch togglespecialworkspace X` | **BROKEN** — syntax error | same as #1 |
| 5 | Pill click → special ws (id −99) | `dispatch togglespecialworkspace` | **BROKEN** — runtime error: `hl.dispatch: expected a dispatcher (…)` (`togglespecialworkspace` is a nil global) | same as #1 |
| 6 | Workspaces scroll (our config: `on-scroll-up/down`) | `dispatch hl.dsp.focus({workspace='e+1'/'e-1'})` | **OK** | ours; already fixed pre-0.56 (commit 6ebf15f) |
| 7 | Language module click (our config) | `hyprctl switchxkblayout current next` (child process, not IPC string) | **OK** — `switchxkblayout` is a native socket1 command (HyprCtl.cpp:2034); takes `current|<device>` + `next/prev/<idx>` | ours |
| 8 | Language module event/display | subscribes `activelayout` (socket2); queries `devices` (socket1) | **OK** — `activelayout` emitted (InputManager.cpp:1189/1290/1731); `devices` native | — |
| 9 | hyprland/window, hyprland/submap, windowcount | socket2 queries only (`activewindow`, `closewindow`, `movewindow`, `changefloatingmode`, `fullscreen`, `submap`) | **OK** — all event names still emitted in 0.56.2 | not in our config anyway |
| 10 | Workspaces event stream | subscribes `workspacev2, activespecial, createworkspacev2, destroyworkspacev2, focusedmonv2, moveworkspacev2, renameworkspace, openwindow, closewindow, movewindowv2, urgent, configreloaded` | **OK** — every one is still posted by 0.56.2 (Workspace.cpp:73/82, FocusState.cpp:288, Window.cpp:580/1453/1458/1371, Monitor.cpp:1505-1689, KeybindManager.cpp:54, lua/ConfigManager.cpp:854) | — |
| 11 | Urgent tracking | event `urgent` payload = window addr (`%x`); module resolves via `clients` query | **OK** — Window.cpp:1371 posts `urgent` with hex address; `clients` JSON carries `address: 0x…`; CSS `#workspaces button.urgent` still applies | — |
| 12 | Workspaces queries | `j/workspaces, j/clients, j/monitors, j/activeworkspace, j/workspacerules` | **OK** — all native socket1 commands in 0.56.2 (HyprCtl registerCommand list) | — |
| 13 | Polling updates (`persistent-workspaces` etc.) | same socket1 queries | **OK** | — |

### Waybar-internal strings we CANNOT route around (items 1–5)

Read from `src/modules/hyprland/workspace.cpp:69-93` (tag 0.15.0):

- The click handler is `Workspace::handleClicked`, connected directly to
  `m_button.signal_button_press_event()` (line 33) — a **Gtk::Button signal,
  not the AModule event_box path**. `AModule::handleToggle` (which executes
  `on-click` config strings) is wired to the module's `event_box_`
  (`AModule.cpp:51`), while each workspace pill button is nested deeper
  (module event_box → box → `Workspace::m_button`). GTK delivers button-press
  to the deepest handler first (`handleClicked`, connected *after*/capturing
  via `connect(..., false)` = after default handling? — practically:
  `handleClicked` runs **and returns `true`**, which stops propagation, so the
  AModule user-command path never fires for left-click on a pill).
- The `"on-click": "activate"` key in our config does **nothing** for this
  module: `activate` is a sway/wlr-taskbar action concept; hyprland workspaces
  0.15 has no `eventActionMap_` entries and never reads `config["on-click"]`
  for the pill (only `on-click-window` for the taskbar window items,
  workspace.cpp:769 — different handler, `Workspace::handleClick`, which we
  could use but it's for window items, not the pill).
- `on-scroll-*` works because scroll events are **not** intercepted by the
  button — they land on the module `event_box_` → `AModule::handleScroll` →
  our config string is forkExec'd as a shell command. That's why scroll works
  and click doesn't.

**Verdict: pill click is hard-broken in 0.15.0 under any Lua-parser Hyprland.
No config-only fix exists.**

### Upstream status (fix available)

waybar master (post-0.15.0, 848 commits at fetch time 2026-09-25) **fixed
exactly this**:

- `74cf45d` *fix(hyprland): detect Lua protocol without side-effecting dispatch* (2026-07-05)
- `bfd0cfe` *fix(hyprland): detect dispatch protocol via configProvider* (2026-07-30, PR #4320 lineage)
- plus `2d4fad2`/`f72f84e` stabilization for 0.16.0.

`IPC::dispatch()` on master probes `hyprctl systeminfo` →
`configProvider: lua` (authoritative; version-based detection was wrong
because Hyprland only loads the Lua manager for `.lua` configs) and
**translates legacy dispatchers to the Lua API**:

| waybar internal (legacy) | master emits |
|---|---|
| `dispatch workspace N` | `/dispatch hl.dsp.focus({ workspace = "N" })` |
| `dispatch focusworkspaceoncurrentmonitor N` | `/dispatch hl.dsp.focus({ workspace = "N", on_current_monitor = true })` |
| `dispatch togglespecialworkspace ""` | `/dispatch hl.dsp.workspace.toggle_special()` |
| `dispatch togglespecialworkspace X` | `/dispatch hl.dsp.workspace.toggle_special("X")` |
| `dispatch workspace name:X` | `/dispatch hl.dsp.focus({ workspace = "name:X" })` (generic fallback) |

All four generated forms replay **OK** through the 0.56.2 parser
(`hl.dsp.focus({workspace="5"})` → `dsp_changeWorkspace`; grammar `name:X`,
`special:`, `e±N`, `m±N`, `r±N`, `empty`, `prev`, `next` all still parsed by
`getWorkspaceIDNameFromString` in 0.56.2's MiscFunctions.cpp).

Packaging: Arch **extra** is at `0.15.0-3` (updated 2026-09-02); there is **no
waybar in unstable** and no 0.16.0 tag yet (master, unreleased as of
2026-09-25). So the fix lands in Arch when upstream cuts 0.16.0 and a packager
picks it up — likely, but not schedulable.

### Degraded UX if we accept 0.15.0 as-is

- **Broken:** left-click on a workspace pill (all 4 dispatch strings syntax-error;
  Hyprland logs the error to its own log, waybar logs "Failed to dispatch
  workspace"). No crash, just a no-op + log spam.
- **Works:** scroll up/down (ours), keyboard binds (ours), urgent styling,
  active-pill styling, window counts, workspace create/destroy updates,
  clock/indicators/tray/etc. (non-Hyprland modules).
- **Alternative navigation that works today:** `Super+1..9`, `Super+Tab`
  (binds.lua), scroll on the pills.

## Our own hyprctl calls (runtime conformance — all verified against 0.56.2)

| Call site | String | Verdict |
|---|---|---|
| waybar config `on-scroll-up/down` | `hyprctl dispatch "hl.dsp.focus({workspace='e+1'})"` | **OK** — Lua syntax valid; `hl.dsp.focus({workspace="e+1"})` is a registered dispatcher; `e±N` grammar alive (MiscFunctions.cpp:380) |
| Scripts/powermenu:8, bin/omunchy-menu:37 | `hyprctl dispatch "hl.dsp.exit()"` | **OK** — `hl.dsp.exit` → `dsp_exit` → `CA::exit()` (Dispatchers.cpp:174/262) |
| bin/omunchy-theme-set:137 | `hyprctl eval 'hl.config({general={col=…},group={col=…}})'` | **OK** — `eval` requires the Lua manager (we have it); `hl.config` registered (LuaBindingsConfigRules.cpp:1393); hyprlang `-` → `_` key mapping (`active_border` under `general.col`) matches 0.56.2 ConfigValues naming |
| bin/omunchy-theme-set:152, bin/omunchy-hypr-reload, binds.lua:58 | `hyprctl reload` | **OK** — native socket1 command; emits `configreloaded` under the Lua manager too (lua/ConfigManager.cpp:854) |
| looknfeel.lua:113, bin/omunchy-bg-set:52 | `hyprctl hyprpaper wallpaper '<path>'` / `",$path"` | **OK** — hyprctl is a *hyprpaper client* in 0.56 (hyprctl/src/hyprpaper/; hyprwire protocol). Grammar `wallpaper [mon],[path],[fit]`; empty monitor + path = all monitors; `fit` arg optional. bg-set sends `",<path>"` = all-monitors → valid |
| .config/omunchy/bar/indicators.sh | `hyprctl hyprsunset temperature [v]` (query + set) | **OK** — hyprctl proxies to hyprsunset's own socket (`.hyprsunset.sock`); bare `temperature` returns current Kelvin, `temperature <n>` sets (hyprwm/hyprsunset IPC) |
| waybar config `hyprland/language` on-click | `hyprctl switchxkblayout current next` | **OK** — native command (HyprCtl.cpp:2034); `current` + `next` are valid forms |
| binds.lua (all) | `hl.bind(..., hl.dsp.*(...))` native Lua | **OK** — parsed by the Lua manager at load, no socket strings involved |

## Event-stream conformance (socket2)

waybar 0.15 subscribes 22 event names; **all are still emitted by 0.56.2**:

`workspacev2` (Monitor.cpp:1506, WorkspacePlacementController.cpp:225) ·
`activespecial` (Monitor.cpp:1567-1689) · `createworkspacev2`/`destroyworkspacev2`
(Workspace.cpp:73/82) · `focusedmonv2` (FocusState.cpp:288) ·
`moveworkspacev2` (WPC.cpp:231) · `renameworkspace` (KeybindManager.cpp:54) ·
`openwindow`/`closewindow` · `movewindowv2` (Window.cpp:580) ·
`urgent` (Window.cpp:1371) · `configreloaded` (lua/ConfigManager.cpp:854) ·
`activewindow(2)`, `windowtitle(2)`, `fullscreen`, `changefloatingmode`,
`submap`, `activelayout` (InputManager.cpp) · `focusedmon`, `workspace`,
`movewindow`, `moveworkspace`.

Workspaces module still updates on switch (`onEvent` → `workspacev2` →
`onWorkspaceActivated` → `dp.emit()`), on urgent (`urgent` →
`setUrgentWorkspace` → `setUrgent()`), and on window open/close. No action
needed on our side.

## Summary

- **Only real breakage**: waybar-internal workspace **pill left-click**
  (5 hardcoded legacy dispatch strings, `src/modules/hyprland/workspace.cpp:74-87`).
  Unfixable from config. **Fixed upstream on master** (configProvider-aware
  `IPC::dispatch` with Lua translation); ships with 0.16.0.
- **Everything else** — scroll, all our scripts' hyprctl calls, the event
  stream, language switching, urgent — is conformant under 0.56.2.
- Recommendation: **accept degraded UX (click ≠ switch) until Arch extra
  ships waybar 0.16.0**; do NOT pin/patch (lean rule). Watch
  `archlinux.org/packages/extra/waybar` for 0.16.0; the workaround
  documentation is this file. Optionally file/link upstream issue
  (already fixed there, so nothing to file).