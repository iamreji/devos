#!/usr/bin/env bash
# go.sh — Go language toolchain
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_go() {
  log_section "Go Language"

  local go_version go_tarball go_url install_dir

  # Determine latest Go version
  go_version="$(curl -fsSL https://go.dev/dl/?mode=json 2>/dev/null | grep 'version' | head -1 | cut -d'"' -f4)" || true
  if [[ -z "$go_version" ]]; then
    go_version="go1.24.0"
    log_warn "Could not fetch latest Go version, defaulting to $go_version"
  fi

  install_dir="/usr/local"
  go_tarball="${go_version}.linux-amd64.tar.gz"
  go_url="https://go.dev/dl/${go_tarball}"

  if command -v go &>/dev/null; then
    local current_ver
    current_ver="$(go version 2>/dev/null | awk '{print $3}')"
    if [[ "$current_ver" == "$go_version" ]]; then
      log_info "Go $current_ver already installed"
      log_ok "Go is up to date"
    else
      log_info "Go $current_ver installed, latest is $go_version"
      log_info "Updating Go..."
      local tmp_tarball
      tmp_tarball="$(_devos_mktemp "go.tar.gz")"
      curl -fsSL "$go_url" -o "$tmp_tarball"
      sudo rm -rf "${install_dir}/go"
      sudo tar -C "$install_dir" -xzf "$tmp_tarball"
      rm -f "$tmp_tarball"
      log_ok "Go updated to $go_version"
    fi
  else
    log_info "Installing Go $go_version..."
    local tmp_tarball
    tmp_tarball="$(_devos_mktemp "go.tar.gz")"
    curl -fsSL "$go_url" -o "$tmp_tarball"
    sudo tar -C "$install_dir" -xzf "$tmp_tarball"
    rm -f "$tmp_tarball"
    log_ok "Go $go_version installed"
  fi

  # Set up GOPATH
  export GOPATH="$HOME/go"
  export PATH="${install_dir}/go/bin:$GOPATH/bin:$PATH"
  mkdir -p "$GOPATH"/{bin,src,pkg}

  # Install Go tools
  local go_tools=(
    "golang.org/x/tools/gopls@latest"
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    "github.com/go-delve/delve/cmd/dlv@latest"
    "github.com/air-verse/air@latest"
    "github.com/nametake/golangci-lint-langserver@latest"
  )
  for tool in "${go_tools[@]}"; do
    local tool_name
    tool_name="$(basename "$(echo "$tool" | cut -d'@' -f1)")"
    if [[ -f "${GOPATH}/bin/${tool_name}" ]]; then
      log_debug "Go tool already installed: $tool_name"
    else
      log_info "Installing Go tool: $tool_name..."
      go install "$tool" 2>/dev/null || log_warn "Failed to install $tool_name"
    fi
  done

  # Add Go PATH to exports.zsh if not already present
  local exports_file="$HOME/.config/zsh/exports.zsh"
  if [[ -f "$exports_file" ]] && ! grep -q "GOPATH" "$exports_file" 2>/dev/null; then
    cat >> "$exports_file" <<'GOEXPORT'

# --- Go (lazy-loaded) -------------------------------------------------
export GOPATH="$HOME/go"
_go_lazy_load() {
  unset -f go
  dedup_path PATH "/usr/local/go/bin"
  dedup_path PATH "$GOPATH/bin"
}
go() { _go_lazy_load; go "$@"; }
GOEXPORT
    log_ok "Go env vars added to exports.zsh"
  fi

  pkg_mark_installed "mod:go"
  log_section "Go Setup Complete"
}
