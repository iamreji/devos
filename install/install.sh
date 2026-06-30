#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ===========================================================================
# install.sh — DevOS main entry point
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<user>/devos/main/install/install.sh | bash
#   ./install/install.sh [--all] [--module shell,git] [--dry-run] [--skip nvidia] [--force]
# ===========================================================================

set -Eeuo pipefail

# Resolve DevOS root
DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVOS_ROOT
readonly DEVOS_ROOT

# Source framework
source "${DEVOS_ROOT}/install/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"
source "${DEVOS_ROOT}/install/rollback.sh"
source "${DEVOS_ROOT}/install/packages.sh"

# --- Banner -----------------------------------------------------------------
_banner() {
  echo
  echo -e "${BOLD}${CYAN} ╔═══════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN} ║${RESET}  ${BOLD}DevOS${RESET} — Developer Workstation Bootstrap Framework    ${BOLD}${CYAN}║${RESET}"
  echo -e "${BOLD}${CYAN} ╚═══════════════════════════════════════════════════════╝${RESET}"
  echo
  log_info "OS:       ${DEVOS_OS_ID} ${DEVOS_OS_VERSION} (${DEVOS_ARCH})"
  log_info "Kernel:   ${DEVOS_KERNEL}"
  log_info "Home:     ${DEVOS_HOME}"
  log_info "Log:      ${DEVOS_LOG}"
  echo
}

# --- OS preflight -----------------------------------------------------------
_preflight() {
  log_section "Preflight Checks"

  if ! is_supported_os; then
    log_error "Unsupported OS. DevOS requires Ubuntu 24.04 or 26.04 (x86_64)."
    log_error "Detected: ${DEVOS_OS_ID} ${DEVOS_OS_VERSION} (${DEVOS_ARCH})"
    exit 1
  fi
  log_ok "Operating system supported"

  if ! _is_root && ! prompt_confirm "DevOS needs sudo. Install packages system-wide?"; then
    log_error "Sudo access is required. Exiting."
    exit 1
  fi

  # Check sudo validity
  if ! sudo -n true 2>/dev/null; then
    log_info "Sudo required. You may be prompted for your password."
  fi

  # Ensure basic tools
  ensure_curl_wget

  log_info "Memory: $(_mem_total_mb) MB"
  log_info "CPU cores: $(_cpu_count)"

  if _is_true "${DEVOS_DRYRUN:-0}"; then
    log_warn "DRY-RUN mode active — nothing will be installed"
    echo
  fi
}

# --- Module registry --------------------------------------------------------
# Define all available modules.
# Each entry: "module_name:display_name:dependencies,comma,separated"
# Dependencies are module names that must run before this module.
_register_all_modules() {
  _DEVOS_MODULES=(
    "shell:Shell & Command Line:"
    "git:Git Configuration:"
    "docker:Docker & Containers:"
    "node:Node.js Ecosystem:"
    "bun:Bun Runtime:"
    "pnpm:pnpm Package Manager:"
    "rust:Rust Toolchain:"
    "cargo:Cargo Tools:"
    "solana:Solana CLI:"
    "anchor:Anchor Framework:"
    "foundry:Foundry (Forge/Cast):"
    "nvidia:NVIDIA + CUDA:nvidia"
    "fonts:Nerd Fonts:"
    "terminal:Terminal Emulators:"
    "desktop:GNOME Desktop:"
    "gnome:GNOME Tweaks:"
    "wayland:Wayland Setup:"
    "cursor:Cursor Editor:"
    "vscode:VS Code Editor:"
    "nvim:Neovim:"
  )
}

# --- Parse flags ------------------------------------------------------------
_parse_flags() {
  DEVOS_MODULES_SELECTED=""
  DEVOS_ALL=0
  DEVOS_DRYRUN=0
  DEVOS_FORCE=0
  DEVOS_SKIP_MODULES=""
  DEVOS_ONLY_MODULES=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        DEVOS_ALL=1; shift ;;
      --dry-run)
        DEVOS_DRYRUN=1; shift ;;
      --force)
        DEVOS_FORCE=1; shift ;;
      --module)
        DEVOS_ONLY_MODULES="${2}"; shift 2 ;;
      --skip)
        DEVOS_SKIP_MODULES="${2}"; shift 2 ;;
      --debug)
        export DEVOS_DEBUG=1; shift ;;
      --help|-h)
        _usage; exit 0 ;;
      *)
        log_error "Unknown option: $1"
        _usage; exit 1 ;;
    esac
  done
}

_usage() {
  echo "Usage: devos [OPTIONS]"
  echo
  echo "Options:"
  echo "  --all              Install all modules"
  echo "  --module <names>   Install only specified modules (comma-separated)"
  echo "  --skip <names>     Skip specified modules (comma-separated)"
  echo "  --dry-run          Show what would be installed without doing it"
  echo "  --force            Reinstall even if already installed"
  echo "  --debug            Enable debug output"
  echo "  --help, -h         Show this help message"
  echo
  echo "Examples:"
  echo "  devos --all                         # Full workstation setup"
  echo "  devos --module shell,git,rust       # Install specific modules"
  echo "  devos --all --skip nvidia           # Everything except NVIDIA"
  echo "  devos --dry-run --all               # Preview installation plan"
}

