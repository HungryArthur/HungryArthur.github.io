# 📚 Конспекты — GitHub Pages версия

Статический сайт с конспектами. Работает на GitHub Pages без сервера.

## 🚀 Как задеплоить

### 1. Создай репозиторий на GitHub

```bash
git init
git remote add origin https://github.com/ВАШ_НИК/ВАШ_РЕПО.git
```

### 2. Если репозиторий называется не `ВАШ_НИК.github.io`

Открой `index.html` и найди строку в `<head>`:
```html
<!-- <script>window.SITE_BASE = '/ИМЯ_РЕПО'</script> -->
```
Раскомментируй и замени `ИМЯ_РЕПО` на имя своего репозитория.

Если репозиторий называется `ВАШ_НИК.github.io` — ничего менять не нужно.

### 3. Включи GitHub Pages

В настройках репозитория: **Settings → Pages → Source → Deploy from branch → `gh-pages`**

### 4. Запушь

```bash
git add .
git commit -m "initial"
git push -u origin main
```

GitHub Action запустится автоматически, сгенерирует `index.json` и задеплоит сайт.

---

## ➕ Добавить конспект

1. Положи `.md` или `.html` файл в папку `learn/` (можно в подпапку)
2. `git add . && git commit -m "add lesson" && git push`
3. Через ~1 минуту файл появится на сайте автоматически

---

## 💻 Локальный запуск (без Node.js)

```bash
# сгенерировать index.json вручную
node scripts/build-index.js

# запустить любой статический сервер
npx serve .
# или
python3 -m http.server 8080
```

---

## 📁 Структура

```
project/
├── index.html
├── css/main.css
├── js/app.js
├── scripts/
│   └── build-index.js       ← генератор index.json
├── .github/workflows/
│   └── deploy.yml           ← GitHub Action
└── learn/
    ├── index.json            ← auto-generated, не редактируй руками
    ├── Go/
    │   └── 01_goroutines.md
    └── ...
```
