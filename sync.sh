#!/usr/bin/env bash
# Omunchy repo sync for build-test machines (desktop / laptop).
# Pulls the latest from GitHub; --build also builds the ISO with mkarchiso
# and prints the QEMU one-liner to test it.
#
# Usage: ./sync.sh [--build]
set -euo pipefail
cd "$(dirname "$0")"

echo "[omunchy] Pulling latest from GitHub..."
git pull --ff-only origin main

if [[ "${1:-}" == "--build" ]]; then
    command -v mkarchiso >/dev/null 2>&1 || {
        echo "[omunchy] mkarchiso missing — install it: sudo pacman -S archiso" >&2
        exit 1
    }
    echo "[omunchy] Building ISO (needs sudo, ~10 GB scratch in work/)..."
    sudo mkarchiso -v -w work -o out .
    iso=$(ls -t out/*.iso | head -1)
    echo "[omunchy] Built: $iso"
    echo "[omunchy] Test it (needs: sudo pacman -S qemu-full):"
    echo "  qemu-system-x86_64 -enable-kvm -m 4G -cdrom $iso"
fi