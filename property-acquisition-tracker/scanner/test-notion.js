import { readFileSync, existsSync } from 'fs';
import { Client } from '@notionhq/client';

// Load .env
const envPath = new URL('.env', import.meta.url).pathname;
if (existsSync(envPath)) {
  const lines = readFileSync(envPath, 'utf-8').split('\n');
  for (const line of lines) {
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
const dbId = process.env.NOTION_DATABASE_ID;

// Test 1: connection
console.log('1. Testing Notion connection...');
try {
  const me = await notion.users.me();
  console.log(`   OK - Connected as: ${me.name || me.type}`);
} catch (err) {
  console.error(`   FAIL: ${err.message}`);
  process.exit(1);
}

// Test 2: database access
console.log('2. Testing database access...');
try {
  const db = await notion.databases.retrieve({ database_id: dbId });
  console.log(`   OK - Database: ${db.title?.[0]?.plain_text || 'unnamed'}`);
  console.log(`   Properties: ${Object.keys(db.properties).join(', ')}`);
} catch (err) {
  console.error(`   FAIL: ${err.message}`);
  if (err.code === 'object_not_found') {
    console.error('   -> Connetti l\'integration "Property Scanner" al database in Notion');
  }
  process.exit(1);
}

// Test 3: query
console.log('3. Querying existing entries...');
try {
  const res = await notion.databases.query({ database_id: dbId, page_size: 5 });
  console.log(`   OK - Total entries: ${res.results.length}+ (showing max 5)`);
} catch (err) {
  console.error(`   FAIL: ${err.message}`);
}

console.log('\nAll tests passed. Notion integration ready.');
