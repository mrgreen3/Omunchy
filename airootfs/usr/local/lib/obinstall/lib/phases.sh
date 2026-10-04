# shellcheck shell=bash disable=SC2034
# Install phases. The base system is a copy of the running live system
# no pacstrap, no network, no package repo.

LIVE_USER=live
LIVE_ROOT=/run/archiso/airootfs
LIVE_BOOT=/run/archiso/bootmnt
ROOT_MAPPER=cryptroot
BTRFS_TOP=/tmp/obinstall-btrfs-top
ROOT_DEV=''; LUKS_PART=''; ESP_DEV=''

# ---------------------------------------------------------------------------
phase_preflight() {
  ((EUID == 0 || DRY_RUN)) || die "must run as root"
  local t; for t in genfstab arch-chroot sgdisk wipefs cryptsetup mkfs.btrfs mkfs.fat jq pv rsync tar grub-install; do
    command -v "$t" >/dev/null || die "missing tool: $t"
  done
  if ((!DRY_RUN)); then
    [[ -d $LIVE_ROOT && -f $LIVE_BOOT/arch/boot/x86_64/vmlinuz-linux ]] || die "not running from the live ISO ($LIVE_ROOT missing)"
    [[ -b $DISK ]] || die "$DISK is not a block device"
    lsblk -nro MOUNTPOINTS "$DISK" | grep -qE '^(/|/run/archiso.*)$' && die "$DISK holds the running live system"
  fi
  info "boot mode: $(is_uefi && echo UEFI || echo BIOS)"
}

# ---------------------------------------------------------------------------
cleanup_disk() {
  info "releasing $DISK"
  ((DRY_RUN)) && return 0
  cd /
  local devs dev mp
  mapfile -t devs < <(lsblk -nrpo NAME "$DISK")
  # leftovers from earlier attempts (stray gpg-agent, mounts, swap, LUKS mappings)
  for dev in "${devs[@]}"; do swapoff "$dev" 2>/dev/null || true; done
  while read -r mp; do
    [[ -n $mp ]] || continue
    case $mp in /|/usr|/etc|/home|/var|/boot|/run|/run/*|/proc|/sys|/dev|/dev/*) die "$DISK is in use by the running system ($mp); refusing to wipe it" ;; esac
    umount "$mp" 2>/dev/null && continue
    # busy: stop what is using it (e.g. a stray gpg-agent from a previous run), then unmount
    fuser -km "$mp" >/dev/null 2>&1 || true
    sleep 1
    umount "$mp" 2>/dev/null || umount -l "$mp" 2>/dev/null || true
  done < <(for dev in "${devs[@]}"; do findmnt -rno TARGET -S "$dev"; done | sort -ru)
  for dev in "${devs[@]}"; do
    [[ $(lsblk -dnro TYPE "$dev" 2>/dev/null) == crypt ]] && cryptsetup close "${dev##*/}" 2>/dev/null || true
  done
  cryptsetup close "$ROOT_MAPPER" 2>/dev/null || true
  udevadm settle 2>/dev/null || true
  for dev in "${devs[@]}"; do
    if mp=$(findmnt -rno TARGET -S "$dev" | head -1) && [[ -n $mp ]]; then
      die "$dev is still mounted at $mp and could not be released"
    fi
  done
}

# partprobe can race udev right after sgdisk; retry before giving up
reread_partitions() {
  ((DRY_RUN)) && { echo "  [dry-run] partprobe $DISK" >&2; return 0; }
  local i
  for i in 1 2 3 4 5; do
    partprobe "$DISK" >>"$LOG_FILE" 2>&1 && break
    udevadm settle; sleep 1
  done
  udevadm settle
}

