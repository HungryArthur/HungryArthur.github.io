export function formatRecipeLine(recipe) {
  return `${recipe.ingredients.map(({ id, count }) => `${id} * ${count}`).join(' + ')} -> ${recipe.resultId ?? recipe.result.id} * ${recipe.resultCount}; age=${recipe.requiredAge}`;
}

export function parseRecipeLine(line) {
  if (typeof line !== 'string' || line.length > 4096) throw new Error('invalid_formula');
  const match = line.trim().match(/^(.+?)\s*(?:->|→)\s*(.+?)\s*;\s*(?:age|эпоха)\s*=\s*(\d+)$/i);
  if (!match) throw new Error('invalid_formula');
  const part = (value) => {
    const entry = value.trim().match(/^([a-z][a-z0-9_]*)\s*[*×]\s*(\d+)$/);
    if (!entry) throw new Error('invalid_formula');
    const count = Number(entry[2]);
    if (!Number.isSafeInteger(count) || count < 1 || count > 2147483647) throw new Error('invalid_count');
    return { id: entry[1], count };
  };
  const ingredients = match[1].split('+').map(part);
  if (new Set(ingredients.map(({ id }) => id)).size !== ingredients.length) throw new Error('duplicate_ingredient');
  const result = part(match[2]);
  const requiredAge = Number(match[3]);
  if (![1, 2, 3, 4, 5, 6, 99].includes(requiredAge)) throw new Error('invalid_age');
  return { ingredients, resultId: result.id, resultCount: result.count, requiredAge };
}
