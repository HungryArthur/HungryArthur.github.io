import assert from 'node:assert/strict';
import { test } from 'node:test';
import { rankSearchSuggestions } from '../client/components/search-suggestions.js';
import { fetchWikiJson, fetchWikiSearchIndex } from '../client/api/wiki-api.js';

const page = (title, type = 'item', url = `/ru/items/${encodeURIComponent(title)}`) => ({ title, type, url });

test('suggestions rank exact titles before prefixes, substrings and spelling approximations', () => {
  const entries = ['Стальная печь', 'Печной блок', 'Печь большого размера', 'Печь', 'Печьм', 'Пещера'].map((title) => page(title));
  const titles = rankSearchSuggestions(entries, 'печь').map((entry) => entry.title);
  assert.equal(titles[0], 'Печь');
  assert.ok(titles.indexOf('Печь большого размера') < titles.indexOf('Стальная печь'));
  assert.ok(titles.indexOf('Стальная печь') < titles.indexOf('Печной блок'));
  assert.equal(titles.length, 5);
});

test('Russian and English partial words and small spelling errors match titles', () => {
  const boiler = page('Паровой котёл');
  assert.deepEqual(rankSearchSuggestions([boiler], '  ПАРОВОЙ   КОТЕЛ '), [boiler]);
  assert.deepEqual(rankSearchSuggestions([boiler], 'котле'), [boiler]);
  assert.deepEqual(rankSearchSuggestions([boiler], 'котел пар'), [boiler]);
  const furnace = page('Electric furnace', 'machine', '/en/machines/electric_furnace');
  assert.deepEqual(rankSearchSuggestions([furnace], 'elecrtic furn', 'en'), [furnace]);
  assert.deepEqual(rankSearchSuggestions([furnace], 'elektric', 'en'), [furnace]);
});

test('suggestions show up to five distinct titles and prefer machine articles to recipes', () => {
  const item = page('Паровой котёл');
  const machine = page('Паровой котёл', 'machine', '/ru/machines/steam_boiler');
  const recipe = page('Паровой котёл', 'recipe', '/ru/recipes/steam_boiler');
  const entries = [recipe, item, machine, ...Array.from({ length: 8 }, (_, i) => page(`Паровой двигатель ${i}`))];
  const suggestions = rankSearchSuggestions(entries, 'пар');
  assert.equal(suggestions.length, 5);
  assert.equal(suggestions.filter((entry) => entry.title === machine.title).length, 1);
  assert.ok(suggestions.includes(machine));
  assert.equal(rankSearchSuggestions(entries, 'пар', 'ru', 20).length, 5);
});

test('empty and unrelated input stays empty; descriptions do not displace title matches', () => {
  const unrelated = { ...page('Дерево'), description: 'котёл', meta: 'котёл', searchText: 'котёл' };
  const boiler = page('Паровой котёл');
  for (const query of ['', '   ', '!?', 'абракадабра', 'котёл медный']) {
    assert.deepEqual(rankSearchSuggestions([boiler, unrelated], query), [], query);
  }
  assert.deepEqual(rankSearchSuggestions([unrelated, boiler], 'котёл'), [boiler]);
  const multiplayer = { ...page('Совместная игра'), aliases: ['Мультиплеер'] };
  assert.deepEqual(rankSearchSuggestions([unrelated, multiplayer], 'мульти'), [multiplayer]);
});

test('search index is shared by suggestions and full search, with retry after a failed load', async () => {
  const originalFetch = globalThis.fetch;
  const originalDocument = globalThis.document;
  const originalWindow = globalThis.window;
  const entries = [{ ...page('Совместная игра'), id: 'multiplayer', description: '', meta: '', aliases: ['Мультиплеер'] }];
  let requests = 0;
  globalThis.document = { documentElement: { dataset: { staticWiki: 'true' } } };
  globalThis.window = { location: { origin: 'https://example.test' } };
  globalThis.fetch = async (url) => {
    assert.equal(url, '/api-data/ru/search-index.json');
    requests += 1;
    if (requests === 1) throw new Error('Temporary network error');
    return { ok: true, json: async () => ({ entries }) };
  };
  try {
    await assert.rejects(fetchWikiSearchIndex('ru'), /Temporary network error/);
    const [first, second] = await Promise.all([fetchWikiSearchIndex('ru'), fetchWikiSearchIndex('ru')]);
    assert.equal(first, second);
    const search = await fetchWikiJson('/api/v1/ru/search?q=мульти');
    assert.equal(search.results[0].title, 'Совместная игра');
    assert.equal(requests, 2);
  } finally {
    globalThis.fetch = originalFetch;
    globalThis.document = originalDocument;
    globalThis.window = originalWindow;
  }
});
