#!/usr/bin/env bash
# wayland.sh — Wayland utilities and environment setup
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_wayland() {
  log_section "Wayland Setup"

  if [[ "$(loginctl show-session "$(loginctl | grep "$(whoami)" | awk '{print $1}')" -p Type 2>/dev/null || true)" != *wayland* ]]; then
    log_warn "Wayland session not detected. Skipping Wayland utilities."
    pkg_mark_installed "mod:wayland"
    return 0
  fi

  pkg_apt_install_batch wl-clipboard grim slurp

  # Export Wayland-friendly environment vars via exports.zsh
  local exports_file="$HOME/.config/zsh/exports.zsh"
  if [[ -f "$exports_file" ]]; then
    if ! grep -q "ELECTRON_OZONE_PLATFORM_HINT" "$exports_file" 2>/dev/null; then
      cat >> "$exports_file" <<'WAYLANDEXPORT'

# Wayland (DevOS)
export ELECTRON_OZONE_PLATFORM_HINT=auto
export MOZ_ENABLE_WAYLAND=1
WAYLANDEXPORT
      log_ok "Wayland environment variables configured"
    fi
  fi

  log_ok "Wayland utilities installed"
  pkg_mark_installed "mod:wayland"
  log_section "Wayland Setup Complete"
}
