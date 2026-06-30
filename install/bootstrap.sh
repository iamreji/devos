#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ===========================================================================
# bootstrap.sh — DevOS bootstrap / phase-runner
#
# Called by install.sh to execute all selected modules in order.
# Handles resume-from on failure and tracks progress across phases.
# ===========================================================================

if [[ -z "${DEVOS_ROOT:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export DEVOS_ROOT
fi

source "${DEVOS_ROOT}/install/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"

# --- Run a single module ------------------------------------------------
bootstrap_module() {
  local mod_name="$1"
  local mod_dir="${DEVOS_ROOT}/modules"
  local mod_script="${mod_dir}/${mod_name}.sh"

  if [[ ! -f "$mod_script" ]]; then
    log_warn "Module script not found: ${mod_script}"
    return 2
  fi

  # Track progress in a state file so we can resume
  local progress_file="${DEVOS_DATA}/bootstrap_progress.txt"
  if grep -Fxq "$mod_name" "$progress_file" 2>/dev/null; then
    log_info "Module '${mod_name}' already completed (resume mode)"
    return 0
  fi

  log_section "Bootstrapping: ${mod_name}"

  source "$mod_script"

  if declare -f "install_${mod_name}" &>/dev/null; then
    "install_${mod_name}"
  elif declare -f "install" &>/dev/null; then
    install
  else
    log_error "Module '${mod_name}' does not define an install function"
    return 1
  fi

  echo "$mod_name" >> "$progress_file"
  log_ok "Module '${mod_name}' bootstrapped"
  return 0
}

# --- Bootstrap all given modules ----------------------------------------
bootstrap_all() {
  local modules=("$@")
  local progress_file="${DEVOS_DATA}/bootstrap_progress.txt"
  mkdir_safe "$DEVOS_DATA"
  touch "$progress_file"

  local failed=""
  for mod in "${modules[@]}"; do
    if ! bootstrap_module "$mod"; then
      failed+=" $mod"
    fi
  done

  if [[ -n "$failed" ]]; then
    log_error "Bootstrap failed for:$failed"
    return 1
  fi

  rm -f "$progress_file"
  log_section "Bootstrap Complete"
  return 0
}

# Direct invocation support
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  bootstrap_all "$@"
fi
