#!/usr/bin/env bash
# update.sh — Unified system updater for DevOS
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then
  source "${DEVOS_ROOT}/install/logger.sh"
fi

update_run() {
  local updated_count=0
  local skipped_count=0
  log_section "DevOS Update"

  # --- apt ------------------------------------------------------------
  log_info "Updating apt packages..."
  if sudo apt-get update -qq 2>/dev/null; then
    local apt_upgrades
    apt_upgrades="$(apt list --upgradable 2>/dev/null | grep -c / || true)"
    if [[ "$apt_upgrades" -gt 0 ]]; then
      sudo apt-get upgrade -y -qq
      updated_count=$((updated_count + apt_upgrades))
      log_ok "Updated ${apt_upgrades} apt package(s)"
    else
      log_info "apt packages already up to date"
      skipped_count=$((skipped_count + 1))
    fi
  else
    log_warn "apt update failed"
  fi

  # --- snap -----------------------------------------------------------
  if command -v snap &>/dev/null; then
    log_info "Refreshing snap packages..."
    sudo snap refresh 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Snap packages refreshed"; } || { log_warn "snap refresh failed"; }
  fi

  # --- flatpak --------------------------------------------------------
  if command -v flatpak &>/dev/null; then
    log_info "Updating flatpaks..."
    flatpak update -y 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Flatpaks updated"; } || { log_warn "flatpak update failed"; }
  fi

  # --- rustup ---------------------------------------------------------
  if command -v rustup &>/dev/null; then
    log_info "Updating Rust toolchain..."
    rustup update stable 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Rust toolchain updated"; } || { log_warn "rustup update failed"; }
  fi

  # --- cargo-update (updates installed crates) ------------------------
  if command -v cargo-install-update &>/dev/null || cargo install --list 2>/dev/null | grep -q "cargo-update"; then
    log_info "Updating cargo crates..."
    cargo install-update -a 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Cargo crates updated"; } || { log_warn "cargo-update failed or none needed"; }
  fi

  # --- bun ------------------------------------------------------------
  if command -v bun &>/dev/null; then
    log_info "Upgrading Bun..."
    bun upgrade 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Bun upgraded"; } || { log_warn "bun upgrade failed"; }
  fi

  # --- pnpm -----------------------------------------------------------
  if command -v pnpm &>/dev/null; then
    log_info "Updating pnpm..."
    pnpm self-update 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "pnpm updated"; } || { log_warn "pnpm already up to date"; }
  fi

  # --- node/nvm -------------------------------------------------------
  if command -v nvm &>/dev/null || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    log_info "Checking for newer Node LTS..."
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null
    if command -v nvm &>/dev/null; then
      local current_lts
      current_lts="$(nvm version node 2>/dev/null)"
      nvm install --lts --latest-npm 2>/dev/null && nvm use --lts 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Node LTS updated"; } || skipped_count=$((skipped_count + 1))
    fi
  fi

  # --- docker images -------------------------------------------------
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    log_info "Pulling latest Docker images..."
    local docker_count=0
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '<none>' | while read -r img; do
      docker pull "$img" >/dev/null 2>&1 || true
    done
    log_ok "Docker images pulled"
    updated_count=$((updated_count + 1))
  fi

  # --- solana ---------------------------------------------------------
  if command -v solana-install &>/dev/null || command -v agave-install &>/dev/null; then
    log_info "Updating Solana CLI..."
    local si_cmd
    si_cmd="$(command -v agave-install 2>/dev/null || command -v solana-install 2>/dev/null)"
    if [[ -n "$si_cmd" ]]; then
      "$si_cmd" update 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Solana CLI updated"; } || { log_warn "solana-install update failed"; }
    fi
  fi

  # --- foundry --------------------------------------------------------
  if command -v foundryup &>/dev/null; then
    log_info "Updating Foundry..."
    foundryup 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Foundry updated"; } || { log_warn "foundryup failed"; }
  fi

  # --- gh extensions --------------------------------------------------
  if command -v gh &>/dev/null; then
    log_info "Upgrading gh extensions..."
    gh extension upgrade --all 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "gh extensions upgraded"; } || { log_info "No gh extensions to update"; }
  fi

  # --- summary --------------------------------------------------------
  echo
  log_section "Update Summary"
  log_ok "Updated: ${updated_count} component(s)"
  log_info "Already up to date: ${skipped_count} component(s)"
  echo
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  update_run
fi
