[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi
