/* ── STATE ─────────────────────────────────────────────────────────────────── */
let flatFiles = [];   // [{ node, path:[], filePath }]
let activeIdx = -1;
let sbOpen    = true;
let fpOpen    = false;
const openSet = new Set();

/* ── DOM refs ──────────────────────────────────────────────────────────────── */
const $tree          = document.getElementById('tree');
const $sbCount       = document.getElementById('sb-count');
const $center        = document.getElementById('topbar-center');
const $pdots         = document.getElementById('pdots');
const $btnPrev       = document.getElementById('btn-prev');
const $btnNext       = document.getElementById('btn-next');
const $content       = document.getElementById('content');
const $scroll        = document.getElementById('scroll-area');
const $sidebar       = document.getElementById('sidebar');
const $fpDrop        = document.getElementById('fp-dropdown');
const $folderPanel   = document.getElementById('folder-panel');
const $folderOverlay = document.getElementById('folder-panel-overlay');
const $folderList    = document.getElementById('folder-panel-list');
const $folderBtn     = document.getElementById('folder-panel-btn');
const $folderLabel   = document.getElementById('folder-panel-label');
let folderPanelOpen  = false;

/* ── UTILS ─────────────────────────────────────────────────────────────────── */
function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
function countFiles(node) {
  if (node.type === 'file') return 1;
  return (node.children || []).reduce((s, c) => s + countFiles(c), 0);
}
function countFolders(nodes) {
  let c = 0;
  for (const n of nodes) if (n.type === 'folder') c += 1 + countFolders(n.children || []);
  return c;
}

/* ── FLATTEN ───────────────────────────────────────────────────────────────── */
function buildFlat(nodes, pathArr, fpPrefix) {
  for (const node of nodes) {
    const p  = [...pathArr, node.name];
    const fp = fpPrefix ? `${fpPrefix}/${node.name}` : node.name;
    if (node.type === 'file') {
      flatFiles.push({ node, path: p, filePath: fp });
    } else if (node.children) {
      buildFlat(node.children, p, fp);
    }
  }
}

/* ── SIDEBAR TREE ──────────────────────────────────────────────────────────── */
function buildTree(nodes, container, depth) {
  for (const node of nodes) {
    if (node.type === 'file') {
      const idx = flatFiles.findIndex(f => f.node === node);
      const row = document.createElement('div');
      row.className = 'file-row' + (idx === activeIdx ? ' active' : '');
      row.style.setProperty('--depth', depth);
      row.innerHTML = `<span class="file-dot"></span><span class="file-name">${esc(node.name)}</span>`;
      row.addEventListener('click', () => openNote(idx));
      container.appendChild(row);
    } else if (node.type === 'folder') {
      const key    = `${depth}_${node.name}`;
      const isOpen = openSet.has(key);
      const row    = document.createElement('div');
      row.className = 'folder-row' + (isOpen ? ' open' : '');
      row.style.setProperty('--depth', depth);
      row.innerHTML = `
        <span class="folder-chevron">▶</span>
        <span class="folder-icon">${node.icon || '📁'}</span>
        <span class="folder-name">${esc(node.name)}</span>
        <span class="folder-badge">${countFiles(node)}</span>`;
      const ch = document.createElement('div');
      ch.className = 'folder-children' + (isOpen ? ' open' : '');
      row.addEventListener('click', () => {
        const now = row.classList.toggle('open');
        ch.classList.toggle('open', now);
        now ? openSet.add(key) : openSet.delete(key);
      });
      container.appendChild(row);
      container.appendChild(ch);
      buildTree(node.children || [], ch, depth + 1);
    }
  }
}

function renderTree() {
  $tree.innerHTML = '';
  buildTree(window._tree || [], $tree, 0);
  $sbCount.textContent = `${countFolders(window._tree || [])} папок · ${flatFiles.length} файлов`;
}

/* ── SIBLINGS (файлы в той же папке) ───────────────────────────────────────── */
function getSiblings(idx) {
  const parent = flatFiles[idx].path.slice(0, -1).join('/');
  return flatFiles
    .map((f, i) => ({ ...f, idx: i }))
    .filter(f => f.path.slice(0, -1).join('/') === parent);
}

