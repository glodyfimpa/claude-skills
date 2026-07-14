#!/usr/bin/env bash
set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_FILE="$SCRIPT_DIR/.sync-manifest.json"
CLAUDE_CODE_SKILLS="$HOME/.claude/skills"
COWORK_BASE="$HOME/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin"

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

discover_cowork_path() {
    local base="${1:-$COWORK_BASE}"
    if [ ! -d "$base" ]; then
        return 1
    fi
    local match
    match="$(find "$base" -name "SKILL.md" -maxdepth 5 2>/dev/null | head -1)"
    if [ -z "$match" ]; then
        return 1
    fi
    # Go up from .../skills/some-skill/SKILL.md to .../skills/
    dirname "$(dirname "$match")"
}

sync_skill() {
    local skill_name="$1"
    local source_dir="$2"
    local dest_dir="$3"

    if [ ! -d "$source_dir/$skill_name" ]; then
        return 1
    fi

    mkdir -p "$dest_dir/$skill_name"
    rsync -a --checksum --delete --exclude='.git' --exclude='.DS_Store' \
        "$source_dir/$skill_name/" "$dest_dir/$skill_name/"
}

remove_skill() {
    local skill_name="$1"
    local dest_dir="$2"

    if [ -d "$dest_dir/$skill_name" ]; then
        rm -rf "$dest_dir/$skill_name"
        return 0
    fi
    return 1
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
    local cowork_dest="$1"
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
    "claude_code": "$claude_code_dest",
    "cowork": "$cowork_dest"
  }
}
MANIFEST_EOF
}

# ─── Main ─────────────────────────────────────────────────────────────

main() {
    local source_dir="${SYNC_SOURCE_DIR:-$SCRIPT_DIR}"
    local cc_dest="${SYNC_CC_DEST:-$CLAUDE_CODE_SKILLS}"
    local cowork_base="${SYNC_COWORK_BASE:-$COWORK_BASE}"
    local manifest="${SYNC_MANIFEST:-$MANIFEST_FILE}"

    log "${BOLD}Skill Sync${RESET}"
    log ""

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

    # 2. Discover destinations
    mkdir -p "$cc_dest"

    local cowork_dest=""
    if cowork_dest="$(discover_cowork_path "$cowork_base")" 2>/dev/null; then
        log "  Cowork path: ${CYAN}$cowork_dest${RESET}"
    else
        cowork_dest=""
        log "  ${YELLOW}Cowork not found, syncing only to Claude Code${RESET}"
    fi

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

        # Cowork
        if [ -n "$cowork_dest" ]; then
            if sync_skill "$skill" "$source_dir" "$cowork_dest"; then
                log "  ${GREEN}✓${RESET} $skill → Cowork"
            else
                err "$skill → Cowork failed"
            fi
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
            if [ -n "$cowork_dest" ] && remove_skill "$old_skill" "$cowork_dest"; then
                log "  ${YELLOW}✗${RESET} $old_skill removed from Cowork"
            fi
        fi
    done

    # 5. Write manifest
    write_manifest "$manifest" "$cc_dest" "${cowork_dest:-none}" "${synced_skills[@]+"${synced_skills[@]}"}"

    log ""
    log "${GREEN}${BOLD}Synced ${#synced_skills[@]} skill(s)${RESET}${removed:+, removed $removed}"
}

# Allow sourcing for tests without executing main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
