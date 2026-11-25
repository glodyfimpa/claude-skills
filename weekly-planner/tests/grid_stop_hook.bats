#!/usr/bin/env bats
# Tests for bin/grid-stop-hook, the Stop hook that refuses a weekly-planner gate
# message presented without the fenced ASCII calendar (SKILL.md, Phase 3).
# Contract: read the Stop hook JSON on stdin; to block, print
# {"decision": "block", "reason": ...} on stdout and exit 0; to allow, print nothing.

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
  # Invoked through python3, as in the settings.json wiring: no reliance on the
  # executable bit surviving a sync or a checkout.
  HOOK_PATH="$DIR/bin/grid-stop-hook"
  FIX="$DIR/tests/fixtures"
  TMP="$(mktemp -d)"
}

teardown() { rm -rf "$TMP"; }

_hook() { python3 "$HOOK_PATH"; }

# Feed the hook a Stop input pointing at transcript $1; $2 = stop_hook_active.
_run_hook() {
  local active="${2:-false}"
  printf '{"session_id":"bc9dc60c","transcript_path":"%s","hook_event_name":"Stop","stop_hook_active":%s}' \
    "$1" "$active" > "$TMP/input.json"
  run _hook < "$TMP/input.json"
}

# Transcript with the skill loaded and a final assistant text of $1 (JSON-escaped).
_transcript_with_last() {
  head -n 4 "$FIX/gate-no-grid.jsonl" > "$TMP/t.jsonl"
  printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"%s"}]}}\n' \
    "$1" >> "$TMP/t.jsonl"
}

@test "blocks the 09:38 gate message that has no ASCII grid" {
  _run_hook "$FIX/gate-no-grid.jsonl"
  [ "$status" -eq 0 ] || return 1
  echo "$output" | grep -q '"decision": "block"' || return 1
  echo "$output" | grep -qi 'griglia' || return 1
}

@test "lets through the 09:56 gate message with the fenced grid" {
  _run_hook "$FIX/gate-with-grid.jsonl"
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "ignores sessions that never loaded the weekly-planner skill" {
  grep -v 'weekly-planner' "$FIX/gate-no-grid.jsonl" > "$TMP/t.jsonl"
  _run_hook "$TMP/t.jsonl"
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "ignores a last message that is not the gate" {
  _transcript_with_last 'Ho letto il consuntivo, passo alla raccolta delle email.'
  _run_hook "$TMP/t.jsonl"
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "a message saying 'come proposto' counts as the gate" {
  _transcript_with_last 'Procedo come proposto? LUN focus, MAR handoff, MER reminder.'
  _run_hook "$TMP/t.jsonl"
  echo "$output" | grep -q '"decision": "block"' || return 1
}

@test "a fenced block with only two day headings is not a grid" {
  _transcript_with_last 'Proposta:\n```\nLUN  focus\nMAR  handoff\n```\nDimmi OK per applicarlo al calendario.'
  _run_hook "$TMP/t.jsonl"
  echo "$output" | grep -q '"decision": "block"' || return 1
}

@test "day headings outside a fenced block do not count" {
  _transcript_with_last 'LUN focus, MAR handoff, MER reminder, GIO design, VEN libero. Dimmi OK per applicarlo al calendario.'
  _run_hook "$TMP/t.jsonl"
  echo "$output" | grep -q '"decision": "block"' || return 1
}

@test "a tilde fence with three lowercase day headings is a grid" {
  _transcript_with_last 'Proposta:\n~~~\n        lun   mar   mer\nmattina [+]   .     [=]\n~~~\nDimmi OK per applicarlo al calendario.'
  _run_hook "$TMP/t.jsonl"
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "detects the skill loaded by the /weekly-planner slash command" {
  printf '%s\n' '{"type":"user","message":{"role":"user","content":"<command-name>/weekly-planner</command-name>"}}' > "$TMP/t.jsonl"
  tail -n 2 "$FIX/gate-no-grid.jsonl" >> "$TMP/t.jsonl"
  _run_hook "$TMP/t.jsonl"
  echo "$output" | grep -q '"decision": "block"' || return 1
}

@test "detects the plugin-namespaced skill life-os:weekly-planner" {
  printf '%s\n' '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Skill","input":{"skill":"life-os:weekly-planner"}}]}}' > "$TMP/t.jsonl"
  tail -n 2 "$FIX/gate-no-grid.jsonl" >> "$TMP/t.jsonl"
  _run_hook "$TMP/t.jsonl"
  echo "$output" | grep -q '"decision": "block"' || return 1
}

@test "a skill name merely mentioned in text does not count as loaded" {
  printf '%s\n' '{"type":"user","message":{"role":"user","content":"la skill weekly-planner ha un bug"}}' > "$TMP/t.jsonl"
  tail -n 2 "$FIX/gate-no-grid.jsonl" >> "$TMP/t.jsonl"
  _run_hook "$TMP/t.jsonl"
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "prefers last_assistant_message from the input when present" {
  printf '{"transcript_path":"%s","stop_hook_active":false,"last_assistant_message":"Dimmi OK per applicarlo al calendario."}' \
    "$FIX/gate-with-grid.jsonl" > "$TMP/input.json"
  run _hook < "$TMP/input.json"
  echo "$output" | grep -q '"decision": "block"' || return 1
}

@test "does not block twice in a row (stop_hook_active)" {
  _run_hook "$FIX/gate-no-grid.jsonl" true
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "fails open on a missing transcript" {
  _run_hook "$TMP/nope.jsonl"
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "fails open on garbage stdin" {
  run _hook <<< 'not json'
  [ "$status" -eq 0 ] || return 1
  [ -z "$output" ] || return 1
}

@test "skips malformed transcript lines instead of crashing" {
  { echo '{broken'; cat "$FIX/gate-no-grid.jsonl"; } > "$TMP/t.jsonl"
  _run_hook "$TMP/t.jsonl"
  echo "$output" | grep -q '"decision": "block"' || return 1
}
