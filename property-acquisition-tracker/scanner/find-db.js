import { readFileSync, existsSync } from 'fs';
import { Client } from '@notionhq/client';

const envPath = new URL('.env', import.meta.url).pathname;
if (existsSync(envPath)) {
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

const notion = new Client({ auth: process.env.NOTION_TOKEN });
const pageId = process.env.NOTION_DATABASE_ID;

console.log(`Searching for databases inside page ${pageId}...\n`);

// Get child blocks of the page to find inline databases
const blocks = await notion.blocks.children.list({ block_id: pageId, page_size: 50 });
let found = false;
for (const block of blocks.results) {
  if (block.type === 'child_database') {
    console.log(`Found database: "${block.child_database.title}"`);
    console.log(`Database ID: ${block.id}`);
    found = true;
  }
}

if (!found) {
  // Try searching for databases the integration has access to
  console.log('No inline database found. Searching all accessible databases...\n');
  const search = await notion.search({ filter: { property: 'object', value: 'database' } });
  for (const db of search.results) {
    const title = db.title?.[0]?.plain_text || 'untitled';
    console.log(`- "${title}" -> ID: ${db.id}`);
  }
  if (search.results.length === 0) {
    console.log('No databases found. The integration may need access to more pages.');
  }
}
