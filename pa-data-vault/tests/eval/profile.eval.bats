#!/usr/bin/env bats
# Contract evals for pa-data-vault: what an agent following SKILL.md does with a profile.
#
# GIVEN a fake profile (fixtures/personal/glody.md, invented values, same structure as the
# real gitignored profile), WHEN a fresh headless Claude follows SKILL.md for a request,
# THEN we check EFFECTS only: values in the answer, the missing-field list, the profile
# file diff. Never the skill's wording.
#
# Model-backed, so skipped unless RUN_EVALS=1:
#   RUN_EVALS=1 bats pa-data-vault/tests/eval/profile.eval.bats
# Knobs: EVAL_MODEL (default sonnet), EVAL_KEEP=1 keeps the fixture dir.
# RED: EVAL_MUTANT=<name> runs the same test against a broken SKILL.md (see mutate.py).
#
# Not covered: "asks Glody to fill the missing fields". SKILL.md only promises to return
# the list, so no test asserts the asking.

load lib

setup() { require_eval_env; make_fixture; }

teardown() {
  [ -n "${FIX:-}" ] || return 0
  dump_evidence >&3 2>/dev/null || true
  [ "${EVAL_KEEP:-0}" = "1" ] || rm -rf "$FIX"
}

# Mutant that must turn it red: values-withheld
@test "contract a: another PA skill asks for stored fields -> the answer carries the profile's values" {
  ask "The pa-form-filler skill needs two fields from the profile personal/glody: cognome and pec. Reply with their values."
  echo "$RESULT" | grep -q "Quagliarello"
  echo "$RESULT" | grep -q "m.quagliarello@pec.example.invalid"
  [ -z "$(changed_paths)" ]
}

# Mutant that must turn it red: placeholders-hidden
@test "contract b: missing-field request -> exactly the [da completare] fields are reported" {
  ask "List the missing fields of the profile personal/glody."
  for k in codice_fiscale partita_iva iban_tasse portale_username portale_codice_operatore; do
    echo "$RESULT" | grep -q "$k"
  done
  # Fields that already hold a value must not be reported as missing.
  for k in luogo_nascita regime_fiscale comune_residenza telefono; do
    ! echo "$RESULT" | grep -q "$k"
  done
  [ -z "$(changed_paths)" ]
}

# Mutant that must turn it red: append-instead-of-replace
@test "contract c: new value for a missing field -> only that line of the profile changes, in place" {
  ask "Glody gives you the value of codice_fiscale for the profile personal/glody: VALORE-DI-PROVA-123. Save it."
  [ "$(changed_paths)" = "references/personal/glody.md" ]
  [ "$(profile_numstat)" = "$(printf '1\t1')" ]
  [ "$(profile_diff)" = "$(printf -- '-codice_fiscale: [da completare]\n+codice_fiscale: VALORE-DI-PROVA-123')" ]
}
