import { chromium } from 'playwright';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { createInterface } from 'readline';
import { SEARCH_CONFIG, SUBLETTING_BLOCKERS, SKIP_CONTRACTS, EXCLUDED_ZONES } from './config.js';
import { getZoneRate, quickScore, investmentStatus, fullROI } from './scoring.js';
import { Deduplicator } from './dedup.js';
import { NotionSync } from './notion.js';

// Load .env
function loadEnv() {
  const envPath = new URL('.env', import.meta.url).pathname;
  if (!existsSync(envPath)) return;
  for (const line of readFileSync(envPath, 'utf-8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.substring(0, eqIdx).trim();
    const val = trimmed.substring(eqIdx + 1).trim();
    if (!process.env[key]) process.env[key] = val;
  }
}
loadEnv();

const notion = new NotionSync(process.env.NOTION_TOKEN, process.env.NOTION_DATABASE_ID);
const dedup = new Deduplicator();
const results = { saved: [], skipped: { lowScore: 0, wrongZone: 0, price: 0, wrongContract: 0, noElevator: 0, noSubletting: 0, tooSmall: 0, tooBig: 0, duplicate: 0 } };
const log = SEARCH_CONFIG.debug ? console.log : () => {};

function delay(ms) { return new Promise(r => setTimeout(r, ms)); }

/** Prompt user in terminal to solve captcha manually */
async function waitForUser(message) {
  if (SEARCH_CONFIG.headless) return; // skip in headless
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(resolve => {
    rl.question(`\n⚠️  ${message}\n   Premi INVIO quando hai risolto il captcha... `, () => {
      rl.close();
      resolve();
    });
  });
}

/** Wait for page to fully render (JS SPA) */
async function waitForRender(page, timeout = 10000) {
  try {
    await page.waitForLoadState('networkidle', { timeout });
  } catch { /* timeout is ok, continue */ }
  await delay(1500);
}

/** Detect and handle captcha/block. Returns true if page is usable. */
async function handleBlock(page, portalName) {
  const body = await page.textContent('body').catch(() => '');
  const blocked = body.includes('Verifica di sicurezza')
    || body.includes('non sei un robot')
    || body.includes('Access Denied')
    || body.includes('captcha');

  if (!blocked) return true;

  console.log(`[${portalName}] Anti-bot detected.`);

  if (!SEARCH_CONFIG.headless) {
    await waitForUser(`${portalName}: risolvi il captcha nel browser.`);
    await waitForRender(page);
    return true;
  }

  // Headless: wait 30s and retry once
  console.log(`[${portalName}] Headless mode: waiting 30s and retrying...`);
  await delay(30000);
  await page.reload({ waitUntil: 'domcontentloaded' });
  await waitForRender(page);

  const stillBlocked = await page.textContent('body').catch(() => '');
  if (stillBlocked.includes('captcha') || stillBlocked.includes('non sei un robot') || stillBlocked.includes('Verifica')) {
    console.log(`[${portalName}] Still blocked. Use "npm run scan:headed" to solve captchas manually.`);
    return false;
  }
  return true;
}

// ─── IMMOBILIARE.IT ──────────────────────────────────────────────────────────

async function scanImmobiliare(browser) {
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    viewport: { width: 1280, height: 800 },
    locale: 'it-IT',
  });
  const page = await context.newPage();
  let totalScanned = 0;

  try {
    for (let pageNum = 1; pageNum <= SEARCH_CONFIG.maxPages; pageNum++) {
      const url = buildImmobiliareURL(pageNum);
      console.log(`[Immobiliare] Page ${pageNum}: ${url}`);
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await waitForRender(page);

      // Handle cookie banner
      const cookieBtn = await page.$('button[id*="accept"], button[class*="accept"], #didomi-notice-agree-button');
      if (cookieBtn) { await cookieBtn.click().catch(() => {}); await delay(1000); }

      if (!await handleBlock(page, 'Immobiliare')) break;

      // Extract listing URLs - try multiple selector strategies
      const listingUrls = await page.$$eval('a', (anchors) => {
        const urls = new Set();
        for (const a of anchors) {
          const href = a.href || '';
          // Immobiliare listing URLs: /annunci/XXXXXXX/
          if (/\/annunci\/\d{5,}\/?/.test(href)) {
            urls.add(href.split('?')[0]); // remove query params
          }
        }
        return [...urls];
      });

      console.log(`[Immobiliare] Found ${listingUrls.length} listing URLs on page ${pageNum}`);

      for (const listingUrl of listingUrls) {
        totalScanned++;
        await processListing(page, listingUrl, 'Immobiliare');
        await delay(1500 + Math.random() * 2000);
      }

      if (listingUrls.length === 0) break;
    }
  } catch (err) {
    console.error(`[Immobiliare] Error: ${err.message}`);
  }

  await context.close();
  return totalScanned;
}

