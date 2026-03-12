---
name: time-energy-manager
description: |
  Daily time and energy management system with 4 phases: Morning Plan, Mid-day Check, Pivot, Evening Close. Complements the planning-review-system by translating weekly priorities into daily execution with energy-adaptive scheduling. Scans emails for actionable items and integrates them into the plan. Optionally exports the approved plan as calendar events. Use this skill when: starting the day, checking energy levels, handling schedule changes, or closing the day. Triggers are defined in the user's config file (.claude/life-os.local.md). Works with any task database, calendar, and email MCP, or in chat-only mode without any tools.
---

# Time & Energy Manager

Daily time and energy management system in 4 phases. Operational complement to the planning-review-system: PRS looks back and up (weekly review, quarter), TEM looks forward and down (what you do today, with how much energy).

**Principle:** Don't do more. Do what matters, then live.

## Config Guard

**BEFORE ANYTHING ELSE:** Look for the config file in this order:
1. `.claude/life-os.local.md` (project-level)
2. `~/.claude/life-os.local.md` (global, portable across projects)

Use the first one found.

**If a config file exists** (plugin mode or previously configured standalone):
- Read the file and parse:
  - **Frontmatter (YAML):** connected tools, database IDs, field mappings, language, schedule settings
  - **Body (Markdown):** triggers, fixed commitments, recurring meetings, ideal week
- Read `task_tool`, `calendar_tool`, `notes_tool`, and `email_tool` from config. These determine whether to use MCP tools or conversational fallbacks.

**If NO config file exists** (first run — run mini-setup):
1. **Auto-detect** available MCP tools in the current session:
   - Notion tools available (notion-search, notion-fetch, etc.)? → propose `task_tool = notion`, `notes_tool = notion`
   - Google Calendar tools available (gcal_list_events, etc.)? → propose `calendar_tool = google-calendar`
   - Gmail tools available (gmail_search_messages, etc.)? → propose `email_tool = gmail`
2. **Present findings** to the user:
   - If tools detected: "I detected [tools]. I'll ask a few questions to configure this skill."
   - If no tools detected: "No MCP tools detected. I'll ask you what tools you use so we can set everything up."
