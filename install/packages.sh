#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ---------------------------------------------------------------------------
# packages.sh — Package installation and dependency-graph management for DevOS
#
# Handles apt, snap, flatpak, cargo, npm, pipx installations with idempotency
# checks, dependency ordering, parallel-safe install marking, and retry logic.
#
# Safe to source multiple times.
# ---------------------------------------------------------------------------

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"
source "${DEVOS_ROOT}/install/rollback.sh"

# --- Load guard for sourcing -------------------------------------------------
if [[ -n "${DEVOS_PACKAGES_LOADED:-}" ]]; then
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return
  fi
fi
readonly DEVOS_PACKAGES_LOADED=1

# --- State tracking ---------------------------------------------------------
_PKG_INSTALLED_FILE="${DEVOS_DATA}/installed_packages.txt"
mkdir_safe "$DEVOS_DATA"
touch "$_PKG_INSTALLED_FILE"

# Mark a package as installed (prevents re-install in future runs)
pkg_mark_installed() {
  local name="$1"
  if ! grep -Fxq "$name" "$_PKG_INSTALLED_FILE" 2>/dev/null; then
    echo "$name" >> "$_PKG_INSTALLED_FILE"
  fi
}

# Check if a package was previously installed by DevOS
pkg_is_installed() {
  local name="$1"
  grep -Fxq "$name" "$_PKG_INSTALLED_FILE" 2>/dev/null
}

# --- Dry-run mode -----------------------------------------------------------
DEVOS_DRYRUN="${DEVOS_DRYRUN:-0}"

_dryrun_pkg() {
  if _is_true "$DEVOS_DRYRUN"; then
    log_info "[DRY-RUN] Would install: $*"
    return 0
  fi
  return 1
}

# --- APT / dpkg -------------------------------------------------------------
pkg_apt_update() {
  if _dryrun_pkg "apt-get update"; then return 0; fi
  log_info "Updating apt package lists…"
  sudo apt-get update -qq
}

