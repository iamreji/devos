# Developer Guide

## Architecture Overview

DevOS is a modular shell-based workstation bootstrap framework. It provisions a fresh Ubuntu 24.04/26.04 machine into a fully configured development environment.

## Core Design

### Framework Layer (`install/`)

| File | Role |
|------|------|
| `common.sh` | Shared utilities, strict mode, OS detection, color constants |
| `logger.sh` | Structured logging with timestamps and log file output |
| `rollback.sh` | Transaction-style rollback registry |
| `packages.sh` | Package manager abstraction (apt, snap, cargo, pipx, npm) |
| `install.sh` | Main entry point, CLI parsing, module orchestration |
| `bootstrap.sh` | Phase runner with resume-on-failure support |

### Module Layer (`modules/`)

Each module is a self-contained installer for a category of tools:

| Module | What it installs |
|--------|-----------------|
| `shell.sh` | Zsh, Oh-My-Zsh, Starship, fzf, zoxide, eza, bat, fd, rg |
| `git.sh` | Git config, GitHub CLI, GPG signing, SSH keygen |
| `docker.sh` | Docker Engine, Compose, lazydocker |
| `node.sh` | NVM, Node LTS, pnpm, Bun |
| `rust.sh` | rustup, cargo tools |
| `solana.sh` | Solana CLI, Anchor, Foundry |
| `nvidia.sh` | NVIDIA driver, CUDA |
| `fonts.sh` | Nerd Fonts |
| `terminal.sh` | Kitty, Ghostty, WezTerm |
| `desktop.sh` | GNOME, Wayland, btop, tmux |
| `vscode.sh` | VS Code + extensions |
| `cursor.sh` | Cursor editor |
| `nvim.sh` | Neovim + LazyVim |

### Config Layer (`configs/`)

Pre-built configuration files deployed by modules:

- **starship** — Prompt theme (Catppuccin Mocha)
- **kitty/ghostty/wezterm** — Terminal configs
- **nvim** — LazyVim-style Neovim config with LSP
- **vscode/cursor** — Editor settings and keybindings
- **git** — Global gitconfig with delta diffs
- **tmux** — Terminal multiplexer with Catppuccin theme
- **btop/fastfetch** — System monitor and info display

### Shell Layer (`shell/`)

Modular Zsh configuration loaded by `~/.config/zsh/zshrc`:

- `exports.zsh` — PATH, environment variables, lazy NVM/Bun
- `history.zsh` — History optimization, fzf history
- `completion.zsh` — Zsh completion, kubectl/docker/gh
- `aliases.zsh` — Navigation, eza, system aliases
- `prompt.zsh` — Starship or Oh-My-Zsh prompt
- `git.zsh`, `docker.zsh`, `node.zsh`, `rust.zsh`, `solana.zsh` — Tool aliases
- `kubernetes.zsh`, `terraform.zsh` — Infrastructure aliases
- `functions.zsh` — Utility functions (mkcd, extract, dev, serve)
- `utils.zsh` — Helpers (killport, bigfiles, psgrep)

## How It Works

### Installation Flow

```
devos install --all
  → install.sh parses flags
  → Preflight checks (OS, sudo, memory)
  → Resolves module selection
  → For each module:
      → bootstrap.sh runs module script
      → Module installs packages via packages.sh
      → Configs deployed from configs/
      → Rollback actions registered
  → Summary printed
```

### Rollback

Every state-changing operation registers a reverse action:
- Package install → `rollback_register "pkg:remove:name"`
- File modify → backup original, `rollback_register "file:restore:path"`

On ERR/INT/TERM, rollback executes all actions in reverse order.

### Idempotency

Modules track installed state in `~/.local/share/devos/installed_packages.txt`:
- `pkg_mark_installed "mod:shell"` — Mark module as done
- `pkg_is_installed "mod:shell"` — Check if already installed
- Use `--force` to reinstall

## Adding a New Module

```bash
# modules/mytool.sh

install_mytool() {
  log_section "My Tool"

  pkg_apt_install mytool

  # Deploy config
  cp "${DEVOS_ROOT}/configs/mytool/config" "$HOME/.config/mytool/config"

  pkg_mark_installed "mod:mytool"
  log_section "My Tool Complete"
}
```

Then register in `install/install.sh`:
```bash
_DEVOS_MODULES+=("mytool:My Tool:")
```

## Testing

```bash
# Syntax check all scripts
bash -n install/*.sh modules/*.sh

# Dry run
./install/install.sh --dry-run --all

# Single module
./install/install.sh --module shell

# Doctor check
bash install/doctor.sh
```
