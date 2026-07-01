#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ===========================================================================
# cleanup.sh — DevOS system cleanup / disk space reclamation
# ===========================================================================

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"

# --- Main --------------------------------------------------------------------
main() {
  local total_freed=0
  log_section "DevOS Cleanup"

  # Docker prune
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    log_info "Docker system prune..."
    docker system prune -af --volumes 2>/dev/null && log_ok "Docker pruned" || log_info "Docker skipped"
  fi

  # Journal cleanup
  if command -v journalctl &>/dev/null; then
    log_info "Journal vacuum (7 days)..."
    local before
    before="$(_devos_size_bytes /var/log/journal)"
    sudo journalctl --vacuum-time=7d 2>/dev/null && {
      local after
      after="$(_devos_size_bytes /var/log/journal)"
      local freed=$(( before - after ))
      if [[ $freed -gt 0 ]]; then
        log_ok "Journal freed $(_devos_format_bytes $freed)"
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
    before="$(_devos_size_bytes "$HOME/.cargo/registry/cache")"
    if command -v cargo-sweep &>/dev/null; then
      cargo sweep -r 2>/dev/null && {
        local after
        after="$(_devos_size_bytes "$HOME/.cargo/registry/cache")"
        local freed=$(( before - after ))
        [[ $freed -gt 0 ]] && log_ok "Cargo freed $(_devos_format_bytes $freed)"
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

  # uv cache
  if command -v uv &>/dev/null; then
    log_info "uv cache clean..."
    uv cache clean 2>/dev/null && log_ok "uv cache cleaned" || true
  fi

  # Go module cache
  if command -v go &>/dev/null; then
    log_info "Go module cache clean..."
    local before
    before="$(_devos_size_bytes "$HOME/go/pkg/mod")"
    go clean -modcache 2>/dev/null || true
    local after
    after="$(_devos_size_bytes "$HOME/go/pkg/mod")"
    local go_freed=$(( before - after ))
    [[ $go_freed -gt 0 ]] && log_ok "Go module cache freed $(_devos_format_bytes $go_freed)"
  fi

  # pipx unused packages
  if command -v pipx &>/dev/null; then
    log_info "Checking pipx for unused packages..."
    pipx list --short 2>/dev/null | head -20 || true
  fi

  # Thumbnail cache
  if [[ -d "$HOME/.cache/thumbnails" ]]; then
    log_info "Thumbnail cache..."
    local before
    before="$(_devos_size_bytes "$HOME/.cache/thumbnails")"
    rm -rf "$HOME/.cache/thumbnails"
    local freed=$before
    [[ $freed -gt 0 ]] && log_ok "Thumbnails freed $(_devos_format_bytes $freed)"
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

main "$@"
