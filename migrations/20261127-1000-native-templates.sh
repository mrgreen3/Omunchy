# noctalia renders rofi/mango/waybar/foot colours itself (theme.templates.user),
# so every palette source works, builtin included. Safe to rerun.
set -euo pipefail
D=$OMUNCHY_DIR
c=$HOME/.config/noctalia/config.toml
[[ -f $c ]] || exit 0

if ! grep -Eq '^[[:space:]]*\[theme\.templates\.user' "$c"; then
    cp -n "$c" "$c.bak-templates"
    { echo; sed -n '/^\[theme\.templates\.user\./,$p' "$D/airootfs/etc/skel/.config/noctalia/config.toml"; } >>"$c"
    echo "  added noctalia colour templates to config.toml (backup: $c.bak-templates)"
else
    echo "  config.toml already has theme templates; left as is"
fi
if grep -q '^colors_changed = ".*omunchy-theme-refresh"' "$c"; then
    sed -i '/^colors_changed = ".*omunchy-theme-refresh"/d' "$c"
    echo "  removed old colors_changed hook"
fi
[[ -f $HOME/.config/noctalia/templates.toml ]] &&
    echo "  note: ~/.config/noctalia/templates.toml is no longer used; move any own templates into config.toml"
rm -f /tmp/omunchy-mango-colors.conf
noctalia msg config-reload >/dev/null 2>&1 || true
noctalia msg templates-apply >/dev/null 2>&1 || true