phase_prepare_disk() {
  cleanup_disk
  info "partitioning $DISK"
  run wipefs -af "$DISK"
  run sgdisk --zap-all "$DISK"
  run sgdisk -n 1:1MiB:+1GiB -t 1:EF00 -c 1:EFI "$DISK"
  if is_uefi; then
    run sgdisk -n 2:0:0 -t 2:8300 -c 2:root "$DISK"
  else
    run sgdisk -n 2:0:-2MiB -t 2:8300 -c 2:root "$DISK"
    run sgdisk -n 3:0:0 -t 3:EF02 -c 3:bios_grub "$DISK"
  fi
  reread_partitions
  ESP_DEV=$(part_dev "$DISK" 1); LUKS_PART=$(part_dev "$DISK" 2)
  ((DRY_RUN)) || for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -b $ESP_DEV && -b $LUKS_PART ]] && break; sleep 1; done
  run wipefs -af "$ESP_DEV" "$LUKS_PART"

  if ((ENCRYPT)); then
    info "LUKS2 on $LUKS_PART"
    ((DRY_RUN)) || {
      cryptsetup luksFormat --type luks2 --iter-time 2000 --batch-mode "$LUKS_PART" - <"$LUKS_PASS_FILE" >>"$LOG_FILE" 2>&1 || die "luksFormat failed"
      cryptsetup open "$LUKS_PART" "$ROOT_MAPPER" - <"$LUKS_PASS_FILE" >>"$LOG_FILE" 2>&1 || die "luksOpen failed"
    }
    ROOT_DEV=/dev/mapper/$ROOT_MAPPER
  else
    ROOT_DEV=$LUKS_PART
  fi

  info "filesystems + btrfs subvolumes"
  run mkfs.fat -F32 -n EFI "$ESP_DEV"
  run mkfs.btrfs -f -L omunchy "$ROOT_DEV"
  run mkdir -p "$BTRFS_TOP" "$MNT"
  run mount "$ROOT_DEV" "$BTRFS_TOP"
  local sv; for sv in @ @home @log @pkg; do run btrfs subvolume create "$BTRFS_TOP/$sv"; done
  run umount "$BTRFS_TOP"
  local o=noatime,compress=zstd
  run mount -o "$o,subvol=@" "$ROOT_DEV" "$MNT"
  run mkdir -p "$MNT"/{boot,home,var/log,var/cache/pacman/pkg}
  run mount -o "$o,subvol=@home" "$ROOT_DEV" "$MNT/home"
  run mount -o "$o,subvol=@log" "$ROOT_DEV" "$MNT/var/log"
  run mount -o "$o,subvol=@pkg" "$ROOT_DEV" "$MNT/var/cache/pacman/pkg"
  run mount -o umask=0077 "$ESP_DEV" "$MNT/boot"
}

# console keymap name -> xkb layout name for mango (falls back to us)
xkb_for_keymap() {
  local k=$1 base
  case $k in
    uk) base=gb ;; sv-*|sv) base=se ;; br-*) base=br ;; jp*) base=jp ;; pl*) base=pl ;; cz*) base=cz ;;
    dvorak*) base=us ;; colemak*) base=us ;; ua*) base=ua ;; *) base=${k%%[-_.0-9]*} ;;
  esac
  if awk '/^! layout/{f=1;next} /^!/{f=0} f{print $1}' /usr/share/X11/xkb/rules/base.lst 2>/dev/null | grep -qx "$base"; then
    echo "$base"
  else
    warn "no xkb layout for console keymap '$k'; using us for mango (change xkb_rules_layout in ~/.config/mango/config.conf)"
    echo us
  fi
}

# xkb layout for this install (mango and the greeter), computed once
XKB_LAYOUT=''
install_xkb() { [[ -n $XKB_LAYOUT ]] || XKB_LAYOUT=$(xkb_for_keymap "$KEYMAP"); }

