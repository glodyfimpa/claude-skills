---
name: planning-review-system
description: |
  Weekly review and quarterly planning system based on GTD methodology. Automates inbox processing, project review, and quarterly tracking with Notion integration. Use this skill when: starting a weekly review, processing inbox, checking quarterly progress, or asking "come sto andando con gli obiettivi?". Triggers: "weekly review", "inizia la weekly review", "processa l'inbox", "stato Q1/Q2/Q3/Q4", "quick capture". Requires Notion MCP connected. Optional: Gmail MCP for email scanning.
---

# Planning & Review System

Weekly review workflow (30 min) with GTD-based inbox processing and quarterly tracking. Outputs structured review pages to Notion SECOND BRAIN.

## Notion Filters (CRITICAL)

Apply these filters to ALL queries:

| Database | Filter | Reason |
|----------|--------|--------|
| PROJECTS | `Legacy = false` | Legacy projects are archived separately |
| Tasks | Varies by phase | See workflow below |

## Database References

- **Tasks:** `collection://8e608c2b-6cbb-46a2-b233-fffc0b4f5e21`
- **PROJECTS:** `collection://38d9dc09-59f1-4f94-b36b-f62ab9772ac6`
- **RESOURCES:** `collection://6e75acb5-5b90-4939-b618-e02480f64c26`
- **SECOND BRAIN:** `https://www.notion.so/142e510c5e598039933ef8a447570ece`

## Workflow (6 Phases, 30 min total)

### Phase 1: Quick Capture (3 min)

**Automatic scans:**

1. **Notion RESOURCES:** Query `Status = Inbox` or created last 7 days without Project linked
2. **Gmail (if connected):** Unread emails, starred, or containing action keywords

Present count to user:
> "Found X Notion resources and Y emails to process. Review now or skip to inbox?"

### Phase 2: GTD Inbox Processing (10 min)

**Query:** Tasks where `Status = Not Started`

For each item, ask:
1. Still relevant? (No → delete)
2. Takes < 2 minutes? (Yes → do now or delete)
3. If > 2 min → assign Project + Due Date

**Actions:** Do Now | Schedule | Link to Project | Waiting For | Delete

### Phase 3: Project Review (8 min)

**Query:** PROJECTS where `Status IN (In progress, Stand By)` AND `Legacy = false`

For each project check:
1. Has at least one Task with `Next Action = true`?
2. Touched in last 7 days?
3. Still relevant to quarterly goals?

**Actions:** Keep Active | Stand By | Archive | Define Next Action

Use "Stalled Projects" view for projects without recent activity.

### Phase 4: Quarterly Check (3 min)

**Query:** PROJECTS where `Quarter = Q[current]` AND `Legacy = false`

Calculate and present:
- % complete (Done / Total)
- Projects blocked or stalled
- Days remaining in quarter

Reference "Pianificazione 2026" page for goals context: `https://www.notion.so/2dce510c5e5980c6a688c1c8e0257912`

### Phase 5: Week Ahead (4 min)

Apply the Golden Rule — ask user:

| Element | Question |
|---------|----------|
| **One decision** | What single thing, if completed this week, makes the biggest difference? |
| **One number** | What metric will you track this week? |
| **One why** | Why does this matter to you this week? |

### Phase 6: Summary (2 min)

Create Notion page in SECOND BRAIN:

**Title:** `Weekly Review — [date in Italian format, e.g., "9 Febbraio 2026"]`

**Content:** See `references/weekly-template.md`

## Trigger Mapping

| User says | Execute |
|-----------|---------|
| "weekly review" / "inizia la weekly review" | Full workflow (Phases 1-6) |
| "processa l'inbox" / "inbox processing" | Phases 1-2 only |
| "stato Q1/Q2/Q3/Q4" / "quarterly check" | Phase 4 only |
| "quick capture" | Phase 1 only |
| "come sto andando?" | Phase 4 + summary |

## Key Notion Fields

**Tasks:**
- `Status`: Not Started / Waiting For / Stand By / In Progress / Done
- `Next Action`: checkbox (GTD flag for priority tasks)
- `Due Date`: date
- `Project`: relation to PROJECTS

**PROJECTS:**
- `Status`: Inbox / In progress / Stand By / Delegate / Done
- `Quarter`: Q1 / Q2 / Q3 / Q4 / Someday
- `Legacy`: checkbox (if true, ALWAYS ignore)
- `This Sprint`: checkbox

**RESOURCES:**
- `Status`: Inbox / To Review / Reviewed
- `Projects`: relation (empty = potential item to process)

## Dependencies

| Service | Required | Purpose |
|---------|----------|---------|
| Notion MCP | Yes | All database operations |
| Gmail MCP | No | Email scan in Phase 1 (skip if not connected) |
