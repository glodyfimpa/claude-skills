#!/usr/bin/env python3
"""
Business plan calculator for short-term rental investments.
Calculates ROI, break-even, monthly projections based on market data and costs.
"""

from dataclasses import dataclass
from typing import Dict, List
import json


@dataclass
class PropertyCosts:
    """Monthly costs for a rental property"""
    monthly_rent: float
    condo_fees: float
    utilities: float
    wifi: float
    cleaning_per_stay: float
    supplies: float
    insurance: float
    property_mgmt_percent: float = 0.0  # % of revenue
    
    @property
    def fixed_monthly_costs(self) -> float:
        """Total fixed monthly costs (excluding variable costs like cleaning)"""
        return (
            self.monthly_rent +
            self.condo_fees +
            self.utilities +
            self.wifi +
            self.supplies +
            self.insurance
        )


@dataclass
class MarketData:
    """Market data from zone analysis"""
    avg_price_per_night: float
    occupancy_rate: float
    avg_stays_per_month: int = 10  # Estimated based on typical booking patterns


@dataclass
class BusinessProjection:
    """Monthly business projection results"""
    gross_revenue: float
    fixed_costs: float
    variable_costs: float
    property_mgmt_fee: float
    total_costs: float
    net_profit: float
    profit_margin: float
    annual_roi: float
    break_even_nights: int


class BusinessPlanCalculator:
    """Calculate business plan metrics for short-term rentals"""
    
    # Average stay length (nights) - can be adjusted
    AVG_STAY_LENGTH = 3
    
    # Platform commission (Airbnb charges ~3% to guests, ~14-16% to hosts)
    PLATFORM_COMMISSION = 0.15
    
    # Default tax rate (Italy cedolare secca for first property)
    DEFAULT_TAX_RATE = 0.21
    
    def __init__(self, costs: PropertyCosts, market: MarketData, tax_rate: float = None):
        """
        Initialize calculator.
        
        Args:
            costs: Property cost structure
            market: Market data from zone analysis
            tax_rate: Tax rate to apply (default: 0.21 for cedolare secca first property)
                      Use 0.26 for second property under cedolare secca
        """
        self.costs = costs
        self.market = market
        self.tax_rate = tax_rate if tax_rate is not None else self.DEFAULT_TAX_RATE
        
    def calculate_monthly_projection(self) -> BusinessProjection:
        """Calculate monthly business projection"""
        
        # Calculate nights booked per month
        nights_per_month = 30
        occupied_nights = nights_per_month * self.market.occupancy_rate
        
        # Gross revenue (before platform fees)
        gross_revenue = occupied_nights * self.market.avg_price_per_night
        
        # Net revenue after platform commission
        net_revenue = gross_revenue * (1 - self.PLATFORM_COMMISSION)
        
        # Variable costs (cleaning per stay)
        num_stays = occupied_nights / self.AVG_STAY_LENGTH
        variable_costs = num_stays * self.costs.cleaning_per_stay
        
        # Property management fee
        property_mgmt_fee = net_revenue * self.costs.property_mgmt_percent
        
        # Total costs
        total_costs = (
            self.costs.fixed_monthly_costs +
            variable_costs +
            property_mgmt_fee
        )
        
        # Net profit before taxes
        profit_before_tax = net_revenue - total_costs
        
        # Net profit after taxes
        net_profit = profit_before_tax * (1 - self.tax_rate)
        
        # Profit margin
        profit_margin = net_profit / net_revenue if net_revenue > 0 else 0
        
        # Annual ROI (assuming similar performance year-round)
        annual_profit = net_profit * 12
        annual_investment = self.costs.monthly_rent * 12  # Using rent as proxy for investment
        annual_roi = annual_profit / annual_investment if annual_investment > 0 else 0
        
        # Break-even calculation (nights needed to cover costs)
        revenue_per_night = self.market.avg_price_per_night * (1 - self.PLATFORM_COMMISSION)
        cost_per_night = self.costs.cleaning_per_stay / self.AVG_STAY_LENGTH
        contribution_per_night = revenue_per_night - cost_per_night
        
        break_even_nights = int(self.costs.fixed_monthly_costs / contribution_per_night) if contribution_per_night > 0 else 30
        
        return BusinessProjection(
            gross_revenue=gross_revenue,
            fixed_costs=self.costs.fixed_monthly_costs,
            variable_costs=variable_costs,
            property_mgmt_fee=property_mgmt_fee,
            total_costs=total_costs,
            net_profit=net_profit,
            profit_margin=profit_margin,
            annual_roi=annual_roi,
            break_even_nights=min(break_even_nights, 30)
        )
    
    def calculate_scenario_analysis(self, occupancy_variations: List[float]) -> Dict[str, BusinessProjection]:
        """Calculate projections for different occupancy scenarios"""
        scenarios = {}
        original_occupancy = self.market.occupancy_rate
        
        for variation in occupancy_variations:
            self.market.occupancy_rate = original_occupancy * variation
            scenario_name = f"{int(variation * 100)}%"
            scenarios[scenario_name] = self.calculate_monthly_projection()
        
        # Restore original occupancy
        self.market.occupancy_rate = original_occupancy
        
        return scenarios
    
    def generate_decision_recommendation(self) -> Dict[str, any]:
        """Generate go/no-go recommendation based on metrics"""
        projection = self.calculate_monthly_projection()
        
        # Decision criteria (as defined in investment analysis)
        min_roi = 0.40  # 40% annual ROI minimum
        optimal_roi = 0.60  # 60% annual ROI optimal
        min_revenue_to_rent_ratio = 2.5  # Minimum revenue/rent ratio
        optimal_revenue_to_rent_ratio = 3.0  # Optimal revenue/rent ratio
        max_break_even = 10  # Max 10 days to break even
        optimal_break_even = 8  # Optimal 8 days break even
        
        # Calculate revenue-to-rent ratio
        monthly_revenue = projection.gross_revenue * (1 - self.PLATFORM_COMMISSION)
        revenue_to_rent = monthly_revenue / self.costs.monthly_rent if self.costs.monthly_rent > 0 else 0
        
        score = 0
        optimal_count = 0
        reasons = []
        
        # ROI evaluation
        if projection.annual_roi >= optimal_roi:
            score += 1
            optimal_count += 1
            reasons.append(f"✓ ROI {projection.annual_roi:.1%} is OPTIMAL (≥{optimal_roi:.0%})")
        elif projection.annual_roi >= min_roi:
            score += 1
            reasons.append(f"✓ ROI {projection.annual_roi:.1%} meets minimum {min_roi:.0%}")
        else:
            reasons.append(f"✗ ROI {projection.annual_roi:.1%} below minimum {min_roi:.0%}")
        
        # Revenue-to-rent ratio evaluation
        if revenue_to_rent >= optimal_revenue_to_rent_ratio:
            score += 1
            optimal_count += 1
            reasons.append(f"✓ Revenue/Rent {revenue_to_rent:.1f}x is OPTIMAL (≥{optimal_revenue_to_rent_ratio:.1f}x)")
        elif revenue_to_rent >= min_revenue_to_rent_ratio:
            score += 1
            reasons.append(f"✓ Revenue/Rent {revenue_to_rent:.1f}x meets minimum {min_revenue_to_rent_ratio:.1f}x")
        else:
            reasons.append(f"✗ Revenue/Rent {revenue_to_rent:.1f}x below minimum {min_revenue_to_rent_ratio:.1f}x")
        
        # Break-even evaluation
        if projection.break_even_nights <= optimal_break_even:
            score += 1
            optimal_count += 1
            reasons.append(f"✓ Break-even {projection.break_even_nights} days is OPTIMAL (≤{optimal_break_even})")
        elif projection.break_even_nights <= max_break_even:
            score += 1
            reasons.append(f"✓ Break-even {projection.break_even_nights} days meets maximum {max_break_even}")
        else:
            reasons.append(f"✗ Break-even {projection.break_even_nights} days exceeds maximum {max_break_even}")
        
        # Decision logic: must meet ALL 3 minimum criteria
        if score == 3:
            recommendation = "GO"
            if optimal_count == 3:
                confidence = "Excellent"
            elif optimal_count >= 2:
                confidence = "High"
            else:
                confidence = "Medium"
        else:
            recommendation = "NO GO"
            confidence = "High"
        
        return {
            "recommendation": recommendation,
            "confidence": confidence,
            "score": f"{score}/3",
            "optimal_metrics": f"{optimal_count}/3",
            "reasons": reasons,
            "monthly_profit": projection.net_profit,
            "annual_roi": projection.annual_roi,
            "revenue_to_rent_ratio": revenue_to_rent,
            "break_even_days": projection.break_even_nights
        }


