#!/usr/bin/env bash
# BP007 fixture: date --iso-8601 is GNU-only.
set -euo pipefail

now=$(date --iso-8601=seconds)
echo "$now"
