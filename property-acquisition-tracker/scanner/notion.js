import { Client } from '@notionhq/client';

const REQUIRED_PROPERTIES = {
  'Prezzo': { type: 'number', number: { format: 'euro' } },
  'Mq': { type: 'number', number: { format: 'number' } },
  'Zona': { type: 'rich_text' },
  'Locali': { type: 'number', number: { format: 'number' } },
  'Piano': { type: 'rich_text' },
  'Spese Condo': { type: 'number', number: { format: 'euro' } },
  'Score': { type: 'number', number: { format: 'number' } },
  'Tipo Contratto': { type: 'select', select: { options: [{ name: '4+4' }, { name: '3+2' }, { name: 'Transitorio' }, { name: 'Uso Foresteria' }] } },
  'Status Investimento': { type: 'select', select: { options: [{ name: 'Hot' }, { name: 'Review' }, { name: 'Watch' }, { name: 'Skip' }] } },
  'Fonte': { type: 'select', select: { options: [{ name: 'Immobiliare' }, { name: 'Idealista' }, { name: 'Casa.it' }] } },
  'Data Scansione': { type: 'date' },
};

export class NotionSync {
  constructor(token, databaseId) {
    if (!token || !databaseId) {
      this.disabled = true;
      console.log('[Notion] Token or Database ID missing, Notion sync disabled. Results saved to JSON/CSV only.');
      return;
    }
    this.client = new Client({ auth: token });
    this.databaseId = databaseId;
    this.disabled = false;
    this.existingUrls = new Set();
    this.stats = { created: 0, skipped: 0, failed: 0 };
  }

  /**
   * Load existing URLs from the database to avoid duplicates across scans.
   */
  async loadExistingEntries() {
    if (this.disabled) return;
    try {
      let cursor;
      do {
        const response = await this.client.databases.query({
          database_id: this.databaseId,
          start_cursor: cursor,
          page_size: 100,
        });
        for (const page of response.results) {
          const url = page.properties?.URL?.url;
          if (url) this.existingUrls.add(url);
        }
        cursor = response.has_more ? response.next_cursor : undefined;
      } while (cursor);
      console.log(`[Notion] Loaded ${this.existingUrls.size} existing entries from database.`);
    } catch (err) {
      console.error(`[Notion] Failed to load existing entries: ${err.message}`);
    }
  }

  /**
   * Check if the database has the required properties, and report missing ones.
   */
  async verifySchema() {
    if (this.disabled) return;
    try {
      const db = await this.client.databases.retrieve({ database_id: this.databaseId });
      const existingProps = Object.keys(db.properties);
      const missing = Object.keys(REQUIRED_PROPERTIES).filter(p => !existingProps.includes(p));
      if (missing.length > 0) {
        console.log(`[Notion] Missing properties in database: ${missing.join(', ')}`);
        console.log('[Notion] These will be created as text in Notes. Add them manually in Notion for proper types.');
      }
      // Check for "Aggiunto su BNB" checkbox
      if (!existingProps.includes('Aggiunto su BNB')) {
        console.log('[Notion] "Aggiunto su BNB" checkbox not found. Add it manually if needed for Make automation.');
      }
      this.dbProperties = db.properties;
    } catch (err) {
      console.error(`[Notion] Failed to verify schema: ${err.message}`);
      if (err.code === 'object_not_found') {
        console.error('[Notion] Database not found. Check the database ID and ensure the integration has access.');
        this.disabled = true;
      }
    }
  }

  /**
   * Check if a URL already exists in the database.
   */
  urlExists(url) {
    return this.existingUrls.has(url);
  }

  /**
   * Save a qualified listing to Notion.
   */
  async saveListing(listing) {
    if (this.disabled) return false;

    if (this.urlExists(listing.url)) {
      this.stats.skipped++;
      return false;
    }

    try {
      const title = formatTitle(listing);
      const properties = {
        // Name / Title (assumes first property is title type)
        Name: { title: [{ text: { content: title } }] },
        URL: { url: listing.url },
      };

      // Add structured fields if they exist in db
      if (this.hasProperty('Prezzo')) {
        properties['Prezzo'] = { number: listing.price || null };
      }
      if (this.hasProperty('Mq')) {
        properties['Mq'] = { number: listing.sqm || null };
      }
      if (this.hasProperty('Zona')) {
        properties['Zona'] = { rich_text: [{ text: { content: listing.zoneName || '' } }] };
      }
      if (this.hasProperty('Locali')) {
        properties['Locali'] = { number: listing.rooms || 2 };
      }
      if (this.hasProperty('Piano')) {
        properties['Piano'] = { rich_text: [{ text: { content: formatFloor(listing.floor) } }] };
      }
      if (this.hasProperty('Spese Condo')) {
        properties['Spese Condo'] = { number: listing.condoFees || null };
      }
      if (this.hasProperty('Score')) {
        properties['Score'] = { number: listing.score || null };
      }
      if (this.hasProperty('Tipo Contratto') && listing.contractType) {
        properties['Tipo Contratto'] = { select: { name: listing.contractType } };
      }
      if (this.hasProperty('Status Investimento')) {
        properties['Status Investimento'] = { select: { name: listing.status } };
      }
      if (this.hasProperty('Fonte')) {
        properties['Fonte'] = { select: { name: listing.source } };
      }
      if (this.hasProperty('Data Scansione')) {
        properties['Data Scansione'] = { date: { start: listing.scanDate } };
      }
      if (this.hasProperty('Aggiunto su BNB')) {
        properties['Aggiunto su BNB'] = { checkbox: false };
      }

      const response = await this.client.pages.create({
        parent: { database_id: this.databaseId },
        properties,
        children: buildNotesBlocks(listing),
      });

      this.existingUrls.add(listing.url);
      this.stats.created++;
      return true;
    } catch (err) {
      console.error(`[Notion] Failed to save "${listing.title?.substring(0, 40)}": ${err.message}`);
      this.stats.failed++;
      return false;
    }
  }

  hasProperty(name) {
    return this.dbProperties && name in this.dbProperties;
  }

  printStats() {
    if (this.disabled) {
      console.log('  Notion: disabled (no token/db)');
      return;
    }
    console.log(`  Notion: ${this.stats.created} created, ${this.stats.skipped} already existed, ${this.stats.failed} failed`);
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

function formatTitle(listing) {
  const parts = [];
  if (listing.title) parts.push(listing.title.substring(0, 80));
  else {
    if (listing.address) parts.push(listing.address);
    if (listing.zoneName) parts.push(listing.zoneName);
  }
  const meta = [];
  if (listing.rooms) meta.push(`${listing.rooms} locali`);
  if (listing.sqm) meta.push(`${listing.sqm} m²`);
  if (meta.length) parts.push(meta.join(' | '));
  return parts.join(', ') || 'Bilocale Milano';
}

function formatFloor(floor) {
  if (floor === null || floor === undefined) return '?';
  if (floor === 0) return 'Terra';
  return `${floor}°`;
}

function buildNotesBlocks(listing) {
  const lines = listing.notes?.split('\n') || [];
  return lines.map(line => ({
    object: 'block',
    type: 'paragraph',
    paragraph: {
      rich_text: [{ type: 'text', text: { content: line } }],
    },
  }));
}
