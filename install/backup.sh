#!/usr/bin/env bash
# backup.sh — DevOS backup: saves configs, dotfiles, and tool state
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then
  source "${DEVOS_ROOT}/install/logger.sh"
fi

BACKUP_DIR="${DEVOS_DATA}/backups/$(date +%Y-%m-%d-%H%M%S)"
BACKUP_TAR="${BACKUP_DIR}/devos-backup.tar.gz"
BACKUP_MANIFEST="${BACKUP_DIR}/manifest.txt"

mkdir_safe "$BACKUP_DIR"

backup_run() {
  log_section "DevOS Backup"
  log_info "Backing up to: ${BACKUP_DIR}"

  local tempdir
  tempdir="$(_devos_mktemp "backup.XXXXXX")"
  mkdir -p "$tempdir"

  # Zsh configs
  if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$tempdir/zshrc"
    echo "zshrc" >> "$BACKUP_MANIFEST"
  fi
  if [[ -f "$HOME/.zshenv" ]]; then
    cp "$HOME/.zshenv" "$tempdir/zshenv"
    echo "zshenv" >> "$BACKUP_MANIFEST"
  fi
  if [[ -d "$HOME/.config/zsh" ]]; then
    cp -r "$HOME/.config/zsh" "$tempdir/zsh"
    echo "zsh/" >> "$BACKUP_MANIFEST"
  fi
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    tar -czf "$tempdir/oh-my-zsh.tar.gz" -C "$HOME" .oh-my-zsh
    echo "oh-my-zsh.tar.gz" >> "$BACKUP_MANIFEST"
  fi

  # Git
  if [[ -f "$HOME/.gitconfig" ]]; then
    cp "$HOME/.gitconfig" "$tempdir/gitconfig"
    echo "gitconfig" >> "$BACKUP_MANIFEST"
  fi
  if [[ -f "$HOME/.gitignore_global" ]]; then
    cp "$HOME/.gitignore_global" "$tempdir/gitignore_global"
    echo "gitignore_global" >> "$BACKUP_MANIFEST"
  fi

  # SSH
  if [[ -d "$HOME/.ssh" ]]; then
    tar -czf "$tempdir/ssh.tar.gz" -C "$HOME" .ssh
    echo "ssh.tar.gz" >> "$BACKUP_MANIFEST"
  fi

  # GPG
  if [[ -d "$HOME/.gnupg" ]]; then
    tar -czf "$tempdir/gnupg.tar.gz" -C "$HOME" .gnupg
    echo "gnupg.tar.gz" >> "$BACKUP_MANIFEST"
  fi

  # Starship
  if [[ -f "$HOME/.config/starship.toml" ]]; then
    cp "$HOME/.config/starship.toml" "$tempdir/starship.toml"
    echo "starship.toml" >> "$BACKUP_MANIFEST"
  fi

  # Fastfetch
  if [[ -d "$HOME/.config/fastfetch" ]]; then
    cp -r "$HOME/.config/fastfetch" "$tempdir/fastfetch"
    echo "fastfetch/" >> "$BACKUP_MANIFEST"
  fi

  # Kitty
  if [[ -d "$HOME/.config/kitty" ]]; then
    cp -r "$HOME/.config/kitty" "$tempdir/kitty"
    echo "kitty/" >> "$BACKUP_MANIFEST"
  fi

  # Ghostty
  if [[ -d "$HOME/.config/ghostty" ]]; then
    cp -r "$HOME/.config/ghostty" "$tempdir/ghostty"
    echo "ghostty/" >> "$BACKUP_MANIFEST"
  fi

  # WezTerm
  if [[ -d "$HOME/.config/wezterm" ]]; then
    cp -r "$HOME/.config/wezterm" "$tempdir/wezterm"
    echo "wezterm/" >> "$BACKUP_MANIFEST"
  fi

  # Neovim
  if [[ -d "$HOME/.config/nvim" ]]; then
    cp -r "$HOME/.config/nvim" "$tempdir/nvim"
    echo "nvim/" >> "$BACKUP_MANIFEST"
  fi

  # VS Code
  if [[ -f "$HOME/.config/Code/User/settings.json" ]]; then
    cp "$HOME/.config/Code/User/settings.json" "$tempdir/vscode-settings.json"
    echo "vscode-settings.json" >> "$BACKUP_MANIFEST"
  fi
  if [[ -f "$HOME/.config/Code/User/keybindings.json" ]]; then
    cp "$HOME/.config/Code/User/keybindings.json" "$tempdir/vscode-keybindings.json"
    echo "vscode-keybindings.json" >> "$BACKUP_MANIFEST"
  fi
  if command -v code &>/dev/null; then
    code --list-extensions 2>/dev/null > "$tempdir/vscode-extensions.txt"
    echo "vscode-extensions.txt" >> "$BACKUP_MANIFEST"
  fi

  # Cursor
  if [[ -f "$HOME/.config/Cursor/User/settings.json" ]]; then
    cp "$HOME/.config/Cursor/User/settings.json" "$tempdir/cursor-settings.json"
    echo "cursor-settings.json" >> "$BACKUP_MANIFEST"
  fi

  # Export VS Code / Cursor extensions
  if command -v cursor &>/dev/null; then
    cursor --list-extensions 2>/dev/null > "$tempdir/cursor-extensions.txt" || true
    echo "cursor-extensions.txt" >> "$BACKUP_MANIFEST"
  fi

  # Fonts list
  if command -v fc-list &>/dev/null; then
    fc-list 2>/dev/null | grep -i nerd > "$tempdir/nerd-fonts-list.txt" 2>/dev/null || true
    echo "nerd-fonts-list.txt" >> "$BACKUP_MANIFEST"
  fi

  # btop
  if [[ -f "$HOME/.config/btop/btop.conf" ]]; then
    cp "$HOME/.config/btop/btop.conf" "$tempdir/btop.conf"
    echo "btop.conf" >> "$BACKUP_MANIFEST"
  fi

  # Package list (for reference)
  if [[ -r "${DEVOS_DATA}/installed_packages.txt" ]]; then
    cp "${DEVOS_DATA}/installed_packages.txt" "$tempdir/installed_packages.txt"
    echo "installed_packages.txt" >> "$BACKUP_MANIFEST"
  fi

  # Create the archive
  log_info "Creating backup archive..."
  tar -czf "$BACKUP_TAR" -C "$tempdir" .
  rm -rf "$tempdir"

  # Symlink to "latest"
  ln -sfn "$BACKUP_DIR" "${DEVOS_DATA}/backups/latest"

  local size
  size="$(du -h "$BACKUP_TAR" 2>/dev/null | cut -f1)"
  log_ok "Backup created: ${BACKUP_TAR} (${size})"

  # List available backups
  echo
  log_info "Available backups:"
  for d in "${DEVOS_DATA}/backups"/20*/; do
    if [[ -d "$d" ]] && [[ "$d" != "${DEVOS_DATA}/backups/latest/" ]]; then
      local ts
      ts="$(basename "$d" | sed 's|/$||')"
      local sz
      sz="$(du -h "$d/"*.tar.gz 2>/dev/null | cut -f1)"
      printf '  %s — %s\n' "$ts" "${sz:-unknown}"
    fi
  done
  echo
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  backup_run
fi
