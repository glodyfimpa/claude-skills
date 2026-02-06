/**
 * Idealista Scanner - Phase 3: rebrowser-puppeteer
 *
 * Uses rebrowser-puppeteer which patches CDP Runtime.Enable detection.
 * This is the primary detection vector used by DataDome/Idealista.
 *
 * Key differences from Playwright approach:
 * - Patches Runtime.Enable CDP command (DataDome's main detection)
 * - Uses addBinding mode for execution context creation
 * - Combined with ghost-cursor for realistic mouse movement
 *
 * Usage:
 *   npm run scan:rebrowser
 */
import puppeteer from 'rebrowser-puppeteer';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { createInterface } from 'readline';
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

const notion = new NotionSync(process.env.NOTION_TOKEN, process.env.NOTION_DATABASE_ID);
const dedup = new Deduplicator();
const results = { saved: [], skipped: { lowScore: 0, wrongZone: 0, price: 0, wrongContract: 0, noElevator: 0, noSubletting: 0, duplicate: 0 } };

function delay(ms) { return new Promise(r => setTimeout(r, ms)); }

function prompt(msg) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(resolve => {
    rl.question(msg, () => { rl.close(); resolve(); });
  });
}

function humanDelay(min = 3000, max = 7000) {
  return delay(min + Math.random() * (max - min));
}

async function humanScroll(page) {
  const scrolls = 3 + Math.floor(Math.random() * 4);
  for (let i = 0; i < scrolls; i++) {
    await page.evaluate(() => window.scrollBy(0, 200 + Math.random() * 400));
    await delay(500 + Math.random() * 800);
  }
}

async function humanMouse(page) {
  const x = 200 + Math.floor(Math.random() * 800);
  const y = 200 + Math.floor(Math.random() * 400);
  await page.mouse.move(x, y, { steps: 5 + Math.floor(Math.random() * 10) });
}

