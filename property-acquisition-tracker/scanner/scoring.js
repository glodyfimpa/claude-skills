import { ZONE_RATES } from './config.js';

/**
 * Match a listing's zone/address text to a known zone and return the nightly rate.
 * Returns null if no match found.
 */
export function getZoneRate(zoneText) {
  if (!zoneText) return null;
  const normalized = zoneText.toLowerCase().trim();
  for (const [zone, rate] of Object.entries(ZONE_RATES)) {
    if (normalized.includes(zone)) return { zone, rate };
  }
  return null;
}

/**
 * Calculate quick investment score.
 * quick_score = (zone_avg_nightly_rate × 20) / total_monthly_cost × 10
 */
export function quickScore(monthlyRent, condoFees, zoneRate) {
  const totalMonthlyCost = monthlyRent + (condoFees || 0);
  if (totalMonthlyCost <= 0) return 0;
  const estimatedRevenue = zoneRate * 20; // 67% occupancy = 20 nights/month
  return Math.round((estimatedRevenue / totalMonthlyCost) * 10 * 10) / 10;
}

/**
 * Determine investment status from quick score.
 */
export function investmentStatus(score) {
  if (score >= 30) return 'Hot';
  if (score >= 25) return 'Review';
  if (score >= 20) return 'Watch';
  return 'Skip';
}

/**
 * Full ROI calculation for detailed analysis.
 */
export function fullROI(monthlyRent, condoFees, zoneRate, taxRate = 0.21) {
  const airbnbCommission = 0.15;
  const cleaningPerStay = 50;
  const utilitiesPerNight = 4;
  const maintenanceAnnual = 500;
  const avgStayLength = 3;
  const occupiedNightsYear = 365 * 0.67; // 67% occupancy
  const occupiedNightsMonth = 20;
  const staysPerMonth = occupiedNightsMonth / avgStayLength;

  const annualRevenue = zoneRate * occupiedNightsYear * (1 - airbnbCommission);
  const annualRent = (monthlyRent + (condoFees || 0)) * 12;
  const annualCleaning = cleaningPerStay * staysPerMonth * 12;
  const annualUtilities = utilitiesPerNight * occupiedNightsYear;
  const annualCosts = annualRent + annualCleaning + annualUtilities + maintenanceAnnual;
  const annualProfit = annualRevenue * (1 - taxRate) - annualCosts;
  const roi = (annualProfit / annualCosts) * 100;

  const netDailyRate = zoneRate * (1 - airbnbCommission) * (1 - taxRate);
  const monthlyCosts = monthlyRent + (condoFees || 0) + (utilitiesPerNight * occupiedNightsMonth)
    + (cleaningPerStay * staysPerMonth) + (maintenanceAnnual / 12);
  const breakEvenDays = Math.ceil(monthlyCosts / netDailyRate);

  const revenueToRent = (zoneRate * occupiedNightsMonth) / monthlyRent;

  return {
    annualRevenue: Math.round(annualRevenue),
    annualCosts: Math.round(annualCosts),
    annualProfit: Math.round(annualProfit),
    roi: Math.round(roi * 10) / 10,
    breakEvenDays,
    revenueToRent: Math.round(revenueToRent * 10) / 10,
    verdict: roi >= 40 && breakEvenDays <= 10 && revenueToRent >= 2.5 ? 'GO' : 'NO-GO',
  };
}
