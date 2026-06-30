# FAQ

## Why not use Ansible / Nix / dotbot?

These are great tools for complex fleet management. DevOS is designed for individual developers who want one shell script that works on a fresh Ubuntu machine with no dependencies other than curl. If you need multi-machine orchestration, Ansible or Nix are excellent choices.

## Can I use this on non-Ubuntu systems?

DevOS targets Ubuntu 24.04/26.04 (x86_64). It uses `apt` as the primary package manager. Some modules may work on Debian, but it's not tested. For other distros, consider Omakub (macOS), Omarchy (Arch), or nix-home-manager.

## Does it work on WSL?

Some modules do. The terminal, GNOME, and desktop modules are skipped automatically if not in a graphical session. Shell, Git, Docker, Node, Rust, and Solana modules should work. NVIDIA passthrough to WSL is not supported.

## How do I uninstall completely?

```bash
devos uninstall --purge
```

This removes DevOS-installed packages and deletes the DevOS data directory. Some config files may remain in `~/.config/` — these are standard app configs that you may want to keep.

## Will it break my existing setup?

DevOS backs up any file it modifies with a `.devos-bak` extension. You can restore from backup with `devos restore`. All installations are idempotent — running twice won't duplicate anything.

## How do I skip specific modules?

```bash
devos install --all --skip nvidia,gnome      # Skip NVIDIA and GNOME
devos install --module shell,git,node,rust    # Only these modules
```

## How do I add custom configuration?

Create `~/.config/devos/local.sh` — it runs after all modules complete. For Zsh, add files to `~/.config/zsh/` and source them. For VS Code, install extensions manually.

## Does it support other shells?

DevOS configures Zsh. Bash users can still run `devos` commands but won't get the shell aliases and plugins.

## How is this different from dotfiles?

Dotfiles repositories store your personal config files. DevOS generates and installs them programmatically from a modular system. It also installs the tools themselves (Docker, Node, Rust, Solana, etc.), not just their configs.

## Can I contribute?

Yes! See [CONTRIBUTING.md](CONTRIBUTING.md). All code is ShellCheck clean, follows strict mode, and uses the module system pattern.
