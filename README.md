```
  ____ _                 _        ____  _    _ _ _     
 / ___| | __ _ _   _  __| | ___  / ___|| | _(_) | |___ 
| |   | |/ _` | | | |/ _` |/ _ \ \___ \| |/ / | | / __|
| |___| | (_| | |_| | (_| |  __/  ___) |   <| | | \__ \
 \____|_|\__,_|\__,_|\__,_|\___| |____/|_|\_\_|_|_|___/
```

A collection of Claude skills for productivity and business automation.

Five standalone skills covering GTD planning, energy-based scheduling, Airbnb investment analysis, property scouting, and Java code standards. Each skill auto-detects available MCP tools on first run and configures itself accordingly.

## Skills

| Skill | Does |
|-------|------|
| [planning-review-system](./planning-review-system/) | 6-phase GTD weekly review with quarterly planning. Works with any task database MCP (Notion, Airtable, Linear) or chat-only. |
| [time-energy-manager](./time-energy-manager/) | Daily planning in 4 phases (Morning Plan, Mid-day Check, Pivot, Evening Close). Adapts scheduling to energy levels 1-5. Works with any task/calendar MCP or chat-only. |
| [property-acquisition-tracker](./property-acquisition-tracker/) | Automated apartment scouting across Immobiliare.it, Idealista, Casa.it. Applies investment scoring, saves qualified properties to project tracker. Includes Node.js scanner scripts. |
| [short-term-rental-analyzer](./short-term-rental-analyzer/) | Airbnb investment analysis with InsideAirbnb market data, ROI projections, and Excel business plan generation. Covers cedolare secca tax rules. Includes Python analysis scripts. |
| [java-spring-clean-code](./java-spring-clean-code/) | Clean Code standards for Java 8-21 LTS and Spring Boot 3. SOLID principles, naming conventions, exception handling, testing patterns, Lombok/JPA best practices, SonarQube metrics. |

## Usage

### Standalone (single skill)

Skills work with Claude Code, Claude.ai, and Cowork. Pick any skill folder from this repo and follow the instructions for your platform.

#### Claude Code

```bash
git clone https://github.com/glodyfimpa/claude-skills.git
cd claude-skills

# Pick any skill folder. Two install options:

# Option A — personal (available in all projects)
cp -r planning-review-system ~/.claude/skills/

# Option B — project-level (available only in that project)
cp -r time-energy-manager /your/project/.claude/skills/
```

#### Claude.ai / Cowork

1. Download and zip any skill folder from this repo
2. Go to **Customize > Skills** → click **+** → **Upload a skill**
3. Upload the ZIP file

Requires Code execution enabled in **Settings > Capabilities**. Skills added on Claude.ai are automatically available in Cowork.

---

On first use, the skill auto-detects available MCP tools (Notion, Google Calendar, Gmail) and configures itself. No tools detected? It asks what you use. No tools at all? Chat-only mode.

### As part of the life-os plugin

`planning-review-system` and `time-energy-manager` are also available through the [life-os](https://github.com/glodyfimpa/life-os) Claude Code plugin, which adds slash commands, shared configuration, and coordinated workflows.

## Structure

```
claude-skills/
├── planning-review-system/
│   ├── SKILL.md                                     6-phase weekly review workflow
│   └── references/
│       └── weekly-template.md                       page template for review output
├── time-energy-manager/
│   ├── SKILL.md                                     4-phase daily management workflow
│   └── references/
│       └── energy-patterns.md                       pattern detection guide
├── property-acquisition-tracker/
│   ├── SKILL.md                                     portal scouting workflow
│   ├── references/
│   │   ├── portals.md                               URL patterns, filters, extraction rules
│   │   └── scoring.md                               thresholds, formulas, zone rates
│   └── scanner/                                     Node.js automation scripts
│       ├── scan.js                                  main scanner entry point
│       ├── scan-idealista.js                        Idealista-specific scraper
│       ├── scoring.js                               investment score calculator
│       ├── dedup.js                                 cross-portal deduplication
│       ├── notion.js                                Notion API integration
│       ├── find-db.js                               database discovery utility
│       ├── inspect.js                               listing inspector
│       ├── test-notion.js                           Notion connection test
│       ├── config.js                                scanner configuration
│       ├── package.json                             dependencies
│       └── .env.example                             environment template
├── short-term-rental-analyzer/
│   ├── SKILL.md                                     zone analysis + business plan workflow
│   ├── scripts/
│   │   ├── market_analyzer.py                       InsideAirbnb data pull + zone stats
│   │   ├── business_plan_calculator.py              ROI, break-even, scenario analysis
│   │   └── create_template.py                       Excel business plan generator
│   └── assets/
│       └── business_plan_template.xlsx              pre-built Excel template
├── java-spring-clean-code/
│   └── SKILL.md                                     clean code standards reference
└── README.md
```

5 skills, 10 automation scripts, 4 reference files, 1 template. No plugin infrastructure.

## License

MIT

## Author

Glody Fimpa
