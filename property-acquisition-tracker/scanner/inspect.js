import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  viewport: { width: 1280, height: 800 },
});

// ─── IMMOBILIARE.IT ───
console.log('=== IMMOBILIARE.IT ===');
const page = await context.newPage();
await page.goto('https://www.immobiliare.it/affitto-case/milano/?criterio=rilevanza&prezzoMinimo=800&prezzoMassimo=1500&superficieMinima=50&superficieMassima=65&locpiualiMin=2&locpiualiMax=2', { waitUntil: 'domcontentloaded', timeout: 30000 });
await new Promise(r => setTimeout(r, 4000));

console.log('Title:', await page.title());
console.log('URL:', page.url());

const selectors1 = [
  'li.nd-list__item', '[class*="listing-item"]', '[class*="in-realEstateResults"] li',
  'article', '.in-realEstateResults__item', '[data-cy="result-item"]',
  'div[class*="ListingCard"]', 'a[href*="/annunci/"]', 'a[href*="/annuncio/"]',
  '[class*="RealEstateListCard"]', '[class*="realEstateListCard"]',
  'li[class*="result"]', 'div[class*="result"]',
];

for (const sel of selectors1) {
  const count = await page.$$eval(sel, els => els.length).catch(() => 0);
  if (count > 0) console.log(`  MATCH: ${sel} -> ${count} elements`);
}

// Dump links that look like listing URLs
const links1 = await page.$$eval('a[href*="/annunci/"]', els =>
  els.slice(0, 5).map(a => ({ href: a.href, parent: a.parentElement?.className?.substring(0, 80) }))
).catch(() => []);
console.log('Listing links:', JSON.stringify(links1, null, 2));

// Look for any significant list containers
const containers1 = await page.evaluate(() => {
  const candidates = document.querySelectorAll('ul, ol, div[class*="list"], div[class*="List"], div[class*="results"], div[class*="Results"]');
  return Array.from(candidates).slice(0, 10).map(el => ({
    tag: el.tagName,
    class: el.className?.substring?.(0, 100) || '',
    childCount: el.children.length,
    firstChildTag: el.children[0]?.tagName || '',
    firstChildClass: el.children[0]?.className?.substring?.(0, 80) || '',
  }));
});
console.log('Containers:', JSON.stringify(containers1, null, 2));

// ─── IDEALISTA ───
console.log('\n=== IDEALISTA ===');
const page2 = await context.newPage();
await page2.goto('https://www.idealista.it/affitto-case/milano-milano/con-prezzo-da_800,prezzo-fino_1500,dimensione-da_50,dimensione-fino_65/2-locali/', { waitUntil: 'domcontentloaded', timeout: 30000 });
await new Promise(r => setTimeout(r, 4000));

console.log('Title:', await page2.title());
console.log('URL:', page2.url());

const selectors2 = [
  'article.item', 'article', '.item-info-container', '.items-container .item',
  'a[href*="/immobile/"]', '[class*="listing"]', '.result-item',
  '[class*="ItemCard"]', '[class*="item-card"]', 'section.items-list article',
];

for (const sel of selectors2) {
  const count = await page2.$$eval(sel, els => els.length).catch(() => 0);
  if (count > 0) console.log(`  MATCH: ${sel} -> ${count} elements`);
}

const links2 = await page2.$$eval('a[href*="/immobile/"]', els =>
  els.slice(0, 5).map(a => ({ href: a.href, parent: a.parentElement?.className?.substring(0, 80) }))
).catch(() => []);
console.log('Listing links:', JSON.stringify(links2, null, 2));

// Check if blocked
const bodyText = await page2.textContent('body');
if (bodyText.includes('non sei un robot') || bodyText.includes('captcha')) {
  console.log('BLOCKED by captcha!');
}
if (bodyText.includes('Access Denied') || bodyText.includes('403')) {
  console.log('BLOCKED - access denied');
}

await browser.close();
