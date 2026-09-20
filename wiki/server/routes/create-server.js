import { createServer } from 'node:http';
import { resolve } from 'node:path';
import { isPathInside, sendFile, sendJson } from './http.js';

export function createWikiServer({
  assetsRoot,
  clientRoot,
  getHealth,
  handleApi,
  handleRecipeEdit,
  host,
  isWikiPageRoute,
  wikiPage,
}) {
  return createServer(async (request, response) => {
    const method = request.method ?? 'GET';
    const editRoute = /^\/api\/v1\/(ru|en)\/crafting-balance\/([a-z][a-z0-9_]*)$/.exec(request.url ?? '');
    if (method === 'PUT' && editRoute && handleRecipeEdit) {
      const localAddresses = ['127.0.0.1', '::1', '::ffff:127.0.0.1'];
      const origin = request.headers.origin;
      const expectedOrigin = `http://${request.headers.host}`;
      let localHost = false;
      try { localHost = ['localhost', '127.0.0.1', '[::1]'].includes(new URL(expectedOrigin).hostname); } catch {}
      if (!localAddresses.includes(request.socket.remoteAddress) || !localHost || (origin && origin !== expectedOrigin)) {
        sendJson(response, 403, { error: 'local_only' });
        return;
      }
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        sendJson(response, 415, { error: 'json_required' });
        return;
      }
      try {
        let body = '';
        for await (const chunk of request) {
          body += chunk;
          if (Buffer.byteLength(body) > 16384) {
            sendJson(response, 413, { error: 'request_too_large' });
            return;
          }
        }
        const payload = JSON.parse(body);
        handleRecipeEdit(response, editRoute[1], editRoute[2], payload);
      } catch (error) {
        sendJson(response, 400, { error: error instanceof SyntaxError ? 'invalid_json' : 'save_failed' });
      }
      return;
    }
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
