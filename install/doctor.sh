#!/usr/bin/env bash
set -Eeuo pipefail
DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${DEVOS_ROOT}/install/common.sh" 2>/dev/null || true
source "${DEVOS_ROOT}/install/logger.sh" 2>/dev/null || true

declare -i TOTAL_CHECKS=0
declare -i PASSED_CHECKS=0
declare -i WARN_CHECKS=0
declare -i FAILED_CHECKS=0
DEVOS_SCORE=0
DOCTOR_TABLE=()

doctor_check() {
  local name="$1" status="$2" detail="${3:-}"
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  DOCTOR_TABLE+=("${name}|${status}|${detail}")
  case "${status,,}" in
    pass|ok) PASSED_CHECKS=$((PASSED_CHECKS + 1)) ;;
    warn|skip) WARN_CHECKS=$((WARN_CHECKS + 1)) ;;
    fail|error|missing) FAILED_CHECKS=$((FAILED_CHECKS + 1)) ;;
  esac
}

doctor_print_table() {
  local row IFS_saved="$IFS"
  printf '\n%b%s%b\n' "$BOLD" "DOCTOR REPORT" "$RESET"
  printf '  %-45s %-8s %s\n' "CHECK" "STATUS" "DETAIL"
  printf '  %-45s %-8s %s\n' "─────" "──────" "──────"
  for row in "${DOCTOR_TABLE[@]}"; do
    IFS='|'
    set -- $row
    IFS="$IFS_saved"
    local check="$1" status="$2" detail="$3"
    local colour=""
    case "${status,,}" in
      pass|ok) colour="$GREEN" ;;
      warn|skip) colour="$YELLOW" ;;
      *) colour="$RED" ;;
    esac
    printf '  %b%-45s %-8s%b %s\n' "$colour" "$check" "$status" "$RESET" "$detail"
  done
  echo
}

doctor_calculate_score() {
  if [[ $TOTAL_CHECKS -gt 0 ]]; then
    DEVOS_SCORE=$(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))
  fi
}

doctor_system() {
  log_section "System Health Check"

  doctor_check "Operating System" "pass" "${DEVOS_OS_ID} ${DEVOS_OS_VERSION}"
  doctor_check "Architecture" "pass" "$DEVOS_ARCH"

  local kernel_ver
  kernel_ver="$(uname -r)"
  if ver_ge "$kernel_ver" "6.0"; then
    doctor_check "Kernel Version" "pass" "$kernel_ver"
  else
    doctor_check "Kernel Version" "warn" "$kernel_ver (consider upgrading)"
  fi

  local cores
  cores="$(_cpu_count)"
  if [[ "$cores" -ge 4 ]]; then
    doctor_check "CPU Cores" "pass" "$cores cores"
  else
    doctor_check "CPU Cores" "warn" "$cores cores"
  fi

  local mem
  mem="$(_mem_total_mb)"
  if [[ "$mem" -ge 8000 ]]; then
    doctor_check "Memory" "pass" "$(((mem + 512) / 1024)) GB"
  elif [[ "$mem" -ge 4000 ]]; then
    doctor_check "Memory" "warn" "$(((mem + 512) / 1024)) GB"
  else
    doctor_check "Memory" "fail" "$mem MB (too low)"
  fi

  local disk_free
  disk_free="$(df -h "$HOME" | awk 'NR==2 {print $4}')"
  doctor_check "Disk Free (\$HOME)" "pass" "$disk_free"
}

doctor_gpu() {
  local has_nvidia=0
  if command -v nvidia-smi &>/dev/null; then
    has_nvidia=1
    local gpu_info
    gpu_info="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
    doctor_check "NVIDIA GPU" "pass" "${gpu_info:-Detected}"
    doctor_check "NVIDIA Driver" "ok" "$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)"

    if command -v nvcc &>/dev/null; then
      doctor_check "CUDA Toolkit" "pass" "$(nvcc --version 2>/dev/null | grep 'release' | awk '{print $5}' | tr -d ',')"
    else
      doctor_check "CUDA Toolkit" "fail" "nvcc not found"
    fi
  elif command -v lspci &>/dev/null && lspci | grep -qi nvidia; then
    doctor_check "NVIDIA GPU" "warn" "GPU detected but driver not loaded"
    doctor_check "NVIDIA Driver" "fail" "not found"
    doctor_check "CUDA Toolkit" "fail" "requires driver"
  else
    doctor_check "NVIDIA GPU" "skip" "not detected"
    doctor_check "NVIDIA Driver" "skip" "not applicable"
    doctor_check "CUDA Toolkit" "skip" "not applicable"
  fi
}

