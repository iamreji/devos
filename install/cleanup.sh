#!/usr/bin/env bash
# cleanup.sh — System cleanup utilities
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then
  source "${DEVOS_ROOT}/install/logger.sh"
fi

_clean_size_before() {
  local path="$1"
  if [[ -e "$path" ]]; then
    du -sb "$path" 2>/dev/null | cut -f1 || echo 0
  else
    echo 0
  fi
}

_clean_format_bytes() {
  local bytes="$1"
  if command -v numfmt &>/dev/null; then
    numfmt --to=iec-i --suffix=B "$bytes"
  else
    echo "$bytes bytes"
  fi
}

cleanup_run() {
  local total_freed=0
  log_section "DevOS Cleanup"

  # Docker prune
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    log_info "Docker system prune..."
    local before
    before="$(docker system df --format '{{.Size}}' 2>/dev/null | head -1 || echo '0')"
    docker system prune -af --volumes 2>/dev/null && log_ok "Docker pruned" || log_info "Docker skipped"
  fi

  # Journal cleanup
  if command -v journalctl &>/dev/null; then
    log_info "Journal vacuum (7 days)..."
    local before
    before="$(_clean_size_before /var/log/journal)"
    sudo journalctl --vacuum-time=7d 2>/dev/null && {
      local after
      after="$(_clean_size_before /var/log/journal)"
      local freed=$(( before - after ))
      if [[ $freed -gt 0 ]]; then
        log_ok "Journal freed $(_clean_format_bytes $freed)"
      fi
    }
  fi

  # apt cleanup
  log_info "apt cleanup..."
  sudo apt-get autoremove -y -qq 2>/dev/null || true
  sudo apt-get autoclean -qq 2>/dev/null || true
  log_ok "apt cleaned"

  # Cargo sweep
  if command -v cargo &>/dev/null; then
    log_info "Cargo sweep..."
    local before
    before="$(_clean_size_before "$HOME/.cargo/registry/cache")"
    if command -v cargo-sweep &>/dev/null; then
      cargo sweep -r 2>/dev/null && {
        local after
        after="$(_clean_size_before "$HOME/.cargo/registry/cache")"
        local freed=$(( before - after ))
        [[ $freed -gt 0 ]] && log_ok "Cargo freed $(_clean_format_bytes $freed)"
      }
    else
      cargo install cargo-sweep 2>/dev/null && cargo sweep -r 2>/dev/null && log_ok "Cargo sweep installed and run" || log_info "Cargo sweep not available — skipped"
    fi
  fi

  # npm cache
  if command -v npm &>/dev/null; then
    log_info "npm cache clean..."
    npm cache clean --force 2>/dev/null && log_ok "npm cache cleaned" || true
  fi

  # pnpm store prune
  if command -v pnpm &>/dev/null; then
    log_info "pnpm store prune..."
    pnpm store prune 2>/dev/null && log_ok "pnpm store pruned" || true
  fi

  # bun cache
  if command -v bun &>/dev/null; then
    log_info "Bun cache clean..."
    bun cache clean 2>/dev/null && log_ok "Bun cache cleaned" || true
  fi

  # pip cache
  if command -v pip3 &>/dev/null; then
    log_info "pip cache purge..."
    pip3 cache purge 2>/dev/null && log_ok "pip cache purged" || true
  fi

  # Thumbnail cache
  if [[ -d "$HOME/.cache/thumbnails" ]]; then
    log_info "Thumbnail cache..."
    local before
    before="$(_clean_size_before "$HOME/.cache/thumbnails")"
    rm -rf "$HOME/.cache/thumbnails"
    local freed=$before
    [[ $freed -gt 0 ]] && log_ok "Thumbnails freed $(_clean_format_bytes $freed)"
  fi

  # Temp files
  if [[ -d "$HOME/.local/share/Trash" ]]; then
    log_info "Emptying trash..."
    rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null || true
    log_ok "Trash emptied"
  fi

  echo
  log_section "Cleanup Complete"
  log_ok "System is tidier now!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cleanup_run
fi
