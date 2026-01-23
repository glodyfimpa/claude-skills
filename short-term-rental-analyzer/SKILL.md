---
name: short-term-rental-analyzer
description: |
  Analyze short-term rental investment opportunities by evaluating specific zones within a city and calculating detailed business plans with ROI projections. Use this skill when evaluating apartments for Airbnb or similar platforms, deciding which neighborhoods to invest in, or determining if rental economics make sense. Triggers include: "analyze zone for short-term rentals", "calculate ROI for Airbnb apartment", "is this neighborhood good for rentals", "create business plan", or providing apartment details with location and costs. Currently optimized for Milan with InsideAirbnb data, expandable to other cities.
---

# Short-Term Rental Analyzer

Evaluate investment opportunities for short-term rental properties using real market data and financial projections. The skill combines zone analysis with detailed business planning to support go/no-go decisions.

## Core Workflow

Input property details. The skill pulls market data, calculates financial projections, generates business plan spreadsheet, provides recommendation based on three key thresholds including minimum ROI targets and maximum break-even requirements that together determine whether the property merits investment or should be passed over.

### Step 1: Market Analysis

Run `market_analyzer.py` to pull real data from InsideAirbnb for the target zone:

```python
from scripts.market_analyzer import MarketAnalyzer

analyzer = MarketAnalyzer(city="milan")
analyzer.load_data()
result = analyzer.analyze_zone("Navigli", bedrooms=2)
```

The analyzer downloads listings and calendar data, filters by neighborhood and property characteristics, calculates occupancy rates from booking patterns, provides price statistics. Output includes average nightly rate, median rate, estimated occupancy percentage, total competitor count, property type distribution, price ranges from 25th to 90th percentile.

### Step 2: Business Plan Calculation

Feed market data into `business_plan_calculator.py` along with cost structure:

```python
from scripts.business_plan_calculator import BusinessPlanCalculator, PropertyCosts, MarketData

costs = PropertyCosts(
    monthly_rent=1200,
    condo_fees=150,
    utilities=80,
    wifi=30,
    cleaning_per_stay=60,
    supplies=50,
    insurance=40,
    property_mgmt_percent=0.10
)

market = MarketData(
    avg_price_per_night=85,
    occupancy_rate=0.70
)

calculator = BusinessPlanCalculator(costs, market)
projection = calculator.calculate_monthly_projection()
recommendation = calculator.generate_decision_recommendation()
```

Calculator applies Italian tax structure. Includes cedolare secca at 21 percent, Airbnb platform commission at 15 percent, standard stay length patterns averaging three nights per booking. Financial model accounts for fixed monthly costs separate from variable per-stay expenses like cleaning, calculates property management fees as percentage of net revenue after platform commission, projects both monthly profit and annualized ROI against initial investment proxy using annual rent total.

The recommendation engine scores properties against three thresholds with minimum and optimal levels:

| Metric | Minimum | Optimal |
|--------|---------|---------|
| Break-even | ≤ 10 days | ≤ 8 days |
| ROI (profit/total costs) | ≥ 40% | ≥ 60% |
| Revenue-to-Rent Ratio | ≥ 2.5x | ≥ 3x |

Properties must meet ALL THREE minimum criteria to receive a GO recommendation. Confidence level depends on how many optimal thresholds are met: Excellent (3/3 optimal), High (2/3 optimal), Medium (meets minimums only).

### Step 3: Excel Business Plan Generation

Create formatted spreadsheet using the template:

```python
from scripts.create_template import create_business_plan_template
import shutil

# Generate base template
template_path = create_business_plan_template()

# Copy to output location
shutil.copy(template_path, f"/mnt/user-data/outputs/{property_name}_business_plan.xlsx")
```

Template includes three interconnected sheets: Inputs captures property details, market data, cost structure, platform assumptions. Calculations contains formulas for revenue projections, cost totals, profit computation, ROI calculation, break-even analysis. Summary displays key metrics with visual pass/fail indicators against decision criteria, formatted for quick review by stakeholders or decision makers who need to approve the investment before contracts get signed and deposits get transferred to property owners.

