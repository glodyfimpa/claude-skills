/**
 * Idealista Scanner - Uses your REAL Chrome browser via CDP.
 *
 * How it works:
 * 1. Launches YOUR Chrome (not Playwright's) with your actual profile
 * 2. Your cookies, extensions, history = 100% real browser fingerprint
 * 3. Idealista cannot distinguish this from your normal browsing
 * 4. If captcha appears, you solve it manually, then press ENTER
 *
 * Usage:
 *   IMPORTANT: Close Chrome completely before running.
 *   npm run scan:idealista
 */
import { chromium } from 'playwright';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { execSync } from 'child_process';
import { createInterface } from 'readline';
import { homedir } from 'os';
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
const results = { saved: [], skipped: { lowScore: 0, wrongZone: 0, price: 0, wrongContract: 0, noElevator: 0, noSubletting: 0, tooSmall: 0, tooBig: 0, duplicate: 0 } };

function delay(ms) { return new Promise(r => setTimeout(r, ms)); }

function prompt(msg) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(resolve => {
    rl.question(msg, () => { rl.close(); resolve(); });
  });
}

/** Random delay between min and max ms */
function humanDelay(min = 2000, max = 4000) {
  return delay(min + Math.random() * (max - min));
}

/** Simulate human scrolling */
async function humanScroll(page) {
  const scrolls = 3 + Math.floor(Math.random() * 4);
  for (let i = 0; i < scrolls; i++) {
    await page.evaluate(() => window.scrollBy(0, 200 + Math.random() * 400));
    await delay(500 + Math.random() * 800);
  }
}

/** Move mouse randomly to simulate human behavior */
async function humanMouse(page) {
  const x = 200 + Math.floor(Math.random() * 800);
  const y = 200 + Math.floor(Math.random() * 400);
  await page.mouse.move(x, y, { steps: 5 + Math.floor(Math.random() * 10) });
}

// ─── CHROME DETECTION ────────────────────────────────────────────────────────

function findChrome() {
  const paths = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
  ];
  for (const p of paths) {
    if (existsSync(p)) return p;
  }
  return null;
}

function getChromeProfile() {
  const defaultProfile = `${homedir()}/Library/Application Support/Google/Chrome`;
  if (existsSync(defaultProfile)) return defaultProfile;
  return null;
}

function isChromeRunning() {
  try {
    const result = execSync('pgrep -x "Google Chrome"', { encoding: 'utf-8' });
    return result.trim().length > 0;
  } catch { return false; }
}