// ─── MAIN ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  Idealista Scanner (rebrowser-puppeteer mode)          ║');
  console.log('╚══════════════════════════════════════════════════════════╝\n');

  await notion.verifySchema();
  await notion.loadExistingEntries();

  // Viewport sizes that look realistic
  const viewports = [
    { width: 1920, height: 1080 },
    { width: 1440, height: 900 },
    { width: 1536, height: 864 },
    { width: 1280, height: 720 },
  ];
  const viewport = viewports[Math.floor(Math.random() * viewports.length)];

  console.log(`Viewport: ${viewport.width}x${viewport.height}`);
  console.log('Launching browser with CDP patches...\n');

  const browser = await puppeteer.launch({
    headless: false,
    args: [
      `--window-size=${viewport.width},${viewport.height}`,
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-sync',
      '--lang=it-IT',
    ],
    defaultViewport: viewport,
  });

  const page = (await browser.pages())[0] || await browser.newPage();

  // Set realistic headers
  await page.setExtraHTTPHeaders({
    'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
  });

  // Navigate to Idealista
  console.log('[1/3] Navigando su Idealista...');
  await page.goto('https://www.idealista.it/affitto-case/milano-milano/', {
    waitUntil: 'domcontentloaded',
    timeout: 30000,
  });
  await humanDelay(3000, 6000);

  // Handle cookie consent
  try {
    const cookieBtn = await page.$('#didomi-notice-agree-button');
    if (cookieBtn) {
      await humanDelay(500, 1500);
      await cookieBtn.click();
      await humanDelay(1000, 2000);
    }
  } catch {}

  // Check for block
  const bodyText = await page.evaluate(() => document.body.textContent || '');
  if (bodyText.includes('non sei un robot') || bodyText.includes('captcha') || bodyText.includes('uso improprio') || bodyText.includes('dispositivo')) {
    console.log('\n⚠️  Blocco rilevato.');
    await prompt('   Risolvilo nel browser e premi INVIO... ');
    await humanDelay(1000, 2000);
  }

  // Navigate to filtered search
  console.log('[2/3] Applicando filtri di ricerca...\n');
  const searchUrl = `https://www.idealista.it/affitto-case/milano-milano/con-prezzo-da_${SEARCH_CONFIG.minPrice},prezzo-fino_${SEARCH_CONFIG.maxPrice},dimensione-da_${SEARCH_CONFIG.minSize},dimensione-fino_${SEARCH_CONFIG.maxSize}/2-locali/`;
  await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await humanDelay(3000, 6000);
  await humanScroll(page);

  // Re-check for block
  const bodyText2 = await page.evaluate(() => document.body.textContent || '');
  if (bodyText2.includes('non sei un robot') || bodyText2.includes('captcha') || bodyText2.includes('uso improprio') || bodyText2.includes('dispositivo')) {
    await prompt('\n⚠️  Blocco sulla ricerca. Risolvilo e premi INVIO... ');
  }

  // Extract listings
  console.log('[3/3] Estrazione annunci...\n');
  let totalScanned = 0;

  for (let pageNum = 1; pageNum <= SEARCH_CONFIG.maxPages; pageNum++) {
    if (pageNum > 1) {
      const pageUrl = searchUrl + `pagina-${pageNum}.htm`;
      await humanMouse(page);
      await humanDelay(2000, 4000);
      await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await humanDelay(3000, 6000);
      await humanScroll(page);
    }

    const listingUrls = await page.evaluate(() => {
      const urls = new Set();
      document.querySelectorAll('a').forEach(a => {
        if (/\/immobile\/\d{5,}\/?/.test(a.href)) urls.add(a.href.split('?')[0]);
      });
      return [...urls];
    });

    console.log(`[Idealista] Pagina ${pageNum}: ${listingUrls.length} annunci trovati`);
    if (listingUrls.length === 0) {
      const bt = await page.evaluate(() => document.body.textContent || '');
      if (bt.includes('non sei un robot') || bt.includes('dispositivo') || bt.includes('uso improprio')) {
        await prompt('⚠️  Blocco rilevato. Risolvilo e premi INVIO... ');
        await page.reload({ waitUntil: 'domcontentloaded' });
        await humanDelay(2000, 3000);
        continue;
      }
      break;
    }

    for (const url of listingUrls) {
      totalScanned++;
      await humanMouse(page);
      await humanDelay(3000, 7000);
      await processListing(page, url);
    }
  }

  await browser.close();

  // Output
  const dateStr = new Date().toISOString().split('T')[0];
  writeFileSync(`idealista-rebrowser-${dateStr}.json`, JSON.stringify(results.saved, null, 2));

  const hot = results.saved.filter(l => l.status === 'Hot').length;
  const review = results.saved.filter(l => l.status === 'Review').length;
  const watch = results.saved.filter(l => l.status === 'Watch').length;
  const skipTotal = Object.values(results.skipped).reduce((a, b) => a + b, 0);

  console.log('\n══════════════════════════════════════════════════════════');
  console.log(`Idealista scan completato: ${totalScanned} annunci scansionati`);
  console.log(`  Salvati: ${results.saved.length} (Hot: ${hot}, Review: ${review}, Watch: ${watch})`);
  console.log(`  Scartati: ${skipTotal}`);
  notion.printStats();
  console.log('══════════════════════════════════════════════════════════');
}

// ─── LISTING PROCESSING ─────────────────────────────────────────────────────

