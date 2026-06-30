# ┌─────────────────────────────────────────────────────────────────┐
# │ Shell Prompt — Oh-My-Zsh agnoster theme                         │
# └─────────────────────────────────────────────────────────────────┘

# Starship prompt (preferred if available)
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  # Fallback: Oh-My-Zsh with agnoster (already configured in oh-my-zsh)
  :
fi
