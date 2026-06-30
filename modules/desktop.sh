#!/usr/bin/env bash
# desktop.sh — GNOME desktop, Wayland, and btop/fastfetch configs
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_desktop() {
  install_gnome
  install_wayland
  pkg_apt_install_batch btop fastfetch tmux

  # btop config
  if [[ -f "${DEVOS_ROOT}/configs/btop/btop.conf" ]]; then
    mkdir -p "$HOME/.config/btop"
    cp "${DEVOS_ROOT}/configs/btop/btop.conf" "$HOME/.config/btop/btop.conf"
    log_ok "btop config deployed"
  fi

  # fastfetch config
  if [[ -f "${DEVOS_ROOT}/configs/fastfetch/config.jsonc" ]]; then
    mkdir -p "$HOME/.config/fastfetch"
    cp "${DEVOS_ROOT}/configs/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    log_ok "fastfetch config deployed"
  fi

  # tmux config
  if [[ -f "${DEVOS_ROOT}/configs/tmux/tmux.conf" ]]; then
    cp "${DEVOS_ROOT}/configs/tmux/tmux.conf" "$HOME/.tmux.conf"
    log_ok "tmux config deployed"
  fi

  pkg_mark_installed "mod:desktop"
  log_section "Desktop Setup Complete"
}

install_gnome() {
  log_section "GNOME Desktop"

  if ! command -v gnome-shell &>/dev/null; then
    log_info "GNOME not detected. Skipping GNOME tweaks."
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

  # Animations
  gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
  log_ok "Animations disabled"

  # Tap to click
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true

  pkg_mark_installed "mod:gnome"
  log_section "GNOME Setup Complete"
}

install_wayland() {
  log_section "Wayland Setup"

  if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
    log_warn "Wayland session not active. Skipping Wayland utilities."
    return 0
  fi

  pkg_apt_install_batch wl-clipboard grim slurp

  # Environment for Wayland
  export ELECTRON_OZONE_PLATFORM_HINT=auto
  export MOZ_ENABLE_WAYLAND=1

  log_ok "Wayland utilities installed"

  pkg_mark_installed "mod:wayland"
}