async function processListing(page, url) {
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
    await humanDelay(2000, 4000);

    const fullText = await page.evaluate(() => document.body.textContent || '');
    if (fullText.length < 200) return;
    if (fullText.includes('non sei un robot') || fullText.includes('dispositivo') || fullText.includes('uso improprio')) {
      await prompt('⚠️  Blocco su annuncio. Risolvilo e premi INVIO... ');
      await page.reload({ waitUntil: 'domcontentloaded' });
      await humanDelay(1000, 2000);
      return;
    }

    const textLower = fullText.toLowerCase();

    const listing = {
      url,
      source: 'Idealista',
      title: await evalText(page, 'h1, .main-info__title-main, [class*="title"]'),
      price: extractPrice(fullText),
      sqm: extractNum(fullText, /(\d{2,3})\s*m²/i) || extractNum(fullText, /(\d{2,3})\s*mq/i),
      rooms: extractNum(fullText, /(\d)\s*local/i),
      floor: extractFloor(textLower),
      elevator: /ascensore\s*[:.]?\s*s[iì]/i.test(fullText) || /con ascensore/i.test(fullText),
      condoFees: extractNum(fullText, /spese\s*(?:condo(?:miniali)?|condominio)\s*[:.]?\s*€?\s*(\d+)/i),
      contractType: extractContract(textLower),
      address: await evalText(page, '.main-info__title-minor, [class*="location"], [class*="address"]'),
      zone: '',
    };

    listing.zone = listing.address || listing.title || '';

    if (listing.price === 0) return;

    const totalCost = listing.price + (listing.condoFees || 0);
    if (totalCost > SEARCH_CONFIG.maxPrice) { results.skipped.price++; return; }

    if (listing.contractType) {
      if (SKIP_CONTRACTS.some(sc => listing.contractType.toLowerCase().includes(sc))) {
        results.skipped.wrongContract++; return;
      }
    }
    if (listing.floor !== null && listing.floor > 0 && !listing.elevator) {
      results.skipped.noElevator++; return;
    }
    if (SUBLETTING_BLOCKERS.some(kw => textLower.includes(kw))) {
      results.skipped.noSubletting++; return;
    }
    if (EXCLUDED_ZONES.some(z => listing.zone.toLowerCase().includes(z))) {
      results.skipped.wrongZone++; return;
    }

    const dupCheck = dedup.check(listing);
    if (dupCheck.isDuplicate) { results.skipped.duplicate++; return; }

    const zoneInfo = getZoneRate(listing.zone) || getZoneRate(listing.title);
    const nightlyRate = zoneInfo?.rate || 85;
    const zoneName = zoneInfo?.zone || 'sconosciuta';
    const score = quickScore(listing.price, listing.condoFees, nightlyRate);
    const status = investmentStatus(score);

    if (status === 'Skip') { results.skipped.lowScore++; return; }

    const roi = fullROI(listing.price, listing.condoFees, nightlyRate);
    const qualified = {
      ...listing, zoneName, nightlyRate, totalCost, score, status, roi,
      scanDate: new Date().toISOString().split('T')[0],
      notes: [
        `Rent: ${listing.price}\u20AC + Condo: ${listing.condoFees || 0}\u20AC = Total: ${totalCost}\u20AC`,
        `Size: ${listing.sqm || '?'} m\u00B2 | Floor: ${listing.floor ?? '?'} | Elevator: ${listing.elevator ? 'S\u00EC' : 'No'}`,
        `Quick Score: ${score} (${status}) | ROI: ${roi.roi}% | Break-even: ${roi.breakEvenDays}d`,
      ].join('\n'),
    };

    dedup.add(listing);
    results.saved.push(qualified);
    console.log(`  \u2713 [${status}] Score ${score} | ${totalCost}\u20AC | ${zoneName} | ${listing.title?.substring(0, 55)}`);
    await notion.saveListing(qualified);

  } catch { /* skip failed listings silently */ }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

async function evalText(page, sel) {
  try {
    return await page.evaluate((s) => {
      const el = document.querySelector(s);
      return el ? el.textContent.trim() : '';
    }, sel);
  } catch { return ''; }
}

function extractPrice(text) {
  const matches = text.match(/€\s*[\d.]+/g) || text.match(/[\d.]+\s*€/g) || [];
  for (const m of matches) { const v = parseInt(m.replace(/[€\s.]/g, '')); if (v >= 400 && v <= 5000) return v; }
  return 0;
}
function extractNum(text, re) { const m = text.match(re); return m ? parseInt(m[1]) : null; }
function extractFloor(text) {
  if (/piano\s*terra|piano\s*rialzato/i.test(text)) return 0;
  const m = text.match(/(\d+)[°º]?\s*piano/i) || text.match(/piano\s*(\d+)/i);
  return m ? parseInt(m[1]) : null;
}
function extractContract(text) {
  if (text.includes('4+4') || text.includes('canone libero')) return '4+4';
  if (text.includes('3+2') || text.includes('concordato')) return '3+2';
  if (text.includes('transitorio')) return 'Transitorio';
  if (text.includes('uso foresteria')) return 'Uso Foresteria';
  return null;
}

main().catch(console.error);