3. **Mini-setup** (always runs, adapts to what's available):
   - Ask language preference
   - Ask/confirm which tools the user wants to connect (auto-detected ones are pre-selected, user can add/remove)
   - For each confirmed tool, ask specifics:
     - Task DB (Notion/Airtable/Linear): database IDs (`tasks_db`, `projects_db`), field mappings, output page URL
     - Calendar: calendar ID
     - Notes: output page URL (if different from task tool)
     - Email (Gmail/Outlook/other): which labels/folders to scan (default: INBOX), exclude patterns — senders or subjects to always skip (e.g., newsletters, automated notifications). Store as `email_scan_labels` (list, default: `["INBOX"]`) and `email_exclude_patterns` (list, default: `[]`).
   - Ask about work schedule: work days, work hours, lunch break
   - Ask about fixed commitments that block the evening (gym, family, etc.)
   - Ask about ideal week structure (or offer to generate one from the schedule info)
   - If user has NO tools and no info to provide: set all tool values to `none`, save minimal config (language only) → skill works in chat-only mode
4. **Save** config to `~/.claude/life-os.local.md` (global, default) or `.claude/life-os.local.md` (project-level, if user prefers). Ask the user which location.

All instructions below reference config values. Never use hardcoded database IDs, field names, or schedule times.

## Language

Respond in the language specified by the `language` field in the config. If no config exists yet (during mini-setup), detect language from the user's message. Format dates according to the configured language's conventions.

## Database References

If `task_tool != none`, read all database IDs from config frontmatter:

- **Tasks:** value of `tasks_db`
- **Projects:** value of `projects_db`
- **Planning board:** value of `planning_board_db` (may be empty)
- **Output page:** value of `output_page_url`

If `task_tool = none`, skip — data will be collected from the user directly.

## Critical Filters

Skip if `task_tool = none`.

| Database | Filter | Reason |
|----------|--------|--------|
| Projects | `[project_legacy_field] = false` | Ignore archived projects |
| Tasks | `[task_status_field] != [task_status_done]` AND `[task_due_date_field] = today` | Only active tasks for today |
| Planning | Day-based filter (if planning board is configured) | Tasks assigned to today |

## Phase 1 — Morning Plan (5 min)

**Triggers:** Read from "Morning Plan" section in config trigger mapping.

### Step 1: Read context (automatic)

Gather the following context. For each item, use the connected tool or fall back to asking the user.

1. **Latest Weekly Review:**
   - If `notes_tool != none`: Search in output page for the most recent page with title starting "Weekly Review —". Extract: weekly priorities, metric, why.
   - If `notes_tool = none`: Ask the user: "What was your main priority from your last weekly review?"

2. **Today's tasks:**
   - If `task_tool != none`: From Tasks database, filter `[task_status_field] != [task_status_done]` AND (`[task_due_date_field] = today` OR `[task_due_date_field]` is overdue). If planning board is configured, also query it for today's day.
   - If `task_tool = none`: Ask the user: "What tasks do you have for today? Include anything overdue."

3. **Quarter projects:**
   - If `task_tool != none`: From Projects database, filter `[project_quarter_field] = Q[current quarter]` AND `[project_status_field] = In progress` AND `[project_legacy_field] = false`.
   - If `task_tool = none`: Ask the user: "What are your main projects this quarter?"

4. **Ideal Week:** Read the "Ideal Week" section from config body for today's day name. If sprint cycle is enabled, determine if it's Sprint Week A or B using the configured parity.

5. **Calendar events:**
   - If `calendar_tool != none`: Read today's calendar events using the calendar MCP (use `calendar_id` from config). Merge calendar events with the ideal week template: calendar events take priority over template blocks when they overlap. Show both scheduled meetings from calendar and planned deep work from ideal week.
   - If `calendar_tool = none`: Use only the ideal week template from config.

6. **Actionable emails:**
   - If `email_tool = none`: Skip entirely.
   - If `email_tool != none`:
     - **First execution of the day** (no Plan page exists for today — check via notes tool or conversation history): Search emails received from yesterday's start-of-workday until now. Use labels/folders from `email_scan_labels` config. Exclude senders/subjects matching `email_exclude_patterns`.
     - **Subsequent executions** (Plan page already exists for today): Search only unread emails since the timestamp stored in `email_last_check` on the Plan page. If no timestamp found, fall back to emails from the last 4 hours.
     - **Processing:** For each email, read the subject, sender, and first ~200 characters of body. Classify into:
       - **Reply needed** — requires a response from the user
       - **Task to add** — contains an action item that should enter today's plan
       - **Meeting/schedule** — proposes or changes a meeting time
       - **Delegation** — something the user needs to assign to someone else
       - **FYI only** — informational, no action required
     - **Filter:** Discard all FYI-only emails. Only surface actionable emails (reply needed, task, meeting, delegation).
     - **Present summary:** Show a compact list of actionable emails with suggested actions:
       > "I found [N] emails that need attention:"
       > 1. **[Sender]** — [Subject snippet] → Suggested: [reply / add task "[description]" / schedule response / delegate to [name]]
       > 2. ...
       > "Want to accept these suggestions, modify any, or skip email actions for now?"
     - **User response handling:**
       - Accept all: each suggested action becomes an input for Step 3 (plan generation).
       - Modify: user adjusts individual suggestions. Updated actions feed into Step 3.
       - Skip: no email-derived actions enter the plan. Move to Step 2.
     - **Collect results:** Store accepted email actions as a list to be merged into the plan in Step 3.

### Step 2: Energy check-in (30 sec)

Ask the user:
> "How are you feeling this morning? (1-5)"

If the user wants to add context (optional):
> "Anything specific weighing on you or giving you energy today?"

### Step 3: Generate adaptive plan

Based on: weekly priorities + today's tasks + email-derived actions (if any) + energy + ideal week template for today (merged with calendar events if available).

**Energy logic:**

| Energy | Strategy |
|--------|----------|
| 4-5 | Creative deep work first, admin after. Propose ambitious tasks for the first focus block. |
| 3 | Important but non-creative tasks. Alternate focus and breaks. First block for study/review. |
| 1-2 | Essential tasks and deadlines only. Protect energy. First focus block optional. Suggest extra breaks. |

**Email action integration (if email-derived actions were accepted in Step 1):**

| Action type | How to schedule |
|-------------|-----------------|
| Reply needed | Add a 15-min "Email replies" block in the first light-work slot. Group all pending replies into one block. |
| Task to add | Add to the appropriate focus block based on its nature (deep work vs admin). If the plan is already full, apply the Pivot principle: propose removing or deferring a lower-priority item. Never silently add. |
| Meeting/schedule | Flag as "needs scheduling" in the plan. Do not auto-create calendar events. Present as a note: "Schedule: [meeting description] — propose a time after your first focus block." |
| Delegation | Add a 5-min item in the first admin/light-work block: "Delegate: [task] to [person]." |

If adding email actions would push the plan beyond the available time blocks, explicitly warn:
> "Email brought in [N] new actions. Your plan is full. Which existing items should we defer to make room?"

**Block structure:** Use today's template from the "Ideal Week" section in config, merged with calendar events when available. Adapt based on energy level. Use these icons:

- Deep focus: relevant icon
- Light work: relevant icon
- Break: relevant icon
- Personal: relevant icon
- Family/personal time: relevant icon
- Meeting: relevant icon

**ALWAYS close with:**
> "Today if you do [X], [Y], and [Z] — tonight you can disconnect."

Where X, Y, Z are the 3 real priorities for the day (not all tasks, only the ones that matter).

### Step 4: User confirmation

Present the plan and ask:
> "Does this work or do you want to change something?"

If the user modifies, adapt. If confirmed, proceed.

### Step 4.5: Calendar export (optional)

After the user confirms the plan, offer to create the plan blocks as calendar events.

- If `calendar_tool = none`: Skip entirely.
- If `calendar_tool != none`:
  > "Want me to add today's plan blocks to your calendar?"

  If the user says yes:
  - Default calendar: use `calendar_id` from config (the same calendar used to read events in Step 1).
  - Optional: ask the user if they want to use a different calendar.
    > "I'll use your default calendar ([calendar_id]). Want to use a different one?"
  - For each block in the plan that is NOT already a calendar event (skip blocks that came from calendar in Step 1 — they already exist):
    - Create a calendar event with:
      - **Title:** block name (e.g., "Deep Focus: [task]", "Break", "Admin: Email replies")
      - **Start/End:** times from the plan blocks
      - **Description:** brief context from the plan (priority, energy level)
    - Do NOT send notifications to attendees (use `sendUpdates: none`).
  - Confirm when done:
    > "Done — [N] blocks added to your calendar."

  If the user says no: skip and proceed to Step 5.

### Step 5: Save plan

- If `notes_tool != none`: Create a page under the output page (from config `output_page_url`) with:

  - **Title:** `Plan [date in configured language]`
  - **Content:** the complete plan with blocks, energy, weekly priorities

  Page structure:

  ```markdown
  ## Plan [date]

  **Morning energy:** [N]/5
  **Context:** [optional note or "—"]
  **Weekly priority:** [from weekly review]
  **Week type:** [Sprint A / Sprint B / Standard]
  **Email last check:** [ISO timestamp of when email was last scanned, or "—" if email_tool = none]

  ### Today's Blocks
  [block list from generated plan]

  **Daily goal:** If you do [X], [Y], [Z] — tonight you can disconnect.

  ### Email Actions
  [If email_tool != none and actions were accepted:]
  | Email | Action | Status |
  |-------|--------|--------|
  | [Sender — Subject snippet] | [Reply / Task added / Schedule / Delegate] | Pending |

  [If email_tool = none or no actionable emails: "—"]

  ---
  ### Afternoon Check-in
  [completed by Phase 2]

  ---
  ### Evening Close
  [completed by Phase 4]
  ```

- If `notes_tool = none`: Present the complete plan in chat as formatted markdown. Tell the user: "Here's your daily plan. You can copy it wherever you'd like."

## Phase 2 — Mid-day Check (1 min)

**Triggers:** Read from "Mid-day Check" section in config trigger mapping.

### Step 1: Energy rating

> "Energy right now? (1-5)"

### Step 2: Compare with morning

- If `notes_tool != none`: Read today's Plan page (search for "Plan [today's date]").
- If `notes_tool = none`: Ask the user: "What was your morning energy level, and what were your 3 priorities?"

