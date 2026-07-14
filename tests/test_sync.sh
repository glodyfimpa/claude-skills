#!/usr/bin/env bash
set -euo pipefail

# ─── Test framework (minimal) ─────────────────────────────────────────
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=()

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

assert_eq() {
    local expected="$1" actual="$2" msg="${3:-}"
    if [ "$expected" = "$actual" ]; then
        return 0
    fi
    echo -e "  ${RED}FAIL${RESET}: $msg" >&2
    echo "    expected: '$expected'" >&2
    echo "    actual:   '$actual'" >&2
    return 1
}

assert_file_exists() {
    local path="$1" msg="${2:-file should exist: $path}"
    if [ -f "$path" ]; then return 0; fi
    echo -e "  ${RED}FAIL${RESET}: $msg (not found: $path)" >&2
    return 1
}

assert_dir_exists() {
    local path="$1" msg="${2:-dir should exist: $path}"
    if [ -d "$path" ]; then return 0; fi
    echo -e "  ${RED}FAIL${RESET}: $msg (not found: $path)" >&2
    return 1
}

assert_not_exists() {
    local path="$1" msg="${2:-should not exist: $path}"
    if [ ! -e "$path" ]; then return 0; fi
    echo -e "  ${RED}FAIL${RESET}: $msg (exists: $path)" >&2
    return 1
}

run_test() {
    local name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    if "$name"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}✓${RESET} $name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("$name")
        echo -e "  ${RED}✗${RESET} $name"
    fi
}

# ─── Setup / Teardown ─────────────────────────────────────────────────
# Save repo root BEFORE sourcing sync.sh (which sets its own SCRIPT_DIR)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_TMP=""

setup() {
    TEST_TMP="$(mktemp -d)"
    mkdir -p "$TEST_TMP/source"
    mkdir -p "$TEST_TMP/cc_dest"
    mkdir -p "$TEST_TMP/cowork_base/uuid1/uuid2/skills"
    export SYNC_SOURCE_DIR="$TEST_TMP/source"
    export SYNC_CC_DEST="$TEST_TMP/cc_dest"
    export SYNC_COWORK_BASE="$TEST_TMP/cowork_base"
    export SYNC_MANIFEST="$TEST_TMP/.sync-manifest.json"
}

teardown() {
    if [ -n "$TEST_TMP" ] && [ -d "$TEST_TMP" ]; then
        rm -rf "$TEST_TMP"
    fi
    unset SYNC_SOURCE_DIR SYNC_CC_DEST SYNC_COWORK_BASE SYNC_MANIFEST
}

create_source_skill() {
    local name="$1"
    local content="${2:-# Test skill}"
    mkdir -p "$TEST_TMP/source/$name"
    echo "$content" > "$TEST_TMP/source/$name/SKILL.md"
}

seed_cowork_skill() {
    local name="$1"
    local cowork_skills="$TEST_TMP/cowork_base/uuid1/uuid2/skills"
    mkdir -p "$cowork_skills/$name"
    echo "# seed" > "$cowork_skills/$name/SKILL.md"
}

# Source sync.sh to access its functions (BASH_SOURCE fix prevents SCRIPT_DIR clash)
source "$REPO_ROOT/sync.sh" 2>/dev/null || true

# ─── Unit Tests ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Unit Tests${RESET}"
echo ""

test_find_source_skills_only_with_skillmd() {
    setup
    create_source_skill "real-skill"
    mkdir -p "$TEST_TMP/source/no-skill-md"
    echo "readme" > "$TEST_TMP/source/no-skill-md/README.md"
    mkdir -p "$TEST_TMP/source/empty-dir"

    local result
    result="$(find_source_skills "$TEST_TMP/source")"
    assert_eq "real-skill" "$result" "should find only dirs with SKILL.md" || return 1
    teardown
}
run_test test_find_source_skills_only_with_skillmd

