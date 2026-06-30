# DevOS

**Production-grade developer workstation bootstrap framework for Ubuntu.**

One command provisions a fresh Ubuntu 24.04/26.04 machine into a fully configured development workstation — shell, tools, editors, fonts, terminal, GPU drivers, and more.

```bash
curl -fsSL https://raw.githubusercontent.com/<username>/devos/main/install/install.sh | bash
```

## What You Get

- **⚡ Fast shell** — Zsh with lazy-loaded NVM/Bun, Oh-My-Zsh, or Starship prompt. <30ms startup.
- **🎨 Beautiful prompt** — Starship with Git, Node, Rust, Docker, Kubernetes, Cloud modules.
- **🐳 Docker** — Engine, Compose, lazydocker, rich aliases.
- **🌿 Git** — Full oh-my-zsh git aliases, GPG signing, delta diffs, GitHub CLI.
- **🟢 Node** — NVM, latest LTS, pnpm, Bun. npm/yarn/pnpm aliases.
- **🦀 Rust** — rustup, cargo-binstall, cargo-edit, cargo-watch, cargo-audit.
- **⛓️ Solana** — Solana CLI, Anchor, Foundry (forge, cast, anvil).
- **🖥️ NVIDIA** — Driver verification, CUDA toolkit, GPU health report.
- **🔍 Modern CLI** — fzf, zoxide, eza, bat, fd, ripgrep, btop, fastfetch.
- **📝 Editors** — VS Code, Cursor, Neovim with LazyVim-style config, LSP.
- **🔤 Fonts** — JetBrains Mono, Fira Code, Cascadia Code, Ubuntu (Nerd Fonts).
- **🖼️ Desktop** — GNOME dark theme, Wayland utilities, keyboard shortcuts.

## Quick Start

```bash
# Full workstation setup
devos install --all

# Preview what will be installed
devos install --dry-run --all

# Install specific modules
devos install --module shell,git,node,rust

# Skip certain modules
devos install --all --skip nvidia
```

## Commands

| Command | Description |
|---------|-------------|
| `devos install --all` | Full workstation provisioning |
| `devos doctor` | System health check with score |
| `devos update` | Update all installed tools |
| `devos backup` | Backup dotfiles and configs |
| `devos restore [date]` | Restore from backup |
| `devos cleanup` | Free disk space, prune caches |
| `devos uninstall` | Remove DevOS-installed packages |
| `devos info` | System overview |

## Modules

| Module | Description |
|--------|-------------|
| `shell` | Zsh, Oh-My-Zsh, Starship, CLI tools |
| `git` | Git config, GitHub CLI, GPG, SSH |
| `docker` | Docker Engine, Compose, lazydocker |
| `node` | NVM, Node.js LTS, pnpm, Bun |
| `rust` | Rust toolchain, cargo tools |
| `solana` | Solana CLI, Anchor, Foundry |
| `nvidia` | NVIDIA driver, CUDA toolkit |
| `fonts` | Nerd Fonts (4 families) |
| `terminal` | Kitty, Ghostty, WezTerm |
| `desktop` | GNOME tweaks, Wayland, btop, tmux |
| `vscode` | VS Code + extensions |
| `cursor` | Cursor editor |
| `nvim` | Neovim + LazyVim-style config |

## Requirements

- Ubuntu 24.04 or 26.04 (x86_64)
- Sudo access
- Internet connection

## Architecture

DevOS uses a modular architecture:

```
install/         — Core framework (common.sh, logger.sh, rollback.sh, packages.sh)
modules/         — Install modules (shell.sh, node.sh, rust.sh, …)
shell/           — Zsh configuration modules (aliases, functions, exports)
configs/         — Application configs (starship, kitty, nvim, vscode, …)
bin/             — User-facing CLI tools
docs/            — Documentation
```

Each module is idempotent — safe to run repeatedly. Rollback support lets you unwind changes on failure.

## Customization

Skip modules with `--skip`. Create `~/.config/devos/local.sh` to add custom post-install hooks. See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md).

## License

MIT — See [LICENSE](LICENSE)
