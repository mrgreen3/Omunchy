#!/bin/bash

# omunchy:summary=Waybar indicators: DnD / night light / stay awake (one JSON state per mode; click toggles it)
# omunchy:args=[state <mode>|toggle|toggle-dnd|toggle-night|toggle-awake|--help]
# omunchy:examples=omunchy indicators-toggle toggle-night

# Omarchy quattro omarchy.indicators widget, waybar edition
# (docs/bar-research.md §5). Emits one JSON object for waybar's
# custom module: combined text, tooltip, and CSS classes.
#
# Every check is non-fatal: if the tool for a state is missing or the
# service is not running, that indicator simply shows nothing.
#
# State sources (mirroring Omarchy's quattro widgets):
#   dnd         makoctl mode  (mode "do-not-disturb" present = on)
#   night       wlsunset running with -T < 6000K = on (process args; wlsunset
#               has no IPC, identity = wlsunset not running at all)
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
    # wlsunset has no IPC — the tint level lives on its own command line (-T).
    local temp
    temp=$(pgrep -x wlsunset -a 2>/dev/null | grep -oE '\-T [0-9]+' | head -n1 | grep -oE '[0-9]+') || return 1
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

nightlight_toggle() {
    if night_on; then
        # Back to identity: stop wlsunset entirely (no IPC to neutralise the
        # tint — not running = no tint).
        pkill -x wlsunset >/dev/null 2>&1 || true
        return 0
    fi
    # Night on: start wlsunset lazily at the night temperature.
    command -v wlsunset >/dev/null 2>&1 || return 0
    # -T (day) must exceed -t (night, default 4000) or wlsunset refuses to start;
    # night_on() reads -T, so keep it just above -t and below IDENTITY_TEMP.
    setsid wlsunset -T "$((NIGHT_TEMP + 1))" -t "$NIGHT_TEMP" >/dev/null 2>&1 &
    sleep 0.5
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

# waybar re-runs a module's exec on SIGRTMIN+N ("signal": N in the config), so a
# click updates the icon immediately instead of waiting for the poll interval.
SIG_DND=8
SIG_NIGHT=9
SIG_AWAKE=10
refresh() { pkill -RTMIN+"$1" waybar >/dev/null 2>&1 || true; }

# One waybar module per mode: dim ("inactive") until the mode is on, then lit
# ("active"). style.css turns inactive into a faint icon that brightens on hover.
state() { # $1 = dnd|night|awake|recording
    local icon label on=1
    case $1 in
    dnd) icon=$ICON_DND label="Do Not Disturb"; dnd_on && on=0 ;;
    night) icon=$ICON_NIGHT label="Night light"; night_on && on=0 ;;
    awake) icon=$ICON_AWAKE label="Stay awake"; awake_on && on=0 ;;
    recording) icon=$ICON_REC label="Screen recording"; recording_on && on=0 ;;
    *) return 1 ;;
    esac
    if ((on == 0)); then
        printf '{"text": "%s", "tooltip": "%s: on (click to turn off)", "class": "active"}\n' "$icon" "$label"
    else
        printf '{"text": "%s", "tooltip": "%s: off (click to turn on)", "class": "inactive"}\n' "$icon" "$label"
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
state)
    state "${2:-}"
    exit
    ;;
toggle | toggle-dnd)
    toggle_dnd
    refresh "$SIG_DND"
    exit 0
    ;;
toggle-night)
    nightlight_toggle
    refresh "$SIG_NIGHT"
    exit 0
    ;;
toggle-awake)
    stayawake_toggle
    refresh "$SIG_AWAKE"
    exit 0
    ;;
--help | -h)
    echo "Usage: indicators.sh [state <mode>|toggle-dnd|toggle-night|toggle-awake]"
    echo "  state <mode>   print waybar JSON for dnd | night | awake | recording"
    echo "  toggle-dnd     toggle do-not-disturb (mako); 'toggle' is an alias"
    echo "  toggle-night   toggle night light (wlsunset 4000K)"
    echo "  toggle-awake   toggle stay-awake (idle inhibit, 8 h max)"
    echo "  (no args)      print the combined JSON of all active modes"
    exit 0
    ;;
esac

render