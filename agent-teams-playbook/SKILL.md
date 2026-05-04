---
name: agent-teams-playbook
description: >
  Use when spawning Claude Code agent teams (multiple Claude sessions coordinating via shared task list and mailbox).
  Triggers: "spawna un team", "agent team", "team di agenti", "team di Claude", "crea un team",
  "lavora in parallelo multi-dominio", "parallel multi-domain work", "ipotesi concorrenti",
  "competing hypotheses", "coordinare più sessioni Claude", "team lead coordinator".
  Includes decision matrix vs subagents/Explore/single session, sizing rules, spawn prompt patterns,
  plan-approval gate, anti-patterns (file overlap), cleanup discipline, and a lessons-learned section
  that grows with each team executed (rule of three for promotion).
  Does NOT trigger for: simple multi-site research (use parallel general-purpose agents),
  codebase exploration (use Explore agent), single-file edits (use main session).
---

# Agent Teams Playbook

Operational reference for orchestrating Claude Code agent teams. Loaded only when the trigger matches; setup steps live in `setup.md` and are loaded on demand.

## When to use this skill

Use it BEFORE spawning a team. The decision matrix below tells you whether agent teams are the right tool, or whether subagents / Explore / a single session would be better. If the matrix sends you elsewhere, do not spawn a team.

## Decision matrix — pick the right tool

| Situation | Tool | Why |
|---|---|---|
| Extract data from N sites, no cross-talk needed (e.g. scrape 3 real-estate portals) | **Parallel general-purpose agents** (subagents) | Lower token cost, no coordination overhead, results synthesized in main context |
| Codebase exploration (find symbol, trace flow, locate definition) | **Explore agent** | Read-only, fast, designed for it |
| Investigate bug with N hypotheses that must **debate and disprove each other** | **Agent team** | Mailbox enables real cross-talk; teammates challenge each other (anti-anchoring) |
| Refactor in N **independent** modules (no file overlap) | **Agent team** | Shared task list + auto-claim removes manual coordination |
| Multi-perspective code review (security + perf + tests) | **Agent team** | Reviewers can cross-reference findings via mailbox |
| Research + decision (e.g. "which apartment to invest in?") | **Agent team** | Teammates discuss trade-offs and converge |
| Sequential task or shared file edits | **Single session** | Team adds only overhead |
| Single-file refactor or one-off edit | **Single session** | No parallelism available |

If you're not sure between teams and subagents: **does success require teammates to talk to each other?** Yes → team. No → subagents.

> Subagents tassonomia note: the `feedback_parallel_agents_research` memory (Apr 2026) predates agent teams. It still holds for **pure extraction** workloads, but does NOT apply when the work needs cross-agent dialogue. This skill supersedes that memory for the dialogue case.

## Setup (first time only)

Prerequisites (env var, Claude Code version, tmux/iTerm2, display modes) live in `setup.md`. Read it once when configuring the workstation; you do not need it during normal use.

## Sizing rules

- **Default team size**: 3–5 teammates. Tested range that balances parallelism with coordination overhead.
- **Tasks per teammate**: aim for 5–6. Below that, coordination overhead dominates. Above, teammates run too long without check-in.
- **Heuristic**: 15 independent tasks → start with 3 teammates. Scale up only when work genuinely benefits from more parallel slots.
- **Token cost scales linearly** with teammate count. Each teammate is a full Claude Code session with its own context window. Budget accordingly: a 5-teammate team easily costs 5x a single session.
- **Permission inheritance**: teammates start with the lead's permission mode at spawn time. If the lead is in auto mode, so are teammates. Plan permissions before spawning, not after.

## Spawn prompt template

A teammate inherits project context (CLAUDE.md, MCP servers, skills) but NOT the lead's conversation history. The spawn prompt must be self-contained.

Required fields:

1. **Role / persona** — what hat does this teammate wear?
2. **Scope** — exact files / modules / domain it owns
3. **Deliverable** — what does "done" look like?
4. **Constraints** — what to NOT touch (e.g. "do not modify schema files")
5. **Reporting style** — terse vs verbose, format expected back

Example spawn prompt (security reviewer):

```text
Spawn a teammate named "security-reviewer" with this prompt:

"Review the authentication module in src/auth/ for security vulnerabilities.
Focus: token handling, session management, input validation.
Context: app uses JWT tokens stored in httpOnly cookies.
Deliverable: a findings list with severity ratings (critical/high/medium/low)
and file:line references. Post the list to the team mailbox when done.
Do NOT modify code — read-only review. Do NOT touch other modules."
```

Same pattern for every teammate. Be specific. Vague prompts produce shallow work.

## Plan-approval gate (use for risky work)

For risky or scope-heavy tasks (auth refactor, schema migration, public API change), require teammates to **plan first, implement after lead approval**. The teammate works in read-only plan mode until the lead reviews and approves.

Trigger conditions:
- Modifies authentication, authorization, or session handling
- Touches database schema or migrations
- Changes a public API contract
- Affects shared infrastructure or CI/CD

Spawn pattern:

```text
Spawn the architect teammate to refactor the auth module.
Require plan approval before any code changes.
Approve only plans that include test coverage and rollback notes.
```

The lead reviews each plan autonomously. Influence the lead's judgment by stating approval criteria in the spawn prompt ("approve only X", "reject if Y").

## Anti-patterns

- **File overlap** — two teammates editing the same file leads to overwrites. Partition by file ownership, never by line range within a file.
- **Sequential masquerading as parallel** — if task B depends on task A's output, do not spawn two teammates; one session is faster.
- **Lead implements while teammates wait** — if the lead starts coding, teammates idle. Tell the lead explicitly: "wait for teammates to complete before proceeding."
- **Teammate runs cleanup** — only the lead runs cleanup. Teammates do not have the full team context and may leave inconsistent state.
- **Spawn without scope** — a teammate without an explicit "do not touch X" tends to scope-creep into other teammates' files.
- **Skipping the decision matrix** — defaulting to teams for any parallel work wastes tokens. Re-read the matrix when in doubt.

## Cleanup discipline

When the team finishes:

1. Lead verifies all tasks marked completed and all teammates idle.
2. Lead asks each teammate to shut down (graceful exit).
3. Lead runs cleanup (removes shared team resources).
4. Verify no orphaned tmux sessions: `tmux ls` and kill any stragglers named after the team.

If a teammate refuses to shut down, read its session, address the blocker, then retry.

## Lessons learned

This section grows with experience. Format for each lesson:

```
### <short rule>
- **Why**: original incident or constraint that led to the rule
- **How to apply**: when/where this kicks in
- **Validated**: YYYY-MM-DD, after N teams executed
```

Promotion rule: a lesson enters this section only after **≥2 occurrences** (rule of three applied to learnings — one data point is noise, two is a pattern). Lessons with only one occurrence stay in conversation memory until they recur.

Categories below are added on demand. Empty categories are removed during quarterly review.

### Sizing
*No lessons yet.*

### Prompting
*No lessons yet.*

### Coordination & messaging
*No lessons yet.*

### Troubleshooting
*No lessons yet.*

### Token economics
*No lessons yet.*

### Anti-patterns observed in practice
*No lessons yet.*

---

## How to update this skill

After running a team, ask: did anything surprise me? Did a heuristic break? Did I find a new anti-pattern?

- **Once**: keep it in conversation memory, do not edit the skill.
- **Twice**: open a PR on `claude-skills` and add the lesson under the right category with full format above.
- **Outdated rule**: open a PR removing or revising the rule. Do not silently leave stale guidance.

The skill is versioned in git. Every change is a commit with a clear message — that is the audit log.
