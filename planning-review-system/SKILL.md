---
name: planning-review-system
description: |
  Weekly review and quarterly planning system based on GTD methodology. Automates inbox processing, project review, and quarterly tracking with flexible tool integration. Use this skill when: starting a weekly review, processing inbox, checking quarterly progress, or asking about goal status. Triggers are defined in the user's config file (.claude/life-os.local.md). Works with any task database MCP (Notion, Airtable, Linear, etc.) or in chat-only mode without any tools. Optional: email MCP for email scanning.
---

# Planning & Review System

Weekly review workflow (30 min) with GTD-based inbox processing and quarterly tracking. Outputs structured review pages to the connected notes tool, or directly to chat if no notes tool is configured.

## Config Guard

**Config lookup:** open and follow `_shared-refs/config-lookup.md` (or `../_shared-refs/config-lookup.md` when running from the synced plugin copy).

**If a config file exists** (plugin mode or previously configured standalone):
- Read the file and parse:
  - **Frontmatter (YAML):** connected tools (`task_tool`, `notes_tool`, `email_tool`), database IDs, field mappings, language
  - **Body (Markdown):** triggers, commitments, meetings, ideal week
- Read `task_tool` and `notes_tool` from config. These determine whether to use MCP tools or conversational fallbacks.

**If NO config file exists** (first run — run mini-setup):
1. **Auto-detect** available MCP tools in the current session:
   - Notion tools available (notion-search, notion-fetch, etc.)? → propose `task_tool = notion`, `notes_tool = notion`
   - Gmail tools available (gmail_search_messages, etc.)? → propose `email_tool = gmail`
2. **Present findings** to the user:
   - If tools detected: "I detected [tools]. I'll ask a few questions to configure this skill."
   - If no tools detected: "No MCP tools detected. I'll ask you what tools you use so we can set everything up."
