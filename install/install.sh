#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ===========================================================================
# install.sh — DevOS main entry point
#
# World-class developer workstation bootstrap framework.
# Features: dependency resolution, parallel execution, interactive TUI,
#           per-module timing, beautiful summaries.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<user>/devos/main/install/install.sh | bash
#   ./install/install.sh [--all] [--module shell,git] [--dry-run] [--skip nvidia] [--force]
# ===========================================================================

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"
source "${DEVOS_ROOT}/install/rollback.sh"
source "${DEVOS_ROOT}/install/packages.sh"

# === Banner ==================================================================
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

# === Module Registry =========================================================
# Format: "name:display:category:deps"
#   name     — module script name (modules/<name>.sh must exist)
#   display  — human-readable label
#   category — group for TUI display (language, tool, desktop, cloud, etc.)
#   deps     — comma-separated module names required before this one
_DEVOS_MODULE_REGISTRY=()
_register_all_modules() {
  _DEVOS_MODULE_REGISTRY=(
    "shell:Shell & CLI Tools:core:"
    "git:Git Configuration:core:shell"
    "fonts:Nerd Fonts:core:"
    "python:Python Ecosystem:lang:shell"
    "go:Go Language:lang:shell"
    "node:Node.js Ecosystem:lang:shell"
    "bun:Bun Runtime:lang:node"
    "pnpm:pnpm Package Manager:lang:node"
    "rust:Rust Toolchain:lang:shell"
    "cargo:Cargo Tools:lang:rust"
    "solana:Solana CLI:blockchain:rust"
    "anchor:Anchor Framework:blockchain:rust,solana"
    "foundry:Foundry (Forge/Cast):blockchain:rust"
    "docker:Docker & Containers:infra:"
    "databases:PostgreSQL + Redis:infra:"
    "cloud:AWS CLI + GCP CLI:cloud:"
    "kubernetes:K8s Tooling:cloud:"
    "nvidia:NVIDIA + CUDA:hardware:"
    "terminal:Terminal Emulators:desktop:"
    "desktop:GNOME Desktop:desktop:shell"
    "gnome:GNOME Tweaks:desktop:desktop"
    "wayland:Wayland Setup:desktop:desktop"
    "precommit:Pre-commit Hooks:tools:"
    "wallpaper:Desktop Wallpaper:desktop:desktop"
    "cursor:Cursor Editor:editors:"
    "vscode:VS Code Editor:editors:"
    "nvim:Neovim:editors:"
  )
  # Store module count for reference
  _DEVOS_MODULE_COUNT=${#_DEVOS_MODULE_REGISTRY[@]}
}

# === Dependency Resolution ===================================================
# Build execution layers: Layer 0 = no deps, Layer N = depends on Layer N-1
_build_layers() {
  local selected=("$@")
  local -A selected_map deps_of
  local name entry rest display category deps_raw

  # Build selected map and dep map
  for entry in "${_DEVOS_MODULE_REGISTRY[@]}"; do
    name="${entry%%:*}"
    selected_map["$name"]=0
  done
  for entry in "${_DEVOS_MODULE_REGISTRY[@]}"; do
    name="${entry%%:*}"
    rest="${entry#*:}"
    display="${rest%%:*}"
    rest="${rest#*:}"
    category="${rest%%:*}"
    deps_raw="${rest#*:}"
    deps_of["$name"]="$deps_raw"
  done

  # Mark selected
  for s in "${selected[@]}"; do
    selected_map["$s"]=1
  done

  # Recursive dep resolution: for each selected module, collect all transitive deps
  local -a resolved=()
  local -A visited
  _resolve_deps() {
    local mod="$1"
    [[ "${visited[$mod]:-0}" -eq 1 ]] && return
    visited["$mod"]=1
    local deps="${deps_of[$mod]:-}"
    if [[ -n "$deps" ]]; then
      local IFS=','
      for d in $deps; do
        _resolve_deps "$d"
      done
    fi
    resolved+=("$mod")
  }

  for s in "${selected[@]}"; do
    _resolve_deps "$s"
  done

  # Build layers: level 0 = modules with no unresolved deps, etc.
  local -A layer_of
  local max_layer=0
  for mod in "${resolved[@]}"; do
    local deps="${deps_of[$mod]:-}"
    local layer=0
    if [[ -n "$deps" ]]; then
      local IFS=','
      for d in $deps; do
        local dl="${layer_of[$d]:-0}"
        (( dl + 1 > layer )) && layer=$((dl + 1))
      done
    fi
    layer_of["$mod"]=$layer
    (( layer > max_layer )) && max_layer=$layer
  done

  # Build array of layers
  local -a layers_result=()
  local l
  for ((l = 0; l <= max_layer; l++)); do
    local layer_mods=""
    for mod in "${resolved[@]}"; do
      if [[ "${layer_of[$mod]:-0}" -eq $l ]]; then
        layer_mods+="$mod "
      fi
    done
    layers_result+=("${layer_mods% }")
  done

  echo "${layers_result[@]}"
}

# === Timing Tracker ==========================================================
declare -a _MODULE_TIMINGS=()
_MODULE_START_TIME=0

_timing_start() { _MODULE_START_TIME="$EPOCHREALTIME"; }

_timing_stop() {
  local name="$1" status="$2"
  local elapsed
  elapsed="$(LC_NUMERIC=C awk "BEGIN { printf \"%.1f\", $EPOCHREALTIME - $_MODULE_START_TIME }")"
  _MODULE_TIMINGS+=("${name}|${status}|${elapsed}")
}

# === Preflight ===============================================================
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

  if ! sudo -n true 2>/dev/null; then
    log_info "Sudo required. You may be prompted for your password."
  fi

  ensure_curl_wget

  log_info "Memory: $(_mem_total_mb) MB"
  log_info "CPU cores: $(_cpu_count)"
  echo
}

