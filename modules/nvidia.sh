#!/usr/bin/env bash
# nvidia.sh — NVIDIA driver verification, CUDA toolkit, GPU diagnostics
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_nvidia() {
  log_section "NVIDIA + CUDA"

  # Detect NVIDIA GPU
  if ! lspci 2>/dev/null | grep -qi "nvidia\|3d controller.*nvidia"; then
    log_warn "No NVIDIA GPU detected. Skipping NVIDIA setup."
    pkg_mark_installed "mod:nvidia"
    return 0
  fi

  log_ok "NVIDIA GPU detected"

  local gpu_info
  gpu_info="$(lspci | grep -i nvidia | head -1 | cut -d: -f3-)"
  log_info "GPU: ${gpu_info}"

  # Check for existing driver
  if command -v nvidia-smi &>/dev/null; then
    log_ok "NVIDIA driver loaded"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null | while read -r line; do
      log_info "  $line"
    done
  else
    log_warn "NVIDIA driver not loaded"

    # Check Secure Boot
    if command -v mokutil &>/dev/null && mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
      log_warn "Secure Boot is ENABLED. NVIDIA drivers require MOK enrollment."
      log_info "After installing drivers, you'll be prompted to enroll the key on reboot."
      log_info "Select 'Enroll MOK' → 'Continue' → 'Yes' → enter the password you set during install."
    fi

    if prompt_confirm "Install NVIDIA driver? (recommended: ubuntu-drivers autoinstall)"; then
      pkg_apt_install_batch ubuntu-drivers-common
      log_info "Installing recommended NVIDIA driver..."
      sudo ubuntu-drivers autoinstall
      log_warn "NVIDIA driver installed. REBOOT your system to activate the driver."
      pkg_mark_installed "mod:nvidia"
      return 0
    else
      log_info "Skipping NVIDIA driver installation."
      pkg_mark_installed "mod:nvidia"
      return 0
    fi
  fi

  # CUDA Toolkit
  if ! command -v nvcc &>/dev/null; then
    if prompt_confirm "Install CUDA Toolkit?"; then
      log_info "Installing CUDA Toolkit..."

      # Add NVIDIA CUDA repo
      local ubuntu_ver
      ubuntu_ver="$(lsb_release -rs | tr -d '.')"
      local cuda_repo="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${ubuntu_ver}/x86_64/cuda-keyring_1.1-1_all.deb"

      wget -q "$cuda_repo" -O /tmp/cuda-keyring.deb 2>/dev/null
      sudo dpkg -i /tmp/cuda-keyring.deb 2>/dev/null || true
      rm -f /tmp/cuda-keyring.deb

      pkg_apt_update
      pkg_apt_install_batch cuda-toolkit

      # Add CUDA to PATH (will be sourced from exports.zsh)
      local cuda_path="/usr/local/cuda/bin"
      if [[ -d "$cuda_path" ]]; then
        dedup_path PATH "$cuda_path"
        cat >> "$HOME/.config/zsh/exports.zsh" <<'CUDAEXPORT'

# CUDA (DevOS)
[[ -d "/usr/local/cuda/bin" ]] && dedup_path PATH "/usr/local/cuda/bin"
CUDAEXPORT
      fi

      log_ok "CUDA Toolkit installed"
      nvcc --version 2>/dev/null | grep "release" || log_warn "nvcc may need a fresh shell"
    fi
  else
    log_ok "CUDA already installed ($(nvcc --version 2>/dev/null | grep 'release' | awk '{print $5}' | tr -d ','))"
  fi

  # GPU health report
  if command -v nvidia-smi &>/dev/null; then
    echo
    log_section "GPU Health Report"
    nvidia-smi --query-gpu=name,driver_version,temperature.gpu,utilization.gpu,memory.used,memory.total,fan.speed --format=csv 2>/dev/null | head -2 | while read -r line; do
      log_info "$line"
    done
    echo
  fi

  pkg_mark_installed "mod:nvidia"
  log_section "NVIDIA Setup Complete"
}