function buildImmobiliareURL(pageNum) {
  const params = new URLSearchParams({
    criterio: 'rilevanza',
    prezzoMinimo: SEARCH_CONFIG.minPrice,
    prezzoMassimo: SEARCH_CONFIG.maxPrice,
    superficieMinima: SEARCH_CONFIG.minSize,
    superficieMassima: SEARCH_CONFIG.maxSize,
    locpiualiMin: SEARCH_CONFIG.rooms,
    locpiualiMax: SEARCH_CONFIG.rooms,
  });
  if (pageNum > 1) params.set('pag', pageNum);
  return `https://www.immobiliare.it/affitto-case/milano/?${params}`;
}

// ─── IDEALISTA ───────────────────────────────────────────────────────────────

async function scanIdealista(browser) {
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    viewport: { width: 1280, height: 800 },
    locale: 'it-IT',
  });
  const page = await context.newPage();
  let totalScanned = 0;

  try {
    for (let pageNum = 1; pageNum <= SEARCH_CONFIG.maxPages; pageNum++) {
      const url = buildIdealistaURL(pageNum);
      console.log(`[Idealista] Page ${pageNum}: ${url}`);
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await waitForRender(page);

      // Handle cookie banner
      const cookieBtn = await page.$('#didomi-notice-agree-button, button[id*="accept"]');
      if (cookieBtn) { await cookieBtn.click().catch(() => {}); await delay(1000); }

      if (!await handleBlock(page, 'Idealista')) break;

      // Extract listing URLs
      const listingUrls = await page.$$eval('a', (anchors) => {
        const urls = new Set();
        for (const a of anchors) {
          const href = a.href || '';
          // Idealista listing URLs: /immobile/XXXXXXX/
          if (/\/immobile\/\d{5,}\/?/.test(href)) {
            urls.add(href.split('?')[0]);
          }
        }
        return [...urls];
      });

      console.log(`[Idealista] Found ${listingUrls.length} listing URLs on page ${pageNum}`);

      for (const listingUrl of listingUrls) {
        totalScanned++;
        await processListing(page, listingUrl, 'Idealista');
        await delay(1500 + Math.random() * 2000);
      }

      if (listingUrls.length === 0) break;
    }
  } catch (err) {
    console.error(`[Idealista] Error: ${err.message}`);
  }

  await context.close();
  return totalScanned;
}

function buildIdealistaURL(pageNum) {
  let url = `https://www.idealista.it/affitto-case/milano-milano/con-prezzo-da_${SEARCH_CONFIG.minPrice},prezzo-fino_${SEARCH_CONFIG.maxPrice},dimensione-da_${SEARCH_CONFIG.minSize},dimensione-fino_${SEARCH_CONFIG.maxSize}/2-locali/`;
  if (pageNum > 1) url += `pagina-${pageNum}.htm`;
  return url;
}

// ─── LISTING DETAIL EXTRACTION ───────────────────────────────────────────────

