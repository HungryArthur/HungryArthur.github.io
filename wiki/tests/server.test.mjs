import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { loadArtManifest, validateArtManifest, validateSprite32 } from '../../scripts/validate-textures.mjs';
import { pixelPerfectGeometry } from '../client/components/pixel-images.js';
import { rankSearchSuggestions } from '../client/components/search-suggestions.js';

const testRoot = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(testRoot, '..', '..');
const gameRoot = resolve(process.env.INFINITEFORGE_GAME_ROOT ?? resolve(repositoryRoot, 'game-data'));
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
    env: { ...process.env, INFINITEFORGE_GAME_ROOT: gameRoot, WIKI_HOST: '127.0.0.1', WIKI_PORT: String(port) },
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
  assert.ok(['configured', 'parent', 'sibling', 'snapshot'].includes(data.source));
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

test('live search index supports five title suggestions and the Russian multiplayer alias', async () => {
  for (const language of ['ru', 'en']) {
    const response = await fetch(`${baseUrl}/api/v1/${language}/search-index`);
    assert.equal(response.status, 200);
    const { entries } = await response.json();
    const suggestions = rankSearchSuggestions(entries, language === 'ru' ? 'пар' : 'steam', language);
    assert.equal(suggestions.length, 5);
    assert.equal(new Set(suggestions.map((entry) => entry.title)).size, 5);
    for (const entry of suggestions) {
      assert.equal((await fetch(`${baseUrl}${entry.url}`)).status, 200, entry.url);
    }
    if (language === 'ru') {
      const multiplayer = rankSearchSuggestions(entries, 'мульти', language);
      assert.equal(multiplayer.length, 5);
      assert.equal(multiplayer[0].url, '/ru/multiplayer');
      const search = await (await fetch(`${baseUrl}/api/v1/ru/search?q=мульти`)).json();
      assert.ok(search.results.some((entry) => entry.url === '/ru/multiplayer'));
    }
  }
});

test('all item and machine sprites are 32x32 with valid files and atlas regions', async () => {
  assert.ok(validateArtManifest(gameRoot) >= 248);
  const paths = new Set();
  const itemCatalog = await (await fetch(`${baseUrl}/api/v1/ru/items`)).json();
  const machineCatalog = await (await fetch(`${baseUrl}/api/v1/ru/machines`)).json();
  for (const entry of [...itemCatalog.items, ...machineCatalog.machines]) {
    validateSprite32(entry.texture, gameRoot, entry.id);
    paths.add(entry.texture.path);
  }
  const manifest = loadArtManifest(gameRoot);
  for (const art of manifest.filter(e => e.item && e.kind !== 'connector')) {
    const item = itemCatalog.items.find(e => e.id === (art.itemId ?? art.id));
    assert.ok(item, `Missing generated item: ${art.id}`);
    assert.equal(item.texture.path, `/${art.output}`, `Old placeholder used: ${item.id}`);
  }
  for (const path of paths) {
    const response = await fetch(`${baseUrl}${path}`, { method: 'HEAD' });
    assert.equal(response.status, 200, path);
    assert.match(response.headers.get('content-type'), path.endsWith('.svg') ? /image\/svg\+xml/ : /image\/png/);
  }
});

test('chests and conveyors show one 32px atlas cell; standalone icons are square', async () => {
  const { items } = await (await fetch(`${baseUrl}/api/v1/en/items`)).json();
  const byId = new Map(items.map(e => [e.id, e]));
  assert.deepEqual(byId.get('CHEST_T1').texture.atlas, { x: 0, y: 0, width: 32, height: 32 });
  assert.deepEqual(byId.get('conveyor').texture.atlas, { x: 0, y: 32, width: 32, height: 32 });
  assert.ok(byId.get('resonite_shard').texture.dimensions.width > 0);
  for (const id of ['water_pump', 'fluid_pipe', 'fluid_valve', 'fluid_tank_t5', 'solar_panel', 'me_controller']) {
    assert.deepEqual(byId.get(id).texture.dimensions, { width: 32, height: 32 });
    assert.match(byId.get(id).texture.path, /\/generated\//);
  }
  assert.deepEqual(pixelPerfectGeometry(16,16,40), { width:32,height:32,scale:2 });
  assert.deepEqual(pixelPerfectGeometry(32,48,32), { width:16,height:24,scale:.5 });
});

test('current game snapshot exposes new containers, ME guides and complete mixer variants in both languages', async () => {
  for (const language of ['ru', 'en']) {
    const get = async (resource) => {
      const response = await fetch(`${baseUrl}/api/v1/${language}/${resource}`);
      assert.equal(response.status, 200, resource);
      return response.json();
    };
    const { item: capsule } = await get('items/fluid_capsule');
    assert.equal(capsule.fluidCapacity, 100);
    assert.equal(capsule.maxStack, 1);
    assert.notEqual(capsule.title, capsule.nameKey);
    const { item: wireless } = await get('items/me_wireless_terminal');
    assert.equal(wireless.useAction, 'open_me_wireless');
    const systems = await get('systems');
    for (const id of ['me-network', 'me-autocrafting', 'fluid-containers', 'mixer']) {
      assert.ok(systems.systems.some((guide) => guide.id === id), id);
      const detail = await get(`systems/${id}`);
      const guide = detail.system;
      assert.ok(guide.stages.length >= 3, id);
      for (const item of [...guide.equipment, ...guide.stages.flatMap((stage) => stage.links)]) {
        assert.ok(item.exists, `Missing guide item: ${id}/${item.id}`);
      }
    }
    const { machine, fluidProcesses } = await get('machines/mixer');
    assert.deepEqual(machine.size, { x: 2, y: 2 });
    assert.equal(machine.metrics.energyUse, 50);
    assert.equal(machine.metrics.processTime, 5);
    assert.equal(machine.metrics.fluidCapacity, 400);
    assert.equal(fluidProcesses.length, 5);
    const blends = fluidProcesses.filter((recipe) => recipe.outputs.some((output) => output.id === 'fuel_blend'));
    assert.deepEqual(blends.map((recipe) => recipe.inputs.length).sort(), [2, 3, 4]);
    assert.deepEqual(blends.map((recipe) => recipe.outputs[0].amount).sort((a, b) => a - b), [100, 120, 150]);
    const { machine: furnace } = await get('machines/electric_furnace');
    assert.equal(furnace.metrics.energyUse, 15);
    assert.equal(furnace.metrics.processTime, 2);
    const { machine: generator } = await get('machines/coal_generator');
    assert.equal(generator.metrics.energyOutput, 40);
    const { fluid: bronze } = await get('fluids/molten_bronze');
    assert.ok(bronze.sources.some((recipe) => recipe.machine.id === 'mixer'));
    const { mobs } = await get('mobs');
    assert.equal(mobs.filter((mob) => mob.biomeResource === 'ForestBiome').length, 0);
  }
});
