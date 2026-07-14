---
description: Review session and update CLAUDE.md with new learnings
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(ls:*)
---

Review the current conversation session and update CLAUDE.md files with any new learnings worth preserving. Follow these 5 steps exactly. Do NOT skip steps or combine them.

## Step 1: Reflect

Scan the full conversation history from this session. Identify anything worth persisting:

- **Operational fixes:** file paths corrected, config locations discovered, workarounds found
- **Preferences:** workflow preferences expressed by the user (how they want things done, what to skip, what to assume)
- **Tool/environment quirks:** gotchas, bugs, unexpected behaviors, things that work differently than expected
- **Context updates:** project status changes, new deadlines, role changes, new contacts, decisions made
- **Patterns:** bash commands discovered, code patterns that worked, integration setups

Be selective. Only capture things that will save time or prevent mistakes in future sessions. Skip anything already documented or too session-specific to be reusable.

If nothing worth saving was found, tell the user: "Nothing new to save from this session. CLAUDE.md is up to date." Stop here.

## Step 2: Find CLAUDE.md

Search for all `CLAUDE.md` and `.claude.local.md` files in the current project and workspace:

1. Check the current working directory and parent directories
2. Check `/mnt/.claude/` (Cowork workspace)
3. Check any mounted project directories

For each file found, read it and note its scope:

- **Team-shared CLAUDE.md** (in project root): facts, conventions, architecture decisions. Things any team member benefits from.
- **Personal CLAUDE.md** (in `.claude/` or workspace-level): personal preferences, workflow shortcuts, individual context.

Decide where each learning from Step 1 belongs. Personal preferences go in personal files. Project facts go in shared files. When in doubt, use the personal file.

## Step 3: Draft

For each CLAUDE.md file that needs changes, draft the additions:

- One line per concept, format: `- <thing> - <why it matters or what to do>`
- Group additions under existing sections when a matching section exists
- Create a new section only if no existing section fits
- Keep the same style and tone as the existing file
- Never duplicate information already present
- Never remove existing content unless it is explicitly wrong (corrected during this session)

## Step 4: Show

Present ALL proposed changes to the user in a clear diff format BEFORE touching any file:

For each file to modify, show:
- The file path
- Each change: the section where it goes, and the exact lines to add or modify
- Use `+` prefix for additions, `~` for modifications

Example format:
```
📄 /mnt/.claude/CLAUDE.md

Section: PREFERENCES (COWORK)
+ - Energy check-in: skip and assume 3/5 when in meetings or rushed

Section: PLUGIN PATHS (COWORK)  [NEW SECTION]
+ - life-os config: /mnt/.local-plugins/.../life-os/.claude/life-os.local.md
```

Do NOT apply anything yet. Wait for explicit approval.

## Step 5: Apply

Ask the user: "Apply these changes? (yes / edit / skip)"

- **yes**: Apply all proposed changes using the Edit tool. Confirm when done.
- **edit**: Ask what to change, revise the draft, show again (return to Step 4).
- **skip**: Discard all changes. Tell the user nothing was modified.

After applying, show a one-line summary: "Updated [filename] with [N] additions."
