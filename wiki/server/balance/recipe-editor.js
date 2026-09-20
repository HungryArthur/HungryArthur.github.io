import { createHash } from 'node:crypto';
import { parseRecipeLine } from '../../client/components/recipe-line.js';

export function recipeRevision(content) {
  return createHash('sha256').update(content).digest('hex');
}

export function editRecipeContent(content, line, items) {
  const recipe = parseRecipeLine(line);
  if ([recipe.resultId, ...recipe.ingredients.map(({ id }) => id)].some((id) => !items.has(id))) {
    throw new Error('unknown_item');
  }
  const fields = {
    result_item_id: JSON.stringify(recipe.resultId),
    result_count: recipe.resultCount,
    ingredient_ids: `PackedStringArray(${recipe.ingredients.map(({ id }) => JSON.stringify(id)).join(', ')})`,
    ingredient_counts: `PackedInt32Array(${recipe.ingredients.map(({ count }) => count).join(', ')})`,
    required_age: recipe.requiredAge,
  };
  const newline = content.includes('\r\n') ? '\r\n' : '\n';
  for (const [key, value] of Object.entries(fields)) {
    const pattern = new RegExp(`^${key} = [^\\r\\n]*`, 'm');
    if (pattern.test(content)) content = content.replace(pattern, `${key} = ${value}`);
    else content = `${content.trimEnd()}${newline}${key} = ${value}${newline}`;
  }
  return { content, recipe };
}
