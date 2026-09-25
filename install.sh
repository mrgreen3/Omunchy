#!/usr/bin/env bash
#
# omunchy — lightweight Omarchy-inspired desktop installer for ArchBang
#
# Layers the desktop onto an existing ArchBang install:
#   1. installs the package stack from packages.x86_64 — everything including
#      the desktop stack (sway included) is official-repo now (the last
#      AUR leftover, networkmanager-dmenu-git, was swapped for the extra/
#      networkmanager-dmenu package: same binary, same config); AUR entries
#      would still go through yay when they exist
#   2. copies the skel configs (foot/waybar/rofi/mako/sway), backing up any
#      existing ones — the sway config is i3-style (config + binds + looknfeel
#      + theme, see airootfs/etc/skel/.config/sway/)
#   3. installs the omunchy CLI into ~/Scripts (on PATH via .bashrc, and
#      the archbang-menu app entry lives there) so keybinds that call
#      ~/Scripts/... and `omunchy <verb>` both resolve
#   4. hands off to bin/omunchy sync for the web app + TUI launchers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.x86_64"
SKEL_DIR="$SCRIPT_DIR/airootfs/etc/skel"

if (( EUID == 0 )); then
    echo "[omunchy] Do not run as root — it calls sudo where needed." >&2
    exit 1
fi

# Package array straight from packages.x86_64: strip comments, drop blanks,
# dedupe (pacman tolerates repeats, but the count should be honest).
mapfile -t PACKAGES < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$PACKAGES_FILE" | awk '!seen[$0]++')

# Split by repo: whatever pacman -Si resolves is official, the rest is AUR.
OFFICIAL=()
AUR=()
for pkg in "${PACKAGES[@]}"; do
    if pacman -Si "$pkg" >/dev/null 2>&1; then
        OFFICIAL+=("$pkg")
    else
        AUR+=("$pkg")
    fi
done

install_base_stack() {
    echo "[omunchy] Installing ${#OFFICIAL[@]} base packages (official repos)..."
    sudo pacman -S --needed -- "${OFFICIAL[@]}"

    if ((${#AUR[@]})); then
        if command -v yay >/dev/null 2>&1; then
            echo "[omunchy] Installing ${#AUR[@]} AUR package(s) via yay: ${AUR[*]}"
            yay -S --needed -- "${AUR[@]}"
        else
            echo "[omunchy] SKIP: AUR packages need yay (${AUR[*]})" >&2
            echo "[omunchy]          Install yay first (~/Scripts/install-yay) and re-run." >&2
        fi
    fi
}

install_configs() {
    local app src dest backup
    for app in foot waybar rofi mako sway omunchy; do
        src="$SKEL_DIR/.config/$app"
        [[ -d $src ]] || continue
        dest="$HOME/.config/$app"
        if [[ -e $dest ]]; then
            backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
            echo "[omunchy] Backing up $dest -> $backup"
            mv "$dest" "$backup"
        fi
        cp -r "$src" "$dest"
        echo "[omunchy] Installed configs: ~/.config/$app"
    done
    # The shipped looknfeel sets this wallpaper on sway start.
    if [[ ! -e $HOME/Backgrounds/aesthetic.jpg && -f $SKEL_DIR/Backgrounds/aesthetic.jpg ]]; then
        mkdir -p "$HOME/Backgrounds"
        cp "$SKEL_DIR/Backgrounds/aesthetic.jpg" "$HOME/Backgrounds/"
        echo "[omunchy] Installed default wallpaper: ~/Backgrounds/aesthetic.jpg"
    fi
    # Install the omunchy CLI into ~/Scripts (already on PATH via .bashrc; the
    # menu/launcher keybinds call ~/Scripts/... paths, and the archbang-menu
    # "Applications" entry is what the dead arch-logo menu should have been).
    # Symlinks rather than copies so `omunchy sync`'s repo-checkout link_bin and
    # this agree on one source of truth.
    mkdir -p "$HOME/Scripts"
    for f in "$SCRIPT_DIR"/bin/omunchy "$SCRIPT_DIR"/bin/omunchy-*; do
        [[ -f $f && -x $f ]] || continue
        ln -sfn "$f" "$HOME/Scripts/${f##*/}"
    done
    echo "[omunchy] Installed CLI: ~/Scripts/omunchy (+ verbs)"
}

install_base_stack
install_configs
echo "[omunchy] Generating web app + TUI launchers..."
exec "$SCRIPT_DIR/bin/omunchy" sync