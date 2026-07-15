#!/usr/bin/env bats
# Integration tests for bin/show-neighbors: build a tiny fake vault + skills dir,
# run the CLI with a spark, assert the neighbors it surfaces (and the "no neighbors"
# path). The CLI is the thin shell the SKILL.md rite invokes.

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
  CLI="$DIR/bin/show-neighbors"
  VAULT="$(mktemp -d)"
  SKILLS="$(mktemp -d)"

  mkdir -p "$VAULT/principles" "$VAULT/memory" "$VAULT/areas/affitti-brevi"
  cat > "$VAULT/principles/engineering-lessons.md" <<'EOF'
# Engineering lessons
- design review gate come varco d'entrata sulle spec
EOF
  cat > "$VAULT/memory/MEMORY.md" <<'EOF'
- [Verify-before-react](feedback_verify.md) — guarda il dato osservabile, non stimare
EOF
  cat > "$VAULT/areas/affitti-brevi/CLAUDE.md" <<'EOF'
# Affitti brevi
- messaggi agli ospiti da fonte ufficiale, mai a sensazione
EOF

  mkdir -p "$SKILLS/quick-capture"
  cat > "$SKILLS/quick-capture/SKILL.md" <<'EOF'
---
name: quick-capture
description: cattura veloce di una nota in inbox del vault
---
# Quick Capture
EOF
}

teardown() { rm -rf "$VAULT" "$SKILLS"; }

@test "surfaces the matching principle for a design-review spark" {
  run "$CLI" --vault "$VAULT" --skills "$SKILLS" "design review gate su una nuova spec"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "engineering-lessons.md"
}

@test "surfaces the matching skill for a capture spark" {
  run "$CLI" --vault "$VAULT" --skills "$SKILLS" "cattura veloce di una nota vault"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "quick-capture"
}

@test "prints a clear 'no neighbors' line when nothing overlaps" {
  run "$CLI" --vault "$VAULT" --skills "$SKILLS" "kubernetes helm chart rollout canary"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "nessun vicino"
}

@test "requires a spark argument" {
  run "$CLI" --vault "$VAULT" --skills "$SKILLS"
  [ "$status" -ne 0 ]
}
