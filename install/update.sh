#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ===========================================================================
# update.sh — Unified system updater for DevOS
# ===========================================================================

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"

# --- Main --------------------------------------------------------------------
main() {
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
      nvm install --lts --latest-npm 2>/dev/null && nvm use --lts 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "Node LTS updated"; } || skipped_count=$((skipped_count + 1))
    fi
  fi

  # --- docker images -------------------------------------------------
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    log_info "Pulling latest Docker images..."
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '<none>' | while read -r img; do
      docker pull "$img" >/dev/null 2>&1 || true
    done || true
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

  # --- pyenv -----------------------------------------------------------
  if command -v pyenv &>/dev/null; then
    log_info "Updating pyenv..."
    if [[ -d "$HOME/.pyenv" ]]; then
      (cd "$HOME/.pyenv" && git pull --ff-only 2>/dev/null) && log_ok "pyenv updated" || log_debug "pyenv already up to date"
    fi
    # Update pyenv-virtualenv too
    if [[ -d "$HOME/.pyenv/plugins/pyenv-virtualenv" ]]; then
      (cd "$HOME/.pyenv/plugins/pyenv-virtualenv" && git pull --ff-only 2>/dev/null) || true
    fi
  fi

  # --- uv --------------------------------------------------------------
  if command -v uv &>/dev/null; then
    log_info "Updating uv..."
    uv self update 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "uv updated"; } || { log_info "uv already up to date"; }
  fi

  # --- npm global packages --------------------------------------------
  if command -v npm &>/dev/null; then
    log_info "Updating npm global packages..."
    npm update -g 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "npm global packages updated"; } || true
  fi

  # --- Go --------------------------------------------------------------
  if command -v go &>/dev/null; then
    log_info "Updating Go tools..."
    for tool in golang.org/x/tools/gopls@latest github.com/golangci/golangci-lint/cmd/golangci-lint@latest github.com/go-delve/delve/cmd/dlv@latest; do
      go install "$tool" 2>/dev/null || true
    done
    updated_count=$((updated_count + 1))
    log_ok "Go tools updated"
  fi

  # --- PostgreSQL -------------------------------------------------------
  if command -v psql &>/dev/null && command -v pg_lsclusters &>/dev/null; then
    log_info "Checking PostgreSQL version upgrades..."
    sudo pg_lsclusters 2>/dev/null | grep -q "online" && log_ok "PostgreSQL running" || log_debug "PostgreSQL not running"
  fi

  # --- AWS CLI ----------------------------------------------------------
  if command -v aws &>/dev/null; then
    log_info "Updating AWS CLI..."
    if [[ -f /usr/local/bin/aws ]]; then
      sudo /usr/local/bin/aws --no-sign-request 2>/dev/null || true
    fi
    local tmp_zip
    tmp_zip="$(_devos_mktemp "awscliv2.zip")"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp_zip" 2>/dev/null || true
    unzip -qo "$tmp_zip" -d /tmp/awscliv2 2>/dev/null || true
    sudo /tmp/awscliv2/aws/install --update 2>/dev/null || true
    rm -rf /tmp/awscliv2 "$tmp_zip" 2>/dev/null || true
    log_ok "AWS CLI update checked"
  fi

  # --- gcloud -----------------------------------------------------------
  if command -v gcloud &>/dev/null; then
    log_info "Updating gcloud components..."
    gcloud components update --quiet 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "gcloud updated"; } || { log_warn "gcloud update failed"; }
  fi

  # --- pre-commit autoupdate -------------------------------------------
  if command -v pre-commit &>/dev/null && [[ -f "$HOME/.pre-commit-config.yaml" ]]; then
    log_info "Running pre-commit autoupdate..."
    pre-commit autoupdate 2>/dev/null && { updated_count=$((updated_count + 1)); log_ok "pre-commit hooks updated"; } || true
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

main "$@"