// ─── MAIN ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  Idealista Scanner (Real Chrome mode)                  ║');
  console.log('╚══════════════════════════════════════════════════════════╝\n');

  const chromePath = findChrome();
  if (!chromePath) {
    console.error('Chrome non trovato. Installa Google Chrome.');
    process.exit(1);
  }
  console.log(`Chrome: ${chromePath}`);

  const chromeProfile = getChromeProfile();
  if (chromeProfile) {
    console.log(`Profilo: ${chromeProfile}`);
  }

  await notion.verifySchema();
  await notion.loadExistingEntries();

  // Launch real Chrome executable with a lightweight dedicated profile.
  // Uses your Chrome binary (real fingerprint) but a clean profile (fast startup).
  // Cookies persist between scans in .browser-profile/
  const profileDir = new URL('.browser-profile', import.meta.url).pathname;
  console.log(`\nAvvio Chrome reale con profilo dedicato...\n`);

  const context = await chromium.launchPersistentContext(profileDir, {
    executablePath: chromePath,
    headless: false,
    args: [
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-sync',
      '--disable-extensions',
    ],
    ignoreDefaultArgs: [
      '--enable-automation',
      '--disable-component-update',
      '--disable-background-networking',
      '--enable-features=CDPScreenshotNewSurface',
    ],
    viewport: { width: 1280, height: 900 },
    locale: 'it-IT',
  });

  const page = context.pages()[0] || await context.newPage();

  // Navigate to Idealista
  console.log('[1/3] Navigando su Idealista...');
  await page.goto('https://www.idealista.it/affitto-case/milano-milano/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await humanDelay(3000, 5000);

  // Handle cookie consent
  const cookieBtn = await page.$('#didomi-notice-agree-button');
  if (cookieBtn) {
    await humanDelay(500, 1500);
    await cookieBtn.click().catch(() => {});
    await humanDelay(1000, 2000);
  }

  // Check for captcha/block
  const bodyText = await page.textContent('body').catch(() => '');
  if (bodyText.includes('non sei un robot') || bodyText.includes('captcha') || bodyText.includes('dispositivo')) {
    await prompt('\n⚠️  Captcha o blocco rilevato. Risolvilo nel browser e premi INVIO... ');
    await humanDelay(1000, 2000);
  }

  // Navigate to filtered search
  console.log('[2/3] Applicando filtri di ricerca...\n');
  const searchUrl = `https://www.idealista.it/affitto-case/milano-milano/con-prezzo-da_${SEARCH_CONFIG.minPrice},prezzo-fino_${SEARCH_CONFIG.maxPrice},dimensione-da_${SEARCH_CONFIG.minSize},dimensione-fino_${SEARCH_CONFIG.maxSize}/2-locali/`;
  await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await humanDelay(3000, 5000);
  await humanScroll(page);

  // Re-check for block after navigation
  const bodyText2 = await page.textContent('body').catch(() => '');
  if (bodyText2.includes('non sei un robot') || bodyText2.includes('captcha') || bodyText2.includes('dispositivo')) {
    await prompt('\n⚠️  Blocco sulla pagina di ricerca. Risolvilo e premi INVIO... ');
  }

  // Extract listings
  console.log('[3/3] Estrazione annunci...\n');
  let totalScanned = 0;

  for (let pageNum = 1; pageNum <= SEARCH_CONFIG.maxPages; pageNum++) {
    if (pageNum > 1) {
      const pageUrl = searchUrl + `pagina-${pageNum}.htm`;
      await humanMouse(page);
      await humanDelay(1000, 2000);
      await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await humanDelay(2000, 4000);
      await humanScroll(page);
    }

    // Extract listing URLs from current page
    const listingUrls = await page.$$eval('a', anchors => {
      const urls = new Set();
      for (const a of anchors) {
        if (/\/immobile\/\d{5,}\/?/.test(a.href)) urls.add(a.href.split('?')[0]);
      }
      return [...urls];
    });

    console.log(`[Idealista] Pagina ${pageNum}: ${listingUrls.length} annunci trovati`);
    if (listingUrls.length === 0) {
      // Might be blocked
      const bt = await page.textContent('body').catch(() => '');
      if (bt.includes('non sei un robot') || bt.includes('dispositivo')) {
        await prompt('⚠️  Blocco rilevato. Risolvilo e premi INVIO... ');
        // Retry same page
        await page.reload({ waitUntil: 'domcontentloaded' });
        await humanDelay(2000, 3000);
        continue;
      }
      break;
    }

    for (const url of listingUrls) {
      totalScanned++;
      await humanMouse(page);
      await humanDelay(2500, 5000); // slow, human-like
      await processListing(page, url);
    }
  }

  await context.close();

  // Output
  const dateStr = new Date().toISOString().split('T')[0];
  writeFileSync(`idealista-results-${dateStr}.json`, JSON.stringify(results.saved, null, 2));

  const hot = results.saved.filter(l => l.status === 'Hot').length;
  const review = results.saved.filter(l => l.status === 'Review').length;
  const skipTotal = Object.values(results.skipped).reduce((a, b) => a + b, 0);

  console.log('\n══════════════════════════════════════════════════════════');
  console.log(`Idealista scan completato: ${totalScanned} annunci scansionati`);
  console.log(`  Salvati: ${results.saved.length} (Hot: ${hot}, Review: ${review})`);
  console.log(`  Scartati: ${skipTotal} (score: ${results.skipped.lowScore}, zona: ${results.skipped.wrongZone}, prezzo: ${results.skipped.price}, contratto: ${results.skipped.wrongContract}, no asc: ${results.skipped.noElevator}, no subloc: ${results.skipped.noSubletting}, duplicati: ${results.skipped.duplicate})`);
  notion.printStats();
  console.log('══════════════════════════════════════════════════════════');
}

