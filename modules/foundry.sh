#!/usr/bin/env bash
# foundry.sh — Foundry (forge, cast, anvil, chisel)
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_foundry() {
  log_section "Foundry (Forge/Cast)"

  if command -v forge &>/dev/null; then
    log_info "Foundry already installed ($(forge --version 2>/dev/null | head -1))"
    log_ok "Foundry is ready"
  else
    pkg_apt_install_batch build-essential curl pkg-config libssl-dev
    log_info "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    foundryup
    log_ok "Foundry installed ($(forge --version 2>/dev/null | head -1))"
  fi

  pkg_mark_installed "mod:foundry"
  log_section "Foundry Setup Complete"
}