Then compare:

- If drop > 2 points from morning: "Significant drop. I suggest lightening the afternoon."
- If stable or rising: "Energy is stable, keep going."

### Step 2.5: Email check (if email_tool != none)

Skip entirely if `email_tool = none`.

- Search unread emails since `email_last_check` timestamp from today's Plan page. Apply same `email_scan_labels` and `email_exclude_patterns` filters as Phase 1.
- Classify emails using the same categories as Phase 1 (reply needed, task, meeting, delegation, FYI). Discard FYI.
- If no actionable emails: say nothing about email, move to Step 3.
- If actionable emails exist, present a compact summary:
  > "[N] new emails since this morning that need attention:"
  > 1. **[Sender]** — [Subject snippet] → [suggested action]
  > ...
  > "Want to handle any of these now?"
- **If the user accepts any actions, apply the Pivot principle:** for every task or reply block added, propose what to remove or defer from the afternoon.
  > "Adding [action]. What do we drop from the afternoon? Options: [A], [B], [C]."
- Update `email_last_check` timestamp on the Plan page.
- Add any new email actions to the "Email Actions" table on the Plan page.

### Step 3: Quick status

> "Of this morning's priorities ([X], [Y], [Z]), what did you get done?"

- If on track: "You're doing well. This afternoon focus on [remaining priority]."
- If behind: recalibrate without judgment. "OK, [X] is still open. Want to put it in the afternoon focus block or move it to tomorrow?"

