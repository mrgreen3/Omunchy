#!/usr/bin/env bash
# Generates the syslinux vesamenu background (splash.png).
#
# Look: dark charcoal canvas, single green glow anchoring the bottom-right,
# JetBrains Mono ExtraBold wordmark with green rule + tagline. Output must be
# a plain 8-bit RGB PNG at exactly the MENU RESOLUTION (vesamenu won't scale).
#
# Layer order: base -> vignette -> glow -> text, so the ink stays crisp.
#
# NOTE: keep the magick call contiguous - bare comment lines inside a
# line-continued command terminate it early in bash.
set -euo pipefail

W="${W:-1024}"
H="${H:-768}"
OUT="${OUT:-splash.png}"
FONT_BOLD="/usr/share/fonts/TTF/JetBrainsMono-ExtraBold.ttf"
FONT_MED="/usr/share/fonts/TTF/JetBrainsMono-Medium.ttf"
[[ -f "$FONT_BOLD" ]] || FONT_BOLD="JetBrainsMono"
[[ -f "$FONT_MED" ]] || FONT_MED="JetBrainsMono"

MANGO="#5fd068"
INK="#f2ebe1"
INK_DIM="#9a938c"

# wordmark width (100pt) drives the centred green rule length
ww=$(magick -font "$FONT_BOLD" -pointsize 100 label:'Omunchy' -format '%w' info:)
RX=$(( (W - ww) / 2 ))

magick -size ${W}x${H} xc:'#141110' \
    \( -size ${W}x${H} gradient:'#1c1613'-'#0a0807' \) -compose Over -composite \
    \( -size ${W}x${H} radial-gradient:'rgba(0,0,0,0.0)'-'rgba(0,0,0,0.38)' \) -compose Over -composite \
    \( -size 1400x1400 radial-gradient:'rgba(95,208,104,0.34)'-'rgba(95,208,104,0.0)' \
         -gravity northwest -geometry +240+30 \) -compose Over -composite \
    -font "$FONT_BOLD" -pointsize 100 \
    -fill 'rgba(0,0,0,0.50)' -gravity north -annotate +3+33 'Omunchy' \
    -fill "$INK" -gravity north -annotate +0+26 'Omunchy' \
    -fill "$MANGO" -draw "rectangle ${RX},150 $(( RX + ww )),153" \
    -font "$FONT_MED" -pointsize 30 \
    -fill "$MANGO" -gravity north -annotate +0+163 'MangoWC - Wayland' \
    -pointsize 26 \
    -fill "$INK_DIM" -gravity southeast -annotate +42+30 'live media' \
    -alpha off -depth 8 -strip \
    "$OUT"

echo "wrote $OUT ($(identify -format '%wx%h %[colorspace]' "$OUT")) wordmark:${ww}px"