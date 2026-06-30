# Contributing Guide

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone git@github.com:you/devos.git`
3. Create a branch: `git checkout -b feature/my-feature`

## Code Style

### Shell Scripts

All shell scripts must:

- Start with `#!/usr/bin/env bash`
- Use `set -Eeuo pipefail` (via `source install/common.sh`)
- Pass ShellCheck with zero warnings
- Be executable (`chmod +x`)
- Use the DevOS logging functions (`log_info`, `log_ok`, `log_warn`, `log_error`)

### ShellCheck

```bash
# Run ShellCheck on all scripts
shellcheck **/*.sh
```

CI will fail if ShellCheck reports warnings.

### Module Structure

New modules go in `modules/name.sh` and must define:

```bash
install_modname() {
  log_section "Module Name"
  # Install logic here
  pkg_mark_installed "mod:modname"
  log_section "Module Name Complete"
}
```

Modules should be idempotent — check if already installed before acting.

### Config Files

Configs go in `configs/appname/`. They are deployed by the corresponding module.

## Pull Request Process

1. Write clear commit messages
2. Add your feature to `CHANGELOG.md`
3. Run `shellcheck **/*.sh` and fix any warnings
4. Open a PR with a description of what you changed and why

## Adding a New Module

1. Create `modules/yourmodule.sh`
2. Define `install_yourmodule()` function
3. Register in the `_register_all_modules()` function in `install/install.sh`
4. Add corresponding config files in `configs/` if needed
5. Add documentation in `docs/`

## Testing

```bash
# Dry run (no changes)
./install/install.sh --dry-run --all

# Install a single module
./install/install.sh --module yourmodule

# Run doctor after changes
./install/doctor.sh
```

## Project Structure Standards

- Framework scripts → `install/`
- Provisioning modules → `modules/`
- Shell config fragments → `shell/`
- Application configs → `configs/appname/`
- User-facing tools → `bin/`
- Helper scripts → `scripts/`
- Documentation → `docs/`
