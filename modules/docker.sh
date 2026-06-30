#!/usr/bin/env bash
# docker.sh — Docker Engine + Compose + lazydocker
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_docker() {
  log_section "Docker Engine"

  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    log_info "Docker already installed and working"
    pkg_mark_installed "mod:docker"
    return 0
  fi

  # Remove old Docker packages
  log_info "Removing old Docker packages if present..."
  for pkg in docker docker-engine docker.io containerd runc; do
    sudo apt-get remove -y "$pkg" 2>/dev/null || true
  done

  # Install prerequisites
  pkg_apt_install_batch ca-certificates curl gnupg lsb-release

  # Add Docker's official GPG key
  log_info "Adding Docker repository..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null

  # Add Docker apt repo
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Install Docker Engine
  pkg_apt_update
  pkg_apt_install_batch docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # Add user to docker group
  if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    log_warn "Added $USER to docker group. Log out and back in for this to take effect."
  fi

  # Enable and start Docker
  sudo systemctl enable docker.socket 2>/dev/null || true
  sudo systemctl enable docker 2>/dev/null || true
  sudo systemctl start docker 2>/dev/null || true

  # lazydocker
  if ! command -v lazydocker &>/dev/null; then
    log_info "Installing lazydocker..."
    local ld_version
    ld_version="$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep tag_name | cut -d'"' -f4)"
    curl -Lo /tmp/lazydocker.tar.gz \
      "https://github.com/jesseduffield/lazydocker/releases/download/${ld_version}/lazydocker_${ld_version#v}_Linux_x86_64.tar.gz"
    tar -xzf /tmp/lazydocker.tar.gz -C "$HOME/.local/bin" lazydocker
    rm -f /tmp/lazydocker.tar.gz
    log_ok "lazydocker installed"
  fi

  pkg_mark_installed "mod:docker"
  log_section "Docker Setup Complete"

  if ! docker info &>/dev/null 2>&1; then
    log_warn "Docker may not be fully active. Try logging out and back in, or run: newgrp docker"
  fi
}
