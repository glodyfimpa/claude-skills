# CLAUDE.md — claude-skills

## Repo Structure
- Each subdirectory with a `SKILL.md` is a skill
- `install.sh` — interactive installer (Claude Code or Desktop)
- `sync.sh` — syncs all skills to Claude Code (`~/.claude/skills/`) and Cowork (auto-discovered path). Post-commit hook runs `sync.sh --quiet` automatically
- `tests/test_sync.sh` — bash test suite (19 tests). Run: `bash tests/test_sync.sh`

## Bash Script Conventions
- `set -euo pipefail` in all scripts
- Use `BASH_SOURCE[0]` not `$0` for path resolution (scripts may be sourced by tests)
- Empty arrays under `set -u`: use `"${arr[@]+"${arr[@]}"}"` pattern
- rsync: use `--checksum` for small files to avoid same-second same-size skip
- Scripts support env var overrides (SYNC_SOURCE_DIR, SYNC_CC_DEST, etc.) for test isolation
- Funzioni interattive che restituiscono valori: SEMPRE redirect display (echo, read prompt, colori) su `>&2`. Lasciare stdout puro per il dato di ritorno se chiamate via `$()`. Alternativa bash 3.2-compatible (no nameref): variabile globale popolata dalla funzione (es. `SELECTED_SKILLS` in install.sh). Mai `echo "$result"` dopo aver stampato UI in stdout — il caller riceve UI mescolato al valore e `read -ra` rompe

## Testing
- Tests use `mktemp -d` fixtures, cleaned in teardown
- Source the script under test to access functions; guard main with `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]`
- Every assert needs `|| return 1` to propagate failures inside `if`-wrapped test runners
