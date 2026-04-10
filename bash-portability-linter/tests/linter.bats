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
