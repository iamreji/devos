#!/usr/bin/env bash
# rust.sh — Rust toolchain + cargo binstall + essential cargo tools
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_rust() {
  log_section "Rust Toolchain"

  pkg_apt_install_batch build-essential curl pkg-config libssl-dev

  # rustup
  if ! command -v rustup &>/dev/null; then
    log_info "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source "$HOME/.cargo/env"
    log_ok "Rust installed ($(rustc --version 2>/dev/null | awk '{print $2}'))"
  else
    log_info "Rust already installed ($(rustc --version 2>/dev/null | awk '{print $2}'))"
    source "$HOME/.cargo/env" 2>/dev/null || true
  fi

  # cargo-binstall (fast binary installs)
  if ! command -v cargo-binstall &>/dev/null; then
    log_info "Installing cargo-binstall..."
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    log_ok "cargo-binstall installed"
  fi

  # Essential cargo tools
  local cargo_tools=(
    cargo-edit
    cargo-watch
    cargo-audit
    cargo-deny
    cargo-nextest
    cargo-update
  )
  for tool in "${cargo_tools[@]}"; do
    if ! cargo install --list 2>/dev/null | grep -q "^${tool} "; then
      log_info "Installing cargo tool: $tool"
      if command -v cargo-binstall &>/dev/null; then
        cargo binstall -y "$tool" 2>/dev/null || cargo install "$tool"
      else
        cargo install "$tool"
      fi
    fi
  done

  pkg_mark_installed "mod:rust"
  pkg_mark_installed "mod:cargo"
  log_section "Rust Setup Complete"
}
