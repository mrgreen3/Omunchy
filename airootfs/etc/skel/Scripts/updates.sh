#!/bin/bash
# Waybar custom/updates: pending pacman update count (Omarchy's
# omarchy.system-update widget, waybar edition).
#
# Prints a badge + count when updates are pending, nothing otherwise
# (waybar hides an empty module). Refreshed every 6 h by waybar, or on
# demand: pkill -RTMIN+8 waybar  (e.g. after `omunchy update`).

set -uo pipefail

n=0
if command -v checkupdates >/dev/null 2>&1; then
    n=$(checkupdates 2>/dev/null | wc -l) || n=0
fi

if ((n > 0)); then
    printf '{"text": "󰚭 %d", "tooltip": "%d updates pending", "class": "pending"}\n' "$n" "$n"
else
    printf '{"text": "", "tooltip": "Up to date", "class": ""}\n'
fi