async function processListing(page, url, source) {
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
    await waitForRender(page, 6000);

    if (!await handleBlock(page, source)) return;

    const fullText = await page.textContent('body') || '';
    const textLower = fullText.toLowerCase();

    if (fullText.length < 200) {
      log(`[${source}] Page too short, likely blocked: ${url}`);
      return;
    }

    const listing = {
      url,
      source,
      title: await extractText(page, 'h1, .main-title, [class*="title"]'),
      price: extractPrice(fullText),
      sqm: extractNumber(fullText, /(\d{2,3})\s*m²/i) || extractNumber(fullText, /(\d{2,3})\s*mq/i),
      rooms: extractNumber(fullText, /(\d)\s*local/i),
      floor: extractFloor(textLower),
      elevator: /ascensore\s*[:.]?\s*s[iì]/i.test(fullText) || /con ascensore/i.test(fullText),
      condoFees: extractNumber(fullText, /spese\s*(?:condo(?:miniali)?|condominio)\s*[:.]?\s*€?\s*(\d+)/i),
      contractType: extractContract(textLower),
      address: await extractText(page, '[class*="address"], [class*="location"], .header-map-list, [class*="Address"]'),
      zone: '',
    };

    listing.zone = listing.address || listing.title || '';
    log(`[${source}] ${listing.title?.substring(0, 50)} | ${listing.price}€ | ${listing.sqm}m² | floor:${listing.floor} | elevator:${listing.elevator}`);

    // ─── FILTERS ───

    if (listing.price === 0) { log(`  skip: no price`); return; }
    if (listing.sqm && listing.sqm < 45) { results.skipped.tooSmall++; return; }
    if (listing.sqm && listing.sqm > 70) { results.skipped.tooBig++; return; }

    const totalCost = listing.price + (listing.condoFees || 0);
    if (totalCost > SEARCH_CONFIG.maxPrice) { results.skipped.price++; return; }

    if (listing.contractType) {
      const ctLower = listing.contractType.toLowerCase();
      if (SKIP_CONTRACTS.some(sc => ctLower.includes(sc))) { results.skipped.wrongContract++; return; }
    }

    if (listing.floor !== null && listing.floor > 0 && !listing.elevator) {
      results.skipped.noElevator++;
      return;
    }

    if (SUBLETTING_BLOCKERS.some(kw => textLower.includes(kw))) {
      results.skipped.noSubletting++;
      return;
    }

    if (EXCLUDED_ZONES.some(z => listing.zone.toLowerCase().includes(z))) {
      results.skipped.wrongZone++;
      return;
    }

    const dupCheck = dedup.check(listing);
    if (dupCheck.isDuplicate) {
      results.skipped.duplicate++;
      log(`  skip: duplicate (first seen on ${dupCheck.matchedWith.source})`);
      return;
    }

    // ─── SCORING ───

    const zoneInfo = getZoneRate(listing.zone) || getZoneRate(listing.title);
    const nightlyRate = zoneInfo?.rate || 80;
    const zoneName = zoneInfo?.zone || 'sconosciuta';
    const score = quickScore(listing.price, listing.condoFees, nightlyRate);
    const status = investmentStatus(score);

    if (status === 'Skip') { results.skipped.lowScore++; return; }

    const roi = fullROI(listing.price, listing.condoFees, nightlyRate);

    const qualified = {
      ...listing,
      zoneName, nightlyRate, totalCost, score, status, roi,
      scanDate: new Date().toISOString().split('T')[0],
      notes: formatNotes(listing, totalCost, nightlyRate, score, status, roi),
    };

    dedup.add(listing);
    results.saved.push(qualified);
    console.log(`  ✓ [${status}] Score ${score} | ${listing.price}€ + ${listing.condoFees || 0}€ = ${totalCost}€ | ${zoneName} | ${listing.title?.substring(0, 60)}`);

    await notion.saveListing(qualified);

  } catch (err) {
    log(`[Error] ${url}: ${err.message}`);
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

async function extractText(page, selector) {
  try {
    const el = await page.$(selector);
    return el ? (await el.textContent())?.trim() || '' : '';
  } catch { return ''; }
}

function extractPrice(text) {
  // Match patterns like "€ 1.200" or "1.200 €" or "€1200"
  const matches = text.match(/€\s*([\d.]+)/g) || text.match(/([\d.]+)\s*€/g) || [];
  for (const m of matches) {
    const digits = m.replace(/[€\s]/g, '').replace(/\./g, '');
    const val = parseInt(digits);
    // Monthly rent is typically 400-5000
    if (val >= 400 && val <= 5000) return val;
  }
  return 0;
}

function extractNumber(text, regex) {
  const match = text.match(regex);
  return match ? parseInt(match[1]) : null;
}

function extractFloor(text) {
  if (/piano\s*terra|piano\s*rialzato/i.test(text)) return 0;
  const match = text.match(/(\d+)[°º]?\s*piano/i) || text.match(/piano\s*(\d+)/i);
  return match ? parseInt(match[1]) : null;
}

function extractContract(text) {
  if (text.includes('4+4') || text.includes('canone libero')) return '4+4';
  if (text.includes('3+2') || text.includes('concordato')) return '3+2';
  if (text.includes('transitorio')) return 'Transitorio';
  if (text.includes('uso foresteria')) return 'Uso Foresteria';
  if (text.includes('studenti')) return 'Studenti';
  return null;
}

function formatNotes(listing, totalCost, nightlyRate, score, status, roi) {
  return [
    `Rent: ${listing.price}€ + Condo: ${listing.condoFees || 0}€ = Total: ${totalCost}€`,
    `Size: ${listing.sqm || '?'} m² | Floor: ${listing.floor !== null ? (listing.floor === 0 ? 'Terra' : listing.floor + '°') : '?'} | Elevator: ${listing.elevator ? 'Sì' : 'No'}`,
    `Zone avg rate: ${nightlyRate}€/night`,
    `Quick Score: ${score} (${status})`,
    `ROI: ${roi.roi}% | Break-even: ${roi.breakEvenDays} days | Rev/Rent: ${roi.revenueToRent}x | ${roi.verdict}`,
  ].join('\n');
}

// ─── MAIN ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  Property Acquisition Tracker - Milan BnB Scanner      ║');
  console.log('╚══════════════════════════════════════════════════════════╝');
  console.log(`Config: ${SEARCH_CONFIG.minPrice}-${SEARCH_CONFIG.maxPrice}€ | ${SEARCH_CONFIG.minSize}-${SEARCH_CONFIG.maxSize}m² | ${SEARCH_CONFIG.rooms} locali | Max ${SEARCH_CONFIG.maxPages} pages/portal`);
  console.log(`Mode: ${SEARCH_CONFIG.headless ? 'headless' : 'HEADED (browser visibile)'}\n`);

  if (SEARCH_CONFIG.headless) {
    console.log('⚠️  I portali bloccano spesso il mode headless.');
    console.log('   Se 0 risultati, usa: npm run scan:headed\n');
  }

  await notion.verifySchema();
  await notion.loadExistingEntries();

  const browser = await chromium.launch({
    headless: SEARCH_CONFIG.headless,
    args: ['--disable-blink-features=AutomationControlled'],
  });

  const immobiliareCount = await scanImmobiliare(browser);
  const idealistaCount = await scanIdealista(browser);

  await browser.close();

  // ─── OUTPUT ───

  const dateStr = new Date().toISOString().split('T')[0];
  const outputFile = `scan-results-${dateStr}.json`;
  writeFileSync(outputFile, JSON.stringify(results.saved, null, 2));

  const csvFile = `scan-results-${dateStr}.csv`;
  const csvHeader = 'Title,URL,Price,Condo Fees,Total,Sqm,Zone,Floor,Elevator,Score,Status,ROI%,Break-even,Rev/Rent,Verdict,Source\n';
  const csvRows = results.saved.map(l =>
    `"${l.title?.replace(/"/g, '""')}","${l.url}",${l.price},${l.condoFees || 0},${l.totalCost},${l.sqm || ''},${l.zoneName},${l.floor !== null ? l.floor : ''},${l.elevator},${l.score},${l.status},${l.roi.roi},${l.roi.breakEvenDays},${l.roi.revenueToRent},${l.roi.verdict},${l.source}`
  ).join('\n');
  writeFileSync(csvFile, csvHeader + csvRows);

  const hot = results.saved.filter(l => l.status === 'Hot').length;
  const review = results.saved.filter(l => l.status === 'Review').length;

  console.log('\n══════════════════════════════════════════════════════════');
  console.log('Scan completed:');
  console.log(`  Immobiliare.it: ${immobiliareCount} listings scanned`);
  console.log(`  Idealista: ${idealistaCount} listings scanned`);
  console.log(`  Duplicates skipped: ${results.skipped.duplicate}`);
  console.log(`  Saved: ${results.saved.length} (Hot: ${hot}, Review: ${review})`);
  console.log(`  Skipped: ${Object.values(results.skipped).reduce((a, b) => a + b, 0)} (low score: ${results.skipped.lowScore}, wrong zone: ${results.skipped.wrongZone}, price: ${results.skipped.price}, wrong contract: ${results.skipped.wrongContract}, no elevator: ${results.skipped.noElevator}, no subletting: ${results.skipped.noSubletting})`);
  notion.printStats();
  console.log(`\nResults saved to: ${outputFile} and ${csvFile}`);
  console.log('══════════════════════════════════════════════════════════');
}

main().catch(console.error);
