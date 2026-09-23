#!/usr/bin/env bash
#
# omunchy — lightweight Omarchy-inspired desktop installer for ArchBang
#
# Installs the base stack, then generates .desktop entries for web apps and
# TUIs from config. Entry generation lives in bin/ — run `bin/omunchy help`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_base_stack() {
    echo "[omunchy] Checking base stack (mangowc waybar rofi mako chromium)..."
    # TODO: pacman -S --needed waybar rofi mako chromium
    # TODO: mangowc comes from the AUR — needs an AUR helper or a prebuilt pkg
    # TODO: copy default configs for mango/waybar/rofi/mako into place
    echo "[omunchy] Base stack install: not yet implemented"
}

install_base_stack
exec "$SCRIPT_DIR/bin/omunchy" sync