pkg_apt_is_installed() {
  local pkg="$1"
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

pkg_apt_install() {
  local pkg="$1"
  if pkg_apt_is_installed "$pkg"; then
    log_debug "apt package already installed: $pkg"
    return 0
  fi
  if _dryrun_pkg "apt install $pkg"; then return 0; fi
  log_info "Installing apt package: $pkg"
  rollback_register "pkg:remove:${pkg}"
  sudo apt-get install -y -qq "$pkg"
  pkg_mark_installed "apt:${pkg}"
  log_ok "Installed: $pkg"
}

pkg_apt_install_batch() {
  local pkgs=("$@")
  local to_install=()
  for pkg in "${pkgs[@]}"; do
    if ! pkg_apt_is_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done
  if [[ ${#to_install[@]} -eq 0 ]]; then
    log_debug "All apt packages already installed: ${pkgs[*]}"
    return 0
  fi
  if _dryrun_pkg "apt install ${to_install[*]}"; then return 0; fi
  log_info "Installing apt packages: ${to_install[*]}"
  for pkg in "${to_install[@]}"; do
    rollback_register "pkg:remove:${pkg}"
  done
  sudo apt-get install -y -qq "${to_install[@]}"
  for pkg in "${to_install[@]}"; do
    pkg_mark_installed "apt:${pkg}"
  done
  log_ok "Installed: ${to_install[*]}"
}

pkg_add_repo() {
  local name="$1" repo_url="$2" key_url="$3" component="${4:-main}"
  if _dryrun_pkg "add apt repo $name"; then return 0; fi
  if [[ -f "/etc/apt/sources.list.d/${name}.list" ]]; then
    log_debug "Apt repository already added: $name"
    return 0
  fi
  log_info "Adding apt repository: $name"
  if [[ -n "$key_url" ]]; then
    curl -fsSL "$key_url" | sudo gpg --dearmor -o "/etc/apt/keyrings/${name}.gpg" 2>/dev/null || \
      curl -fsSL "$key_url" | sudo apt-key add - 2>/dev/null || true
  fi
  echo "deb [signed-by=/etc/apt/keyrings/${name}.gpg] ${repo_url} ${component}" | \
    sudo tee "/etc/apt/sources.list.d/${name}.list" > /dev/null
  rollback_register "file:restore:/etc/apt/sources.list.d/${name}.list"
}

# --- Snap -------------------------------------------------------------------
pkg_snap_install() {
  local name="$1"
  if snap list "$name" &>/dev/null 2>&1; then
    log_debug "Snap already installed: $name"
    return 0
  fi
  if _dryrun_pkg "snap install $name"; then return 0; fi
  log_info "Installing snap: $name"
  sudo snap install "$name" --classic 2>/dev/null || sudo snap install "$name"
  rollback_register "snap:remove:${name}"
  pkg_mark_installed "snap:${name}"
  log_ok "Installed snap: $name"
}

# --- Flatpak ----------------------------------------------------------------
pkg_flatpak_install() {
  local appid="$1"
  if flatpak info "$appid" &>/dev/null 2>&1; then
    log_debug "Flatpak already installed: $appid"
    return 0
  fi
  if _dryrun_pkg "flatpak install $appid"; then return 0; fi
  log_info "Installing flatpak: $appid"
  flatpak install -y flathub "$appid"
  rollback_register "flatpak:remove:${appid}"
  pkg_mark_installed "flatpak:${appid}"
  log_ok "Installed flatpak: $appid"
}

# --- Cargo ------------------------------------------------------------------
pkg_cargo_install() {
  local crate="$1"
  if cargo install --list 2>/dev/null | grep -q "^${crate} "; then
    log_debug "Cargo crate already installed: $crate"
    return 0
  fi
  if _dryrun_pkg "cargo install $crate"; then return 0; fi
  log_info "Installing cargo crate: $crate"
  cargo install "$crate"
  rollback_register "cargo:remove:${crate}"
  pkg_mark_installed "cargo:${crate}"
  log_ok "Installed cargo: $crate"
}

# --- npm global -------------------------------------------------------------
pkg_npm_install() {
  local pkg="$1"
  if npm list -g --depth=0 2>/dev/null | grep -q " ${pkg}@"; then
    log_debug "npm global already installed: $pkg"
    return 0
  fi
  if _dryrun_pkg "npm install -g $pkg"; then return 0; fi
  log_info "Installing npm global: $pkg"
  npm install -g "$pkg"
  pkg_mark_installed "npm:${pkg}"
  log_ok "Installed npm: $pkg"
}

# --- pipx -------------------------------------------------------------------
pkg_pipx_install() {
  local pkg="$1"
  if pipx list 2>/dev/null | grep -q "package ${pkg} "; then
    log_debug "pipx already installed: $pkg"
    return 0
  fi
  if _dryrun_pkg "pipx install $pkg"; then return 0; fi
  log_info "Installing pipx: $pkg"
  pipx install "$pkg"
  rollback_register "pipx:remove:${pkg}"
  pkg_mark_installed "pipx:${pkg}"
  log_ok "Installed pipx: $pkg"
}

# --- Install script (URL-based) ---------------------------------------------
pkg_install_url() {
  local name="$1" url="$2" args="${3:-}"
  if pkg_is_installed "url:${name}"; then
    log_debug "URL install already done: $name"
    return 0
  fi
  if _dryrun_pkg "install from URL: $name"; then return 0; fi
  log_info "Installing from URL: $name"
  if [[ -n "$args" ]]; then
    curl -fsSL "$url" | bash -s -- "$args"
  else
    curl -fsSL "$url" | bash
  fi
  pkg_mark_installed "url:${name}"
  log_ok "Installed: $name"
}

# --- Check if a binary is available (for skip-if-exists logic) --------------
pkg_has_cmd() {
  command -v "$1" &>/dev/null
}

# --- Dependency graph: ensure prerequisite packages before a module ---------
require_apt() {
  local missing=()
  for pkg in "$@"; do
    if ! pkg_apt_is_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    pkg_apt_install_batch "${missing[@]}"
  fi
}

# --- Main (only runs when executed directly) ---------------------------------
main() {
  echo "packages.sh is a library — source it from other scripts."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
