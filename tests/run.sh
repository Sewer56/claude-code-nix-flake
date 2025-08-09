#!/usr/bin/env bash

set -e

# Fix current directory to the script's location
cd "$(dirname "${BASH_SOURCE[0]}")"
echo "Running Claude Code NMT tests..."

# Run tests through nix-shell as NMT expects
nix-shell default.nix