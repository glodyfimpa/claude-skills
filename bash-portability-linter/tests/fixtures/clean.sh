#!/usr/bin/env bash
# Portable bash 3.2 script. Should trigger zero rules.
set -euo pipefail

name="Glody"
upper=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')
echo "hello $upper"

# Integer-indexed array (portable).
items=(one two three)
for item in "${items[@]}"; do
  echo "$item"
done

# Portable file read.
while IFS= read -r line; do
  echo "$line"
done < /dev/null

# Portable sed with explicit backup extension.
tmpf=$(mktemp)
echo "foo" > "$tmpf"
sed -i.bak 's/foo/bar/' "$tmpf" && rm -f "${tmpf}.bak"
rm -f "$tmpf"

# Portable date.
date -u '+%Y-%m-%dT%H:%M:%SZ'
