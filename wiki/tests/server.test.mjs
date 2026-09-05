import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const testRoot = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(testRoot, '..', '..');
const port = 18_000 + Math.floor(Math.random() * 1_000);
const baseUrl = `http://127.0.0.1:${port}`;
let serverProcess;
let serverOutput = '';

async function waitForServer() {
  const deadline = Date.now() + 15_000;
  while (Date.now() < deadline) {
    if (serverProcess.exitCode !== null) {
      throw new Error(`Wiki server exited early.\n${serverOutput}`);
    }
    try {
      const response = await fetch(`${baseUrl}/api/v1/health`);
      if (response.ok) return;
    } catch {
      // The server is still loading the game snapshot.
    }
    await new Promise((resolveWait) => setTimeout(resolveWait, 100));
  }
  throw new Error(`Wiki server did not start in time.\n${serverOutput}`);
}

before(async () => {
  serverProcess = spawn(process.execPath, ['wiki/server/index.js'], {
    cwd: repositoryRoot,
    env: { ...process.env, WIKI_HOST: '127.0.0.1', WIKI_PORT: String(port) },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  serverProcess.stdout.on('data', (chunk) => { serverOutput += chunk; });
  serverProcess.stderr.on('data', (chunk) => { serverOutput += chunk; });
  await waitForServer();
});

after(async () => {
  if (!serverProcess || serverProcess.exitCode !== null) return;
  serverProcess.kill('SIGTERM');
  await new Promise((resolveWait) => {
    serverProcess.once('exit', resolveWait);
    setTimeout(resolveWait, 2_000).unref();
  });
});

test('health endpoint reports loaded game catalogs', async () => {
  const response = await fetch(`${baseUrl}/api/v1/health`);
  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.status, 'ok');
  assert.ok(['configured', 'sibling', 'snapshot'].includes(data.source));
  assert.ok(data.counts.items > 300);
  assert.ok(data.counts.recipes > 0);
});

test('localized pages and client modules are served', async () => {
  const paths = [
    '/ru/home',
    '/en/items',
    '/client/styles/wiki.css',
    '/client/pages/app.js',
    '/client/api/wiki-api.js',
    '/client/components/text.js',
  ];
  for (const path of paths) {
    const response = await fetch(`${baseUrl}${path}`);
    assert.equal(response.status, 200, path);
    assert.match(response.headers.get('content-type') ?? '', path.endsWith('.css') ? /text\/css/ : /text\/(html|javascript)/);
  }
});

test('API, assets, HEAD, redirects, and invalid methods behave correctly', async () => {
  const itemResponse = await fetch(`${baseUrl}/api/v1/ru/items`);
  assert.equal(itemResponse.status, 200);
  const items = await itemResponse.json();
  assert.equal(items.count, items.items.length);

  const assetResponse = await fetch(`${baseUrl}/assets/branding/infinity-forge-emblem-v1.png`, { method: 'HEAD' });
  assert.equal(assetResponse.status, 200);
  assert.match(assetResponse.headers.get('content-type') ?? '', /image\/png/);
  assert.equal(await assetResponse.text(), '');

  const rootResponse = await fetch(`${baseUrl}/`, { redirect: 'manual' });
  assert.equal(rootResponse.status, 302);
  assert.equal(rootResponse.headers.get('location'), '/ru/home');

  const postResponse = await fetch(`${baseUrl}/api/v1/health`, { method: 'POST' });
  assert.equal(postResponse.status, 405);

  const traversalResponse = await fetch(`${baseUrl}/client/%2e%2e/server/index.js`);
  assert.equal(traversalResponse.status, 404);
});
