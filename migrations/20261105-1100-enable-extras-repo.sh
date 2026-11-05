# Enable the omunchy-extras repo on installs predating it. Safe to rerun.
# Fresh installs get this from obinstall and have this migration pre-marked done
# by the build; it only runs for systems installed from an older ISO.
set -euo pipefail
D=$OMUNCHY_DIR

# 1. Omarchy keyring (public key + trust policy), from the checkout.
if [[ ! -f /usr/share/pacman/keyrings/omarchy.gpg ]]; then
    sudo mkdir -p /usr/share/pacman/keyrings
    sudo install -m0644 "$D/airootfs/usr/share/pacman/keyrings/omarchy.gpg" /usr/share/pacman/keyrings/
    sudo install -m0644 "$D/airootfs/usr/share/pacman/keyrings/omarchy-trusted" /usr/share/pacman/keyrings/
    sudo install -m0644 "$D/airootfs/usr/share/pacman/keyrings/omarchy-revoked" /usr/share/pacman/keyrings/
    echo "  installed Omarchy keyring files"
fi
if ! pacman-key -l 2>/dev/null | grep -qi 'omarchy'; then
    sudo pacman-key --populate omarchy
    echo "  trusted Omarchy keyring"
fi

# 2. DB before the repo section, so pacman -Sy never sees a missing database.
if [[ ! -f /var/lib/omunchy/extras/omunchy-extras.db ]]; then
    if ! "$D/bin/omunchy-extras-db"; then
        tmp=$(mktemp -d)
        ( cd "$tmp" && tar -czf db.tgz . )
        sudo install -D -m0644 "$tmp/db.tgz" /var/lib/omunchy/extras/omunchy-extras.db
        rm -rf "$tmp"
        echo "  wrote an empty omunchy-extras DB (omunchy-update will refresh it)"
    fi
fi

# 3. Repo section last: the DB and keyring are already in place by now.
if ! grep -q '^\[omunchy-extras\]' /etc/pacman.conf 2>/dev/null; then
    sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[omunchy-extras]
SigLevel = Required DatabaseOptional
Server = file:///var/lib/omunchy/extras
CacheServer = https://pkgs.omarchy.org/stable/$arch
EOF
    echo "  /etc/pacman.conf: added [omunchy-extras]"
fi

exit 0
