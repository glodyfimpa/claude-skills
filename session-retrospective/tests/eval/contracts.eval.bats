#!/usr/bin/env bats
# Contract evals for the session-retrospective ritual (the judgment around show-neighbors).
#
# Each test is GIVEN a fixture session + fixture vault, WHEN a fresh headless Claude
# runs the ritual from SKILL.md, THEN it checks EFFECTS only: files written in the
# fixture vault (git status), whether bin/show-neighbors ran (wrapper log), entries in
# build-queue.md (parsed and validated by the real queue_parser), calendar events
# (gcal-event stub log). It never greps the skill's wording.
#
# These tests cost model calls, so they are skipped unless RUN_EVALS=1. Run:
#   RUN_EVALS=1 bats session-retrospective/tests/eval/contracts.eval.bats
#   RUN_EVALS=1 bats -f 'contract a' session-retrospective/tests/eval/contracts.eval.bats
# Knobs: EVAL_MODEL (default sonnet), EVAL_PYTHON (python3 with PyYAML),
#        EVAL_QUEUE_PARSER (default ~/Documents/brain/.../autonomous-agents/queue_parser.py),
#        EVAL_KEEP=1 keeps the fixture dir for inspection.
#
# RED: EVAL_MUTANT=<name> runs the same test against a deliberately broken SKILL.md
# (see mutate.py). Each test names the mutant that must make it fail:
#   EVAL_MUTANT=always-a-spark RUN_EVALS=1 bats -f 'contract a' ...
#
# Seams: Google Calendar is replaced by the gcal-event CLI stub (the skill names no
# calendar tool, so the run is told in its prompt that gcal-event is the calendar).
# Glody's confirmation is a follow-up turn on the same session (claude -p --resume).
# A run that calls neighbors.py directly instead of bin/show-neighbors is not logged.

load lib

setup_file() { require_eval_env; }

setup() {
  require_eval_env
  make_fixture
}

teardown() {
  [ -n "${FIX:-}" ] || return 0
  dump_evidence >&3 2>/dev/null || true
  [ "${EVAL_KEEP:-0}" = "1" ] || rm -rf "$FIX"
}

# Mutant that must turn it red: always-a-spark
@test "contract a: session without a spark -> outcome niente, nothing written, show-neighbors not run" {
  start_ritual a-ordinary
  [ "$(neighbors_runs)" = "0" ]
  [ -z "$(vault_changes)" ]
  [ "$(queue_len)" = "$QUEUE_BEFORE" ]
  [ "$(calendar_events)" = "0" ]
  echo "$RESULT" | grep -qi "niente"
}

# Mutant that must turn it red: neighbors-before-self-check
@test "contract b: episode repeated only inside the session fails the self-check -> show-neighbors not run, nothing written" {
  start_ritual b-vivid-repeat
  [ "$(neighbors_runs)" = "0" ]
  [ -z "$(vault_changes)" ]
  [ "$(queue_len)" = "$QUEUE_BEFORE" ]
  [ "$(calendar_events)" = "0" ]
}

# Mutant that must turn it red: save-even-if-covered
@test "contract c (full cover): an installed skill covers the spark -> no write, one 'già coperta' line" {
  start_ritual c-covered-tool
  [ "$(neighbors_runs)" -ge 1 ]
  [ -z "$(vault_changes)" ]
  [ "$(queue_len)" = "$QUEUE_BEFORE" ]
  [ "$(calendar_events)" = "0" ]
  echo "$RESULT" | grep -qiE "gi(à|a') coperta"
}

# Mutant that must turn it red: new-file-always
@test "contract c (partial cover): a strong neighbor -> after confirmation only that file changes, no new file" {
  start_ritual c-partial-lesson
  [ "$(neighbors_runs)" -ge 1 ]
  reply "Confermo, applica."
  run vault_changes
  [ "$output" = "$(printf 'M\t.brain/principles/engineering-lessons.md')" ]
}

# Mutant that must turn it red: write-without-confirm
@test "contract d: LEZIONE branch -> diff shown and nothing written before confirmation; written after" {
  start_ritual d-new-lesson
  [ "$(neighbors_runs)" -ge 1 ]
  [ -z "$(vault_changes)" ]
  echo "$RESULT" | grep -qE '^[[:space:]>`]*[+~]'
  reply "Confermo, applica."
  [ -n "$(vault_changes)" ]
}

# Mutant that must turn it red: both-channels
@test "contract e (forma-A): headless-buildable seed -> one valid queue entry, no calendar event" {
  start_ritual e1-forma-a-tool
  if [ "$(queue_len)" = "$QUEUE_BEFORE" ] && [ "$(calendar_events)" = "0" ]; then
    reply "Sì, procedi."
  fi
  # queue_len parses with queue_parser.parse_queue, which validates every voice.
  [ "$(queue_len)" = "$((QUEUE_BEFORE + 1))" ]
  [ "$(calendar_events)" = "0" ]
}

# Mutant that must turn it red: both-channels
@test "contract e (needs your head): seed needing login/judgment -> calendar event, no queue entry" {
  start_ritual e2-needs-your-head
  if [ "$(queue_len)" = "$QUEUE_BEFORE" ] && [ "$(calendar_events)" = "0" ]; then
    reply "Sì, procedi."
  fi
  [ "$(calendar_events)" -ge 1 ]
  [ "$(queue_len)" = "$QUEUE_BEFORE" ]
}
