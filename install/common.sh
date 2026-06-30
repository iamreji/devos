#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ---------------------------------------------------------------------------
# common.sh — Shared utilities, constants, and strict-mode setup for DevOS
#
# Source this file in every DevOS script to inherit:
#   - Strict error handling (set -Eeuo pipefail)
#   - Color constants for terminal output
#   - OS / architecture detection
#   - Path and user utilities
#   - Trap handlers for cleanup and rollback
#
# Usage:
#   source "${DEVOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/common.sh"
# ---------------------------------------------------------------------------

set -Eeuo pipefail

# --- Global root -----------------------------------------------------------
DEVOS_ROOT="${DEVOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly DEVOS_ROOT

# --- User and system paths -------------------------------------------------
DEVOS_HOME="${DEVOS_HOME:-$HOME}"
DEVOS_DATA="${DEVOS_DATA:-$DEVOS_HOME/.local/share/devos}"
DEVOS_CONFIG="${DEVOS_CONFIG:-$DEVOS_HOME/.config/devos}"
DEVOS_CACHE="${DEVOS_CACHE:-$DEVOS_HOME/.cache/devos}"
DEVOS_LOG="${DEVOS_LOG:-$DEVOS_DATA/install.log}"
readonly DEVOS_HOME DEVOS_DATA DEVOS_CONFIG DEVOS_CACHE

mkdir -p "$DEVOS_DATA" "$DEVOS_CONFIG" "$DEVOS_CACHE"

# --- OS detection ----------------------------------------------------------
DEVOS_OS="$(uname -s)"
DEVOS_ARCH="$(uname -m)"
DEVOS_KERNEL="$(uname -r)"
readonly DEVOS_OS DEVOS_ARCH DEVOS_KERNEL

_devos_os_id=""
_devos_os_version_id=""
if command -v lsb_release &>/dev/null; then
  _devos_os_id="$(lsb_release -is 2>/dev/null || true)"
  _devos_os_version_id="$(lsb_release -rs 2>/dev/null || true)"
elif [[ -r /etc/os-release ]]; then
  _devos_os_id="$(. /etc/os-release && echo "${ID:-}")"
  _devos_os_version_id="$(. /etc/os-release && echo "${VERSION_ID:-}")"
fi
DEVOS_OS_ID="${_devos_os_id,,}"
DEVOS_OS_VERSION="${_devos_os_version_id}"
readonly DEVOS_OS_ID DEVOS_OS_VERSION
unset _devos_os_id _devos_os_version_id

is_ubuntu()  { [[ "$DEVOS_OS_ID" == "ubuntu" ]]; }
is_debian()  { [[ "$DEVOS_OS_ID" == "debian" ]]; }
is_arch64()  { [[ "$DEVOS_ARCH" == "x86_64" || "$DEVOS_ARCH" == "amd64" ]]; }
is_arm64()   { [[ "$DEVOS_ARCH" == "aarch64" || "$DEVOS_ARCH" == "arm64" ]]; }
is_supported_os() {
  is_ubuntu && is_arch64 && { [[ "$DEVOS_OS_VERSION" == "24.04" ]] || [[ "$DEVOS_OS_VERSION" == "26.04" ]]; }
}

# --- Colour constants (tty-safe) -------------------------------------------
if [[ -t 1 ]] && command -v tput &>/dev/null && tput setaf 1 &>/dev/null; then
  readonly BOLD="$(tput bold)"
  readonly RED="$(tput setaf 1)"
  readonly GREEN="$(tput setaf 2)"
  readonly YELLOW="$(tput setaf 3)"
  readonly BLUE="$(tput setaf 4)"
  readonly MAGENTA="$(tput setaf 5)"
  readonly CYAN="$(tput setaf 6)"
  readonly WHITE="$(tput setaf 7)"
  readonly RESET="$(tput sgr0)"
  readonly DIM="$(tput dim)"
else
  readonly BOLD="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE="" RESET="" DIM=""
fi

