#!/usr/bin/env bash
# BP003 fixture: bash 4+ mapfile/readarray.
set -euo pipefail

mapfile -t lines < /etc/hosts
echo "${#lines[@]} lines"
