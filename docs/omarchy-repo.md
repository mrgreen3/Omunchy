# Using Omarchy's package repo from Omunchy

Research + **tested** notes (2026-11-05). Companion to `upstream-tracking.md` (which covers tracking
upstream *code*). This one answers: can we add `pkgs.omarchy.org`, and can we keep the unwanted
packages out of the way?

Everything below was verified in a throwaway Arch container (rootless docker, `archlinux:latest`,
**pacman 7.1.0 / libalpm 16.0.1**) with a real keyring and the live repo. Nothing was tested on the
host system.

## Facts

| Fact | Value |
| --- | --- |
| Repo URL | `https://pkgs.omarchy.org/<channel>/<arch>`, e.g. `…/stable/x86_64` |
| Channels | `edge` → `rc` → `stable` (forward only) |
| DB | `omarchy.db` (zstd tar), **unsigned** — no `omarchy.db.sig` (404) |
| Packages | signed; `.sig` present (verified `EDDSA 40DFB630FF42BCFFB047046CF0134EE680CAC571`) |
| Keyring pkg | `omarchy-keyring-20251027-1-any` (6.6 KB), key `Omarchy <pkgs@omarchy.org>` |
| Keyring auto-trust | **works**: the `.install` runs `pacman-key --populate omarchy` via the relative path `usr/bin/pacman-key`, which resolves because pacman runs scriptlets with cwd `/`. After `pacman -U` the key shows `[full]`. Needs an initialised keyring (`pacman-key --init`, which every Arch install has). |
| Package count (stable x86_64) | 256 |
| Coupled to Hyprland/Quickshell | 10 (e.g. `omasnap` → `hyprland` + `layer-shell-qt`) |
| Name collisions with Arch today | **5**: `ghostty`, `ghostty-nautilus`, `ghostty-shell-integration`, `ghostty-terminfo` (identical versions `1.4.0-1`), and `quickshell` (Arch `0.3.2-1` vs Omarchy `0.3.2.r7` — theirs is **newer**) |
| Packages whose deps are clean | `herdr` → `gcc-libs glibc` only; `gliff` → `dbus gcc-libs`; files land in `/usr/bin` + `/usr/share` only (no `/etc/skel`, no `/usr/share/omarchy`) |

Because `omarchy.db` is unsigned, the repo needs `SigLevel = Required DatabaseOptional`. That is
safe: an injected package still fails the *package* signature check.

## What is usable, what is not

Usable (plain Arch-style packages, no Omarchy runtime needed): `herdr`/`herdr-app`/`herdr-core`,
`superwhisper-bin`, the `oma-*` utilities (`aether`, `gliff`, `hype`, `omawrite`, `omacalc`,
`omacharts`, `omatrack`, `omareel`, `omafeed`, `omairc`, `omawake`, `monologue`, `elsewhen`),
`ttf-ia-writer`, `ttf-jetbrains-mono-nerd-basic`, `maplemono-nf-cn`, `qmk-hid`, `wayfreeze`,
`v4l2-relayd`, their third-party apps (`1password`, `brave-bin`, `google-chrome`, `zen-browser-bin`,
`spotify`, `dropbox`, `heroic-games-launcher`, `retroarch`, `libretro-*` …).

**Never**: `omarchy`, `omarchy-settings` (own `/usr/share/omarchy`, `/etc/skel`, ALPM hooks, pacman
guard, Hyprland + Quattro shell assumptions). Also avoid `omasnap`/anything pulling `hyprland` or
`quickshell`.

## Filtering: three tested mechanisms

### A. `Usage = Sync Search Install` — the repo is never used for upgrades *(best default)*

```ini
[omarchy]
Usage = Sync Search Install
SigLevel = Required DatabaseOptional
Server = https://pkgs.omarchy.org/stable/$arch
```

`Usage` (pacman ≥ 6.1) is the token list `Sync Search Install Upgrade`. Leaving `Upgrade` out means
the repo is refreshed and searchable, explicit `pacman -S herdr` works, but **`-Su`/`-Syu` ignore it
completely**.

Tested:
- `pacman -Sy` → downloads `omarchy` DB alongside core/extra. ✅
- `pacman -Ss '^herdr$'` → finds it. ✅
- `pacman -Sp omarchy/herdr` → `https://pkgs.omarchy.org/stable/x86_64/herdr-0.9.1-2-x86_64.pkg.tar.zst`. ✅
- Installed `quickshell 0.3.2-1` (Arch build), then `-Su --print` and `-Syu --print`: **quickshell not
  in the upgrade list** — their newer `0.3.2.r7` is never pulled in. ✅
- Explicit reinstall still upgrades on request: `pacman -S omarchy/quickshell` moved it to
  `0.3.2.r7.g2b4501a-1`. ✅

Consequence: packages installed from this repo don't get upgraded by `pacman -Syu`; Omunchy needs a
small `omunchy-update-extras` (or a line in `omunchy-update`) that runs
`pacman -S --needed <list>` for the explicit allowlist. That is arguably a *feature* here.

Note: `Usage = Sync Search Install` is required — `Usage = Install Search` also blocks `Sync`, and
the DB is then never downloaded ("database file for 'omarchy' does not exist").

