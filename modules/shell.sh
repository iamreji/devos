#!/usr/bin/env bash
# shell.sh — Install Zsh, Oh-My-Zsh, Starship, and all shell tooling
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi
if [[ -z "${DEVOS_ROLLBACK_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/rollback.sh"; fi

install_shell() {
  log_section "Shell & CLI Tools"

  pkg_apt_update

  # Zsh + core shell packages
  pkg_apt_install_batch zsh curl wget git

  # Modern CLI replacements
  pkg_apt_install_batch eza fd-find ripgrep fzf zoxide bat tree jq

  # bat symlink (Ubuntu names it batcat)
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi

  # fd symlink
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi

  # Starship prompt
  if ! command -v starship &>/dev/null; then
    log_info "Installing Starship prompt..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
    log_ok "Starship installed"
  else
    log_info "Starship already installed"
  fi

  # Oh-My-Zsh
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh-My-Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    rollback_register "dir:remove:$HOME/.oh-my-zsh"
    log_ok "Oh-My-Zsh installed"
  else
    log_info "Oh-My-Zsh already installed"
  fi

  # zsh-syntax-highlighting
  if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
    log_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    log_ok "zsh-syntax-highlighting installed"
  fi

  # zsh-autosuggestions
  if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
    log_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git \
      "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    log_ok "zsh-autosuggestions installed"
  fi

  # Deploy shell configs to ~/.config/zsh/
  log_info "Deploying shell configuration..."
  local src_dir="${DEVOS_ROOT}/shell"
  local dst_dir="$HOME/.config/zsh"
  mkdir -p "$dst_dir"

  for f in zshrc exports.zsh history.zsh completion.zsh aliases.zsh prompt.zsh \
           functions.zsh utils.zsh git.zsh docker.zsh node.zsh rust.zsh \
           solana.zsh kubernetes.zsh terraform.zsh; do
    if [[ -f "${src_dir}/${f}" ]]; then
      cp "${src_dir}/${f}" "${dst_dir}/${f}"
    fi
  done

  # Create ~/.zshrc stub that sources DevOS config
  backup_file "$HOME/.zshrc"
  cat > "$HOME/.zshrc" <<'ZSHSTUB'
# Managed by DevOS — sources modular Zsh config
export DEVOS_ZSH_DIR="${DEVOS_ZSH_DIR:-$HOME/.config/zsh}"
[[ -f "$DEVOS_ZSH_DIR/zshrc" ]] && source "$DEVOS_ZSH_DIR/zshrc"
ZSHSTUB

  # Starship config
  if [[ ! -f "$HOME/.config/starship.toml" ]] && [[ -f "${DEVOS_ROOT}/configs/starship/starship.toml" ]]; then
    mkdir -p "$HOME/.config"
    cp "${DEVOS_ROOT}/configs/starship/starship.toml" "$HOME/.config/starship.toml"
    log_ok "Starship config deployed"
  fi

  # Set zsh as default shell
  if [[ "$SHELL" != *"zsh"* ]]; then
    log_info "Setting zsh as default shell..."
    chsh -s "$(command -v zsh)" || log_warn "Could not change default shell (try: chsh -s \$(which zsh))"
  fi

  pkg_mark_installed "mod:shell"
  log_section "Shell Setup Complete"
  log_info "Restart your terminal or run 'exec zsh' to activate the new shell"
}
