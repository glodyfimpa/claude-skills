/**
 * Local backend server that receives listings from the Chrome Extension.
 * Applies the same scoring, filtering, and Notion saving as the main scanner.
 *
 * Usage: npm run extension:server
 */
import { createServer } from 'http';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { SEARCH_CONFIG, SUBLETTING_BLOCKERS, SKIP_CONTRACTS, EXCLUDED_ZONES } from './config.js';
import { getZoneRate, quickScore, investmentStatus, fullROI } from './scoring.js';
import { Deduplicator } from './dedup.js';
import { NotionSync } from './notion.js';

// Load .env
const envPath = new URL('.env', import.meta.url).pathname;
if (existsSync(envPath)) {
  for (const line of readFileSync(envPath, 'utf-8').split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const eq = t.indexOf('=');
    if (eq === -1) continue;
    if (!process.env[t.substring(0, eq).trim()]) process.env[t.substring(0, eq).trim()] = t.substring(eq + 1).trim();
  }
}

const PORT = 3456;
const notion = new NotionSync(process.env.NOTION_TOKEN, process.env.NOTION_DATABASE_ID);
const dedup = new Deduplicator();
const stats = { received: 0, saved: 0, skipped: 0, errors: 0 };

async function init() {
  await notion.verifySchema();
  await notion.loadExistingEntries();

  const server = createServer(async (req, res) => {
    // CORS headers for extension
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.writeHead(200);
      res.end();
      return;
    }

    if (req.method === 'GET' && req.url === '/api/stats') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(stats));
      return;
    }

    if (req.method === 'POST' && req.url === '/api/listings') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        try {
          const payload = JSON.parse(body);
          await handlePayload(payload);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, stats }));
        } catch (err) {
          stats.errors++;
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: err.message }));
        }
      });
      return;
    }

    if (req.method === 'POST' && req.url === '/api/export') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        try {
          const payload = JSON.parse(body);
          const results = await processExport(payload);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, ...results }));
        } catch (err) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: err.message }));
        }
      });
      return;
    }

    res.writeHead(404);
    res.end('Not found');
  });

  server.listen(PORT, () => {
    console.log(`\nExtension backend running on http://localhost:${PORT}`);
    console.log('Waiting for data from Chrome Extension...\n');
    console.log('Endpoints:');
    console.log(`  POST /api/listings  - receive listings in real-time`);
    console.log(`  POST /api/export    - batch export from extension`);
    console.log(`  GET  /api/stats     - current session stats\n`);
  });
}

async function handlePayload(payload) {
  if (payload.type === 'SEARCH_RESULTS') {
    for (const listing of payload.data) {
      stats.received++;
      await processSearchListing(listing);
    }
  } else if (payload.type === 'DETAIL_PAGE') {
    stats.received++;
    await processDetailListing(payload.data);
  }
}

async function processExport(payload) {
  let saved = 0;
  let skipped = 0;

  // Process detail pages (richer data)
  if (payload.detailPages) {
    for (const listing of Object.values(payload.detailPages)) {
      const result = await processDetailListing(listing);
      if (result) saved++;
      else skipped++;
    }
  }

  // Process search results that don't have detail pages
  if (payload.searchResults) {
    const detailUrls = new Set(Object.keys(payload.detailPages || {}));
    for (const listing of payload.searchResults) {
      if (detailUrls.has(listing.url)) continue;
      const result = await processSearchListing(listing);
      if (result) saved++;
      else skipped++;
    }
  }

  return { saved, skipped, total: saved + skipped };
}

async function processSearchListing(raw) {
  const listing = {
    url: raw.url,
    source: 'Idealista',
    title: raw.title || '',
    price: raw.price || 0,
    sqm: raw.sqm || parseFromDetails(raw.details, /(\d{2,3})\s*m[²q]/i),
    rooms: raw.rooms || parseFromDetails(raw.details, /(\d)\s*local/i),
    floor: raw.floor ?? null,
    elevator: raw.elevator ?? null,
    condoFees: raw.condoFees || 0,
    contractType: raw.contractType || null,
    zone: raw.title || '',
  };

  const textLower = (raw.description || '').toLowerCase();
  return await scoreSaveAndFilter(listing, textLower, raw.sublettingBlocked);
}

