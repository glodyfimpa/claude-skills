# Helpers for contracts.eval.bats: build an isolated fixture world, run the ritual in a
# fresh headless Claude session against it, and read back the effects.
#
# The fixture world ($FIX) contains:
#   vault/    a git repo shaped like the brain (principles, MEMORY.md, build-queue.md,
#             queue_parser.py copied from the real brain)
#   skills/   installed-skills dir for show-neighbors (fixture skills)
#   skill/    the skill under test: SKILL.md (real or mutant) with ~ paths rewritten
#             into $FIX, plus show-neighbors wrapped to log every invocation
#   bin/      PATH stubs: gcal-event (calendar seam, logs to logs/calendar.log) and
#             python3 (an interpreter with PyYAML, needed by queue_parser)
#   logs/     show-neighbors.log, calendar.log, turn-N.json (raw claude output)

EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$(cd "$EVAL_DIR/../.." && pwd)"

: "${EVAL_MODEL:=sonnet}"
: "${EVAL_QUEUE_PARSER:=$HOME/Documents/brain/areas/ai-automation/autonomous-agents/queue_parser.py}"

# An interpreter with PyYAML: EVAL_PYTHON if set, else the first python3 that imports yaml.
eval_python() {
  if [ -n "${EVAL_PYTHON:-}" ]; then echo "$EVAL_PYTHON"; return; fi
  local p
  for p in python3 /opt/homebrew/bin/python3 /usr/local/bin/python3; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import yaml' 2>/dev/null; then
      command -v "$p"; return
    fi
  done
  return 1
}

# Skip the whole file unless evals were asked for and their prerequisites exist.
require_eval_env() {
  [ "${RUN_EVALS:-0}" = "1" ] || skip "model-backed eval: set RUN_EVALS=1 to run"
  command -v claude >/dev/null || skip "claude CLI not on PATH"
  command -v jq >/dev/null || skip "jq not on PATH"
  eval_python >/dev/null || skip "no python3 with PyYAML (set EVAL_PYTHON)"
  [ -f "$EVAL_QUEUE_PARSER" ] || skip "queue_parser.py not found (set EVAL_QUEUE_PARSER)"
}

