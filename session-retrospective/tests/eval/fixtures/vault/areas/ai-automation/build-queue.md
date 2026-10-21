---
title: Build Queue — Autonomous Agents
doc_type: knowledge
slug: build-queue
queue: []
---

# Build Queue — Autonomous Agents

Input queue of the headless Builder. Machine contract: only what is left to build.
Fields: `slug`, `title`, `repo_target` (claude-skills | bnb-investment-toolkit | claude-autopilot | life-os), `effort` (simple|standard|complex), `added`, `notes` (optional).
Write it only through `queue_parser.append_voice` (`areas/ai-automation/autonomous-agents/queue_parser.py`).
