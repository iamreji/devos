#!/usr/bin/env bash
# anchor.sh — Anchor Framework for Solana
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_anchor() {
  log_section "Anchor Framework"

  if ! command -v cargo &>/dev/null; then
    log_warn "Rust toolchain not found. Install the 'rust' module first."
    return 1
  fi

  source "$HOME/.cargo/env" 2>/dev/null || true

  if command -v anchor &>/dev/null; then
    log_info "Anchor already installed ($(anchor --version 2>/dev/null | awk '{print $2}'))"
    log_ok "Anchor is ready"
  else
    log_info "Installing Anchor..."
    cargo install --git https://github.com/coral-xyz/anchor avm --locked --force 2>/dev/null
    if command -v avm &>/dev/null; then
      avm install latest
      avm use latest
    else
      cargo install --git https://github.com/coral-xyz/anchor anchor-cli --locked --force
    fi
    log_ok "Anchor installed"
  fi

  pkg_mark_installed "mod:anchor"
  log_section "Anchor Setup Complete"
}
