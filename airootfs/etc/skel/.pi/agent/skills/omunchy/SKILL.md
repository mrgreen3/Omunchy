---
name: omunchy
description: Install apps, web apps, TUI launchers and dev tools on an Omunchy (ArchBang + sway) system. Prefer the omunchy CLI verbs for web apps and TUIs; use the desktop-entry rules here for anything they do not cover (one-off installers like pi.dev, custom scripts, special window rules). Trigger when the user asks to install, add, or wire up a launcher/app on Omunchy, or mentions omunchy.
---

# Omunchy — app installation & launchers

Omunchy is a lean Omarchy-style layer on ArchBang: sway + foot + rofi, no
daemons. This skill covers two things: driving the deterministic `omunchy` CLI,
and the verified desktop-entry rules for the long tail it does not cover.

## 1. Prefer the CLI verbs

The dispatcher is `omunchy` (on PATH via ~/.local/bin, or `~/Scripts/omunchy`).
Routes are self-describing; `omunchy help` lists them. Use these instead of
hand-writing entries whenever they fit:

```
omunchy webapp install <name> <url> [icon] [custom-exec]   # chromium --app window
omunchy tui install <name> <command> [float|tile] [icon]   # foot TUI launcher
omunchy webapp remove / omunchy tui remove                  # pickers
omunchy sync                                                # batch from ~/.config/omunchy/*.conf
omunchy theme set / bg set / update / menu                  # desktop config
```

These scripts already handle icon fetching (apple-touch-icon → well-known →
Google favicons), `foot --app-id=` window rules, and desktop-entry escaping.
Do not reimplement them; call them, then verify the result (see §3).

## 2. Desktop-entry rules for everything else

For one-off installers (pi.dev, custom scripts) write the entry yourself.
These rules are empirically verified against glib (rofi/launcher loader) on
this stack — keep them exactly:

- **Two escaping layers.** The `.desktop` file is a GKeyFile value first
  (where `\\` is a literal backslash) and an Exec-tokenizer string second
  (where `\$` inside double quotes means a literal `$`). So a literal `$`
  inside a double-quoted Exec argument must be written as **`\\$` in the
  file**. Verified forms:

  | file bytes inside `"..."` | glib | result |
  |---|---|---|
  | `\\$` | loads | `$` reaches the shell (correct) |
  | raw `$` | loads (lenient) | validator errors |
  | `\$` (one backslash) | **refuses to load** | entry silently dead |
  | raw `$` unquoted | **silently never executes** | worst case |

- **Robust one-off entry shape.** Wrap the command in the terminal:
  `Exec=foot --app-id=omunchy.Installer -e sh -c "exec ~/path/script arg"`
  — tilde avoids the `$` problem entirely in static entries; `sh -c` keeps
  shell semantics; `exec` folds `sh` away. Sway already floats app-id
  `omunchy.Installer` (see looknfeel).
- **Validation loop, always:** `desktop-file-validate <file>` then a
  `gio launch <file>` probe whose command writes a marker to /tmp; confirm
  the marker before telling the user it works. `desktop-file-validate` is
  necessary but not sufficient (glib is stricter about loading than the
  validator is about `$` in quotes).
- `Terminal=false` for foot-wrapped TUIs (foot provides the terminal);
  entries go to `~/.local/share/applications`; run
  `update-desktop-database ~/.local/share/applications` after writing.
- Icons: install to `~/.local/share/icons/hicolor/256x256/apps/<name>.png`
  then `gtk-update-icon-cache ~/.local/share/icons/hicolor`. Sanitise names
  like the installers do (lowercase, non-alphanumeric runs → `-`).

## 3. Verification, not vibes

After creating anything: validate the entry, launch it once with a probe
(redirect output to a file, check the file), then report the exact command
the user can re-run. If an entry fails `gio launch` silently, check for
raw `$` outside double quotes first.

## 4. Installing pi itself (pi.dev)

Official route, run inside a foot terminal or as a background job with a pty:

```
curl -fsSL https://pi.dev/install.sh | sh
```

Facts: the installer reads prompts from /dev/tty (piping is safe), bootstraps
node/npm itself, installs to `~/.pi/agent/bin` (NOT on the current shell's
PATH until re-login), and needs an API key on first `pi` run. `omunchy pi
install` does all of this with a network precheck and self-cleaning launcher
entry; prefer it when present.

## 5. When to extend bin/omunchy-* instead

If a request becomes a repeated pattern (a third user asking for the same
shape), promote it: add a self-describing `bin/omunchy-<verb>` script with
`omunchy:summary=/args=/examples=` headers and the dispatcher picks it up.
One-off agent work is for one-offs; distro-shipped behaviour belongs in
tested scripts.