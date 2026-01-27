---
name: property-acquisition-tracker
description: |
  Automated property scouting for short-term rental investments in Milan. Use when scanning rental portals (Immobiliare.it, Idealista, Casa.it) for apartments, filtering listings by investment criteria, calculating quick scores, and saving qualified properties to Notion. Triggers include: "scan for apartments", "find rental properties", "search listings for BnB", "scout properties in Milan", or requests to automate property research. Works with browser automation to navigate portals, extract listing data, deduplicate across platforms, apply scoring criteria, and save to Notion database with structured fields.
---

# Property Acquisition Tracker

Automate rental property scouting in Milan for short-term rental investments. Navigate real estate portals, extract listing data, apply investment scoring, deduplicate across platforms, save qualified properties to Notion.

## Prerequisites

Before running, verify:
1. Browser access to Immobiliare.it and Idealista
2. Notion connector enabled with write access to "(DB) Appartamenti BNB" database
3. Investment criteria from `references/scoring.md` loaded

## Workflow

### Step 1: Configure Search Parameters

Default search criteria for Milan bilocali:
- Property type: Bilocale (2 locali)
- Size: 50-65 m²
- Price range: 800-1,500€/month (rent only, excluding condo fees)
- Contract type: 4+4 (canone libero) — REQUIRED, skip transitorio/uso foresteria
- Zones: Within circonvallazione + strategic extensions (see `references/portals.md`)

User can override any parameter. If user specifies different criteria, use those instead.

### Step 2: Navigate Portals

For each portal (Immobiliare.it first, then Idealista):

1. Open portal search page with filters applied
2. Set location to Milano
3. Apply property type and size filters
4. Apply price range filter
5. Navigate through results pages (max 5 pages per portal to avoid overload)

See `references/portals.md` for URL structures and filter parameters.

### Step 3: Extract Listing Data

For each listing in search results, extract:

| Field | Source | Required |
|-------|--------|----------|
| Title | Page title/headline | Yes |
| URL | Listing page URL | Yes |
| Price | Monthly rent amount | Yes |
| Size (m²) | Property features | Yes |
| Rooms | "Locali" count | Yes |
| Zone | Neighborhood from address | Yes |
| Contract type | "Tipologia contratto" field | Yes |
| Floor | "Piano" if available | No |
| Condo fees | "Spese condominiali" if listed | No |
| Energy class | Energy certificate badge | No |

Skip listings that:
- Are outside target zones (see zone list in `references/portals.md`)
- Exceed 1,500€ rent (before user applies stricter filters)
- Are smaller than 45 m² or larger than 70 m²
- Have contract type other than 4+4 (skip: transitorio, uso foresteria, concordato 3+2)

### Step 4: Deduplicate

Before processing any listing, check if it already exists:

1. Normalize address: lowercase, remove punctuation, standardize abbreviations ("via" = "v.", "corso" = "c.so")
2. Compare against already-extracted listings in current session
3. If address matches (fuzzy, 90% similarity), check sqm (±5) and price (±50€)
4. If duplicate found, skip and note which portal had it first

Maintain a session list of processed addresses to avoid cross-portal duplicates.

### Step 5: Calculate Quick Score

For each unique listing, calculate quick investment score:

```
quick_score = (zone_avg_nightly_rate × 21) / monthly_rent × 10
```

Zone average nightly rates (reference):
- Centro/Brera/Duomo: 125€
- Navigli/Isola: 107€
- Porta Romana/Buenos Aires: 95€
- Città Studi/Lambrate: 80€

Score interpretation:
- ≥30: High potential, save with status "Hot"
- 25-29: Moderate potential, save with status "Review"
- <25: Skip unless user explicitly requests saving all

### Step 6: Update Notion Database

For qualified listings, add to Notion database "(DB) Appartamenti BNB" with:

**Required fields:**
- Name: Listing title (e.g., "Bilocale via Savona 25, Navigli, Milano | 2 locali | 55 m²")
- URL: Full listing URL
- Aggiunto su BNB: false (checkbox unchecked - this triggers Make automation later)

**New structured fields to add:**
- Prezzo: Monthly rent in euros (number)
- Mq: Size in square meters (number)
- Zona: Neighborhood name (text)
- Locali: Room count (number)
- Piano: Floor number if available (text, e.g., "3°" or "Terra")
- Spese Condo: Condo fees if available (number)
- Score: Calculated quick score (number)
- Status Investimento: "Hot", "Review", or "Skip" (select)
- Fonte: Portal name "Immobiliare" or "Idealista" (select)
- Data Scansione: Current date (date)

**Notes field:**
Write a mini-report with key data:

```
Rent: 1,200€ + Condo: 150€ = Total: 1,350€
Size: 55 m² | Floor: 3° | Energy: C
Zone avg rate: 107€/night
Quick Score: 28.5 (Review)
```

### Step 7: Report Summary

After completing scan, provide summary:
- Total listings scanned per portal
- Duplicates found and skipped
- Listings saved to Notion (by status)
- Listings skipped (with reason counts: price, zone, score)

Example output:

```
Scan completed:
	∙	Immobiliare.it: 47 listings scanned
	∙	Idealista: 52 listings scanned
	∙	Duplicates skipped: 12
	∙	Saved to Notion: 18 (Hot: 5, Review: 13)
	∙	Skipped: 69 (low score: 41, wrong zone: 18, price: 10, wrong contract: 8)
```

## Notion Database Schema Updates

If the Notion database "(DB) Appartamenti BNB" lacks the structured fields, create them first:

| Property | Type | Options |
|----------|------|---------|
| Prezzo | Number | Format: Euro |
| Mq | Number | - |
| Zona | Text | - |
| Locali | Number | - |
| Piano | Text | - |
| Spese Condo | Number | Format: Euro |
| Score | Number | Format: Number (1 decimal) |
| Tipo Contratto | Select | 4+4, 3+2, Transitorio, Uso Foresteria |
| Status Investimento | Select | Hot, Review, Skip |
| Fonte | Select | Immobiliare, Idealista, Casa.it |
| Data Scansione | Date | - |

## Error Handling

If portal blocks access or shows captcha:
1. Pause for 30 seconds
2. Retry once
3. If still blocked, skip to next portal and note in summary

If Notion write fails:
1. Log the listing data locally
2. Continue with remaining listings
3. Report failed writes in summary

## Usage Examples

**Basic scan:**
"Scan Milan portals for bilocali under 1,300€"

**Zone-specific:**
"Find apartments in Navigli and Isola only"

**Full parameters:**
"Search Immobiliare and Idealista for 2-room apartments, 50-60 m², max 1,200€ rent, Porta Romana area"

**Continue previous:**
"Continue scanning from page 3 of Idealista"
