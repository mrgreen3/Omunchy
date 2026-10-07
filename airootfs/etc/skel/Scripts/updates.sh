#!/usr/bin/env bash
# Waybar custom/updates: pending pacman update count (Omarchy's
# omarchy.system-update widget, waybar edition).
#
# Prints a badge + count when updates are pending, nothing otherwise
# (waybar hides an empty module). Refreshed every 6 h by waybar, or on
# demand: pkill -RTMIN+8 waybar .

set -uo pipefail

# Live session: updating there is pointless (nothing persists) and changes
# what the installer copies, so show no badge.
if [[ -d /run/archiso ]]; then
    printf '{"text": "", "tooltip": "", "class": ""}\n'
    exit 0
fi

# Keyring not initialised (fresh install): checkupdates can't verify the sync
# databases and would silently report "Up to date". Warn once per boot instead.
if [[ ! -s /etc/pacman.d/gnupg/pubring.gpg ]]; then
    flag="${XDG_RUNTIME_DIR:-/tmp}/updates-keyring-warned"
    if [[ ! -e $flag ]] && command -v notify-send >/dev/null 2>&1; then
        notify-send -u normal "Pacman keyring not set up" \
            "Open a terminal and run fix-keys before updating." && : >"$flag"
    fi
    printf '{"text": "󰌆", "tooltip": "Pacman keyring not set up - run fix-keys", "class": "pending"}\n'
    exit 0
fi

n=0
if command -v checkupdates >/dev/null 2>&1; then
    n=$(checkupdates 2>/dev/null | wc -l) || n=0
fi

if ((n > 0)); then
    printf '{"text": "󰚭 %d", "tooltip": "%d updates pending", "class": "pending"}\n' "$n" "$n"
else
    printf '{"text": "", "tooltip": "Up to date", "class": ""}\n'
fi