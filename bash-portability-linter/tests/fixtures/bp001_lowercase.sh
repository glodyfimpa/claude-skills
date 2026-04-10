#!/usr/bin/env bash
# BP001 fixture: bash 4+ case modification.
set -euo pipefail

name="Glody"
lower="${name,,}"
echo "$lower"
