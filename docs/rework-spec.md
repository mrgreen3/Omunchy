# Omunchy scripts/agents rework — spec (draft)

Goal: replace the loose `~/Scripts` collection with an Omarchy-style per-user
tree: namespaced `omunchy-*` commands, one menu hub, agents as ordinary
installables, git + migrations for updates.

## Acceptance criteria

- No file in `/etc/skel/Scripts`; nothing in configs references `~/Scripts`.
- Every user-facing action is an `omunchy-*` command on PATH.
- `omunchy-menu` reaches every action; install entries hidden on live.
- `omunchy-update` = git pull + pending migrations + `pacman -Syu`; idempotent.
- `omunchy-install-ai <id>` / `omunchy-remove-ai <id>` for every table row; the single
  "AI Agents" launcher lists only installed ones (no per-agent .desktop files).
- No AGENTS.md/CLAUDE.md/GEMINI.md: Guide.md is the only agent instructions file (reached via the omunchy-guide skill); it references commands only.
- ISO build + install verified: LUKS UEFI, non-LUKS BIOS; update from a
  pre-rework install migrates cleanly.

## Layout

```
~/.local/share/omunchy/          shallow clone of this whole repo, baked by `build`; dirs below are repo top-level
├── bin/                         on PATH via skel .bashrc + mango env
├── default/                     shipped defaults configs are copied from (rofi themes, webapp presets, agent table)
├── install/                     first-boot/post-install steps called by obinstall
├── migrations/                  <unix-ts>.sh, run once each
├── applications/                .desktop templates
├── themes/                      wallpapers + theme hooks
└── version
~/.local/state/omunchy/migrations/<ts>.sh   empty marker = done
```

## Commands

| New | From | Notes |
|---|---|---|
| `omunchy-menu` | new | rofi hub; sections below |
| `omunchy-update` | `omunchy-update`; calls `omunchy-update-system` (kept for the waybar badge) | pull → migrate → pacman -Syu → yay if present |
| `omunchy-update-available` | `updates.sh` | waybar module |
| `omunchy-migrate` | new | runs pending migrations; called by update |
| `omunchy-install-gpu` | `install-gpu` | |
| `omunchy-install-snapper` | `install-snapper` | |
| `omunchy-install-yay` | `install-yay` | |
| `omunchy-agents` | new | prints the table (shipped + user rows), `installed`, `get <id>` |
| `omunchy-install-ai <name>` | `install-opencode`, Guide mise steps | generic: reads `default/agents.tsv` |
| `omunchy-remove-ai <name>` | new | mise uninstall + drop launcher |
| `omunchy-launch-ai` | `agents-menu` | rofi of installed agents → foot |
| `omunchy-webapp-install` / `-remove` | `omunchy-webapp` | split subcommands |
| `omunchy-menu-keybinds` | `keybinds-menu` | |
| `omunchy-radio` | `radio` | |
| `omunchy-welcome` | same | becomes thin: opens menu Setup section on first run |
| `omunchy-askpass` | same | internal |
| `omunchy-netcheck` | `netcheck` | update opencode.json allowlist |
| `omunchy-fix-keys` | `fix-keys` | |
| `omunchy-theme-refresh`, `omunchy-theme-mango` | `noctalia-colors`, `apply-mango-colors` | kept separate (different triggers); `/home/live` path is rewritten by obinstall |
| `omunchy-pkg-add` / `-missing` / `-present` | new | shared pacman helpers |
| `obinstall` | stays | `/usr/local/bin/obinstall` + `/usr/local/lib/obinstall/`, removed from target by obinstall |

Agent table `default/agents.tsv`: `name  mise-tool  cmd  args  label`
Initial set, matching Omarchy's mise-installed agents: claude, opencode, pi.
opencode moves from `install-opencode` (pacman) to mise. codex, copilot,
crush, goose, hermes and gemini are dropped from the shipped table; a user can
add a row. One table drives install, remove, launcher and menu.

## Menu tree

```
Apps (launch-ai, webapps, radio)
Install   → AI ▸ <agents> · GPU drivers · Snapper · yay · Webapp
Remove    → AI ▸ <installed> · Webapp
Update    → Omunchy · System
Setup     → Keybinds · Theme · Wallpaper
System    → Lock · Logout · Reboot · Shutdown
```
Live session: Install/Remove/Update hidden; adds "Install Omunchy" (obinstall).

## Migrations

- `<ts>-scripts-to-bin.sh`: first migration for pre-rework installs — remove
  stale `~/Scripts/*` that match shipped hashes (leave modified ones, warn),
  rewrite config refs, create launchers for already-installed mise agents.
- Rule: migrations must be idempotent and never touch files the user changed
  (compare to known shipped hash first).

Stage 4 as built: shallow fetch + `checkout -B main origin/main` (refuses on
local edits or an upstream without bin/), re-exec of the pulled script,
wallpapers, `omunchy-migrate` (markers in ~/.local/state/omunchy/migrated),
then `omunchy-update-system`. rc-021126 installs reach it through
`airootfs/etc/skel/Scripts/omunchy-update`, a bridge the old updater copies
over itself (build strips it from the ISO; the migration deletes it). The
first migration also drops old AGENTS.md links and offers (never forces) the
pacman→mise OpenCode switch. No yay step (AUR only on explicit request).

## Stages (one branch, `rework-bin`)

1. Skeleton: tree, PATH, `omunchy-pkg-*`, move scripts with renames, fix refs.
2. Menu + keybind.
3. Agents table, install/remove/launch-ai, launchers.
4. Git checkout + `omunchy-migrate` + update rewrite + first migration.
5. Docs: Guide.md, omunchy-guide skill.
6. ISO build + install tests (on Kev's go).

## Decisions (2026-11-03)

1. Offline: the checkout ships complete with a shallow `.git` baked into skel at
   build time (`git clone --depth 1` of the build commit into
   `airootfs/etc/skel/.local/share/omunchy`, gitignored in the repo). Update
   pulls from upstream once online. No first-boot clone.
2. Upstream: `github.com/mrgreen3/Omunchy`, fixed.
3. Menu: Super+Alt+Space.
4. `~/Scripts` stays as an empty user-owned dir for user scripts.

## profiledef.sh / build

The checkout is cloned by `build` (`_make_omunchy_checkout`) straight into the
pacstrap dir, so git sets the exec bits and no `file_permissions` entry is
needed for `bin/`. Only committed HEAD is baked (warns on dirty bin/migrations).
Existing migrations get done-markers in skel `.local/state`. profiledef keeps
755 for `/usr/local/bin/obinstall` and `/usr/local/lib/obinstall/`; the
`/etc/skel/Scripts/` entry is gone and `~/Scripts` ships with a `.keep`.

## To think about: agent launchers (noted 2026-11-03)

mise installs give no .desktop entry, so OpenCode (and Claude/Pi) don't show in
the main launcher (Super+Space), only under "AI Agents" / the Omunchy menu.
Seen in VM test of rc-031126. Options, undecided:
- `omunchy-install-ai` writes a per-agent .desktop on install, removes it on
  remove (Exec = foot + mise shim; icon from default/ or a generic one).
- OpenCode back to pacman (it is in the official repos, ships its own entry),
  mise only for agents not packaged.
- Keep one "AI Agents" entry but make it obvious (name/keywords per agent).
