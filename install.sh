#!/usr/bin/env bash
# DevOS — one-command workstation bootstrap
# Convenience entry point pointing to the installer
cd "$(dirname "$0")" || exit 1
exec bash install/install.sh "$@"
