# Extras feature — test results (rc-051126) and open items

Date: 2026-11-05
ISO: `out/omunchy-rc-051126-x86_64.iso` (commit `fd26ade` "Extras: curated Omarchy packages via a filtered pacman repo")
Tested on: `omunchy-test` VM (installed system), `192.168.122.154`, user `mrgreen`

## Verdict: the feature works

Tested the whole Extras path end to end on an installed system.

| Test | Result |
|---|---|
| `pacman.conf` `[omunchy-extras]` section after `obinstall` | present, correct |
| Baked DB `/var/lib/omunchy/extras/omunchy-extras.db` | 504 B, contains **only** `herdr-0.9.1-2/desc` |
| Isolation: `pacman -Si omarchy` / `omarchy-settings` / `omarchy-herdr` | all "package was not found" |
| `pacman -Sl omunchy-extras` | exactly one package: `herdr 0.9.1-2` |
| `omunchy-install-extras herdr` | installed → `/usr/bin/herdr`, `herdr --version` → `0.9.1` |
| Signature verification | `Good signature from "Omarchy <pkgs@omarchy.org>"`; sha256 of fetched pkg == desc |
| `omunchy-remove-extras herdr` | removed cleanly |
| `pacman -Syu` with the `file://` repo | no errors, "nothing to do" |
| `omunchy-update` (full) | DB refresh + `-Syu` both fine |
| `omunchy-extras-db` refresh as user | rewrites DB fine |
| Migration (simulated old install: removed keyring files, DB, pacman.conf section) | migration re-added all three **in the right order** |
| Migration **idempotency** (re-ran it) | no duplicate section, still exactly 1 |
| Live-session guard | `omunchy-install-extras` → "available after installing Omunchy (obinstall)." |
| Live ISO pacman.conf | no `[omunchy-extras]` — stays pure Arch |
| `$arch` expansion in `CacheServer` | resolves to `x86_64` |

`$arch` note: `Architecture = auto` in pacman.conf, but pacman substitutes the real
arch, so `CacheServer = https://pkgs.omarchy.org/stable/$arch` →
`.../stable/x86_64/` → 200. The non-arch path 404s, so this matters.

## Open item 1 — `omunchy-remove-extras` prompt (NOT a --noconfirm bug)

Earlier I reported this as a `--noconfirm` bug. **That was wrong.** Verified against
pacman 7.1.0 source (`src/pacman/util.c`, `question()`):

```c
if(config->noconfirm) {
    fprintf(stream, "\n");
    return preset;      /* <- returns immediately, prints prompt but auto-answers */
}
```

So with `--noconfirm` pacman **prints** `:: Do you want to remove these packages? [Y/n]`
and answers "yes" itself without reading stdin. It does **not** block. Confirmed on the VM:
`timeout 5 pacman -R --noconfirm ... < /dev/null` returned immediately, exit 0.

The confusing part is only cosmetic: the prompt line still appears in the output.
`bin/omunchy-remove-extras` already passes `--noconfirm` correctly. **No fix needed.**

### But: a real, adjacent problem — "Command aborted"

`omunchy-remove-extras` aborts with `Command aborted` when run **non-interactively**
(no TTY), e.g. over SSH from an agent. Cause: `sudo pacman -R` needs a password,
there's no TTY to prompt on, and the configured `SUDO_ASKPASS` is the GTK3
`omunchy-askpass` box, which needs a Wayland session — none over SSH.

The repo already has the right idiom in `omunchy-install-gpu`, `omunchy-install-snapper`
and `omunchy-install-yay`:

```bash
SUDO=(sudo)
[[ ! -t 0 && -n ${SUDO_ASKPASS:-} ]] && SUDO=(sudo -A)
```

`bin/omunchy-install-extras` and `bin/omunchy-remove-extras` do **not** use it — they
call bare `sudo`. Both should adopt the `SUDO=(...)` pattern so an agent-driven run
either uses the askpass box or fails with a clear message instead of "Command aborted".

TODO: apply the `SUDO=(sudo)` / `sudo -A` pattern to
`bin/omunchy-install-extras` and `bin/omunchy-remove-extras`.

## Open item 2 — installed system keeps a NOPASSWD sudoers rule

Diff of live ISO `/etc/sudoers` vs the installed system's:

```
125c125
< # %wheel ALL=(ALL:ALL) ALL
> %wheel ALL=(ALL:ALL) ALL
128c128
< # %wheel ALL=(ALL:ALL) NOPASSWD: ALL
>  %wheel ALL=(ALL:ALL) NOPASSWD: ALL     <- ACTIVE
139c139
< @includedir /etc/sudoers.d
> #@includedir /etc/sudoers.d
```

`obinstall` intends the opposite of the last two: `phases.sh:253` removes the live
`10-live-nopasswd` drop-in and `phases.sh:257` uncomments
`%wheel ALL=(ALL:ALL) ALL` (password required) — but the NOPASSWD line is left
**active** and `@includedir` is left **commented out**. Result: `sudo -l` on the
installed system shows `(ALL : ALL) NOPASSWD: ALL`, i.e. wheel has passwordless sudo.

Note the live ISO's `/etc/sudoers` has `#@includedir` *uncommented* and the NOPASSWD
line *commented* — the installed system is the reverse of both. `10-live-nopasswd`
(also NOPASSWD) is correctly removed by `phases.sh:253`, so the two are inconsistent.

The `sed` at `phases.sh:257` only handles the `# %wheel ALL=(ALL:ALL) ALL` line; nothing
touches line 128 or the `@includedir` line. Where the swap comes from is **not yet
identified** — no script in the ISO greps for `includedir`/`NOPASSWD` in
`/etc/sudoers` other than `phases.sh` (checked the whole extracted airootfs).

TODO: find what rewrites `/etc/sudoers` at runtime (check the archiso initramfs /
`/etc/archiso` runtime hooks and the live session's own startup), then decide whether
`phases.sh` should also neutralise line 128 and restore `@includedir`.

## Cleanup done on the VM

- Removed my temporary `/etc/sudoers.d/99-omunchy-askpass-tmp` and
  `/usr/local/bin/omunchy-askpass-tmp` (added only to work around the askpass issue).
- `/etc/pacman.conf` restored **byte-identical** to its pre-test state (diffed).
- `herdr` left installed; `/tmp/pacman.conf.bak` left on the VM as a backup.

## Reproducing the test

```bash
# start the VM
virsh start omunchy-test
# wait for boot, then
sshpass -p live ssh -o StrictHostKeyChecking=no mrgreen@192.168.122.154
```

Live-session-only checks need the ISO booted (no disk): boot `omunchy-test-uefi`
or detach `vda`. The live ISO has no sshd enabled, so live-session checks need the
graphical console (`virsh screenshot omunchy-test /tmp/s.png` works well for this).
