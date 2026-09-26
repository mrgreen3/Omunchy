#!/bin/bash
# Omunchy login shell configuration
# Starts sway (Wayland compositor, i3-compatible)

. $HOME/.bashrc

# Environment for the Wayland session: sway does not export session vars
# itself, and `exec`-ed children (foot, chromium, waybar) inherit this env.
WindowManager=sway

# Start sway on TTY1
if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=sway
    export XDG_BACKEND=wayland
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
    export MOZ_ENABLE_WAYLAND=1
    export GDK_BACKEND=wayland,x11
    exec $WindowManager
fi