# Move a pre-rework install (~/Scripts era) onto ~/.local/share/omunchy/bin.
# Safe to rerun. Only touches files that still match what Omunchy shipped.
set -uo pipefail
D=$OMUNCHY_DIR
H=$HOME
apps=$H/.local/share/applications

# old name -> new name
map="agents-menu omunchy-install-ai
apply-mango-colors omunchy-theme-mango
noctalia-colors omunchy-theme-refresh
fix-keys omunchy-fix-keys
install-gpu omunchy-install-gpu
install-snapper omunchy-install-snapper
install-yay omunchy-install-yay
keybinds-menu omunchy-menu-keybinds
netcheck omunchy-netcheck
radio omunchy-radio
system-update omunchy-update-system
updates.sh omunchy-update-available
omunchy-askpass omunchy-askpass
omunchy-update omunchy-update
omunchy-webapp omunchy-webapp
omunchy-welcome omunchy-welcome
install-opencode omunchy-install-ai"

# 1. PATH: new bin first, ~/Scripts kept for the user's own scripts.
if ! grep -q '.local/share/omunchy/bin' "$H/.bashrc" 2>/dev/null; then
    cat >>"$H/.bashrc" <<'EOF'

# Omunchy commands (added by omunchy-update)
for d in "$HOME/.local/share/omunchy/bin" "$HOME/Scripts"; do
    [[ ":$PATH:" == *":$d:"* ]] || PATH="$d:$PATH"
done
export PATH
EOF
    echo "  ~/.bashrc: added ~/.local/share/omunchy/bin to PATH (open a new terminal)"
fi

# 2. Config references to ~/Scripts/<old>.
files=("$H/.config/mango/config.conf" "$H/.config/waybar/config" "$H/.config/noctalia/config.toml"
    "$H/.config/noctalia/templates.toml" "$H/.bash_profile" "$H/.config/opencode/opencode.json"
    "$apps/radio.desktop")
while read -r old new; do
    [[ $old == install-opencode ]] && continue
    o=${old//./\\.}
    for f in "${files[@]}"; do
        [[ -f $f ]] || continue
        grep -qE "/Scripts/$o\b" "$f" || continue
        sed -i -E -e "s#(~|\\\$HOME|/home/[^/\"]+)/Scripts/$o\b#\1/.local/share/omunchy/bin/$new#g" \
            -e "s#${H//#/\\#}/Scripts/$o\b#$H/.local/share/omunchy/bin/$new#g" "$f"
        echo "  ${f/#$H/\~}: $old -> $new"
    done
done <<<"$map"
# opencode.json allowlist used the bare name
[[ -f $H/.config/opencode/opencode.json ]] &&
    sed -i -E 's#"netcheck( \*)?"#"omunchy-netcheck\1"#g' "$H/.config/opencode/opencode.json"

# 3. Omunchy menu keybind, unless the user already bound Super+Alt+Space.
mc=$H/.config/mango/config.conf
if [[ -f $mc ]] && ! grep -qE 'omunchy-menu([^-]|$)' "$mc" && ! grep -qiE '^bind=SUPER\+ALT,space,' "$mc"; then
    printf '\n#: Omunchy menu\nbind=SUPER+Alt,space,spawn,~/.local/share/omunchy/bin/omunchy-menu\n' >>"$mc"
    echo "  mango: added Super+Alt+Space for omunchy-menu"
    command -v mmsg >/dev/null && mmsg dispatch reload_config >/dev/null 2>&1 || true
fi

# 4. Old copies in ~/Scripts: remove only if byte-identical to a shipped version.
shipped() { # shipped <file> <old name>: is this file's blob in Omunchy's history?
    local blob c
    blob=$(git hash-object "$1")
    git -C "$D" cat-file -e "$blob" 2>/dev/null && return 0
    # shallow checkout: fall back to the current renamed file
    [[ -f $D/bin/$2 ]] && cmp -s "$1" "$D/bin/$2"
}
while read -r old new; do
    f=$H/Scripts/$old
    [[ -f $f ]] || continue
    if shipped "$f" "$new"; then
        rm -f "$f" && echo "  removed ~/Scripts/$old (now $new)"
    else
        echo "  kept ~/Scripts/$old: you changed it. Omunchy's version is now $new; delete yours if not needed."
    fi
done <<<"$map"

# 5. Launchers: each installed agent gets its own entry; "Install AI Agent" adds more.
for id in claude codex copilot crush goose hermes pi; do
    f=$apps/$id.desktop
    [[ -f $f ]] && grep -q 'installed with mise; see Guide' "$f" && rm -f "$f" && echo "  removed old launcher $id.desktop"
done
f=$apps/opencode.desktop
[[ -f $f ]] && grep -q 'install-opencode' "$f" && rm -f "$f" && echo "  removed old launcher opencode.desktop"
f=$apps/agents-menu.desktop
[[ -f $f ]] && grep -qE 'agents-menu|omunchy-launch-ai' "$f" && rm -f "$f" && echo "  removed AI Agents picker launcher"
while IFS=$'\t' read -r id label _; do
    [[ -n $id && ! -f $apps/omunchy-ai-$id.desktop ]] || continue
    "$D/bin/omunchy-install-ai" --launcher "$id" && echo "  added launcher for $label"
done < <("$D/bin/omunchy-agents" installed)
if [[ ! -f $apps/omunchy-install-ai.desktop ]]; then
    mkdir -p "$apps"
    grep -v '^Hidden=true' "$D/airootfs/etc/skel/.local/share/applications/omunchy-install-ai.desktop" >"$apps/omunchy-install-ai.desktop" &&
        echo "  added Install AI Agent launcher"
fi

# 6. Agent instruction files are gone: the Guide is the only one (omunchy-guide skill stays).
for l in .claude/CLAUDE.md .gemini/GEMINI.md .pi/agent/AGENTS.md .config/opencode/AGENTS.md; do
    [[ -L $H/$l && $(readlink "$H/$l") == *omunchy/AGENTS.md ]] && rm -f "$H/$l" && echo "  removed link ~/$l"
done
f=$H/.config/omunchy/AGENTS.md
if [[ -f $f ]]; then
    if git -C "$D" cat-file -e "$(git hash-object "$f")" 2>/dev/null; then
        rm -f "$f" && echo "  removed ~/.config/omunchy/AGENTS.md (rules now live in ~/Documents/Guide.md)"
    else
        echo "  kept ~/.config/omunchy/AGENTS.md: you changed it. Omunchy no longer uses it."
    fi
fi

# 7. OpenCode from pacman (old installer): offer the switch, never remove it ourselves.
if pacman -Q opencode >/dev/null 2>&1; then
    echo "  OpenCode is installed with pacman. Omunchy now installs it with mise. To switch:"
    echo "      sudo pacman -Rns opencode && omunchy-install-ai opencode"
fi
exit 0
