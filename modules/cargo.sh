#!/usr/bin/env bash
# cargo.sh — Cargo tools (cargo-edit, cargo-watch, cargo-audit, etc.)
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_cargo() {
  log_section "Cargo Tools"

  if ! command -v cargo &>/dev/null; then
    log_warn "Rust toolchain not found. Install the 'rust' module first."
    return 1
  fi

  source "$HOME/.cargo/env" 2>/dev/null || true

  # Install cargo-binstall for faster binary installs
  if ! command -v cargo-binstall &>/dev/null; then
    log_info "Installing cargo-binstall..."
    curl -L --proto '=https' --tlsv1.2 -sSf \
      https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    log_ok "cargo-binstall installed"
  fi

  local cargo_tools=(
    cargo-edit
    cargo-watch
    cargo-audit
    cargo-deny
    cargo-nextest
    cargo-update
  )

  for tool in "${cargo_tools[@]}"; do
    if cargo install --list 2>/dev/null | grep -q "^${tool} "; then
      log_debug "Cargo tool already installed: $tool"
      continue
    fi
    log_info "Installing cargo tool: $tool"
    if command -v cargo-binstall &>/dev/null; then
      cargo binstall -y "$tool" 2>/dev/null || cargo install "$tool"
    else
      cargo install "$tool"
    fi
  done

  pkg_mark_installed "mod:cargo"
  log_section "Cargo Tools Complete"
}
