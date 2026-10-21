---
name: bash-portability-linter
description: >
  Lints bash scripts for constructs that break between macOS (BSD userland, bash 3.2) and
  Linux (GNU userland): `sed -i` without suffix, `date -d`, `readlink -f`, `grep -P`,
  `stat -c`, `mapfile`, associative arrays, `${var,,}`. Reports each non-portable line with
  the portable alternative. Use when writing or reviewing a bash script that must run on
  both macOS and Linux, or when a script works on the Mac and fails on a VPS (or the reverse).
---

# bash-portability-linter

Run `bin/lint-portability <script.sh>`: one line per finding, `file:line: construct -> portable alternative`.
