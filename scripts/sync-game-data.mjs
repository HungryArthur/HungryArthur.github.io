import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { dirname, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptsRoot = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptsRoot, '..');
const argumentIndex = process.argv.indexOf('--game-root');
const argumentGameRoot = argumentIndex >= 0 ? process.argv[argumentIndex + 1] : null;
const gameRoot = resolve(
  argumentGameRoot
    ?? process.env.INFINITEFORGE_GAME_ROOT
    ?? resolve(repositoryRoot, '..', 'InfiniteForge')
);

function isGameRoot(candidate) {
  return existsSync(resolve(candidate, 'project.godot'))
    && existsSync(resolve(candidate, 'assets'))
    && existsSync(resolve(candidate, 'core/resources/items/definitions'));
}

if (!isGameRoot(gameRoot)) {
  throw new Error(
    `InfiniteForge not found at "${gameRoot}". Use --game-root <path> or INFINITEFORGE_GAME_ROOT.`
  );
}

const sourceFiles = [
  'wiki/server/index.js',
  'wiki/server/loaders/game-root.js',
];
const serverSource = sourceFiles
  .map((file) => readFileSync(resolve(repositoryRoot, file), 'utf8'))
  .join('\n');
const referencedPaths = [
  'assets',
  ...[...serverSource.matchAll(/resolve\(projectRoot, '([^']+)'/g)]
    .map((match) => match[1].replaceAll('/', sep)),
];

const sources = [...new Set(referencedPaths)]
  .filter((entry) => existsSync(resolve(gameRoot, entry)))
  .sort((left, right) => left.length - right.length)
  .filter((entry, index, entries) => !entries.slice(0, index).some((parent) => {
    const parentPath = resolve(gameRoot, parent);
    return statSync(parentPath).isDirectory()
      && resolve(gameRoot, entry).startsWith(`${parentPath}${sep}`);
  }));

const dataRoot = resolve(repositoryRoot, 'game-data');
const nextRoot = resolve(repositoryRoot, 'game-data.next');
const previousRoot = resolve(repositoryRoot, 'game-data.previous');

rmSync(nextRoot, { recursive: true, force: true });
mkdirSync(nextRoot, { recursive: true });

for (const source of sources) {
  const from = resolve(gameRoot, source);
  const to = resolve(nextRoot, source);
  mkdirSync(dirname(to), { recursive: true });
  cpSync(from, to, { recursive: true });
}

writeFileSync(resolve(nextRoot, '.snapshot.json'), `${JSON.stringify({
  generatedAt: new Date().toISOString(),
  source: relative(resolve(repositoryRoot, '..'), gameRoot) || '.',
  entries: sources.map((entry) => entry.split(sep).join('/')),
}, null, 2)}\n`);

rmSync(previousRoot, { recursive: true, force: true });
if (existsSync(dataRoot)) renameSync(dataRoot, previousRoot);

try {
  renameSync(nextRoot, dataRoot);
  rmSync(previousRoot, { recursive: true, force: true });
} catch (error) {
  if (!existsSync(dataRoot) && existsSync(previousRoot)) renameSync(previousRoot, dataRoot);
  throw error;
}

console.log(`Wiki data synchronized from: ${gameRoot}`);
console.log(`Snapshot entries: ${sources.length}`);
