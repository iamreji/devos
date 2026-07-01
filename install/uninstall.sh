#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ===========================================================================
# uninstall.sh — DevOS uninstall / reverse provisioning
# ===========================================================================

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"
source "${DEVOS_ROOT}/install/rollback.sh"

# --- Main --------------------------------------------------------------------
main() {
  local UNINSTALL_PURGE=0
  [[ "${1:-}" == "--purge" ]] && UNINSTALL_PURGE=1
  log_section "DevOS Uninstall"

  if [[ $UNINSTALL_PURGE -eq 1 ]]; then
    log_warn "PURGE MODE: This will remove ALL DevOS-installed packages, configs, and data."
  else
    log_warn "This will remove DevOS-installed packages and restore backups."
  fi
  prompt_confirm "Are you sure you want to uninstall DevOS?" || { log_info "Cancelled."; exit 0; }

  local installed="${DEVOS_DATA}/installed_packages.txt"
  if [[ -r "$installed" ]]; then
    log_info "Removing installed packages..."
    while IFS= read -r line; do
      local type="${line%%:*}"
      local name="${line#*:}"
      case "$type" in
        apt)
          log_info "Removing apt package: $name"
          sudo apt-get remove --purge -y "$name" 2>/dev/null || true
          ;;
        snap)
          sudo snap remove "$name" 2>/dev/null || true
          ;;
        flatpak)
          flatpak uninstall -y "$name" 2>/dev/null || true
          ;;
        cargo)
          cargo uninstall "$name" 2>/dev/null || true
          ;;
        pipx)
          pipx uninstall "$name" 2>/dev/null || true
          ;;
        url|mod|npm)
          log_info "Skipping $type: $name (manual removal may be needed)"
          ;;
      esac
    done < "$installed"
  fi

  # Restore backed-up files
  log_info "Restoring backed-up files..."
  find "$HOME" -maxdepth 4 -name '*.devos-bak' 2>/dev/null | while read -r bak; do
    local orig="${bak%.devos-bak}"
    log_info "Restoring: $orig"
    cp -f "$bak" "$orig"
    rm -f "$bak"
  done

  # Remove DevOS-installed config symlinks
  local config_links=(
    "$HOME/.config/zsh"
    "$HOME/.config/starship"
    "$HOME/.config/kitty"
    "$HOME/.config/ghostty"
    "$HOME/.config/wezterm"
    "$HOME/.config/nvim"
    "$HOME/.config/fastfetch"
    "$HOME/.config/btop"
  )
  for link in "${config_links[@]}"; do
    if [[ -L "$link" ]]; then
      log_info "Removing symlink: $link"
      rm -f "$link"
    fi
  done

  # Clean apt
  log_info "Running apt autoremove..."
  sudo apt-get autoremove -y -qq 2>/dev/null || true

  if [[ $UNINSTALL_PURGE -eq 1 ]]; then
    log_warn "Purging DevOS data directory..."
    rm -rf "$DEVOS_DATA"
    rm -rf "$DEVOS_CONFIG"
    log_warn "Purge complete. Some files in ~/.config may remain."
  fi

  log_section "Uninstall Complete"
  log_info "DevOS has been removed. Some manual cleanup may be needed for:"
  log_info "  - Oh-My-Zsh (if installed via DevOS): rm -rf ~/.oh-my-zsh"
  log_info "  - NVM/Bun/Solana toolchains (if DevOS-installed)"
}

main "$@"
