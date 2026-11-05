# Keeping Omunchy in step with upstream Omarchy

Research notes (2026-11-05). Goal: pick a mechanism that keeps the parts of Omarchy we
borrow current, without turning Omunchy into a Hyprland/Quattro fork.

## What upstream is today (verified)

| Fact | Value |
| --- | --- |
| Canonical repo | `https://github.com/omacom/omarchy` (`basecamp/omarchy` 301-redirects there) |
| Licence | MIT (attribution required if code is copied) |
| Default branch | `quattro` |
| Releases | GitHub tags `v4.0.x` … `v4.5.0` (latest `v4.5.0`) |
| Churn | ~100–230 commits/week over the last 12 weeks; hot dirs: `bin/`, `default/`, `themes/`, `migrations/`, `install/`, `manual/`, `shell/` |
| Layout | `bin/`, `default/`, `install/`, `migrations/`, `themes/`, `config/`, `etc/mise/`, `agents/skills/`, `docs/`, `manual/`, `shell/` (new QML "Quattro" shell) |
| Packaging | Two packages built from a separate repo `omacom/omarchy-pkgs` (`omarchy`, `omarchy-settings`) + `omarchy-keyring`, `omarchy-nvim`; published per channel (`stable`/`rc`/`edge`) at `pkgs.omarchy.org` |
| Upstream's own update model | Package-backed: `omarchy update` → pacman guard → migrations (per-user markers) → `omarchy-update-mise` → restart checks; a `dev` channel links a git checkout and fast-forwards it; `omarchy-update-available` (bar widget) reports upstream commits |

Omunchy already mirrors upstream's *shape* (`bin/`, `default/`, `migrations/`, git checkout in
`~/.local/share/omunchy`), which is why the gap is not "how do we pull" but "which upstream
subsystems do we track, and by what mechanism".

## Where upstream and Omunchy actually overlap

Mapped upstream path → Omunchy consumer. This table is the raw material for every option below.

| Upstream path | Omunchy counterpart | Drift risk | Notes |
| --- | --- | --- | --- |
| `etc/mise/conf.d/omarchy-tools.toml` | `default/agents.tsv`, `bin/omunchy-install-ai` | **high** | Upstream now uses mise *registry shorthands* (`opencode = {...}`) and `auto_update = "4h"`. Omunchy still pins `aqua:anomalyco/opencode` and has no auto-update policy. Tool list changes weekly. |
| `agents/skills/mise-tools.md` | `bin/omunchy-install-ai`, Guide.md | medium | Upstream's rules for declaring tools (shorthand vs explicit backend, `lazy`, `minimum_release_age`) — directly applicable. |
| `install/omarchy-*.packages` | `packages.x86_64` | medium | Upstream list is 172+92 lines incl. `hyprlock`/`quickshell` etc. Useful as a "what did we miss" checklist, not as a source of truth. |
| `default/hypr/*`, `config/hypr/bindings.lua` | `airootfs/etc/skel/.config/mango/config.conf` | medium | Upstream keybind conventions still the reference (README claims parity). Hyprland-specific, so mapping is manual. |
| `themes/*/colors.toml`, `themes/*/backgrounds/` | `airootfs/etc/skel/.config/noctalia/palettes/Omunchy.json`, `Backgrounds/` | medium | Omunchy already borrows two wallpapers with a CREDITS table — the attribution workflow exists, just not automated. |
| `shell/Ui/*`, `shell/plugins/bar` (Quattro tokens, `shell.toml`) | `airootfs/etc/skel/.config/waybar/style.css` | low | Upstream's shell is a different compositor stack (QML/Quickshell); tokens are a design reference only. |
| `docs/update-process.md`, `agents/skills/migrations.md` | `bin/omunchy-update`, `bin/omunchy-migrate`, `docs/rework-spec.md` | medium | Upstream's migration contract (idempotent, per-user markers, update-order rules) is written down and worth copying verbatim. |
| `bin/omarchy-migrate`, `bin/omarchy-update-available` | `bin/omunchy-migrate`, `bin/omunchy-update-available` | low | Omunchy already forked these; upstream is the reference for bug fixes. |
| `shell/`, `bin/omarchy-upgrade-to-quattro`, Quickshell plugins | — | **do not track** | Architectural divergence (Hyprland → Quattro shell). Syncing would undo Omunchy's Mango/noctalia direction. |