# make_fixture: build $FIX. Honors EVAL_MUTANT (a name from mutate.py --list).
make_fixture() {
  FIX="$(mktemp -d "${TMPDIR:-/tmp}/retro-eval.XXXXXX")"
  FIX="$(cd "$FIX" && pwd -P)"
  mkdir -p "$FIX/logs" "$FIX/bin" "$FIX/work" "$FIX/skills" "$FIX/skill/bin"

  # Vault: template + queue_parser, committed so `git status` shows every write.
  cp -R "$EVAL_DIR/fixtures/vault" "$FIX/vault"
  mkdir -p "$FIX/vault/areas/ai-automation/autonomous-agents"
  cp "$EVAL_QUEUE_PARSER" "$FIX/vault/areas/ai-automation/autonomous-agents/queue_parser.py"
  printf "__pycache__/\n" > "$FIX/vault/.gitignore"
  git -C "$FIX/vault" init -q
  git -C "$FIX/vault" -c user.name=eval -c user.email=eval@example.invalid add -A
  git -C "$FIX/vault" -c user.name=eval -c user.email=eval@example.invalid commit -qm fixture

  # Installed skills seen by show-neighbors (stored as SKILL.fixture.md so they are
  # never discovered as real skills once this repo is synced into ~/.claude/skills).
  local d
  for d in "$EVAL_DIR"/fixtures/skills/*/; do
    mkdir -p "$FIX/skills/$(basename "$d")"
    cp "$d/SKILL.fixture.md" "$FIX/skills/$(basename "$d")/SKILL.md"
  done

  # Skill under test.
  cp "$SKILL_SRC/neighbors.py" "$FIX/skill/"
  cp "$SKILL_SRC/bin/show-neighbors" "$FIX/skill/bin/show-neighbors.real"
  local skill_md="$SKILL_SRC/SKILL.md"
  if [ -n "${EVAL_MUTANT:-}" ]; then
    "$(eval_python)" "$EVAL_DIR/mutate.py" "$EVAL_MUTANT" "$skill_md" "$FIX/skill/SKILL.orig.md"
    skill_md="$FIX/skill/SKILL.orig.md"
  fi
  # Point every home-relative path of the skill into the fixture (order matters).
  sed -e "s#~/.claude/skills/session-retrospective#$FIX/skill#g" \
      -e "s#~/Documents/brain#$FIX/vault#g" \
      -e "s#~/.claude/skills#$FIX/skills#g" \
      "$skill_md" > "$FIX/skill/SKILL.md"
  rm -f "$FIX/skill/SKILL.orig.md"

  cat > "$FIX/skill/bin/show-neighbors" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$FIX/logs/show-neighbors.log"
exec python3 "$FIX/skill/bin/show-neighbors.real" --vault "$FIX/vault" --skills "$FIX/skills" "\$@"
EOF
  chmod +x "$FIX/skill/bin/show-neighbors" "$FIX/skill/bin/show-neighbors.real"

  # Calendar seam: the real channel is a Google Calendar event; here a CLI that logs.
  cat > "$FIX/bin/gcal-event" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" != "create" ]; then
  echo 'usage: gcal-event create --title "..." --start "YYYY-MM-DDTHH:MM" --description "..."'
  exit 0
fi
# One line per event, whatever the description holds.
printf '%s' "\$*" | tr '\n' ' ' >> "$FIX/logs/calendar.log"; echo >> "$FIX/logs/calendar.log"
echo "event created: id=stub-\$(wc -l < "$FIX/logs/calendar.log" | tr -d ' ')"
EOF
  chmod +x "$FIX/bin/gcal-event"
  # A wrapper, not a symlink: a symlinked venv interpreter loses its site-packages.
  printf '#!/bin/sh\nexec "%s" "$@"\n' "$(eval_python)" > "$FIX/bin/python3"
  chmod +x "$FIX/bin/python3"

  VAULT_BASE="$(git -C "$FIX/vault" rev-parse HEAD)"
  QUEUE_BEFORE="$(queue_len)"
}

# run_turn <n> <message-file-or-text>: first turn starts a session, later turns resume it.
run_turn() {
  local n="$1" msg="$2" out="$FIX/logs/turn-$1.json"
  local -a resume=()
  [ -n "${SESSION_ID:-}" ] && resume=(--resume "$SESSION_ID")
  (cd "$FIX/work" && printf "%s" "$msg" | PATH="$FIX/bin:$PATH" PYTHONDONTWRITEBYTECODE=1 claude -p \
      --safe-mode --strict-mcp-config --disable-slash-commands \
      --model "$EVAL_MODEL" --output-format json \
      --permission-mode dontAsk --allowedTools "Bash Read Write Edit Glob Grep" \
      --add-dir "$FIX" \
      "${resume[@]+"${resume[@]}"}") > "$out" 2> "$FIX/logs/turn-$n.err" || true
  SESSION_ID="$(jq -r '.session_id // empty' "$out")"
  RESULT="$(jq -r '.result // empty' "$out")"
  COST_TOTAL="$(jq -r --arg prev "${COST_TOTAL:-0}" '(.total_cost_usd // 0) + ($prev|tonumber)' "$out")"
  echo "turn $n cost: $(jq -r '.total_cost_usd' "$out") USD" >> "$FIX/logs/cost.log"
}

# start_ritual <session-fixture-name>: turn 1, Glody closes the session.
start_ritual() {
  local transcript="$EVAL_DIR/fixtures/sessions/$1.md"
  SESSION_ID=""; COST_TOTAL=0
  run_turn 1 "You are at the end of a working session with Glody. The full transcript of that session is in $transcript: treat it as the session you just worked in.

Glody now says: \"retrospettiva sessione\".

Run the session-retrospective ritual: read $FIX/skill/SKILL.md and follow it exactly.

Environment of this run:
- The brain vault is $FIX/vault (a git repo). The installed skills are in $FIX/skills.
- Google Calendar is reachable only through the command gcal-event (on PATH): gcal-event create --title \"...\" --start \"YYYY-MM-DDTHH:MM\" --description \"...\". There is no calendar MCP.
- python3 on PATH has PyYAML.
- Glody reads your final message and may answer in a follow-up message."
}

# reply <text>: Glody answers in a follow-up turn.
reply() {
  local n=$(( $(ls "$FIX"/logs/turn-*.json | wc -l) + 1 ))
  run_turn "$n" "$1"
}

# ---- effect probes -------------------------------------------------------------
# Every path that differs from the fixture commit, committed or not, plus new files.
# (A run may commit in the vault: `git status` alone would read that as "nothing written".)
vault_changes() {
  git -C "$FIX/vault" diff --name-status "$VAULT_BASE"
  git -C "$FIX/vault" ls-files --others --exclude-standard | sed 's/^/??\t/'
}
neighbors_runs()     { [ -f "$FIX/logs/show-neighbors.log" ] && wc -l < "$FIX/logs/show-neighbors.log" | tr -d ' ' || echo 0; }
calendar_events()    { [ -f "$FIX/logs/calendar.log" ] && wc -l < "$FIX/logs/calendar.log" | tr -d ' ' || echo 0; }
queue_len() {
  (cd "$FIX/vault/areas/ai-automation/autonomous-agents" && "$(eval_python)" -B -c '
import sys, queue_parser
print(len(queue_parser.parse_queue(open(sys.argv[1], encoding="utf-8").read())))' \
    "$FIX/vault/areas/ai-automation/build-queue.md")
}

# dump_evidence: print what the run did, so a failing test explains itself.
dump_evidence() {
  echo "--- fixture: $FIX  mutant: ${EVAL_MUTANT:-none}  model: $EVAL_MODEL"
  echo "--- show-neighbors runs: $(neighbors_runs)  calendar events: $(calendar_events)"
  echo "--- vault changes:"; vault_changes
  echo "--- cost:"; cat "$FIX/logs/cost.log" 2>/dev/null
  local f
  for f in "$FIX"/logs/turn-*.json; do
    echo "--- $(basename "$f") result:"; jq -r '.result // .' "$f"
  done
}
