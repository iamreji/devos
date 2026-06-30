# DevOS Architecture

## Overview

DevOS is a modular shell-based workstation bootstrap framework. It provisions a fresh Ubuntu machine into a fully configured development environment.

## Directory Structure

```
DevOS/
├── install/              # Core framework
│   ├── install.sh        # Main entry point (module orchestration)
│   ├── bootstrap.sh      # Phase runner with resume support
│   ├── common.sh         # Shared utilities, OS detection, strict mode
│   ├── logger.sh         # Structured logging with timestamps
│   ├── rollback.sh       # Transaction-style rollback registry
│   ├── packages.sh       # Package manager abstraction (apt, snap, cargo, …)
│   ├── doctor.sh         # System health check with scoring
│   ├── update.sh         # Unified toolchain updater
│   ├── backup.sh         # Dotfile and config backup
│   ├── restore.sh        # Restore from backup
│   ├── cleanup.sh        # Disk space and cache cleanup
│   └── uninstall.sh      # Reverse provisioning
├── modules/              # Provisioning modules
│   ├── shell.sh          # Zsh, Oh-My-Zsh, Starship, CLI tools
│   ├── git.sh            # Git, GitHub CLI, GPG, SSH
│   ├── docker.sh         # Docker Engine, Compose, lazydocker
│   ├── node.sh           # NVM, Node LTS, pnpm, Bun
│   ├── rust.sh           # Rust toolchain, cargo tools
│   ├── solana.sh         # Solana CLI, Anchor, Foundry
│   ├── nvidia.sh         # NVIDIA driver, CUDA, GPU health
│   ├── fonts.sh          # Nerd Fonts installer
│   ├── terminal.sh       # Kitty, Ghostty, WezTerm
│   ├── desktop.sh        # GNOME, Wayland, btop, tmux
│   ├── vscode.sh         # VS Code + extensions
│   ├── cursor.sh         # Cursor editor
│   └── nvim.sh           # Neovim + LazyVim
├── shell/                # Zsh configuration fragments
│   ├── zshrc             # Main entry (sources all others)
│   ├── exports.zsh       # Environment variables, PATH, lazy NVM/Bun
│   ├── history.zsh       # History optimization, fzf history search
│   ├── completion.zsh    # Zsh completion, kubectl/docker/gh completions
│   ├── aliases.zsh       # Navigation, eza, system aliases
│   ├── prompt.zsh        # Starship or Oh-My-Zsh prompt
│   ├── git.zsh           # Full git aliases (100+)
│   ├── docker.zsh        # Docker/docker-compose aliases
│   ├── node.zsh          # npm/yarn/pnpm/TypeScript aliases
│   ├── rust.zsh          # Cargo aliases
│   ├── solana.zsh        # Solana/Anchor aliases
│   ├── kubernetes.zsh    # kubectl aliases
│   ├── terraform.zsh     # Terraform aliases
│   ├── functions.zsh     # mkcd, extract, weather, cheat, git-clean, dev, serve
│   └── utils.zsh         # Misc utilities (psgrep, killport, bigfiles, …)
├── configs/              # Application configuration files
│   ├── starship/         # Starship prompt (Catppuccin Mocha)
│   ├── kitty/            # Kitty terminal (Catppuccin Mocha)
│   ├── ghostty/          # Ghostty terminal (Catppuccin Mocha)
│   ├── wezterm/          # WezTerm (Lua, Catppuccin Mocha)
│   ├── fastfetch/        # Fastfetch system info
│   ├── tmux/             # Tmux (Ctrl-a prefix, Catppuccin)
│   ├── btop/             # System monitor
│   ├── git/              # Global gitconfig + gitignore
│   ├── nvim/             # Neovim (LazyVim-style + LSP)
│   ├── vscode/           # VS Code settings + keybindings
│   └── cursor/           # Cursor settings
├── bin/                  # User-facing commands
│   └── devos             # DevOS command dispatcher
├── scripts/              # Maintenance scripts
├── docs/                 # Documentation
├── tests/                # Test suite
├── assets/               # Logo, images
└── .github/workflows/    # CI/CD (ShellCheck, lint, release)
```

## Core Framework

### install.sh

