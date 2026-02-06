/**
 * Background service worker.
 * Collects listings from content scripts, stores in chrome.storage,
 * and forwards to local backend server.
 */

const BACKEND_URL = 'http://localhost:3456';

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'SEARCH_RESULTS') {
    handleSearchResults(message);
  } else if (message.type === 'DETAIL_PAGE') {
    handleDetailPage(message);
  } else if (message.type === 'GET_STATS') {
    getStats().then(sendResponse);
    return true; // async response
  } else if (message.type === 'EXPORT_DATA') {
    exportData().then(sendResponse);
    return true;
  } else if (message.type === 'CLEAR_DATA') {
    clearData().then(sendResponse);
    return true;
  } else if (message.type === 'START_AUTO_SCAN') {
    startAutoScan(message.searchUrl, sender.tab.id);
  }
});

async function handleSearchResults(message) {
  const { searchResults } = await chrome.storage.local.get('searchResults');
  const existing = searchResults || [];

  // Deduplicate by URL
  const existingUrls = new Set(existing.map(l => l.url));
  const newListings = message.data.filter(l => !existingUrls.has(l.url));

  if (newListings.length > 0) {
    await chrome.storage.local.set({
      searchResults: [...existing, ...newListings],
    });
    updateBadge(existing.length + newListings.length);
  }

  // Forward to backend (background script has host_permissions)
  forwardToBackend(message);
}

async function handleDetailPage(message) {
  const { detailPages } = await chrome.storage.local.get('detailPages');
  const existing = detailPages || {};
  existing[message.data.url] = message.data;
  await chrome.storage.local.set({ detailPages: existing });

  // Forward to backend
  forwardToBackend(message);
}

async function forwardToBackend(payload) {
  try {
    await fetch(`${BACKEND_URL}/api/listings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
  } catch {
    // Backend not running, data stays in chrome.storage
  }
}

async function getStats() {
  const { searchResults, detailPages } = await chrome.storage.local.get(['searchResults', 'detailPages']);
  return {
    searchResults: (searchResults || []).length,
    detailPages: Object.keys(detailPages || {}).length,
  };
}

async function exportData() {
  const { searchResults, detailPages } = await chrome.storage.local.get(['searchResults', 'detailPages']);
  const data = {
    searchResults: searchResults || [],
    detailPages: detailPages || {},
    exportedAt: new Date().toISOString(),
  };

  // Try sending to backend
  try {
    const res = await fetch(`${BACKEND_URL}/api/export`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (res.ok) return { success: true, method: 'backend', count: data.searchResults.length };
  } catch {}

  return { success: true, method: 'local', data };
}

async function clearData() {
  await chrome.storage.local.remove(['searchResults', 'detailPages']);
  updateBadge(0);
  return { success: true };
}

function updateBadge(count) {
  chrome.action.setBadgeText({ text: count > 0 ? String(count) : '' });
  chrome.action.setBadgeBackgroundColor({ color: '#4CAF50' });
}

// ─── Auto-scan: navigate pages with human-like delays ──────────

let autoScanActive = false;

async function startAutoScan(searchUrl, tabId) {
  if (autoScanActive) return;
  autoScanActive = true;

  // Navigate to first page
  chrome.tabs.update(tabId, { url: searchUrl });

  // The content script will extract data on each page load.
  // We listen for page completion to navigate to next page.
  const listener = (updatedTabId, changeInfo) => {
    if (updatedTabId !== tabId || changeInfo.status !== 'complete') return;
    if (!autoScanActive) {
      chrome.tabs.onUpdated.removeListener(listener);
      return;
    }

    // Wait a random human-like delay, then check for next page
    const delay = 5000 + Math.random() * 10000; // 5-15 seconds
    setTimeout(async () => {
      if (!autoScanActive) return;

      try {
        const results = await chrome.tabs.sendMessage(tabId, { type: 'GET_NEXT_PAGE' });
        if (results?.nextPageUrl) {
          chrome.tabs.update(tabId, { url: results.nextPageUrl });
        } else {
          // No more pages
          autoScanActive = false;
          chrome.tabs.onUpdated.removeListener(listener);
        }
      } catch {
        autoScanActive = false;
        chrome.tabs.onUpdated.removeListener(listener);
      }
    }, delay);
  };

  chrome.tabs.onUpdated.addListener(listener);
}
