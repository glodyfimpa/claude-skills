---
name: session-retrospective
description: >
  Analyzes the current session to identify repetitive patterns that could become skills, commands, or plugins.
  Run this command toward the end of a work session, after the main tasks are complete. Triggers (Italian):
  "cosa posso automatizzare?", "session retrospective", "retrospettiva sessione", "c'è qualcosa da trasformare in skill?",
  "analizza la sessione", "pattern da automatizzare", or any request to identify automation opportunities
  from the work just completed. Works well in combination with /claude-md-management:revise-claude-md (run this
  first to capture automations, then revise-claude-md to persist them to memory).
---

# Session Retrospective

Analyzes the current session to extract automation opportunities.

## Backlog location (source of truth)

The skill backlog "Skills & Sub-agents per Claude" lives as a markdown file in the filesystem vault:

```
~/Documents/brain/areas/ai-automation/backlog-skill.md
```

Read it with the Read tool and update it with the Edit tool. This file is the **single source of truth**.

The backlog was migrated from Notion to the vault on 2026-06-03 (Second Brain Migration — the user is moving
"thinking" out of Notion into the filesystem). The old Notion page is **historical/read-only**: never
`notion-fetch`, `notion-search`, or `notion-update-page` it for the backlog. All reads and writes target the
vault file above.

## Purpose

At the end of a work session, walk back through what was done and identify:
- Repetitive action sequences that could become **skills**
- Single reusable commands that could become **commands**
- Groups of related skills/commands that could become **plugins**
- Patterns that recur across different sessions

The goal is to turn manual work into incremental automation: every session leaves behind tools that make the next session faster.

## Workflow

### Phase 0: Backlog health check

Before scanning the session, Read the backlog vault file `~/Documents/brain/areas/ai-automation/backlog-skill.md` and verify:
- Total file length ≤ 800 lines
- No `# Idee da sessione [date]` sections at top-level (anti-pattern, see "Anti-patterns" below)

If either limit is breached, STOP and surface to the user:

> "The backlog file has grown beyond healthy limits (X lines, Y `# Idee da sessione` sections). The retrospective should write into a clean catalog, not into a log. Recommend running `/simplify` cleanup on the file first, then re-run retrospective."

Do not proceed with Phase 1 until the user either confirms cleanup is done or explicitly overrides ("procedi comunque").

Rationale: without this gate, retrospective output silently drowns in noise, and Phase 1.5 cross-check becomes useless (the model cannot find repetitions in a 1200-line file).

### Phase 1: Scan the session

Walk back through the entire conversation and catalog:

1. **Actions executed**: every tool call, bash command, file created/modified, search performed
2. **Multi-step sequences**: groups of actions that together complete an objective (e.g. "find file → filter → copy → rename")
3. **User decisions**: choices that indicate recurring preferences
4. **Corrections and adjustments**: places where the user corrected the course indicate a pattern to codify

### Phase 1.5: Cross-check with existing backlog

Before identifying new candidates, Read the backlog vault file `~/Documents/brain/areas/ai-automation/backlog-skill.md`. Read the "Status Implementazione" table to see:
- Which skills are already published (status ✅)
- Which are already registered as ideas (status 💡 IDEA)
- Any "Idee da sessione" sections from previous retrospectives

If a candidate from this session matches an existing IDEA, mark it as **"confirmed by repetition"** instead of proposing it as new. Multiple independent occurrences of the same pattern across sessions is a strong signal to prioritize building it.

### Phase 1.7: Cross-check with installed skills (/find-skills)

For each candidate that passed the backlog check (Phase 1.5), execute the cross-check with the skills marketplace. **This is not optional**: skipping it silently produces false "no skill found" reports (regression observed 2026-05-13).

**Step 1 — REQUIRED, do not skip**: run the bash command below for each candidate. Replace `<keywords>` with 2-4 words that capture the candidate's use case.

