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

@test "finds principles in the .brain/ layout (post L2 migration)" {
  mkdir -p "$VAULT/.brain"
  mv "$VAULT/principles" "$VAULT/memory" "$VAULT/.brain/"
  run "$CLI" --vault "$VAULT" --skills "$SKILLS" "design review gate su una nuova spec"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q ".brain/principles/engineering-lessons.md"
}

@test "warns on stderr when a perimeter source is missing" {
  rm -rf "$VAULT/principles"
  run "$CLI" --vault "$VAULT" --skills "$SKILLS" "design review gate su una nuova spec"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "attenzione.*principles"
}

@test "warns on stderr when the vault itself does not exist" {
  run "$CLI" --vault "$VAULT/nope" --skills "$SKILLS" "cattura veloce di una nota vault"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "attenzione.*vault"
}

@test "requires a spark argument" {
  run "$CLI" --vault "$VAULT" --skills "$SKILLS"
  [ "$status" -ne 0 ]
}

# --- defaults without explicit flags (Cloud / worktree portability) ---------
# Without --vault/--skills the CLI must not assume the Mac layout: it detects the
# vault from the cwd (walking up to the checkout root) and, when ~/.claude/skills
# is absent, reads the skills nested in the vault's claude-skills repo.

_vault_checkout() {
  # Turn $VAULT into a .brain/ layout git checkout with nested claude-skills.
  mkdir -p "$VAULT/.brain"
  mv "$VAULT/principles" "$VAULT/memory" "$VAULT/.brain/"
  mkdir -p "$VAULT/areas/ai-automation/skills/claude-skills"
  mv "$SKILLS/quick-capture" "$VAULT/areas/ai-automation/skills/claude-skills/"
  git -C "$VAULT" init -q
  FAKE_HOME="$(mktemp -d)"
}

@test "without --vault, detects the vault from a cwd inside the checkout" {
  _vault_checkout
  cd "$VAULT/areas/affitti-brevi"
  run env HOME="$FAKE_HOME" "$CLI" "design review gate su una nuova spec"
  rm -rf "$FAKE_HOME"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q ".brain/principles/engineering-lessons.md"
  ! echo "$output" | grep -qi "attenzione.*vault"
}

@test "without --skills and no ~/.claude/skills, reads the nested claude-skills" {
  _vault_checkout
  cd "$VAULT"
  run env HOME="$FAKE_HOME" "$CLI" "cattura veloce di una nota vault"
  rm -rf "$FAKE_HOME"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "quick-capture"
  ! echo "$output" | grep -qi "attenzione.*skills"
}

@test "without --vault, a cwd outside any vault falls back to ~/Documents/brain" {
  _vault_checkout
  mkdir -p "$FAKE_HOME/Documents"
  ln -s "$VAULT" "$FAKE_HOME/Documents/brain"
  OUTSIDE="$(mktemp -d)"
  cd "$OUTSIDE"
  run env HOME="$FAKE_HOME" "$CLI" "design review gate su una nuova spec"
  rm -rf "$FAKE_HOME" "$OUTSIDE"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "engineering-lessons.md"
}

@test "an installed ~/.claude/skills still wins over the nested repo" {
  _vault_checkout
  mkdir -p "$FAKE_HOME/.claude/skills/rito-locale"
  printf -- '---\nname: rito-locale\ndescription: helm chart rollout canary kubernetes\n---\n' \
    > "$FAKE_HOME/.claude/skills/rito-locale/SKILL.md"
  cd "$VAULT"
  run env HOME="$FAKE_HOME" "$CLI" "kubernetes helm chart rollout canary"
  rm -rf "$FAKE_HOME"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "rito-locale"
}