### B. Full repo + `IgnorePkg` globs — works, but needs upkeep

Listing `[omarchy]` after `[core]`/`[extra]` is **not** enough on its own: with equal or newer
versions pacman prefers their build (that is how `quickshell` would move to `0.3.2.r7`). Globs do
work (`IgnorePkg = quick* omarchy* linux* nvidia* hypr*`), and an ignored package can still be
installed explicitly. Today only `quickshell` actually needs ignoring (the `ghostty*` builds are
byte-identical in version, and repo order settles the tie).

Weakness: a name Arch and Omarchy both ship *later* silently starts shadowing; nothing tells you.

### C. A curated DB that lists only what we ship *(true allowlist, no rehosting)*

A pacman DB is just a tarball of `<pkg>-<ver>/desc` files, and `desc` carries `%FILENAME%`. So we can
publish a tiny DB containing only the packages we allow, and point the repo's server at Omarchy's so
pacman downloads the real file from them — no mirroring, no redistribution, no rebuild.

```ini
[omunchy-extras]
SigLevel = Required DatabaseOptional
Server = file:///var/lib/omunchy/extras          # our DB (a few KB)
Server = https://pkgs.omarchy.org/stable/$arch   # the packages themselves
```

Tested end to end: built a DB containing only `herdr`, `gliff`, `superwhisper-bin` from the extracted
`desc` files (`tar -czf omunchy-extras.db.tar.gz herdr-0.9.1-2 …`, symlinked as
`omunchy-extras.db`), `pacman -Sy` picked it up, `pacman -S gliff`/`herdr` downloaded from
`pkgs.omarchy.org`, fell back correctly past the missing `file://` copy
(`error: failed retrieving … from disk` → then fetched), and verified Omarchy's signature with their
key. ✅

Variants:
- DB generated **locally** by `omunchy-update` from Omarchy's `omarchy.db` (filter list lives in the
  Omunchy checkout — no hosting, no extra URL for users);
- DB hosted on GitHub Pages (`mrgreen.blog/docs` already exists) — then a user only adds a URL.

Pros: the repo appears to contain *only* our packages, so `-Syu` upgrades them and nothing else, no
`IgnorePkg` bookkeeping, no shadowing at all, licence-clean (we host only metadata).
Cons: one more moving part (DB regeneration + a filter list to curate).

### D. Re-host the built packages — **no**

Downloading their `.pkg.tar.zst` files and serving them (re-signed or not) is redistribution:
`superwhisper-bin` is `LicenseRef-proprietary`, browsers and Dropbox have their own terms, and we'd
carry tens of MB per package. Only worth it if we ever *rebuild* from upstream sources, which is the
separate `Omunchy-pkgs` option and much more work.

### E. No repo at all: URL-pinned installs

`omunchy-pkg-add` variant that does `pacman -U https://pkgs.omarchy.org/stable/x86_64/<pkg>-<ver>-…`
(plus `pacman-key --populate omarchy` once). Updates then need the same script with a version bump.
Cheapest dependency-wise, but every version is a manual bump and there is no `-Su` story.

## Recommendation

**A now, C later if the "only show our packages" property is worth it.**