// ─── LISTING PROCESSING ─────────────────────────────────────────────────────

async function processListing(page, url) {
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
    await humanDelay(1500, 3000);

    const fullText = await page.textContent('body') || '';
    if (fullText.length < 200) return;
    if (fullText.includes('non sei un robot') || fullText.includes('dispositivo')) {
      await prompt('⚠️  Blocco su annuncio. Risolvilo e premi INVIO... ');
      await page.reload({ waitUntil: 'domcontentloaded' });
      await humanDelay(1000, 2000);
      return; // skip this one
    }

    const textLower = fullText.toLowerCase();

    const listing = {
      url,
      source: 'Idealista',
      title: await extractText(page, 'h1, .main-info__title-main, [class*="title"]'),
      price: extractPrice(fullText),
      sqm: extractNum(fullText, /(\d{2,3})\s*m²/i) || extractNum(fullText, /(\d{2,3})\s*mq/i),
      rooms: extractNum(fullText, /(\d)\s*local/i),
      floor: extractFloor(textLower),
      elevator: /ascensore\s*[:.]?\s*s[iì]/i.test(fullText) || /con ascensore/i.test(fullText),
      condoFees: extractNum(fullText, /spese\s*(?:condo(?:miniali)?|condominio)\s*[:.]?\s*€?\s*(\d+)/i),
      contractType: extractContract(textLower),
      address: await extractText(page, '.main-info__title-minor, [class*="location"], [class*="address"]'),
      zone: '',
    };

    listing.zone = listing.address || listing.title || '';

    // Filters
    if (listing.price === 0) return;
    if (listing.sqm && listing.sqm < 45) { results.skipped.tooSmall++; return; }
    if (listing.sqm && listing.sqm > 70) { results.skipped.tooBig++; return; }

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

    // Scoring
    const zoneInfo = getZoneRate(listing.zone) || getZoneRate(listing.title);
    const nightlyRate = zoneInfo?.rate || 80;
    const zoneName = zoneInfo?.zone || 'sconosciuta';
    const score = quickScore(listing.price, listing.condoFees, nightlyRate);
    const status = investmentStatus(score);

    if (status === 'Skip') { results.skipped.lowScore++; return; }

    const roi = fullROI(listing.price, listing.condoFees, nightlyRate);
    const qualified = {
      ...listing, zoneName, nightlyRate, totalCost, score, status, roi,
      scanDate: new Date().toISOString().split('T')[0],
      notes: [
        `Rent: ${listing.price}€ + Condo: ${listing.condoFees || 0}€ = Total: ${totalCost}€`,
        `Size: ${listing.sqm || '?'} m² | Floor: ${listing.floor ?? '?'} | Elevator: ${listing.elevator ? 'Sì' : 'No'}`,
        `Quick Score: ${score} (${status}) | ROI: ${roi.roi}% | Break-even: ${roi.breakEvenDays}d`,
      ].join('\n'),
    };

    dedup.add(listing);
    results.saved.push(qualified);
    console.log(`  ✓ [${status}] Score ${score} | ${totalCost}€ | ${zoneName} | ${listing.title?.substring(0, 55)}`);
    await notion.saveListing(qualified);

  } catch { /* skip failed listings silently */ }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

async function extractText(page, sel) {
  try { const el = await page.$(sel); return el ? (await el.textContent())?.trim() || '' : ''; } catch { return ''; }
}
function extractPrice(text) {
  const matches = text.match(/€\s*([\d.]+)/g) || text.match(/([\d.]+)\s*€/g) || [];
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
