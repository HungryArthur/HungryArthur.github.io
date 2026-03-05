/**
 * scripts/build-index.js
 * Запускается GitHub Action при каждом push.
 * Рекурсивно сканирует папку learn/ и записывает learn/index.json —
 * то же дерево, что раньше отдавал /api/tree на Node.js сервере.
 */

const fs   = require('fs');
const path = require('path');

const LEARN_DIR  = path.join(__dirname, '..', 'learn');
const OUTPUT     = path.join(LEARN_DIR, 'index.json');

const ICONS = {
  go: '🐹', docker: '🐳', linux: '🐧', python: '🐍',
  js: '🟨', ts: '🔷', rust: '🦀', k8s: '☸️', git: '📦',
  network: '🌐', db: '🗄️', security: '🔒', kafka: '📨',
  redis: '🟥', nginx: '🟩', aws: '☁️', default: '📁'
};

function folderIcon(name) {
  const n = name.toLowerCase();
  for (const [key, icon] of Object.entries(ICONS)) {
    if (n.includes(key)) return icon;
  }
  return ICONS.default;
}

function scanDir(dirPath, rel) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true })
    .sort((a, b) => {
      if (a.isDirectory() !== b.isDirectory())
        return a.isDirectory() ? -1 : 1;
      return a.name.localeCompare(b.name, undefined, { numeric: true });
    });

  const result = [];
  for (const entry of entries) {
    if (entry.name === 'index.json') continue; // пропускаем себя
    const full    = path.join(dirPath, entry.name);
    const relPath = rel ? `${rel}/${entry.name}` : entry.name;

    if (entry.isDirectory()) {
      const children = scanDir(full, relPath);
      if (children.length > 0) {
        result.push({
          type:     'folder',
          name:     entry.name,
          icon:     folderIcon(entry.name),
          path:     relPath,
          children
        });
      }
    } else if (/\.(md|html)$/i.test(entry.name)) {
      result.push({
        type:  'file',
        name:  entry.name,
        title: fileToTitle(entry.name),
        path:  relPath,
        ext:   path.extname(entry.name).slice(1).toLowerCase()
      });
    }
  }
  return result;
}

function fileToTitle(filename) {
  return filename
    .replace(/\.(md|html)$/i, '')
    .replace(/^\d+[-_.]?/, '')
    .replace(/[-_.]/g, ' ')
    .trim()
    .replace(/\b\w/g, c => c.toUpperCase()) || filename;
}

const tree = scanDir(LEARN_DIR, '');
fs.writeFileSync(OUTPUT, JSON.stringify(tree, null, 2), 'utf8');
console.log(`✅ learn/index.json written (${tree.length} top-level entries)`);
