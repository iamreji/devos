#!/usr/bin/env bash
# node.sh — Node.js (NVM), pnpm, Bun, global tooling
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_node() {
  log_section "Node.js Ecosystem"

  pkg_apt_install_batch build-essential

  # NVM
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    log_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    log_ok "NVM installed"
  else
    log_info "NVM already installed"
  fi

  # Load NVM
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install latest Node LTS
  if command -v nvm &>/dev/null; then
    log_info "Installing Node.js LTS via NVM..."
    nvm install --lts --latest-npm 2>/dev/null
    nvm alias default lts/*
    nvm use default
    log_ok "Node.js $(node --version) installed"
  fi

  # pnpm
  if ! command -v pnpm &>/dev/null; then
    log_info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | bash -
    log_ok "pnpm installed"
  else
    log_info "pnpm already installed ($(pnpm --version 2>/dev/null))"
  fi

  # Bun
  if ! command -v bun &>/dev/null; then
    log_info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    log_ok "Bun installed"
  else
    log_info "Bun already installed ($(bun --version 2>/dev/null))"
  fi

  pkg_mark_installed "mod:node"
  pkg_mark_installed "mod:pnpm"
  pkg_mark_installed "mod:bun"
  log_section "Node.js Setup Complete"
}