test_find_source_skills_multiple() {
    setup
    create_source_skill "alpha"
    create_source_skill "beta"
    create_source_skill "gamma"

    local count
    count="$(find_source_skills "$TEST_TMP/source" | wc -l | tr -d ' ')"
    assert_eq "3" "$count" "should find 3 skills" || return 1
    teardown
}
run_test test_find_source_skills_multiple

test_discover_cowork_path_found() {
    setup
    seed_cowork_skill "some-skill"

    local path
    path="$(discover_cowork_path "$TEST_TMP/cowork_base")"
    assert_dir_exists "$path" "discovered cowork path should exist" || return 1
    teardown
}
run_test test_discover_cowork_path_found

test_discover_cowork_path_not_found() {
    setup
    if discover_cowork_path "$TEST_TMP/nonexistent" 2>/dev/null; then
        echo -e "  ${RED}FAIL${RESET}: should fail when base doesn't exist" >&2
        teardown
        return 1
    fi
    teardown
}
run_test test_discover_cowork_path_not_found

test_sync_skill_copies_files() {
    setup
    create_source_skill "my-skill" "---\nname: my-skill\n---"
    mkdir -p "$TEST_TMP/dest"

    sync_skill "my-skill" "$TEST_TMP/source" "$TEST_TMP/dest"
    assert_file_exists "$TEST_TMP/dest/my-skill/SKILL.md" "SKILL.md should be copied" || return 1
    teardown
}
run_test test_sync_skill_copies_files

test_sync_skill_updates_existing() {
    setup
    create_source_skill "my-skill" "version 1"
    mkdir -p "$TEST_TMP/dest"
    sync_skill "my-skill" "$TEST_TMP/source" "$TEST_TMP/dest"

    # Update source
    echo "version 2" > "$TEST_TMP/source/my-skill/SKILL.md"
    sync_skill "my-skill" "$TEST_TMP/source" "$TEST_TMP/dest"

    local content
    content="$(cat "$TEST_TMP/dest/my-skill/SKILL.md")"
    assert_eq "version 2" "$content" "should update to version 2" || return 1
    teardown
}
run_test test_sync_skill_updates_existing

test_remove_skill_deletes_dir() {
    setup
    mkdir -p "$TEST_TMP/dest/old-skill"
    echo "old" > "$TEST_TMP/dest/old-skill/SKILL.md"

    remove_skill "old-skill" "$TEST_TMP/dest"
    assert_not_exists "$TEST_TMP/dest/old-skill" "skill dir should be removed" || return 1
    teardown
}
run_test test_remove_skill_deletes_dir

test_remove_skill_nonexistent_fails() {
    setup
    if remove_skill "ghost" "$TEST_TMP/dest"; then
        echo -e "  ${RED}FAIL${RESET}: should fail for nonexistent skill" >&2
        teardown
        return 1
    fi
    teardown
}
run_test test_remove_skill_nonexistent_fails

test_write_manifest_creates_valid_json() {
    setup
    write_manifest "$TEST_TMP/manifest.json" "/dest/cc" "/dest/cowork" "skill-a" "skill-b"

    assert_file_exists "$TEST_TMP/manifest.json" "manifest should be created" || return 1
    grep -q '"skill-a"' "$TEST_TMP/manifest.json" || { echo "  FAIL: missing skill-a"; teardown; return 1; }
    grep -q '"skill-b"' "$TEST_TMP/manifest.json" || { echo "  FAIL: missing skill-b"; teardown; return 1; }
    grep -q '"last_sync"' "$TEST_TMP/manifest.json" || { echo "  FAIL: missing last_sync"; teardown; return 1; }
    teardown
}
run_test test_write_manifest_creates_valid_json

