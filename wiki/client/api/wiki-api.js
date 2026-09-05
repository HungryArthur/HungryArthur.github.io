export async function fetchWikiJson(path) {
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
