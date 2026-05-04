# Eval Cases — agent-teams-playbook

These cases are the spec for the skill. Each case has:
- **Input**: a realistic scenario
- **Expected**: what the skill must do or contain
- **Pass criterion**: how to verify

Run a manual eval by reading SKILL.md (and setup.md when relevant) and checking each case. A case fails when the skill does not contain the expected behavior or contains contradicting guidance.

---

## Part A — Trigger eval (does the skill activate?)

The skill description must match these positive cases and reject these negative cases. Self-check by re-reading the `description` frontmatter and asking: would this trigger?

### A1 — Positive: explicit team request (Italian)
- **Input**: "Spawna un team di agenti per esplorare questo problema da angoli diversi"
- **Expected**: skill activates
- **Pass**: description contains "spawna un team" OR "team di agenti" OR semantic equivalent

### A2 — Positive: explicit team request (English)
- **Input**: "Create an agent team to review this PR from security/perf/test angles"
- **Expected**: skill activates
- **Pass**: description contains "agent team" OR "spawn a team"

### A3 — Positive: parallel multi-domain intent
- **Input**: "Lavora in parallelo su frontend, backend e tests, ognuno un dominio diverso"
- **Expected**: skill activates
- **Pass**: description contains "parallelo multi-dominio" OR "multi-domain parallel" OR semantic equivalent

### A4 — Positive: competing hypotheses
- **Input**: "Ho un bug strano, voglio 4 ipotesi concorrenti che si confutino a vicenda"
- **Expected**: skill activates
- **Pass**: description contains "ipotesi concorrenti" OR "competing hypotheses" OR "concurrent hypotheses"

### A5 — Negative: simple multi-site research
- **Input**: "Cerca su 3 portali immobiliari le case con prezzo sotto 200k"
- **Expected**: skill does NOT activate (subagents are the right tool)
- **Pass**: description does NOT match generic "ricerca su N siti" / "N portals" patterns

### A6 — Negative: codebase exploration
- **Input**: "Esplora il codebase per trovare dove è definita questa funzione"
- **Expected**: skill does NOT activate (Explore agent is the right tool)
- **Pass**: description does NOT match generic "esplora codebase" / "explore codebase"

### A7 — Negative: single-file edit
- **Input**: "Refactora questa funzione in foo.py"
- **Expected**: skill does NOT activate
- **Pass**: description requires multi-domain or multi-agent intent, not single-task

---

## Part B — Content eval (does the skill contain the right guidance?)

For each scenario the user might be in, the skill must contain explicit guidance. Self-check by reading the body of SKILL.md.

### B1 — Decision matrix vs subagents/Explore
- **Scenario**: user asks "perché non uso subagents invece?"
- **Expected**: skill has a decision matrix that compares agent teams vs subagents vs single session vs Explore
- **Pass**: SKILL.md contains a table or list with at least 4 distinct cases mapping situation → tool

### B2 — Sizing guidance
- **Scenario**: user has 15 independent tasks, asks how many teammates to spawn
- **Expected**: skill states a default range (3-5) and the heuristic "5-6 tasks per teammate"
- **Pass**: SKILL.md mentions both numbers explicitly

### B3 — Spawn prompt structure
- **Scenario**: user wants to spawn a security reviewer teammate
- **Expected**: skill provides a template/example showing required prompt fields (role, scope, deliverable, constraints)
- **Pass**: SKILL.md contains at least one example spawn prompt

### B4 — Plan-mode approval gate
- **Scenario**: task is risky (auth refactor, schema migration)
- **Expected**: skill recommends `Request plan approval before changes` and shows when to use it
- **Pass**: SKILL.md mentions plan approval gate with at least one trigger condition

### B5 — File overlap anti-pattern
- **Scenario**: user wants 3 teammates editing the same file
- **Expected**: skill flags this as anti-pattern and recommends task partitioning by file
- **Pass**: SKILL.md contains explicit "no file overlap" rule

### B6 — Cleanup step
- **Scenario**: team finishes work
- **Expected**: skill instructs the lead (not teammates) to run cleanup
- **Pass**: SKILL.md contains "lead runs cleanup, not teammates"

### B7 — Token cost awareness
- **Scenario**: user is on a tight budget
- **Expected**: skill warns that tokens scale linearly with teammate count
- **Pass**: SKILL.md mentions token cost scaling

### B8 — Setup prerequisites pointer
- **Scenario**: first-time user, env var not set
- **Expected**: skill points to setup.md instead of inlining setup steps
- **Pass**: SKILL.md has a one-line pointer to setup.md, setup.md exists with full prerequisites

### B9 — Lessons learned section exists and has format
- **Scenario**: after running a team, user wants to record a lesson
- **Expected**: skill has a "Lessons learned" section with category headers and explicit format (rule + Why + How to apply + validation date + occurrence count)
- **Pass**: SKILL.md contains the section with the format documented

### B10 — Rule-of-three for lessons promotion
- **Scenario**: user observes a pattern once
- **Expected**: skill states a lesson is added only after ≥2 incidents (rule of three applied to learnings)
- **Pass**: SKILL.md states the threshold explicitly

### B11 — Subagents tassonomia integration
- **Scenario**: user is unsure whether to use teams or parallel general-purpose agents
- **Expected**: skill explicitly references the case where subagents win (independent extraction, no cross-talk needed)
- **Pass**: SKILL.md decision matrix has at least one row "use subagents instead"

### B12 — Auto mode interaction
- **Scenario**: user runs Claude in auto mode and spawns a team
- **Expected**: skill notes that teammates inherit lead's permission mode at spawn time
- **Pass**: SKILL.md mentions permission inheritance at spawn

---

## Part C — Setup eval (setup.md only)

### C1 — Env var
- **Pass**: setup.md states `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is required and shows where to set it

### C2 — Display modes
- **Pass**: setup.md explains in-process vs split-pane and when each is auto-selected

### C3 — Version requirement
- **Pass**: setup.md states minimum Claude Code version (v2.1.32)

---

## How to run this eval

1. Read `SKILL.md` (and `setup.md` for Part C)
2. For each case, check the pass criterion
3. Mark passes/fails in a checklist
4. A case fail means the skill must be revised before merging

A skill change is "green" when all cases pass.
