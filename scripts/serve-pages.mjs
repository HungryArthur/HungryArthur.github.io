import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const outputRoot = resolve(repositoryRoot, 'dist');
const host = process.env.PAGES_HOST ?? '127.0.0.1';
const port = Number.parseInt(process.env.PAGES_PORT ?? '4173', 10);
const contentTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.xml': 'application/xml; charset=utf-8',
};

if (!existsSync(resolve(outputRoot, 'index.html'))) {
  throw new Error('Static build is missing. Run "npm run build:pages" first.');
}

function resolveRequestPath(requestUrl) {
  const pathname = decodeURIComponent(new URL(requestUrl, `http://${host}:${port}`).pathname);
  const relativePath = pathname.replace(/^\/+/, '');
  let target = resolve(outputRoot, relativePath);
  if (target !== outputRoot && !target.startsWith(`${outputRoot}${sep}`)) return null;
  if (existsSync(target) && statSync(target).isDirectory()) target = resolve(target, 'index.html');
  if (!existsSync(target)) return resolve(outputRoot, '404.html');
  return target;
}

createServer((request, response) => {
  const target = resolveRequestPath(request.url ?? '/');
  if (!target) {
    response.writeHead(400).end('Bad request');
    return;
  }
  const isNotFound = target === resolve(outputRoot, '404.html');
  response.writeHead(isNotFound ? 404 : 200, {
    'Content-Type': contentTypes[extname(target).toLowerCase()] ?? 'application/octet-stream',
  });
  if (request.method === 'HEAD') response.end();
  else createReadStream(target).pipe(response);
}).listen(port, host, () => {
  console.log(`GitHub Pages preview: http://${host}:${port}/`);
});
