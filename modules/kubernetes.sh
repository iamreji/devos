#!/usr/bin/env bash
# kubernetes.sh — kubectl, helm, k9s, kind, krew
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_kubernetes() {
  log_section "Kubernetes Tooling"

  # ── kubectl ─────────────────────────────────────────────────────
  if command -v kubectl &>/dev/null; then
    log_info "kubectl already installed ($(kubectl version --client 2>/dev/null | head -1 | awk '{print $3}' | tr -d '"'))"
  else
    log_info "Installing kubectl..."
    local latest_kubectl
    latest_kubectl="$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "v1.32.0")"
    curl -fsSL "https://dl.k8s.io/release/${latest_kubectl}/bin/linux/amd64/kubectl" -o /tmp/kubectl
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
    log_ok "kubectl ${latest_kubectl} installed"
  fi

  # ── Helm ────────────────────────────────────────────────────────
  if command -v helm &>/dev/null; then
    log_info "Helm already installed ($(helm version --short 2>/dev/null | tr -d 'v'))"
  else
    log_info "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_ok "Helm installed"
  fi

  # ── k9s ─────────────────────────────────────────────────────────
  if command -v k9s &>/dev/null; then
    log_info "k9s already installed"
  else
    log_info "Installing k9s..."
    local k9s_version
    k9s_version="$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null | grep tag_name | cut -d'"' -f4 | tr -d 'v' || echo "0.32.7")"
    local k9s_url="https://github.com/derailed/k9s/releases/download/v${k9s_version}/k9s_Linux_amd64.tar.gz"
    local tmp_tar
    tmp_tar="$(_devos_mktemp "k9s.tar.gz")"
    curl -fsSL "$k9s_url" -o "$tmp_tar"
    tar -xzf "$tmp_tar" -C /tmp k9s 2>/dev/null
    sudo install -o root -g root -m 0755 /tmp/k9s /usr/local/bin/k9s
    rm -f "$tmp_tar" /tmp/k9s
    log_ok "k9s installed"
  fi

  # ── kind ────────────────────────────────────────────────────────
  if command -v kind &>/dev/null; then
    log_info "kind already installed ($(kind version 2>/dev/null | awk '{print $2}'))"
  else
    log_info "Installing kind..."
    curl -fsSL https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 -o /tmp/kind
    sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
    rm -f /tmp/kind
    log_ok "kind installed"
  fi

  # ── krew ────────────────────────────────────────────────────────
  if ! command -v kubectl-krew &>/dev/null && [[ ! -d "$HOME/.krew" ]]; then
    log_info "Installing krew..."
    local krew_tar
    krew_tar="$(_devos_mktemp "krew.tar.gz")"
    curl -fsSL https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz -o "$krew_tar"
    tar -xzf "$krew_tar" -C /tmp krew-linux_amd64 2>/dev/null
    /tmp/krew-linux_amd64 install krew 2>/dev/null || true
    rm -f "$krew_tar" /tmp/krew-linux_amd64
    log_ok "krew installed"
  elif [[ -d "$HOME/.krew" ]]; then
    log_info "krew already installed"
  fi

  # Add krew to PATH
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

  # Install useful krew plugins
  if command -v kubectl-krew &>/dev/null; then
    local krew_plugins=(ctx ns access-matrix who-can tail)
    for plugin in "${krew_plugins[@]}"; do
      if ! kubectl krew list 2>/dev/null | grep -q "^${plugin}$"; then
        kubectl krew install "$plugin" 2>/dev/null || true
      fi
    done
  fi

  # ── kubectl completions ─────────────────────────────────────────
  local completion_file="$HOME/.config/zsh/completion.zsh"
  if [[ -f "$completion_file" ]] && ! grep -q "kubectl completion zsh" "$completion_file" 2>/dev/null; then
    cat >> "$completion_file" <<'K8SCOMP'

# kubectl completion
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh 2>/dev/null || true)
fi

# helm completion
if command -v helm &>/dev/null; then
  source <(helm completion zsh 2>/dev/null || true) 2>/dev/null || true
fi
K8SCOMP
    log_ok "kubectl and helm completions configured"
  fi

  # ── K8s aliases ─────────────────────────────────────────────────
  local aliases_file="$HOME/.config/zsh/aliases.zsh"
  if [[ -f "$aliases_file" ]] && ! grep -q "kubectl" "$aliases_file" 2>/dev/null; then
    # K8s aliases are already handled in kubernetes.zsh
    :
  fi

  pkg_mark_installed "mod:kubernetes"
  log_section "Kubernetes Setup Complete"
}
