#!/usr/bin/env bash
set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_FILE="$SCRIPT_DIR/.sync-manifest.json"
CLAUDE_CODE_SKILLS="$HOME/.claude/skills"

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

# ─── Output helpers ───────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { $QUIET || echo -e "$1"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}" >&2; }
err()  { echo -e "${RED}✗ $1${RESET}" >&2; }

# ─── Core functions ───────────────────────────────────────────────────

find_source_skills() {
    local source_dir="${1:-$SCRIPT_DIR}"
    for d in "$source_dir"/*/; do
        [ -f "$d/SKILL.md" ] && basename "$d"
    done
}

sync_skill() {
    local skill_name="$1"
    local source_dir="$2"
    local dest_dir="$3"

    if [ ! -d "$source_dir/$skill_name" ]; then
        return 1
    fi

    # A symlinked install is owned elsewhere (e.g. the brain vault): never write through it.
    if [ -L "$dest_dir/$skill_name" ]; then
        warn "$skill_name: $dest_dir/$skill_name is a symlink, left untouched"
        return 0
    fi

    mkdir -p "$dest_dir/$skill_name"
    rsync -a --checksum --delete --exclude='.git' --exclude='.DS_Store' \
        "$source_dir/$skill_name/" "$dest_dir/$skill_name/"
}

remove_skill() {
    local skill_name="$1"
    local dest_dir="$2"

    if [ -L "$dest_dir/$skill_name" ]; then
        warn "$skill_name: $dest_dir/$skill_name is a symlink, not removed"
        return 1
    fi

    if [ -d "$dest_dir/$skill_name" ]; then
        rm -rf "${dest_dir:?}/${skill_name:?}"
        return 0
    fi
    return 1
}

# ─── Publish guard ────────────────────────────────────────────────────

# The runtime (~/.claude/skills) gets only reviewed skills: the source
# tree must be on branch main at a commit contained in origin/main. A feature
# branch, a linked worktree on another branch, a detached HEAD, a local commit
# not yet on origin/main, or a source outside git is skipped (fail closed).
# Uses the local origin/main ref, no fetch: hooks must not hit the network.
# Incident 2026-11-23: a commit on a feature branch in a worktree published an
# unmerged, review-rejected weekly-planner through the post-commit hook.
publish_allowed() {
    local source_dir="$1" branch sha
    if ! git -C "$source_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        warn "sync skipped: $source_dir is not a git work tree, nothing published"
        return 1
    fi
    branch="$(git -C "$source_dir" rev-parse --abbrev-ref HEAD)"
    sha="$(git -C "$source_dir" rev-parse --short HEAD)"
    if [ "$branch" != "main" ]; then
        warn "sync skipped: $branch@$sha is not branch main, nothing published (publish after merge + pull)"
        return 1
    fi
    if ! git -C "$source_dir" rev-parse --verify -q refs/remotes/origin/main >/dev/null; then
        warn "sync skipped: no origin/main ref in $source_dir, nothing published"
        return 1
    fi
    if ! git -C "$source_dir" merge-base --is-ancestor HEAD refs/remotes/origin/main; then
        warn "sync skipped: main@$sha is not on origin/main, nothing published (push and merge first)"
        return 1
    fi
    return 0
}

# ─── Manifest ─────────────────────────────────────────────────────────

read_manifest_skills() {
    local manifest="${1:-$MANIFEST_FILE}"
    if [ ! -f "$manifest" ]; then
        return 0
    fi
    # Extract managed_skills array values (simple JSON parsing without jq)
    sed -n '/"managed_skills"/,/]/p' "$manifest" \
        | grep '"' \
        | grep -v 'managed_skills' \
        | sed 's/.*"\([^"]*\)".*/\1/'
}

write_manifest() {
    local manifest="$1"
    shift
    local claude_code_dest="$1"
    shift
    local skills=("$@")

    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%S)"

    local skills_json=""
    for i in "${!skills[@]}"; do
        skills_json="${skills_json}    \"${skills[$i]}\""
        if [ "$i" -lt $(( ${#skills[@]} - 1 )) ]; then
            skills_json="${skills_json},"
        fi
        skills_json="${skills_json}
"
    done

    cat > "$manifest" << MANIFEST_EOF
{
  "last_sync": "$now",
  "managed_skills": [
$skills_json  ],
  "destinations": {
    "claude_code": "$claude_code_dest"
  }
}
MANIFEST_EOF
}

# ─── Main ─────────────────────────────────────────────────────────────

main() {
    local source_dir="${SYNC_SOURCE_DIR:-$SCRIPT_DIR}"
    local cc_dest="${SYNC_CC_DEST:-$CLAUDE_CODE_SKILLS}"
    local manifest="${SYNC_MANIFEST:-$MANIFEST_FILE}"

    log "${BOLD}Skill Sync${RESET}"
    log ""

    # 0. Publish only reviewed skills (before any write or removal)
    publish_allowed "$source_dir" || exit 0

    # Cowork is not a destination: the desktop app re-syncs its skills folder
    # every 20 minutes and on window focus, deleting whatever is not in the
    # account's server-side skill set (verified in main.log, 2026-11-23).
    warn "Cowork is not synced (the app deletes local copies within 20 min): upload a skill ZIP in claude.ai Customize > Skills, or install as a plugin in Cowork"

    # 1. Find source skills
    local source_skills=()
    while IFS= read -r s; do
        source_skills+=("$s")
    done < <(find_source_skills "$source_dir")

    if [ ${#source_skills[@]} -eq 0 ] && [ ! -f "$manifest" ]; then
        warn "No skills found in $source_dir"
        exit 0
    fi

    log "  Found ${#source_skills[@]} skill(s) in source"

    # 2. Destination: Claude Code only
    mkdir -p "$cc_dest"

    log ""

    # 3. Sync each skill
    local synced_skills=()
    for skill in "${source_skills[@]+"${source_skills[@]}"}"; do
        # Claude Code
        if sync_skill "$skill" "$source_dir" "$cc_dest"; then
            log "  ${GREEN}✓${RESET} $skill → Claude Code"
        else
            err "$skill → Claude Code failed"
        fi

        synced_skills+=("$skill")
    done

    # 4. Cleanup: remove skills in old manifest but no longer in source
    local old_managed=()
    while IFS= read -r s; do
        [ -n "$s" ] && old_managed+=("$s")
    done < <(read_manifest_skills "$manifest")

    local removed=0
    for old_skill in "${old_managed[@]+"${old_managed[@]}"}"; do
        local still_exists=false
        for current in "${source_skills[@]+"${source_skills[@]}"}"; do
            if [ "$old_skill" = "$current" ]; then
                still_exists=true
                break
            fi
        done

        if ! $still_exists; then
            if remove_skill "$old_skill" "$cc_dest"; then
                log "  ${YELLOW}✗${RESET} $old_skill removed from Claude Code"
                removed=$((removed + 1))
            fi
        fi
    done

    # 5. Write manifest
    write_manifest "$manifest" "$cc_dest" "${synced_skills[@]+"${synced_skills[@]}"}"

    log ""
    log "${GREEN}${BOLD}Synced ${#synced_skills[@]} skill(s)${RESET}${removed:+, removed $removed}"
}

# Allow sourcing for tests without executing main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
