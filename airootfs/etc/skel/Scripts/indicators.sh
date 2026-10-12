#!/usr/bin/env bash

# omunchy:summary=Waybar Do Not Disturb indicator (noctalia notifications; click toggles it)
# omunchy:args=[state dnd|toggle|toggle-dnd|--help]
# omunchy:examples=indicators.sh toggle-dnd

# Omarchy quattro omarchy.indicators widget, waybar edition. Night light and
# stay awake live in noctalia's control centre (Super+C), which has no state
# query for them, so only DnD is shown on the bar.

set -uo pipefail

ICON_DND="󰂛"

dnd_on() {
    [[ $(noctalia msg notification-dnd-status 2>/dev/null) == on ]]
}

# waybar re-runs the module's exec on SIGRTMIN+7 ("signal": 7 in the config),
# so a click updates the icon immediately.
refresh() { pkill -RTMIN+7 waybar >/dev/null 2>&1 || true; }

# Dim ("inactive") until DnD is on, then lit ("active").
state() {
    if dnd_on; then
        printf '{"text": "%s", "tooltip": "Do Not Disturb: on (click to turn off)", "class": "active"}\n' "$ICON_DND"
    else
        printf '{"text": "%s", "tooltip": "Do Not Disturb: off (click to turn on)", "class": "inactive"}\n' "$ICON_DND"
    fi
}

case ${1:-} in
state)
    [[ ${2:-dnd} == dnd ]] || exit 1
    state
    ;;
toggle | toggle-dnd)
    noctalia msg notification-dnd-toggle >/dev/null 2>&1 || true
    refresh
    ;;
--help | -h)
    echo "Usage: indicators.sh [state dnd|toggle-dnd]"
    echo "  state dnd    print waybar JSON for do-not-disturb"
    echo "  toggle-dnd   toggle do-not-disturb (noctalia); 'toggle' is an alias"
    ;;
*)
    state
    ;;
esac
