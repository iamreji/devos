#!/usr/bin/env bash
# python.sh — Python ecosystem (pyenv, uv, poetry, ruff, mypy)
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_python() {
  log_section "Python Ecosystem"

  pkg_apt_install_batch build-essential curl wget git

  # pyenv build dependencies
  pkg_apt_install_batch \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

  # pyenv
  export PYENV_ROOT="$HOME/.pyenv"
  if [[ ! -d "$PYENV_ROOT" ]]; then
    log_info "Installing pyenv..."
    curl -fsSL https://pyenv.run | bash
    rollback_register "dir:remove:$PYENV_ROOT"
    log_ok "pyenv installed"
  else
    log_info "pyenv already installed"
  fi

  # Add pyenv to PATH for this session
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - 2>/dev/null || true)"

  # Install latest Python 3.x via pyenv
  if command -v pyenv &>/dev/null; then
    local py_latest
    py_latest="$(pyenv install --list 2>/dev/null | grep -E '^\s*3\.' | grep -v 'dev\|rc\|alpha\|beta' | tail -1 | tr -d ' ')" || true
    if [[ -n "$py_latest" ]]; then
      if pyenv versions 2>/dev/null | grep -q "$py_latest"; then
        log_info "Python $py_latest already installed via pyenv"
      else
        log_info "Installing Python $py_latest via pyenv (this may take a while)..."
        pyenv install "$py_latest"
        log_ok "Python $py_latest installed"
      fi
      pyenv global "$py_latest"
      log_ok "Python $py_latest set as global default"
    else
      log_warn "Could not determine latest Python 3.x version"
    fi
  fi

  # Install uv (blazing-fast Python package manager)
  if ! command -v uv &>/dev/null; then
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | bash
    log_ok "uv installed"
  else
    log_info "uv already installed ($(uv --version 2>/dev/null | awk '{print $2}'))"
  fi

  # Ensure pipx is available
  if ! command -v pipx &>/dev/null; then
    pkg_apt_install_batch pipx
    pipx ensurepath
  fi

  # Python dev tools via pipx
  local pipx_tools=(poetry ruff mypy)
  for tool in "${pipx_tools[@]}"; do
    if pipx list 2>/dev/null | grep -q "package ${tool} "; then
      log_debug "pipx tool already installed: $tool"
    else
      log_info "Installing $tool via pipx..."
      pipx install "$tool" 2>/dev/null || log_warn "Failed to install $tool"
    fi
  done

  # Add pyenv PATH to exports.zsh if not already present
  local exports_file="$HOME/.config/zsh/exports.zsh"
  if [[ -f "$exports_file" ]] && ! grep -q "PYENV_ROOT" "$exports_file" 2>/dev/null; then
    cat >> "$exports_file" <<'PYTHONEXPORT'

# --- Python / pyenv (lazy-loaded) ------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
_pyenv_lazy_load() {
  unset -f pyenv python pip
  [[ -d "$PYENV_ROOT/bin" ]] && dedup_path PATH "$PYENV_ROOT/bin"
  eval "$(pyenv init - 2>/dev/null)" 2>/dev/null || true
}
pyenv() { _pyenv_lazy_load; pyenv "$@"; }
python() { _pyenv_lazy_load; python "$@"; }
pip() { _pyenv_lazy_load; pip "$@"; }

# --- uv (lazy-loaded) -------------------------------------------------
export UV_INSTALL_DIR="$HOME/.local/bin"
_uv_lazy_load() { unset -f uv; }
uv() { command uv "$@"; }
PYTHONEXPORT
    log_ok "Python env vars added to exports.zsh"
  fi

  pkg_mark_installed "mod:python"
  log_section "Python Setup Complete"
}
