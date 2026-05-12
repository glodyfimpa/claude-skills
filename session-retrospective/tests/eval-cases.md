# Eval Cases — session-retrospective (Phase 1.7)

These cases are the spec for Phase 1.7 of the session-retrospective skill: the `/find-skills` cross-check
that verifies a candidate skill does not already exist locally before proposing it to the user.

Each case has:
- **Setup**: what emerged from the session scan, and what `/find-skills` returns
- **Expected**: what Claude must do in response
- **Pass criterion**: how to verify the skill contains this behavior

Run a manual eval by reading `SKILL.md` and checking each case against the Phase 1.7 guidance.
A case fails when the skill is missing the expected behavior or contains contradicting guidance.

---

## TC-01 — Exact skill match → discard silently

**Setup**

Phase 1 identifies a multi-step sequence: the user exported documents from Notion, uploaded them to Drive,
and extracted metadata into CSV. Claude proposes the candidate: `document-exporter`.

`/find-skills` returns a high-confidence match: the `document-collector` skill covers exactly that
sequence (Notion export → Drive upload → metadata extraction). Estimated coverage: 95%+.

**Expected**

Claude silently discards the candidate. It is not mentioned in the final report. The user is not asked
what to do. The Phase 3 report only lists candidates that passed the cross-check.

**Pass criterion**

SKILL.md Phase 1.7 contains an explicit rule: if the match exceeds a coverage threshold (e.g. ≥90%),
the candidate is discarded without appearing in the report. The threshold must be declared numerically.

---

## TC-02 — Partial coverage (~70%) → surface as "extend existing skill"

**Setup**

Phase 1 identifies: the user iterated 4 times on a PR review process with a custom checklist
(security, performance, readability, test coverage). Proposed candidate: `pr-review-toolkit`.

`/find-skills` returns a partial match: the `code-review:code-review` skill covers generic review
but not the custom checklist part or the multi-iteration loop. Estimated coverage: ~70%.

**Expected**

Claude surfaces the partial match in the report. Instead of proposing `pr-review-toolkit` as a new skill,
it suggests extending `code-review:code-review` with the identified gaps (custom checklist, loop).
Explicitly indicates the gaps: what is missing in the existing skill relative to the observed pattern.

**Pass criterion**

SKILL.md Phase 1.7 distinguishes between full match (≥90%) and partial match (50-89%). For the partial case
it must contain instructions to present the candidate as "existing skill improvement" with a gap list,
not as a new skill.

---

## TC-03 — High frequency (≥3 occurrences) + exact duplicate → surface the frequency

**Setup**

Phase 1 finds that the user executed the same deploy sequence 5 times during the session:
`git push` → wait for CI → check Notion status → manual field update. Candidate: `ci-deploy-tracker`.

`/find-skills` returns an exact match (95%+): the `planning-review-system` skill already includes a
post-CI Notion update step. Coverage: ~92%.

In addition, Phase 1 detected that this sequence appeared ≥3 times in the current session.

**Expected**

The candidate is discarded (exact match). However, even though discarded, Claude surfaces the high
frequency (5 occurrences) to the user as relevant data: "The pattern is already covered by `planning-review-system`,
but its frequency (5×) suggests running that skill or automating the trigger."

The message is constructive, not redundant: it does not repeat "already covered" twice, but adds the
frequency value as an action signal.

**Pass criterion**

SKILL.md Phase 1.7 specifies that, even in case of discard for duplicate, if the observed frequency
is ≥3 occurrences, Claude adds a separate note about the frequency with a concrete action suggestion
(e.g. "run X" or "automate the trigger"). The frequency threshold must be declared numerically.

---

## TC-04 — Existing skill with outdated/non-relevant description → surface + delegate to user

**Setup**

Phase 1 identifies: the user configured deploy settings multiple times across three environments
(staging, prod, preview) using distinct `.env` files with merge logic. Candidate: `env-config-manager`.

`/find-skills` returns a nominal match: a skill `update-config` exists, but its description talks
exclusively about Claude Code harness configuration (settings.json, hooks, permissions), not about
deploy environments or `.env` files. The name vaguely coincides but the domain is completely different.

**Expected**

Claude does not discard the candidate and does not treat it as a partial match. Instead, it surfaces
to the user: the `update-config` skill exists but covers a different domain. It asks the user to decide whether:
(a) `env-config-manager` is genuinely a new separate skill, or (b) `update-config` should be updated to
also include env management.

Claude does not make the decision autonomously because the domain boundary is ambiguous.

**Pass criterion**