/* ── TOPBAR ────────────────────────────────────────────────────────────────── */
function renderTopbar() {
  $btnPrev.disabled = activeIdx <= 0;
  $btnNext.disabled = activeIdx < 0 || activeIdx >= flatFiles.length - 1;

  if (activeIdx < 0) {
    $center.innerHTML = `<span class="bc-placeholder">выбери конспект</span>`;
    $pdots.innerHTML  = '';
    return;
  }

  const { path: p } = flatFiles[activeIdx];
  const dirs  = p.slice(0, -1);
  const fname = p[p.length - 1];
  const sibs  = getSiblings(activeIdx);

  // breadcrumb + trigger
  const bcHtml = dirs.map(d => `<span class="bc-seg">${esc(d)}</span><span class="bc-sep">/</span>`).join('');
  $center.innerHTML = `
    <div class="bc">
      ${bcHtml}
      <span class="fp-trigger${fpOpen ? ' open' : ''}" id="fp-trigger">
        ${esc(fname)} <span class="fp-arr">▼</span>
      </span>
    </div>`;

  // dots — кликабельные
  if (sibs.length > 1) {
    $pdots.innerHTML = sibs.map(s =>
      `<div class="pdot ${s.idx === activeIdx ? 'active' : ''}" data-idx="${s.idx}" title="${esc(s.node.name)}"></div>`
    ).join('');
    $pdots.querySelectorAll('.pdot').forEach(dot => {
      dot.addEventListener('click', () => openNote(Number(dot.dataset.idx)));
    });
  } else {
    $pdots.innerHTML = '';
  }

  // attach trigger listener
  document.getElementById('fp-trigger').addEventListener('click', e => {
    e.stopPropagation();
    fpOpen = !fpOpen;
    positionDropdown();
    renderTopbar();         // re-render trigger .open class
  });
}

/* ── DROPDOWN: позиционирование под триггером ──────────────────────────────── */
function positionDropdown() {
  if (!fpOpen || activeIdx < 0) {
    $fpDrop.classList.remove('open');
    return;
  }

  const trigger = document.getElementById('fp-trigger');
  if (!trigger) return;

  const sibs = getSiblings(activeIdx);
  $fpDrop.innerHTML = sibs.map(s => `
    <div class="fp-item ${s.idx === activeIdx ? 'active' : ''}" data-idx="${s.idx}">
      <span class="fp-item-name">${esc(s.node.title || s.node.name)}</span>
      <span class="fp-item-n">${sibs.indexOf(s) + 1}/${sibs.length}</span>
    </div>`).join('');

  // события через делегирование — не теряются при перерисовке
  $fpDrop.querySelectorAll('.fp-item').forEach(el => {
    el.addEventListener('click', e => {
      e.stopPropagation();
      fpOpen = false;
      $fpDrop.classList.remove('open');
      openNote(Number(el.dataset.idx));
    });
  });

  // позиция
  const rect = trigger.getBoundingClientRect();
  $fpDrop.style.top  = `${rect.bottom + 6}px`;
  $fpDrop.style.left = `${rect.left + rect.width / 2}px`;
  $fpDrop.style.transform = 'translateX(-50%)';
  $fpDrop.classList.add('open');
}

