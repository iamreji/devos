#!/usr/bin/env bash
# -*- mode: bash; tab-width: 2; indent-tabs-mode: nil; -*-
# ---------------------------------------------------------------------------
# logger.sh — Structured logging for DevOS
#
# Sources common.sh and provides timestamped, colour-coded log output
# to both stderr and the session log file.
# ---------------------------------------------------------------------------

# Ensure common.sh is loaded
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi

# --- Log file -----------------------------------------------------------------
DEVOS_LOG="${DEVOS_LOG:-$DEVOS_DATA/install.log}"
mkdir -p "$(dirname "$DEVOS_LOG")"
touch "$DEVOS_LOG"

# --- Timestamp ----------------------------------------------------------------
_now() { date '+%Y-%m-%d %H:%M:%S'; }

# --- Core log functions -------------------------------------------------------
log_info() {
  local ts
  ts="$(_now)"
  printf '%b[%s] %sINFO  %s%b\n' "$BLUE" "$ts" "$RESET" "$*" "$RESET" >&2
  echo "[$ts] INFO  $*" >> "$DEVOS_LOG"
}

log_ok() {
  local ts
  ts="$(_now)"
  printf '%b[%s] %sOK    %s%b\n' "$GREEN" "$ts" "$RESET" "$*" "$RESET" >&2
  echo "[$ts] OK    $*" >> "$DEVOS_LOG"
}

log_warn() {
  local ts
  ts="$(_now)"
  printf '%b[%s] %sWARN  %s%b\n' "$YELLOW" "$ts" "$RESET" "$*" "$RESET" >&2
  echo "[$ts] WARN  $*" >> "$DEVOS_LOG"
}

log_error() {
  local ts
  ts="$(_now)"
  printf '%b[%s] %sERROR %s%b\n' "$RED" "$ts" "$RESET" "$*" "$RESET" >&2
  echo "[$ts] ERROR $*" >> "$DEVOS_LOG"
}

log_debug() {
  if [[ -n "${DEVOS_DEBUG:-}" ]]; then
    local ts
    ts="$(_now)"
    printf '%b[%s] %sDEBUG %s%b\n' "$DIM" "$ts" "$RESET" "$*" "$RESET" >&2
    echo "[$ts] DEBUG $*" >> "$DEVOS_LOG"
  fi
}

log_section() {
  local ts line
  ts="$(_now)"
  line="══════ $* ══════"
  printf '%b[%s] %b%s%b\n' "$BOLD$CYAN" "$ts" "$BOLD$CYAN" "$line" "$RESET" >&2
  echo "[$ts] ---- $line" >> "$DEVOS_LOG"
}

# --- Progress bar helper -------------------------------------------------------
log_progress() {
  local current="$1" total="$2" label="${3:-Progress}"
  local pct=$(( current * 100 / (total > 0 ? total : 1) ))
  local bar_width=40
  local filled=$(( pct * bar_width / 100 ))
  local empty=$(( bar_width - filled ))
  printf '\r%b[%s] %s : [%s%s] %3d%%%b' "$BLUE" "$(_now)" "$label" \
    "$(printf '#%.0s' $(seq 1 $filled 2>/dev/null) || printf '%*s' "$filled" | tr ' ' '#')" \
    "$(printf '%*s' "$empty" | tr ' ' '-')" "$pct" "$RESET" >&2
  if [[ "$current" -eq "$total" ]]; then
    printf '\n' >&2
  fi
}

# --- Status table row ----------------------------------------------------------
log_check() {
  local check="$1" status="$2"
  local colour icon
  case "${status,,}" in
    pass|ok|installed)
      colour="$GREEN" icon="✔"
      ;;
    warn|skip)
      colour="$YELLOW" icon="⚠"
      ;;
    fail|error|missing)
      colour="$RED" icon="✘"
      ;;
    *)
      colour="$RESET" icon="·"
      ;;
  esac
  printf '%b  %s %-50s %s%b\n' "$colour" "$icon" "$check" "$status" "$RESET"
  echo "$(_now) CHECK $check → $status" >> "$DEVOS_LOG"
}

DEVOS_LOGGER_LOADED=1
readonly DEVOS_LOGGER_LOADED
