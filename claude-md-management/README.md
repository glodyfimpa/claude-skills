# claude-md-management

Review the current session and update CLAUDE.md with new learnings, preferences, and context.

## Commands

| Command | Description |
|---------|-------------|
| `/revise-claude-md` | Scan the session for learnings and propose CLAUDE.md updates |

## How it works

At the end of a session (or any time), run `/revise-claude-md`. The command:

1. Scans the conversation for new learnings (fixes, preferences, context updates)
2. Finds all CLAUDE.md files and determines where each addition belongs
3. Drafts concise one-line additions grouped by section
4. Shows a diff preview before touching anything
5. Applies only after your explicit approval

## Setup

No configuration needed. Works in both Cowork and Claude Code.
