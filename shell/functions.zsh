# ┌─────────────────────────────────────────────────────────────────┐
# │ Custom Shell Functions                                          │
# └─────────────────────────────────────────────────────────────────┘

# mkcd — create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1" || return 1
}

# extract — universal archive extractor
extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2)  tar xjf "$1"   ;;
      *.tar.gz)   tar xzf "$1"   ;;
      *.tar.xz)   tar xJf "$1"   ;;
      *.bz2)      bunzip2 "$1"   ;;
      *.rar)      unrar x "$1"   ;;
      *.gz)       gunzip "$1"    ;;
      *.tar)      tar xf "$1"    ;;
      *.tbz2)     tar xjf "$1"   ;;
      *.tgz)      tar xzf "$1"   ;;
      *.zip)      unzip "$1"     ;;
      *.7z)       7z x "$1"      ;;
      *.Z)        uncompress "$1";;
      *)          echo "Unknown archive: $1" ;;
    esac
  else
    echo "Not a file: $1"
  fi
}

# weather — quick weather via wttr.in
weather() {
  local city="${1:-}"
  curl -s "wttr.in/${city}?format=3"
}

# cheat — search cheat.sh
cheat() {
  curl -s "cheat.sh/$1"
}

# git-clean — prune merged branches
git-clean() {
  git branch --merged | grep -v '\*\|main\|master\|develop' | xargs -n 1 git branch -d
}

# dev — start common dev server patterns
dev() {
  if [[ -f "package.json" ]]; then
    if grep -q '"dev"' package.json; then
      npm run dev
    elif grep -q '"start"' package.json; then
      npm start
    else
      echo "No dev/start script in package.json"
    fi
  elif [[ -f "Cargo.toml" ]]; then
    cargo run
  elif [[ -f "Makefile" ]]; then
    make dev
  else
    echo "No recognized project type found"
  fi
}

# serve — quick Python HTTP server on given port
serve() {
  local port="${1:-8000}"
  if command -v python3 &>/dev/null; then
    python3 -m http.server "$port"
  elif command -v python &>/dev/null; then
    python -m SimpleHTTPServer "$port"
  else
    echo "Python not found"
  fi
}

# cht — interactive cht.sh for language/tool lookup
cht() {
  local lang="${1:-}"
  local query="${2:-}"
  if [[ -z "$lang" ]]; then
    echo "Usage: cht <lang> <query>"
    return 1
  fi
  curl -s "cht.sh/${lang}/${query}"
}