1. `[omarchy]` with `Usage = Sync Search Install`, after `[extra]`, `SigLevel = Required DatabaseOptional`.
2. Ship `omarchy-keyring` (6.6 KB, `any`) in `packages.x86_64` so the key exists offline; `obinstall`
   already runs `pacman-key --init` + `--populate archlinux` in `phases.sh` — add
   `pacman-key --populate omarchy` next to it (the package's own `.install` handles it on a normal
   `pacman -U`, but the ISO's keyring is built by hand, so be explicit).
3. Keep the allowlist tiny and versioned (`default/extras.tsv`): `herdr`, `superwhisper-bin`, and only
   add the `oma-*` utilities/fonts users actually ask for. `omunchy-install-extras` installs them,
   `omunchy-update` upgrades exactly those (`pacman -S --needed`), never a bare `-Syu` from this repo.
4. Add a `omunchy-doctor` check: intersect `pacman -Sl core extra` with `pacman -Sl omarchy` and warn
   on any new shared name (that is the only way shadowing can bite with option A too — a dependency
   of an installed omarchy package resolving to a newer Arch build is fine, but the reverse deserves
   a look).
5. Amend the README principle: "Official Arch repos first. Omarchy's repo (`pkgs.omarchy.org`) is
   used only for tools Arch doesn't ship, is never used for upgrades, and is never a fallback."

## Recommendation for Omunchy (installed systems only)

The live ISO stays **pure Arch**: no foreign repo in `pacman.conf`, no foreign key, nothing to
mirror offline. The extras channel is added by `obinstall` to the *installed* system only.

Design (verified end to end in a container, see "Verified run" below):

```
/etc/pacman.d/omunchy-extras.conf      (written by obinstall into the target's /etc/pacman.conf)
  [omunchy-extras]
  SigLevel = Required DatabaseOptional
  Server = file:///var/lib/omunchy/extras          # our filtered DB (a few KB of metadata)
  CacheServer = https://pkgs.omarchy.org/stable/$arch   # the packages themselves
```

`CacheServer` (pacman ≥ 6.1) is tried before `Server` for package files and never for database
files, so the DB comes from the local `file://` path and packages download straight from Omarchy's
HTTPS server with no `file://` fallthrough error.

### 1. Allowlist DB instead of their whole repo

`default/extras.tsv` in the Omunchy checkout is the single source of truth:

```
# name	label	note
herdr	Herdr	terminal workspace manager for coding agents
```

`bin/omunchy-extras-db` fetches `https://pkgs.omarchy.org/stable/<arch>/omarchy.db`, keeps the
`desc` of the allowlisted names, and writes `omunchy-extras.db` (a tar.gz of `<pkg>-<ver>/desc`).
`%FILENAME%` inside `desc` points pacman at the real file on their server, so **nothing is
rehosted** — only metadata is ours.

Why this beats adding their repo directly:

- users see and can install *only* what Omunchy lists (`pacman -Si omarchy-settings` →
  "package 'omarchy-settings' was not found" — their packages are unreachable);
- `pacman -Syu` upgrades exactly those packages and nothing else, so no separate update path;
- no shadowing is possible: the DB contains our names only, and the generator refuses a name that
  Arch's `core`/`extra` also ships;
- no `IgnorePkg` bookkeeping, no `Usage` trickery, no denylist hook.

### 2. The key: bake it, don't redistribute their package

We need `omarchy.gpg` before the first `-Sy` of their DB, and the install is offline. Their
`omarchy-keyring` package would be redistribution, so bake the three upstream keyring files instead
(≈700 bytes total, public key + trust policy):

```
airootfs/usr/share/pacman/keyrings/omarchy.gpg
airootfs/usr/share/pacman/keyrings/omarchy-trusted
airootfs/usr/share/pacman/keyrings/omarchy-revoked
```

`obinstall` already rebuilds the keyring offline (`pacman-key --init`, `--populate archlinux` in
`phases.sh`); add `pacman-key --populate omarchy` next to it. Verified: key comes up `[full]`.

Key: `EDDSA 40DFB630FF42BCFFB047046CF0134EE680CAC571` (`Omarchy <pkgs@omarchy.org>`).
Maintenance: if upstream rotates the key, refresh the three baked files (their
`omarchy-keyring` pkgver is the signal).

### 3. Where it plugs into the existing code

| Change | File |
| --- | --- |
| allowlist | `default/extras.tsv` (new) |
| DB generator (fetch + filter + tar) | `bin/omunchy-extras-db` (new) |
| install/remove from the allowlist | `bin/omunchy-install-extras`, `bin/omunchy-remove-extras` (new) + `omunchy-menu` entries |
| regenerate the DB before the pacman step | `bin/omunchy-update` (one line) |
| bake the key files | `airootfs/usr/share/pacman/keyrings/omarchy.*` (new, 3 files) |
| trust the key offline | `airootfs/usr/local/lib/obinstall/lib/phases.sh` (`pacman-key --populate omarchy`) |
| repo section + `/var/lib/omunchy/extras` | `obinstall` (appends the section to the target's `/etc/pacman.conf`) |
| bake a current DB into the ISO (install is offline) | `build` (one step) |
| docs | `README.md` principle, `Guide.md` section |

### 4. Verified run (container, pacman 7.1.0)

Baked key → `pacman-key --populate omarchy` → `[full]`; filtered DB + `CacheServer` → `-Sy` lists
only the allowlisted package; `pacman -S herdr` downloads from `pkgs.omarchy.org`, verifies the
signature, installs (no `file://` fallthrough error); `pacman -Si omarchy-settings` → not found.

### 5. What we explicitly do not do

- no `[omarchy]` repo as-is (their `omarchy`/`omarchy-settings` are reachable and would wreck the
  system);
- no redistribution of their `.pkg.tar.zst` files (`superwhisper-bin` is `LicenseRef-proprietary`);
- no `IgnorePkg`/denylist hooks, no `Usage` juggling, no second update mechanism.

### 6. If a simpler (less safe) route is preferred

`[omarchy]` with `Usage = Sync Search Install` + a denylist hook is one config block and no script,
but exposes all 256 packages (including `omarchy-settings`) and needs a hook to guard them.

## Key facts for future reference

- `https://pkgs.omarchy.org/<channel>/<arch>`; DB `omarchy.db` **unsigned**; packages signed by
  `EDDSA 40DFB630FF42BCFFB047046CF0134EE680CAC571`.
- `omarchy-keyring` populates the key on install (relative-path `.install`, cwd `/`); `--populate`
  by hand if you copy the keyring files without pacman.
- `Usage = Sync Search Install` keeps `-Syu` away from the repo while allowing `pacman -S`.
- A filtered `desc`-only DB + their server = allowlist without rehosting.
- Collisions today: `ghostty*` (same version), `quickshell` (theirs newer).
- Packaging repo with reusable CI: `github.com/omacom/omarchy-pkgs`; their shadow list:
  `release/shadowed-packages.txt`.
