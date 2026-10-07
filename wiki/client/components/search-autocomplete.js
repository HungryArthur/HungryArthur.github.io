import { fetchWikiSearchIndex } from '../api/wiki-api.js';
import { rankSearchSuggestions } from './search-suggestions.js';

let autocompleteId = 0;

export function attachSearchAutocomplete(input, language, typeLabels) {
  const labels = language === 'en'
    ? { suggestions: 'Suggested pages', count: (count) => `${count} suggestions. Use up and down arrows to choose.` }
    : { suggestions: 'Подходящие страницы', count: (count) => `Подсказок: ${count}. Для выбора используйте стрелки вверх и вниз.` };
  const host = document.createElement('div');
  host.className = 'search-autocomplete';
  input.before(host);
  host.append(input);
  const list = document.createElement('div');
  list.id = `search-suggestions-${++autocompleteId}`;
  list.className = 'search-suggestions';
  list.setAttribute('role', 'listbox');
  list.setAttribute('aria-label', labels.suggestions);
  list.hidden = true;
  const status = document.createElement('span');
  status.className = 'visually-hidden';
  status.setAttribute('role', 'status');
  host.append(list, status);
  input.setAttribute('role', 'combobox');
  input.setAttribute('aria-autocomplete', 'list');
  input.setAttribute('aria-controls', list.id);
  input.setAttribute('aria-expanded', 'false');
  input.setAttribute('autocomplete', 'off');
  const listeners = new AbortController();
  const options = { signal: listeners.signal };
  let revision = 0;
  let suggestions = [];
  let active = -1;

  function close() {
    revision += 1;
    list.hidden = true;
    active = -1;
    input.setAttribute('aria-expanded', 'false');
    input.removeAttribute('aria-activedescendant');
    status.textContent = '';
  }

  function select(index) {
    active = index;
    [...list.children].forEach((option, position) => {
      option.setAttribute('aria-selected', String(position === active));
    });
    if (active >= 0) {
      input.setAttribute('aria-activedescendant', list.children[active].id);
      list.children[active].scrollIntoView({ block: 'nearest' });
    } else input.removeAttribute('aria-activedescendant');
  }

  async function update() {
    close();
    const currentRevision = revision;
    const query = input.value.trim();
    if (!query || document.activeElement !== input) return;
    try {
      const index = await fetchWikiSearchIndex(language);
      if (revision !== currentRevision || !input.isConnected || document.activeElement !== input) return;
      suggestions = rankSearchSuggestions(index.entries, query, language);
      list.replaceChildren();
      for (const [position, entry] of suggestions.entries()) {
        const option = document.createElement('a');
        option.id = `${list.id}-${position}`;
        option.href = entry.url;
        option.className = 'search-suggestion';
        option.setAttribute('role', 'option');
        option.setAttribute('aria-selected', 'false');
        option.tabIndex = -1;
        const title = document.createElement('strong');
        title.textContent = entry.title;
        const detail = document.createElement('small');
        detail.textContent = [typeLabels[entry.type], entry.meta].filter(Boolean).join(' · ');
        option.append(title, detail);
        list.append(option);
      }
      list.hidden = suggestions.length === 0;
      input.setAttribute('aria-expanded', String(suggestions.length > 0));
      status.textContent = suggestions.length ? labels.count(suggestions.length) : '';
    } catch {
      // Keep ordinary form submission available if the index cannot be loaded.
      if (revision === currentRevision) close();
    }
  }

  input.addEventListener('input', (event) => { if (!event.isComposing) update(); }, options);
  input.addEventListener('compositionend', update, options);
  input.addEventListener('focus', update, options);
  input.addEventListener('blur', close, options);
  input.addEventListener('keydown', (event) => {
    if (event.isComposing) return;
    if (event.key === 'Escape') {
      if (!list.hidden) event.preventDefault();
      close();
    } else if (!list.hidden && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
      event.preventDefault();
      const next = event.key === 'ArrowDown' ? active + 1 : (active < 0 ? suggestions.length - 1 : active - 1);
      select((next + suggestions.length) % suggestions.length);
    } else if (!list.hidden && event.key === 'Enter' && active >= 0) {
      event.preventDefault();
      window.location.assign(suggestions[active].url);
    }
  }, options);
  // Retain input focus until the option receives its click, including touch taps.
  list.addEventListener('pointerdown', (event) => { if (event.button === 0) event.preventDefault(); }, options);
  document.addEventListener('pointerdown', (event) => {
    if (!host.contains(event.target)) close();
  }, options);
  return () => { close(); listeners.abort(); };
}
