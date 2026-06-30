#!/usr/bin/env bash
# nvim.sh — Neovim installation and modern LazyVim-style configuration
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_nvim() {
  log_section "Neovim"

  if command -v nvim &>/dev/null; then
    log_info "Neovim already installed ($(nvim --version 2>/dev/null | head -1 | awk '{print $2}'))"
  else
    # Prefer unstable PPA for latest version
    log_info "Adding Neovim PPA..."
    sudo add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || true
    pkg_apt_update
    pkg_apt_install neovim
    log_ok "Neovim installed"
  fi

  pkg_apt_install_batch git ripgrep fd-find

  # Deploy Neovim config
  local nvim_dir="$HOME/.config/nvim"
  mkdir -p "$nvim_dir/lua/config" "$nvim_dir/lua/plugins"

  if [[ -f "${DEVOS_ROOT}/configs/nvim/init.lua" ]]; then
    cp "${DEVOS_ROOT}/configs/nvim/init.lua" "$nvim_dir/init.lua"
  fi
  if [[ -d "${DEVOS_ROOT}/configs/nvim/lua/config" ]]; then
    cp -r "${DEVOS_ROOT}/configs/nvim/lua/config/"* "$nvim_dir/lua/config/"
  fi
  if [[ -d "${DEVOS_ROOT}/configs/nvim/lua/plugins" ]]; then
    cp -r "${DEVOS_ROOT}/configs/nvim/lua/plugins/"* "$nvim_dir/lua/plugins/"
  fi

  log_ok "Neovim config deployed"

  # Headless plugin sync
  log_info "Syncing Neovim plugins (headless)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
  log_ok "Neovim plugins synced"

  pkg_mark_installed "mod:nvim"
  log_section "Neovim Setup Complete"
  log_info "Launch 'nvim' to complete setup. Leader key: Space"
}