The main entry point. Parses CLI flags (`--all`, `--module`, `--skip`, `--dry-run`, `--force`), runs preflight checks, resolves selected modules, and executes them via `bootstrap.sh`.

### common.sh

Sourced by every script. Provides:
- `set -Eeuo pipefail` (strict mode)
- OS/architecture detection (`is_ubuntu`, `is_arch64`, `is_supported_os`)
- Color constants (`RED`, `GREEN`, `YELLOW`, etc.)
- Fallback logging functions
- Path deduplication (`dedup_path`)
- Retry logic (`retry`)
- Trap-based cleanup stack

### logger.sh

Timestamped, color-coded logging:
- `log_info`, `log_ok`, `log_warn`, `log_error`, `log_debug`
- `log_section` for visual separators
- `log_progress` for progress bars
- `log_check` for pass/warn/fail status rows
- Output to both stderr and `~/.local/share/devos/install.log`

### rollback.sh

Transaction-style rollback registry:
- `rollback_register "type:action"` — Register an undo action
- `rollback_execute` — Execute all rollback actions in reverse (LIFO)
- Supports: file restore, apt remove, directory delete, snap remove, flatpak remove, pipx uninstall, cargo uninstall
- Auto-triggers on ERR, INT, TERM if `rollback_trap_enable` is called

### packages.sh

Package manager abstraction:
- `pkg_apt_install`, `pkg_apt_install_batch` — APT with idempotency
- `pkg_snap_install`, `pkg_flatpak_install` — Snap and Flatpak
- `pkg_cargo_install`, `pkg_npm_install`, `pkg_pipx_install` — Language-specific
- `pkg_install_url` — URL-based installers
- Dry-run mode (`--dry-run`) skips all installations
- Installed package tracking in `~/.local/share/devos/installed_packages.txt`

### doctor.sh

System health checker:
- 12 categories, 40+ individual checks
- Produces a score out of 100
- Checks: OS, kernel, CPU, memory, disk, GPU, CUDA, Docker, Node, pnpm, Bun, Rust, Cargo, Solana, Anchor, Foundry, Git, GitHub CLI, SSH, GPG, shell, fonts, editors, display server
- Color-coded: green (pass), yellow (warn), red (fail)

### update.sh

Unified updater for all toolchains:
- apt upgrade, snap refresh, flatpak update
- rustup update, cargo-update
- bun upgrade, pnpm self-update
- nvm install --lts --latest-npm
- docker pull (latest images)
- solana-install update, foundryup
- gh extension upgrade

## Module System

Each module in `modules/` defines either:
- `install_modname()` — Specific install function
- `install()` — Generic install function

Modules are idempotent through `pkg_is_installed "mod:<name>"` tracking. Use `--force` to reinstall.

## Shell Configuration

Zsh config is modular — each concern lives in its own file:
- `exports.zsh` — PATH and env vars with lazy NVM/Bun loading
- `history.zsh` — Optimized history with fzf Ctrl-R
- `aliases.zsh` — Navigation, eza, system tools
- `git.zsh` — Full oh-my-zsh git aliases
- `docker.zsh` — Docker/docker-compose aliases
- `node.zsh` — npm/yarn/pnpm/TypeScript tooling
- `rust.zsh`, `solana.zsh` — Language-specific aliases

### Lazy Loading

NVM and Bun are loaded lazily — they're defined as shell functions that load the real tool on first use. This keeps shell startup under 30ms.

```zsh
nvm() { _nvm_lazy_load; nvm "$@"; }
node() { _nvm_lazy_load; node "$@"; }
```

## Rollback Strategy

Every state-changing operation registers a reverse action:
1. Install package → register `pkg:remove:<name>`
2. Modify file → backup original, register `file:restore:<path>`
3. Create directory → register `dir:remove:<path>`

On error or interrupt, actions execute in reverse order. On success, the registry is cleared.

## Design Principles

1. **Idempotent** — Every module can be re-run safely
2. **Production quality** — ShellCheck clean, strict mode, proper error handling
3. **Modular** — Each concern isolated; skip what you don't need
4. **Fast** — Lazy loading, parallel-safe package installs
5. **Reversible** — Full rollback on failure, uninstall on demand