## Options

### A. Pinned upstream mirror + mapping manifest + watch command (recommended)

Add upstream as a second remote and track it by *diff*, not by merge.

- `git remote add upstream https://github.com/omacom/omarchy`; fetch shallow (`--depth 200`).
- `vendor/omarchy-ref` — pinned upstream commit we last reviewed.
- `vendor/omarchy-map.tsv` — mapping table above in machine-readable form:
  `area<TAB>upstream_path<TAB>omunchy_path<TAB>level(high|medium|low)`.
- New command `bin/omunchy-upstream`:
  - `check` — fetch, list upstream commits since the pin, grouped by area, exit non-zero if anything in a `high` area changed;
  - `diff <area>` — `git diff <pin>..upstream/quattro -- <upstream_path>` against the current Omunchy file;
  - `bump` — move the pin forward, recording what was reviewed in `docs/upstream-notes.md`;
  - `show <area>` — print the current upstream file for manual porting.
- Trigger: weekly systemd user timer + an "Upstream changes" entry in `omunchy-menu` + a
  notification when `high` areas moved. Nothing auto-merges; a human ports and then bumps the pin.

Pros: zero merge debt, no vendored upstream code to attribute, small and readable, scoped to the
areas we actually borrow. Cons: porting is manual, so it only works if the mapping table is kept
honest; a "high" area can rot between reviews.

### B. Vendor upstream trees with `git subtree`

`git subtree add --prefix=vendor/omarchy <upstream> <ref> --squash` for a chosen subset
(`themes/`, `agents/skills/`, `etc/mise/conf.d/`, `install/*.packages`), then
`git subtree pull` to refresh.

