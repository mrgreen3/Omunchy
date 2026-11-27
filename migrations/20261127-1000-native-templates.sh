# noctalia renders rofi/mango/waybar/foot colours itself (theme.templates.user),
# so every palette source works, builtin included. Safe to rerun.
set -euo pipefail
D=$OMUNCHY_DIR
c=$HOME/.config/noctalia/config.toml
[[ -f $c ]] || exit 0

if ! grep -q '^\[theme\.templates\.user\.' "$c"; then
    sed -n '/^\[theme\.templates\.user\./,$p' "$D/airootfs/etc/skel/.config/noctalia/config.toml" |
        sed "s|/home/live|$HOME|g" | { echo; cat; } >>"$c"
    echo "  added noctalia colour templates to config.toml"
fi
if grep -q '^colors_changed = ".*omunchy-theme-refresh"' "$c"; then
    sed -i '/^colors_changed = ".*omunchy-theme-refresh"/d' "$c"
    echo "  removed old colors_changed hook"
fi
rm -f /tmp/omunchy-mango-colors.conf
noctalia msg config-reload >/dev/null 2>&1 || true
