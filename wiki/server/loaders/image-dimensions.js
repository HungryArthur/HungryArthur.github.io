import { readFileSync } from 'node:fs';
import { extname } from 'node:path';

// Dimensions of the source image, not the region of a Godot AtlasTexture.
export function imageDimensions(filePath) {
  const data = readFileSync(filePath);
  const extension = extname(filePath).toLowerCase();
  if (extension === '.png') {
    if (data.length < 33 || !data.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) {
      throw new Error(`Invalid PNG: ${filePath}`);
    }
    return { width: data.readUInt32BE(16), height: data.readUInt32BE(20) };
  }
  if (extension === '.svg') {
    const root = data.toString('utf8').match(/<svg\b[^>]*>/i)?.[0] ?? '';
    const attribute = name => root.match(new RegExp(`\\b${name}\\s*=\\s*["']([^"']+)["']`, 'i'))?.[1];
    const length = value => /^\d+(?:\.\d+)?(?:px)?$/.test(value ?? '') ? Number.parseFloat(value) : 0;
    const viewBox = attribute('viewBox')?.trim().split(/[\s,]+/).map(Number);
    const width = length(attribute('width')) || viewBox?.[2];
    const height = length(attribute('height')) || viewBox?.[3];
    if (!(width > 0 && height > 0)) throw new Error(`SVG has no usable dimensions: ${filePath}`);
    return { width, height };
  }
  return null;
}
