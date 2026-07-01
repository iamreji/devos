#!/usr/bin/env bash
# cloud.sh — AWS CLI + GCP gcloud CLI
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_cloud() {
  log_section "Cloud CLIs"

  # ── AWS CLI v2 ─────────────────────────────────────────────────
  if command -v aws &>/dev/null; then
    log_info "AWS CLI already installed ($(aws --version 2>/dev/null | head -1))"
  else
    log_info "Installing AWS CLI v2..."
    local tmp_zip
    tmp_zip="$(_devos_mktemp "awscliv2.zip")"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp_zip"
    unzip -qo "$tmp_zip" -d /tmp/awscliv2
    sudo /tmp/awscliv2/aws/install --update
    rm -rf /tmp/awscliv2 "$tmp_zip"
    log_ok "AWS CLI installed"
  fi

  # AWS CLI completions
  local exports_file="$HOME/.config/zsh/exports.zsh"
  local completion_file="$HOME/.config/zsh/completion.zsh"
  if [[ -f "$completion_file" ]] && ! grep -q "aws_completer" "$completion_file" 2>/dev/null; then
    cat >> "$completion_file" <<'AWSCOMP'

# AWS CLI completion
if command -v aws_completer &>/dev/null; then
  complete -C "$(command -v aws_completer)" aws
fi
AWSCOMP
    log_ok "AWS CLI completions configured"
  fi

  # ── Google Cloud SDK (gcloud) ──────────────────────────────────
  if command -v gcloud &>/dev/null; then
    log_info "Google Cloud SDK already installed"
  else
    log_info "Installing Google Cloud SDK..."
    pkg_apt_install_batch apt-transport-https ca-certificates gnupg

    # Add gcloud apt repo
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
      sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
      sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg 2>/dev/null || true

    pkg_apt_update
    pkg_apt_install_batch google-cloud-cli
    log_ok "Google Cloud SDK installed"
  fi

  # ── Session Manager Plugin (AWS SSM) ────────────────────────────
  if ! command -v session-manager-plugin &>/dev/null; then
    log_info "Installing AWS Session Manager Plugin..."
    local tmp_deb
    tmp_deb="$(_devos_mktemp "session-manager.deb")"
    curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "$tmp_deb"
    sudo dpkg -i "$tmp_deb" 2>/dev/null || sudo apt-get install -f -y -qq
    rm -f "$tmp_deb"
    log_ok "Session Manager Plugin installed"
  else
    log_info "Session Manager Plugin already installed"
  fi

  # ── AWS CLI lazy-loader in exports.zsh ──────────────────────────
  if [[ -f "$exports_file" ]] && ! grep -q "_aws_lazy_load" "$exports_file" 2>/dev/null; then
    cat >> "$exports_file" <<'CLOUDEXPORT'

# --- AWS CLI (lazy-loaded) -------------------------------------------
_aws_lazy_load() {
  unset -f aws
}
aws() { command aws "$@"; }

# --- gcloud (lazy-loaded) --------------------------------------------
_gcloud_lazy_load() {
  unset -f gcloud
}
gcloud() { command gcloud "$@"; }
CLOUDEXPORT
    log_ok "Cloud CLI env vars added to exports.zsh"
  fi

  pkg_mark_installed "mod:cloud"
  log_section "Cloud CLI Setup Complete"
}
