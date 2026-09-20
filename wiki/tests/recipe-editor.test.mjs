import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { cpSync, mkdtempSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { formatRecipeLine, parseRecipeLine } from '../client/components/recipe-line.js';
import { editRecipeContent } from '../server/balance/recipe-editor.js';

const siteRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const gameRoot = resolve(process.env.INFINITEFORGE_GAME_ROOT ?? join(siteRoot, 'game-data'));

test('single-line recipe accepts both notations and rejects invalid ingredients, counts and ages', () => {
  const line = 'wood * 2 + stone × 3 → bronze_drill * 2; эпоха=1';
  const recipe = parseRecipeLine(line);
  assert.deepEqual(parseRecipeLine(formatRecipeLine(recipe)), recipe);
  for (const invalid of [
    'wood * 0 -> bronze_drill * 1; age=1',
    'wood * 1.5 -> bronze_drill * 1; age=1',
    'wood * 2147483648 -> bronze_drill * 1; age=1',
    'wood * 1 + wood * 2 -> bronze_drill * 1; age=1',
    'wood * 1 -> bronze_drill * 1; age=7',
    '../wood * 1 -> bronze_drill * 1; age=1',
  ]) assert.throws(() => parseRecipeLine(invalid), invalid);
  assert.throws(() => editRecipeContent('', line, new Set(['wood', 'bronze_drill'])), /unknown_item/);
});

test('editor preserves unrelated resource properties and line endings', () => {
  const original = readFileSync(join(gameRoot, 'core/resources/crafting/recipes/bronze_drill.tres'), 'utf8').replace(/\r?\n/g, '\r\n');
  const edited = editRecipeContent(original, 'wood * 2 -> bronze_drill * 3; age=2', new Set(['wood', 'bronze_drill'])).content;
  assert.match(edited, /ingredient_ids = PackedStringArray\("wood"\)/);
  assert.match(edited, /result_count = 3/);
  const unrelated = (text) => text.split('\r\n').filter((line) => !/^(result_item_id|result_count|ingredient_ids|ingredient_counts|required_age) =/.test(line));
  assert.deepEqual(unrelated(edited), unrelated(original));
});

test('local editing persists one recipe, recalculates dependent chains and protects invalid/stale writes', async () => {
  const fixture = mkdtempSync(join(tmpdir(), 'infiniteforge-recipe-editor-'));
  let server;
  try {
    // Only the copied core is writable by this test; other game data is read through junctions.
    for (const entry of readdirSync(gameRoot, { withFileTypes: true })) {
      const source = join(gameRoot, entry.name);
      const target = join(fixture, entry.name);
      if (entry.isDirectory() && entry.name !== 'core') symlinkSync(source, target, 'junction');
      else cpSync(source, target, { recursive: true });
    }
    // The shipped bronze drill has no consumers; add one only in the fixture.
    const consumerPath = join(fixture, 'core/resources/crafting/recipes/steel_drill.tres');
    writeFileSync(consumerPath, editRecipeContent(readFileSync(consumerPath, 'utf8'),
      'bronze_drill * 2 -> steel_drill * 1; age=2', new Set(['bronze_drill', 'steel_drill'])).content);
    const port = 21000 + Math.floor(Math.random() * 1000);
    const base = `http://127.0.0.1:${port}`;
    server = spawn(process.execPath, ['wiki/server/index.js'], { cwd: siteRoot,
      env: { ...process.env, INFINITEFORGE_GAME_ROOT: fixture, WIKI_HOST: '127.0.0.1', WIKI_PORT: String(port) }, stdio: 'ignore' });
    let ready = false;
    for (let attempt = 0; attempt < 150; attempt++) {
      try { if ((await fetch(`${base}/api/v1/health`)).ok) { ready = true; break; } } catch {}
      await new Promise((resolveWait) => setTimeout(resolveWait, 100));
    }
    assert.ok(ready, 'server started');
    const path = '/api/v1/ru/crafting-balance/bronze_drill';
    const get = async (url) => (await fetch(base + url)).json();
    const before = await get(path);
    const directory = join(fixture, 'core/resources/crafting/recipes');
    const originals = new Map(readdirSync(directory).map((name) => [name, readFileSync(join(directory, name), 'utf8')]));
    const put = (line, revision = before.recipe.revision, extraHeaders = {}) => fetch(base + path, {
      method: 'PUT', headers: { 'Content-Type': 'application/json', ...extraHeaders }, body: JSON.stringify({ line, revision }),
    });
    assert.equal((await put('wood * 3 -> bronze_drill * 2; age=2', undefined, { Origin: 'https://example.com' })).status, 403);
    for (const line of ['missing_item * 1 -> bronze_drill * 1; age=1', 'bronze_drill * 1 -> bronze_drill * 1; age=1', 'wood * 0 -> bronze_drill * 1; age=1']) {
      assert.equal((await put(line)).status, 400, line);
      assert.equal(readFileSync(join(directory, 'bronze_drill.tres'), 'utf8'), originals.get('bronze_drill.tres'));
    }
    const catalogBefore = await get('/api/v1/ru/crafting-balance');
    const saved = await put('wood * 3 -> bronze_drill * 2; age=2');
    assert.equal(saved.status, 200);
    const after = await get(path);
    assert.equal(after.recipe.rawTotal, 3);
    assert.equal(after.recipe.resultCount, 2);
    assert.equal(after.recipe.requiredAge, 2);
    assert.notEqual(after.recipe.revision, before.recipe.revision);
    assert.equal((await put('wood * 4 -> bronze_drill * 1; age=1')).status, 409);
    assert.equal((await get(path)).recipe.rawTotal, 3);
    const catalogAfter = await get('/api/v1/ru/crafting-balance');
    const steelBefore = catalogBefore.recipes.find((recipe) => recipe.id === 'steel_drill');
    const steelAfter = catalogAfter.recipes.find((recipe) => recipe.id === 'steel_drill');
    assert.ok(steelAfter.rawTotal < steelBefore.rawTotal, 'dependent drill chain recalculated');
    assert.equal(steelAfter.rawTotal, 3, 'dependent chain accounts for batch output');
    assert.equal((await get('/api/v1/ru/recipes/bronze_drill')).recipe.resultCount, 2, 'recipe catalog refreshed');
    for (const [name, content] of originals) if (name !== 'bronze_drill.tres') assert.equal(readFileSync(join(directory, name), 'utf8'), content, name);
  } finally {
    if (server && server.exitCode === null) {
      server.kill();
      await new Promise((done) => server.once('exit', done));
    }
    assert.ok(resolve(fixture).startsWith(resolve(tmpdir()) + '\\') || resolve(fixture).startsWith(resolve(tmpdir()) + '/'));
    rmSync(fixture, { recursive: true, force: true });
  }
});