Pros: exact upstream content, one command to update, `git log` shows upstream provenance per file.
Cons: pulls in code we will never use (Hyprland, Quickshell, shell plugins); our edits cause subtree
merge conflicts on every pull; MIT attribution must be maintained per file; the vendored tree
becomes a fork-by-accident (the thing the README says we don't want).

### C. Generate our data files from upstream (best value for the high-drift areas)

Instead of tracking code, treat the churning upstream artefacts as *inputs*:

- `default/agents.tsv` ← generated from upstream `etc/mise/conf.d/omarchy-tools.toml`
  (tool name, shorthand vs explicit backend, `lazy`, `auto_update`, `minimum_release_age`),
  with an Omunchy-side allow-list deciding what is shipped.
- `packages.x86_64` ← cross-check report against upstream `install/omarchy-base.packages`
  ("upstream ships X, we don't") rather than a blind copy.
- `docs/` ← copy `agents/skills/mise-tools.md` and `agents/skills/migrations.md` into
  `docs/upstream/` as reference, with a header naming the upstream commit they came from.

Pros: the parts that change most often (agent/tool tables) get refreshed by a script, not by hand;
keeps Omunchy's own defaults while staying current. Cons: needs a generator + CI to be trusted; a
generator that silently rewrites the shipped table is a footgun, so it should output a *diff/PR*,
never edit the file in place.

### D. Consume upstream's *packages* (not their scripts)

Omarchy publishes a real pacman repo (`https://pkgs.omarchy.org/<channel>/<arch>`, 256 packages,
signed with `omarchy-keyring`). Installing `omarchy`/`omarchy-settings` from it is **not viable**
(they own `/usr/share/omarchy`, `/etc/skel`, ALPM hooks and assume Hyprland + the Quattro shell).
But the other ~245 packages are plain Arch-style builds and *are* usable — as a source of tools
(herdr, superwhisper-bin, the oma-* utilities) and as a model for our own packaging repo.
Full analysis, key bootstrap, repo-order/shadow rules and the three packaging options:
[`omarchy-repo.md`](omarchy-repo.md).

### E. Become package-backed like upstream (the "omarchy-settings" model)

Split Omunchy the way upstream split itself: an `omunchy` package (bin/, migrations, themes) and an
`omunchy-settings` package (skel, /etc drop-ins, fonts, plymouth), built in a separate `omunchy-pkgs`
repo and published to a pacman repo. Then `omunchy update` = pacman + migrations + restart checks,
and `omunchy-update-available` compares the installed package version, exactly as upstream does.

Pros: the "keep up to date" problem disappears for our own files (users update a package); we inherit
a proven update pipeline design (pacman guard, per-user migration markers, channel switching); the
ISO stops being the only delivery vehicle.
Cons: big refactor of the current model (git checkout in `~/.local/share/omunchy`, `obinstall`
copies the live system), needs a repo host and keyring handling, and users currently update via
`omunchy-update` git pull — a transition period where both exist.

### F. Feed-only monitoring (cheapest)

Poll the GitHub Atom feed of `quattro` commits, or a GitHub watch notification, and surface a digest
(no code coupling at all).

Pros: minutes of work, zero maintenance. Cons: no mapping, so you read every commit title;
upstream moves ~150 commits/week, so the signal-to-noise is poor without the mapping table of
Option A.

### G. Manual quarterly review

A short checklist in `docs/` ("read upstream release notes, check the mise table, check themes,
check migration rules") plus a pinned commit recorded in the repo.

Pros: zero machinery. Cons: relies on remembering; upstream ships weekly.

## Comparison

| Option | Effort | Keeps us current | Merge debt | Divergence risk |
| --- | --- | --- | --- | --- |
| A. Pinned mirror + mapping + watch cmd | medium | high (scoped) | none | low |
| B. Subtree vendor | low–medium | medium | high | high |
| C. Generate data files | medium | very high (agents, packages) | none | low |
| D. Upstream pacman repo | low | n/a | n/a | fatal |
| E. Package-backed Omunchy | high | n/a (different problem) | n/a | low, but big refactor |
| F. Feed only | very low | low | none | low |
| G. Manual review | very low | sporadic | none | medium |

## Recommendation

**A + C, and defer E.**

1. Add upstream as a remote with a pin (`vendor/omarchy-ref`) and the mapping manifest
   (`vendor/omarchy-map.tsv`), plus `bin/omunchy-upstream {check,diff,bump,show}` and a weekly timer
   that raises a notification only for `high` areas. Cost: one script, one data file.
2. Generate the agent table and the package-gap report from upstream data instead of hand-editing
   them (C). This removes the highest-drift item (mise tool/agent list) from the manual work.
3. Borrow upstream's *mechanism* docs verbatim where they apply (`agents/skills/migrations.md`,
   `agents/skills/mise-tools.md`) into `docs/upstream/` with attribution, and port concrete deltas:
   registry shorthands instead of `aqua:`/`github:` backends, `lazy = true`, `auto_update = "4h"`,
   `minimum_release_age = "0s"`.
4. Revisit E (package-backed Omunchy) only if the ISO-only delivery model becomes a problem —
   it is an independent decision, not an upstream-tracking one.

Explicitly out of scope: the Quattro/QML shell, Hyprland configs, Quickshell plugins,
`omarchy-upgrade-to-quattro`.

## Legal / attribution

Upstream is MIT: copying code or assets requires keeping the copyright notice. Omunchy already
ships `LICENSES/Omarchy-MIT.txt` and a per-asset table in
`airootfs/etc/skel/Backgrounds/CREDITS.md`. Anything vendored under Option B or C must extend both:
a header naming the upstream file and commit, plus a row in the CREDITS table.

## Quick facts for future reference

- Upstream repo: `https://github.com/omacom/omarchy` (branch `quattro`, MIT).
- Tool table: `etc/mise/conf.d/omarchy-tools.toml`; rules: `agents/skills/mise-tools.md`.
- Migration model: `agents/skills/migrations.md`, `docs/update-process.md`.
- Packages: `install/omarchy-*.packages`; packaging repo: `omacom/omarchy-pkgs`.
