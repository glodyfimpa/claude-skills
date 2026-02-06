/**
 * Content script for Idealista listing extraction.
 * Runs on every Idealista page. Detects if it's a search results page
 * or a detail page and extracts accordingly.
 */

(function () {
  console.log('[PropertyScanner] Content script loaded on:', window.location.href);

  // Detect page type
  const url = window.location.href;
  const isSearchPage = /\/affitto-case\/|\/vendita-case\//.test(url) && !/\/immobile\//.test(url);
  const isDetailPage = /\/immobile\/\d+/.test(url);

  console.log('[PropertyScanner] isSearchPage:', isSearchPage, 'isDetailPage:', isDetailPage);

  if (isSearchPage) {
    extractSearchResults();
  } else if (isDetailPage) {
    extractDetailPage();
  } else {
    console.log('[PropertyScanner] Page not matched as search or detail');
  }

  /** Extract all listings from a search results page */
  function extractSearchResults() {
    const items = document.querySelectorAll('article.item, article[data-element-id]');
    if (items.length === 0) {
      console.log('[PropertyScanner] No article.item found, trying broader selectors');
      // Fallback: try any container with listing links
      const allLinks = document.querySelectorAll('a[href*="/immobile/"]');
      console.log('[PropertyScanner] Found', allLinks.length, 'listing links');
    }

    const listings = [];
    items.forEach(item => {
      const linkEl = item.querySelector('a.item-link, a[href*="/immobile/"]');
      const priceEl = item.querySelector('.item-price, [class*="price"]');

      // Use full card text - Idealista puts all details as separate .item-detail
      // elements but also includes description with extra info like "senza ascensore"
      const fullCardText = item.textContent || '';
      const cardTextLower = fullCardText.toLowerCase();

      // Parse structured data from the full card text
      const sqm = parseNum(fullCardText, /(\d{2,3})\s*m[²q2]/i);
      const rooms = parseNum(fullCardText, /(\d)\s*local/i);
      const floor = extractFloor(cardTextLower);
      const hasElevator = /con ascensore/i.test(fullCardText);
      const noElevator = /senza ascensore/i.test(fullCardText);
      const contractType = extractContract(cardTextLower);

      // Check subletting restrictions in description
      const sublettingKeywords = [
        'no sublocazione', 'vietata sublocazione', 'no subaffitto',
        'no affitti brevi', 'no airbnb', 'vietato airbnb',
        'no b&b', 'no bnb', 'solo residenziale',
      ];
      const sublettingBlocked = sublettingKeywords.some(kw => cardTextLower.includes(kw));

      const listing = {
        url: linkEl?.href?.split('?')[0] || '',
        title: linkEl?.textContent?.trim() || '',
        price: parsePrice(priceEl?.textContent),
        sqm,
        rooms,
        floor,
        elevator: hasElevator ? true : (noElevator ? false : null),
        contractType,
        sublettingBlocked,
        description: fullCardText.substring(0, 500).trim(),
        extractedAt: new Date().toISOString(),
        pageUrl: url,
        type: 'search_result',
      };

      if (listing.url) {
        console.log(`[PropertyScanner] Card: ${listing.title?.substring(0,40)} | ${listing.price}€ | ${listing.sqm}m² | Piano ${listing.floor} | Asc: ${listing.elevator} | Contratto: ${listing.contractType}`);
        listings.push(listing);
      }
    });

    console.log('[PropertyScanner] Extracted', listings.length, 'listings from search page');

    // Get pagination info
    const currentPage = document.querySelector('.pagination .selected')?.textContent?.trim() || '1';
    const nextPageLink = document.querySelector('.pagination .next a')?.href || null;

    const payload = {
      type: 'SEARCH_RESULTS',
      data: listings,
      pagination: { currentPage: parseInt(currentPage), nextPageUrl: nextPageLink },
      sourceUrl: url,
      timestamp: new Date().toISOString(),
    };

    chrome.runtime.sendMessage(payload);
  }

  /** Extract full details from a single listing page */
  function extractDetailPage() {
    const fullText = document.body.textContent || '';
    const textLower = fullText.toLowerCase();

    const listing = {
      url: url.split('?')[0],
      title: getText('h1, .main-info__title-main, [class*="title"]'),
      price: parsePrice(getText('.info-data-price, .price, [class*="price"]')),
      address: getText('.main-info__title-minor, [class*="location"], [class*="address"]'),
      description: getText('.comment p, .adCommentsBody, [class*="description"]'),
      details: {},
      fullText: fullText.substring(0, 5000),
      extractedAt: new Date().toISOString(),
      type: 'detail_page',
    };

    // Extract structured details from the info table
    document.querySelectorAll('.details-property_features li, .info-features li, .details-property li').forEach(li => {
      const text = li.textContent.trim();

      if (/m[²q]/.test(text)) listing.details.sqm = parseNum(text, /(\d{2,3})\s*m[²q]/i);
      if (/local/i.test(text)) listing.details.rooms = parseNum(text, /(\d)\s*local/i);
      if (/piano/i.test(text)) listing.details.floor = extractFloor(text.toLowerCase());
      if (/ascensore/i.test(text)) listing.details.elevator = /s[iì]/i.test(text);
      if (/spese.*condo/i.test(text)) listing.details.condoFees = parseNum(text, /(\d+)/);
    });

    // Contract type from text
    listing.details.contractType = extractContract(textLower);

    // Subletting restrictions
    const sublettingKeywords = [
      'no sublocazione', 'vietata sublocazione', 'no subaffitto',
      'no affitti brevi', 'no airbnb', 'vietato airbnb',
      'no b&b', 'no bnb', 'solo residenziale',
      'no attività ricettiva', 'no locazione turistica',
    ];
    listing.details.sublettingBlocked = sublettingKeywords.some(kw => textLower.includes(kw));

    const payload = {
      type: 'DETAIL_PAGE',
      data: listing,
      sourceUrl: url,
      timestamp: new Date().toISOString(),
    };

    chrome.runtime.sendMessage(payload);
  }

  // ─── Helpers ────────────────────────────────────────────

  function getText(selector) {
    const el = document.querySelector(selector);
    return el ? el.textContent.trim() : '';
  }

  function parsePrice(text) {
    if (!text) return 0;
    const cleaned = text.replace(/[€\s.]/g, '').replace(',', '.');
    const num = parseInt(cleaned);
    return (num >= 400 && num <= 5000) ? num : 0;
  }

  function parseNum(text, re) {
    const m = text.match(re);
    return m ? parseInt(m[1]) : null;
  }

  function extractFloor(text) {
    if (/piano\s*terra|piano\s*rialzato/.test(text)) return 0;
    const m = text.match(/(\d+)[°º]?\s*piano/) || text.match(/piano\s*(\d+)/);
    return m ? parseInt(m[1]) : null;
  }

  function extractContract(text) {
    if (text.includes('4+4') || text.includes('canone libero')) return '4+4';
    if (text.includes('3+2') || text.includes('concordato')) return '3+2';
    if (text.includes('transitorio')) return 'Transitorio';
    if (text.includes('uso foresteria')) return 'Uso Foresteria';
    return null;
  }

})();
