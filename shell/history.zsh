# ┌─────────────────────────────────────────────────────────────────┐
# │ History Settings — Optimized for speed & dedup                  │
# └─────────────────────────────────────────────────────────────────┘

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify
setopt inc_append_history
setopt extended_history

# fzf history search (Ctrl-R)
if command -v fzf &>/dev/null; then
  _fzf_history_search() {
    local selected
    selected="$(fc -rl 1 | awk '{ $1=""; print substr($0,2) }' | \
      fzf --query="$LBUFFER" --height=40% --reverse --no-sort)"
    if [[ -n "$selected" ]]; then
      LBUFFER="$selected"
    fi
    zle reset-prompt
  }
  zle -N _fzf_history_search
  bindkey '^R' _fzf_history_search
fi
