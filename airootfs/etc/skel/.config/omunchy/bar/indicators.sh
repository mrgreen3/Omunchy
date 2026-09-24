#!/bin/bash

# omunchy:summary=Waybar indicators: DnD / night light / recording / stay awake (JSON for the bar; `toggle` flips DnD + night light)
# omunchy:args=[toggle|toggle-night|--help]
# omunchy:examples=omunchy indicators-toggle

# Omarchy quattro omarchy.indicators widget, waybar edition
# (docs/bar-research.md §5). Emits one JSON object for waybar's
# custom module: combined text, tooltip, and CSS classes.
#
# Every check is non-fatal: if the tool for a state is missing or the
# service is not running, that indicator simply shows nothing.
#
# State sources (mirroring Omarchy's quattro widgets):
#   dnd         makoctl mode  (mode "do-not-disturb" present = on)
#   night       hyprctl hyprsunset temperature < 6000K = on
#               (bin/omarchy-toggle-nightlight: identity 6000K)
#   recording   pgrep -f "^wf-recorder|^gpu-screen-recorder"
#   stay-awake  pgrep -f "systemd-inhibit.*omunchy-stay-awake"
#               (a tagged systemd-inhibit sleep process is inspectable and
#               daemon-free — see stayawake_toggle below)

set -uo pipefail

ICON_DND="󰂛"
ICON_NIGHT="󰔎"
ICON_REC="󰻂"
ICON_AWAKE="󰅶"
IDENTITY_TEMP=6000
NIGHT_TEMP=4000

# --- state checks (each independent, each non-fatal) -------------------------

dnd_on() {
    command -v makoctl >/dev/null 2>&1 || return 1
    makoctl mode 2>/dev/null | grep -q do-not-disturb
}

night_on() {
    command -v hyprctl >/dev/null 2>&1 || return 1
    local temp
    temp=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+' | head -n1) || return 1
    [[ -n $temp && $temp -lt $IDENTITY_TEMP ]]
}

recording_on() {
    pgrep -f '^wf-recorder|^gpu-screen-recorder' >/dev/null 2>&1
}

awake_on() {
    pgrep -f 'systemd-inhibit.*omunchy-stay-awake' >/dev/null 2>&1
}

# --- actions ------------------------------------------------------------------

toggle_dnd() {
    command -v makoctl >/dev/null 2>&1 || return 0
    makoctl mode -t do-not-disturb >/dev/null 2>&1 || true
}

ensure_hyprsunset() {
    pgrep -x hyprsunset >/dev/null 2>&1 && return 0
    command -v hyprsunset >/dev/null 2>&1 || return 1
    setsid hyprsunset >/dev/null 2>&1 &
    sleep 0.5
}

nightlight_toggle() {
    # Start hyprsunset lazily; a fresh instance carries no tint until set.
    ensure_hyprsunset || return 0
    if night_on; then
        target=6500
    else
        target=$NIGHT_TEMP
    fi
    # hyprsunset applies its boot temperature after startup — resend until
    # the value sticks (same workaround as Omarchy's toggle script).
    for _ in {1..10}; do
        hyprctl hyprsunset temperature "$target" >/dev/null 2>&1 || true
        sleep 0.2
        current=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+' | head -n1)
        [[ $current == "$target" ]] && return 0
    done
}

stayawake_toggle() {
    if awake_on; then
        pkill -f 'systemd-inhibit.*omunchy-stay-awake' >/dev/null 2>&1 || true
    else
        # Inhibit idle, self-terminating after 8 h (no daemon to manage)
        setsid systemd-inhibit --who=omunchy-stay-awake --what=idle \
            --why='Stay awake (bar toggle)' sleep 28800 >/dev/null 2>&1 &
    fi
}

# --- output -------------------------------------------------------------------

render() {
    local parts=() classes=() tips=()

    if dnd_on; then
        parts+=("$ICON_DND")
        classes+=("dnd")
        tips+=("DND: notifications silenced")
    fi
    if night_on; then
        parts+=("$ICON_NIGHT")
        classes+=("night")
        tips+=("Night light on")
    fi
    if recording_on; then
        parts+=("$ICON_REC")
        classes+=("recording")
        tips+=("Screen recording")
    fi
    if awake_on; then
        parts+=("$ICON_AWAKE")
        classes+=("awake")
        tips+=("Stay awake")
    fi

    # No active indicators: emit empty text (waybar hides the module)
    if ((${#parts[@]} == 0)); then
        printf '{"text": "", "tooltip": "", "class": ""}\n'
        return 0
    fi

    # tooltip newlines must be JSON-escaped; class is a JSON array of
    # CSS class names (waybar applies each to #custom-indicators.<class>)
    local text=${parts[0]} tip=${tips[0]} i json_classes=""
    for ((i = 0; i < ${#classes[@]}; i++)); do
        [[ $i -gt 0 ]] && json_classes+=", "
        json_classes+="\"${classes[$i]}\""
    done
    for ((i = 1; i < ${#parts[@]}; i++)); do
        text+=" ${parts[$i]}"
        tip+="\\n"${tips[$i]}
    done
    printf '{"text": "%s", "tooltip": "%s", "class": [%s]}\n' "$text" "$tip" "$json_classes"
}

case ${1:-} in
toggle)
    toggle_dnd
    ;;
toggle-night)
    nightlight_toggle
    ;;
--help | -h)
    echo "Usage: indicators.sh [toggle|toggle-night]"
    echo "  (no args)  print waybar JSON state"
    echo "  toggle     toggle do-not-disturb (mako)"
    echo "  toggle-night  toggle night light (hyprsunset 4000K)"
    exit 0
    ;;
esac

render