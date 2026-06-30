# Installation Guide

## Quick Install (One Command)

```bash
curl -fsSL https://raw.githubusercontent.com/<username>/devos/main/install/install.sh -o /tmp/install.sh
bash /tmp/install.sh --all
```

Or pipe directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<username>/devos/main/install/install.sh) -- --all
```

Note: the extra `-- --all` passes flags through when piping.

## Prerequisites

- **Ubuntu 24.04 or 26.04** (x86_64)
- Sudo access
- Internet connection
- ~10 GB free disk space (full install)

## Fresh Ubuntu Install

1. Install Ubuntu 24.04 or 26.04
2. Open Terminal
3. Run `sudo apt update && sudo apt install -y curl`
4. Run `bash <(curl -fsSL .../install.sh) -- --all`
5. Restart when prompted (for NVIDIA drivers, Docker group)
6. Open Kitty/Ghostty/WezTerm for the full experience

## Existing System

DevOS is designed to be safe on existing systems:

- Config files are backed up before modification (`.devos-bak` extension)
- All module installations are idempotent
- Use `--dry-run` to preview changes first
- Use `devos doctor` to check current state

## Module-by-Module

Install modules one at a time if you prefer:

```bash
devos install --module shell
devos install --module git
devos install --module node
devos install --module rust
devos install --module docker
devos install --module solana
```

## Post-Install

1. **Restart shell**: `exec zsh` or open a new terminal
2. **Docker**: Log out and back in for docker group membership
3. **NVIDIA**: Reboot if drivers were installed
4. **GitHub**: Run `gh auth login` if not done during install
5. **VS Code**: Open once to complete extension setup

## Uninstall

```bash
devos uninstall           # Remove DevOS-installed packages, restore configs
devos uninstall --purge   # Also delete DevOS data directory
```

## Updating

```bash
devos update  # Updates all installed tools
```
