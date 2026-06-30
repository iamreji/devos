#!/usr/bin/env bash
# cursor.sh — Cursor editor installation and configuration
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_cursor() {
  log_section "Cursor Editor"

  if command -v cursor &>/dev/null; then
    log_info "Cursor already installed"
  else
    log_info "Installing Cursor..."
    # Cursor provides an AppImage — download and install
    local cursor_url="https://downloader.cursor.sh/linux/appImage/x64"
    local cursor_dir="$HOME/.local/cursor"
    mkdir -p "$cursor_dir"
    curl -L "$cursor_url" -o "$cursor_dir/cursor.AppImage" 2>/dev/null
    chmod +x "$cursor_dir/cursor.AppImage"
    ln -sf "$cursor_dir/cursor.AppImage" "$HOME/.local/bin/cursor"

    # Desktop entry
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/cursor.desktop" <<'DESKTOP'
[Desktop Entry]
Name=Cursor
Comment=AI-first Code Editor
Exec=$HOME/.local/bin/cursor --no-sandbox %F
Icon=cursor
Type=Application
Categories=Development;IDE;
StartupWMClass=Cursor
DESKTOP
    log_ok "Cursor installed"
  fi

  # Deploy settings
  local cursor_dir="$HOME/.config/Cursor/User"
  mkdir -p "$cursor_dir"

  if [[ -f "${DEVOS_ROOT}/configs/cursor/settings.json" ]]; then
    cp "${DEVOS_ROOT}/configs/cursor/settings.json" "$cursor_dir/settings.json"
    log_ok "Cursor settings deployed"
  fi

  pkg_mark_installed "mod:cursor"
  log_section "Cursor Setup Complete"
}
