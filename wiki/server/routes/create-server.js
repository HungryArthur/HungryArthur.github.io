import { createServer } from 'node:http';
import { resolve } from 'node:path';
import { isPathInside, sendFile, sendJson } from './http.js';

export function createWikiServer({
  assetsRoot,
  clientRoot,
  getHealth,
  handleApi,
  host,
  isWikiPageRoute,
  wikiPage,
}) {
  return createServer((request, response) => {
    const method = request.method ?? 'GET';
    if (method !== 'GET' && method !== 'HEAD') {
      response.writeHead(405, { Allow: 'GET, HEAD', 'X-Content-Type-Options': 'nosniff' });
      response.end();
      return;
    }

    const requestUrl = new URL(request.url ?? '/', `http://${request.headers.host ?? host}`);
    let pathname;
    try {
      pathname = decodeURIComponent(requestUrl.pathname);
    } catch {
      sendJson(response, 400, { error: 'invalid_url' });
      return;
    }

    if (pathname === '/') {
      response.writeHead(302, { Location: '/ru/home' });
      response.end();
      return;
    }

    const route = pathname.split('/').filter(Boolean);
    if (pathname === '/api/v1/health') {
      sendJson(response, 200, getHealth());
      return;
    }
    if (route[0] === 'assets') {
      const assetPath = resolve(assetsRoot, ...route.slice(1));
      if (!isPathInside(assetsRoot, assetPath)) {
        sendJson(response, 404, { error: 'asset_not_found' });
        return;
      }
      sendFile(response, assetPath, method, 'public, max-age=3600');
      return;
    }
    if (route[0] === 'client') {
      const clientPath = resolve(clientRoot, ...route.slice(1));
      if (!isPathInside(clientRoot, clientPath)) {
        sendJson(response, 404, { error: 'client_file_not_found' });
        return;
      }
      sendFile(response, clientPath, method);
      return;
    }
    if (route[0] === 'api' && route[1] === 'v1') {
      handleApi(response, route, requestUrl.searchParams);
      return;
    }
    if (isWikiPageRoute(route)) {
      sendFile(response, wikiPage, method);
      return;
    }
    sendJson(response, 404, { error: 'page_not_found' });
  });
}