```bash
npx skills find "<keywords>"
```

The command returns a list of `owner/repo@skill` hits with install counts. If output is empty or all hits have <1K installs, write the literal line `No relevant skill found via skills.sh for "<keywords>"` and skip to Phase 2 for that candidate.

**Environment-blocked fallback (NOT the same as "no hit")**: if `npx skills find` is denied by the host security policy / auto-mode classifier — i.e. the command never ran, as opposed to running and returning nothing — do NOT treat this as a blocking step and do NOT attempt to edit permission files to route around the block. Write the literal line `Cross-check marketplace non eseguibile in questo ambiente (comando negato dalla policy) — procedo senza` and proceed to Phase 2 for that candidate, exactly as you would on a "no hit". The marketplace check is one filter among several (Phase 1.5 backlog cross-check + Phase 2 repeatability + Phase 3.5 rule-of-three already gate the candidate); degrading gracefully on it is correct, stalling the whole retrospective is not. To make the command runnable on this machine, the user can add `Bash(npx skills find:*)` to their `~/.claude/settings.json` allowlist — surface this as a one-line suggestion in the Phase 4 closing summary, never act on it yourself.

**Step 2 — REQUIRED when Step 1 returns hits with ≥1K installs**: estimate coverage of the top hit using `WebFetch` on `https://skills.sh/<owner>/<repo>/<skill>`. Prompt the fetch with: "Does this skill cover the use case '<candidate description>'? Quote relevant capabilities and gaps."

**Step 3 — decision table** (coverage estimated from Step 2, reputation from install count of Step 1):

| Coverage | Reputation | Azione obbligata |
|----------|-----------|-------------------|
| ≥90% | ≥1K installs | **discard silently** — non menzionare al utente, candidato non passa a Phase 2 |
| ≥90% | <1K installs | **surface come "installazione suggerita"**, una riga in Phase 4 closing summary, niente menu |
| 50–89% | qualsiasi | **save_idea come "extend X"** (mai come skill nuova standalone). La nota nel backlog vault menziona quale skill esistente estendere e i gap precisi. |
| <50% o no hit | — | candidato passa a Phase 2 senza menzione cross-check |
| Name match con dominio diverso | — | surface ambiguità con AskUserQuestion a 2 opzioni: (a) nuova skill separata, (b) estendi esistente includendo il nuovo dominio. Non decidere autonomamente. |

The high-frequency pattern (≥3 occurrences in the session) is handled in Phase 3.5, not here. This phase is purely "does the marketplace already cover it?".

### Phase 2: Identify candidates

For each sequence or pattern that passed the previous phases, evaluate:

**Is it repeatable?** If it's a one-off action specific to this situation, it doesn't need to be automated. If it could happen again (even in slightly different form), it's a candidate.

**Is it complex enough?** If it's 1-2 trivial commands, it's not worth a skill. If it's 3+ steps with decision logic, yes.

**Does it already exist as a skill?** This is automatically verified in Phase 1.7 via `/find-skills` — do not repeat the check manually here.

**Does it already exist as an idea in the backlog?** Check the backlog vault file (Phase 1.5). If found, don't present it as a new discovery: note "Already in backlog as [name] (IDEA, [date]). This session confirms the pattern — consider bumping priority."

Categorize each candidate:

| Type | When | Example |
|------|------|---------|
| **Skill** | Multi-step workflow with logic, reusable in different contexts | Document collection for bureaucratic processes |
| **Command** | Single action or structured prompt to launch with a trigger | End-of-session retrospective |
| **Plugin** | Group of related skills + commands serving one domain | PA process management toolkit |
| **Existing skill improvement** | A skill exists but is missing something | Add cloud search to document-collector |

### Phase 3: Present results

For each candidate, present:

**Proposed name**: e.g. `document-collector`

**Type**: skill / command / plugin / improvement

**What it automates**: concrete description of what it would do, based on what happened in the session. No vague abstractions — reference the actual observed actions.

