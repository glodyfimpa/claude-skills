#!/usr/bin/env bats
# Test suite per le skill Bureaucratic Research Assistant (BRA):
#   - pa-data-vault
#   - pa-form-filler (core + id-mapper + checkpoint)
#   - pa-legal-clause-analyzer

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# ──────────────────────────────────────────────────────────────────────────────
# pa-data-vault
# ──────────────────────────────────────────────────────────────────────────────

@test "pa-data-vault: SKILL.md esiste con frontmatter valido" {
  skill_file="$REPO_ROOT/pa-data-vault/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "^name:" "$skill_file"
  grep -q "^description:" "$skill_file"
}

@test "pa-data-vault: references/personal/glody.md esiste" {
  [ -f "$REPO_ROOT/pa-data-vault/references/personal/glody.md" ]
}

@test "pa-data-vault: references/bnb-via-braida/structure.md esiste" {
  [ -f "$REPO_ROOT/pa-data-vault/references/bnb-via-braida/structure.md" ]
}

@test "pa-data-vault: caricamento reference esistente restituisce dati" {
  profile="$REPO_ROOT/pa-data-vault/references/personal/glody.md"
  # Verifica che contenga almeno una chiave: valore nel code-fence
  grep -q "nome:" "$profile"
  grep -q "email:" "$profile"
}

@test "pa-data-vault: detection campi [da completare] nel profilo" {
  profile="$REPO_ROOT/pa-data-vault/references/personal/glody.md"
  # Il profilo deve avere campi da completare (è uno scaffold intenzionale)
  grep -q "\[da completare\]" "$profile"
  # E il SKILL.md deve documentare la detection
  grep -q "da completare" "$REPO_ROOT/pa-data-vault/SKILL.md"
}

@test "pa-data-vault: errore controllato su profilo inesistente" {
  # Verifica che SKILL.md documenti l'error handling per profilo non trovato
  grep -q "non trovato\|not found\|Profili disponibili" "$REPO_ROOT/pa-data-vault/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# pa-form-filler (core + id-mapper + checkpoint)
# ──────────────────────────────────────────────────────────────────────────────

@test "pa-form-filler: SKILL.md esiste con frontmatter valido" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "^name:" "$skill_file"
  grep -q "^description:" "$skill_file"
}

@test "pa-form-filler: portals-catalog.yaml esiste con almeno 2 entry" {
  catalog="$REPO_ROOT/pa-form-filler/references/portals-catalog.yaml"
  [ -f "$catalog" ]
  entry_count=$(grep -c "^  [a-zA-Z]" "$catalog")
  [ "$entry_count" -ge 2 ]
}

@test "pa-form-filler: workflow FAQ PDF scan documentato in SKILL.md" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "FAQ" "$skill_file"
  grep -q "pdftotext" "$skill_file"
  grep -q "obbligatori" "$skill_file"
}

@test "pa-form-filler: browser adapter fallback Playwright→Chrome→Computer Use documentato" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "Playwright" "$skill_file"
  grep -q "Chrome" "$skill_file"
  grep -q "Computer Use" "$skill_file"
  grep -q "fallback" "$skill_file"
}

@test "pa-form-filler id-mapper: strategia label-first documentata" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "Label-First\|label-first" "$skill_file"
  grep -q "for=" "$skill_file"
}

@test "pa-form-filler id-mapper: catalog fallback documentato" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "Catalog Fallback\|catalog fallback" "$skill_file"
  grep -q "portals-catalog.yaml" "$skill_file"
}

@test "pa-form-filler id-mapper: auto-save regola nuova nel YAML" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "Auto-Save\|auto-save\|auto_save" "$skill_file"
  # Verifica che il catalog YAML sia scrivibile (test di smoke)
  catalog="$REPO_ROOT/pa-form-filler/references/portals-catalog.yaml"
  [ -w "$catalog" ]
}

@test "pa-form-filler checkpoint: schema file ~/.claude/pa-checkpoints/{portale}-{YYYY-MM-DD}.json documentato" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "pa-checkpoints" "$skill_file"
  grep -q "YYYY-MM-DD" "$skill_file"
}

@test "pa-form-filler checkpoint: trigger save ogni cambio pagina + ogni 5 campi documentato" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "cambio pagina\|ogni 5" "$skill_file"
}

@test "pa-form-filler checkpoint: detection HTTP 401 e redirect login documentata" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "401" "$skill_file"
  grep -q "redirect\|login" "$skill_file"
}

@test "pa-form-filler checkpoint: cleanup automatico post-submit documentato" {
  skill_file="$REPO_ROOT/pa-form-filler/SKILL.md"
  grep -q "Cleanup\|cleanup\|Elimina\|eliminato" "$skill_file"
  grep -q "submit" "$skill_file"
}

# ──────────────────────────────────────────────────────────────────────────────
# pa-legal-clause-analyzer
# ──────────────────────────────────────────────────────────────────────────────

@test "pa-legal-clause-analyzer: SKILL.md esiste con frontmatter valido" {
  skill_file="$REPO_ROOT/pa-legal-clause-analyzer/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "^name:" "$skill_file"
  grep -q "^description:" "$skill_file"
}

@test "pa-legal-clause-analyzer: input multipli (URL, PDF locale, testo) documentati" {
  skip "pending — implementazione in t1778606943948"
}

@test "pa-legal-clause-analyzer: pattern normativi (art. X, comma Y D.L. Z/YYYY) documentati" {
  skip "pending — implementazione in t1778606943948"
}

@test "pa-legal-clause-analyzer: cross-check profilo pa-data-vault documentato" {
  skip "pending — implementazione in t1778606943948"
}

@test "pa-legal-clause-analyzer: output tabella markdown con colonne Clausola/Obbligatoria?/Norma/Valore suggerito" {
  skip "pending — implementazione in t1778606943948"
}

@test "pa-legal-clause-analyzer: limite cita solo norme presenti nel documento documentato" {
  skip "pending — implementazione in t1778606943948"
}
