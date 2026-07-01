#!/usr/bin/env bash
# precommit.sh — Pre-commit hooks framework
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_precommit() {
  log_section "Pre-commit Hooks"

  # Install pre-commit via pipx or pip
  if command -v pipx &>/dev/null; then
    if ! pipx list 2>/dev/null | grep -q "package pre-commit "; then
      log_info "Installing pre-commit via pipx..."
      pipx install pre-commit
      log_ok "pre-commit installed"
    else
      log_info "pre-commit already installed"
    fi
  elif command -v pip3 &>/dev/null; then
    if ! pip3 show pre-commit &>/dev/null 2>&1; then
      log_info "Installing pre-commit via pip3..."
      pip3 install --user pre-commit
      log_ok "pre-commit installed"
    else
      log_info "pre-commit already installed"
    fi
  else
    log_warn "Neither pipx nor pip3 found. Install Python first."
    pkg_mark_installed "mod:precommit"
    return 0
  fi

  # Deploy default .pre-commit-config.yaml to home directory
  local src_config="${DEVOS_ROOT}/configs/pre-commit/.pre-commit-config.yaml"
  local dst_config="$HOME/.pre-commit-config.yaml"

  if [[ -f "$src_config" ]]; then
    if [[ -f "$dst_config" ]]; then
      backup_file "$dst_config"
    fi
    cp "$src_config" "$dst_config"
    log_ok "Default .pre-commit-config.yaml deployed"
  else
    log_warn "pre-commit config not found at $src_config"
  fi

  # Set up Git hook templates directory for automatic pre-commit in new repos
  local hook_templates="$HOME/.git-hooks"
  if [[ ! -f "${hook_templates}/pre-commit" ]]; then
    mkdir -p "$hook_templates"
    # Create a pre-commit hook template that checks for .pre-commit-config.yaml and runs pre-commit
    cat > "$hook_templates/pre-commit" <<'HOOK'
#!/bin/sh
# Pre-commit hook template — auto-installed by DevOS
# If .pre-commit-config.yaml exists, run pre-commit
if [ -f ".pre-commit-config.yaml" ] && command -v pre-commit &>/dev/null; then
  exec pre-commit run --hook-stage manual 2>/dev/null || true
fi
HOOK
    chmod +x "$hook_templates/pre-commit"

    # Set git hook templates path globally
    git config --global init.templateDir "$hook_templates" 2>/dev/null || true
    log_ok "Git hook templates configured"
  fi

  pkg_mark_installed "mod:precommit"
  log_section "Pre-commit Setup Complete"
}
