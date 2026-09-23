#!/usr/bin/env bash
#
# omunchy — lightweight Omarchy-inspired desktop installer for ArchBang
#
# Installs MangoWC + Waybar + Rofi + Mako, generates .desktop entries for
# web apps and TUIs from config, and applies keybinds.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
TEMPLATES_DIR="$SCRIPT_DIR/desktop-entries"

WEBAPPS_CONF="$CONFIG_DIR/webapps.conf"
TUIS_CONF="$CONFIG_DIR/tuis.conf"

APPS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.local/share/icons/omunchy"

log() {
    echo "[omunchy] $*"
}

require_pkgs() {
    log "Checking base stack (mangowc waybar rofi mako chromium)..."
    # TODO: pacman -S --needed mangowc waybar rofi mako chromium
}

install_base_stack() {
    require_pkgs
    # TODO: copy default configs for mango/waybar/rofi/mako into place
    log "Base stack install: not yet implemented"
}

gen_webapp_entries() {
    log "Generating web app .desktop entries from $WEBAPPS_CONF"
    [ -f "$WEBAPPS_CONF" ] || { log "No webapps.conf found, skipping"; return; }
    mkdir -p "$APPS_DIR"
    # Format per line: Name|URL|Icon
    while IFS='|' read -r name url icon; do
        [ -z "$name" ] && continue
        [[ "$name" == \#* ]] && continue
        slug=$(echo "$name" | tr '[:upper:] ' '[:lower:]-')
        out="$APPS_DIR/omunchy-webapp-${slug}.desktop"
        cat > "$out" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Exec=chromium --app=${url} --ozone-platform=wayland
Icon=${icon:-web-browser}
Terminal=false
Categories=Network;WebApp;
EOF
        log "  -> $out"
    done < "$WEBAPPS_CONF"
}

gen_tui_entries() {
    log "Generating TUI .desktop entries from $TUIS_CONF"
    [ -f "$TUIS_CONF" ] || { log "No tuis.conf found, skipping"; return; }
    mkdir -p "$APPS_DIR"
    # Format per line: Name|Command|Icon
    while IFS='|' read -r name cmd icon; do
        [ -z "$name" ] && continue
        [[ "$name" == \#* ]] && continue
        slug=$(echo "$name" | tr '[:upper:] ' '[:lower:]-')
        out="$APPS_DIR/omunchy-tui-${slug}.desktop"
        cat > "$out" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Exec=${TERMINAL:-foot} -e ${cmd}
Icon=${icon:-utilities-terminal}
Terminal=false
Categories=Utility;TerminalEmulator;
EOF
        log "  -> $out"
    done < "$TUIS_CONF"
}

apply_keybinds() {
    log "Applying keybinds: not yet implemented"
    # TODO: template mango keybind config into ~/.config/mango/
}

main() {
    install_base_stack
    gen_webapp_entries
    gen_tui_entries
    apply_keybinds
    log "Done."
}

main "$@"
