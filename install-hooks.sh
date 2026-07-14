#!/usr/bin/env bash
#
# install-hooks.sh — installs the maintainer-side git hooks for this repo.
#
# Why this exists: .git/hooks/ is never cloned (git refuses to, for security),
# so a hook installed by hand survives only in the clone where it was created.
# On 2026-07-14 the post-commit hook silently stopped firing because
# core.hooksPath in .git/config still pointed at the repo's pre-PARA-migration
# location (~/Documents/3.RESOURCES/SKILLS/claude-skills/.git/hooks), a path
# that no longer exists. Git does not error on a dead hooksPath: it finds no
# hooks and moves on. Skills then stayed in the source tree and never reached
# ~/.claude/skills/ — a silent failure.
#
# Run this after cloning, or any time the hook seems dead.
#
# NOTE: this is the MAINTAINER installer (keeps the runtime in sync while you
# develop skills here). install.sh is the CONSUMER installer (copies skills to
# someone's Claude). They are deliberately separate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET} $1" >&2; }
err()  { echo -e "${RED}✗${RESET} $1" >&2; }

# Guard: we must be inside this repo's working tree.
assert_in_repo() {
    local toplevel
    toplevel="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null)" || {
        err "not a git repository: $REPO_ROOT"
        exit 1
    }
    [ -f "$REPO_ROOT/sync.sh" ] || {
        err "sync.sh not found in $REPO_ROOT — wrong directory?"
        exit 1
    }
}

# Returns the directory git will actually look in for hooks.
effective_hooks_dir() {
    git -C "$REPO_ROOT" rev-parse --git-path hooks
}


# Guarantees git will actually look somewhere real for its hooks.
#
# core.hooksPath, when set, *replaces* .git/hooks entirely. It is sometimes set
# deliberately (a shared, versioned hooks/ dir), so we do not clobber it when it
# points somewhere that exists — we install into it instead. But a hooksPath
# aimed at a directory that no longer exists makes git find no hooks at all and
# say nothing, which is precisely how the post-commit sync died here. That one
# we remove, out loud.
reconcile_hooks_path() {
    local configured
    configured="$(git -C "$REPO_ROOT" config --get core.hooksPath || true)"

    [ -n "$configured" ] || return 0                 # unset: git uses .git/hooks

    if [ -d "$configured" ]; then
        warn "core.hooksPath is set to $configured — installing the hook there, not in .git/hooks"
        return 0
    fi

    git -C "$REPO_ROOT" config --unset core.hooksPath
    warn "removed a dead core.hooksPath ($configured did not exist) — hooks now live in .git/hooks"
}


# Writes the post-commit hook that mirrors skills into the runtime.
# Uses $0-relative resolution so it works regardless of git's cwd.
write_post_commit_hook() {
    local hooks_dir hook
    hooks_dir="$(effective_hooks_dir)"
    mkdir -p "$hooks_dir"
    hook="$hooks_dir/post-commit"

    cat > "$hook" <<'HOOK'
#!/bin/sh
# Managed by install-hooks.sh — regenerate with: bash install-hooks.sh
# Mirrors the skills in this repo into the Claude runtime after every commit.
set -e
REPO_ROOT="$(git rev-parse --show-toplevel)"
[ -x "$REPO_ROOT/sync.sh" ] || {
    echo "post-commit: sync.sh missing or not executable — skills NOT synced" >&2
    exit 0
}
"$REPO_ROOT/sync.sh" --quiet || \
    echo "post-commit: sync.sh failed — skills may be stale in the runtime" >&2
HOOK

    chmod +x "$hook"
    ok "post-commit hook installed at $hook"
}

main() {
    assert_in_repo
    reconcile_hooks_path
    write_post_commit_hook
    ok "done — commit a skill change and it will sync to the runtime automatically"
}

main "$@"
