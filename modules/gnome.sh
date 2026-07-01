#!/usr/bin/env bash
# gnome.sh — GNOME Desktop tweaks and extensions
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_gnome() {
  log_section "GNOME Tweaks"

  if ! command -v gnome-shell &>/dev/null; then
    log_warn "GNOME not detected. Skipping GNOME tweaks."
    pkg_mark_installed "mod:gnome"
    return 0
  fi

  pkg_apt_install_batch gnome-tweaks gnome-shell-extensions chrome-gnome-shell

  # Dark theme
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark 2>/dev/null || true
  log_ok "Dark theme enabled"

  # Dock
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.dash-to-dock autohide true 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false 2>/dev/null || true
  log_ok "Dock configured"

  # Disable animations
  gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
  log_ok "Animations disabled"

  # Tap-to-click
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true

  # Show weekday in clock
  gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true

  pkg_mark_installed "mod:gnome"
  log_section "GNOME Tweaks Complete"
}
