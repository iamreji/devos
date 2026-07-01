#!/usr/bin/env bash
# wallpaper.sh — Desktop wallpaper setup
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_wallpaper() {
  log_section "Desktop Wallpaper"

  local wallpaper_dir="$HOME/Pictures/Wallpapers"
  mkdir -p "$wallpaper_dir"

  # Check if we have wallpapers in the repo assets
  local repo_wallpapers="${DEVOS_ROOT}/assets/wallpapers"
  local deployed=0

  if [[ -d "$repo_wallpapers" ]] && [[ "$(ls -A "$repo_wallpapers" 2>/dev/null)" ]]; then
    log_info "Deploying wallpapers from repo..."
    cp -r "$repo_wallpapers"/* "$wallpaper_dir/" 2>/dev/null || true
    deployed=1
  fi

  # If no wallpapers in repo, download a curated set
  if [[ $deployed -eq 0 ]]; then
    log_info "Downloading curated wallpapers..."

    # Download a few high-quality developer wallpapers
    local wallpapers=(
      "https://raw.githubusercontent.com/soumik12345/wallpapers/main/code.png"
      "https://raw.githubusercontent.com/soumik12345/wallpapers/main/abstract.png"
      "https://raw.githubusercontent.com/soumik12345/wallpapers/main/matrix.png"
    )

    for url in "${wallpapers[@]}"; do
      local filename
      filename="$(basename "$url")"
      if [[ ! -f "${wallpaper_dir}/${filename}" ]]; then
        curl -fsSL "$url" -o "${wallpaper_dir}/${filename}" 2>/dev/null && deployed=1 || true
      fi
    done
  fi

  # Set GNOME wallpaper (both light and dark variants if available)
  if command -v gsettings &>/dev/null; then
    local first_wallpaper
    first_wallpaper="$(find "$wallpaper_dir" -type f | head -1)" || true
    if [[ -n "$first_wallpaper" ]]; then
      # Set picture URI
      gsettings set org.gnome.desktop.background picture-uri "file://${first_wallpaper}" 2>/dev/null || true
      gsettings set org.gnome.desktop.background picture-uri-dark "file://${first_wallpaper}" 2>/dev/null || true
      # Set picture options
      gsettings set org.gnome.desktop.background picture-options "zoom" 2>/dev/null || true
      log_ok "GNOME wallpaper set"
    fi
  fi

  # Deploy wallpaper changer systemd user service (optional)
  local service_dir="$HOME/.config/systemd/user"
  local service_file="${service_dir}/wallpaper-changer.service"

  if [[ ! -f "$service_file" ]] && [[ -d "$wallpaper_dir" ]]; then
    mkdir -p "$service_dir"

    cat > "$service_file" <<WPSERVICE
[Unit]
Description=Wallpaper Changer
Documentation=https://github.com/soumik12345/wallpapers

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'WALLPAPER=\$(find ${wallpaper_dir} -type f | shuf -n1); gsettings set org.gnome.desktop.background picture-uri "file://\${WALLPAPER}" 2>/dev/null; gsettings set org.gnome.desktop.background picture-uri-dark "file://\${WALLPAPER}" 2>/dev/null'
RemainAfterExit=no

[Install]
WantedBy=default.target
WPSERVICE

    # Create a timer to change wallpaper every hour
    local timer_file="${service_dir}/wallpaper-changer.timer"
    cat > "$timer_file" <<WPTIMER
[Unit]
Description=Wallpaper Changer Timer

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
WPTIMER

    systemctl --user daemon-reload 2>/dev/null || true
    log_ok "Wallpaper changer service deployed (changes wallpaper hourly)"
  fi

  # Add wallpaper-related aliases
  local aliases_file="$HOME/.config/zsh/aliases.zsh"
  if [[ -f "$aliases_file" ]] && ! grep -q "wp-change" "$aliases_file" 2>/dev/null; then
    cat >> "$aliases_file" <<'WPALIAS'

# --- Wallpaper Aliases -------------------------------------------------
alias wp-change="find ~/Pictures/Wallpapers -type f | shuf -n1 | xargs -I{} gsettings set org.gnome.desktop.background picture-uri file://'{}'"
alias wp-dark="find ~/Pictures/Wallpapers -type f | shuf -n1 | xargs -I{} gsettings set org.gnome.desktop.background picture-uri-dark file://'{}'"
alias wp-random="wp-change && wp-dark"
alias wp-dir="cd ~/Pictures/Wallpapers"
WPALIAS
    log_ok "Wallpaper aliases added"
  fi

  log_ok "Wallpapers deployed to ${wallpaper_dir}"
  pkg_mark_installed "mod:wallpaper"
  log_section "Wallpaper Setup Complete"
}