# ---------------------------------------------------------------------------
phase_copy_system() {
  info "copying the live system to $MNT"
  if ((DRY_RUN)); then
    echo "  [dry-run] tar cf - -C $LIVE_ROOT . | pv | tar xpf - -C $MNT" >&2
    echo "  [dry-run] cp vmlinuz-linux from $LIVE_BOOT, rsync live-session changes, machine-id" >&2
    return 0
  fi
  local total; total=$(du -sb "$LIVE_ROOT" | awk '{print $1}')
  printf '  %s to copy\n\n' "$(numfmt --to=iec-i --suffix=B "$total")"
  # errexit off so PIPESTATUS is always inspected (a failed tar on either side must be caught)
  local st
  set +e
  tar cf - -C "$LIVE_ROOT" . | pv -u block -pterb -s "$total" | tar xpf - -C "$MNT"
  st=("${PIPESTATUS[@]}")
  set -e
  [[ ${st[0]} -eq 0 && ${st[2]} -eq 0 ]] || die "copying system files failed (tar: ${st[0]}/${st[2]})"

  # archiso keeps the kernel on the ISO media, not in the squashfs
  mkdir -p "$MNT/boot"
  cp -a "$LIVE_BOOT/arch/boot/x86_64/vmlinuz-linux" "$MNT/boot/vmlinuz-linux"

  # live-session changes (cowspace overlay)
  local upper; upper=$(find /run/archiso/cowspace -type d -path '*/persistent_*/x86_64/upperdir' 2>/dev/null | head -1)
  if [[ -n $upper && -d $upper ]]; then
    info "syncing live session changes"
    rsync -a "$upper/" "$MNT/" >>"$LOG_FILE" 2>&1 || warn "cowspace sync had errors (non-fatal)"
  fi
}