### Step 4: Post-work logic

Read "Fixed Commitments" from config body. Check if today has a commitment that blocks the evening. If today is NOT blocked:

| Current energy | Suggestion |
|----------------|------------|
| >= 3 | "After work you have the personal time window. Reset break first, then [personal task]." |
| 2 | "Low energy. If you want, 20 min of something light after work. No coding." |
| 1 | "You've given enough today. After work, go straight to relax. Zero guilt." |

If today IS blocked by a commitment:
> "You have [commitment name] after work today. Plan is to wrap up and head there."

### Step 5: Save check-in

- If `notes_tool != none`: Update today's Plan page, "Afternoon Check-in" section:

  ```markdown
  ### Afternoon Check-in
  **Energy:** [N]/5 | Completed: [list] | Remaining: [list] → [action]
  **New email actions:** [count of new actions from Step 2.5, or "—" if email_tool = none or no new emails]
  ```

  Also: if email actions from the morning "Email Actions" table have been completed, update their Status from "Pending" to "Done".

- If `notes_tool = none`: Present the check-in summary in chat as formatted markdown. Tell the user: "Here's your check-in summary. You can copy it wherever you'd like."

## Phase 3 — Pivot (2 min)

**Triggers:** Read from "Pivot" section in config trigger mapping.

### Step 1: Gather info

> "What happened? Describe the new thing."

### Step 2: Honest evaluation

- If `notes_tool != none`: Read today's Plan page and weekly priorities from the weekly review.
- If `notes_tool = none`: Ask the user what their current plan and weekly priority are.

Compare:

> "The weekly priority is [X]. Is this new thing more important? Let's see."

**Decision matrix:**

| The new thing... | Action |
|------------------|--------|
| Has a deadline today and impacts the client/stakeholder | "Yes, it's a priority. Let's remove [less urgent task] from the plan." |
| Important but not urgent | "Not urgent. I suggest scheduling it for [day with space] and keeping the plan." |
| Someone else's request, not critical | "Someone else can wait. Your priority today is [X]. Reply later." |
| Anxiety/reactivity, not real urgency | "Stop. This feels urgent but it's not. This morning's plan is still valid." |

**Principle: NEVER add without removing.** If something enters the plan, explicitly ask:
> "OK, we're adding [new thing]. What do we remove? Options: [A], [B], [C]."

### Step 3: Confirm

> "Do you want to proceed with the switch or keep the original plan?"

### Step 4: Save pivot

If the user changes the plan:

- If `notes_tool != none`: Update the daily page with the new blocks. Add note:
  > "Pivot at [time]: [reason]. Removed [X], added [Y]."

- If `notes_tool = none`: Present the updated plan in chat as formatted markdown, including the pivot note.

## Phase 4 — Evening Close (2 min)

**Triggers:** Read from "Evening Close" section in config trigger mapping.

### Step 1: Read the plan

- If `notes_tool != none`: Retrieve today's Plan page. Read the 3 priorities and planned blocks.
- If `notes_tool = none`: Ask the user: "What were your 3 priorities this morning?"

