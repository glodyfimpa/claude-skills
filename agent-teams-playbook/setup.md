# Setup — agent-teams-playbook

Read this once when configuring a workstation for agent teams. Not needed during normal use.

## Prerequisites

### Claude Code version
Minimum **v2.1.32**. Check with:
```bash
claude --version
```

### Experimental flag
Agent teams are disabled by default. Enable with the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var.

**Recommended (persistent, all sessions)** — add to `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**Alternative (one shell session)** — export in shell:
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Verify by asking Claude in a fresh session: "are agent teams enabled?" If the flag is set, Claude will know.

## Display modes

Two ways to view teammates:

### In-process (default in plain terminals)
- All teammates run inside the main terminal window.
- Navigate with **Shift+Down** to scroll teammates and message them directly.
- **Ctrl+T** toggles the task list view.
- Works in any terminal. No extra dependencies.

### Split-pane (one pane per teammate)
- Each teammate gets its own terminal pane.
- Click a pane to interact directly with that teammate's session.
- Requires **tmux** OR **iTerm2 with the `it2` CLI**.

### Auto-selection logic
With `teammateMode` set to `"auto"` (default):
- Inside an existing tmux session → split-pane via tmux.
- Inside iTerm2 with `it2` installed → split-pane via iTerm2.
- Otherwise → in-process.

### Force a mode
In `~/.claude/settings.json`:
```json
{
  "teammateMode": "in-process"
}
```
Valid values: `"auto"`, `"in-process"`, `"tmux"`.

Or per-session:
```bash
claude --teammate-mode in-process
```

## Installing tmux / iTerm2 CLI

### tmux (macOS)
```bash
brew install tmux
```

### iTerm2 `it2` CLI
1. Install the [it2 CLI](https://github.com/mkusaka/it2).
2. Enable Python API: **iTerm2 → Settings → General → Magic → Enable Python API**.

## Where teams are stored

Local state, regenerated automatically:
- **Team config**: `~/.claude/teams/<team-name>/config.json` — contains runtime IDs, do not edit manually.
- **Task list**: `~/.claude/tasks/<team-name>/`

These are not project-scoped. Do not pre-authorize edits to them.

## Known limitations to be aware of

- **No session resume with in-process teammates**: `/resume` and `/rewind` do not restore teammates. After resume, the lead may try to message teammates that no longer exist — respawn them.
- **One team per session**: a lead manages one team at a time. Clean up before starting another.
- **No nested teams**: teammates cannot spawn their own teams.
- **Lead is fixed**: the session that creates the team is the lead for its lifetime; you cannot promote a teammate.
- **Permissions set at spawn time**: cannot vary per-teammate at spawn. Modify after spawn if needed.
- **Split-pane unsupported in**: VS Code integrated terminal, Windows Terminal, Ghostty.

## Troubleshooting setup

### "Agent teams not available" error
- Confirm env var is set: `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` should print `1`.
- Restart the Claude Code session after editing `settings.json`.
- Check version: `claude --version` ≥ 2.1.32.

### Split-pane requested but in-process used
- Verify `tmux` is in `$PATH`: `which tmux`.
- For iTerm2: verify `it2` CLI installed AND Python API enabled.

### Orphan tmux sessions after team ends
```bash
tmux ls
tmux kill-session -t <session-name>
```
