#!/bin/bash
# Omunchy login shell configuration
# Starts mango (Wayland compositor)

. $HOME/.bashrc

# Password helper for `sudo -A` (see ~/Documents/Guide.md)
export SUDO_ASKPASS=$HOME/Scripts/omunchy-askpass

# Environment for the Wayland session: `exec`-ed children (foot, firefox,
# waybar) inherit this env.
WindowManager=mango

# Start mango on TTY1
if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    export XDG_CURRENT_DESKTOP=$WindowManager
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=$WindowManager
    export XDG_BACKEND=wayland
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
    export MOZ_ENABLE_WAYLAND=1
    export GDK_BACKEND=wayland,x11
    exec $WindowManager
fi
