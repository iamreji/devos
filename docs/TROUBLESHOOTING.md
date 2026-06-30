# Troubleshooting

## NVIDIA Driver Issues

**Problem**: `nvidia-smi` not found after driver installation.

**Solution**: Reboot the system. NVIDIA kernel modules load on boot.

**Problem**: "NVIDIA kernel module missing" on Secure Boot systems.

**Solution**: During boot, select "Enroll MOK" → "Continue" → "Yes" → enter the password you set during driver install. Then reboot again.

**Problem**: CUDA not working after driver install.

**Solution**: Ensure CUDA toolkit is installed (`nvidia-smi` shows "CUDA Version: 12.x"). Check PATH includes `/usr/local/cuda/bin`.

## Docker Permission Denied

**Problem**: `docker ps` fails with "permission denied".

**Solution**: Log out and back in, or run `newgrp docker`. The `docker` group membership requires a new session.

**Alternative**: `sudo usermod -aG docker $USER && exec su -l $USER`

## PATH Issues

**Problem**: Commands not found after install (e.g., `solana`, `cargo`).

**Solution**: Restart your shell (`exec zsh`) or source your profile (`source ~/.zshrc`). PATH changes only take effect in new shell sessions.

**Problem**: Duplicate PATH entries.

**Solution**: DevOS uses `typeset -U path PATH` at the end of `~/.config/zsh/zshrc` to deduplicate. If issues persist, check `~/.zshenv` for conflicting PATH exports.

## Shell Startup Slow

**Problem**: Zsh starts slowly (>200ms).

**Solution**: DevOS lazy-loads NVM, Bun, and Oh-My-Zsh. If startup is still slow:
1. Profile with `zsh -xv` to find the slow operation
2. Check if `.oh-my-zsh` is being loaded eagerly
3. Remove unused modules from `~/.config/zsh/zshrc`

## Fonts Not Rendering

**Problem**: Nerd Font icons show as boxes or question marks.

**Solution**: Set your terminal to use a Nerd Font: "JetBrainsMono Nerd Font Mono" in Kitty/Ghostty/WezTerm/VS Code.

## Kitty/Wayland Issues

**Problem**: Kitty doesn't start on Wayland.

**Solution**: Install `libgl1-mesa-glx` and `libegl1-mesa`. Try launching with `kitty --config NONE` to check if it's a config issue.

## CUDA Version Mismatch

**Problem**: `nvcc` shows different version than `nvidia-smi`.

**Solution**: `nvcc` shows CUDA toolkit version, `nvidia-smi` shows the maximum CUDA version supported by the driver. They can differ — the driver supports up to the version it reports.