3. **Mini-setup** (always runs, adapts to what's available):
   - Ask language preference
   - Ask/confirm which tools the user wants to connect (auto-detected ones are pre-selected, user can add/remove)
   - For each confirmed tool, ask specifics:
     - Task DB (Notion/Airtable/Linear): database IDs (`tasks_db`, `projects_db`, `resources_db`), field mappings (`task_status_field`, `project_status_field`, etc.), output page URL
     - Email (Gmail/Outlook/other): which labels/folders to scan (default: INBOX), exclude patterns — senders or subjects to always skip (e.g., newsletters, automated notifications). Store as `email_scan_labels` (list, default: `["INBOX"]`) and `email_exclude_patterns` (list, default: `[]`).
   - If user has NO tools and no info to provide: set all tool values to `none`, save minimal config (language only) → skill works in chat-only mode
4. **Save** config to `~/.claude/life-os.local.md` (global, default) or `.claude/life-os.local.md` (project-level, if user prefers). Ask the user which location.

All instructions below reference config values. Never use hardcoded database IDs or field names.

## Language

See `_shared-refs/language.md` (or `../_shared-refs/language.md` in the synced copy).

## Database Filters (CRITICAL)

**Skip this section if `task_tool = none` in config.**

Apply these filters to ALL queries:

| Database | Filter | Reason |
|----------|--------|--------|
| Projects | `[project_legacy_field] = false` | Legacy/archived projects are excluded |
| Tasks | Varies by phase | See workflow below |

## Database References

**If `task_tool != none`:** Read all database IDs from config frontmatter:

- **Tasks:** value of `tasks_db`
- **Projects:** value of `projects_db`
- **Resources:** value of `resources_db`
- **Output page:** value of `output_page_url`

**If `task_tool = none`:** Skip this section. All data will be collected conversationally.

## Vault Filesystem Mode

This section applies **only when `notes_tool = vault_filesystem`** in config. It defines how Phase 6 (Summary) writes the weekly review to the Obsidian vault on disk instead of Notion.

**Required config fields when `notes_tool = vault_filesystem`:**
- `vault_path`: absolute path to the vault root (e.g. `~/Documents/brain`)
- `helpers_path`: absolute path to the project directory containing the Python helpers and venv (e.g. `~/Documents/1.PROJECTS/SECOND_BRAIN_MIGRATION`)
- `mode` (optional): `vault_only` (default) or `with_legacy_fallback`. Resolved at runtime via `read_life_os_mode()` (see "Source resolution" below).

**Source resolution (M1 front-end switch, 2026-06-06):** the data source for each category is decided by `<vault_path>/system/source_resolution.py`. Read `mode` from config with `read_life_os_mode()`, then call `resolve_source(vault_has_category, mode)`:
- `vault_only` (current setup): always reads from the vault. The thought lives in the vault; structured DBs stay on Notion, so no per-category fallback fires.
- `with_legacy_fallback`: reads from the vault when the category exists there, otherwise from Notion (soft transition). Not active in the current config.

With the default `vault_only`, the save-actions below already write to the vault — the resolver makes that contract explicit and reversible (flip `mode` in config, no code change).

**Path convention:**
- Weekly file: `<vault_path>/weekly/YYYY-Www.md` (ISO week, e.g. `2026-W21.md`)

The weekly file MUST already exist. If missing, fall back to chat mode and tell the user the file isn't there yet.

### Action A — Save Phases 1+2+3 (Quick Capture, Inbox Processed, Projects)

Run from `<helpers_path>`:

```bash
cd <helpers_path> && .venv/bin/python -c "
import sys; sys.path.insert(0, 'scripts')
from pathlib import Path
from life_os.weekly_review import append_weekly_review_sections, WeeklyReviewPayload, ProjectStatus

append_weekly_review_sections(
    Path('<vault_path>/weekly/YYYY-Www.md'),
    WeeklyReviewPayload(
        quick_capture=['<item 1>', '<item 2>'],
        inbox_processed=['<task A → action>', '<task B → action>'],
        projects=[
            ProjectStatus(nome='<project>', status='<Active|Stand By|Archive>', quarter='<Q1-Q4>', note='<short note>'),
        ],
    ),
)
"
```

### Action B — Save Phases 4+5 (Quarterly Progress + Week Ahead)

Run after Action A:

```bash
cd <helpers_path> && .venv/bin/python -c "
import sys; sys.path.insert(0, 'scripts')
from pathlib import Path
from life_os.planning_review_system import append_planning_review_sections, PlanningReviewPayload

append_planning_review_sections(
    Path('<vault_path>/weekly/YYYY-Www.md'),
    PlanningReviewPayload(
        quarter='Q<1-4>',
        completamento='<NN>%',
        giorni_rimanenti=<int>,
        risultato_forte='<short sentence>',
        spillover='<projects spilling to next quarter or — >',
        range_date='<DD MMM – DD MMM>',
        priorita_1='<from Phase 5: one decision>',
        priorita_2='<supporting priority>',
        priorita_3='<supporting priority>',
        numero='<from Phase 5: one metric>',
        perche='<from Phase 5: one why>',
    ),
)
"
```

Conflict handling: both helpers raise `ValueError` if the corresponding section is already present with different content. If that happens, tell the user the weekly review section already exists and ask whether to keep the existing one (the skill does not overwrite).

## Workflow (6 Phases, 30 min total)

### Phase 1: Quick Capture (3 min)

**Automatic scans:**

1. **Resources:**
   - **If `task_tool != none`:** Query resources database where `[resource_status_field] = Inbox` or created in last 7 days without Project linked.
   - **If `task_tool = none`:** Ask the user: "Do you have any unprocessed notes, bookmarks, or resources from this week?"

2. **Email:**
   - **If `email_tool != none`:** Scan for unread emails, starred, or containing action keywords from the past 7 days. Use `email_scan_labels` and `email_exclude_patterns` from config (if configured). For each email found, read subject, sender, and first ~200 characters of body. Classify into:
     - **Create task** — contains an action item that should become a task for next week
     - **Reply needed** — requires a response that hasn't been sent
     - **Archive** — already handled or no longer relevant
     - **Ignore** — newsletters, notifications, no action needed
   - Discard "Ignore" emails from the summary. Present actionable emails as a compact list:
     > "[N] emails from this week still need attention:"
     > 1. **[Sender]** — [Subject snippet] → Suggested: [create task "[description]" / reply / archive]
     > 2. ...
     > "Want to accept these suggestions, modify any, or skip?"
   - Accepted "Create task" suggestions become inputs for Phase 3 (weekly priorities) and Phase 4 (next week planning).
   - **If `email_tool = none`:** Skip email scanning.

Present count to user:
> "Found X resources and Y emails to process. Review now or skip to inbox?"

If in chat-only mode and the user listed items, confirm the count before proceeding.

### Phase 2: GTD Inbox Processing (10 min)

**Query:**
- **If `task_tool != none`:** Query Tasks database where `[task_status_field] = [task_status_not_started]`.
- **If `task_tool = none`:** Ask the user: "List your pending tasks — anything in your inbox or on your mind that needs processing."

For each item, ask:
1. Still relevant? (No → delete)
2. Takes < 2 minutes? (Yes → do now or delete)
3. If > 2 min → assign Project + Due Date

**Actions:** Do Now | Schedule | Link to Project | Waiting For | Delete

### Phase 3: Project Review (8 min)

**Query:**
- **If `task_tool != none`:** Query Projects database where `[project_status_field] IN (In progress, Stand By)` AND `[project_legacy_field] = false`.
- **If `task_tool = none`:** Ask the user: "What projects are you currently working on? For each, is it active, on hold, or done?"

For each project check:
1. Has at least one Task with `[task_next_action_field] = true`?
2. Touched in last 7 days?
3. Still relevant to quarterly goals?

**Actions:** Keep Active | Stand By | Archive | Define Next Action

### Phase 4: Quarterly Check (3 min)

**Query:**
- **If `task_tool != none`:** Query Projects database where `[project_quarter_field] = Q[current quarter]` AND `[project_legacy_field] = false`.
- **If `task_tool = none`:** Ask the user: "What are your goals for this quarter? How is each one progressing — on track, behind, or blocked?"

Calculate and present:
- % complete (Done / Total)
- Projects blocked or stalled
- Days remaining in quarter

If `goals_page_url` is set in config, reference that page for goals context.

### Phase 5: Week Ahead (4 min)

Apply the Golden Rule — ask user:

| Element | Question |
|---------|----------|
| **One decision** | What single thing, if completed this week, makes the biggest difference? |
| **One metric** | What metric will you track this week? |
| **One why** | Why does this matter to you this week? |

### Phase 6: Summary (2 min)

**If `notes_tool = vault_filesystem`:** See "Vault Filesystem Mode" section above. Run **Action A** first (Phases 1+2+3 → `WeeklyReviewPayload`), then **Action B** (Phases 4+5 → `PlanningReviewPayload`) on the same weekly file. Both append distinct sections; they don't conflict with each other.

**If `notes_tool != none` (Notion or other):** Create a page under the output page (from config `output_page_url`):

**If `notes_tool = none`:** Present the complete review summary in chat as formatted markdown. Tell the user: "Here's your weekly review summary. You can copy it wherever you'd like."

**Title:** `Weekly Review — [date in configured language]`

**Content:** See `references/weekly-template.md` in this skill's directory

## Trigger Mapping

Read triggers from the "Trigger Mapping" section in the config body. Match user messages against the "Weekly Review" trigger list. Also match these functional patterns:

| User intent | Execute |
|-------------|---------|
| Mentions "weekly review" or matching trigger | Full workflow (Phases 1-6) |
| Mentions "inbox" or "process" trigger | Phases 1-2 only |
| Mentions quarter (Q1/Q2/Q3/Q4) or "quarterly" | Phase 4 only |
| Mentions "capture" | Phase 1 only |
| Asks about goal progress | Phase 4 + summary |

## Key Database Fields

Read all field names from config. The expected structure:

**Tasks:**
- `[task_status_field]`: with values `[task_status_not_started]` / `[task_status_waiting]` / `[task_status_stand_by]` / `[task_status_in_progress]` / `[task_status_done]`
- `[task_next_action_field]`: checkbox (GTD flag for priority tasks)
- `[task_due_date_field]`: date
- `[task_project_field]`: relation to Projects

**Projects:**
- `[project_status_field]`: with configured status values
- `[project_quarter_field]`: Q1 / Q2 / Q3 / Q4 / Someday
- `[project_legacy_field]`: checkbox (if true, ALWAYS ignore)
- `[project_sprint_field]`: checkbox

**Resources:**
- `[resource_status_field]`: Inbox / To Review / Reviewed
- `[resource_project_field]`: relation (empty = potential item to process)

## Dependencies

| Service | Required | Purpose |
|---------|----------|---------|
| Task database MCP | Recommended | Notion, Airtable, Linear, or similar. Enables automatic data queries. Without it, the user provides information conversationally. |
| Email MCP | No | Gmail, Outlook, or similar. Email scan in Phase 1 (skip if not connected) |
