/**
 * Address normalization and deduplication logic.
 */

const ABBREVIATIONS = {
  'v.': 'via', 'v.le': 'viale', 'c.so': 'corso', 'p.le': 'piazzale',
  'p.za': 'piazza', 'p.zza': 'piazza', 'l.go': 'largo', 'vic.': 'vicolo',
};

export function normalizeAddress(address) {
  if (!address) return '';
  let norm = address.toLowerCase().trim();
  // Remove punctuation except spaces and numbers
  norm = norm.replace(/[,.']/g, ' ');
  // Standardize abbreviations
  for (const [abbr, full] of Object.entries(ABBREVIATIONS)) {
    norm = norm.replace(new RegExp(`\\b${abbr.replace('.', '\\.')}\\b`, 'g'), full);
  }
  // Collapse whitespace
  norm = norm.replace(/\s+/g, ' ').trim();
  return norm;
}

/**
 * Simple similarity check between two normalized addresses.
 * Returns a score between 0 and 1.
 */
function similarity(a, b) {
  if (a === b) return 1;
  const wordsA = a.split(' ');
  const wordsB = b.split(' ');
  const intersection = wordsA.filter(w => wordsB.includes(w));
  return (2 * intersection.length) / (wordsA.length + wordsB.length);
}

export class Deduplicator {
  constructor() {
    this.seen = []; // { address, sqm, price, url, source }
  }

  /**
   * Check if a listing is a duplicate.
   * Returns { isDuplicate, matchedWith } or { isDuplicate: false }
   */
  check(listing) {
    const normAddr = normalizeAddress(listing.address || listing.title);

    // URL-based check first
    for (const existing of this.seen) {
      if (listing.url && existing.url && this.sameListingId(listing.url, existing.url)) {
        return { isDuplicate: true, matchedWith: existing };
      }
    }

    // Address-based check
    for (const existing of this.seen) {
      const sim = similarity(normAddr, existing.address);
      if (sim >= 0.9) {
        const sqmClose = Math.abs((listing.sqm || 0) - (existing.sqm || 0)) <= 5;
        const priceClose = Math.abs((listing.price || 0) - (existing.price || 0)) <= 50;
        if (sqmClose && priceClose) {
          return { isDuplicate: true, matchedWith: existing };
        }
      }
    }

    return { isDuplicate: false };
  }

  add(listing) {
    this.seen.push({
      address: normalizeAddress(listing.address || listing.title),
      sqm: listing.sqm,
      price: listing.price,
      url: listing.url,
      source: listing.source,
    });
  }

  sameListingId(url1, url2) {
    const id1 = url1.match(/\/(\d{5,})\/?/)?.[1];
    const id2 = url2.match(/\/(\d{5,})\/?/)?.[1];
    return id1 && id2 && id1 === id2;
  }
}