# === Interactive Module Selector =============================================
_interactive_select() {
  log_info "No modules specified. Launching interactive selector..."
  echo

  # Group modules by category
  local -A categories
  local entry name display category
  for entry in "${_DEVOS_MODULE_REGISTRY[@]}"; do
    name="${entry%%:*}"
    rest="${entry#*:}"
    display="${rest%%:*}"
    rest="${rest#*:}"
    category="${rest%%:*}"
    categories["$category"]+="$name:$display "
  done

  local all_categories
  all_categories=$(printf '%s\n' "${!categories[@]}" | sort -u)
  local selected_modules=()

  # If fzf is available, use it for multi-select
  if command -v fzf &>/dev/null; then
    log_info "Using fzf for module selection (TAB to toggle, Enter to confirm)"
    echo

    local fzf_input=""
    for cat in $all_categories; do
      fzf_input+="# ${cat^^}\n"
      local items="${categories[$cat]}"
      local IFS=' '
      for item in $items; do
        local mod_name="${item%%:*}"
        local mod_display="${item#*:}"
        fzf_input+="${mod_name}  ${mod_display}\n"
      done
    done

    local chosen
    chosen="$(
      echo -e "$fzf_input" | fzf --multi \
        --header='Select modules (TAB=select, Enter=install)' \
        --prompt='Search modules > ' \
        --preview='echo "Module info: See docs/dev/"' \
        --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
        --height=70% \
        --layout=reverse \
        --color='header:italic:cyan' 2>/dev/null || true
    )"

    if [[ -n "$chosen" ]]; then
      while IFS= read -r line; do
        local mod_name="${line%%  *}"
        mod_name="${mod_name// /}"
        [[ -n "$mod_name" && ! "$mod_name" =~ ^# ]] && selected_modules+=("$mod_name")
      done <<< "$chosen"
    fi
  else
    # Fallback: numbered menu
    log_info "Install fzf for a better selection experience!"
    echo

    local -a menu_items=()
    local -a menu_names=()
    for cat in $all_categories; do
      local items="${categories[$cat]}"
      local IFS=' '
      for item in $items; do
        local mod_name="${item%%:*}"
        local mod_display="${item#*:}"
        menu_items+=("${mod_name} — ${mod_display}")
        menu_names+=("$mod_name")
      done
    done

    echo "Available modules:"
    local idx=0
    for item in "${menu_items[@]}"; do
      printf '  %2d) %s\n' $((idx + 1)) "$item"
      idx=$((idx + 1))
    done
    echo
    echo "Enter numbers separated by spaces (e.g., '1 3 5') or 'all':"
    read -r -p "> " selection
    echo

    if [[ "${selection,,}" == "all" ]]; then
      selected_modules=("${menu_names[@]}")
    else
      for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#menu_names[@]} ]]; then
          selected_modules+=("${menu_names[$((num - 1))]}")
        fi
      done
    fi
  fi

  if [[ ${#selected_modules[@]} -eq 0 ]]; then
    log_warn "No modules selected. Exiting."
    exit 0
  fi

  DEVOS_SELECTED_MODULES=("${selected_modules[@]}")
}

# === Parallel Layer Executor =================================================
_run_layer() {
  local layer_desc="$1"
  shift
  local -a mods=("$@")

  if [[ ${#mods[@]} -eq 0 ]]; then return 0; fi

  local max_jobs="$(_cpu_count)"
  [[ $max_jobs -lt 2 ]] && max_jobs=2
  [[ $max_jobs -gt 8 ]] && max_jobs=8

  log_info "Layer ${layer_desc}: ${#mods[@]} module(s) (concurrency: ${max_jobs})"

  local -a pids=()
  local -a pid_mods=()
  local -a pid_status=()
  local mod

  for mod in "${mods[@]}"; do
    # Throttle: if we've hit max_jobs, wait for one to finish
    while [[ ${#pids[@]} -ge $max_jobs ]]; do
      for i in "${!pids[@]}"; do
        if ! kill -0 "${pids[$i]}" 2>/dev/null; then
          wait "${pids[$i]}" 2>/dev/null || true
          unset 'pids[i]'
          unset 'pid_mods[i]'
          break
        fi
      done
      # Clean up null entries
      local -a new_pids=() new_mods=()
      for i in "${!pids[@]}"; do
        new_pids+=("${pids[$i]}")
        new_mods+=("${pid_mods[$i]}")
      done
      pids=("${new_pids[@]}")
      pid_mods=("${new_mods[@]}")
    done

    # Start module in background
    (
      _run_module "$mod" || true
    ) &
    pids+=($!)
    pid_mods+=("$mod")
  done

  # Wait for remaining modules
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  echo
}

# === Run a single module =====================================================
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
    pkg_mark_installed "mod:${mod_name}"
    return 0
  fi

  printf '\n%b══════ Module: %s ══════%b\n' "$BOLD$CYAN" "$mod_name" "$RESET"

  if _is_true "$DEVOS_DRYRUN"; then
    log_info "[DRY-RUN] Would execute: ${mod_script}"
    return 0
  fi

  _timing_start
  source "$mod_script"

  local exit_code=0
  if declare -f "install_${mod_name}" &>/dev/null; then
    "install_${mod_name}" || exit_code=$?
  elif declare -f "install" &>/dev/null; then
    install || exit_code=$?
  else
    log_error "Module '${mod_name}' does not define an install function"
    _timing_stop "$mod_name" "FAIL"
    return 1
  fi

  if [[ $exit_code -eq 0 ]]; then
    pkg_mark_installed "mod:${mod_name}"
    _timing_stop "$mod_name" "OK"
  else
    _timing_stop "$mod_name" "FAIL"
  fi

  return $exit_code
}

# === Parse CLI flags =========================================================
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
  echo "Usage: devos install [OPTIONS]"
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
  echo "  devos install --all                       # Full workstation setup"
  echo "  devos install --module shell,git,rust     # Install specific modules"
  echo "  devos install --all --skip nvidia         # Everything except NVIDIA"
  echo "  devos install --dry-run --all             # Preview installation plan"
  echo "  devos install                             # Interactive module picker"
  echo
  echo "Available modules:"
  for entry in "${_DEVOS_MODULE_REGISTRY[@]}"; do
    local name="${entry%%:*}"
    local rest="${entry#*:}"
    local display="${rest%%:*}"
    rest="${rest#*:}"
    local category="${rest%%:*}"
    printf '  %-14s %s (%s)\n' "$name" "$display" "$category"
  done
}

# === Resolve selected modules ================================================
_resolve_modules() {
  local skip_arr=()
  if [[ -n "$DEVOS_SKIP_MODULES" ]]; then
    IFS=',' read -ra skip_arr <<< "$DEVOS_SKIP_MODULES"
  fi

  local only_arr=()
  if [[ -n "$DEVOS_ONLY_MODULES" ]]; then
    IFS=',' read -ra only_arr <<< "$DEVOS_ONLY_MODULES"
  fi

  local selected=()
  for entry in "${_DEVOS_MODULE_REGISTRY[@]}"; do
    local mod_name="${entry%%:*}"

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

    selected+=("$mod_name")
  done

  DEVOS_SELECTED_MODULES=("${selected[@]}")
}

# === Enhanced Summary ========================================================
_print_summary() {
  echo
  print_hr
  log_section "Installation Summary"

  # Calculate totals
  local total=${#_MODULE_TIMINGS[@]}
  local ok=0 fail=0 total_time=0.0
  local name status elapsed
  for timing in "${_MODULE_TIMINGS[@]}"; do
    name="${timing%%|*}"
    rest="${timing#*|}"
    status="${rest%%|*}"
    elapsed="${rest#*|}"
    if [[ "$status" == "OK" ]]; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
    total_time="$(LC_NUMERIC=C awk "BEGIN { printf \"%.1f\", $total_time + $elapsed }")"
  done

  echo
  printf '  %bModules: %d installed, %d failed%b\n' "$BOLD" "$ok" "$fail" "$RESET"
  printf '  %bElapsed: %s seconds%b\n' "$DIM" "$total_time" "$RESET"
  echo

  # Print module timing table
  if [[ ${#_MODULE_TIMINGS[@]} -gt 0 ]]; then
    printf '  %-16s %-6s %s\n' "MODULE" "STATUS" "TIME"
    printf '  %-16s %-6s %s\n' "──────" "──────" "────"
    for timing in "${_MODULE_TIMINGS[@]}"; do
      name="${timing%%|*}"
      rest="${timing#*|}"
      status="${rest%%|*}"
      elapsed="${rest#*|}"
      local sc="$GREEN"
      [[ "$status" == "FAIL" ]] && sc="$RED"
      printf '  %b%-16s %-6s%b %ss\n' "$sc" "$name" "$status" "$RESET" "$elapsed"
    done
    echo
  fi

  log_info "Log file: ${DEVOS_LOG}"

  # Next steps
  echo
  log_section "Next Steps"
  if [[ "$ok" -gt 0 ]]; then
    echo
    if command -v exec &>/dev/null; then
      printf '  • %bRun%b   : exec zsh        (activate new shell)\n' "$BOLD" "$RESET"
    fi
    printf '  • %bCheck%b  : devos doctor     (run health check)\n' "$BOLD" "$RESET"
    printf '  • %bUpdate%b: devos update     (update all tools)\n' "$BOLD" "$RESET"
    printf '  • %bBackup%b: devos backup     (backup configs)\n' "$BOLD" "$RESET"
    echo
  fi

  if [[ $fail -gt 0 ]]; then
    log_warn "${fail} module(s) failed. Check the log for details:"
    log_warn "  ${DEVOS_LOG}"
    exit 1
  fi

  echo
  log_ok "DevOS installation complete. Your workstation is ready!"
  echo
}

# === Main ====================================================================
main() {
  _banner
  _register_all_modules
  _parse_flags "$@"
  _preflight

  # Interactive selection if no flags given
  if [[ $DEVOS_ALL -eq 0 ]] && [[ -z "$DEVOS_ONLY_MODULES" ]] && [[ -z "$DEVOS_SKIP_MODULES" ]]; then
    _interactive_select
  else
    _resolve_modules
  fi

  if [[ ${#DEVOS_SELECTED_MODULES[@]} -eq 0 ]]; then
    log_warn "No modules selected. Use --all for full setup or --module <names> for specific modules."
    echo
    _usage
    exit 0
  fi

  # Resolve dependencies and build execution layers
  local -a layers
  IFS=' ' read -ra layers <<< "$(_build_layers "${DEVOS_SELECTED_MODULES[@]}")"

  # Show installation plan
  echo
  log_info "Installation Plan:"
  local layer_num=0
  for layer in "${layers[@]}"; do
    if [[ -n "$layer" ]]; then
      printf '  Layer %d: %s\n' $layer_num "$layer"
    fi
    layer_num=$((layer_num + 1))
  done
  echo

  if ! _is_true "$DEVOS_DRYRUN" && ! _is_true "$DEVOS_FORCE" && ! prompt_confirm "Proceed with installation?"; then
    log_info "Installation cancelled."
    exit 0
  fi

  rollback_trap_enable

  # Execute layers in sequence, modules within a layer in parallel
  local layer_idx=0
  local failed_modules=""
  for layer in "${layers[@]}"; do
    if [[ -n "$layer" ]]; then
      _run_layer "$layer_idx" $layer
    fi
    layer_idx=$((layer_idx + 1))
  done

  # Check results
  for timing in "${_MODULE_TIMINGS[@]}"; do
    name="${timing%%|*}"
    rest="${timing#*|}"
    status="${rest%%|*}"
    if [[ "$status" == "FAIL" ]]; then
      failed_modules+=" $name"
    fi
  done

  if [[ -n "$failed_modules" ]]; then
    log_error "Failed modules:$failed_modules"
  fi

  rollback_clear 2>/dev/null || true
  _print_summary
}

main "$@"
