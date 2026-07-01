#!/usr/bin/env bash
# pnpm.sh — pnpm package manager
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_pnpm() {
  log_section "pnpm Package Manager"

  if command -v pnpm &>/dev/null; then
    log_info "pnpm already installed ($(pnpm --version 2>/dev/null))"
    log_ok "pnpm is ready"
  else
    log_info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | bash -
    log_ok "pnpm installed"
  fi

  pkg_mark_installed "mod:pnpm"
  log_section "pnpm Setup Complete"
}
