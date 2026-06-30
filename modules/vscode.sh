#!/usr/bin/env bash
# vscode.sh — VS Code installation and configuration
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_vscode() {
  log_section "VS Code"

  if command -v code &>/dev/null; then
    log_info "VS Code already installed ($(code --version 2>/dev/null | head -1))"
  else
    log_info "Adding VS Code repository..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
      sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    pkg_apt_update
    pkg_apt_install code
    log_ok "VS Code installed"
  fi

  # Deploy settings
  local vscode_dir="$HOME/.config/Code/User"
  mkdir -p "$vscode_dir"

  if [[ -f "${DEVOS_ROOT}/configs/vscode/settings.json" ]]; then
    cp "${DEVOS_ROOT}/configs/vscode/settings.json" "$vscode_dir/settings.json"
    log_ok "VS Code settings deployed"
  fi
  if [[ -f "${DEVOS_ROOT}/configs/vscode/keybindings.json" ]]; then
    cp "${DEVOS_ROOT}/configs/vscode/keybindings.json" "$vscode_dir/keybindings.json"
    log_ok "VS Code keybindings deployed"
  fi

  # Install essential extensions
  local extensions=(
    "eamodio.gitlens"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "bradlc.vscode-tailwindcss"
    "rust-lang.rust-analyzer"
    "ms-azuretools.vscode-docker"
    "ms-vscode-remote.remote-containers"
    "GitHub.copilot"
    "GitHub.copilot-chat"
    "GitHub.vscode-pull-request-github"
    "PKief.material-icon-theme"
    "teabyii.ayu"
    "usernamehw.errorlens"
    "mikestead.dotenv"
    "redhat.vscode-yaml"
    "tamasfe.even-better-toml"
  )

  log_info "Installing VS Code extensions..."
  for ext in "${extensions[@]}"; do
    if code --list-extensions 2>/dev/null | grep -qi "$ext"; then
      continue
    fi
    code --install-extension "$ext" 2>/dev/null || true
  done
  log_ok "VS Code extensions installed"

  pkg_mark_installed "mod:vscode"
  log_section "VS Code Setup Complete"
}