**Example triggers**: 2-3 phrases the user would say to activate it.

**Estimated effort**: low (< 30 min), medium (30 min - 2 hours), high (> 2 hours)

**Suggested priority**: based on estimated usage frequency × time saved per use

### Phase 3.5: Self-evaluation gate (BEFORE Phase 4)

Per ogni candidato passato attraverso Phase 1.7 + Phase 2 + Phase 3, decidi TU stesso (non l'utente) tra `create_now`, `save_idea`, `discard` applicando queste 5 euristiche deterministiche, in ordine:

1. **≥2 occorrenze in <30 giorni AND non coperto da skill esistente** → `create_now` se la 2ª occorrenza è recente (≤7 giorni) e l'effort è basso (<2h), altrimenti `save_idea`.
2. **1 occorrenza AND non coperto** → `discard`. Il pattern non è ancora confermato dalla regola del 3 (rule of three for abstractions); riproporrai alla 2ª occorrenza in retro futura.
3. **≥2 occorrenze ma coperto ≥90% da skill esistente** → `discard` con menzione "installa skill X" in chiusura, non come domanda.
4. **Partial coverage 50–89%** → `save_idea` come "extend skill X" (mai come standalone). La nota nel backlog vault documenta gap precisi.
5. **Frequenza ≥3 occorrenze nella sessione singola** → `create_now` indipendentemente da copertura. La frequenza intra-sessione è segnale più forte della copertura: lo skill esistente non sta evidentemente venendo usato perché non match al contesto reale.

**Output del gate**: per ogni candidato, scrivere a sé stessi una riga `candidate=<nome> → <create_now|save_idea|discard> (rule=<numero euristica>, reason=<motivo>)`.

**Procedi a Phase 4 SOLO con candidati la cui auto-valutazione è `create_now` o `save_idea`**. I candidati `discard` sono raccolti in una lista che andrà in chiusura summary (Phase 4 closing), non in AskUserQuestion.

### Phase 4: Decide and act

**OUTPUT RULE — critical**: backlog updates go ONLY as rows in the existing `Status Implementazione` markdown table inside the vault file `~/Documents/brain/areas/ai-automation/backlog-skill.md`, edited with the Edit tool. NEVER write to Notion. NEVER add new sections `# Idee da sessione [date]` or `## Nuove idee` / `## Bump priority` / `## Insegnamenti di metodo` / `## Note meta sulla sessione`.

#### Default: single-confirmation per candidate

**Default behavior** = single confirmation. Per ogni candidato sopravvissuto al gate di Phase 3.5 (auto-valutazione = `create_now` o `save_idea`), apri UNA AskUserQuestion con UNA singola opzione + "Annulla":

- Auto-valutazione `create_now` → "Creo ora `<nome>` (effort: X, motivo: Y). Procedo?" — opzione singola "Procedo / Annulla".
- Auto-valutazione `save_idea` → "Salvo `<nome>` come idea nel backlog vault (riga nuova in `Status Implementazione` di `backlog-skill.md`, status `💡 IDEA`). Procedo?" — opzione singola "Procedo / Annulla".

**Riferimento user-level**: questo comportamento è prescritto dal memory file `feedback_retro_no_menu_theater.md` (cache personale dell'utente, tipicamente in `~/.claude/projects/<project-id>/memory/`). Se il memory file esiste o `~/.claude/CLAUDE.md` ha convenzioni utente equivalenti (es. "delega esplicita = esegui, non chiedere"), applicare il default single-confirmation senza eccezioni.

Azioni concrete per `save_idea` (le 2 path, tutte sul file vault `~/Documents/brain/areas/ai-automation/backlog-skill.md` via Edit tool):
- **New idea**: add ONE row (cell text ≤ 200 chars) to the `Status Implementazione` markdown table with status `💡 IDEA`. Cells: Skill name, Skill ID, Status, Date, Note (one-liner). No new sections.
- **Repetition of existing idea**: update ONLY the "Note" cell of the existing row, appending `+ Nª occorrenza (YYYY-MM-DD): [one-line context]`. Bump priority in same cell if Nª ≥ 3.
- **After any write**: bump the `updated:` field in the file's YAML frontmatter to today's date.

#### Caso eccezionale: menu 3-opzioni

Il menu Create / Save / Discard a 3 opzioni è il **caso eccezionale**, non il default. Va aperto SOLO quando:
- 2+ candidati di pari valore con direzioni davvero ortogonali (es. "skill nuova" vs "estendi esistente" e i dati di Phase 1.7 non bastano a scegliere); E
- L'utente non ha convenzioni che prescrivono autonomia decisionale.

In ogni altro caso, il menu 3-opzioni è anti-pattern (produce "presentation theater" — vedi memory file citato sopra).

#### Closing summary obbligatoria

A fine Phase 4, riporta in narrativa (NON AskUserQuestion):
1. Lista candidati `create_now`/`save_idea` con esito conferma utente (procedo / annullato).
2. Lista candidati `discard` da Phase 3.5 con motivo (rule + reason): formato "Valutato `<nome>`, scartato perché `<motivo>`".
3. Eventuali skill da installare ("installa `<owner/repo@skill>`") per coverage ≥90% con <1K installs.

#### Cross-project methodology lessons

For cross-project methodology lessons (e.g. "memory → artifact promotion", "auto-mode does not bypass approvals"), these belong in `~/.claude/CLAUDE.md` via `/claude-md-management:revise-claude-md`, NOT in the backlog. Surface them to the user as a separate list at end of retrospective output and suggest running revise-claude-md as next step.

If the user chooses to create, proceed immediately. Do not defer to "the next session".

## Anti-patterns (what NOT to do in the backlog file)

**NEVER create sections with these titles in the backlog file**:
- `# Idee da sessione [data]`
- `## Nuove idee` / `## Bump priority su idee esistenti`
- `## Insegnamenti di metodo` / `## Note meta sulla sessione`
- `## [Categoria specifica della sessione]`

The backlog is a **consultable catalog**, not a session journal. Every section above represents narrative content that:
- Duplicates information already in the canonical table
- Grows unboundedly across sessions (we hit 19 such sections / ~800 lines before forced cleanup on 2026-05-12)
- Makes future cross-check (Phase 1.5) impossible because the model cannot find repetitions inside narrative blocks

If you have valuable methodology insights that don't fit as table rows, surface them to the user at end of output and route them to `/claude-md-management:revise-claude-md` (CLAUDE.md globale or memory file), not to the backlog.

### Output budget per row

| Cell | Max length | Allowed values |
|------|-----------|----------------|
| Skill name | 60 chars | Human-readable name |
| Skill ID | 40 chars | kebab-case identifier |
| Status | one of | `💡 IDEA`, `🚧 DRAFT`, `✅ Pubblicato`, `✅ Pubblicato (locale)`, `✅ SUPERSEDED → [link]` |
| Date | "YYYY-MM-DD" or "YYYY-MM-DD (bump YYYY-MM-DD)" | First occurrence + optional bump dates |
| Note | 200 chars | One-line description + occurrence count if repetition |

If you cannot stay within the budget, the idea is probably too vague to be actionable — clarify scope with the user before saving.

## What is NOT a good automation candidate

- Conversations and decisions that require human judgment every time
- Actions executed only once for an unrepeatable context
- Patterns too simple (a single bash command, a search query)
- Things the user prefers to do manually to maintain control

## Usage suggestion

Run this command before `/claude-md-management:revise-claude-md`. The ideal end-of-session order:

1. `/session-retrospective` → identify what to automate
2. Create the skills/commands if decided
3. `/claude-md-management:revise-claude-md` → save the new knowledge (including newly created skills)
