#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ---------------------------------------------------------------------------
# rollback.sh — Rollback registry and transaction management for DevOS
#
# Every module can register rollback actions. If the installer is interrupted
# or a module fails, actions execute in reverse (LIFO) order to unwind state.
#
# Safe to source multiple times.
# ---------------------------------------------------------------------------

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
source "${DEVOS_ROOT}/install/logger.sh"

# --- Load guard for sourcing -------------------------------------------------
if [[ -n "${DEVOS_ROLLBACK_LOADED:-}" ]]; then
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return
  fi
fi
readonly DEVOS_ROLLBACK_LOADED=1

# --- Rollback registry state ------------------------------------------------
ROLLBACK_FILE="${DEVOS_DATA}/rollback.txt"
mkdir_safe "$DEVOS_DATA"

declare -a _DEVOS_ROLLBACK_ACTIONS=()
DEVOS_HAD_ERROR=0

# Load persisted rollback entries from a previous interrupted run
_rollback_load() {
  _DEVOS_ROLLBACK_ACTIONS=()
  if [[ -r "$ROLLBACK_FILE" ]]; then
    local line
    while IFS= read -r line; do
      [[ -n "$line" ]] && _DEVOS_ROLLBACK_ACTIONS+=("$line")
    done < "$ROLLBACK_FILE"
  fi
}

# Persist current rollback stack to disk
_rollback_persist() {
  printf '%s\n' "${_DEVOS_ROLLBACK_ACTIONS[@]}" > "$ROLLBACK_FILE"
}

# --- Register a rollback action --------------------------------------------
rollback_register() {
  local action="$1"
  _DEVOS_ROLLBACK_ACTIONS+=("$action")
  _rollback_persist
  log_debug "Rollback registered: $action"
}

# --- Execute all rollback actions (LIFO) -----------------------------------
rollback_execute() {
  log_warn "Executing rollback (${#_DEVOS_ROLLBACK_ACTIONS[@]} actions)…"
  set +e
  local idx action type target
  for ((idx=${#_DEVOS_ROLLBACK_ACTIONS[@]}-1; idx>=0; idx--)); do
    action="${_DEVOS_ROLLBACK_ACTIONS[$idx]}"
    type="${action%%:*}"
    target="${action#*:}"
    target="${target#*:}"  # strip second colon (e.g. file:restore:<path>)

    case "$type" in
      file)
        if [[ -r "$target" ]]; then
          log_info "Restoring: $target"
          local dest="${target%.devos-bak}"
          cp -f "$target" "$dest"
          rm -f "$target"
        fi
        ;;
      pkg)
        log_info "Removing package: $target"
        sudo apt-get remove --purge -y "$target" 2>/dev/null || true
        ;;
      dir)
        if [[ -d "$target" ]]; then
          log_info "Removing directory: $target"
          rm -rf "$target"
        fi
        ;;
      cmd)
        log_info "Running: $target"
        eval "$target" 2>/dev/null || true
        ;;
      snap)
        log_info "Removing snap: $target"
        sudo snap remove "$target" 2>/dev/null || true
        ;;
      flatpak)
        log_info "Removing flatpak: $target"
        flatpak uninstall -y "$target" 2>/dev/null || true
        ;;
      pipx)
        log_info "Uninstalling pipx: $target"
        pipx uninstall "$target" 2>/dev/null || true
        ;;
      cargo)
        log_info "Uninstalling cargo: $target"
        cargo uninstall "$target" 2>/dev/null || true
        ;;
      *)
        log_warn "Unknown rollback action type: $type"
        ;;
    esac
  done
  set -e
  _DEVOS_ROLLBACK_ACTIONS=()
  _rollback_persist
  log_info "Rollback complete"
}

# --- Clear rollback registry (on success) ----------------------------------
rollback_clear() {
  _DEVOS_ROLLBACK_ACTIONS=()
  rm -f "$ROLLBACK_FILE"
  log_debug "Rollback registry cleared (success)"
}

# --- Transaction helpers ---------------------------------------------------
# Backup a file before modifying it (registers rollback automatically)
backup_file() {
  local src="$1"
  if [[ -f "$src" ]]; then
    local bak="${src}.devos-bak"
    cp -f "$src" "$bak"
    rollback_register "file:restore:${bak}"
    log_debug "Backed up: $src → $bak"
  else
    rollback_register "dir:remove:${src}"
    log_debug "New file registered for rollback: $src"
  fi
}

# --- Trap handler for error / interrupt ------------------------------------
_rollback_trap() {
  DEVOS_HAD_ERROR=1
  log_error "Installation interrupted. Rolling back changes…"
  rollback_execute
  exit 1
}

# Enable rollback trap (call at start of install.sh)
rollback_trap_enable() {
  trap _rollback_trap ERR INT TERM
}

# --- Main (only runs when executed directly) ---------------------------------
main() {
  echo "rollback.sh is a library — source it from other scripts."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
