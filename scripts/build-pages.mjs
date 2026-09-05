import { spawn } from 'node:child_process';
import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptsRoot = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptsRoot, '..');
const outputRoot = resolve(repositoryRoot, 'dist');
const clientRoot = resolve(repositoryRoot, 'wiki/client');
const gameDataRoot = resolve(repositoryRoot, 'game-data');
const port = 19_000 + Math.floor(Math.random() * 500);
const serverUrl = `http://127.0.0.1:${port}`;
const languages = ['ru', 'en'];
const pageRoutes = [
  'home', 'about', 'items', 'recipes', 'crafting-balance', 'bosses', 'mobs',
  'machines', 'technologies', 'quests', 'npcs', 'systems', 'fluids',
  'achievements', 'mechanics', 'gathering', 'interface', 'exploration',
  'optimization', 'multiplayer', 'energy', 'logistics', 'steam',
  'ore-processing', 'search', 'guides/getting-started',
];
const collections = [
  { resource: 'items', key: 'items' },
  { resource: 'recipes', key: 'recipes' },
  { resource: 'crafting-balance', key: 'recipes', pages: false },
  { resource: 'bosses', key: 'bosses' },
  { resource: 'mobs', key: 'mobs' },
  { resource: 'machines', key: 'machines' },
  { resource: 'technologies', key: 'technologies' },
  { resource: 'systems', key: 'systems' },
  { resource: 'fluids', key: 'fluids' },
  { resource: 'achievements', key: 'achievements' },
  { resource: 'mechanics', key: 'mechanics' },
  { resource: 'gathering', key: 'gathering' },
  { resource: 'interface', key: 'guides' },
  { resource: 'exploration', key: 'guides' },
  { resource: 'optimization', key: 'guides' },
  { resource: 'multiplayer', key: 'guides' },
  { resource: 'energy', key: 'guides' },
  { resource: 'logistics', key: 'guides' },
  { resource: 'steam', key: 'guides' },
  { resource: 'ore-processing', key: 'guides' },
  { resource: 'quests', key: 'ages', id: (entry) => entry.age },
  { resource: 'npcs', key: 'npcs' },
];

if (!existsSync(resolve(gameDataRoot, 'project.godot'))) {
  throw new Error('game-data snapshot is missing. Run "npm run sync" before building Pages.');
}

const originalShell = readFileSync(resolve(clientRoot, 'index.html'), 'utf8');
const staticShell = originalShell
  .replace('<html lang="ru">', '<html lang="ru" data-static-wiki="true">')
  .replaceAll('../../assets/', '/assets/');
const routes = new Set(['', 'ru', 'en']);
let apiFiles = 0;

function writeText(relativePath, content) {
  const target = resolve(outputRoot, relativePath);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, content);
}

function writeJson(relativePath, data) {
  writeText(relativePath, `${JSON.stringify(data)}\n`);
  apiFiles += 1;
}

async function fetchJson(path) {
  const response = await fetch(`${serverUrl}${path}`);
  if (!response.ok) throw new Error(`${path} returned ${response.status}`);
  return response.json();
}

async function waitForServer(serverProcess, output) {
  const deadline = Date.now() + 20_000;
  while (Date.now() < deadline) {
    if (serverProcess.exitCode !== null) throw new Error(`Wiki server exited early.\n${output.value}`);
    try {
      const response = await fetch(`${serverUrl}/api/v1/health`);
      if (response.ok) return;
    } catch {
      // The snapshot is still loading.
    }
    await new Promise((resolveWait) => setTimeout(resolveWait, 100));
  }
  throw new Error(`Wiki server did not start.\n${output.value}`);
}

async function stopServer(serverProcess) {
  if (serverProcess.exitCode !== null) return;
  serverProcess.kill('SIGTERM');
  await new Promise((resolveWait) => {
    serverProcess.once('exit', resolveWait);
    setTimeout(resolveWait, 2_000).unref();
  });
}

