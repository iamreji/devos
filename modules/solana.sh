#!/usr/bin/env bash
# solana.sh — Solana CLI, Anchor, Foundry
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_solana() {
  log_section "Solana + Anchor + Foundry"

  pkg_apt_install_batch build-essential curl pkg-config libssl-dev libudev-dev

  # Solana CLI (agave-install)
  if ! command -v solana &>/dev/null; then
    log_info "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    log_ok "Solana CLI installed ($(solana --version 2>/dev/null | head -1 | awk '{print $2}'))"
  else
    log_info "Solana CLI already installed ($(solana --version 2>/dev/null | head -1 | awk '{print $2}'))"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
  fi

  # Anchor (via avm)
  if ! command -v anchor &>/dev/null; then
    log_info "Installing Anchor (AVM)..."
    cargo install --git https://github.com/coral-xyz/anchor avm --force 2>/dev/null || \
      cargo install --git https://github.com/coral-xyz/anchor anchor-cli --locked --force
    if command -v avm &>/dev/null; then
      avm install latest
      avm use latest
    fi
    log_ok "Anchor installed"
  else
    log_info "Anchor already installed ($(anchor --version 2>/dev/null | awk '{print $2}'))"
  fi

  # Foundry
  if ! command -v forge &>/dev/null; then
    log_info "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    foundryup
    log_ok "Foundry installed ($(forge --version 2>/dev/null | head -1))"
  else
    log_info "Foundry already installed ($(forge --version 2>/dev/null | head -1))"
  fi

  pkg_mark_installed "mod:solana"
  pkg_mark_installed "mod:anchor"
  pkg_mark_installed "mod:foundry"
  log_section "Solana Ecosystem Setup Complete"
}
