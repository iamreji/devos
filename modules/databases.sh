#!/usr/bin/env bash
# databases.sh — PostgreSQL + Redis
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_databases() {
  log_section "Databases"

  # ── PostgreSQL ────────────────────────────────────────────────
  if command -v psql &>/dev/null; then
    log_info "PostgreSQL already installed ($(psql --version 2>/dev/null | awk '{print $3}'))"
  else
    log_info "Installing PostgreSQL..."
    pkg_apt_install_batch postgresql postgresql-contrib libpq-dev
    pkg_mark_installed "db:postgresql"
    log_ok "PostgreSQL installed"
  fi

  # Start and enable PostgreSQL
  if command -v systemctl &>/dev/null; then
    sudo systemctl enable postgresql 2>/dev/null || true
    sudo systemctl start postgresql 2>/dev/null || true
  fi

  # Create dev user (if not exists)
  if command -v psql &>/dev/null; then
    if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$(whoami)'" 2>/dev/null | grep -q 1; then
      log_info "Creating PostgreSQL user: $(whoami)..."
      sudo -u postgres createuser --superuser "$(whoami)" 2>/dev/null || true
    fi
    # Create dev database
    if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$(whoami)'" 2>/dev/null | grep -q 1; then
      sudo -u postgres createdb "$(whoami)" 2>/dev/null || true
    fi
    log_ok "PostgreSQL user and database configured"
  fi

  # Install pgcli
  if command -v pipx &>/dev/null && ! pipx list 2>/dev/null | grep -q "package pgcli "; then
    log_info "Installing pgcli via pipx..."
    pipx install pgcli 2>/dev/null || log_warn "Failed to install pgcli"
  fi

  # ── Redis ──────────────────────────────────────────────────────
  if command -v redis-server &>/dev/null; then
    log_info "Redis already installed ($(redis-server --version 2>/dev/null | awk '{print $3}' | tr -d 'v='))"
  else
    log_info "Installing Redis..."
    pkg_apt_install_batch redis-server
    pkg_mark_installed "db:redis"
    log_ok "Redis installed"
  fi

  # Start and enable Redis
  if command -v systemctl &>/dev/null; then
    sudo systemctl enable redis-server 2>/dev/null || true
    sudo systemctl start redis-server 2>/dev/null || true
  fi

  # Install redis-cli tools via pipx
  if command -v pipx &>/dev/null && ! pipx list 2>/dev/null | grep -q "package iredis "; then
    log_info "Installing iredis via pipx..."
    pipx install iredis 2>/dev/null || log_warn "Failed to install iredis"
  fi

  pkg_mark_installed "mod:databases"
  log_section "Databases Setup Complete"
}