test_read_manifest_skills_parses_correctly() {
    setup
    write_manifest "$TEST_TMP/manifest.json" "/cc" "/cowork" "alpha" "beta" "gamma"

    local skills
    skills="$(read_manifest_skills "$TEST_TMP/manifest.json")"
    local count
    count="$(echo "$skills" | wc -l | tr -d ' ')"
    assert_eq "3" "$count" "should read 3 skills from manifest" || return 1

    echo "$skills" | grep -q "alpha" || { echo "  FAIL: missing alpha"; teardown; return 1; }
    echo "$skills" | grep -q "beta" || { echo "  FAIL: missing beta"; teardown; return 1; }
    echo "$skills" | grep -q "gamma" || { echo "  FAIL: missing gamma"; teardown; return 1; }
    teardown
}
run_test test_read_manifest_skills_parses_correctly

test_read_manifest_skills_empty_when_no_file() {
    setup
    local result
    result="$(read_manifest_skills "$TEST_TMP/nonexistent.json")"
    assert_eq "" "$result" "should return empty for missing manifest" || return 1
    teardown
}
run_test test_read_manifest_skills_empty_when_no_file

# ─── Integration Tests ────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Integration Tests${RESET}"
echo ""

test_integration_full_sync() {
    setup
    create_source_skill "skill-a" "# Skill A"
    create_source_skill "skill-b" "# Skill B"
    seed_cowork_skill "existing"

    "$REPO_ROOT/sync.sh" --quiet

    assert_file_exists "$TEST_TMP/cc_dest/skill-a/SKILL.md" "skill-a in Claude Code" || return 1
    assert_file_exists "$TEST_TMP/cc_dest/skill-b/SKILL.md" "skill-b in Claude Code" || return 1

    local cowork_path="$TEST_TMP/cowork_base/uuid1/uuid2/skills"
    assert_file_exists "$cowork_path/skill-a/SKILL.md" "skill-a in Cowork" || return 1
    assert_file_exists "$cowork_path/skill-b/SKILL.md" "skill-b in Cowork" || return 1

    assert_file_exists "$TEST_TMP/.sync-manifest.json" "manifest created" || return 1
    teardown
}
run_test test_integration_full_sync

test_integration_idempotent() {
    setup
    create_source_skill "skill-x" "# content"
    seed_cowork_skill "existing"

    "$REPO_ROOT/sync.sh" --quiet
    local first_content
    first_content="$(cat "$TEST_TMP/cc_dest/skill-x/SKILL.md")"

    "$REPO_ROOT/sync.sh" --quiet
    local second_content
    second_content="$(cat "$TEST_TMP/cc_dest/skill-x/SKILL.md")"

    assert_eq "$first_content" "$second_content" "content unchanged after second sync" || return 1
    teardown
}
run_test test_integration_idempotent

test_integration_add_new_skill() {
    setup
    create_source_skill "initial"
    seed_cowork_skill "existing"

    "$REPO_ROOT/sync.sh" --quiet
    assert_file_exists "$TEST_TMP/cc_dest/initial/SKILL.md" "initial synced" || return 1

    create_source_skill "added-later" "# New"
    "$REPO_ROOT/sync.sh" --quiet

    assert_file_exists "$TEST_TMP/cc_dest/added-later/SKILL.md" "new skill synced" || return 1
    assert_file_exists "$TEST_TMP/cc_dest/initial/SKILL.md" "initial still there" || return 1
    teardown
}
run_test test_integration_add_new_skill

test_integration_remove_skill_cleanup() {
    setup
    create_source_skill "keep-me"
    create_source_skill "remove-me"
    seed_cowork_skill "existing"

    "$REPO_ROOT/sync.sh" --quiet
    assert_file_exists "$TEST_TMP/cc_dest/remove-me/SKILL.md" "remove-me exists after first sync" || return 1

    rm -rf "$TEST_TMP/source/remove-me"
    "$REPO_ROOT/sync.sh" --quiet

    assert_not_exists "$TEST_TMP/cc_dest/remove-me" "remove-me cleaned up" || return 1
    assert_file_exists "$TEST_TMP/cc_dest/keep-me/SKILL.md" "keep-me still there" || return 1
    teardown
}
run_test test_integration_remove_skill_cleanup

