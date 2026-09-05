export const languages = new Set(['ru', 'en']);

export function normalizeLanguage(language) {
  return languages.has(language) ? language : 'ru';
}
