# add vim as default editor
export EDITOR=vim
export TERMINAL=foot
export BROWSER=firefox

# Add scripts path safely
for d in "$HOME/.local/share/omunchy/bin" "$HOME/Scripts"; do
    [[ ":$PATH:" == *":$d:"* ]] || PATH="$PATH:$d"
done
export PATH

# User-local tools (claude, tuios, herdr)
for d in "$HOME/.local/bin"; do
    [[ ":$PATH:" != *":$d:"* ]] && export PATH="$PATH:$d"
done
unset d

# mise: user-local agent/tool installs (~/.local/share/mise)
command -v mise >/dev/null && eval "$(mise activate bash)"

[[ -r /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# Shell tools (Omarchy-style): eza listings, bat previews, zoxide jumps
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons=auto --git'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias ..='cd ..'
alias ...='cd ../..'
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress='tar -xzf'

# Package sizes
alias pkg_size="pacman -Qi | awk '/^Name/{n=\$3} /^Installed Size/{print \$4\$5\"\t\"n}' | sort -hr"

# Pacman upgrades
alias update='sudo pacman -Syu'
alias updates='checkupdates'

# fzf shell integration
eval "$(fzf --bash)"

# fzf defaults
export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
export FZF_CTRL_R_OPTS="--border"

# Enhanced history function
fh() {
  local cmd
  cmd=$(history | awk '{$1=""; print substr($0,2)}' | tac | sort -u | fzf \
    --height 40% \
    --reverse \
    --border \
    --prompt="History ❯ " \
    --preview 'echo {}' \
    --preview-window=up:1:wrap \
  )
  if [ -n "$cmd" ]; then
    echo -e "\n> $cmd"
    read -p "Run? [y/N/c(opy)] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      history -s "$cmd"
      eval "$cmd"
    elif [[ "$ans" =~ ^[Cc]$ ]]; then
      echo "$cmd" | wl-copy && echo "Copied to clipboard."
    fi
  fi
}

# Bindings for fh
bind -x '"\C-h": fh'

