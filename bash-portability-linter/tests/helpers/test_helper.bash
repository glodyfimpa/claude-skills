#!/usr/bin/env bash
# Bats helpers for bash-portability-linter tests.

# Absolute path to the linter, derived from this helper's location.
_helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINTER="${_helper_dir}/../../bin/bash-portability-linter"
FIXTURES="${_helper_dir}/../fixtures"

# Assert the given substring is present in $output (set by bats `run`).
assert_output_contains() {
  needle="$1"
  if [ "${output#*$needle}" = "$output" ]; then
    echo "Expected output to contain: $needle"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
}

# Assert exit code equals expected.
assert_status() {
  expected="$1"
  if [ "$status" -ne "$expected" ]; then
    echo "Expected status $expected, got $status"
    echo "Output: $output"
    return 1
  fi
}
