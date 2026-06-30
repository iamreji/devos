#!/usr/bin/env bash
# git.sh — Git, GitHub CLI, GPG signing, SSH setup
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi
if [[ -z "${DEVOS_ROLLBACK_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/rollback.sh"; fi

install_git() {
  log_section "Git Configuration"

  pkg_apt_install_batch git gh

  # git-delta (beautiful diffs)
  if ! command -v delta &>/dev/null; then
    if command -v cargo &>/dev/null; then
      cargo install git-delta
    else
      pkg_apt_install git-delta 2>/dev/null || true
    fi
  fi

  # Deploy gitconfig
  if [[ -f "${DEVOS_ROOT}/configs/git/gitconfig" ]]; then
    backup_file "$HOME/.gitconfig"
    cp "${DEVOS_ROOT}/configs/git/gitconfig" "$HOME/.gitconfig"
    log_ok "Git config deployed"
  fi

  # Deploy global gitignore
  if [[ -f "${DEVOS_ROOT}/configs/git/gitignore_global" ]]; then
    cp "${DEVOS_ROOT}/configs/git/gitignore_global" "$HOME/.gitignore_global"
    git config --global core.excludesfile "$HOME/.gitignore_global"
    log_ok "Global gitignore deployed"
  fi

  # Prompt for user identity
  local current_name current_email
  current_name="$(git config --global user.name 2>/dev/null || true)"
  current_email="$(git config --global user.email 2>/dev/null || true)"

  if [[ "$current_name" == "DevOS User" ]] || [[ -z "$current_name" ]]; then
    echo
    log_info "Setting up Git identity..."
    local new_name
    read -r -p "  Your full name: " new_name
    if [[ -n "$new_name" ]]; then
      git config --global user.name "$new_name"
    fi
    local new_email
    read -r -p "  Your email: " new_email
    if [[ -n "$new_email" ]]; then
      git config --global user.email "$new_email"
    fi
  fi

  # GPG signing (if key exists)
  if command -v gpg &>/dev/null; then
    local gpg_key
    gpg_key="$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep '^sec' | head -1 | awk '{print $2}' | cut -d'/' -f2)"
    if [[ -n "$gpg_key" ]]; then
      git config --global user.signingkey "$gpg_key"
      git config --global commit.gpgSign true
      git config --global tag.gpgSign true
      log_ok "GPG signing configured with key: $gpg_key"
    else
      log_info "No GPG key found. Skipping GPG signing setup."
      log_info "Generate one with: gpg --full-generate-key"
    fi
  fi

  # GitHub CLI auth
  if command -v gh &>/dev/null; then
    if ! gh auth status &>/dev/null 2>&1; then
      log_info "Authenticating GitHub CLI..."
      gh auth login -p https -w
    else
      log_info "GitHub CLI already authenticated"
    fi

    # Useful gh extensions
    for ext in gh-copilot gh-dash; do
      if ! gh extension list 2>/dev/null | grep -q "$ext"; then
        gh extension install "github/$ext" 2>/dev/null || true
      fi
    done
  fi

  # SSH keygen if missing
  if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    log_info "No SSH key found."
    if prompt_confirm "Generate a new ED25519 SSH key?"; then
      local ssh_email
      ssh_email="$(git config --global user.email 2>/dev/null || echo 'devos@localhost')"
      ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
      eval "$(ssh-agent -s)" 2>/dev/null || true
      ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
      log_ok "SSH key created: ~/.ssh/id_ed25519"
      echo
      log_info "Public key:"
      cat "$HOME/.ssh/id_ed25519.pub"
      echo
      log_info "Add this key to GitHub: https://github.com/settings/ssh/new"
    fi
  else
    log_info "SSH key already exists"
  fi

  pkg_mark_installed "mod:git"
  log_section "Git Setup Complete"
}
