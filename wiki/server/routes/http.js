import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, isAbsolute, relative } from 'node:path';

const mimeTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.webp': 'image/webp',
};

const commonHeaders = {
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'same-origin',
};

export function sendJson(response, statusCode, data) {
  const body = JSON.stringify(data, null, 2);
  response.writeHead(statusCode, {
    ...commonHeaders,
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Cache-Control': 'no-store',
  });
  response.end(body);
}

export function sendFile(response, filePath, method, cacheControl = 'no-cache') {
  if (!existsSync(filePath) || !statSync(filePath).isFile()) {
    sendJson(response, 404, { error: 'not_found' });
    return;
  }

  const stat = statSync(filePath);
  const contentType = mimeTypes[extname(filePath).toLowerCase()] ?? 'application/octet-stream';
  response.writeHead(200, {
    ...commonHeaders,
    'Content-Type': contentType,
    'Content-Length': stat.size,
    'Cache-Control': cacheControl,
  });
  if (method === 'HEAD') {
    response.end();
    return;
  }
  createReadStream(filePath).pipe(response);
}

export function isPathInside(root, candidate) {
  const pathFromRoot = relative(root, candidate);
  return pathFromRoot !== ''
    && !pathFromRoot.startsWith('..')
    && !isAbsolute(pathFromRoot);
}