# --- Logging fallbacks (overridden when logger.sh is sourced) ---------------
if ! declare -f log_info &>/dev/null; then
  _log_emit() { echo -e "${2:-}${DEVOS_OS:-DevOS}: ${1}${RESET:-}" >&2; }
  log_info()  { _log_emit "$*" "$BLUE"; }
  log_ok()    { _log_emit "$*" "$GREEN"; }
  log_warn()  { _log_emit "$*" "$YELLOW"; }
  log_error() { _log_emit "$*" "$RED"; }
  log_debug() { [[ -n "${DEVOS_DEBUG:-}" ]] && _log_emit "[DEBUG] $*" "$DIM"; }
  log_section() { _log_emit "══════ $* ══════" "$BOLD$CYAN"; }
fi

# --- Root detection ---------------------------------------------------------
_is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

# --- User confirmation ------------------------------------------------------
prompt_confirm() {
  local msg="${1:-Continue?}"
  local answer
  read -r -p "${YELLOW}${msg}${RESET} [y/N] " answer
  [[ "${answer,,}" =~ ^(y|yes)$ ]]
}

# --- Path deduplication -----------------------------------------------------
dedup_path() {
  local var_name="$1"
  local entry="$2"
  local current="${!var_name:-}"
  current=":${current}:"
  current="${current//:$entry:/:}"
  current="${current#:}"
  current="${current%:}"
  if [[ -z "$current" ]]; then
    printf -v "$var_name" '%s' "$entry"
  else
    printf -v "$var_name" '%s' "$entry:$current"
  fi
}

# --- Directory helper -------------------------------------------------------
mkdir_safe() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" || return 1
  fi
}

# --- Trap stack for cleanup -------------------------------------------------
declare -a _DEVOS_CLEANUP_STACK=()
_add_cleanup() { _DEVOS_CLEANUP_STACK+=("$*"); }
_run_cleanup() {
  set +e
  local idx cmd
  for ((idx=${#_DEVOS_CLEANUP_STACK[@]}-1; idx>=0; idx--)); do
    cmd="${_DEVOS_CLEANUP_STACK[$idx]}"
    eval "$cmd" 2>/dev/null || true
  done
  set -e
}
trap _run_cleanup EXIT INT TERM

# --- Temporary files --------------------------------------------------------
_devos_mktemp() {
  local template="${1:-tmp.XXXXXX}"
  mktemp -t "devos-${template}" 2>/dev/null || mktemp "/tmp/devos-${template}"
}

# --- Retry command ----------------------------------------------------------
retry() {
  local max_attempts="$1"; shift
  local attempt=1 delay=2
  while true; do
    if "$@"; then return 0; fi
    if (( attempt >= max_attempts )); then return 1; fi
    log_warn "Retrying in ${delay}s (${attempt}/${max_attempts})…"
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
  done
}

# --- Require commands -------------------------------------------------------
require_cmd() {
  local cmd missing=""
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=" $cmd"
    fi
  done
  if [[ -n "$missing" ]]; then
    log_error "Required command(s) not found:${missing}"
    return 1
  fi
}

# --- Ensure curl/wget available (pre-bootstrap) ----------------------------
ensure_curl_wget() {
  local missing=""
  command -v curl &>/dev/null || missing+=" curl"
  command -v wget &>/dev/null || missing+=" wget"
  if [[ -n "$missing" ]]; then
    log_info "Installing prerequisites:${missing} …"
    sudo apt-get update -qq
    sudo apt-get install -y -qq curl wget
  fi
}

# --- String helpers ---------------------------------------------------------
_is_true() {
  local val="${1:-}"
  [[ "${val,,}" =~ ^(true|1|yes|on)$ ]]
}

# --- Version comparison -----------------------------------------------------
ver_ge() { printf '%s\n%s' "$2" "$1" | sort -V -C; }

# --- CPU count --------------------------------------------------------------
_cpu_count() { nproc 2>/dev/null || echo 4; }

# --- Memory total (MB) ------------------------------------------------------
_mem_total_mb() {
  if [[ -r /proc/meminfo ]]; then
    awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo
  else
    echo "0"
  fi
}

# --- Check if command is available ------------------------------------------
has_cmd() { command -v "$1" &>/dev/null; }

# --- Print a horizontal rule ------------------------------------------------
print_hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '─'; }

# --- Run with spinner for long operations -----------------------------------
_spinner() {
  local pid="$1"
  local spin='-\|/'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r[%s] ' "${spin:i++%4:1}" >&2
    sleep 0.1
  done
  printf '\r    \r' >&2
}

DEVOS_COMMON_LOADED=1
readonly DEVOS_COMMON_LOADED
