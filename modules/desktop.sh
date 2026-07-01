#!/usr/bin/env bash
# desktop.sh — GNOME desktop, Wayland, and btop/fastfetch configs
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_desktop() {
  # Delegate to standalone modules if they exist
  local gnome_script="${DEVOS_ROOT}/modules/gnome.sh"
  local wayland_script="${DEVOS_ROOT}/modules/wayland.sh"

  if [[ -f "$gnome_script" ]]; then source "$gnome_script"; install_gnome; fi
  if [[ -f "$wayland_script" ]]; then source "$wayland_script"; install_wayland; fi

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

  # Tmux Plugin Manager (tpm)
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    log_info "Installing Tmux Plugin Manager..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null || true
    rollback_register "dir:remove:$tpm_dir"
    log_ok "tpm installed"
  else
    log_info "tpm already installed"
  fi

  # Install tmux plugins (run in background, tpm may not be in PATH yet)
  if [[ -d "$tpm_dir" ]] && [[ -f "$HOME/.tmux.conf" ]]; then
    # Install plugins by running tpm's install script directly
    if [[ -f "${tpm_dir}/scripts/install_plugins.sh" ]]; then
      TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" \
        bash "${tpm_dir}/scripts/install_plugins.sh" 2>/dev/null || true
      log_ok "Tmux plugins installed (prefix + I to verify)"
    fi
  fi

  pkg_mark_installed "mod:desktop"
  log_section "Desktop Setup Complete"
}
