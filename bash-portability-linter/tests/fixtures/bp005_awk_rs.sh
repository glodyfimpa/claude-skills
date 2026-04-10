#!/usr/bin/env bash
# BP005 fixture: awk -v RS with multi-char delimiter.
set -euo pipefail

input="foo@@bar@@baz"
echo "$input" | awk -v RS='@@' '{print}'
