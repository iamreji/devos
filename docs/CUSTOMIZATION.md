# Customization Guide

## Skip Modules

Use `--skip` to exclude modules you don't need:

```bash
devos install --all --skip nvidia        # Everything except NVIDIA
devos install --all --skip nvim,gnome    # Multiple skips
```

## Install Specific Modules

```bash
devos install --module shell,git,node,rust,solana  # Just the essentials
```

## Local Hooks

Create `~/.config/devos/local.sh` — it's sourced at the end of a full installation. Use it for:

```bash
#!/usr/bin/env bash
# DevOS local hook — runs after all modules

# Install additional apt packages
sudo apt-get install -y my-extra-package

# Set custom git config
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Install VS Code extensions
code --install-extension some-extension

# Run custom scripts
bash ~/my-setup-script.sh
```

## Custom Zsh

DevOS writes a minimal `~/.zshrc` that sources `~/.config/zsh/zshrc`. To customize:

1. Add aliases to `~/.config/zsh/aliases.zsh`
2. Add functions to `~/.config/zsh/functions.zsh`
3. Add env vars to `~/.config/zsh/exports.zsh`

Or create `~/.config/zsh/local.zsh` and source it:

```bash
# In ~/.config/zsh/zshrc
[[ -f ~/.config/zsh/local.zsh ]] && source ~/.config/zsh/local.zsh
```

## Custom Starship

Edit `~/.config/starship.toml`. See the [Starship docs](https://starship.rs/config/) for all options.

## Custom Terminal

- Kitty: `~/.config/kitty/kitty.conf`
- Ghostty: `~/.config/ghostty/config`
- WezTerm: `~/.config/wezterm/wezterm.lua`

## Custom Neovim

DevOS uses LazyVim-style config. Add plugins in `~/.config/nvim/lua/plugins/`.

## Reinstall

Use `--force` to reinstall even if already installed:

```bash
devos install --force --module shell
```

## Dry Run

Preview without installing:

```bash
devos install --dry-run --all
```
