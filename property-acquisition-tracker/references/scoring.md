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
| Target occupancy | 67% (20 days/month) |

## Quick Estimation

For rapid filtering without full calculation, use simplified scoring:

**Quick Score = (estimated_monthly_revenue / total_monthly_cost) × 10**

Where `total_monthly_cost = rent + condo_fees`

Interpretation:
- Score ≥ 30: High potential, save to Notion with status "Hot"
- Score 25-29: Moderate potential, save with status "Review"
- Score 20-24: Worth monitoring, save with status "Watch"
- Score < 20: Skip unless exceptional location

**Estimated monthly revenue formula:**

```
estimated_revenue = zone_avg_nightly_rate × 20 days (67% occupancy)
```

Zone average rates (2026 market data, bilocale 4 ospiti):
- Centro storico/Brera/Duomo: 130-200€/night (midpoint 155€)
- Navigli/Isola/Garibaldi: 100-160€/night (midpoint 125€)
- Porta Romana/Buenos Aires/Porta Venezia: 90-140€/night (midpoint 110€)
- Città Studi/Lambrate/Nolo: 65-110€/night (midpoint 85€)

## Property Requirements

- Type: Bilocale (2 locali)
- Size: 50-65 m²
- Capacity: 4 guests (1 bedroom + sofa-bed in living room)
- Budget: Target 1,300€/month total (rent + condo), max 1,500€
- Contract: 4+4 (canone libero) ONLY — skip transitorio, uso foresteria, 3+2
- Elevator: Required for floors above ground level (piano terra/rialzato OK without)
- Subletting: SKIP if listing prohibits sublocazione, affitti brevi, or Airbnb
