#!/usr/bin/env python3
"""
Market analyzer for short-term rentals using InsideAirbnb data.
Analyzes specific zones within a city to provide occupancy rates, pricing, and competition data.
"""

import pandas as pd
import requests
from typing import Dict, Any, Optional
from dataclasses import dataclass
import io


@dataclass
class ZoneAnalysis:
    """Results of zone analysis"""
    zone_name: str
    avg_price_per_night: float
    median_price_per_night: float
    estimated_occupancy_rate: float
    total_listings: int
    listings_per_type: Dict[str, int]
    price_percentiles: Dict[str, float]


class MarketAnalyzer:
    """Analyzes short-term rental market data for a specific city and zone"""
    
    # InsideAirbnb base URLs
    INSIDEAIRBNB_BASE = "http://data.insideairbnb.com"
    
    # City-specific data URLs (to be expanded)
    CITY_DATA_URLS = {
        "milan": {
            "listings": f"{INSIDEAIRBNB_BASE}/italy/lombardy/milan/2024-09-06/data/listings.csv.gz",
            "calendar": f"{INSIDEAIRBNB_BASE}/italy/lombardy/milan/2024-09-06/data/calendar.csv.gz"
        }
    }
    
    def __init__(self, city: str = "milan"):
        self.city = city.lower()
        self.listings_df: Optional[pd.DataFrame] = None
        self.calendar_df: Optional[pd.DataFrame] = None
        
    def load_data(self) -> bool:
        """Load InsideAirbnb data for the specified city"""
        if self.city not in self.CITY_DATA_URLS:
            print(f"City {self.city} not yet supported. Available: {list(self.CITY_DATA_URLS.keys())}")
            return False
            
        try:
            urls = self.CITY_DATA_URLS[self.city]
            
            print(f"Downloading listings data for {self.city}...")
            self.listings_df = pd.read_csv(urls["listings"], compression='gzip')
            
            print(f"Downloading calendar data for {self.city}...")
            self.calendar_df = pd.read_csv(urls["calendar"], compression='gzip')
            
            print(f"Data loaded: {len(self.listings_df)} listings")
            return True
            
        except Exception as e:
            print(f"Error loading data: {e}")
            return False
    
    def analyze_zone(self, zone_query: str, bedrooms: Optional[int] = None) -> Optional[ZoneAnalysis]:
        """
        Analyze a specific zone within the city.
        
        Args:
            zone_query: Neighborhood name or part of it (case-insensitive)
            bedrooms: Filter by number of bedrooms (optional)
            
        Returns:
            ZoneAnalysis object with market data
        """
        if self.listings_df is None:
            print("Data not loaded. Call load_data() first.")
            return None
        
        # Filter by zone
        zone_mask = self.listings_df['neighbourhood_cleansed'].str.contains(
            zone_query, case=False, na=False
        )
        zone_listings = self.listings_df[zone_mask].copy()
        
        if len(zone_listings) == 0:
            print(f"No listings found for zone: {zone_query}")
            return None
        
        # Filter by bedrooms if specified
        if bedrooms is not None:
            zone_listings = zone_listings[zone_listings['bedrooms'] == bedrooms]
            if len(zone_listings) == 0:
                print(f"No listings with {bedrooms} bedrooms in zone: {zone_query}")
                return None
        
        # Clean price data
        zone_listings['price_clean'] = zone_listings['price'].str.replace('$', '').str.replace(',', '').astype(float)
        
        # Calculate occupancy rate from calendar data
        occupancy_rate = self._calculate_occupancy_rate(zone_listings['id'].tolist())
        
        # Property type distribution
        property_types = zone_listings['property_type'].value_counts().to_dict()
        
        # Price statistics
        price_percentiles = {
            'p25': zone_listings['price_clean'].quantile(0.25),
            'p50': zone_listings['price_clean'].quantile(0.50),
            'p75': zone_listings['price_clean'].quantile(0.75),
            'p90': zone_listings['price_clean'].quantile(0.90)
        }
        
        return ZoneAnalysis(
            zone_name=zone_listings['neighbourhood_cleansed'].mode()[0],
            avg_price_per_night=zone_listings['price_clean'].mean(),
            median_price_per_night=zone_listings['price_clean'].median(),
            estimated_occupancy_rate=occupancy_rate,
            total_listings=len(zone_listings),
            listings_per_type=property_types,
            price_percentiles=price_percentiles
        )
    
    def _calculate_occupancy_rate(self, listing_ids: list) -> float:
        """Calculate average occupancy rate from calendar data"""
        if self.calendar_df is None:
            return 0.65  # Default estimate if calendar data unavailable
        
        # Filter calendar for these listings
        relevant_calendar = self.calendar_df[self.calendar_df['listing_id'].isin(listing_ids)]
        
        if len(relevant_calendar) == 0:
            return 0.65
        
        # Calculate occupancy (available='f' means booked)
        total_days = len(relevant_calendar)
        booked_days = (relevant_calendar['available'] == 'f').sum()
        
        return booked_days / total_days if total_days > 0 else 0.65


def main():
    """Example usage"""
    analyzer = MarketAnalyzer(city="milan")
    
    if analyzer.load_data():
        # Analyze Navigli zone
        result = analyzer.analyze_zone("Navigli", bedrooms=2)
        
        if result:
            print(f"\n=== Zone Analysis: {result.zone_name} ===")
            print(f"Total listings: {result.total_listings}")
            print(f"Avg price/night: €{result.avg_price_per_night:.2f}")
            print(f"Median price/night: €{result.median_price_per_night:.2f}")
            print(f"Estimated occupancy: {result.estimated_occupancy_rate:.1%}")
            print(f"\nPrice percentiles:")
            for k, v in result.price_percentiles.items():
                print(f"  {k}: €{v:.2f}")
            print(f"\nTop property types:")
            for ptype, count in list(result.listings_per_type.items())[:5]:
                print(f"  {ptype}: {count}")


if __name__ == "__main__":
    main()
