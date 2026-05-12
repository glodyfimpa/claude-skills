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

## Purpose

At the end of a work session, walk back through what was done and identify:
- Repetitive action sequences that could become **skills**
- Single reusable commands that could become **commands**
- Groups of related skills/commands that could become **plugins**
- Patterns that recur across different sessions

The goal is to turn manual work into incremental automation: every session leaves behind tools that make the next session faster.

## Workflow

### Phase 1: Scan the session

Walk back through the entire conversation and catalog:

1. **Actions executed**: every tool call, bash command, file created/modified, search performed
2. **Multi-step sequences**: groups of actions that together complete an objective (e.g. "find file → filter → copy → rename")
3. **User decisions**: choices that indicate recurring preferences
4. **Corrections and adjustments**: places where the user corrected the course indicate a pattern to codify

### Phase 1.5: Cross-check with existing backlog

Before identifying new candidates, check the Notion page "Skills & Sub-agents per Claude" (search Notion for it). Read the "Status Implementazione" table to see:
- Which skills are already published (status ✅)
- Which are already registered as ideas (status 💡 IDEA)
- Any "Idee da sessione" sections from previous retrospectives

If a candidate from this session matches an existing IDEA, mark it as **"confirmed by repetition"** instead of proposing it as new. Multiple independent occurrences of the same pattern across sessions is a strong signal to prioritize building it.

### Phase 1.7: Cross-check with installed skills (/find-skills)

For each candidate that passed the Notion check (Phase 1.5), invoke the `/find-skills` skill to search for skills that cover the same use case.

**Default: discard silently** if `/find-skills` finds a skill with ≥90% coverage of the use case. The candidate does not appear in the final report and is not mentioned to the user.

**Surface instead of discarding** in the following four cases:

- **Partial coverage (50-89%)**: present the candidate as "existing skill improvement" rather than a new skill. Explicitly indicate the gaps: what the found skill covers and what is missing relative to the observed pattern. Suggest extending the existing skill rather than creating a new one.
- **High-frequency pattern (≥3 occurrences in the session)**: even if the match exceeds ≥90% and the candidate is discarded, add a separate note with the frequency data and a concrete action suggestion (e.g. "run that skill" or "automate the trigger"). Do not repeat "already covered" — just add the frequency value as an action signal.
- **Name match with non-relevant domain**: if the found skill has a vaguely similar name but its description covers a different domain from the candidate, do not discard and do not treat as a partial match. Surface the ambiguity to the user with the two explicit options: (a) the candidate is a new separate skill, or (b) the existing skill should be updated to include the new domain. Do not make the decision autonomously.
- **Existing skill seems outdated**: the description of the found skill does not mention the specific use case that emerged in the session, despite potential overlap. Surface it and let the user decide.

If `/find-skills` finds nothing relevant, the candidate passes to Phase 2 without additional messages about the cross-check. Silence is the expected behavior for "all good".

### Phase 2: Identify candidates

For each sequence or pattern that passed the previous phases, evaluate:

**Is it repeatable?** If it's a one-off action specific to this situation, it doesn't need to be automated. If it could happen again (even in slightly different form), it's a candidate.

**Is it complex enough?** If it's 1-2 trivial commands, it's not worth a skill. If it's 3+ steps with decision logic, yes.

**Does it already exist as a skill?** This is automatically verified in Phase 1.7 via `/find-skills` — do not repeat the check manually here.

**Does it already exist as an idea in the backlog?** Check the Notion backlog (Phase 1.5). If found, don't present it as a new discovery: note "Already in backlog as [name] (IDEA, [date]). This session confirms the pattern — consider bumping priority."

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

### Phase 4: Decide and act

Ask the user what they want to do:

1. **Create now** one or more of the identified skills/commands → use skill-creator if available, otherwise write the SKILL.md directly
2. **Save as an idea** → add to a backlog (Notion task, local file, or simply CLAUDE.md)
3. **Discard** → nothing to do, the session did not produce automatable patterns

If the user chooses to create, proceed immediately. Do not defer to "the next session".

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
