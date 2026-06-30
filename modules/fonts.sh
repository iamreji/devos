#!/usr/bin/env bash
# fonts.sh — Install Nerd Fonts (JetBrains Mono, Fira Code, Cascadia Code)
if [[ -z "${DEVOS_COMMON_LOADED:-}" ]]; then
  DEVOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "${DEVOS_ROOT}/install/common.sh"
fi
if [[ -z "${DEVOS_LOGGER_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/logger.sh"; fi
if [[ -z "${DEVOS_PACKAGES_LOADED:-}" ]]; then source "${DEVOS_ROOT}/install/packages.sh"; fi

install_fonts() {
  log_section "Nerd Fonts"

  local fonts_dir="$HOME/.local/share/fonts"
  mkdir -p "$fonts_dir"

  # Nerd Fonts to install
  local fonts=(
    "JetBrainsMono"
    "FiraCode"
    "CascadiaCode"
    "Ubuntu"
  )

  local font_installed=0
  local nf_version
  nf_version="$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d'"' -f4)"

  for font in "${fonts[@]}"; do
    if fc-list 2>/dev/null | grep -qi "${font}.*Nerd"; then
      log_info "${font} Nerd Font already installed"
      font_installed=1
      continue
    fi

    log_info "Downloading ${font} Nerd Font (${nf_version})..."
    local zip_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_version}/${font}.zip"
    local tmp_zip="$(_devos_mktemp "${font}.zip")"

    if curl -fsSL "$zip_url" -o "$tmp_zip"; then
      unzip -qo "$tmp_zip" -d "$fonts_dir" 2>/dev/null
      rm -f "$tmp_zip"
      font_installed=1
      log_ok "${font} Nerd Font installed"
    else
      log_warn "Could not download ${font} Nerd Font"
    fi
  done

  # Refresh font cache
  if [[ $font_installed -eq 1 ]]; then
    if command -v fc-cache &>/dev/null; then
      fc-cache -fv > /dev/null 2>&1
      log_ok "Font cache refreshed"
    fi
  fi

  pkg_mark_installed "mod:fonts"
  log_section "Fonts Complete"
}
