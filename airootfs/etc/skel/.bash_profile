#!/bin/bash
# Omunchy login shell configuration
# Starts mango (Wayland compositor)

. $HOME/.bashrc

# Password helper for `sudo -A` (see ~/Documents/Guide.md)
export SUDO_ASKPASS=$HOME/.local/share/omunchy/bin/omunchy-askpass

# Environment for the Wayland session, also used when greetd starts
# omunchy-session: `exec`-ed children (foot, firefox, waybar) inherit it.
WindowManager=mango
if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY ]]; then
    export XDG_CURRENT_DESKTOP=$WindowManager
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=$WindowManager
    export XDG_BACKEND=wayland
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
    export MOZ_ENABLE_WAYLAND=1
    export GDK_BACKEND=wayland,x11
fi

# Start mango on TTY1 (live ISO); under greetd omunchy-session starts it
if [[ $- == *i* && -z $WAYLAND_DISPLAY && -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec $WindowManager
fi
