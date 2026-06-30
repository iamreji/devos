# ┌─────────────────────────────────────────────────────────────────┐
# │ Core Aliases — Navigation, system, misc                         │
# └─────────────────────────────────────────────────────────────────┘

# --- Navigation ------------------------------------------------------
alias ...="../.."
alias ....="../../.."
alias .....="../../../.."
alias ......="../../../../.."

# --- Better ls (eza) ------------------------------------------------
if command -v eza &>/dev/null; then
  alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
  alias la="eza -lah --icons=always"
  alias ll="eza -lh --icons=always"
  alias lsa="eza -lah --icons=always"
  alias lt="eza --tree --level=2 --icons=always"
else
  alias la="ls -lAh"
  alias ll="ls -lh"
  alias lsa="ls -lah"
fi

# --- Directory -------------------------------------------------------
alias md="mkdir -p"
alias rd="rmdir"

# --- File search -----------------------------------------------------
alias ff="find . -type f -name"
alias fd="find . -type d -name"

# --- grep -------------------------------------------------------------
alias grep="grep --color=auto"
alias egrep="grep -E"
alias fgrep="grep -F"

# --- bat --------------------------------------------------------------
if command -v batcat &>/dev/null; then
  alias bat="batcat"
elif command -v bat &>/dev/null; then
  alias bat="bat"
fi

# --- Misc ------------------------------------------------------------
alias sz="source ~/.zshrc"
alias zshconfig="\$EDITOR ~/.zshrc"
alias please="sudo"
alias hi="echo Hello Soumik!"
alias myip="curl -s https://ipinfo.io/ip"
alias ports="netstat -tulnp"
alias speed="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -"

# --- zoxide -----------------------------------------------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# --- ngrok ------------------------------------------------------------
[[ -f "$HOME/ngrok" ]] && alias ngrok="$HOME/ngrok"

# --- Wallpaper Changer ------------------------------------------------
if [[ -x /usr/local/bin/wallpaper_changer ]]; then
  alias wp="/usr/local/bin/wallpaper_changer /home/soumik/MyDrive/walp/code/wallpapers"
  alias wp-p="systemctl --user stop  wallpaper-changer.service"
  alias wp-r="systemctl --user start wallpaper-changer.service"
  alias wp-st="systemctl --user status wallpaper-changer.service"
  alias wp-e="systemctl --user enable  wallpaper-changer.service"
  alias wp-d="systemctl --user disable wallpaper-changer.service"
  alias wp-rs="systemctl --user restart wallpaper-changer.service"
fi
