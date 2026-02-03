// Search parameters - override via CLI args or env vars
export const SEARCH_CONFIG = {
  minPrice: parseInt(process.env.MIN_PRICE) || 800,
  maxPrice: parseInt(process.env.MAX_PRICE) || 1500,
  minSize: parseInt(process.env.MIN_SIZE) || 50,
  maxSize: parseInt(process.env.MAX_SIZE) || 65,
  rooms: 2,
  maxPages: parseInt(process.env.MAX_PAGES) || 5,
  headless: process.env.HEADLESS !== 'false',
  debug: process.env.DEBUG === 'true',
};

// Zone average nightly rates for quick score calculation (2026 market data, bilocale 4 ospiti)
export const ZONE_RATES = {
  'centro storico': 155, 'duomo': 155, 'brera': 155, 'magenta': 155,
  'quadrilatero': 155, 'san babila': 155, 'montenapoleone': 155,
  'navigli': 125, 'isola': 125, 'garibaldi': 125, 'porta nuova': 125,
  'porta romana': 110, 'buenos aires': 110, 'porta venezia': 110,
  'centrale': 110, 'sempione': 110, 'ticinese': 110, 'loreto': 110,
  'città studi': 85, 'lambrate': 85, 'lodi': 85, 'brenta': 85,
  'turro': 85, 'nolo': 85,
};

// Priority zones (accept listings from these)
export const TARGET_ZONES = [
  // Centro storico
  'duomo', 'brera', 'quadrilatero', 'magenta', 'porta venezia',
  // High-demand
  'navigli', 'isola', 'centrale', 'buenos aires', 'porta romana',
  'ticinese', 'sempione', 'garibaldi', 'porta nuova',
  // Strategic extensions
  'città studi', 'lambrate', 'lodi', 'brenta', 'loreto', 'turro', 'nolo',
];

// Zones to exclude
export const EXCLUDED_ZONES = [
  'rogoredo', 'bisceglie', 'baggio', 'quarto oggiaro',
  'gratosoglio', 'corvetto', 'comasina', 'affori',
];

// Subletting restriction keywords
export const SUBLETTING_BLOCKERS = [
  'no sublocazione', 'non si accetta sublocazione', 'vietata sublocazione',
  'no subaffitto', 'vietato subaffitto', 'subaffitto non consentito',
  'no affitti brevi', 'affitti brevi non ammessi', 'no affitto breve',
  'no airbnb', 'vietato airbnb', 'airbnb non consentito',
  'no b&b', 'no bnb', 'vietato uso b&b',
  'solo residenziale', 'uso esclusivamente residenziale',
  'no attività ricettiva', 'vietata attività ricettiva',
  'divieto di sublocazione', 'clausola anti-sublocazione',
  'no locazione turistica', 'locazione turistica vietata',
  'regolamento condominiale vieta', 'il proprietario non consente',
  'contratto prevede divieto',
];

// Valid contract types
export const VALID_CONTRACTS = ['4+4', 'libero', 'canone libero'];
export const SKIP_CONTRACTS = ['transitorio', 'uso foresteria', '3+2', 'concordato', 'studenti'];
