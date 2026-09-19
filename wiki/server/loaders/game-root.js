import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const serverRoot = dirname(fileURLToPath(import.meta.url));
export const repositoryRoot = resolve(serverRoot, '..', '..', '..');

export function isGameRoot(candidate) {
  return Boolean(
    candidate
    && existsSync(resolve(candidate, 'project.godot'))
    && existsSync(resolve(candidate, 'assets'))
    && existsSync(resolve(candidate, 'core/resources/items/definitions'))
  );
}

const candidates = [
  {
    label: 'configured',
    path: process.env.INFINITEFORGE_GAME_ROOT
      ? resolve(process.env.INFINITEFORGE_GAME_ROOT)
      : null,
  },
  { label: 'parent', path: resolve(repositoryRoot, '..') },
  { label: 'sibling', path: resolve(repositoryRoot, '..', 'InfiniteForge') },
  { label: 'snapshot', path: resolve(repositoryRoot, 'game-data') },
];

if (process.env.INFINITEFORGE_GAME_ROOT && !isGameRoot(candidates[0].path)) {
  throw new Error(`Configured InfiniteForge folder does not contain game data: ${candidates[0].path}`);
}

const selected = candidates.find((candidate) => isGameRoot(candidate.path));

if (!selected) {
  throw new Error(
    'InfiniteForge game data was not found. Run "npm run sync" or set INFINITEFORGE_GAME_ROOT.'
  );
}

export const projectRoot = selected.path;
export const assetsRoot = resolve(projectRoot, 'assets');
export const gameDataSource = selected.label;
