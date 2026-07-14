# Plan: Create "automation-stack-advisor" Skill

## Context

During a full automation audit (April 2026), we designed a hybrid architecture:
- Claude Code Routines (Anthropic cloud, 24/7) for simple scheduled/webhook automations
- GCP Cloud Functions + Python for heavy/custom processing
- Claude Code local for development workflow (hooks, skills)
- GitHub Actions for CI/CD

The decision of WHEN to use Routines vs GCP vs GitHub Actions depends on 3 variables:
complexity, volume, and data ownership. This skill codifies that decision framework
so it's available at the moment of need — both for personal automations and client projects.

## What to Create

**File:** `claude-skills/automation-stack-advisor/SKILL.md`

A decision-support skill that guides through evaluating an automation need and recommending
the right implementation approach (Routines vs GCP vs GitHub Actions vs local Claude Code).

### Skill Structure

1. **Frontmatter** — name, description with trigger phrases (IT + EN)
2. **When to use** — trigger scenarios
3. **Decision workflow** — structured questions to classify the automation
4. **Decision matrix** — the 3-variable framework (complexity × volume × data ownership)
5. **Implementation guidance per approach** — what each path looks like concretely
6. **Client-specific considerations** — pricing tiers, compliance, upsell path
7. **Output format** — structured recommendation card

### Key Content

The skill encodes:
- The 2×2 matrix (complexity vs volume) with Routines/GCP quadrants
- The decision flowchart (< 10 simple workflows? → Routines. Custom libs? → GCP. etc.)
- Cost comparison (Routines: included in subscription vs GCP: $5-16/month vs GitHub Actions: free for public)
- Two service tiers for clients (Automation Light = Routines, Automation Pro = GCP)
- The "land and expand" pattern: start with Routines, upsell to GCP when client scales

### Conventions to Follow (from CLAUDE.md)
- Skill content in English (per feedback_code_language memory)
- Conversation/description can mix IT/EN triggers
- No bin/ directory needed (this is a prompt-based skill, no executable)
- SKILL.md is the only required file

## Verification

1. Read the created SKILL.md and verify structure matches existing skills (frontmatter format, sections)
2. Run `bash sync.sh` from claude-skills repo to sync to ~/.claude/skills/
3. Test trigger: ask "should I use Routines or GCP for this?" and verify the skill activates
