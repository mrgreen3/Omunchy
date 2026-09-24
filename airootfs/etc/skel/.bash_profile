# ArchBang login shell configuration
# Starts Hyprland (Wayland compositor)

. $HOME/.bashrc

WindowManager=Hyprland

# Start Hyprland on TTY1
if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    export XDG_CURRENT_DESKTOP=$WindowManager
    export XDG_SESSION_TYPE=wayland
    exec $WindowManager
fi



