# Link the shared AGENTS.md into opencode and Claude Code. Safe to rerun.
set -euo pipefail
D=$OMUNCHY_DIR
mkdir -p ~/.config/omunchy ~/.config/opencode ~/.claude
cp -n "$D/airootfs/etc/skel/.config/omunchy/AGENTS.md" ~/.config/omunchy/AGENTS.md
[[ -e ~/.config/opencode/AGENTS.md ]] || ln -s ../omunchy/AGENTS.md ~/.config/opencode/AGENTS.md
[[ -e ~/.claude/CLAUDE.md ]] || ln -s ../.config/omunchy/AGENTS.md ~/.claude/CLAUDE.md
