#!/usr/bin/env bash
# BP002 fixture: bash 4+ associative array.
set -euo pipefail

declare -A colors
colors[red]="#ff0000"
echo "${colors[red]}"
