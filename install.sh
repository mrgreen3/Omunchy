#!/usr/bin/env bash
#
# omunchy — lightweight Omarchy-inspired desktop installer for ArchBang
#
# Layers the desktop onto an existing ArchBang install:
#   1. installs the package stack from packages.x86_64 — the desktop stack
#      (hyprland included) is all official-repo now that MangoWC is gone;
#      the one AUR leftover (networkmanager-dmenu-git) goes through yay
#      when it exists
#   2. copies the skel configs (foot/waybar/rofi/mako/hypr), backing up any
#      existing ones
#   3. hands off to bin/omunchy sync for the web app + TUI launchers

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
    for app in foot waybar rofi mako hypr; do
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
    # The shipped hyprland.conf preloads this wallpaper by path.
    if [[ ! -e $HOME/Backgrounds/aesthetic.jpg && -f $SKEL_DIR/Backgrounds/aesthetic.jpg ]]; then
        mkdir -p "$HOME/Backgrounds"
        cp "$SKEL_DIR/Backgrounds/aesthetic.jpg" "$HOME/Backgrounds/"
        echo "[omunchy] Installed default wallpaper: ~/Backgrounds/aesthetic.jpg"
    fi
    # Install the omunchy CLI onto PATH so keybinds (SUPER+A menu etc.) and
    # `omunchy <verb>` work from anywhere, not just inside the repo checkout.
    mkdir -p "$HOME/.local/bin"
    for f in "$SCRIPT_DIR"/bin/omunchy "$SCRIPT_DIR"/bin/omunchy-*; do
        [[ -f $f && -x $f ]] || continue
        install -m 0755 "$f" "$HOME/.local/bin/"
    done
    echo "[omunchy] Installed CLI: ~/.local/bin/omunchy (+ verbs)"
}

install_base_stack
install_configs
echo "[omunchy] Generating web app + TUI launchers..."
exec "$SCRIPT_DIR/bin/omunchy" sync