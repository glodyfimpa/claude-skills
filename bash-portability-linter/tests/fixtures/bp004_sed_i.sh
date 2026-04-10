#!/usr/bin/env bash
# BP004 fixture: non-portable sed -i.
set -euo pipefail

tmp=$(mktemp)
echo "hello" > "$tmp"
sed -i '' 's/hello/world/' "$tmp"
rm -f "$tmp"