# ---------------------------------------------------------------------------
phase_configure_system() {
  info "converting the live copy into an installed system"
  # fixed wallpaper path for the greeter, before /etc/skel is removed
  local wp
  wp=$(sed -n "s#.*swaybg -i [\"'][^\"']*/\([^\"']*\)[\"'].*#\1#p" "$MNT/etc/skel/.config/mango/config.conf" 2>/dev/null | head -1 || true)
  if [[ -n ${wp:-} && -f $MNT/etc/skel/Backgrounds/$wp ]]; then
    run mkdir -p "$MNT/usr/share/backgrounds/omunchy"
    run cp -a "$MNT/etc/skel/Backgrounds/$wp" "$MNT/usr/share/backgrounds/omunchy/current"
  fi

  chroot_run systemd-machine-id-setup

  # archiso mkinitcpio preset -> standard preset
  cat <<'EOT' | write_file "$MNT/etc/mkinitcpio.d/linux.preset"
# mkinitcpio preset file for the 'linux' package
PRESETS=('default' 'fallback')
ALL_kver='/boot/vmlinuz-linux'
ALL_config='/etc/mkinitcpio.conf'

default_image="/boot/initramfs-linux.img"
fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
EOT

  # live-only bits
  run rm -f "$MNT/home/$LIVE_USER/Scripts/obinstall"
  run rm -rf "$MNT/usr/local/lib/obinstall"
  run rm -rf "$MNT/etc/systemd/system/getty@tty1.service.d"
  run rm -f "$MNT/etc/systemd/system/default.target"
  if ((!DRY_RUN)) && [[ -f $MNT/etc/systemd/journald.conf.d/volatile-storage.conf ]]; then
    sed -i 's/volatile/auto/g' "$MNT/etc/systemd/journald.conf.d/volatile-storage.conf"
    mv "$MNT/etc/systemd/journald.conf.d/volatile-storage.conf" "$MNT/etc/systemd/journald.conf.d/auto-storage.conf"
  fi
  run rm -f "$MNT/etc/systemd/system/multi-user.target.wants/pacman-init.service" \
            "$MNT/etc/systemd/system/pacman-init.service" "$MNT/etc/systemd/system/etc-pacman.d-gnupg.mount"
  run rm -rf "$MNT/etc/skel"
  ((DRY_RUN)) || { sed -i '/^Hidden=true/d' "$MNT/usr/share/applications/gparted.desktop" 2>/dev/null || true
    # live NOPASSWD sudo -> password required
    sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/; s/^# %wheel ALL=(ALL:ALL) ALL$/%wheel ALL=(ALL:ALL) ALL/' "$MNT/etc/sudoers"; }

  info "fstab, locale, time, keyboard, hostname"
  ((DRY_RUN)) || { genfstab -U "$MNT" >"$MNT/etc/fstab"; grep -q 'subvol=' "$MNT/etc/fstab" || die "fstab has no btrfs subvolumes"; }
  echo "$HOSTNAME" | write_file "$MNT/etc/hostname"
  printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t%s.localdomain\t%s\n' "$HOSTNAME" "$HOSTNAME" | write_file "$MNT/etc/hosts"
  run ln -sf "/usr/share/zoneinfo/$TIMEZONE" "$MNT/etc/localtime"
  chroot_run hwclock --systohc --utc
  ((DRY_RUN)) || { sed -i "/^#$LOCALE /s/^#//" "$MNT/etc/locale.gen"; }
  chroot_run locale-gen
  printf 'LANG=%s\nLC_COLLATE=C\n' "$LOCALE" | write_file "$MNT/etc/locale.conf"
  printf 'KEYMAP=%s\nFONT=Lat2-Terminus16\n' "$KEYMAP" | write_file "$MNT/etc/vconsole.conf"
  install_xkb
  info "keyboard layout for mango and the login screen: $XKB_LAYOUT (from console keymap $KEYMAP)"
  if ((!DRY_RUN)); then
    local lk=$MNT/home/$LIVE_USER/.config/mango/config.conf
    sed -i "s/^xkb_rules_layout=.*/xkb_rules_layout=$XKB_LAYOUT/" "$lk" 2>>"$LOG_FILE" || true
    grep -qx "xkb_rules_layout=$XKB_LAYOUT" "$lk" 2>/dev/null \
      || warn "could not set xkb_rules_layout in mango config; set it in ~/.config/mango/config.conf after install"
  fi
}

# ---------------------------------------------------------------------------
phase_user() {
  info "creating user $USERNAME"
  [[ -d $MNT/home/$LIVE_USER || $DRY_RUN == 1 ]] || die "live user home missing in target"
  # rewrite the old username in rc files/dot dirs only (not every text file)
  chroot_run /bin/bash -c "grep -rlI -- '$LIVE_USER' /home/$LIVE_USER/.config /home/$LIVE_USER/.local/share/applications /home/$LIVE_USER/.bashrc /home/$LIVE_USER/.bash_profile 2>/dev/null | xargs -r -d '\n' sed -i 's/\\b$LIVE_USER\\b/$USERNAME/g'"
  chroot_run usermod -l "$USERNAME" "$LIVE_USER"
  chroot_run /bin/bash -c "groupmod -n '$USERNAME' '$LIVE_USER' || true"
  chroot_run sed -i "s|/home/$LIVE_USER|/home/$USERNAME|g" /etc/passwd
  chroot_run mv "/home/$LIVE_USER" "/home/$USERNAME"
  chroot_run /bin/bash -c "getent group '$USERNAME' >/dev/null || groupadd '$USERNAME'"
  chroot_run usermod -g "$USERNAME" "$USERNAME"
  chroot_run chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
  # same password for the user and root (hash computed by the wizard)
  if ((DRY_RUN)); then echo "  [dry-run] chpasswd -e for $USERNAME and root (hash hidden)" >&2
  else printf '%s:%s\nroot:%s\n' "$USERNAME" "$USER_HASH" "$USER_HASH" | arch-chroot "$MNT" chpasswd -e >>"$LOG_FILE" 2>&1 || die "chpasswd failed"; fi
}

# ---------------------------------------------------------------------------
phase_mkinitcpio() {
  info "initramfs"
  # No 'autodetect': keeps the install bootable on different hardware.
  local hooks="base systemd microcode modconf kms keyboard keymap sd-vconsole block filesystems fsck"
  ((ENCRYPT)) && hooks="base systemd microcode modconf kms keyboard keymap sd-vconsole sd-encrypt block filesystems fsck"
  # the archiso drop-in would override our hooks on any rebuild that does not pass -c
  run rm -f "$MNT/etc/mkinitcpio.conf.d/archiso.conf"
  chroot_run sed -i -E "s|^HOOKS=.*|HOOKS=($hooks)|" /etc/mkinitcpio.conf
  chroot_run sed -i 's/^COMPRESSION="xz"/#COMPRESSION="xz"/; s/^COMPRESSION_OPTIONS=/#COMPRESSION_OPTIONS=/' /etc/mkinitcpio.conf
  chroot_run mkinitcpio -p linux
}

phase_greeter() {
  info "login screen (greetd + gtkgreet)"
  install_xkb
  # cage (the greeter's compositor) reads the layout from XKB_DEFAULT_LAYOUT; without it
  # the login password would be typed on a US layout
  cat <<EOT | write_file "$MNT/etc/greetd/config.toml"
[terminal]
vt = 1

[default_session]
command = "env XKB_DEFAULT_LAYOUT=$XKB_LAYOUT cage -s -- gtkgreet -s /etc/greetd/gtkgreet.css"
user = "greeter"
# greetd-greeter has no matching /etc/pam.d file; reuse the "greetd" PAM service instead
service = "greetd"
EOT
  echo mango | write_file "$MNT/etc/greetd/environments"
  ((DRY_RUN)) || echo "GTK_THEME=adw-gtk3-dark" >>"$MNT/etc/environment"
  chroot_run systemctl enable greetd.service bluetooth.service power-profiles-daemon.service
  chroot_run systemctl set-default graphical.target
}

# ---------------------------------------------------------------------------
phase_bootloader() {
  info "GRUB ($(is_uefi && echo UEFI || echo BIOS))"
  local cmdline='rootflags=subvol=@ rw'
  if ((DRY_RUN)); then cmdline="root=UUID=DRY $cmdline"
  elif ((ENCRYPT)); then
    cmdline="rd.luks.name=$(blkid -s UUID -o value "$LUKS_PART")=$ROOT_MAPPER root=/dev/mapper/$ROOT_MAPPER $cmdline"
  else
    cmdline="root=UUID=$(blkid -s UUID -o value "$ROOT_DEV") $cmdline"
  fi
  if is_uefi; then
    chroot_run grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    # also install the removable fallback (EFI/BOOT/BOOTX64.EFI): boots even if the firmware's NVRAM entry is missing or stale
    chroot_run grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck
  else
    run grub-install --target=i386-pc --boot-directory="$MNT/boot" "$DISK"
  fi
  chroot_run sed -i.bak -E "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$cmdline\"|" /etc/default/grub
  chroot_run rm -f /etc/default/grub.bak
  chroot_run grub-mkconfig -o /boot/grub/grub.cfg
}

phase_validate() {
  info "validating target"
  ((DRY_RUN)) && return 0
  local f; for f in boot/vmlinuz-linux boot/initramfs-linux.img boot/grub/grub.cfg etc/fstab etc/greetd/config.toml; do
    [[ -s $MNT/$f ]] || die "missing in target: /$f"
  done
  grep -q "$(blkid -s UUID -o value "$ROOT_DEV")" "$MNT/etc/fstab" || die "fstab missing root UUID"
  grep -q 'root=' "$MNT/boot/grub/grub.cfg" || die "grub.cfg has no root="
  ! is_uefi || [[ -s $MNT/boot/EFI/BOOT/BOOTX64.EFI ]] || die "missing EFI fallback loader /EFI/BOOT/BOOTX64.EFI"
  [[ -d $MNT/home/$USERNAME ]] || die "home for $USERNAME missing"
  install_xkb
  grep -q "XKB_DEFAULT_LAYOUT=$XKB_LAYOUT " "$MNT/etc/greetd/config.toml" || die "greeter keyboard layout not set in greetd config"
  grep -qx "xkb_rules_layout=$XKB_LAYOUT" "$MNT/home/$USERNAME/.config/mango/config.conf" || warn "mango xkb_rules_layout in /home/$USERNAME is not $XKB_LAYOUT"
  ! ((ENCRYPT)) || grep -q 'rd.luks.name' "$MNT/boot/grub/grub.cfg" || die "grub.cfg lost rd.luks.name"
}

phase_finish() {
  info "unmounting"
  run sync
  ((DRY_RUN)) || { umount -R "$MNT" 2>/dev/null || true; ((ENCRYPT)) && cryptsetup close "$ROOT_MAPPER" 2>/dev/null || true; }
  info "Installation complete. Remove the install media and reboot."
}

PHASES=(preflight prepare_disk copy_system configure_system user mkinitcpio greeter bootloader validate finish)