async function processDetailListing(raw) {
  const d = raw.details || {};
  const listing = {
    url: raw.url,
    source: 'Idealista',
    title: raw.title || '',
    price: raw.price || 0,
    sqm: d.sqm || null,
    rooms: d.rooms || null,
    floor: d.floor ?? null,
    elevator: d.elevator ?? null,
    condoFees: d.condoFees || 0,
    contractType: d.contractType || null,
    address: raw.address || '',
    zone: raw.address || raw.title || '',
  };

  const fullText = (raw.fullText || raw.description || '').toLowerCase();
  return await scoreSaveAndFilter(listing, fullText, d.sublettingBlocked);
}

async function scoreSaveAndFilter(listing, textLower, sublettingBlocked) {
  // Basic filters
  if (listing.price === 0) { stats.skipped++; return false; }

  const totalCost = listing.price + (listing.condoFees || 0);
  if (totalCost > SEARCH_CONFIG.maxPrice) { stats.skipped++; return false; }

  if (listing.contractType && SKIP_CONTRACTS.some(sc => listing.contractType.toLowerCase().includes(sc))) {
    stats.skipped++; return false;
  }

  if (listing.floor !== null && listing.floor > 0 && listing.elevator === false) {
    stats.skipped++; return false;
  }

  if (sublettingBlocked || SUBLETTING_BLOCKERS.some(kw => textLower.includes(kw))) {
    stats.skipped++; return false;
  }

  if (EXCLUDED_ZONES.some(z => listing.zone.toLowerCase().includes(z))) {
    stats.skipped++; return false;
  }

  const dupCheck = dedup.check(listing);
  if (dupCheck.isDuplicate) { stats.skipped++; return false; }

  // Scoring
  const zoneInfo = getZoneRate(listing.zone) || getZoneRate(listing.title);
  const nightlyRate = zoneInfo?.rate || 85;
  const zoneName = zoneInfo?.zone || 'sconosciuta';
  const score = quickScore(listing.price, listing.condoFees, nightlyRate);
  const status = investmentStatus(score);

  if (status === 'Skip') { stats.skipped++; return false; }

  const roi = fullROI(listing.price, listing.condoFees, nightlyRate);
  const qualified = {
    ...listing, zoneName, nightlyRate, totalCost, score, status, roi,
    scanDate: new Date().toISOString().split('T')[0],
    notes: [
      `Rent: ${listing.price}\u20AC + Condo: ${listing.condoFees || 0}\u20AC = Total: ${totalCost}\u20AC`,
      `Size: ${listing.sqm || '?'} m\u00B2 | Floor: ${listing.floor ?? '?'} | Elevator: ${listing.elevator ? 'S\u00EC' : listing.elevator === false ? 'No' : '?'}`,
      `Quick Score: ${score} (${status}) | ROI: ${roi.roi}% | Break-even: ${roi.breakEvenDays}d`,
    ].join('\n'),
  };

  dedup.add(listing);
  stats.saved++;
  console.log(`  \u2713 [${status}] Score ${score} | ${totalCost}\u20AC | ${zoneName} | ${listing.title?.substring(0, 55)}`);

  await notion.saveListing(qualified);

  // Append to daily JSON
  const dateStr = new Date().toISOString().split('T')[0];
  const jsonPath = new URL(`idealista-extension-${dateStr}.json`, import.meta.url).pathname;
  const existing = existsSync(jsonPath) ? JSON.parse(readFileSync(jsonPath, 'utf-8')) : [];
  existing.push(qualified);
  writeFileSync(jsonPath, JSON.stringify(existing, null, 2));

  return true;
}

function parseFromDetails(detailsStr, re) {
  if (!detailsStr) return null;
  const m = detailsStr.match(re);
  return m ? parseInt(m[1]) : null;
}

init().catch(console.error);