doctor_docker() {
  if command -v docker &>/dev/null; then
    doctor_check "Docker CLI" "pass" "$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
    if docker info &>/dev/null 2>&1; then
      doctor_check "Docker Daemon" "pass" "running"
    else
      doctor_check "Docker Daemon" "fail" "not running or permission denied"
    fi
    if command -v docker-compose &>/dev/null || docker compose version &>/dev/null 2>&1; then
      doctor_check "Docker Compose" "pass" "available"
    else
      doctor_check "Docker Compose" "fail" "not found"
    fi
  else
    doctor_check "Docker CLI" "fail" "not installed"
    doctor_check "Docker Daemon" "fail" "not installed"
    doctor_check "Docker Compose" "fail" "not installed"
  fi
}

doctor_node() {
  if command -v node &>/dev/null; then
    doctor_check "Node.js" "pass" "$(node --version)"
  else
    doctor_check "Node.js" "fail" "not installed"
  fi

  if command -v nvm &>/dev/null || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    doctor_check "NVM" "pass" "available"
  else
    doctor_check "NVM" "warn" "not found"
  fi

  if command -v pnpm &>/dev/null; then
    doctor_check "pnpm" "pass" "$(pnpm --version 2>/dev/null)"
  else
    doctor_check "pnpm" "fail" "not installed"
  fi

  if command -v bun &>/dev/null; then
    doctor_check "Bun" "pass" "$(bun --version 2>/dev/null)"
  else
    doctor_check "Bun" "fail" "not installed"
  fi
}

doctor_rust() {
  if command -v rustc &>/dev/null; then
    doctor_check "Rust" "pass" "$(rustc --version | awk '{print $2}')"
  else
    doctor_check "Rust" "fail" "not installed"
  fi

  if command -v cargo &>/dev/null; then
    doctor_check "Cargo" "pass" "$(cargo --version | awk '{print $2}')"
  else
    doctor_check "Cargo" "fail" "not installed"
  fi

  if command -v rustup &>/dev/null; then
    doctor_check "Rustup" "pass" "available"
  else
    doctor_check "Rustup" "warn" "not found"
  fi
}

doctor_solana() {
  if command -v solana &>/dev/null; then
    doctor_check "Solana CLI" "pass" "$(solana --version 2>/dev/null | head -1 | awk '{print $2}')"
  else
    doctor_check "Solana CLI" "fail" "not installed"
  fi

  if command -v anchor &>/dev/null; then
    doctor_check "Anchor" "pass" "$(anchor --version 2>/dev/null | awk '{print $2}')"
  else
    doctor_check "Anchor" "fail" "not installed"
  fi

  if command -v forge &>/dev/null; then
    doctor_check "Foundry" "pass" "$(forge --version 2>/dev/null | head -1)"
  else
    doctor_check "Foundry" "fail" "not installed"
  fi
}

doctor_git() {
  if command -v git &>/dev/null; then
    doctor_check "Git" "pass" "$(git --version | awk '{print $3}')"
    if git config user.name &>/dev/null; then
      doctor_check "Git User" "pass" "$(git config user.name)"
    else
      doctor_check "Git User" "warn" "not configured"
    fi
    if git config user.email &>/dev/null; then
      doctor_check "Git Email" "pass" "$(git config user.email)"
    else
      doctor_check "Git Email" "warn" "not configured"
    fi
  else
    doctor_check "Git" "fail" "not installed"
    doctor_check "Git User" "fail" "not installed"
    doctor_check "Git Email" "fail" "not installed"
  fi

  if command -v gh &>/dev/null; then
    doctor_check "GitHub CLI" "pass" "$(gh --version 2>/dev/null | head -1 | awk '{print $3}')"
    if gh auth status &>/dev/null 2>&1; then
      doctor_check "GitHub Auth" "pass" "authenticated"
    else
      doctor_check "GitHub Auth" "warn" "not logged in"
    fi
  else
    doctor_check "GitHub CLI" "warn" "not installed"
    doctor_check "GitHub Auth" "skip" "not applicable"
  fi
}