test_integration_external_skills_preserved() {
    setup
    mkdir -p "$TEST_TMP/cc_dest/deploy-check"
    echo "# external" > "$TEST_TMP/cc_dest/deploy-check/SKILL.md"

    create_source_skill "my-skill"
    seed_cowork_skill "existing"

    "$REPO_ROOT/sync.sh" --quiet

    assert_file_exists "$TEST_TMP/cc_dest/deploy-check/SKILL.md" "external skill preserved" || return 1
    assert_file_exists "$TEST_TMP/cc_dest/my-skill/SKILL.md" "own skill synced" || return 1

    rm -rf "$TEST_TMP/source/my-skill"
    "$REPO_ROOT/sync.sh" --quiet

    assert_file_exists "$TEST_TMP/cc_dest/deploy-check/SKILL.md" "external skill still preserved after cleanup" || return 1
    assert_not_exists "$TEST_TMP/cc_dest/my-skill" "managed skill removed" || return 1
    teardown
}
run_test test_integration_external_skills_preserved

test_integration_cowork_absent() {
    setup
    create_source_skill "lonely-skill"
    export SYNC_COWORK_BASE="$TEST_TMP/no-cowork-here"

    "$REPO_ROOT/sync.sh" --quiet

    assert_file_exists "$TEST_TMP/cc_dest/lonely-skill/SKILL.md" "skill synced to Claude Code" || return 1
    assert_not_exists "$TEST_TMP/no-cowork-here" "cowork path not created" || return 1
    assert_file_exists "$TEST_TMP/.sync-manifest.json" "manifest still created" || return 1
    teardown
}
run_test test_integration_cowork_absent

test_integration_skill_with_subdirs() {
    setup
    create_source_skill "complex-skill"
    mkdir -p "$TEST_TMP/source/complex-skill/references"
    echo "ref data" > "$TEST_TMP/source/complex-skill/references/data.md"
    mkdir -p "$TEST_TMP/source/complex-skill/scripts"
    echo "#!/bin/bash" > "$TEST_TMP/source/complex-skill/scripts/run.sh"
    seed_cowork_skill "existing"

    "$REPO_ROOT/sync.sh" --quiet

    assert_file_exists "$TEST_TMP/cc_dest/complex-skill/SKILL.md" "SKILL.md copied" || return 1
    assert_file_exists "$TEST_TMP/cc_dest/complex-skill/references/data.md" "subdirs copied" || return 1
    assert_file_exists "$TEST_TMP/cc_dest/complex-skill/scripts/run.sh" "nested files copied" || return 1
    teardown
}
run_test test_integration_skill_with_subdirs

test_integration_rsync_deletes_removed_files() {
    setup
    create_source_skill "evolving"
    echo "old file" > "$TEST_TMP/source/evolving/old-ref.md"
    seed_cowork_skill "existing"

    "$REPO_ROOT/sync.sh" --quiet
    assert_file_exists "$TEST_TMP/cc_dest/evolving/old-ref.md" "old file synced" || return 1

    rm "$TEST_TMP/source/evolving/old-ref.md"
    echo "new file" > "$TEST_TMP/source/evolving/new-ref.md"
    "$REPO_ROOT/sync.sh" --quiet

    assert_not_exists "$TEST_TMP/cc_dest/evolving/old-ref.md" "old file removed by rsync --delete" || return 1
    assert_file_exists "$TEST_TMP/cc_dest/evolving/new-ref.md" "new file synced" || return 1
    teardown
}
run_test test_integration_rsync_deletes_removed_files

# ─── Results ──────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All $TESTS_RUN tests passed${RESET}"
else
    echo -e "${RED}${BOLD}$TESTS_FAILED/$TESTS_RUN tests failed${RESET}"
    for f in "${FAILURES[@]}"; do
        echo -e "  ${RED}✗${RESET} $f"
    done
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit $TESTS_FAILED
