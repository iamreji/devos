# ┌─────────────────────────────────────────────────────────────────┐
# │ Completion Configuration                                         │
# └─────────────────────────────────────────────────────────────────┘

autoload -Uz compinit
if [[ -n "${ZSH_COMPDUMP:-}" ]]; then
  compinit -i -d "$ZSH_COMPDUMP"
else
  compinit -i
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true

# kubectl completion (lazy-load)
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh 2>/dev/null || true)
fi

# helm completion
if command -v helm &>/dev/null; then
  source <(helm completion zsh 2>/dev/null || true) 2>/dev/null || true
fi

# docker completion
if command -v docker &>/dev/null; then
  source <(docker completion zsh 2>/dev/null || true) 2>/dev/null || true
fi

# AWS CLI completion
if command -v aws_completer &>/dev/null; then
  complete -C "$(command -v aws_completer)" aws 2>/dev/null || true
fi

# gh completion
if command -v gh &>/dev/null; then
  source <(gh completion --shell zsh 2>/dev/null || true) 2>/dev/null || true
fi
