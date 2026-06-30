# ┌─────────────────────────────────────────────────────────────────┐
# │ Utility Functions — misc helpers                                │
# └─────────────────────────────────────────────────────────────────┘

# uptime shorthand
up() { uptime -p 2>/dev/null | sed 's/^up //' || uptime; }

# Take a file backup
bak() { cp "$1" "${1}.bak" && echo "Backed up: $1 → ${1}.bak"; }

# Create a tarball of a directory
tarball() {
  local dir="${1:-.}"
  local name="${2:-$(basename "$dir")}"
  tar -czf "${name}.tar.gz" "$dir" && echo "Created: ${name}.tar.gz"
}

# Find running processes matching a pattern
psgrep() { ps aux | grep -v grep | grep -i "$@"; }

# Get directory size
dirsize() { du -sh "${1:-.}" 2>/dev/null; }

# Quick note in ~/notes
note() {
  local file="${HOME}/notes/$(date +%Y-%m-%d).md"
  mkdir -p "$(dirname "$file")"
  echo "## $(date +%H:%M) — $*" >> "$file"
  ${EDITOR:-vim} "$file"
}

# Reload shell
reload() { exec zsh; }

# Find largest files in a directory
bigfiles() {
  local dir="${1:-.}"
  local count="${2:-10}"
  find "$dir" -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -n "$count" | \
    awk '{printf "%s\t%s\n", $1, substr($0, index($0,$2))}' | \
    while read -r size path; do
      printf '%s\t%s\n' "$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")" "$path"
    done
}

# Kill process by port
killport() {
  local port="$1"
  local pid
  pid="$(lsof -ti:"$port" 2>/dev/null)"
  if [[ -n "$pid" ]]; then
    kill -9 "$pid" && echo "Killed process $pid on port $port"
  else
    echo "No process found on port $port"
  fi
}
