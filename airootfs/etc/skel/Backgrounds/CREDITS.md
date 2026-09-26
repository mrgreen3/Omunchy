# Wallpapers — sources & licences

Every image in this directory is shipped in the Omunchy ISO and must be
verifiably redistributable. This file records where each one came from, the
licence that permits that, and the mapping from any original (non-ASCII-safe)
filename. Review this file whenever wallpapers are added or removed.

## Verification method

Provenance was traced per-file through the git history of
`github.com/omacom/omarchy` (branch `quattro`, Sep 2026), including commits
predating the `a4219f8f` "Store theme backgrounds as webp" bulk conversion
(#7477), the `e2c8e3cc` "Pull backgrounds into the repo" commit that imported
several images from `basecamp/omakub`, and the PRs that contributed
community-submitted wallpapers. Every shipped file has an unbroken commit
chain inside omacom/omarchy or a recorded upstream URL below.

## Licensing basis

- omacom/omarchy is licensed under the MIT licence (Copyright (c) David
  Heinemeier Hansson). The licence text grants use, copying, modification,
  distribution, sublicensing and sale of "the Software" without restriction
  and requires only that the copyright notice be included. Omarchy ships its
  theme background images inside that same repository with no separate
  licence, README credits, or CREDITS file; the repo-wide MIT grant therefore
  covers its redistribution, including in Omunchy. The full text is at
  https://github.com/omacom/omarchy/blob/quattro/LICENSE
  (permission notice included below).
- basecamp/omakub (upstream of some images) is likewise MIT — its README
  states "Omakub is released under the MIT License".
- Unsplash-sourced images: Unsplash Licence (free to use, modification and
  redistribution permitted without attribution; selling unaltered copies is
  the only restriction).

## Shipped wallpapers

| File | Origin (theme in omarchy @ quattro) | Upstream source | Licence / attribution |
|---|---|---|---|
| aesthetic.jpg | Pre-existing in Omunchy (ArchBang-based skel, added in the initial base commit 9c8efda) | Untraced | **UNKNOWN — grandfathered**, see exclusions note below |
| mountain-moon.jpg | osaka-jade `3-mountain-moon` | "Add extra Osaka Jade background image" (commit af00a902, DHH) | MIT (omarchy) |
| sunset-lake.jpg | tokyo-night `3-sunset-lake` | "Add third Tokyo Night background" (commit 49efa1c3, DHH); same image Omunchy already shipped as sunset-lake.png (pixel-identical, corr 0.9999) | MIT (omarchy) |
| tree-tops.jpg | everforest `1-tree-tops` | imported from basecamp/omakub `themes/everforest/background.jpg` (commit e2c8e3cc) | MIT (omarchy + omakub) |

### Conversions

All shipped files are JPEG (quality 80–88, progressive), capped at 3840 px
wide, converted from Omarchy's originals (webp/png/jpg). Filenames are
renamed to clean ASCII slugs without the theme/sequence prefix:

- `themes/tokyo-night/backgrounds/3-sunset-lake.webp` -> `sunset-lake.jpg`
  (and Omunchy's older `sunset-lake.png` copy, pixel-identical content, was
  retired in favour of the 4K JPG re-encode)
- `themes/everforest/backgrounds/1-tree-tops.webp` -> `tree-tops.jpg`
- `themes/osaka-jade/backgrounds/3-mountain-moon.webp` -> `mountain-moon.jpg`

## Excluded (audit of omissions)

Anything whose origin or licence could not be verified was left out.
Excluded candidates and reasons:

- `tokyo-night 1-quattro` — Audi quattro logo/trademark visible in the
  artwork; advertising a brand in a distro wallpaper set is out of scope.
- `lumon 01-united-in-severance` (and the Lumon theme generally) — Lumon
  Industries is the fictional company from the Apple TV+ show *Severance*;
  the image carries the show's logo. Trademark/IP concerns.
- `catppuccin 1-totoro` — depicts Totoro, a Studio Ghibli character; Ghibli
  has not licensed the character for redistribution.
- gruvbox set (`1-the-backwater`, `2-flower-basket`, `3-village-square`,
  `4-idyllic-procession`, `5-leaves`) — contributed by @OldJobobo via
  `OldJobobo/omarchy-gruvbox-bg-addon`; the repo README (fetched 2026-09-25)
  states no licence and gives no source for the images. If they are scans or
  photos of museum-held paintings, rightsholder status is unverifiable. Ship
  nothing without a licence trail; the add-on repo has none.
- `white 1/2/3-white` — trivial solid/branded images of unclear provenance.
- `catppuccin-latte 1-color-fade`, `flexoki-light 1-orb`, `hackerman
  1-synth-scape`, `retro-82` set, `ristretto` set, `matte-black 0-ship-at-sea`
  — provenance not individually traced within the time budget; excluded
  rather than shipped on an assumption. (Not a licence finding — simply not
  audited here.)
- `0-black-moon` (nord) and `3-mountain-moon`-adjacent large scans — skipped
  in favour of smaller equivalents already audited.

Note: `aesthetic.jpg` predates this parity work in Omunchy's own history and
its origin was never recorded. It is grandfathered into the ISO for now (it
is referenced by the sway `looknfeel` (WALLPAPER_MARKER line) and install.sh), but it fails the same
verification standard applied to everything above and should be replaced or
re-sourced when convenient.

## Omarchy licence text (MIT, quoted)

Copyright (c) David Heinemeier Hansson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.