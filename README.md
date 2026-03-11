# Claude Skills

Personal collection of Claude Code skills for productivity and business automation.

## Skills

| Skill | Description |
|-------|-------------|
| [planning-review-system](./planning-review-system/) | Weekly review and quarterly planning based on GTD methodology. Tool-agnostic: works with any task database MCP (Notion, Airtable, Linear) or in chat-only mode. Auto-detects available tools and configures itself on first run. |
| [time-energy-manager](./time-energy-manager/) | Daily time and energy management in 4 phases: Morning Plan, Mid-day Check, Pivot, Evening Close. Tool-agnostic: works with any task/calendar MCP or in chat-only mode. Adapts scheduling to energy levels (1-5). |
| [short-term-rental-analyzer](./short-term-rental-analyzer/) | Evaluate Airbnb investment opportunities with market data and ROI projections. Optimized for Milan, expandable to other cities. |
| [property-acquisition-tracker](./property-acquisition-tracker/) | Automated property scouting for short-term rental investments in Milan. Scans Immobiliare.it, Idealista, Casa.it for apartments, applies investment scoring, and saves qualified properties to Notion. |
| [java-spring-clean-code](./java-spring-clean-code/) | Clean Code standards for Java 8-21 LTS and Spring Boot 3. Includes SOLID principles, naming conventions, exception handling, testing patterns, Lombok/JPA best practices, and SonarQube metrics. |

## Usage

### Standalone (single skill)

Copy a skill folder to your Claude Code skills directory:

```bash
# Copy to personal skills (available in all projects)
cp -r planning-review-system ~/.claude/skills/

# Or to project-level skills (available only in that project)
cp -r planning-review-system /your/project/.claude/skills/
```

On first use, the skill will auto-detect your available MCP tools (Notion, Google Calendar, Gmail, etc.) and run a mini-setup to configure itself. If no tools are detected, it will ask you for the information it needs to function, or fall back to chat-only mode.

### As part of the life-os plugin

These skills are also available as part of the [life-os](https://github.com/glodyfimpa/life-os) Claude Code plugin, which adds slash commands, shared configuration, and coordinated workflows between skills.

## Structure

Each skill folder contains:
- `SKILL.md` - Main instructions and workflow
- `references/` - Templates, patterns, and supporting documentation

## Author

Glody Fimpa