rmSync(outputRoot, { recursive: true, force: true });
mkdirSync(outputRoot, { recursive: true });
cpSync(resolve(gameDataRoot, 'assets'), resolve(outputRoot, 'assets'), { recursive: true });
cpSync(clientRoot, resolve(outputRoot, 'client'), { recursive: true });

const output = { value: '' };
const serverProcess = spawn(process.execPath, ['wiki/server/index.js'], {
  cwd: repositoryRoot,
  env: {
    ...process.env,
    INFINITEFORGE_GAME_ROOT: gameDataRoot,
    WIKI_HOST: '127.0.0.1',
    WIKI_PORT: String(port),
  },
  stdio: ['ignore', 'pipe', 'pipe'],
});
serverProcess.stdout.on('data', (chunk) => { output.value += chunk; });
serverProcess.stderr.on('data', (chunk) => { output.value += chunk; });

try {
  await waitForServer(serverProcess, output);

  for (const language of languages) {
    pageRoutes.forEach((route) => routes.add(`${language}/${route}`));

    for (const collection of collections) {
      const catalog = await fetchJson(`/api/v1/${language}/${collection.resource}`);
      writeJson(`api-data/${language}/${collection.resource}.json`, catalog);
      const entries = catalog[collection.key] ?? [];
      for (const entry of entries) {
        const id = String(collection.id ? collection.id(entry) : entry.id);
        const encodedId = encodeURIComponent(id);
        const detail = await fetchJson(`/api/v1/${language}/${collection.resource}/${encodedId}`);
        writeJson(`api-data/${language}/${collection.resource}/${encodedId}.json`, detail);
        if (collection.pages !== false) routes.add(`${language}/${collection.resource}/${encodedId}`);
      }
    }

    const searchIndex = await fetchJson(`/api/v1/${language}/search-index`);
    writeJson(`api-data/${language}/search-index.json`, searchIndex);

    const worlds = await fetchJson(`/api/v1/${language}/worlds`);
    writeJson(`api-data/${language}/worlds.json`, worlds);
    const overworld = await fetchJson(`/api/v1/${language}/worlds/overworld`);
    writeJson(`api-data/${language}/worlds/overworld.json`, overworld);
    const biomes = await fetchJson(`/api/v1/${language}/worlds/overworld/biomes`);
    writeJson(`api-data/${language}/worlds/overworld/biomes.json`, biomes);
    routes.add(`${language}/worlds/overworld`);
    routes.add(`${language}/worlds/overworld/biomes`);
    for (const biome of overworld.biomes) {
      const detail = await fetchJson(`/api/v1/${language}/worlds/overworld/biomes/${encodeURIComponent(biome.id)}`);
      writeJson(`api-data/${language}/worlds/overworld/biomes/${encodeURIComponent(biome.id)}.json`, detail);
      routes.add(`${language}/worlds/overworld/biomes/${encodeURIComponent(biome.id)}`);
    }
  }
} finally {
  await stopServer(serverProcess);
}

for (const route of routes) {
  writeText(route ? `${route}/index.html` : 'index.html', staticShell);
}
writeText('404.html', staticShell);
writeText('.nojekyll', '');
writeText('robots.txt', 'User-agent: *\nAllow: /\nSitemap: https://hungryarthur.github.io/sitemap.xml\n');
writeText('sitemap.xml', `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${[...routes].filter(Boolean).sort().map((route) => `  <url><loc>https://hungryarthur.github.io/${route}/</loc></url>`).join('\n')}\n</urlset>\n`);

const requiredFiles = [
  'index.html',
  'ru/home/index.html',
  'en/home/index.html',
  'client/pages/app.js',
  'client/styles/wiki.css',
  'api-data/ru/items.json',
  'api-data/ru/search-index.json',
  'assets/branding/infinity-forge-emblem-v1.png',
];
for (const file of requiredFiles) {
  if (!existsSync(resolve(outputRoot, file))) throw new Error(`Static build is missing ${file}`);
}

console.log(`GitHub Pages build complete: ${routes.size} routes, ${apiFiles} API files.`);
