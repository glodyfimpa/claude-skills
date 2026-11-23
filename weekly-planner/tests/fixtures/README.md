# Fixtures for grid-stop-hook

Transcript excerpts in the Claude Code JSONL shape (one entry per line,
`type` + `message.content`). They model session `bc9dc60c`:

- `gate-no-grid.jsonl`: the 09:38 gate message. The Mon-Fri grid is a bullet list,
  with no fenced ASCII calendar. The hook must block it.
- `gate-with-grid.jsonl`: the 09:56 gate message, presented again with the fenced
  ASCII calendar (LUN..VEN headings). The hook must let it through.

The texts were rebuilt from the shape of that session, not copied from the raw
transcript, and personal details are removed. Replace them with the raw excerpt
if the hook ever disagrees with a real session.
