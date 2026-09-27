#!/usr/bin/env bash
# Configure live iso
set -e -u
shopt -s extglob

# Set locales
[[ -f /etc/locale.gen ]] && sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Allow Parallel Downloads in pacman
[[ -f /etc/pacman.conf ]] && sed -i "s/^#Parallel/Parallel/" /etc/pacman.conf


# Un-comment mirrorlist to allow pacman to work live
[[ -f /etc/pacman.d/mirrorlist ]] && sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

# Remove .pacnew strays for paths we overlay on purpose: the overlay is copied
# before packages are installed (build: _make_custom_airootfs runs before
# _make_packages), so pacman parks its versions of these files as .pacnew.
pacnew_paths=(
    /etc/hosts.pacnew
    /etc/passwd.pacnew
    /etc/shadow.pacnew
    /etc/skel/.bashrc.pacnew
    /etc/skel/.bash_profile.pacnew
)
for pacnew in "${pacnew_paths[@]}"; do
    [[ -e $pacnew ]] || continue
    rm -f -- "$pacnew"
    echo "[customize_airootfs] removed overlay .pacnew stray: $pacnew"
done

# Sudo to allow no password
sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
chown -c root:root /etc/sudoers
chmod -c 0440 /etc/sudoers

# Configure gparted to run with sudo for elevated permissions
#sed -i 's|^Exec=/usr/bin/gparted|Exec=sudo /usr/bin/gparted|' /usr/share/applications/gparted.desktop

# Hide gparted from application menu
sed -i '/^Categories=/a Hidden=true' /usr/share/applications/gparted.desktop

# Hostname (hardcoded for live ISO; users can change after installation)
echo "omunchy" > /etc/hostname

# Vconsole
echo "KEYMAP=us" > /etc/vconsole.conf
echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf

# Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_COLLATE=C" >> /etc/locale.conf

# Set clock to UTC (skipped when the build chroot has no RTC access, e.g. rootless builds)
hwclock --systohc --utc 2>/dev/null || echo "[customize_airootfs] no RTC access - skipping hwclock"

# Timezone
ln -sf /usr/share/zoneinfo/America/Montreal /etc/localtime

TARGET_DIR="/etc/skel/.config/systemd/user/default.target.wants"
UNIT_SRC="/usr/lib/systemd/user"

# User services to auto-enable at login
SERVICES=(
  "wireplumber.service"
  "pipewire.service"
  "pipewire-pulse.service"
  "xdg-user-dirs.service"
)

mkdir -p "$TARGET_DIR"

# Only symlink services that actually exist to prevent broken links
for service in "${SERVICES[@]}"; do
  if [[ -f "$UNIT_SRC/$service" ]]; then
    ln -sf "$UNIT_SRC/$service" "$TARGET_DIR/$service"
  else
    echo "Warning: Service file not found: $UNIT_SRC/$service"
  fi
done

# Add live user
useradd -m -p "" -G "wheel" -s /bin/bash -g users live
chown live /home/live

# Start required systemd services
systemctl enable {pacman-init,NetworkManager}.service -f

# Compile dconf database for system defaults
if command -v dconf &>/dev/null; then
  dconf update
fi

# Set graphical target
systemctl set-default graphical.target
