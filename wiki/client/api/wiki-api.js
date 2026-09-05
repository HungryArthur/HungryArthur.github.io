function searchStaticIndex(entries, query, language) {
  const normalizedQuery = String(query ?? '').trim().slice(0, 100).toLocaleLowerCase(language);
  if (!normalizedQuery) return { query: '', total: 0, count: 0, results: [] };
  const terms = normalizedQuery.split(/\s+/).filter(Boolean);
  const matches = [];

  for (const entry of entries) {
    const title = entry.title.toLocaleLowerCase(language);
    const id = entry.id.toLocaleLowerCase(language);
    const description = entry.description.toLocaleLowerCase(language);
    const meta = entry.meta.toLocaleLowerCase(language);
    const searchText = (entry.searchText ?? '').toLocaleLowerCase(language);
    const haystack = `${title} ${id} ${description} ${meta} ${searchText}`;
    if (!terms.every((term) => haystack.includes(term))) continue;
    let score = 0;
    if (title === normalizedQuery) score += 120;
    else if (title.startsWith(normalizedQuery)) score += 85;
    else if (title.includes(normalizedQuery)) score += 60;
    if (id === normalizedQuery) score += 110;
    else if (id.startsWith(normalizedQuery)) score += 70;
    else if (id.includes(normalizedQuery)) score += 45;
    for (const term of terms) {
      if (title.includes(term)) score += 12;
      if (id.includes(term)) score += 9;
      if (meta.includes(term)) score += 4;
      if (description.includes(term)) score += 2;
      if (searchText.includes(term)) score += 1;
    }
    matches.push({ ...entry, score });
  }

  matches.sort((left, right) => right.score - left.score || left.title.localeCompare(right.title, language));
  const results = matches.slice(0, 100).map(({ score, searchText, ...entry }) => entry);
  return { query: normalizedQuery, total: matches.length, count: results.length, results };
}

async function fetchStaticWikiJson(path) {
  const url = new URL(path, window.location.origin);
  const route = url.pathname.split('/').filter(Boolean);
  const language = route[2] === 'en' ? 'en' : 'ru';

  if (route[3] === 'search') {
    const indexResponse = await fetch(`/api-data/${language}/search-index.json`, {
      headers: { Accept: 'application/json' },
    });
    if (!indexResponse.ok) throw new Error(`Wiki search index returned ${indexResponse.status}`);
    const index = await indexResponse.json();
    return searchStaticIndex(index.entries, url.searchParams.get('q'), language);
  }

  const staticPath = `/api-data/${route.slice(2).join('/')}.json`;
  const response = await fetch(staticPath, {
    headers: { Accept: 'application/json' },
  });
  if (!response.ok) {
    const error = new Error(`Wiki API returned ${response.status}`);
    error.status = response.status;
    throw error;
  }

  return response.json();
}

export async function fetchWikiJson(path) {
  if (document.documentElement.dataset.staticWiki === 'true') {
    return fetchStaticWikiJson(path);
  }

  const response = await fetch(path, {
    headers: { Accept: 'application/json' },
  });
  if (!response.ok) {
    const error = new Error(`Wiki API returned ${response.status}`);
    error.status = response.status;
    throw error;
  }
  return response.json();
}
