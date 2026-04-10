#!/usr/bin/env bash
# BP006 fixture: readlink -f is GNU-only.
set -euo pipefail

here=$(readlink -f "$0")
echo "$here"
