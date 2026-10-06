import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { resolve, relative, isAbsolute } from 'node:path';
import { imageDimensions } from '../wiki/server/loaders/image-dimensions.js';

const checked = new Map();
function imageFile(root, url) {
  assert.ok(url.startsWith('/assets/'), `Unexpected image URL: ${url}`);
  const path = resolve(root, url.slice(1));
  const rel = relative(root, path);
  assert.ok(!rel.startsWith('..') && !isAbsolute(rel), `Image outside site: ${url}`);
  if (checked.has(path)) return checked.get(path);
  // Windows tolerates the wrong case; GitHub Pages does not.
  let parent = root;
  for (const part of url.slice(1).split('/')) {
    assert.ok(readdirSync(parent).includes(part), `Missing image or wrong filename case: ${url}`);
    parent = resolve(parent, part);
  }
  const dimensions = imageDimensions(path);
  assert.ok(dimensions?.width > 0 && dimensions?.height > 0, `Unsupported image format: ${url}`);
  checked.set(path, dimensions);
  return dimensions;
}

export function validateTexture(texture, root, label = '') {
  assert.ok(texture?.path, `No texture: ${label}`);
  const dimensions = imageFile(root, texture.path);
  assert.deepEqual(texture.dimensions, dimensions, `Incorrect image dimensions: ${label || texture.path}`);
  if (texture.atlas) {
    const { x, y, width, height } = texture.atlas;
    assert.ok([x,y,width,height].every(Number.isInteger), `Non-pixel atlas region: ${label}`);
    assert.ok(x >= 0 && y >= 0 && width > 0 && height > 0
      && x + width <= dimensions.width && y + height <= dimensions.height,
    `Atlas region outside image: ${label || texture.path}`);
  }
}

export function validateCatalogTextures(catalog, root) {
  let count = 0;
  function visit(value) {
    if (!value || typeof value !== 'object') return;
    if (value.path?.startsWith('/assets/') && 'atlas' in value) {
      validateTexture(value, root); count++;
    }
    for (const child of Object.values(value)) visit(child);
  }
  visit(catalog);
  return count;
}

export function validateSprite32(texture, root, label = '') {
  validateTexture(texture, root, label);
  const { width, height } = texture.atlas ?? texture.dimensions;
  assert.equal(width, 32, `Sprite width must be 32: ${label}`);
  assert.equal(height, 32, `Sprite height must be 32: ${label}`);
}

export function loadArtManifest(gameRoot) {
  const manifestPath = [
    resolve(gameRoot, 'tools/pixel_art/data/texture_art_manifest.json'),
    resolve(gameRoot, 'docs/generated/texture_art_manifest.json'),
  ].find(existsSync);
  assert.ok(manifestPath, 'Texture manifest missing. Run the game-data synchronization first.');
  return JSON.parse(readFileSync(manifestPath, 'utf8'));
}

export function validateArtManifest(gameRoot, outputRoot = gameRoot) {
  const entries = loadArtManifest(gameRoot);
  for (const e of entries) {
    validateTexture({ path: `/${e.output}`, dimensions: { width: e.width, height: e.height }, atlas: null }, outputRoot, e.id);
    if (gameRoot !== outputRoot) {
      assert.ok(readFileSync(resolve(gameRoot, e.output)).equals(readFileSync(resolve(outputRoot, e.output))),
        `Image changed while copying to site: ${e.id}`);
    }
  }
  return entries.length;
}
