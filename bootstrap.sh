#!/usr/bin/env bash
# DevOS bootstrap convenience wrapper
cd "$(dirname "$0")" || exit 1
exec bash install/bootstrap.sh "$@"