doctor_ssh() {
  if [[ -f "$HOME/.ssh/id_ed25519" ]] || [[ -f "$HOME/.ssh/id_rsa" ]]; then
    doctor_check "SSH Key" "pass" "found"
  else
    doctor_check "SSH Key" "warn" "no key found in ~/.ssh"
  fi

  if command -v gpg &>/dev/null; then
    if gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -q 'sec'; then
      doctor_check "GPG Key" "pass" "found"
    else
      doctor_check "GPG Key" "warn" "no GPG key found"
    fi
  else
    doctor_check "GPG Key" "warn" "gpg not installed"
  fi
}

doctor_shell() {
  if [[ "$SHELL" =~ zsh ]]; then
    doctor_check "Default Shell" "pass" "$SHELL"
  else
    doctor_check "Default Shell" "warn" "$SHELL (zsh recommended)"
  fi

  if [[ -f "$HOME/.zshrc" ]]; then
    doctor_check "Zsh Config" "pass" "~/.zshrc exists"
  else
    doctor_check "Zsh Config" "fail" "missing"
  fi

  if command -v starship &>/dev/null; then
    doctor_check "Starship" "pass" "$(starship --version 2>/dev/null | awk '{print $2}')"
  else
    doctor_check "Starship" "warn" "not installed (using Oh-My-Zsh theme)"
  fi
}

doctor_fonts() {
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
    doctor_check "JetBrains Mono Nerd Font" "pass" "installed"
  else
    doctor_check "JetBrains Mono Nerd Font" "fail" "not found"
  fi

  if fc-list 2>/dev/null | grep -qi "FiraCode.*Nerd"; then
    doctor_check "Fira Code Nerd Font" "pass" "installed"
  else
    doctor_check "Fira Code Nerd Font" "fail" "not found"
  fi
}

doctor_editors() {
  if command -v code &>/dev/null; then
    doctor_check "VS Code" "pass" "$(code --version 2>/dev/null | head -1)"
  else
    doctor_check "VS Code" "fail" "not installed"
  fi

  if command -v cursor &>/dev/null || [[ -d "$HOME/.config/Cursor" ]]; then
    doctor_check "Cursor" "pass" "installed"
  else
    doctor_check "Cursor" "warn" "not installed"
  fi

  if command -v nvim &>/dev/null; then
    doctor_check "Neovim" "pass" "$(nvim --version 2>/dev/null | head -1 | awk '{print $2}')"
  else
    doctor_check "Neovim" "warn" "not installed"
  fi
}

doctor_desktop() {
  if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    doctor_check "Display Server" "pass" "Wayland"
  elif [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
    doctor_check "Display Server" "warn" "X11 (Wayland recommended)"
  else
    doctor_check "Display Server" "warn" "unknown ($XDG_SESSION_TYPE)"
  fi

  if command -v gnome-shell &>/dev/null; then
    doctor_check "GNOME" "pass" "$(gnome-shell --version 2>/dev/null | awk '{print $3}')"
  else
    doctor_check "GNOME" "skip" "not GNOME"
  fi
}

doctor_run() {
  doctor_system
  doctor_gpu
  doctor_docker
  doctor_node
  doctor_rust
  doctor_solana
  doctor_git
  doctor_ssh
  doctor_shell
  doctor_fonts
  doctor_editors
  doctor_desktop

  doctor_print_table
  doctor_calculate_score

  local score_color
  if [[ $DEVOS_SCORE -ge 90 ]]; then
    score_color="$GREEN"
  elif [[ $DEVOS_SCORE -ge 70 ]]; then
    score_color="$YELLOW"
  else
    score_color="$RED"
  fi

  printf '  %bSCORE: %d/100%b\n' "$BOLD$score_color" "$DEVOS_SCORE" "$RESET"
  printf '  Passed: %d  Warnings: %d  Failed: %d\n\n' "$PASSED_CHECKS" "$WARN_CHECKS" "$FAILED_CHECKS"

  if [[ $DEVOS_SCORE -ge 90 ]]; then
    log_ok "Your workstation is in excellent shape!"
  elif [[ $DEVOS_SCORE -ge 70 ]]; then
    log_warn "Good, but could use some improvements."
  else
    log_error "Several components need attention. Run 'devos --all' to fix."
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  doctor_run
fi
