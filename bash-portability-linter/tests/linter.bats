#!/usr/bin/env bats
# Tests for bash-portability-linter.

load helpers/test_helper

@test "scaffold: linter is executable and prints usage with no args" {
  run "$LINTER"
  assert_status 64
}

@test "scaffold: linter runs on clean fixture without crashing" {
  run "$LINTER" "$FIXTURES/clean.sh"
  # Clean fixture should eventually be exit 0 when all rules exist.
  # At scaffold stage it already should be 0 since no rules fire.
  assert_status 0
}

@test "BP001: detects \${var,,} bash 4+ lowercase modification" {
  run "$LINTER" "$FIXTURES/bp001_lowercase.sh"
  assert_status 1
  assert_output_contains "BP001"
  assert_output_contains "[ERROR]"
  assert_output_contains "bp001_lowercase.sh:6"
}

@test "BP002: detects 'declare -A' bash 4+ associative array" {
  run "$LINTER" "$FIXTURES/bp002_associative.sh"
  assert_status 1
  assert_output_contains "BP002"
  assert_output_contains "[ERROR]"
  assert_output_contains "bp002_associative.sh:5"
}
