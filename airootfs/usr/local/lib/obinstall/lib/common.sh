# shellcheck shell=bash disable=SC2034
# Shared helpers: logging, command wrapper, state file, UI.

LOG_FILE=${LOG_FILE:-/var/log/obinstall.log}
STATE_DIR=${STATE_DIR:-/run/obinstall}
MNT=${MNT:-/mnt}
DRY_RUN=${DRY_RUN:-0}
ACCENT=${ACCENT:-"#93D5AA"}
DARK=${DARK:-"#1a1b26"}

# gum defaults to pink: recolour every widget the installer uses
export GUM_INPUT_PROMPT_FOREGROUND=$ACCENT GUM_INPUT_CURSOR_FOREGROUND=$ACCENT GUM_INPUT_HEADER_FOREGROUND=$ACCENT
export GUM_CHOOSE_CURSOR_FOREGROUND=$ACCENT GUM_CHOOSE_SELECTED_FOREGROUND=$ACCENT GUM_CHOOSE_HEADER_FOREGROUND=$ACCENT
export GUM_FILTER_INDICATOR_FOREGROUND=$ACCENT GUM_FILTER_MATCH_FOREGROUND=$ACCENT GUM_FILTER_PROMPT_FOREGROUND=$ACCENT
export GUM_FILTER_HEADER_FOREGROUND=$ACCENT GUM_FILTER_SELECTED_PREFIX_FOREGROUND=$ACCENT
export GUM_CONFIRM_SELECTED_BACKGROUND=$ACCENT GUM_CONFIRM_SELECTED_FOREGROUND=$DARK GUM_CONFIRM_PROMPT_FOREGROUND=$ACCENT

info() { printf '\033[1;32m›\033[0m %s\n' "$*" | tee -a "$LOG_FILE" >&2; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" | tee -a "$LOG_FILE" >&2; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$*" | tee -a "$LOG_FILE" >&2; exit 1; }

# screen [SUBTITLE] — clear the terminal and draw the logo (+ optional subtitle).
screen() {
  clear 2>/dev/null || true
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground "$ACCENT" "$(cat "$INSTALLER_DIR/logo.txt")"
    echo
    [[ -n ${1:-} ]] && gum style --bold --foreground "$ACCENT" "  $1"
  else
    cat "$INSTALLER_DIR/logo.txt"; echo; [[ -n ${1:-} ]] && echo "  $1"
  fi
  echo
}

# run CMD... — log and execute; in dry-run only print.
run() {
  if ((DRY_RUN)); then printf '  [dry-run] %s\n' "$*" >&2; return 0; fi
  printf '+ %s\n' "$*" >>"$LOG_FILE"
  "$@" >>"$LOG_FILE" 2>&1 || { tail -n 20 "$LOG_FILE" >&2; die "command failed: $*"; }
}
chroot_run() { run arch-chroot "$MNT" "$@"; }

# write_file PATH [MODE] — stdin to a file.
write_file() {
  local path=$1 mode=${2:-0644}
  if ((DRY_RUN)); then printf '  [dry-run] write %s\n' "$path" >&2; cat >/dev/null; return 0; fi
  mkdir -p "$(dirname "$path")"; cat >"$path"; chmod "$mode" "$path"
}

# --- state file ---------------------------------------------------------------
state_init() {
  ((DRY_RUN)) && return 0
  mkdir -p "$STATE_DIR"
  jq -n --argjson total "$1" --arg target "$MNT" \
    '{started_at: now, target: $target, total_phases: $total, current_index: 0,
      current_phase: "Starting installation", phases: []}' >"$STATE_DIR/state.json"
}
state_update() {
  ((DRY_RUN)) && return 0
  jq "$1" "$STATE_DIR/state.json" >"$STATE_DIR/.s.tmp" && mv "$STATE_DIR/.s.tmp" "$STATE_DIR/state.json"
}

# validate_username NAME — must be a plain new account name (rejects root, live, any existing account)
validate_username() {
  [[ $1 =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "use lowercase letters, digits, - and _ (max 32, not starting with a digit)"; return 1; }
  if getent passwd "$1" >/dev/null 2>&1 || getent group "$1" >/dev/null 2>&1; then
    echo "'$1' is already a system or live account name"; return 1
  fi
}
validate_hostname() {
  [[ $1 =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] || { echo "use letters, digits and - (max 63, no leading/trailing -)"; return 1; }
}

# Partition device path: /dev/nvme0n1 -> /dev/nvme0n1p1, /dev/sda -> /dev/sda1
part_dev() { [[ $1 =~ [0-9]$ ]] && printf '%sp%s' "$1" "$2" || printf '%s%s' "$1" "$2"; }
is_uefi() { [[ -d /sys/firmware/efi ]]; }

# show_summary — everything that is about to happen, before anything is touched.
show_summary() {
  local size model enc boot
  size=$(lsblk -dno SIZE "$DISK" 2>/dev/null || echo '?')
  model=$(lsblk -dno MODEL "$DISK" 2>/dev/null | sed "s/ *$//" || true)
  ((ENCRYPT)) && enc="LUKS2 (your password unlocks the disk at boot)" || enc="none"
  is_uefi && boot="UEFI (GRUB on a 1 GiB EFI partition)" || boot="BIOS (GRUB, bios_grub partition)"
  screen "Review before install"
  cat <<EOT
  User        $USERNAME
  Hostname    $HOSTNAME
  Timezone    $TIMEZONE
  Keyboard    $KEYMAP
  Disk        $DISK  ${size}${model:+  $model}
  Encryption  $enc
  Boot        $boot
  Filesystem  btrfs (zstd) with subvolumes @ @home @log @pkg

  What will happen:
    1. $DISK is partitioned and ERASED (everything on it is lost)
    2. This live system is copied to the disk (no network needed)
    3. Locale, time, user, login screen and bootloader are configured

EOT
  gum style --foreground 9 --bold "  ALL DATA ON $DISK WILL BE DESTROYED."
  echo
}
