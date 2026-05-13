#!/usr/bin/env bats
# Test suite per session-retrospective/SKILL.md.
# Verifica i pattern testuali introdotti dal fix degli anti-pattern emersi
# nella retro 2026-05-13:
#   1. Phase 1.7 imperativa con bash command esplicito + tabella decisionale
#   2. Nuova Phase 3.5 Self-evaluation gate prima di Phase 4
#   3. Phase 4 con single-confirmation default + menu 3-opzioni come eccezione

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SKILL_FILE="$REPO_ROOT/session-retrospective/SKILL.md"

# Helper: estrae il blocco testuale di una Phase data, fino alla prossima ### Phase
# Usage: phase_block <phase_id>   e.g. phase_block "1.7"
phase_block() {
  local phase_id="$1"
  awk -v ph="### Phase $phase_id" '
    $0 ~ "^" ph { in_block=1; next }
    in_block && /^### Phase / { exit }
    in_block { print }
  ' "$SKILL_FILE"
}

# ──────────────────────────────────────────────────────────────────────────────
# Phase 1.7 — imperative bash command + decision table
# ──────────────────────────────────────────────────────────────────────────────

@test "Phase 1.7: comando 'npx skills find' presente e marcato REQUIRED" {
  block="$(phase_block "1.7")"
  echo "$block" | grep -q "npx skills find"
  echo "$block" | grep -q "REQUIRED"
}

@test "Phase 1.7: tabella decisionale markdown coverage→azione presente" {
  block="$(phase_block "1.7")"
  # La tabella decisionale ha header con pipe + righe con pipe.
  # Header atteso include "Coverage" e "Azione" (o "Action").
  echo "$block" | grep -qE "\|.*[Cc]overage.*\|"
  echo "$block" | grep -qiE "\|.*(azione|action).*\|"
  # Almeno una riga della tabella con discard silently
  echo "$block" | grep -qE "\|.*discard silently.*\|"
}

@test "Phase 1.7: partial coverage 50–89% in riga di tabella con regola 'extend' senza alternativa standalone" {
  block="$(phase_block "1.7")"
  # Estrae righe-tabella (con | iniziale o intermedio) che contengono 50 + 89
  partial_rows="$(echo "$block" | grep -E "\|.*50.{0,5}89.*\|")"
  [ -n "$partial_rows" ]
  # La riga deve contenere "extend" o "estendi"
  echo "$partial_rows" | grep -qiE "extend|estendi"
}

# ──────────────────────────────────────────────────────────────────────────────
# Phase 3.5 — Self-evaluation gate (nuova sezione)
# ──────────────────────────────────────────────────────────────────────────────

@test "Phase 3.5: sezione Self-evaluation gate esiste con header ### Phase 3.5" {
  grep -q "^### Phase 3.5" "$SKILL_FILE"
  block="$(phase_block "3.5")"
  echo "$block" | grep -qiE "self.?eval"
}

@test "Phase 3.5: 5 euristiche deterministiche con condizioni chiave" {
  block="$(phase_block "3.5")"
  # ≥2 occorrenze
  echo "$block" | grep -qE "≥2 occorrenze|≥2 occurrences"
  # 1 occorrenza
  echo "$block" | grep -qE "1 occorrenza|1 occurrence"
  # ≥90% coverage
  echo "$block" | grep -qE "≥90%"
  # partial coverage 50-89%
  echo "$block" | grep -qE "50.?89%|partial coverage"
  # ≥3 in sessione singola
  echo "$block" | grep -qE "≥3"
}

@test "Phase 3.5: prescrive 'procedi a Phase 4 SOLO con create_now o save_idea'" {
  block="$(phase_block "3.5")"
  echo "$block" | grep -qiE "Phase 4 SOLO|only.*Phase 4"
  echo "$block" | grep -q "create_now"
  echo "$block" | grep -q "save_idea"
}

# ──────────────────────────────────────────────────────────────────────────────
# Phase 4 — single-confirmation default + menu come eccezione
# ──────────────────────────────────────────────────────────────────────────────

@test "Phase 4: clausola single-confirmation come default presente" {
  block="$(phase_block "4")"
  echo "$block" | grep -qiE "single.?confirmation|una conferma|single confirmation"
}

@test "Phase 4: riferimento esplicito a feedback_retro_no_menu_theater.md (memory file)" {
  block="$(phase_block "4")"
  echo "$block" | grep -qF "feedback_retro_no_menu_theater"
}

@test "Phase 4: menu 3-opzioni dichiarato come caso eccezionale, non default" {
  block="$(phase_block "4")"
  echo "$block" | grep -qiE "caso eccezionale|exceptional case|exception"
}

# ──────────────────────────────────────────────────────────────────────────────
# Frontmatter invariato — no breaking change su trigger
# ──────────────────────────────────────────────────────────────────────────────

@test "Frontmatter: name e prima riga description preservati" {
  # name: session-retrospective
  grep -q "^name: session-retrospective$" "$SKILL_FILE"
  # description multi-line con la frase di apertura originale
  grep -qF "Analyzes the current session to identify repetitive patterns" "$SKILL_FILE"
}
