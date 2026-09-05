export function readWikiRoute(location = window.location) {
  const parts = location.pathname.split('/').filter(Boolean);
  const requestedLanguage = new URLSearchParams(location.search).get('lang');
  const language = parts[0] === 'en' || requestedLanguage === 'en' ? 'en' : 'ru';

  return {
    parts,
    language,
    page: parts[1] || 'home',
    articleId: parts[2] || '',
  };
}

export function localizedPath(language, pagePath = 'home') {
  return `/${language}/${pagePath}`;
}
