function normalizeTitle(value, language) {
  return String(value ?? '').normalize('NFKC').toLocaleLowerCase(language)
    .replaceAll('ё', 'е').replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
}

// Damerau–Levenshtein also accepts an accidental swap of adjacent letters.
function editDistance(left, right) {
  const rows = Array.from({ length: left.length + 1 }, () => Array(right.length + 1).fill(0));
  for (let i = 0; i <= left.length; i += 1) rows[i][0] = i;
  for (let j = 0; j <= right.length; j += 1) rows[0][j] = j;
  for (let i = 1; i <= left.length; i += 1) {
    for (let j = 1; j <= right.length; j += 1) {
      rows[i][j] = Math.min(rows[i - 1][j] + 1, rows[i][j - 1] + 1,
        rows[i - 1][j - 1] + Number(left[i - 1] !== right[j - 1]));
      if (i > 1 && j > 1 && left[i - 1] === right[j - 2] && left[i - 2] === right[j - 1]) {
        rows[i][j] = Math.min(rows[i][j], rows[i - 2][j - 2] + 1);
      }
    }
  }
  return rows[left.length][right.length];
}

function titleScore(title, query) {
  if (!title) return 0;
  if (title === query) return 1000;
  if (title.startsWith(query)) return 900;
  if (title.includes(query)) return 750;
  const words = title.split(' ');
  let total = 0;
  let fuzzy = false;
  for (const term of query.split(' ')) {
    let best = 0;
    for (const word of words) {
      if (word === term) best = Math.max(best, 100);
      else if (word.startsWith(term)) best = Math.max(best, 80);
      else if (word.includes(term)) best = Math.max(best, 60);
      else if (term.length >= 4) {
        const tolerance = term.length >= 7 ? 2 : 1;
        // Match a misspelled word prefix while the visitor is still typing.
        for (let length = Math.max(1, term.length - tolerance); length <= term.length + tolerance; length += 1) {
          const prefix = word.slice(0, length);
          if (Math.abs(prefix.length - term.length) > tolerance) continue;
          const distance = editDistance(term, prefix);
          if (distance <= tolerance) best = Math.max(best, 40 - distance * 10);
        }
      }
    }
    if (!best) return 0;
    if (best < 60) fuzzy = true;
    total += best;
  }
  return (fuzzy ? 300 : 600) + total / query.split(' ').length;
}

const articlePriority = { machine: 3, item: 2, recipe: 0 };

export function rankSearchSuggestions(entries, rawQuery, language = 'ru', limit = 5) {
  const query = normalizeTitle(String(rawQuery ?? '').slice(0, 100), language);
  if (!query) return [];
  const matches = [];
  for (const entry of entries) {
    const title = normalizeTitle(entry.title, language);
    let score = titleScore(title, query);
    for (const alias of entry.aliases ?? []) {
      score = Math.max(score, titleScore(normalizeTitle(alias, language), query) - 5);
    }
    if (score > 0) matches.push({ entry, title, score });
  }
  matches.sort((a, b) => b.score - a.score
    || (articlePriority[b.entry.type] ?? 1) - (articlePriority[a.entry.type] ?? 1)
    || a.title.length - b.title.length
    || a.title.localeCompare(b.title, language));
  const seenTitles = new Set();
  const seenUrls = new Set();
  return matches.filter(({ entry, title }) => {
    if (seenTitles.has(title) || seenUrls.has(entry.url)) return false;
    seenTitles.add(title);
    seenUrls.add(entry.url);
    return true;
  }).slice(0, Math.max(0, Math.min(5, limit))).map(({ entry }) => entry);
}
