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

@test "BP003: detects mapfile bash 4+ builtin" {
  run "$LINTER" "$FIXTURES/bp003_mapfile.sh"
  assert_status 1
  assert_output_contains "BP003"
  assert_output_contains "[ERROR]"
  assert_output_contains "bp003_mapfile.sh:5"
}

@test "BP004: detects non-portable 'sed -i \\'\\''" {
  run "$LINTER" "$FIXTURES/bp004_sed_i.sh"
  assert_status 1
  assert_output_contains "BP004"
  assert_output_contains "[ERROR]"
  assert_output_contains "bp004_sed_i.sh:7"
}

@test "BP005: detects 'awk -v RS=' with multi-char delimiter" {
  run "$LINTER" "$FIXTURES/bp005_awk_rs.sh"
  assert_status 1
  assert_output_contains "BP005"
  assert_output_contains "[ERROR]"
  assert_output_contains "bp005_awk_rs.sh:6"
}

@test "BP006: detects GNU-only 'readlink -f' as WARN" {
  run "$LINTER" "$FIXTURES/bp006_readlink.sh"
  # Only warnings => exit 2
  assert_status 2
  assert_output_contains "BP006"
  assert_output_contains "[WARN]"
  assert_output_contains "bp006_readlink.sh:5"
}

@test "BP007: detects GNU-only 'date --iso-8601' as WARN" {
  run "$LINTER" "$FIXTURES/bp007_date_iso.sh"
  assert_status 2
  assert_output_contains "BP007"
  assert_output_contains "[WARN]"
  assert_output_contains "bp007_date_iso.sh:5"
}

@test "clean: clean fixture produces no output and exits 0" {
  run "$LINTER" "$FIXTURES/clean.sh"
  assert_status 0
  [ -z "$output" ]
}

@test "exit code: ERROR-only file returns 1" {
  run "$LINTER" "$FIXTURES/bp001_lowercase.sh"
  assert_status 1
}

@test "exit code: WARN-only file returns 2" {
  run "$LINTER" "$FIXTURES/bp006_readlink.sh"
  assert_status 2
}

@test "exit code: mixed ERROR+WARN returns 1" {
  mixdir="$BATS_TEST_TMPDIR/mixed"
  mkdir -p "$mixdir"
  cp "$FIXTURES/bp001_lowercase.sh" "$mixdir/a.sh"
  cp "$FIXTURES/bp006_readlink.sh" "$mixdir/b.sh"
  run "$LINTER" "$mixdir"
  assert_status 1
}

@test "directory mode: recurses into subdirs and scans .sh/.bash files" {
  d="$BATS_TEST_TMPDIR/recurse"
  mkdir -p "$d/sub1/sub2"
  cp "$FIXTURES/bp001_lowercase.sh" "$d/sub1/a.sh"
  cp "$FIXTURES/bp002_associative.sh" "$d/sub1/sub2/b.bash"
  run "$LINTER" "$d"
  assert_status 1
  assert_output_contains "BP001"
  assert_output_contains "BP002"
  assert_output_contains "a.sh"
  assert_output_contains "b.bash"
}

@test "directory mode: skips .git, node_modules, tests/fixtures" {
  d="$BATS_TEST_TMPDIR/skip"
  mkdir -p "$d/.git" "$d/node_modules" "$d/tests/fixtures" "$d/src"
  cp "$FIXTURES/bp001_lowercase.sh" "$d/.git/bad.sh"
  cp "$FIXTURES/bp001_lowercase.sh" "$d/node_modules/bad.sh"
  cp "$FIXTURES/bp001_lowercase.sh" "$d/tests/fixtures/bad.sh"
  cp "$FIXTURES/bp001_lowercase.sh" "$d/src/real.sh"
  run "$LINTER" "$d"
  assert_status 1
  assert_output_contains "src/real.sh"
  # None of the excluded dirs should appear in output
  [ "${output#*.git/}" = "$output" ] || { echo "found .git in: $output"; return 1; }
  [ "${output#*node_modules/}" = "$output" ] || { echo "found node_modules in: $output"; return 1; }
  [ "${output#*tests/fixtures/}" = "$output" ] || { echo "found tests/fixtures in: $output"; return 1; }
}

@test "json mode: emits valid JSON with counts for ERROR fixture" {
  run "$LINTER" "$FIXTURES/bp001_lowercase.sh" --json
  assert_status 1
  # Basic JSON shape checks.
  assert_output_contains '"files_scanned":1'
  assert_output_contains '"error_count":1'
  assert_output_contains '"warn_count":0'
  assert_output_contains '"rule_id":"BP001"'
  assert_output_contains '"severity":"ERROR"'
  # Pipe through python3 -c to validate JSON (python3 is preinstalled on macOS).
  echo "$output" | python3 -c 'import sys,json; json.loads(sys.stdin.read())'
}

@test "json mode: clean fixture emits valid JSON with zero counts" {
  run "$LINTER" "$FIXTURES/clean.sh" --json
  assert_status 0
  assert_output_contains '"files_scanned":1'
  assert_output_contains '"error_count":0'
  assert_output_contains '"warn_count":0'
  assert_output_contains '"violations":[]'
  echo "$output" | python3 -c 'import sys,json; json.loads(sys.stdin.read())'
}

@test "json mode: WARN-only fixture returns exit 2 with valid JSON" {
  run "$LINTER" "$FIXTURES/bp006_readlink.sh" --json
  assert_status 2
  assert_output_contains '"warn_count":1'
  assert_output_contains '"severity":"WARN"'
  echo "$output" | python3 -c 'import sys,json; json.loads(sys.stdin.read())'
}

@test "self-clean: the linter is clean under its own rules" {
  run "$LINTER" "$LINTER"
  assert_status 0
  [ -z "$output" ]
}