# --- Resolve selected modules ------------------------------------------------
_resolve_modules() {
  local skip_arr=()
  if [[ -n "$DEVOS_SKIP_MODULES" ]]; then
    IFS=',' read -ra skip_arr <<< "$DEVOS_SKIP_MODULES"
  fi

  local only_arr=()
  if [[ -n "$DEVOS_ONLY_MODULES" ]]; then
    IFS=',' read -ra only_arr <<< "$DEVOS_ONLY_MODULES"
  fi

  DEVOS_SELECTED_MODULES=()
  for entry in "${_DEVOS_MODULES[@]}"; do
    local mod_name="${entry%%:*}"
    local rest="${entry#*:}"
    local display="${rest%%:*}"

    # Check skip list
    local skip=0
    for s in "${skip_arr[@]}"; do
      if [[ "$mod_name" == "$s" ]]; then skip=1; break; fi
    done
    [[ $skip -eq 1 ]] && continue

    # Check only list (if specified)
    if [[ ${#only_arr[@]} -gt 0 ]]; then
      local found=0
      for o in "${only_arr[@]}"; do
        if [[ "$mod_name" == "$o" ]]; then found=1; break; fi
      done
      [[ $found -eq 0 ]] && continue
    fi

    # If --all not set and no --module specified, we need explicit selection
    if [[ $DEVOS_ALL -eq 0 ]] && [[ ${#only_arr[@]} -eq 0 ]]; then
      continue
    fi

    DEVOS_SELECTED_MODULES+=("$entry")
  done
}

# --- Run a single module -----------------------------------------------------
_run_module() {
  local mod_name="$1"
  local mod_dir="${DEVOS_ROOT}/modules"
  local mod_script="${mod_dir}/${mod_name}.sh"

  if [[ ! -f "$mod_script" ]]; then
    log_warn "Module script not found: ${mod_script}"
    return 2
  fi

  if [[ $DEVOS_FORCE -eq 0 ]] && pkg_is_installed "mod:${mod_name}"; then
    log_info "Module '${mod_name}' already installed (use --force to reinstall)"
    return 0
  fi

  log_section "Module: ${mod_name}"

  if _is_true "$DEVOS_DRYRUN"; then
    log_info "[DRY-RUN] Would execute: ${mod_script}"
    return 0
  fi

  source "$mod_script"

  if declare -f "install_${mod_name}" &>/dev/null; then
    "install_${mod_name}"
  elif declare -f "install" &>/dev/null; then
    install
  else
    log_error "Module ${mod_name} does not define an install function"
    return 1
  fi

  pkg_mark_installed "mod:${mod_name}"
  log_ok "Module '${mod_name}' complete"
  return 0
}

# --- Print summary ----------------------------------------------------------
_print_summary() {
  echo
  print_hr
  log_section "Installation Summary"
  if _is_true "$DEVOS_DRYRUN"; then
    log_warn "This was a dry run. No changes were made."
  fi
  log_info "Log file: ${DEVOS_LOG}"
  echo

  if [[ $DEVOS_HAD_ERROR -eq 0 ]]; then
    log_ok "DevOS installation complete. Your workstation is ready!"
    echo
  fi
}

# --- Main --------------------------------------------------------------------
main() {
  _banner
  _register_all_modules
  _parse_flags "$@"
  _preflight
  _resolve_modules

  if [[ ${#DEVOS_SELECTED_MODULES[@]} -eq 0 ]]; then
    log_warn "No modules selected. Use --all for full setup or --module <names> for specific modules."
    echo
    _usage
    exit 0
  fi

  log_info "Selected ${#DEVOS_SELECTED_MODULES[@]} module(s):"
  for entry in "${DEVOS_SELECTED_MODULES[@]}"; do
    local name="${entry%%:*}"
    local rest="${entry#*:}"
    local display="${rest%%:*}"
    printf '  %b• %s%b — %s\n' "$BOLD" "$name" "$RESET" "$display"
  done
  echo

  if ! _is_true "$DEVOS_DRYRUN" && ! _is_true "$DEVOS_FORCE" && ! prompt_confirm "Proceed with installation?"; then
    log_info "Installation cancelled."
    exit 0
  fi

  rollback_trap_enable

  local failed=""
  for entry in "${DEVOS_SELECTED_MODULES[@]}"; do
    local mod_name="${entry%%:*}"
    if ! _run_module "$mod_name"; then
      failed+=" $mod_name"
    fi
  done

  if [[ -n "$failed" ]]; then
    log_error "Failed modules:$failed"
    _print_summary
    exit 1
  fi

  rollback_clear
  _print_summary
}

main "$@"
