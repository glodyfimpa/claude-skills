---
name: planning-review-system
description: |
  Weekly review and quarterly planning system based on GTD methodology. Automates inbox processing, project review, and quarterly tracking with flexible tool integration. Use this skill when: starting a weekly review, processing inbox, checking quarterly progress, or asking about goal status. Triggers are defined in the user's config file (.claude/life-os.local.md). Works with any task database MCP (Notion, Airtable, Linear, etc.) or in chat-only mode without any tools. Optional: email MCP for email scanning.
---

# Planning & Review System

Weekly review workflow (30 min) with GTD-based inbox processing and quarterly tracking. Outputs structured review pages to the connected notes tool, or directly to chat if no notes tool is configured.

## Config Guard

**BEFORE ANYTHING ELSE:** Check if `.claude/life-os.local.md` exists in the current project directory.

**If it exists** (plugin mode or previously configured standalone):
- Read the file and parse:
  - **Frontmatter (YAML):** connected tools (`task_tool`, `notes_tool`, `email_tool`), database IDs, field mappings, language
  - **Body (Markdown):** triggers, commitments, meetings, ideal week
- Read `task_tool` and `notes_tool` from config. These determine whether to use MCP tools or conversational fallbacks.

**If it does NOT exist** (first run — run mini-setup):
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
     - Email: no extra config needed
   - If user has NO tools and no info to provide: set all tool values to `none`, save minimal config (language only) → skill works in chat-only mode
4. **Save** everything to `.claude/life-os.local.md` and proceed.

All instructions below reference config values. Never use hardcoded database IDs or field names.

## Language

Respond in the language specified by the `language` field in the config. If no config exists yet (during mini-setup), detect language from the user's message. Format dates according to the configured language's conventions.

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

## Workflow (6 Phases, 30 min total)

### Phase 1: Quick Capture (3 min)

**Automatic scans:**

1. **Resources:**
   - **If `task_tool != none`:** Query resources database where `[resource_status_field] = Inbox` or created in last 7 days without Project linked.
   - **If `task_tool = none`:** Ask the user: "Do you have any unprocessed notes, bookmarks, or resources from this week?"

2. **Email:**
   - **If `email_tool != none`:** Scan for unread emails, starred, or containing action keywords.
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

**If `notes_tool != none`:** Create a page under the output page (from config `output_page_url`):

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