def main():
    """Example usage"""
    
    # Example property costs
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
    
    # Example market data
    market = MarketData(
        avg_price_per_night=85,
        occupancy_rate=0.70
    )
    
    # Calculate business plan
    calculator = BusinessPlanCalculator(costs, market)
    projection = calculator.calculate_monthly_projection()
    
    print("=== Monthly Business Projection ===")
    print(f"Gross revenue: €{projection.gross_revenue:.2f}")
    print(f"Total costs: €{projection.total_costs:.2f}")
    print(f"  - Fixed: €{projection.fixed_costs:.2f}")
    print(f"  - Variable: €{projection.variable_costs:.2f}")
    print(f"  - Property mgmt: €{projection.property_mgmt_fee:.2f}")
    print(f"Net profit: €{projection.net_profit:.2f}")
    print(f"Profit margin: {projection.profit_margin:.1%}")
    print(f"Annual ROI: {projection.annual_roi:.1%}")
    print(f"Break-even nights: {projection.break_even_nights}/30")
    
    # Get recommendation
    print("\n=== Decision Recommendation ===")
    decision = calculator.generate_decision_recommendation()
    print(f"Recommendation: {decision['recommendation']} ({decision['confidence']} confidence)")
    print(f"Score: {decision['score']}")
    print("\nAnalysis:")
    for reason in decision['reasons']:
        print(f"  {reason}")


if __name__ == "__main__":
    main()