### Step 2: What did you complete?

> "What did you complete today?"

Or, if the task database is connected and tasks are updated, deduce it from status changes.

If `email_tool != none` and the Plan page has an "Email Actions" table: reconcile email-derived actions. For each Pending email action, check if it was completed (via task database status or user confirmation). Update the table status to "Done" or "Carried → tomorrow".

### Step 3: Final energy rating

> "End-of-day energy? (1-5)"

### Step 4: The verdict

Compare planned priorities vs completed:

| Situation | Message |
|-----------|---------|
| All 3 priorities done | "You did what mattered. Relax, you earned it." |
| 2 of 3 done, the third not critical | "Solid day. [Missing task] can wait until tomorrow. Disconnect." |
| 1 of 3 or less, but with good reason (pivot, low energy) | "Imperfect day but you protected what was possible. That's fine." |
| Day went badly | "It happens to everyone. Tomorrow we recalibrate with the Morning Plan. Tonight disconnect anyway — ruminating doesn't produce results, rest does." |

**IMPORTANT:** The verdict is ALWAYS oriented toward permission to disconnect. Never close with "you should have done more." Guilt doesn't produce results, rest does.

### Step 5: Note for tomorrow

> "Anything to remember for tomorrow morning?"

If yes, note it. If no, skip.

### Step 6: Save evening close

- If `notes_tool != none`: Update today's Plan page, "Evening Close" section:

  ```markdown
  ### Evening Close
  **Evening energy:** [N]/5
  **Completed:** [list]
  **Not completed:** [list + brief reason]
  **Email actions resolved:** [N of M, or "—" if no email actions]
  **Verdict:** [message from the verdict]
  **Note for tomorrow:** [text or "—"]
  ```

- If `notes_tool = none`: Present the evening close summary in chat as formatted markdown. Tell the user: "Here's your evening close. You can copy it wherever you'd like."

## Trigger Mapping

Read triggers from the "Trigger Mapping" section in config body. Match user messages against the appropriate trigger list for each phase. Also use time-based defaults:

| Time | Default |
|------|---------|
| Before 2 hours into the workday (and no Plan exists today — check notes tool or conversation history) | Suggest Phase 1 |
| Middle of the workday | Suggest Phase 2 |
| Last hour of workday or after | Suggest Phase 4 |
| Urgency words at any time | Phase 3 always |

## Extra Commands

| User intent | Action |
|-------------|--------|
| "ideal week" / "show me the week" | Show the ideal week template from config body for the current day |
| "what week is it?" / "sprint A or B?" | Calculate ISO week from date, apply configured parity |
| "energy patterns" / "trend" | Analysis from `references/energy-patterns.md` in this skill's directory, using Plan pages from the last 2+ weeks |
| "customize schedule" / "update my week" | Direct the user to run `/update-schedule` |
| "email settings" / "update email config" | Show current `email_scan_labels` and `email_exclude_patterns` from config. Allow user to add/remove labels and exclude patterns. Save updated config. |

## Dependencies

| Service | Required | Purpose |
|---------|----------|---------|
| Task database MCP | Recommended | Notion, Airtable, Linear, or similar. Enables automatic task/project queries. Without it, the user provides information conversationally. |
| Calendar MCP | No | Google Calendar, Outlook, or similar. Enhances Morning Plan with real calendar events. Without it, uses ideal week template only. |
| Email MCP | No | Gmail, Outlook, or similar. Enables email scanning in Morning Plan and Mid-day Check. Without it, email processing is skipped entirely. |
| planning-review-system | No (but recommended) | Morning Plan reads weekly review. Without PRS, that context is skipped. |

## Principles (ALWAYS apply)

1. **Zero overload** — every touchpoint < 5 min, only the Morning Plan is recommended, the rest is optional
2. **Quarter > Week > Day** — the priority hierarchy is always respected
3. **Never add without removing** — if something enters the plan, something else leaves
4. **Permission to disconnect** — the Evening Close exists to tell you "you've done enough"
5. **Radical honesty** — if something is not a priority, the skill says so clearly
6. **Respect the rhythm** — never suggest waking up at 6 AM or sacrificing family/rest
7. **Non-negotiable breaks** — built into the plan, not optional
