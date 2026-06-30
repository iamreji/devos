#!/usr/bin/env bash
# restore.sh — Restore a DevOS backup
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then
  source "${DEVOS_ROOT}/install/logger.sh"
fi

restore_run() {
  log_section "DevOS Restore"

  local target="${1:-latest}"
  local backup_dir

  if [[ "$target" == "latest" ]]; then
    backup_dir="${DEVOS_DATA}/backups/latest"
  else
    backup_dir="${DEVOS_DATA}/backups/${target}"
  fi

  local backup_tar="${backup_dir}/devos-backup.tar.gz"
  local manifest="${backup_dir}/manifest.txt"

  if [[ ! -f "$backup_tar" ]]; then
    log_error "Backup not found: $backup_tar"
    echo
    log_info "Available backups:"
    for d in "${DEVOS_DATA}/backups"/20*/; do
      if [[ -d "$d" ]] && [[ "$d" != "${DEVOS_DATA}/backups/latest/" ]]; then
        printf '  %s\n' "$(basename "$d" | sed 's|/$||')"
      fi
    done
    echo
    exit 1
  fi

  log_info "Restoring from: $(basename "$backup_dir")"

  local tempdir
  tempdir="$(_devos_mktemp "restore.XXXXXX")"
  mkdir -p "$tempdir"

  tar -xzf "$backup_tar" -C "$tempdir"

  log_info "Restoring files..."

  [[ -f "$tempdir/zshrc" ]] && { backup_file "$HOME/.zshrc"; cp "$tempdir/zshrc" "$HOME/.zshrc"; log_ok "~/.zshrc restored"; }
  [[ -f "$tempdir/zshenv" ]] && { backup_file "$HOME/.zshenv"; cp "$tempdir/zshenv" "$HOME/.zshenv"; log_ok "~/.zshenv restored"; }
  [[ -f "$tempdir/gitconfig" ]] && { backup_file "$HOME/.gitconfig"; cp "$tempdir/gitconfig" "$HOME/.gitconfig"; log_ok "~/.gitconfig restored"; }
  [[ -f "$tempdir/gitignore_global" ]] && { backup_file "$HOME/.gitignore_global"; cp "$tempdir/gitignore_global" "$HOME/.gitignore_global"; log_ok "~/.gitignore_global restored"; }

  if [[ -f "$tempdir/ssh.tar.gz" ]]; then
    log_info "Restoring SSH keys..."
    tar -xzf "$tempdir/ssh.tar.gz" -C "$HOME"
  fi

  if [[ -f "$tempdir/gnupg.tar.gz" ]]; then
    log_info "Restoring GPG keys..."
    tar -xzf "$tempdir/gnupg.tar.gz" -C "$HOME"
  fi

  [[ -f "$tempdir/starship.toml" ]] && { mkdir -p "$HOME/.config"; cp "$tempdir/starship.toml" "$HOME/.config/starship.toml"; log_ok "Starship config restored"; }

  for dir in zsh fastfetch kitty ghostty wezterm nvim; do
    if [[ -d "$tempdir/$dir" ]]; then
      mkdir -p "$HOME/.config"
      rm -rf "$HOME/.config/$dir"
      cp -r "$tempdir/$dir" "$HOME/.config/$dir"
      log_ok "~/.config/$dir restored"
    fi
  done

  [[ -f "$tempdir/vscode-settings.json" ]] && { mkdir -p "$HOME/.config/Code/User"; cp "$tempdir/vscode-settings.json" "$HOME/.config/Code/User/settings.json"; log_ok "VS Code settings restored"; }
  [[ -f "$tempdir/vscode-keybindings.json" ]] && { mkdir -p "$HOME/.config/Code/User"; cp "$tempdir/vscode-keybindings.json" "$HOME/.config/Code/User/keybindings.json"; log_ok "VS Code keybindings restored"; }
  [[ -f "$tempdir/vscode-extensions.txt" ]] && { command -v code &>/dev/null && xargs -n1 code --install-extension < "$tempdir/vscode-extensions.txt" 2>/dev/null || true; log_ok "VS Code extensions restored"; }

  [[ -f "$tempdir/cursor-settings.json" ]] && { mkdir -p "$HOME/.config/Cursor/User"; cp "$tempdir/cursor-settings.json" "$HOME/.config/Cursor/User/settings.json"; log_ok "Cursor settings restored"; }
  [[ -f "$tempdir/cursor-extensions.txt" ]] && { command -v cursor &>/dev/null && xargs -n1 cursor --install-extension < "$tempdir/cursor-extensions.txt" 2>/dev/null || true; log_ok "Cursor extensions restored"; }

  [[ -f "$tempdir/btop.conf" ]] && { mkdir -p "$HOME/.config/btop"; cp "$tempdir/btop.conf" "$HOME/.config/btop/btop.conf"; log_ok "btop config restored"; }

  if [[ -f "$tempdir/oh-my-zsh.tar.gz" ]]; then
    log_info "Restoring Oh-My-Zsh..."
    tar -xzf "$tempdir/oh-my-zsh.tar.gz" -C "$HOME"
  fi

  rm -rf "$tempdir"

  log_section "Restore Complete"
  log_info "Your configuration has been restored."
  log_warn "You may need to restart your shell for changes to take effect."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  restore_run "$@"
fi
