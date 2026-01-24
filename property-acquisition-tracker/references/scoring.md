# Investment Scoring Criteria

Evaluation thresholds for short-term rental investments in Milan. Properties must meet ALL minimum criteria for GO recommendation.

## Decision Thresholds

| Metric | Minimum | Optimal |
|--------|---------|---------|
| Break-even | ≤ 10 days | ≤ 8 days |
| ROI (profit/total costs) | ≥ 40% | ≥ 60% |
| Revenue-to-Rent Ratio | ≥ 2.5x | ≥ 3x |

## Scoring Formula

**Break-even days calculation:**

```
monthly_costs = rent + condo_fees + utilities + wifi + insurance + (cleaning × stays_per_month) + maintenance_monthly
break_even_days = monthly_costs / net_daily_rate
net_daily_rate = avg_nightly_rate × (1 - airbnb_commission) × (1 - tax_rate)
```

**ROI calculation:**

```
annual_revenue = avg_nightly_rate × occupied_nights_per_year × (1 - airbnb_commission)
annual_costs = (rent + condo_fees) × 12 + utilities_annual + cleaning_annual + maintenance + insurance_annual
annual_profit = annual_revenue × (1 - tax_rate) - annual_costs
roi = annual_profit / annual_costs
```

**Revenue-to-Rent Ratio:**

```
monthly_gross_revenue = avg_nightly_rate × occupied_nights_per_month
ratio = monthly_gross_revenue / monthly_rent
```

## Cost Parameters (Milan 2025)

| Item | Value |
|------|-------|
| Cleaning fee | 50€/stay |
| Airbnb commission | 15% |
| Utilities | 4€/night occupied |
| Maintenance | 500€/year |
| Cedolare secca | 21% (first property), 26% (second) |
| Average stay length | 3 nights |
| Target occupancy | 70% |

## Quick Estimation

For rapid filtering without full calculation, use simplified scoring:

**Quick Score = (estimated_monthly_revenue / monthly_rent) × 10**

Interpretation:
- Score ≥ 30: High potential, save to Notion
- Score 25-29: Moderate potential, save with note
- Score < 25: Skip unless exceptional location

**Estimated monthly revenue formula:**

```
estimated_revenue = zone_avg_nightly_rate × 21 days (70% of 30)
```

Zone average rates (2025 estimates):
- Centro storico: 110-140€/night
- Navigli/Isola/Brera: 95-120€/night
- Porta Romana/Buenos Aires: 85-105€/night
- Città Studi/Lambrate: 70-90€/night

## Property Requirements

- Type: Bilocale (2 locali)
- Size: 50-65 m²
- Capacity: 4 guests (1 bedroom + sofa-bed in living room)
- Budget: Target 1,300€/month total (rent + condo), max 1,500€
