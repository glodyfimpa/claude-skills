# Energy Patterns — Interpretation Guide

Reference for the Time & Energy Manager skill. Claude uses this guide to analyze energy data collected from daily check-ins and produce actionable insights.

## Data Collected

Each daily plan page contains:
- **Morning energy:** 1-5 (from Morning Plan)
- **Afternoon energy:** 1-5 (from Mid-day Check, optional)
- **Evening energy:** 1-5 (from Evening Close)
- **Context note:** free text (optional)
- **Day of week:** automatic from date
- **Week type:** Sprint A / Sprint B (if sprint cycle enabled)
- **Tasks completed vs. planned:** from Evening Close recap

## Energy Scale

| Level | Meaning | Morning Plan Action |
|-------|---------|---------------------|
| 5 | Full of energy, sharp | Creative deep work, complex tasks, ambitious personal projects |
| 4 | Good energy, decent focus | Standard deep work, important tasks |
| 3 | Average, functional | Important but non-creative tasks, alternate with breaks |
| 2 | Tired, hard to focus | Essential tasks only, no deep work, extra breaks |
| 1 | Drained, struggling to function | Bare minimum, protect energy, suggest stopping early |

## Patterns to Detect (after 2+ weeks)

### Daily Patterns

Analyze averages by day of week:

| Pattern | What to look for | Suggestion |
|---------|-----------------|------------|
| **Weak day** | Average < 2.5 for a specific day | "[Day] is your low point. Only light tasks." |
| **Strong day** | Average > 4 for a specific day | "[Day] is your peak. Protect deep work." |
| **Post-lunch dip** | Afternoon avg < morning avg - 2 | "The post-lunch dip is systematic. The soft re-entry is essential." |
| **Exercise effect** | Energy avg day after gym > avg other days | "Days after gym you perform better." |
| **Sprint A effect** | Sprint A week avg < Sprint B week avg | "Sprint weeks drain you. Calibrate expectations." |

### Weekly Patterns

| Pattern | What to look for | Suggestion |
|---------|-----------------|------------|
| **Descending trend** | 3+ consecutive days of decline | "Downward trend. You need a serious recovery day." |
| **Consistently low** | Weekly average < 2.5 | "Tough week. Review workload in next weekly review." |
| **Completion vs energy** | High correlation between 4-5 energy and tasks completed | Confirm: "When energy is high, you complete 60% more. Protect those moments." |

### Contextual Patterns

| Pattern | What to look for | Suggestion |
|---------|-----------------|------------|
| **Meeting drain** | Low energy on days with 3+ hours of meetings | "Heavy meeting days drain you. Only admin after." |
| **Personal project boost** | Higher energy after personal project mornings | "Working on your own projects in the morning energizes you for the rest." |
| **Weekend recovery** | Monday energy > Friday energy | "The weekend recharges you well. Respect the day off." |

## Output Format

In the weekly review (via PRS) or when the user asks about energy patterns/trends:

```
## Energy Report — Week of [date]

**Weekly average:** X.X/5
**Trend:** up / stable / down
**Best day:** [day] (avg X.X)
**Worst day:** [day] (avg X.X)

### Insights
- [Detected pattern 1 with suggestion]
- [Detected pattern 2 with suggestion]

### Suggestion for next week
[1 concrete action based on data]
```

## When NOT to Analyze

- Less than 5 days of data: "Not enough data yet. Let's keep collecting."
- Less than 2 weeks: daily averages only, no patterns
- Incomplete data (many skipped check-ins): "Data is fragmented. Try to do at least the Morning Plan and Evening Close."

## Principles

1. **Never judge** — "Energy 1 is not failure, it's information"
2. **Concrete suggestions** — not "rest more" but "on Thursdays only schedule light tasks"
3. **Honest about limits** — if data isn't enough, say so
4. **Action-linked** — every insight has a specific suggestion for the Morning Plan