SKILL.md Phase 1.7 covers a "false positive by name" case: when the match is only nominal (description
not relevant to the candidate's domain), Claude surfaces the ambiguity and delegates the decision to the user
with the two explicit options (new skill vs extension). It does not discard silently, does not automatically
assume they are the same thing.

---

## TC-05 — No match found → candidate passes to Phase 2 normally

**Setup**

Phase 1 identifies: the user analyzed 3 BnB apartments, calculated estimated ROI for each,
and generated a comparative report in markdown. Candidate: `bnb-roi-comparator`.

`/find-skills` finds no match. No installed skill covers comparative analysis of BnB properties
with ROI calculation.

**Expected**

Claude proceeds normally to Phase 2 with the candidate `bnb-roi-comparator` intact. No additional
messages about the cross-check (silence on the check is the expected behavior for the "all good" case).
The candidate is presented in Phase 3 as a new skill with the standard structure: name, type, what
it automates, example triggers, effort, priority.

**Pass criterion**

SKILL.md Phase 1.7 specifies that, in the absence of a match, the candidate passes through the normal
flow without modifications and without additional cross-check messages. The "no match" behavior must be
the neutral case, not one that generates extra output.

---

## TC-06 — Output rules: backlog updates are table rows, NOT new sections (Phase 4)

**Setup**

Phase 1 identifies 3 distinct repeated patterns during a session:
1. A new pattern never seen before (effort: medium, frequency: 4×)
2. A new pattern with cross-project methodology value (e.g. "always validate volume before batch operations")
3. A pattern that matches an existing `💡 IDEA` row in `Status Implementazione` (e.g. `bureaucratic-research-assistant` at its 5th occurrence)

The Notion backlog page already has a healthy `Status Implementazione` table with 15 rows and no `# Idee da sessione` sections (Phase 0 passes).

**Expected**

In Phase 4, Claude:
- For pattern 1 (new): adds ONE row to the `Status Implementazione` table with status `💡 IDEA`, Note cell ≤ 200 chars
- For pattern 2 (methodology): does NOT add to Notion. Surfaces it separately at the end of output as "methodology insight" and suggests running `/claude-md-management:revise-claude-md` for `~/.claude/CLAUDE.md`
- For pattern 3 (repetition): updates ONLY the existing row's Note cell with `+ 5ª occorrenza (YYYY-MM-DD): [one-liner]`. Bumps priority since Nª ≥ 3.

Claude does NOT create any new section in the page: no `# Idee da sessione [date]`, no `## Nuove idee`, no `## Bump priority`, no `## Insegnamenti di metodo`, no `## Note meta sulla sessione`.

**Failure modes (FAIL)**

- Creating a section `# Idee da sessione [date]` ← critical fail, the original bug
- Writing a debrief paragraph with session context before the table updates
- Creating subsections like `## Nuove idee` / `## Bump priority` / `## Note meta`
- Note cells longer than 200 chars
- Adding methodology insights as rows in the backlog (they belong in CLAUDE.md, not Notion)
- Skipping the methodology routing and silently dropping the insight

**Pass criterion**

SKILL.md Phase 4 contains:
- An explicit `OUTPUT RULE` declaring that backlog updates go ONLY as table rows, NEVER as new sections
- A dedicated `Anti-patterns` section listing forbidden section titles (`# Idee da sessione`, `## Nuove idee`, `## Bump priority`, `## Insegnamenti di metodo`, `## Note meta`)
- An `Output budget` table specifying max char length per cell (Note ≤ 200)
- A clear separation of "what goes in Notion backlog" (actionable skill rows) vs "what goes in CLAUDE.md" (methodology insights), with explicit routing to `/claude-md-management:revise-claude-md`

**Why this case exists**

Between mid-March and mid-May 2026 the skill silently generated 19 `# Idee da sessione` sections (~800 lines of noise) in the Notion backlog before being noticed in a cleanup session on 2026-05-12. The original Phase 4 instruction ("add to a backlog") was ambiguous and the model interpreted it as verbose narrative output. The fix introduced strict OUTPUT RULE + Anti-patterns + Output budget + Phase 0 health check. This eval case ensures regressions don't reintroduce the bug.

---

## How to run this eval

1. Read `SKILL.md` Phase 1.7 and Phase 4 sections (when they exist)
2. For each case, verify the pass criterion
3. Mark pass/fail for every TC
4. A fail means SKILL.md must be updated before merging

The skill is "green" when all 6 cases pass.

| ID | Description | Pass |
|----|-------------|------|
| TC-01 | Exact skill → silent discard | [ ] |
| TC-02 | Partial coverage → surface gaps | [ ] |
| TC-03 | High frequency + duplicate → frequency note | [ ] |
| TC-04 | Outdated nominal match → delegate to user | [ ] |
| TC-05 | No match → pass through silently | [ ] |
| TC-06 | Output rules: rows not sections | [ ] |
