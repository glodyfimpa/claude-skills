document.addEventListener('DOMContentLoaded', () => {
  refreshStats();

  document.getElementById('exportBtn').addEventListener('click', async () => {
    setStatus('Invio al backend...');
    const response = await chrome.runtime.sendMessage({ type: 'EXPORT_DATA' });
    if (response?.success) {
      if (response.method === 'backend') {
        setStatus(`Inviati ${response.count} annunci al backend.`);
      } else {
        setStatus('Backend non attivo. Usa "Scarica JSON".');
      }
    }
  });

  document.getElementById('downloadBtn').addEventListener('click', async () => {
    const response = await chrome.runtime.sendMessage({ type: 'EXPORT_DATA' });
    if (response?.success && response.data) {
      const blob = new Blob([JSON.stringify(response.data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `idealista-scan-${new Date().toISOString().split('T')[0]}.json`;
      a.click();
      URL.revokeObjectURL(url);
      setStatus('JSON scaricato.');
    }
  });

  document.getElementById('clearBtn').addEventListener('click', async () => {
    if (confirm('Cancellare tutti i dati raccolti?')) {
      await chrome.runtime.sendMessage({ type: 'CLEAR_DATA' });
      refreshStats();
      setStatus('Dati cancellati.');
    }
  });
});

async function refreshStats() {
  const stats = await chrome.runtime.sendMessage({ type: 'GET_STATS' });
  document.getElementById('searchCount').textContent = stats?.searchResults || 0;
  document.getElementById('detailCount').textContent = stats?.detailPages || 0;
}

function setStatus(msg) {
  document.getElementById('status').textContent = msg;
  setTimeout(() => { document.getElementById('status').textContent = ''; }, 3000);
}
