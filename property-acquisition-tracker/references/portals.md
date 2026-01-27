# Portal Navigation Guide

Instructions for extracting rental listings from Italian real estate portals.

## Immobiliare.it

**Base URL for Milan rentals:**

```
https://www.immobiliare.it/affitto-case/milano/
```

**Filter parameters:**
- `criterio=rilevanza` - Sort by relevance
- `prezzoMinimo=X` - Minimum price
- `prezzoMassimo=X` - Maximum price
- `superficieMinima=X` - Minimum sqm
- `superficieMassima=X` - Maximum sqm
- `locpiualiMin=2` - Minimum rooms (2 = bilocale)
- `locpiualiMax=2` - Maximum rooms
- `contratto=libero` - Contract type 4+4 (canone libero)

**Data extraction from listing page:**
- Price: Look for element with class `in-price__price` or similar price container
- Address: Title usually contains street and neighborhood
- Size: Look for `m²` or `mq` values in features section
- Rooms: Look for `locali` count
- Floor: Look for `piano` in features (e.g., "Piano terra", "1°", "2° su 5")
- Elevator: Look for `ascensore` — if floor > 0 and no elevator, SKIP listing
- Contract type: Look for `tipologia contratto` — accept only "4+4" or "Libero", skip "Transitorio", "Uso foresteria", "3+2"
- Condo fees: Look for `spese condominio` or `spese condominiali`
- Energy class: Look for `classe energetica` badge

**Listing URL pattern:**

```
https://www.immobiliare.it/annunci/[ID]/
```

## Idealista

**Base URL for Milan rentals:**

```
https://www.idealista.it/affitto-case/milano-milano/
```

**Filter parameters (URL path based):**
- `con-prezzo-fino_X` - Maximum price
- `con-prezzo-da_X` - Minimum price
- `con-dimensione-da_X` - Minimum sqm
- `con-dimensione-fino_X` - Maximum sqm
- `2-locali/` - Bilocale filter

**Data extraction from listing page:**
- Price: Element with `info-data-price` or price span
- Address: In listing title and location section
- Size: Look for `m²` value
- Rooms: Listed in features as `habitaciones` or `locali`
- Floor: Look for `planta` or `piano`
- Elevator: Look for `ascensor` or `ascensore` in features — if floor > 0 and no elevator, SKIP listing
- Contract type: Look in listing details for "Tipo contratto" — accept only "4+4" or "Libero", skip "Transitorio", "Uso foresteria", "3+2"
- Condo fees: May appear in expenses section
- Energy class: Energy certificate section

**Listing URL pattern:**

```
https://www.idealista.it/immobile/[ID]/
```

## Casa.it

**Base URL for Milan rentals:**

```
https://www.casa.it/affitto/residenziale/milano/
```

**Filter approach:**
Use the site's filter interface to set parameters, then work with filtered results.

**Data extraction similar to other portals.**

## Deduplication Logic

Before saving any listing, check if it already exists by matching:

1. **Primary match**: Normalize address (lowercase, remove punctuation, standardize street abbreviations like "via" vs "v.") and compare
2. **Secondary confirmation**: If addresses match, verify with sqm (±5 tolerance) and price (±50€ tolerance)
3. **URL check**: Extract listing ID from URL and check against already-saved URLs

Address normalization examples:
- "Via Savona, 25" → "via savona 25"
- "V. Savona 25" → "via savona 25"
- "Corso Buenos Aires, 35/A" → "corso buenos aires 35a"

## Zone Filtering

Milan target zones (within circonvallazione + extensions):

**Priority zones (centro storico):**
Duomo, Brera, Quadrilatero, Magenta, Porta Venezia

**High-demand zones:**
Navigli, Isola, Centrale, Buenos Aires, Porta Romana, Ticinese, Sempione, Garibaldi

**Strategic extensions:**
Città Studi, Lambrate, Lodi-Brenta, Loreto, Turro

**Exclude:**
Rogoredo, Bisceglie, Baggio, Quarto Oggiaro, extreme periphery

## Contract Type Filtering

**REQUIRED: Only accept 4+4 contracts (canone libero)**

Contract types to ACCEPT:
- "4+4" or "Libero" or "Canone libero" — standard residential contract, 4 years + 4 years renewal

Contract types to SKIP:
- "Transitorio" — temporary contract (max 18 months), not suitable for stable BnB operation
- "Uso foresteria" — corporate housing, typically restrictive on subletting
- "3+2" or "Concordato" — regulated rent contract, often below market and with restrictions
- "Studenti" — student housing, seasonal and restricted

When contract type is not specified in the listing, check the detail page. If still unclear, save with "Tipo Contratto" = null and flag for manual review in Notes.

## Floor & Elevator Filtering

**REQUIRED: Elevator mandatory for floors above ground level**

Floor classification:
- "Piano terra", "Piano rialzato", "T", "R" → Ground floor, elevator NOT required
- "1°", "2°", "3°", etc. → Upper floors, elevator REQUIRED

Elevator detection:
- Look for "Ascensore: Sì" or "con ascensore" in features
- If floor info shows "3° su 5 con ascensore" → OK
- If floor info shows "3° su 5" without elevator mention → check features section
- If floor > 0 and elevator not confirmed → SKIP listing

Rationale: BnB guests arrive with luggage. Walking up stairs significantly impacts reviews and booking rates.

## Subletting Restrictions Detection

**CRITICAL: SKIP any listing that prohibits subletting or short-term rentals**

Scan the ENTIRE listing text (title, description, features, notes) for these keywords:

**Italian phrases to detect (case-insensitive):**
- "no sublocazione" / "non si accetta sublocazione" / "vietata sublocazione"
- "no subaffitto" / "vietato subaffitto" / "subaffitto non consentito"
- "no affitti brevi" / "affitti brevi non ammessi" / "no affitto breve"
- "no Airbnb" / "vietato Airbnb" / "Airbnb non consentito"
- "no B&B" / "no BnB" / "vietato uso B&B"
- "solo residenziale" / "uso esclusivamente residenziale"
- "no attività ricettiva" / "vietata attività ricettiva"
- "divieto di sublocazione" / "clausola anti-sublocazione"
- "no locazione turistica" / "locazione turistica vietata"

**Also check for:**
- Condominium rules mentioned ("regolamento condominiale vieta...")
- Owner restrictions ("il proprietario non consente...")
- Contract clauses ("contratto prevede divieto di...")

**Action:** If ANY of these phrases appear → SKIP listing immediately, do not save to Notion.

**In summary report:** Count as "no subletting allowed"
