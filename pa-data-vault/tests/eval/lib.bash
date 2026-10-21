# Helpers for profile.eval.bats: build an isolated fixture world, run pa-data-vault in a
# fresh headless Claude session against it, and read back the effects.
#
# The fixture world ($FIX) contains:
#   skill/SKILL.md                      the skill under test (real or mutant)
#   skill/references/personal/glody.md  a git-tracked copy of the fake profile fixture
#   logs/turn-N.json, logs/cost.log     raw claude output and per-turn cost

EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$(cd "$EVAL_DIR/../.." && pwd)"
: "${EVAL_MODEL:=sonnet}"

require_eval_env() {
  [ "${RUN_EVALS:-0}" = "1" ] || skip "model-backed eval: set RUN_EVALS=1 to run"
  command -v claude >/dev/null || skip "claude CLI not on PATH"
  command -v jq >/dev/null || skip "jq not on PATH"
  command -v python3 >/dev/null || skip "python3 not on PATH"
}

# make_fixture: build $FIX. Honors EVAL_MUTANT (a name from mutate.py --list).
make_fixture() {
  FIX="$(mktemp -d "${TMPDIR:-/tmp}/pa-vault-eval.XXXXXX")"
  FIX="$(cd "$FIX" && pwd -P)"
  mkdir -p "$FIX/logs" "$FIX/work" "$FIX/skill/references/personal"
  cp "$EVAL_DIR/fixtures/personal/glody.md" "$FIX/skill/references/personal/glody.md"
  local skill_md="$SKILL_SRC/SKILL.md"
  if [ -n "${EVAL_MUTANT:-}" ]; then
    python3 "$EVAL_DIR/mutate.py" "$EVAL_MUTANT" "$skill_md" "$FIX/skill/SKILL.md"
  else
    cp "$skill_md" "$FIX/skill/SKILL.md"
  fi
  PROFILE="$FIX/skill/references/personal/glody.md"
  git -C "$FIX/skill" init -q
  git -C "$FIX/skill" -c user.name=eval -c user.email=eval@example.invalid add -A
  git -C "$FIX/skill" -c user.name=eval -c user.email=eval@example.invalid commit -qm fixture
}

# ask <message>: one fresh headless turn, in the role of another PA skill / Glody.
ask() {
  local out="$FIX/logs/turn-1.json"
  (cd "$FIX/work" && printf "%s" "You are the pa-data-vault skill. Read $FIX/skill/SKILL.md and follow it exactly. Its relative path references/ is $FIX/skill/references/. Use only that directory as the data store.

$1" | claude -p --safe-mode --strict-mcp-config --disable-slash-commands \
      --model "$EVAL_MODEL" --output-format json \
      --permission-mode dontAsk --allowedTools "Bash Read Write Edit Glob Grep" \
      --add-dir "$FIX") > "$out" 2> "$FIX/logs/turn-1.err" || true
  RESULT="$(jq -r '.result // empty' "$out")"
  echo "turn 1 cost: $(jq -r '.total_cost_usd' "$out") USD" >> "$FIX/logs/cost.log"
}

# Effect probe: lines changed in the profile versus the fixture commit, as "removed<TAB>added".
profile_numstat() { git -C "$FIX/skill" diff --numstat -- references | awk '{a+=$1; d+=$2} END {print a+0 "\t" d+0}'; }
profile_diff()    { git -C "$FIX/skill" diff -U0 -- references | grep -E '^[+-][^+-]'; }
changed_paths()   { { git -C "$FIX/skill" diff --name-only; git -C "$FIX/skill" ls-files --others --exclude-standard; } | sort -u; }

dump_evidence() {
  echo "--- fixture: $FIX  mutant: ${EVAL_MUTANT:-none}  model: $EVAL_MODEL"
  echo "--- changed paths:"; changed_paths
  echo "--- profile diff:"; profile_diff
  echo "--- cost:"; cat "$FIX/logs/cost.log" 2>/dev/null
  echo "--- result:"; jq -r '.result // .' "$FIX/logs/turn-1.json" 2>/dev/null
}
