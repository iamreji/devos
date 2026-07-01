#!/usr/bin/env bash
# bun.sh — Bun JavaScript runtime
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_bun() {
  log_section "Bun Runtime"

  if command -v bun &>/dev/null; then
    log_info "Bun already installed ($(bun --version 2>/dev/null))"
    log_ok "Bun is ready"
  else
    log_info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    log_ok "Bun installed"
  fi

  pkg_mark_installed "mod:bun"
  log_section "Bun Setup Complete"
}
