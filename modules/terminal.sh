#!/usr/bin/env bash
# terminal.sh — Kitty, Ghostty, WezTerm terminal emulators
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_terminal() {
  log_section "Terminal Emulators"

  # Kitty
  if ! command -v kitty &>/dev/null; then
    log_info "Installing Kitty..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin \
      launch=n dest="$HOME/.local/kitty.app" 2>/dev/null
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    # Desktop entry
    cp "$HOME/.local/kitty.app/share/applications/kitty.desktop" \
       "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null || true
    log_ok "Kitty installed"
  else
    log_info "Kitty already installed"
  fi

  # Kitty config
  if [[ -f "${DEVOS_ROOT}/configs/kitty/kitty.conf" ]]; then
    mkdir -p "$HOME/.config/kitty"
    cp "${DEVOS_ROOT}/configs/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    [[ -f "${DEVOS_ROOT}/configs/kitty/current-theme.conf" ]] && \
      cp "${DEVOS_ROOT}/configs/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
    log_ok "Kitty config deployed"
  fi

  # Ghostty (snap or apt)
  if ! command -v ghostty &>/dev/null; then
    log_info "Installing Ghostty..."
    if snap list ghostty &>/dev/null 2>&1; then
      log_info "Ghostty snap already installed"
    elif command -v snap &>/dev/null; then
      sudo snap install ghostty --classic 2>/dev/null || true
    fi
    if ! command -v ghostty &>/dev/null; then
      log_warn "Ghostty installed but binary not found — may need snap PATH"
    else
      log_ok "Ghostty installed"
    fi
  else
    log_info "Ghostty already installed"
  fi

  # Ghostty config
  if [[ -f "${DEVOS_ROOT}/configs/ghostty/config" ]]; then
    mkdir -p "$HOME/.config/ghostty"
    cp "${DEVOS_ROOT}/configs/ghostty/config" "$HOME/.config/ghostty/config"
    log_ok "Ghostty config deployed"
  fi

  # WezTerm
  if ! command -v wezterm &>/dev/null; then
    log_info "Installing WezTerm..."
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg 2>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" | \
      sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null 2>&1
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y wezterm 2>/dev/null && log_ok "WezTerm installed" || log_warn "WezTerm install failed"
  else
    log_info "WezTerm already installed"
  fi

  # WezTerm config
  if [[ -f "${DEVOS_ROOT}/configs/wezterm/wezterm.lua" ]]; then
    mkdir -p "$HOME/.config/wezterm"
    cp "${DEVOS_ROOT}/configs/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
    log_ok "WezTerm config deployed"
  fi

  pkg_mark_installed "mod:terminal"
  log_section "Terminals Complete"
}