Users can modify input values directly in Excel to run scenario analyses. Adjust occupancy assumptions, test different pricing strategies, model various cost structures. All calculations update automatically through formula linkages between sheets.

### Step 4: Present Findings

Combine market analysis data with business plan projections into recommendation report. Include zone competitiveness assessment, pricing positioning relative to market, detailed monthly financial breakdown, sensitivity analysis showing impact of occupancy variations, final go/no-go recommendation with supporting rationale.

Report format should address key stakeholder questions: Is the zone attractive for short-term rentals? Does the property's economics justify investment? What are the main risk factors? How sensitive is profitability to occupancy rate changes?

## Italian Tax Rules (Cedolare Secca)

Short-term rentals in Italy follow a progressive tax structure based on number of properties. These rules may change annually; verify current legislation before making investment decisions.

**Current structure (2025):**

| Properties | Tax Treatment |
|------------|---------------|
| 1st property | 21% cedolare secca (flat tax) |
| 2nd property | 26% cedolare secca on lower-earning property, 21% on higher-earning |
| 3+ properties | Requires P.IVA (business registration), different tax regime applies |

The calculator defaults to 21% for first property analysis. For second property evaluation, pass `tax_rate=0.26`:

```python
calculator = BusinessPlanCalculator(costs, market, tax_rate=0.26)
```

When scaling beyond two properties, consult a commercialista for P.IVA regime calculations as the tax structure changes substantially.

## Key Assumptions

The model incorporates these Italian market specifics built from real-world data patterns observed across multiple property analyses conducted during skill development and testing phases:

- Average booking stay length: 3 nights
- Airbnb commission: 15% of gross revenue
- Tax rate: 21% cedolare secca (configurable, see Italian Tax Rules section)
- Monthly occupancy calculated from 30-day period
- Cleaning occurs once per stay, not per night

For properties outside Milan, InsideAirbnb may have data available. Check `CITY_DATA_URLS` dictionary in `market_analyzer.py`. If city is missing, you'll need to add its InsideAirbnb CSV URLs following the existing pattern for Milan.

## Scripts Reference

`scripts/market_analyzer.py` - Downloads and processes InsideAirbnb data, filters by zone and property type, calculates occupancy from calendar availability, provides price statistics and competitor counts. Main class `MarketAnalyzer` with methods `load_data()` and `analyze_zone()`.

`scripts/business_plan_calculator.py` - Computes financial projections, applies tax and commission rates, generates scenario analyses, provides go/no-go recommendations. Main class `BusinessPlanCalculator` with method `calculate_monthly_projection()` and `generate_decision_recommendation()`.

`scripts/create_template.py` - Generates Excel template with three linked sheets, formatted headers and styling, currency and percentage formatting, decision criteria indicators. Run directly to create template file.

## Assets

`assets/business_plan_template.xlsx` - Pre-formatted Excel workbook with input fields, automated formulas, summary dashboard. Contains three sheets: Inputs (editable parameters), Calculations (formulas), Summary (key metrics with pass/fail indicators). Users can copy this template and populate with property-specific data for each evaluation.

## Expanding to New Cities

Add city to `CITY_DATA_URLS` dictionary in `market_analyzer.py`:

```python
CITY_DATA_URLS = {
    "milan": {
        "listings": "http://data.insideairbnb.com/italy/lombardy/milan/2024-09-06/data/listings.csv.gz",
        "calendar": "http://data.insideairbnb.com/italy/lombardy/milan/2024-09-06/data/calendar.csv.gz"
    },
    "rome": {
        "listings": "http://data.insideairbnb.com/italy/lazio/rome/[DATE]/data/listings.csv.gz",
        "calendar": "http://data.insideairbnb.com/italy/lazio/rome/[DATE]/data/calendar.csv.gz"
    }
}
```

Find city URLs at http://insideairbnb.com/get-the-data/. Replace `[DATE]` with most recent data snapshot date. Local regulations may differ—adjust tax rates and restrictions in calculator constants if needed for new markets.
