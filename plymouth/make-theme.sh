#!/usr/bin/env bash
# Generates the Omunchy plymouth theme images into airootfs.
# Same palette and wordmark as syslinux/make-splash.sh.
set -euo pipefail

OUT="${OUT:-$(dirname "$0")/../airootfs/usr/share/plymouth/themes/omunchy}"
FONT_BOLD="/usr/share/fonts/TTF/JetBrainsMono-ExtraBold.ttf"
FONT_MED="/usr/share/fonts/TTF/JetBrainsMono-Medium.ttf"
[[ -f "$FONT_BOLD" ]] || FONT_BOLD="JetBrainsMono"
[[ -f "$FONT_MED" ]] || FONT_MED="JetBrainsMono"

MANGO="#5fd068"
INK="#f2ebe1"
mkdir -p "$OUT"

ww=$(magick -font "$FONT_BOLD" -pointsize 100 label:'Omunchy' -format '%w' info:)
LW=$(( ww + 40 ))
RX=$(( (LW - ww) / 2 ))

magick -size ${LW}x150 xc:none \
    -font "$FONT_BOLD" -pointsize 100 \
    -fill "$INK" -gravity north -annotate +0+0 'Omunchy' \
    -fill "$MANGO" -draw "rectangle ${RX},128 $(( RX + ww )),131" \
    "$OUT/logo.png"

magick -size 420x56 xc:none \
    -fill 'rgba(242,235,225,0.06)' -stroke "$MANGO" -strokewidth 2 \
    -draw 'roundrectangle 1,1 418,54 12,12' \
    "$OUT/entry.png"

magick -size 14x14 xc:none -fill "$INK" -draw 'circle 7,7 7,1' "$OUT/bullet.png"

magick -size 22x30 xc:none -fill "$MANGO" \
    -draw 'roundrectangle 1,12 21,29 3,3' \
    -fill none -stroke "$MANGO" -strokewidth 3 -draw 'arc 4,1 18,23 180,360' \
    "$OUT/lock.png"

echo "wrote theme images to $OUT"