/* ── OPEN NOTE ─────────────────────────────────────────────────────────────── */
async function openNote(idx) {
  activeIdx = idx;
  fpOpen    = false;
  $fpDrop.classList.remove('open');

  renderTree();
  renderTopbar();

  // skeleton
  $content.style.animation = 'none';
  $content.offsetHeight;
  $content.style.animation = '';
  $content.innerHTML = `
    <div class="skeleton-line" style="width:40%;height:28px;margin-bottom:20px"></div>
    <div class="skeleton-line" style="width:80%"></div>
    <div class="skeleton-line"></div>
    <div class="skeleton-line" style="width:60%"></div>`;

  const entry = flatFiles[idx];
  const sibs  = getSiblings(idx);
  const si    = sibs.findIndex(s => s.idx === idx);
  const prev  = sibs[si - 1];
  const next  = sibs[si + 1];

  try {
    const base    = window._base || '';
    const encoded = entry.filePath.split('/').map(encodeURIComponent).join('/');
    const res = await fetch(`${base}/learn/${encoded}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const text = await res.text();

    const isHtml = entry.node.name.endsWith('.html');
    const body   = isHtml ? text : `<div class="md">${marked.parse(text)}</div>`;

    const prevBtn = prev
      ? `<button class="bnav-btn" data-nav="${prev.idx}">
           <span class="bnav-arr">←</span>
           <div class="bnav-info">
             <span class="bnav-lbl">Предыдущий</span>
             <span class="bnav-ttl">${esc(prev.node.title || prev.node.name)}</span>
           </div>
         </button>`
      : '<div></div>';
    const nextBtn = next
      ? `<button class="bnav-btn right" data-nav="${next.idx}">
           <div class="bnav-info">
             <span class="bnav-lbl">Следующий</span>
             <span class="bnav-ttl">${esc(next.node.title || next.node.name)}</span>
           </div>
           <span class="bnav-arr">→</span>
         </button>`
      : '<div></div>';

    $content.innerHTML = `${body}<div class="bottom-nav">${prevBtn}${nextBtn}</div>`;

    // слушатели на кнопки bottom-nav
    $content.querySelectorAll('.bnav-btn[data-nav]').forEach(btn => {
      btn.addEventListener('click', () => openNote(Number(btn.dataset.nav)));
    });

  } catch (err) {
    $content.innerHTML = `<p style="color:#c0392b;font-family:'JetBrains Mono',monospace;font-size:13px">❌ ${esc(err.message)}</p>`;
  }

  $scroll.scrollTo({ top: 0, behavior: 'smooth' });
  history.replaceState({}, '', `#${encodeURIComponent(entry.filePath)}`);
}

/* ── FOLDER PANEL ──────────────────────────────────────────────────────────── */
// Собираем все папки первого уровня дерева (и вложенные рекурсивно)
function collectFolders(nodes, prefix) {
  const result = [];
  for (const node of nodes) {
    if (node.type !== 'folder') continue;
    const path = prefix ? `${prefix}/${node.name}` : node.name;
    result.push({ node, path, depth: prefix ? prefix.split('/').length : 0 });
    result.push(...collectFolders(node.children || [], path));
  }
  return result;
}

function getCurrentFolder() {
  if (activeIdx < 0) return null;
  return flatFiles[activeIdx].path.slice(0, -1).join('/');
}

function renderFolderPanel() {
  const folders = collectFolders(window._tree || [], '');
  const curFolder = getCurrentFolder();

  if (!folders.length) {
    $folderList.innerHTML = `<div style="padding:16px;font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--text-dim)">Папки не найдены</div>`;
    return;
  }

  $folderList.innerHTML = folders.map(({ node, path, depth }) => {
    const isActive = curFolder === path;
    const fileCount = countFiles(node);
    const indent = depth * 14;
    return `
      <div class="fp-folder-item ${isActive ? 'active' : ''}" data-path="${esc(path)}" style="padding-left:${16 + indent}px">
        <span class="fp-folder-icon">${node.icon || '📁'}</span>
        <div class="fp-folder-info" style="min-width:0">
          <span class="fp-folder-name">${esc(node.name)}</span>
          <span class="fp-folder-count">${fileCount} файл${fileCount === 1 ? '' : fileCount < 5 ? 'а' : 'ов'}</span>
        </div>
      </div>`;
  }).join('');

  $folderList.querySelectorAll('.fp-folder-item').forEach(el => {
    el.addEventListener('click', () => {
      const targetPath = el.dataset.path;
      // найти первый файл в этой папке
      const first = flatFiles.find(f => f.path.slice(0, -1).join('/') === targetPath);
      if (first) {
        closeFolderPanel();
        // раскрыть папки в дереве по пути
        first.path.slice(0, -1).forEach((seg, d) => openSet.add(`${d}_${seg}`));
        renderTree();
        openNote(flatFiles.indexOf(first));
      }
    });
  });
}

function openFolderPanel() {
  folderPanelOpen = true;
  $folderPanel.classList.add('open');
  $folderOverlay.classList.add('open');
  $folderBtn.classList.add('open');
  renderFolderPanel();
}

function closeFolderPanel() {
  folderPanelOpen = false;
  $folderPanel.classList.remove('open');
  $folderOverlay.classList.remove('open');
  $folderBtn.classList.remove('open');
}

$folderBtn.addEventListener('click', () => folderPanelOpen ? closeFolderPanel() : openFolderPanel());
$folderOverlay.addEventListener('click', closeFolderPanel);
document.getElementById('folder-panel-close').addEventListener('click', closeFolderPanel);

/* ── FLOATING BUTTONS POSITION ─────────────────────────────────────────────── */
function updateFloatPos() {
  const sidebarW = sbOpen ? 260 : 0; // var(--sidebar-w) = 260px
  document.getElementById('float-left').style.left = `${sidebarW + 16}px`;
}

/* ── KEYBOARD & CONTROLS ───────────────────────────────────────────────────── */
document.getElementById('toggle-btn').addEventListener('click', () => {
  sbOpen = !sbOpen;
  $sidebar.classList.toggle('collapsed', !sbOpen);
  updateFloatPos();
});
$btnPrev.addEventListener('click', () => { if (activeIdx > 0) openNote(activeIdx - 1); });
$btnNext.addEventListener('click', () => { if (activeIdx < flatFiles.length - 1) openNote(activeIdx + 1); });

document.addEventListener('keydown', e => {
  if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
  if (e.key === 'ArrowRight' && activeIdx < flatFiles.length - 1) openNote(activeIdx + 1);
  if (e.key === 'ArrowLeft'  && activeIdx > 0) openNote(activeIdx - 1);
  if (e.key === 'b' || e.key === 'B') {
    sbOpen = !sbOpen;
    $sidebar.classList.toggle('collapsed', !sbOpen);
    updateFloatPos();
  }
  if (e.key === 'Escape' && fpOpen) {
    fpOpen = false;
    $fpDrop.classList.remove('open');
    renderTopbar();
  }
});

// закрыть dropdown при клике вне
document.addEventListener('click', e => {
  if (fpOpen && !$fpDrop.contains(e.target)) {
    fpOpen = false;
    $fpDrop.classList.remove('open');
    renderTopbar();
  }
});

// пересчитать позицию dropdown при ресайзе
window.addEventListener('resize', () => { if (fpOpen) positionDropdown(); });

/* ── INIT ──────────────────────────────────────────────────────────────────── */
(async () => {
  // Определяем base path для GitHub Pages (репо может быть в подпапке)
  // На GitHub Pages: https://user.github.io/repo-name/ → base = '/repo-name'
  // Локально или на корне: base = ''
  const base = window.SITE_BASE || '';

  try {
    const res  = await fetch(`${base}/learn/index.json`);
    if (!res.ok) throw new Error('index.json не найден. Запусти: node scripts/build-index.js');
    const tree = await res.json();

    window._tree  = tree;
    window._base  = base;
    buildFlat(tree, [], '');
    renderTree();
    renderTopbar();
    updateFloatPos();

    // открыть файл из хэша URL
    const hash = decodeURIComponent(location.hash.slice(1));
    if (hash) {
      const idx = flatFiles.findIndex(f => f.filePath === hash);
      if (idx >= 0) {
        flatFiles[idx].path.slice(0, -1).forEach((seg, d) => openSet.add(`${d}_${seg}`));
        renderTree();
        openNote(idx);
      }
    }
  } catch (err) {
    $tree.innerHTML = `
      <div style="padding:12px 16px;font-family:'JetBrains Mono',monospace;font-size:11px;color:#c0392b">
        ⚠ ${esc(err.message)}
      </div>`;
  }
})();
