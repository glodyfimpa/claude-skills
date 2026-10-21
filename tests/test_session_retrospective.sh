#!/usr/bin/env bats
# Contract tests for session-retrospective/SKILL.md (the one-question rite).
# The skill is prose judged by an agent, so these tests pin the load-bearing
# contract only: the single question with "nothing" as default outcome, the
# written self-check before the neighbor-finder, the neighbor-finder outcomes,
# the three destinations, and the frontmatter triggers.
# Behavior of the neighbor-finder CLI itself lives in
# session-retrospective/tests/test_show_neighbors.bats.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SKILL_DIR="$REPO_ROOT/session-retrospective"
SKILL_FILE="$SKILL_DIR/SKILL.md"

# Prints a section from its heading line (exclusive) to the next heading of the
# same or higher level. Usage: section_block "## Passo 2" | section_block "### Ramo LEZIONE"
section_block() {
  local heading="$1"
  local level="${heading%% *}"
  awk -v h="$heading" -v lvl="$level" '
    index($0, h) == 1 { in_block=1; next }
    in_block {
      if (match($0, /^#+ /)) {
        cur = substr($0, 1, RLENGTH - 1)
        if (length(cur) <= length(lvl)) exit
      }
      print
    }
  ' "$SKILL_FILE"
}

# Same block joined on one line, for phrases that wrap across lines in the prose.
flat_block() {
  section_block "$1" | tr '\n' ' ' | tr -s ' '
}

# ──────────────────────────────────────────────────────────────────────────────
# Frontmatter: name and triggers (no silent breaking change on activation)
# ──────────────────────────────────────────────────────────────────────────────

@test "Frontmatter: name and current description opening preserved" {
  grep -q "^name: session-retrospective$" "$SKILL_FILE"
  grep -qF "Rito di fine sessione, una domanda sola" "$SKILL_FILE"
  grep -qF '"/session-retrospective"' "$SKILL_FILE"
}

# ──────────────────────────────────────────────────────────────────────────────
# The single question, default outcome "nothing"
# ──────────────────────────────────────────────────────────────────────────────

@test "Rite: one question, and 'niente' is the declared normal outcome" {
  grep -qF "È successo qualcosa di raro che cambia il domani in meglio?" "$SKILL_FILE"
  grep -qE "esito normale.{0,10}NIENTE" "$SKILL_FILE"
}

@test "Passo 1: no spark or failed self-check closes with the explicit sentence" {
  block="$(flat_block "## Passo 1")"
  echo "$block" | grep -qF "Niente di raro da salvare oggi."
  echo "$block" | grep -qiE "non procedere al mostra-vicini"
}

@test "Passo 1: self-check is written BEFORE running the neighbor-finder" {
  block="$(section_block "## Passo 1")"
  echo "$block" | grep -qiE "self-check obbligatorio"
  echo "$block" | grep -qE "PRIMA di eseguire il mostra-vicini"
}

# ──────────────────────────────────────────────────────────────────────────────
# Passo 2: neighbor-finder (replaces the old 'npx skills find' coverage check)
# ──────────────────────────────────────────────────────────────────────────────

@test "Passo 2: invokes show-neighbors by absolute path, and that CLI exists in the repo" {
  block="$(section_block "## Passo 2")"
  echo "$block" | grep -qF "~/.claude/skills/session-retrospective/bin/show-neighbors"
  [ -x "$SKILL_DIR/bin/show-neighbors" ]
}

@test "Passo 2: neighbor outcomes map to new / merge / already covered" {
  block="$(section_block "## Passo 2")"
  echo "$block" | grep -qF '"nessun vicino"'
  echo "$block" | grep -qiE "fondi/aggiorna quel file"
  echo "$block" | grep -qiE "già coperta, non salvare"
}

@test "Passo 2: a missing perimeter source means 'no neighbors' proves nothing" {
  block="$(section_block "## Passo 2")"
  echo "$block" | grep -qF "non trovato nel"
  echo "$block" | grep -qE "NON prova che la scintilla sia nuova"
}

# ──────────────────────────────────────────────────────────────────────────────
# Passo 3: three outcomes, each with its destination; nothing is parked
# ──────────────────────────────────────────────────────────────────────────────

@test "Passo 3: three outcomes with their destinations, undecided is not parked" {
  block="$(section_block "## Passo 3")"
  echo "$block" | grep -qE "LEZIONE.*"
  echo "$block" | grep -qF ".brain/principles/"
  echo "$block" | grep -qE "SEME-DI-STRUMENTO forma-A"
  echo "$block" | grep -qF "build-queue.md"
  echo "$block" | grep -qE "SERVE-LA-TUA-TESTA"
  echo "$block" | grep -qiE "APPUNTAMENTO in calendario"
  echo "$block" | grep -qF "NON si parcheggia"
}

@test "Ramo LEZIONE: diff shown to Glody before writing, applied only on confirmation" {
  block="$(section_block "### Ramo LEZIONE")"
  echo "$block" | grep -qE "Mostra il diff"
  echo "$block" | grep -qE "prima di scrivere"
  echo "$block" | grep -qE "solo su conferma"
}

@test "Ramo SEME-STRUMENTO: queue XOR calendar, 'added' left to append_voice" {
  block="$(flat_block "### Ramo SEME-STRUMENTO")"
  echo "$block" | grep -qF "queue_parser.append_voice"
  echo "$block" | grep -qF "coda XOR calendario"
  echo "$block" | grep -qE "Il campo \`added\`.*auto-compila"
}
