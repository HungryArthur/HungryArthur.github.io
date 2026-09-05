import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const serverRoot = dirname(fileURLToPath(import.meta.url));
export const repositoryRoot = resolve(serverRoot, '..', '..', '..');

function isGameRoot(candidate) {
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
  { label: 'sibling', path: resolve(repositoryRoot, '..', 'InfiniteForge') },
  { label: 'snapshot', path: resolve(repositoryRoot, 'game-data') },
];

const selected = candidates.find((candidate) => isGameRoot(candidate.path));

if (!selected) {
  throw new Error(
    'InfiniteForge game data was not found. Run "npm run sync" or set INFINITEFORGE_GAME_ROOT.'
  );
}

export const projectRoot = selected.path;
export const assetsRoot = resolve(projectRoot, 'assets');
export const gameDataSource = selected.label;
