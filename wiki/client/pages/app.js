import { fetchWikiJson } from '../api/wiki-api.js';
import { showArticlePage } from '../components/article-page.js';
import { fitLoadedPixelImage, observePixelImages, pixelPerfectGeometry } from '../components/pixel-images.js';
import { escapeHtml, localizedValue, readableId } from '../components/text.js';
import { localizedPath, readWikiRoute } from './router.js';

window.fitLoadedPixelImage = fitLoadedPixelImage;
observePixelImages();

    const english = {
      'Главная': 'Main page', 'Исследование': 'Exploration', 'Развитие': 'Progression', 'Системы': 'Systems', 'Оптимизация': 'Optimization', 'Жидкости': 'Fluids', 'Квесты': 'Quests', 'Достижения': 'Achievements', 'Механики': 'Mechanics', 'Добыча': 'Gathering', 'Интерфейс': 'Interface', 'Персонажи': 'Characters', 'Предметы': 'Items', 'Рецепты': 'Recipes', 'Баланс крафтов': 'Crafting balance', 'Мобы': 'Mobs', 'Техника': 'Machines', 'Вики сообщества': 'Community wiki',
      'Добро пожаловать в InfiniteForge Wiki': 'Welcome to the InfiniteForge Wiki',
      'Здесь собрана информация о фабрике, технологиях, предметах, биомах и опасностях мира InfiniteForge.': 'Find information about factories, technologies, items, biomes, and the dangers of the InfiniteForge world.',
      'Об игре': 'About', 'Начать играть': 'Getting started', 'Список предметов': 'Item list', 'Биомы': 'Biomes',
      'Версия игры:': 'Game version:', 'Основной мир:': 'Main world:', 'биомы и боссы': 'biomes and bosses', 'Прогрессия:': 'Progression:', '6 эпох технологий': '6 technological ages', 'Режимы:': 'Modes:', 'одиночная игра и кооператив': 'single-player and co-op',
      'Русский · English': 'Russian · English', 'Материалы вики обновляются вместе с игрой': 'Wiki pages are updated with the game.',
      'InfiniteForge': 'InfiniteForge', '— игра о добыче ресурсов, строительстве производственных линий и экспедициях в опасные биомы. Начните с дерева и камня, создайте первые механизмы, освойте энергию и готовьтесь к боям с боссами. Каждая технология помогает сделать базу эффективнее и открывает путь к новым ресурсам.': 'is a game about resource gathering, production lines, and expeditions into dangerous biomes. Start with wood and stone, build your first machines, master power, and prepare to fight bosses. Every technology makes your base more efficient and opens access to new resources.',
      'Справка': 'Resources', 'Быстрый доступ': 'Quick access', 'Как начать игру': 'Getting started', 'Список руд и материалов': 'Ores and materials', 'Ресурсы и месторождения': 'Resources and deposits', 'Биомы и боссы': 'Biomes and bosses', 'Машины и автоматизация': 'Machines and automation',
      'Основы': 'Basics', 'Фабрика': 'Factory', 'Мир': 'World', 'Игровой процесс': 'Gameplay', 'Разделы вики': 'Wiki sections', 'Игра': 'Game', 'Справочники': 'Reference',
      'Начало игры': 'Getting started', 'Персонаж': 'The player', 'Инвентарь': 'Inventory', 'Выживание': 'Survival', 'Карта мира': 'World map',
      'Печи': 'Furnaces', 'Руда': 'Ore', 'Пар': 'Steam', 'Пар и котлы': 'Steam and boilers', 'Энергия': 'Energy', 'Логистика': 'Logistics', 'Конвейеры': 'Conveyors', 'Хранилища': 'Storage', 'Оптимизация фабрики': 'Factory optimization',
      'Пустыня': 'Desert', 'Снежные земли': 'Snowlands', 'Болото': 'Swamp', 'Джунгли': 'Jungle', 'Исследование мира': 'World exploration', 'Боссы': 'Bosses',
      'Бой': 'Combat', 'Оружие': 'Weapons', 'Добыча ресурсов': 'Resource gathering', 'Жидкости': 'Fluids', 'Квесты и эпохи': 'Quests and ages', 'Здоровье и голод': 'Health and hunger', 'Кооператив': 'Multiplayer',
      'Предметы и технологии': 'Items and technology', 'Инструменты': 'Tools', 'Снаряжение': 'Equipment', 'Рецепты крафта': 'Crafting recipes', 'Руды': 'Ores', 'Слитки и компоненты': 'Ingots and components', 'Топливо': 'Fuel', 'Машины': 'Machines', 'Энергетика': 'Power', 'Буры': 'Drills', 'Вода и пар': 'Water and steam', 'Переработка руды': 'Ore processing',
      'Мир за пределами базы': 'The world beyond your base', 'Ближние земли': 'Near lands', 'Опасные биомы': 'Dangerous biomes', 'Тяжёлые зоны': 'Hard zones', 'Встречи': 'Encounters',
      'Ресурсы': 'Resources', 'Производство': 'Production', 'Существа': 'Creatures', 'Гайды': 'Guides', 'Прогресс': 'Progress', 'Структуры': 'Structures', 'Растения': 'Plants', 'Материалы': 'Materials', 'Слитки': 'Ingots', 'Компоненты': 'Components', 'Растительные ресурсы': 'Plant resources', 'Броня': 'Armor', 'Аксессуары': 'Accessories', 'Расходники': 'Consumables', 'Крафт': 'Crafting', 'Технологии': 'Technologies', 'Исследования': 'Research', 'Эпохи': 'Ages', 'Развитие базы': 'Base development',
      'Переработка': 'Processing', 'Цепочки производства': 'Production chains', 'Автоматизация': 'Automation', 'Враждебные существа': 'Hostile creatures', 'Мирные существа': 'Peaceful creatures', 'Энты': 'Ents', 'Особые встречи': 'Special encounters', 'Первые 10 минут': 'First 10 minutes', 'Первый завод': 'First factory', 'Первое производство': 'First production line', 'Как получить энергию': 'How to get power', 'Как автоматизировать производство': 'How to automate production', 'Как исследовать мир': 'How to explore the world', 'Подготовка к опасным биомам': 'Preparing for dangerous biomes', 'Как победить босса': 'How to defeat a boss', 'Продвинутые фабрики': 'Advanced factories', 'Карта и биомы': 'Map and biomes', 'Системы игры': 'Game systems', 'Первая энергия': 'First power',
      'Биомы, структуры, растения и уровни опасности Верхнего мира.': 'Biomes, structures, plants, and danger tiers of the Overworld.', 'Где добывать сырьё и во что оно превращается.': 'Where to gather raw resources and what they become.', 'Машины, транспорт, энергия и автоматизация фабрики.': 'Machines, transport, power, and factory automation.', 'Снаряжение игрока, компоненты и рецепты изготовления.': 'Player equipment, components, and crafting recipes.', 'Как устроены правила и системы игры.': 'How the game rules and systems work.', 'Обитатели мира, противники, NPC и боссы.': 'World inhabitants, enemies, NPCs, and bosses.', 'Что делать игроку: от первых минут до большой фабрики.': 'What to do, from the first minutes to a large factory.', 'Эпохи, исследования и развитие базы.': 'Ages, research, and base development.',
      'Лес': 'Forest', 'Солнечный каньон': 'Sunny canyon', 'Ледяная бездна': 'Icy abyss', 'Гниющее болото': 'Rotting bog', 'Первобытные дебри': 'Primeval thicket', 'Энт': 'Ent', 'Песчаный колосс': 'Dune colossus', 'Другие боссы': 'Other bosses',
      'InfiniteForge Wiki · Справочник по игре для игроков и разработчиков.': 'InfiniteForge Wiki · A game guide for players and developers.', 'О вики': 'About the wiki'
    };
    const originalText = new WeakMap();
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const textNodes = [];
    while (walker.nextNode()) textNodes.push(walker.currentNode);
    textNodes.forEach((node) => originalText.set(node, node.nodeValue));
    const searchInput = document.querySelector('#search-input');
    const searchForm = document.querySelector('#wiki-search');

    function applyLanguage(language) {
      textNodes.forEach((node) => {
        const source = originalText.get(node);
        const trimmed = source.trim();
        if (!trimmed) return;
        const translated = language === 'en' ? (english[trimmed] || trimmed) : trimmed;
        node.nodeValue = source.replace(trimmed, translated);
      });
      document.documentElement.lang = language;
      document.title = language === 'en' ? 'InfiniteForge Wiki' : 'InfiniteForge Wiki';
      searchInput.placeholder = language === 'en' ? 'Search InfiniteForge Wiki' : 'Поиск по InfiniteForge Wiki';
      searchInput.setAttribute('aria-label', language === 'en' ? 'Search the wiki' : 'Поиск по вики');
    }
    const { parts: routeParts, language: currentLanguage, page: routePage } = readWikiRoute();
    applyLanguage(currentLanguage);
    function updateLanguageLinks(pagePath) {
      document.querySelectorAll('[data-language-link], .language-row a[lang]').forEach((link) => {
        link.href = localizedPath(link.lang, pagePath);
        link.setAttribute('aria-current', link.lang === currentLanguage ? 'true' : 'false');
      });
    }
    updateLanguageLinks(routeParts.slice(1).join('/') || 'home');
    searchForm.addEventListener('submit', (event) => {
      event.preventDefault();
      const query = searchInput.value.trim();
      window.location.href = `/${currentLanguage}/search${query ? `?q=${encodeURIComponent(query)}` : ''}`;
    });

    const routeForSection = {
      top: 'home', main: 'guides/getting-started', about: 'about', world: 'worlds/overworld', resources: 'gathering', production: 'machines', items: 'items', mechanics: 'mechanics', creatures: 'mobs', guides: 'guides/getting-started', progress: 'technologies',
      technologies: 'technologies', systems: 'systems', 'ore-processing': 'ore-processing', steam: 'steam', energy: 'energy', logistics: 'logistics', optimization: 'optimization', multiplayer: 'multiplayer', fluids: 'fluids', quests: 'quests', achievements: 'achievements', gathering: 'gathering', interface: 'interface', exploration: 'exploration', npcs: 'npcs', recipes: 'recipes', 'crafting-balance': 'crafting-balance', mobs: 'mobs', bosses: 'bosses', machines: 'machines',
      structures: 'exploration/world-generation', plants: 'gathering/foraging', 'ore-deposits': 'gathering/ore-deposits', fuel: 'energy/generation', 'production-chains': 'optimization/production-lines', automation: 'systems/logistics', inventory: 'interface/inventory-hotbar', health: 'mechanics/health-respawn', combat: 'mechanics/combat-movement', 'first-factory': 'optimization/production-lines', 'first-power': 'energy/generation', 'map-exploration': 'exploration/map-exploration',
      forest: 'worlds/overworld/biomes/forest', desert: 'worlds/overworld/biomes/desert', snow: 'worlds/overworld/biomes/snow', swamp: 'worlds/overworld/biomes/swamp', jungle: 'worlds/overworld/biomes/jungle', 'sunny-canyon': 'worlds/overworld/biomes/sunny-canyon', 'icy-abyss': 'worlds/overworld/biomes/icy-abyss', 'rotting-bog': 'worlds/overworld/biomes/rotting-bog', 'primeval-thicket': 'worlds/overworld/biomes/primeval-thicket',
    };
    document.querySelectorAll('a[href^="#"]').forEach((link) => {
      const section = link.getAttribute('href').slice(1);
      const page = routeForSection[section];
      if (page) link.setAttribute('href', `/${currentLanguage}/${page}`);
    });
    const sectionForRoute = { about: 'about' };
    if (sectionForRoute[routePage]) {
      window.requestAnimationFrame(() => document.getElementById(sectionForRoute[routePage])?.scrollIntoView());
    }

    const overworldBiomes = {
      ru: {
        title: 'Верхний мир',
        paragraphs: [
          'Верхний мир — первый игровой мир InfiniteForge. Он построен кольцами вокруг стартовой зоны: чем дальше от центра, тем опаснее экспедиции.',
          'Весь центр занимает густой лес. Дальше мир разделяется на четыре направления с обычными биомами, а внешнее кольцо занимает их сложная версия.',
          'Здесь перечислены только биомы. В статьях самих биомов будут собраны мобы, босс, ресурсы, опасности и подготовка к походу.',
        ],
        contents: ['Устройство мира', 'Безопасные земли', 'Обычные биомы', 'Сложные биомы'],
        mapTitle: 'Устройство мира',
        mapText: 'Начните в центральном лесу и выбирайте одно из четырёх направлений. Сложные биомы находятся дальше в том же направлении.',
        infobox: { caption: 'Первый мир для исследования и развития базы.', rows: [['Тип', 'Основной мир'], ['Стартовая зона', 'Лес'], ['Биомов', '9'], ['Прогрессия', 'От центра к внешнему кольцу']] },
        groups: [
          { title: 'Безопасные земли', biomes: [
            ['forest', 'Лес', 'Густой стартовый биом с базовыми ресурсами.', 'Grass.png'],
          ] },
          { title: 'Обычные биомы', biomes: [
            ['desert', 'Пустыня', 'Западный сектор Верхнего мира.', 'Desert.png'],
            ['snow', 'Снежные земли', 'Северный сектор Верхнего мира.', 'Snow.png'],
            ['swamp', 'Болото', 'Южный сектор Верхнего мира.', 'Swamp.png'],
            ['jungle', 'Джунгли', 'Восточный сектор Верхнего мира.', 'Jungle.png'],
          ] },
          { title: 'Сложные биомы', biomes: [
            ['sunny-canyon', 'Солнечный каньон', 'Внешняя западная зона.', 'SunnyCanyon.png'],
            ['icy-abyss', 'Ледяная бездна', 'Внешняя северная зона.', 'IcyAbyss.png'],
            ['rotting-bog', 'Гниющее болото', 'Внешняя южная зона.', 'RottingBog.png'],
            ['primeval-thicket', 'Первобытные дебри', 'Внешняя восточная зона.', 'PrimevalThicket.png'],
          ] },
        ],
      },
      en: {
        title: 'Overworld',
        paragraphs: [
          'The Overworld is InfiniteForge\'s first playable world. It is arranged in rings around the starting area: expeditions become more dangerous farther from the centre.',
          'Dense forest fills the centre. Beyond it, the world divides into four directions with normal biomes, while their hard versions occupy the outer ring.',
          'This page lists biomes only. Each biome article will contain its mobs, boss, resources, hazards, and expedition preparation.',
        ],
        contents: ['World layout', 'Safe lands', 'Normal biomes', 'Hard biomes'],
        mapTitle: 'World layout',
        mapText: 'Start in the central forest, then choose one of four directions. Hard biomes lie farther out in the same direction.',
        infobox: { caption: 'The first world for exploration and base development.', rows: [['Type', 'Main world'], ['Starting area', 'Forest'], ['Biomes', '9'], ['Progression', 'Centre to outer ring']] },
        groups: [
          { title: 'Safe lands', biomes: [
            ['forest', 'Forest', 'Dense starting biome with basic resources.', 'Grass.png'],
          ] },
          { title: 'Normal biomes', biomes: [
            ['desert', 'Desert', 'The western Overworld sector.', 'Desert.png'],
            ['snow', 'Snowlands', 'The northern Overworld sector.', 'Snow.png'],
            ['swamp', 'Swamp', 'The southern Overworld sector.', 'Swamp.png'],
            ['jungle', 'Jungle', 'The eastern Overworld sector.', 'Jungle.png'],
          ] },
          { title: 'Hard biomes', biomes: [
            ['sunny-canyon', 'Sunny Canyon', 'The outer western zone.', 'SunnyCanyon.png'],
            ['icy-abyss', 'Icy Abyss', 'The outer northern zone.', 'IcyAbyss.png'],
            ['rotting-bog', 'Rotting Bog', 'The outer southern zone.', 'RottingBog.png'],
            ['primeval-thicket', 'Primeval Thicket', 'The outer eastern zone.', 'PrimevalThicket.png'],
          ] },
        ],
      },
    };

    const itemUi = {
      ru: {
        catalogTitle: 'Предметы', catalogIntro: 'Полный каталог предметов InfiniteForge. Страницы создаются автоматически из игровых ресурсов.',
        search: 'Поиск по названию или ID', shown: 'Показано', of: 'из', items: 'предметов', loading: 'Загрузка предметов…',
        contents: 'Содержание', characteristics: 'Характеристики', crafting: 'Получение', usage: 'Использование', information: 'Информация',
        noDescription: 'Описание для этого предмета пока не добавлено.', noCrafting: 'Рецепт получения пока не указан.', noUsage: 'Предмет пока не используется в рецептах.',
        type: 'Категория', rarity: 'Редкость', stack: 'Размер стака', identifier: 'ID', property: 'Параметр', value: 'Значение',
        recipe: 'Рецепт', ingredients: 'Компоненты', station: 'Станция', product: 'Продукт', requirements: 'Требования', age: 'Эпоха', fromStart: 'С начала игры', specialUnlock: 'Страница рецепта', count: 'Количество',
        toolType: 'Тип инструмента', power: 'Сила', equipSlot: 'Слот экипировки', foodValue: 'Сытость', fluidCapacity: 'Вместимость жидкости', blockId: 'ID блока', useAction: 'Действие',
        loadError: 'Не удалось загрузить данные предметов.',
      },
      en: {
        catalogTitle: 'Items', catalogIntro: 'The complete InfiniteForge item catalog. Pages are generated automatically from game resources.',
        search: 'Search by name or ID', shown: 'Showing', of: 'of', items: 'items', loading: 'Loading items…',
        contents: 'Contents', characteristics: 'Properties', crafting: 'Obtaining', usage: 'Usage', information: 'Information',
        noDescription: 'This item does not have a description yet.', noCrafting: 'No obtaining recipe is currently specified.', noUsage: 'This item is not currently used in recipes.',
        type: 'Category', rarity: 'Rarity', stack: 'Stack size', identifier: 'ID', property: 'Property', value: 'Value',
        recipe: 'Recipe', ingredients: 'Components', station: 'Station', product: 'Product', requirements: 'Requirements', age: 'Age', fromStart: 'From the start', specialUnlock: 'Recipe page', count: 'Count',
        toolType: 'Tool type', power: 'Power', equipSlot: 'Equipment slot', foodValue: 'Food value', fluidCapacity: 'Fluid capacity', blockId: 'Block ID', useAction: 'Action',
        loadError: 'Could not load item data.',
      },
    };

    const recipeUi = {
      ru: {
        catalogTitle: 'Рецепты', catalogIntro: 'Полный каталог ручного изготовления и кулинарии из игровых ресурсов. Рецепты сгруппированы по назначению и расположены в порядке прогрессии.', search: 'Поиск по результату, ID или категории', shown: 'Показано', of: 'из', recipes: 'рецептов', loading: 'Загрузка рецептов…', loadError: 'Не удалось загрузить рецепты.',
        contents: 'Содержание', formula: 'Формула изготовления', ingredients: 'Ингредиенты', result: 'Результат', unlocking: 'Как открыть рецепт', uses: 'Дальнейшее использование', information: 'Информация', category: 'Категория', station: 'Станция', age: 'Эпоха', identifier: 'ID', output: 'Выход', ingredientKinds: 'Видов ингредиентов', technology: 'Технологический этап', noTechnology: 'Дополнительный этап дерева технологий не требуется.', availableBy: 'Доступен через одно из условий', specialGate: 'Особое условие', usedInCount: 'Рецептов с этим результатом', previous: 'Предыдущий рецепт', next: 'Следующий рецепт',
      },
      en: {
        catalogTitle: 'Recipes', catalogIntro: 'The complete hand-crafting and cooking catalog generated from game resources. Recipes are grouped by purpose and ordered by progression.', search: 'Search by result, ID, or category', shown: 'Showing', of: 'of', recipes: 'recipes', loading: 'Loading recipes…', loadError: 'Could not load recipes.',
        contents: 'Contents', formula: 'Crafting formula', ingredients: 'Ingredients', result: 'Result', unlocking: 'How to unlock the recipe', uses: 'Further use', information: 'Information', category: 'Category', station: 'Station', age: 'Age', identifier: 'ID', output: 'Output', ingredientKinds: 'Ingredient types', technology: 'Technology stage', noTechnology: 'No additional technology-tree stage is required.', availableBy: 'Available through either condition', specialGate: 'Special condition', usedInCount: 'Recipes using this result', previous: 'Previous recipe', next: 'Next recipe',
      },
    };

    const craftingBalanceUi = {
      ru: {
        title: 'Баланс крафтов', intro: 'Рабочая панель экономики. Она читает игровые .tres-рецепты, разворачивает полную цепочку ручного изготовления и помогает формулировать точные правки.',
        loading: 'Расчёт цепочек крафта…', loadError: 'Не удалось рассчитать баланс крафтов.', source: 'Источник данных', liveNote: 'Файлы перечитываются при каждом обновлении страницы — отдельной копии рецептов здесь нет. Итоговыми входами считаются предметы, для которых в CraftingDatabase нет отдельного .tres-рецепта; операции станков здесь не разворачиваются.',
        recipes: 'Рецептов', rawResources: 'Видов итоговых входов', warnings: 'Предупреждений', errors: 'Критических ошибок', search: 'Название или ID', allAges: 'Все эпохи', allCategories: 'Все категории', allStatuses: 'Любой статус', onlyWarnings: 'Требуют внимания', onlyErrors: 'Только ошибки', noWarnings: 'Без предупреждений',
        sort: 'Сортировка', sortProgression: 'По прогрессии', sortCostDesc: 'Сначала дорогие', sortCostAsc: 'Сначала дешёвые', sortDepth: 'По длине цепочки', sortName: 'По названию', refresh: 'Обновить', shown: 'Показано', of: 'из',
        recipe: 'Рецепт', age: 'Эпоха', category: 'Категория', direct: 'Прямые ингредиенты', rawCost: 'Итоговые входы', depth: 'Глубина', operations: 'Операций', usage: 'Использований', status: 'Статус', ok: 'В порядке', open: 'Открыть',
        details: 'Разбор рецепта', formula: 'Прямая формула', metrics: 'Метрики цепочки', rawBreakdown: 'Итоговые входы цепочки', chain: 'Дерево изготовления', issues: 'Замечания', usedIn: 'Используется в рецептах', noUses: 'Нигде не используется.', sourceFile: 'Файл рецепта', raw: 'вход', crafts: 'крафтов',
        copyPrompt: 'Запрос для Codex', promptHint: 'Допиши, что именно нужно изменить, затем скопируй запрос.', copy: 'Скопировать запрос', copied: 'Скопировано', copyFailed: 'Выдели текст и скопируй вручную.', promptChange: 'Нужно изменить: опиши желаемые ингредиенты, количества, выход или эпоху.', promptKeep: 'После правки обнови проверки экономики и не меняй несвязанные рецепты.', noResults: 'По выбранным фильтрам рецептов нет.',
      },
      en: {
        title: 'Crafting balance', intro: 'An economy workbench. It reads live .tres recipes, expands the complete hand-crafting chain, and helps you describe precise balance changes.',
        loading: 'Calculating crafting chains…', loadError: 'Could not calculate crafting balance.', source: 'Data source', liveNote: 'Files are read again on every refresh, so this page does not maintain a separate recipe copy. A terminal input is an item without its own .tres recipe in CraftingDatabase; machine operations are not expanded here.',
        recipes: 'Recipes', rawResources: 'Terminal input types', warnings: 'Warnings', errors: 'Critical errors', search: 'Name or ID', allAges: 'All ages', allCategories: 'All categories', allStatuses: 'Any status', onlyWarnings: 'Needs attention', onlyErrors: 'Errors only', noWarnings: 'No warnings',
        sort: 'Sort', sortProgression: 'Progression order', sortCostDesc: 'Most expensive first', sortCostAsc: 'Cheapest first', sortDepth: 'Chain depth', sortName: 'Name', refresh: 'Refresh', shown: 'Showing', of: 'of',
        recipe: 'Recipe', age: 'Age', category: 'Category', direct: 'Direct ingredients', rawCost: 'Terminal inputs', depth: 'Depth', operations: 'Operations', usage: 'Uses', status: 'Status', ok: 'OK', open: 'Open',
        details: 'Recipe analysis', formula: 'Direct formula', metrics: 'Chain metrics', rawBreakdown: 'Terminal chain inputs', chain: 'Crafting tree', issues: 'Issues', usedIn: 'Used by recipes', noUses: 'Not used anywhere.', sourceFile: 'Recipe file', raw: 'input', crafts: 'crafts',
        copyPrompt: 'Prompt for Codex', promptHint: 'Describe the desired change, then copy the prompt.', copy: 'Copy prompt', copied: 'Copied', copyFailed: 'Select the text and copy it manually.', promptChange: 'Change requested: describe the desired ingredients, counts, output, or age.', promptKeep: 'After the change, update economy checks and do not modify unrelated recipes.', noResults: 'No recipes match the selected filters.',
      },
    };

    const toolTypeTitles = {
      axe: { ru: 'Топор', en: 'Axe' }, armor: { ru: 'Броня', en: 'Armor' }, hammer: { ru: 'Молот', en: 'Hammer' }, hoe: { ru: 'Мотыга', en: 'Hoe' },
      pickaxe: { ru: 'Кирка', en: 'Pickaxe' }, spear: { ru: 'Копьё', en: 'Spear' }, sword: { ru: 'Меч', en: 'Sword' }, wand: { ru: 'Посох', en: 'Wand' },
    };

    const equipSlotTitles = {
      amulet: { ru: 'Амулет', en: 'Amulet' }, back: { ru: 'Спина', en: 'Back' }, feet: { ru: 'Ступни', en: 'Feet' }, hands: { ru: 'Руки', en: 'Hands' },
      head: { ru: 'Голова', en: 'Head' }, mask: { ru: 'Маска', en: 'Mask' }, suit: { ru: 'Костюм', en: 'Suit' }, waist: { ru: 'Пояс', en: 'Waist' },
    };

    const bossUi = {
      ru: {
        catalogTitle: 'Боссы', catalogIntro: 'Боссы Верхнего мира. Каждый охраняет свой биом и обладает отдельным набором атак.', search: 'Поиск босса',
        shown: 'Показано', of: 'из', bosses: 'боссов', loading: 'Загрузка боссов…', loadError: 'Не удалось загрузить данные боссов.',
        contents: 'Содержание', characteristics: 'Характеристики', abilities: 'Способности', loot: 'Добыча', information: 'Информация',
        type: 'Тип', boss: 'Босс', biome: 'Биом', health: 'Здоровье', contactDamage: 'Контактный урон', speed: 'Скорость', phaseOne: 'Первая фаза', phaseTwo: 'Вторая фаза',
        attackType: 'Тип атаки', effect: 'Эффект', range: 'Дальность', radius: 'Радиус', multiplier: 'Множитель урона', cooldown: 'Перезарядка', summonedMob: 'Призываемый моб', count: 'Количество',
        guaranteedLoot: 'Гарантированная добыча', pageDrop: 'Страница рецепта', summoner: 'Предмет призыва', noAbility: 'Особая способность не указана.', noLoot: 'Добыча не указана.',
      },
      en: {
        catalogTitle: 'Bosses', catalogIntro: 'Bosses of the Overworld. Each guards its own biome and uses a distinct set of attacks.', search: 'Search bosses',
        shown: 'Showing', of: 'of', bosses: 'bosses', loading: 'Loading bosses…', loadError: 'Could not load boss data.',
        contents: 'Contents', characteristics: 'Characteristics', abilities: 'Abilities', loot: 'Loot', information: 'Information',
        type: 'Type', boss: 'Boss', biome: 'Biome', health: 'Health', contactDamage: 'Contact damage', speed: 'Speed', phaseOne: 'Phase one', phaseTwo: 'Phase two',
        attackType: 'Attack type', effect: 'Effect', range: 'Range', radius: 'Radius', multiplier: 'Damage multiplier', cooldown: 'Cooldown', summonedMob: 'Summoned mob', count: 'Count',
        guaranteedLoot: 'Guaranteed loot', pageDrop: 'Recipe page', summoner: 'Summoning item', noAbility: 'No special ability is specified.', noLoot: 'No loot is specified.',
      },
    };

    const mobUi = {
      ru: {
        catalogTitle: 'Мобы', catalogIntro: 'Обычные противники Верхнего мира, сгруппированные по биомам. В каждой статье указаны характеристики и гарантированная добыча.', search: 'Поиск моба',
        shown: 'Показано', of: 'из', mobs: 'мобов', loading: 'Загрузка мобов…', loadError: 'Не удалось загрузить данные мобов.',
        contents: 'Содержание', characteristics: 'Характеристики', behavior: 'Поведение', loot: 'Выпадение', information: 'Информация',
        type: 'Тип', mob: 'Моб', role: 'Роль', biome: 'Биом', health: 'Здоровье', damage: 'Урон', speed: 'Скорость', item: 'Предмет', count: 'Количество', guaranteed: 'Гарантированно',
        roleBehavior: {
          rusher: 'Штурмовик быстро сокращает дистанцию и старается постоянно держаться рядом с игроком.',
          brute: 'Тяжёлый боец медленнее других противников, но обладает большим запасом здоровья и наносит сильные удары.',
          skirmisher: 'Застрельщик полагается на подвижность и старается выбирать удобную дистанцию для атаки.',
        },
      },
      en: {
        catalogTitle: 'Mobs', catalogIntro: 'Common Overworld enemies grouped by biome. Every article lists combat stats and guaranteed drops.', search: 'Search mobs',
        shown: 'Showing', of: 'of', mobs: 'mobs', loading: 'Loading mobs…', loadError: 'Could not load mob data.',
        contents: 'Contents', characteristics: 'Characteristics', behavior: 'Behavior', loot: 'Drops', information: 'Information',
        type: 'Type', mob: 'Mob', role: 'Role', biome: 'Biome', health: 'Health', damage: 'Damage', speed: 'Speed', item: 'Item', count: 'Count', guaranteed: 'Guaranteed',
        roleBehavior: {
          rusher: 'A rusher closes the distance quickly and tries to remain close to the player.',
          brute: 'A brute moves more slowly than other enemies, but has more health and deals heavy damage.',
          skirmisher: 'A skirmisher relies on mobility and tries to maintain a favorable attack distance.',
        },
      },
    };

    const machineUi = {
      ru: {
        catalogTitle: 'Техника', catalogIntro: 'Машины, генераторы, конвейеры и хранилища InfiniteForge. Статьи формируются из игровых определений блоков и рецептов.', search: 'Поиск техники',
        shown: 'Показано', of: 'из', machinesCount: 'устройств', loading: 'Загрузка техники…', loadError: 'Не удалось загрузить данные техники.',
        contents: 'Содержание', characteristics: 'Характеристики', technical: 'Технические данные', crafting: 'Создание', fluidProcesses: 'Жидкостные процессы', information: 'Информация',
        category: 'Категория', health: 'Прочность', requiredTool: 'Инструмент', size: 'Размер', rotatable: 'Можно вращать', interactive: 'Интерактивный блок', interface: 'Интерфейс', item: 'Предмет', identifier: 'ID', yes: 'Да', no: 'Нет', property: 'Параметр', value: 'Значение', noTechnical: 'Дополнительные технические параметры не указаны.',
        categories: { machines: 'Машины', generators: 'Генераторы', conveyors: 'Конвейеры', storage: 'Хранилища' },
        metrics: { beltTier: 'Уровень конвейера', crossTime: 'Время прохождения клетки', beltFps: 'Скорость анимации', energyUse: 'Потребление энергии', slotCount: 'Ячеек хранения', energyCapacity: 'Ёмкость энергии', maxIo: 'Максимальный ввод/вывод', fluidCapacity: 'Вместимость жидкости', energyOutput: 'Выработка энергии', energyBuffer: 'Внутренний буфер', processTime: 'Время цикла', outputItem: 'Результат' },
        units: { crossTime: 'с', beltFps: 'кадр/с', energyUse: 'EU/с', energyCapacity: 'EU', maxIo: 'EU/с', fluidCapacity: 'л', energyOutput: 'EU/с', energyBuffer: 'EU', processTime: 'с' },
      },
      en: {
        catalogTitle: 'Machines', catalogIntro: 'InfiniteForge machines, generators, conveyors, and storage. Articles are generated from game block definitions and recipes.', search: 'Search machines',
        shown: 'Showing', of: 'of', machinesCount: 'devices', loading: 'Loading machines…', loadError: 'Could not load machine data.',
        contents: 'Contents', characteristics: 'Characteristics', technical: 'Technical data', crafting: 'Crafting', fluidProcesses: 'Fluid processes', information: 'Information',
        category: 'Category', health: 'Durability', requiredTool: 'Required tool', size: 'Size', rotatable: 'Rotatable', interactive: 'Interactive block', interface: 'Interface', item: 'Item', identifier: 'ID', yes: 'Yes', no: 'No', property: 'Property', value: 'Value', noTechnical: 'No additional technical properties are specified.',
        categories: { machines: 'Machines', generators: 'Generators', conveyors: 'Conveyors', storage: 'Storage' },
        metrics: { beltTier: 'Conveyor tier', crossTime: 'Tile crossing time', beltFps: 'Animation speed', energyUse: 'Energy use', slotCount: 'Storage slots', energyCapacity: 'Energy capacity', maxIo: 'Maximum input/output', fluidCapacity: 'Fluid capacity', energyOutput: 'Energy output', energyBuffer: 'Internal buffer', processTime: 'Process time', outputItem: 'Output' },
        units: { crossTime: 's', beltFps: 'fps', energyUse: 'EU/s', energyCapacity: 'EU', maxIo: 'EU/s', fluidCapacity: 'L', energyOutput: 'EU/s', energyBuffer: 'EU', processTime: 's' },
      },
    };

    const biomeUi = {
      ru: {
        loading: 'Загрузка биома…', loadError: 'Не удалось загрузить данные биома.', contents: 'Содержание',
        overview: 'Обзор', progression: 'Доступ и опасность', resources: 'Ресурсы', inhabitants: 'Обитатели', npc: 'Персонаж', boss: 'Босс', preparation: 'Подготовка к экспедиции', information: 'Информация',
        tier: 'Уровень', direction: 'Расположение', hazard: 'Опасность', safe: 'Нет', exposure: 'Скорость воздействия', exposureTime: 'До полного воздействия', protection: 'Защита', unlock: 'Условие открытия', available: 'Доступно с начала игры', defeat: 'Победить',
        pointsPerSecond: 'ед./с', seconds: 'с', ore: 'Рудное месторождение', forage: 'Природный ресурс', inherited: 'Набор ресурсов наследуется от биома',
        noResources: 'Отдельные ресурсы для этого биома пока не указаны.', noMobs: 'Обычные враждебные мобы в этом биоме не появляются.', noBoss: 'Отдельный босс в этом биоме не предусмотрен.',
        health: 'здоровья', damage: 'урона', previous: 'Предыдущий биом', next: 'Следующий биом', worldLabel: 'Мир', world: 'Верхний мир',
      },
      en: {
        loading: 'Loading biome…', loadError: 'Could not load biome data.', contents: 'Contents',
        overview: 'Overview', progression: 'Access and hazard', resources: 'Resources', inhabitants: 'Inhabitants', npc: 'Character', boss: 'Boss', preparation: 'Expedition preparation', information: 'Information',
        tier: 'Tier', direction: 'Location', hazard: 'Hazard', safe: 'None', exposure: 'Exposure rate', exposureTime: 'Time to full exposure', protection: 'Protection', unlock: 'Unlock requirement', available: 'Available from the start', defeat: 'Defeat',
        pointsPerSecond: 'points/s', seconds: 's', ore: 'Ore deposit', forage: 'Natural resource', inherited: 'Resource set inherited from',
        noResources: 'No distinct resources are currently specified for this biome.', noMobs: 'No common hostile mobs spawn in this biome.', noBoss: 'This biome does not have a dedicated boss.',
        health: 'health', damage: 'damage', previous: 'Previous biome', next: 'Next biome', worldLabel: 'World', world: 'Overworld',
      },
    };

    const technologyUi = {
      ru: {
        catalogTitle: 'Технологическое развитие', catalogIntro: 'Одиннадцать технологических этапов связывают фабрику, исследование биомов и цепочку боссов. Это отдельная система от шести эпох квестовой книги.',
        stages: 'этапов', loading: 'Загрузка технологий…', loadError: 'Не удалось загрузить дерево технологий.', contents: 'Содержание', overview: 'Обзор', requirements: 'Условия открытия', outputs: 'Открываемые технологии', balance: 'Оценка этапа', information: 'Информация',
        biome: 'Требуемый биом', boss: 'Требуемый босс', research: 'Исследовательские материалы', available: 'Доступно с начала игры', machines: 'Машины и устройства', components: 'Компоненты', nextBiome: 'Открывает путь в биом',
        unlocks: 'открытий', targets: 'Ключевых целей', rawUnits: 'Сырьевых единиц', machineTime: 'Работа машин', estimatedTime: 'Ориентировочное время', noBalance: 'Для этого этапа пока нет расчёта баланса.', stage: 'Технологический этап',
      },
      en: {
        catalogTitle: 'Technology progression', catalogIntro: 'Eleven technology stages connect the factory, biome exploration, and boss chain. This is separate from the quest book\'s six ages.',
        stages: 'stages', loading: 'Loading technologies…', loadError: 'Could not load the technology tree.', contents: 'Contents', overview: 'Overview', requirements: 'Unlock requirements', outputs: 'Unlocked technology', balance: 'Stage estimate', information: 'Information',
        biome: 'Required biome', boss: 'Required boss', research: 'Research materials', available: 'Available from the start', machines: 'Machines and devices', components: 'Components', nextBiome: 'Opens the route to',
        unlocks: 'unlocks', targets: 'Core targets', rawUnits: 'Raw units', machineTime: 'Machine time', estimatedTime: 'Estimated time', noBalance: 'No balance estimate is currently available for this stage.', stage: 'Technology stage',
      },
    };

    const systemUi = {
      ru: {
        catalogTitle: 'Производственные системы', catalogIntro: 'Практические руководства по связям между машинами: от первой паровой линии до цифрового хранения ME.', loading: 'Загрузка систем…', loadError: 'Не удалось загрузить руководство.',
        guides: 'руководства', steps: 'этапа настройки', equipment: 'Компоненты системы', tips: 'Важные особенности', facts: 'Ключевые параметры', contents: 'Содержание', setup: 'Порядок настройки', information: 'Информация', type: 'Тип', guide: 'Системное руководство', related: 'Связанных компонентов', previous: 'Предыдущая система', next: 'Следующая система',
      },
      en: {
        catalogTitle: 'Factory systems', catalogIntro: 'Practical guides to the connections between machines, from the first steam line to ME digital storage.', loading: 'Loading systems…', loadError: 'Could not load the guide.',
        guides: 'guides', steps: 'setup steps', equipment: 'System components', tips: 'Important behavior', facts: 'Key parameters', contents: 'Contents', setup: 'Setup sequence', information: 'Information', type: 'Type', guide: 'System guide', related: 'Related components', previous: 'Previous system', next: 'Next system',
      },
    };

    const fluidUi = {
      ru: {
        catalogTitle: 'Жидкости и газы', catalogIntro: 'Двадцать две технологические среды InfiniteForge: вода и пар, нефтяные фракции, топливо и расплавы металлов. Данные рецептов загружаются непосредственно из игровых машин.',
        loading: 'Загрузка жидкостей…', loadError: 'Не удалось загрузить данные жидкостей.', search: 'Поиск по названию, категории или ID', shown: 'Показано', of: 'из', fluids: 'жидкостей', contents: 'Содержание', overview: 'Обзор', production: 'Получение', usage: 'Использование', information: 'Информация', category: 'Категория', sources: 'Способов получения', uses: 'Производственных применений', noSources: 'Отдельный способ получения пока не указан.', noUses: 'Производственное применение пока не указано.', machine: 'Машина', time: 'Время', power: 'Энергия', catalyst: 'катализатор', previous: 'Предыдущая жидкость', next: 'Следующая жидкость', perSecond: 'за 1 секунду',
      },
      en: {
        catalogTitle: 'Fluids and gases', catalogIntro: 'Twenty-two process media in InfiniteForge: water and steam, petroleum fractions, fuels, and molten metals. Recipe data is loaded directly from game machines.',
        loading: 'Loading fluids…', loadError: 'Could not load fluid data.', search: 'Search by name, category, or ID', shown: 'Showing', of: 'of', fluids: 'fluids', contents: 'Contents', overview: 'Overview', production: 'Production', usage: 'Usage', information: 'Information', category: 'Category', sources: 'Production methods', uses: 'Production uses', noSources: 'No separate production method is currently listed.', noUses: 'No production use is currently listed.', machine: 'Machine', time: 'Time', power: 'Power', catalyst: 'catalyst', previous: 'Previous fluid', next: 'Next fluid', perSecond: 'per second',
      },
    };

    const questUi = {
      ru: {
        catalogTitle: 'Квестовая книга', catalogIntro: 'Шесть эпох последовательно знакомят с добычей, производством, энергетикой, автоматизацией и поздними технологиями.',
        loading: 'Загрузка квестов…', loadError: 'Не удалось загрузить квестовую книгу.', quests: 'квестов', chapters: 'глав', tutorials: 'обучающих задач',
        search: 'Поиск по названию, описанию или ID', shown: 'Показано', of: 'из', objectives: 'Цели', unlocks: 'Открывает', prerequisites: 'Предыдущие задачи', tutorial: 'Обучение', information: 'Информация', age: 'Эпоха', chapterCount: 'Глав', questCount: 'Задач', optional: 'Необязательная задача', previous: 'Предыдущая эпоха', next: 'Следующая эпоха',
      },
      en: {
        catalogTitle: 'Quest book', catalogIntro: 'Six ages introduce gathering, production, power, automation, and late-game technology in sequence.',
        loading: 'Loading quests…', loadError: 'Could not load the quest book.', quests: 'quests', chapters: 'chapters', tutorials: 'tutorial tasks',
        search: 'Search by title, description, or ID', shown: 'Showing', of: 'of', objectives: 'Objectives', unlocks: 'Unlocks', prerequisites: 'Previous tasks', tutorial: 'Tutorial', information: 'Information', age: 'Age', chapterCount: 'Chapters', questCount: 'Tasks', optional: 'Optional task', previous: 'Previous age', next: 'Next age',
      },
    };

    const npcUi = {
      ru: {
        catalogTitle: 'Персонажи', catalogIntro: 'В биомах Верхнего мира живут специалисты, а центральный лес принимает сразу двух стартовых персонажей. У каждого есть цепочка из трёх побочных заданий с ресурсами, производственными целями и наградами.',
        loading: 'Загрузка персонажей…', loadError: 'Не удалось загрузить данные персонажей.', search: 'Поиск по имени, роли, биому или ID', shown: 'Показано', of: 'из', characters: 'персонажей', quests: 'заданий',
        contents: 'Содержание', overview: 'О персонаже', location: 'Местонахождение', questChain: 'Цепочка заданий', greeting: 'Приветствие', role: 'Роль', biome: 'Биом', objectives: 'Цели', rewards: 'Награды', unlocks: 'Открывает', information: 'Информация', sideQuests: 'Побочные задания', noUnlocks: 'Дополнительных открытий нет.', previous: 'Предыдущий персонаж', next: 'Следующий персонаж',
      },
      en: {
        catalogTitle: 'Characters', catalogIntro: 'Specialists live across the Overworld biomes, with two starting characters in the central forest. Every character offers a three-part side-quest chain with resource, production, and reward objectives.',
        loading: 'Loading characters…', loadError: 'Could not load character data.', search: 'Search by name, role, biome, or ID', shown: 'Showing', of: 'of', characters: 'characters', quests: 'quests',
        contents: 'Contents', overview: 'Character overview', location: 'Location', questChain: 'Quest chain', greeting: 'Greeting', role: 'Role', biome: 'Biome', objectives: 'Objectives', rewards: 'Rewards', unlocks: 'Unlocks', information: 'Information', sideQuests: 'Side quests', noUnlocks: 'No additional unlocks.', previous: 'Previous character', next: 'Next character',
      },
    };

    const achievementUi = {
      ru: {
        catalogTitle: 'Достижения', catalogIntro: 'Двадцать две контрольные цели отмечают прохождение квестов и эпох, победы над боссами и рост фабрики. Каталог строится напрямую из игрового реестра достижений.',
        loading: 'Загрузка достижений…', loadError: 'Не удалось загрузить достижения.', search: 'Поиск по названию, описанию, условию или ID', shown: 'Показано', of: 'из', achievements: 'достижений',
        contents: 'Содержание', overview: 'Описание', requirement: 'Точное условие открытия', related: 'Связанные статьи', tracking: 'Как отслеживается', information: 'Информация', category: 'Категория', emblem: 'Эмблема', identifier: 'ID', previous: 'Предыдущее достижение', next: 'Следующее достижение', profileStorage: 'Хранение прогресса', automaticCheck: 'Автоматическая проверка',
      },
      en: {
        catalogTitle: 'Achievements', catalogIntro: 'Twenty-two milestones track quest and age completion, boss victories, and factory growth. The catalog is generated directly from the in-game achievement registry.',
        loading: 'Loading achievements…', loadError: 'Could not load achievements.', search: 'Search by title, description, requirement, or ID', shown: 'Showing', of: 'of', achievements: 'achievements',
        contents: 'Contents', overview: 'Overview', requirement: 'Exact unlock condition', related: 'Related articles', tracking: 'How it is tracked', information: 'Information', category: 'Category', emblem: 'Emblem', identifier: 'ID', previous: 'Previous achievement', next: 'Next achievement', profileStorage: 'Progress storage', automaticCheck: 'Automatic check',
      },
    };

    const mechanicUi = {
      ru: {
        catalogTitle: 'Игровые механики', catalogIntro: 'Практический справочник по системам самого персонажа. Числа, формулы, предметы и пороги загружаются из текущих игровых данных.', loading: 'Загрузка механик…', loadError: 'Не удалось загрузить игровые механики.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные предметы', information: 'Информация', type: 'Тип', guide: 'Игровая механика', sections: 'Разделов', links: 'Связанных предметов', previous: 'Предыдущая механика', next: 'Следующая механика',
      },
      en: {
        catalogTitle: 'Gameplay mechanics', catalogIntro: 'A practical reference for the systems governing the player character. Values, formulas, items, and thresholds come from the current game data.', loading: 'Loading mechanics…', loadError: 'Could not load gameplay mechanics.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related items', information: 'Information', type: 'Type', guide: 'Gameplay mechanic', sections: 'Sections', links: 'Related items', previous: 'Previous mechanic', next: 'Next mechanic',
      },
    };

    const gatheringUi = {
      ru: {
        catalogTitle: 'Добыча ресурсов', catalogIntro: 'Практический справочник по получению сырья: от первого удара киркой и дикорастущих ресурсов до автоматических буров, урожая и жидкостных залежей. Все параметры загружаются из текущих игровых данных.', loading: 'Загрузка руководств по добыче…', loadError: 'Не удалось загрузить раздел добычи ресурсов.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Добыча ресурсов', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Resource gathering', catalogIntro: 'A practical guide to acquiring raw materials, from the first pickaxe swing and wild resources to automated drills, crops, and fluid deposits. Every value comes from the current game data.', loading: 'Loading gathering guides…', loadError: 'Could not load the resource-gathering section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Resource gathering', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const interfaceUi = {
      ru: {
        catalogTitle: 'Управление и интерфейс', catalogIntro: 'Практический справочник по управлению персонажем, инвентарю, строительству, игровым книгам, сохранениям и совместной игре. Клавиши и числовые параметры загружаются из текущих настроек проекта.', loading: 'Загрузка руководств по интерфейсу…', loadError: 'Не удалось загрузить раздел управления и интерфейса.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Управление и интерфейс', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Controls and interface', catalogIntro: 'A practical reference for character controls, inventory, building, in-game books, saves, and multiplayer. Keys and numeric values come from the current project settings.', loading: 'Loading interface guides…', loadError: 'Could not load the controls and interface section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Controls and interface', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const explorationUi = {
      ru: {
        catalogTitle: 'Исследование мира', catalogIntro: 'Справочник путешественника по суточному циклу, погоде, карте, обелискам, устройству Верхнего мира и предметам на земле. Числовые параметры загружаются из текущих игровых систем.', loading: 'Загрузка статей об исследовании…', loadError: 'Не удалось загрузить раздел исследования мира.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Исследование мира', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'World exploration', catalogIntro: 'A traveller’s guide to the day cycle, weather, map, obelisks, Overworld structure, and dropped items. Numeric values come from the current game systems.', loading: 'Loading exploration guides…', loadError: 'Could not load the world-exploration section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'World exploration', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const optimizationUi = {
      ru: {
        catalogTitle: 'Оптимизация фабрики', catalogIntro: 'Продвинутый справочник по настройке машин, поддержанию запасов, координации сборщиков, диагностике производительности и поиску узких мест. Все числа берутся из текущей логики фабрики.', loading: 'Загрузка статей об оптимизации…', loadError: 'Не удалось загрузить раздел оптимизации фабрики.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Оптимизация фабрики', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Factory optimization', catalogIntro: 'An advanced guide to machine tuning, stock maintenance, assembler coordination, performance diagnostics, and bottleneck detection. Every value comes from current factory logic.', loading: 'Loading optimization guides…', loadError: 'Could not load the factory-optimization section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Factory optimization', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const multiplayerUi = {
      ru: {
        catalogTitle: 'Совместная игра', catalogIntro: 'Практический справочник по созданию сессий, миру хоста, общему строительству, сетевым предметам и машинам, чату и командным меткам. Параметры загружаются из текущего сетевого кода.', loading: 'Загрузка статей о совместной игре…', loadError: 'Не удалось загрузить раздел совместной игры.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Совместная игра', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Multiplayer', catalogIntro: 'A practical guide to hosting, the host world, shared building, networked items and machines, chat, and team markers. Values come from the current networking code.', loading: 'Loading multiplayer guides…', loadError: 'Could not load the multiplayer section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Multiplayer', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const energyUi = {
      ru: {
        catalogTitle: 'Энергетика', catalogIntro: 'Подробный справочник по производству и распределению EU, накопителям, солнечным панелям и диагностике сети. Числа загружаются из текущих энергетических систем игры.', loading: 'Загрузка статей об энергетике…', loadError: 'Не удалось загрузить раздел энергетики.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Энергетика', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Energy', catalogIntro: 'A detailed guide to EU generation and distribution, storage, solar panels, and grid diagnostics. Values come from the current game power systems.', loading: 'Loading energy guides…', loadError: 'Could not load the energy section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Energy', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const logisticsUi = {
      ru: {
        catalogTitle: 'Предметная логистика', catalogIntro: 'Подробный справочник по конвейерам, манипуляторам, фильтрам, складским запросам и диагностике маршрутов. Параметры загружаются из текущей логики автоматизации.', loading: 'Загрузка статей о логистике…', loadError: 'Не удалось загрузить раздел предметной логистики.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Предметная логистика', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Item logistics', catalogIntro: 'A detailed guide to conveyors, inserters, filters, warehouse demand, and route diagnostics. Values come from the current automation logic.', loading: 'Loading logistics guides…', loadError: 'Could not load the item-logistics section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Item logistics', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const steamUi = {
      ru: {
        catalogTitle: 'Паровые технологии', catalogIntro: 'Подробный справочник по водоснабжению, котлам, топливу, трубам, паровым машинам и диагностике. Числа загружаются из текущих игровых систем.', loading: 'Загрузка статей о паре…', loadError: 'Не удалось загрузить раздел паровых технологий.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Паровые технологии', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Steam technology', catalogIntro: 'A detailed guide to water supply, boilers, fuel, pipes, steam machines, and diagnostics. Values come from the current game systems.', loading: 'Loading steam guides…', loadError: 'Could not load the steam-technology section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Steam technology', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const oreProcessingUi = {
      ru: {
        catalogTitle: 'Переработка руды', catalogIntro: 'Справочник по дроблению, промывке, магнитной сепарации, центрифуге, плавке и расплавам. Параметры загружаются из текущих машин игры.', loading: 'Загрузка статей о переработке…', loadError: 'Не удалось загрузить раздел переработки руды.', guides: 'статей',
        contents: 'Содержание', keyValues: 'Ключевые параметры', related: 'Связанные статьи и предметы', information: 'Информация', type: 'Тип', guide: 'Переработка руды', sections: 'Разделов', links: 'Связанных материалов', previous: 'Предыдущая статья', next: 'Следующая статья',
      },
      en: {
        catalogTitle: 'Ore processing', catalogIntro: 'A guide to crushing, washing, magnetic separation, centrifuging, smelting, and molten metals. Values come from the current game machines.', loading: 'Loading ore-processing guides…', loadError: 'Could not load the ore-processing section.', guides: 'articles',
        contents: 'Contents', keyValues: 'Key values', related: 'Related articles and items', information: 'Information', type: 'Type', guide: 'Ore processing', sections: 'Sections', links: 'Related resources', previous: 'Previous article', next: 'Next article',
      },
    };

    const searchUi = {
      ru: {
        title: 'Поиск по вики', intro: 'Единый поиск по предметам, рецептам, технике, жидкостям, существам, биомам, технологиям, производственным системам, энергетике, предметной логистике, оптимизации фабрики, совместной игре, достижениям, игровым механикам, добыче ресурсов, интерфейсу, исследованию мира, персонажам, квестам и руководствам.', input: 'Введите название, ID или часть описания', button: 'Найти', loading: 'Поиск…', loadError: 'Не удалось выполнить поиск.', prompt: 'Введите запрос, чтобы найти материалы InfiniteForge Wiki.', noResults: 'По вашему запросу ничего не найдено.', found: 'Найдено', results: 'результатов', showing: 'Показаны первые',
        types: { item: 'Предметы', recipe: 'Рецепты', machine: 'Техника', mob: 'Мобы', boss: 'Боссы', biome: 'Биомы', technology: 'Технологии', system: 'Производственные системы', 'ore-processing': 'Переработка руды', steam: 'Паровые технологии', energy: 'Энергетика', logistics: 'Предметная логистика', optimization: 'Оптимизация фабрики', multiplayer: 'Совместная игра', fluid: 'Жидкости и газы', achievement: 'Достижения', mechanic: 'Игровые механики', gathering: 'Добыча ресурсов', interface: 'Управление и интерфейс', exploration: 'Исследование мира', quest: 'Квесты', npc: 'Персонажи и их задания', guide: 'Руководства' },
      },
      en: {
        title: 'Search the wiki', intro: 'One search across items, recipes, machines, fluids, creatures, biomes, technology, factory systems, energy, item logistics, factory optimization, multiplayer, achievements, gameplay mechanics, resource gathering, interface, world exploration, characters, quests, and guides.', input: 'Enter a name, ID, or part of a description', button: 'Search', loading: 'Searching…', loadError: 'Could not complete the search.', prompt: 'Enter a query to find InfiniteForge Wiki content.', noResults: 'No results match your query.', found: 'Found', results: 'results', showing: 'Showing the first',
        types: { item: 'Items', recipe: 'Recipes', machine: 'Machines', mob: 'Mobs', boss: 'Bosses', biome: 'Biomes', technology: 'Technologies', system: 'Factory systems', 'ore-processing': 'Ore processing', steam: 'Steam technology', energy: 'Energy', logistics: 'Item logistics', optimization: 'Factory optimization', multiplayer: 'Multiplayer', fluid: 'Fluids and gases', achievement: 'Achievements', mechanic: 'Gameplay mechanics', gathering: 'Resource gathering', interface: 'Controls and interface', exploration: 'World exploration', quest: 'Quests', npc: 'Characters and their quests', guide: 'Guides' },
      },
    };

    const gettingStartedContent = {
      ru: {
        title: 'Начало игры', intro: 'Первые часы InfiniteForge посвящены созданию устойчивой базы: от ручного сбора и плавки до паровой линии, электричества и экспедиций за пределы безопасного кольца.',
        contents: 'Содержание', firstSteps: 'Первые шаги', factory: 'Первая фабрика', exploration: 'Исследование мира', progression: 'Квесты и технологии', checklist: 'Короткий маршрут', information: 'Информация', type: 'Тип', guide: 'Руководство', audience: 'Для кого', newPlayers: 'Новые игроки', startBiome: 'Начальный биом', forest: 'Лес',
        steps: [
          ['Соберите базовые ресурсы', 'В лесу соберите дерево, камень, палки и еду. Не уходите далеко, пока не освободите место для материалов и не освоите управление инвентарём.'],
          ['Изготовьте первые инструменты', 'Сделайте верстак, примитивный топор и каменную кирку. Кодекс и квестовая книга подскажут следующие рецепты и будут открывать новые цепочки.'],
          ['Освойте руду и плавку', 'Добудьте уголь, медь, олово и железо. Первая печь превращает руду в слитки, а бронза открывает более надёжные инструменты.'],
          ['Запустите механизацию', 'Поставьте сундук и примитивную дробилку, затем переходите к воде, котлу, паровым машинам и конвейерам. Старайтесь строить линии с запасом места.'],
          ['Подготовьтесь к лесу и Энту', 'Лес — первая боевая зона. Возьмите оружие и еду; победа над Энтом даёт страницу рецепта Песчаного амулета и начинает цепочку опасных биомов.'],
          ['Следуйте двум шкалам развития', 'Шесть эпох квестовой книги обучают системам игры, а одиннадцать этапов дерева технологий открывают промышленное оборудование и связаны с биомами и боссами.'],
        ],
      },
      en: {
        title: 'Getting started', intro: 'The opening hours of InfiniteForge focus on building a sustainable base: from hand gathering and smelting to steam lines, electricity, and expeditions beyond the safe ring.',
        contents: 'Contents', firstSteps: 'First steps', factory: 'Your first factory', exploration: 'World exploration', progression: 'Quests and technology', checklist: 'Short route', information: 'Information', type: 'Type', guide: 'Guide', audience: 'Audience', newPlayers: 'New players', startBiome: 'Starting biome', forest: 'Forest',
        steps: [
          ['Gather basic resources', 'Collect wood, stone, sticks, and food in the forest. Stay nearby until you have inventory space and understand the inventory controls.'],
          ['Craft your first tools', 'Make a workbench, primitive axe, and stone pickaxe. The Codex and quest book reveal the next recipes and progression chains.'],
          ['Learn ore and smelting', 'Mine coal, copper, tin, and iron. Your first furnace turns ore into ingots, while bronze unlocks more reliable tools.'],
          ['Begin mechanization', 'Place a chest and primitive crusher, then move into water, boilers, steam machines, and conveyors. Leave room around production lines for expansion.'],
          ['Prepare for the forest and Ent', 'The forest is the first combat zone. Bring a weapon and food; defeating the Ent awards the Sand Amulet recipe page and begins the hazardous biome chain.'],
          ['Follow both progression tracks', 'Six quest-book ages teach the game systems, while eleven technology-tree stages unlock industrial equipment and connect to biomes and bosses.'],
        ],
      },
    };

    const specialTypeTitles = {
      dash: { ru: 'Рывок', en: 'Dash' }, self_aoe: { ru: 'Атака по области вокруг босса', en: 'Area attack around the boss' },
      summon: { ru: 'Призыв существ', en: 'Summoning' }, target_aoe: { ru: 'Атака по выбранной области', en: 'Targeted area attack' },
    };

    function itemUrl(itemId, language) {
      return `/${language}/items/${encodeURIComponent(itemId)}`;
    }

    function itemIcon(item, size) {
      const texture = item.texture ?? {};
      const color = item.color ?? [0.35, 0.55, 0.68, 1];
      const backgroundColor = `rgba(${Math.round(color[0] * 255)}, ${Math.round(color[1] * 255)}, ${Math.round(color[2] * 255)}, ${color[3] ?? 1})`;
      if (texture.path && texture.atlas && texture.dimensions) {
        const geometry = pixelPerfectGeometry(texture.atlas.width, texture.atlas.height, size);
        const spriteStyle = [
          `width:${geometry.width}px`, `height:${geometry.height}px`,
          `background-image:url('${escapeHtml(texture.path)}')`,
          `background-size:${texture.dimensions.width * geometry.scale}px ${texture.dimensions.height * geometry.scale}px`,
          `background-position:${-texture.atlas.x * geometry.scale}px ${-texture.atlas.y * geometry.scale}px`,
        ].join(';');
        return `<span class="item-icon" style="width:${size}px;height:${size}px;background-color:${backgroundColor}" aria-hidden="true"><span class="item-icon__sprite" style="${spriteStyle}"></span></span>`;
      }
      if (texture.path) {
        if (texture.dimensions) {
          const geometry = pixelPerfectGeometry(texture.dimensions.width, texture.dimensions.height, size);
          return `<span class="item-icon" style="width:${size}px;height:${size}px;background-color:${backgroundColor}" aria-hidden="true"><img src="${escapeHtml(texture.path)}" style="width:${geometry.width}px;height:${geometry.height}px;object-fit:fill;margin:0" alt=""></span>`;
        }
        return `<span class="item-icon" style="width:${size}px;height:${size}px;background-color:${backgroundColor}" aria-hidden="true"><img src="${escapeHtml(texture.path)}" style="width:100%;height:100%;object-fit:contain" alt=""></span>`;
      }
      return `<span class="item-icon item-icon__fallback" style="width:${size}px;height:${size}px;background-color:${backgroundColor}" aria-hidden="true">${escapeHtml(item.title.slice(0, 1))}</span>`;
    }

    function recipeItemLink(item, language) {
      const title = escapeHtml(item.title);
      return item.exists === false ? title : `<a href="${itemUrl(item.id, language)}">${title}</a>`;
    }

    function recipeTable(recipes, language, mode) {
      const labels = itemUi[language];
      if (!recipes.length) return `<p class="empty-section">${mode === 'crafting' ? labels.noCrafting : labels.noUsage}</p>`;
      const partMarkup = (item, count, size = 40) => `<span class="recipe-part">${item.exists === false ? itemIcon(item, size) : `<a href="${escapeHtml(item.url)}">${itemIcon(item, size)}</a>`}<span class="recipe-part__count">× ${count}</span><span>${recipeItemLink(item, language)}</span></span>`;
      return `<div class="item-recipe-table-wrap"><table class="item-recipe-table"><thead><tr><th>${labels.recipe}</th><th>${labels.ingredients}</th><th>${labels.station}</th><th>${labels.product}</th><th>${labels.requirements}</th></tr></thead><tbody>${recipes.map((recipe) => {
        const ingredients = recipe.ingredients.length ? `<div class="recipe-parts">${recipe.ingredients.map((ingredient) => partMarkup(ingredient, ingredient.count)).join('')}</div>` : '—';
        const stationIcon = itemIcon(recipe.station, 44);
        const station = `<div class="recipe-station"><a href="${escapeHtml(recipe.station.url)}">${stationIcon}</a><a href="${escapeHtml(recipe.station.url)}">${escapeHtml(recipe.station.title)}</a></div>`;
        const result = `<div class="recipe-parts">${partMarkup(recipe.result, recipe.resultCount, 46)}</div>`;
        const unlocks = recipe.unlocks?.length
          ? recipe.unlocks.map((unlock) => `<a href="${escapeHtml(unlock.url)}">${escapeHtml(unlock.title)}</a>`).join('')
          : `<span>${recipe.requiredAge > 0 ? `${labels.age} ${recipe.requiredAge}` : labels.fromStart}</span>`;
        return `<tr><td><a class="recipe-title" href="${recipeUrl(recipe.id, language)}">${escapeHtml(recipe.result.title)}</a><small class="recipe-subtitle">${escapeHtml(recipe.categoryTitle)}</small></td><td>${ingredients}</td><td>${station}</td><td>${result}</td><td><div class="recipe-requirements">${unlocks}</div></td></tr>`;
      }).join('')}</tbody></table></div>`;
    }

    async function renderItemCatalog(language) {
      const labels = itemUi[language];
      const article = document.querySelector('#item-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/items`);
        const groups = new Map();
        data.items.forEach((item) => {
          if (!groups.has(item.category)) groups.set(item.category, { title: item.categoryTitle, items: [] });
          groups.get(item.category).items.push(item);
        });
        const categoryOrder = ['resources', 'materials', 'components', 'tools', 'weapons', 'equipment', 'machines', 'fluids', 'food', 'knowledge'];
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="catalog-toolbar"><input id="item-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="catalog-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.items}</span></div>
          <div>${categoryOrder.filter((category) => groups.has(category)).map((category) => {
            const group = groups.get(category);
            return `<section class="catalog-section" data-item-section><h2>${escapeHtml(group.title)}</h2><div class="catalog-grid">${group.items.map((item) => `<a class="catalog-card" data-item-card data-search="${escapeHtml(`${item.title} ${item.id}`.toLocaleLowerCase(language))}" href="${itemUrl(item.id, language)}">${itemIcon(item, 48)}<span><strong>${escapeHtml(item.title)}</strong><small>${escapeHtml(item.id)}</small></span></a>`).join('')}</div></section>`;
          }).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('items');
        const filter = article.querySelector('#item-filter');
        const count = article.querySelector('#catalog-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-item-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          article.querySelectorAll('[data-item-section]').forEach((section) => { section.hidden = !section.querySelector('[data-item-card]:not([hidden])'); });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.items}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderItemArticle(language, itemId) {
      const labels = itemUi[language];
      const article = document.querySelector('#item-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/items/${encodeURIComponent(itemId)}`);
        const item = data.item;
        const description = item.description || labels.noDescription;
        const properties = [
          item.toolType && [labels.toolType, localizedValue(toolTypeTitles, item.toolType, language)],
          item.power !== null && item.power > 0 && [labels.power, item.power],
          item.equipSlot && [labels.equipSlot, localizedValue(equipSlotTitles, item.equipSlot, language)],
          item.foodValue > 0 && [labels.foodValue, item.foodValue],
          item.fluidCapacity > 0 && [labels.fluidCapacity, item.fluidCapacity],
          item.blockId && [labels.blockId, item.blockId],
          item.useAction && [labels.useAction, item.useAction],
        ].filter(Boolean);
        const infoRows = [[labels.type, item.categoryTitle], [labels.rarity, item.rarityTitle], [labels.stack, item.maxStack], [labels.identifier, item.id]];
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(item.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(item.title)}</strong> — ${escapeHtml(description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#item-characteristics">${labels.characteristics}</a></li><li><a href="#item-crafting">${labels.crafting}</a></li><li><a href="#item-usage">${labels.usage}</a></li></ol></nav>
              <section class="biome-section" id="item-characteristics"><h2>${labels.characteristics}</h2>${properties.length ? `<table class="wiki-data-table"><thead><tr><th>${labels.property}</th><th>${labels.value}</th></tr></thead><tbody>${properties.map(([key, value]) => `<tr><td>${escapeHtml(key)}</td><td>${escapeHtml(value)}</td></tr>`).join('')}</tbody></table>` : `<p class="empty-section">—</p>`}</section>
              <section class="biome-section" id="item-crafting"><h2>${labels.crafting}</h2>${recipeTable(data.recipes, language, 'crafting')}</section>
              <section class="biome-section" id="item-usage"><h2>${labels.usage}</h2>${recipeTable(data.usedIn, language, 'usage')}</section>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(item.title)}</h2>${itemIcon(item, 112)}<p class="infobox-caption">${escapeHtml(description)}</p><h3>${labels.information}</h3><dl>${infoRows.map(([key, value]) => `<div><dt>${escapeHtml(key)}</dt><dd>${escapeHtml(value)}</dd></div>`).join('')}</dl></aside>
          </div>`;
        document.title = `${item.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`items/${encodeURIComponent(item.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function recipeUrl(recipeId, language) {
      return `/${language}/recipes/${encodeURIComponent(recipeId)}`;
    }

    async function renderRecipeCatalog(language) {
      const labels = recipeUi[language];
      const article = document.querySelector('#recipe-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/recipes`);
        const groups = new Map(data.categories.map((category) => [category.id, { ...category, recipes: [] }]));
        data.recipes.forEach((recipe) => groups.get(recipe.category)?.recipes.push(recipe));
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.recipes}.</p>
          <div class="catalog-toolbar"><input id="recipe-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="recipe-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.recipes}</span></div>
          <div>${[...groups.values()].map((group) => `<section class="catalog-section" data-recipe-section><h2>${escapeHtml(group.title)} <small>(${group.count})</small></h2><div class="catalog-grid">${group.recipes.map((recipe) => `<a class="catalog-card" data-recipe-card data-search="${escapeHtml(`${recipe.title} ${recipe.id} ${recipe.categoryTitle}`.toLocaleLowerCase(language))}" href="${recipeUrl(recipe.id, language)}">${itemIcon(recipe.result, 48)}<span><strong>${escapeHtml(recipe.title)}${recipe.resultCount > 1 ? ` × ${recipe.resultCount}` : ''}</strong><small>${language === 'ru' ? 'Эпоха' : 'Age'} ${recipe.requiredAge > 6 ? '—' : recipe.requiredAge} · ${recipe.ingredientKinds} ${labels.ingredientKinds.toLocaleLowerCase(language)}</small></span></a>`).join('')}</div></section>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('recipes');
        const filter = article.querySelector('#recipe-filter');
        const count = article.querySelector('#recipe-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-recipe-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          article.querySelectorAll('[data-recipe-section]').forEach((section) => { section.hidden = !section.querySelector('[data-recipe-card]:not([hidden])'); });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.recipes}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderRecipeArticle(language, recipeId) {
      const labels = recipeUi[language];
      const article = document.querySelector('#recipe-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/recipes/${encodeURIComponent(recipeId)}`);
        const recipe = data.recipe;
        const ingredients = recipe.ingredients.map((ingredient) => `<a class="catalog-card" href="${itemUrl(ingredient.id, language)}">${itemIcon(ingredient, 48)}<span><strong>${escapeHtml(ingredient.title)}</strong><small>× ${ingredient.count}</small></span></a>`).join('');
        const result = `<a class="catalog-card" href="${itemUrl(recipe.result.id, language)}">${itemIcon(recipe.result, 48)}<span><strong>${escapeHtml(recipe.result.title)}</strong><small>× ${recipe.resultCount}</small></span></a>`;
        const unlocks = recipe.unlocks.map((unlock) => `<article class="mechanic-entry"><h3><a href="${escapeHtml(unlock.url)}">${escapeHtml(unlock.title)}</a></h3><p>${escapeHtml(unlock.description)}</p><strong>${escapeHtml(unlock.kind === 'age' ? labels.age : labels.specialGate)}</strong></article>`).join('');
        const technology = recipe.technology ? `<p><a href="/${language}/technologies/${encodeURIComponent(recipe.technology.id)}">${escapeHtml(recipe.technology.title)}</a> — ${escapeHtml(recipe.technology.description)}</p>` : `<p>${labels.noTechnology}</p>`;
        const pagination = [
          recipe.previous && `<a href="${recipeUrl(recipe.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(recipe.previous.title)}</strong></a>`,
          recipe.next && `<a href="${recipeUrl(recipe.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(recipe.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(recipe.result.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(recipe.result.title)}</strong> — ${language === 'ru' ? `рецепт категории «${escapeHtml(recipe.categoryTitle)}» для изготовления на станции «${escapeHtml(recipe.station.title)}».` : `a ${escapeHtml(recipe.categoryTitle)} recipe crafted at the ${escapeHtml(recipe.station.title)}.`}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#recipe-formula">${labels.formula}</a></li><li><a href="#recipe-unlocking">${labels.unlocking}</a></li><li><a href="#recipe-technology">${labels.technology}</a></li><li><a href="#recipe-uses">${labels.uses}</a></li></ol></nav>
              <section class="biome-section" id="recipe-formula"><h2>${labels.formula}</h2><h3>${labels.ingredients}</h3><div class="catalog-grid">${ingredients}</div><h3>${labels.result}</h3><div class="catalog-grid">${result}</div></section>
              <section class="biome-section" id="recipe-unlocking"><h2>${labels.unlocking}</h2><p>${labels.availableBy}:</p><div class="mechanic-entries">${unlocks}</div></section>
              <section class="biome-section" id="recipe-technology"><h2>${labels.technology}</h2>${technology}</section>
              <section class="biome-section" id="recipe-uses"><h2>${labels.uses}</h2><p>${labels.usedInCount}: <strong>${recipe.usedIngredientCount}</strong>. <a href="${itemUrl(recipe.result.id, language)}">${escapeHtml(recipe.result.title)}</a></p></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(recipe.result.title)}</h2><a href="${itemUrl(recipe.result.id, language)}">${itemIcon(recipe.result, 112)}</a><p class="infobox-caption">${escapeHtml(recipe.categoryTitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.output}</dt><dd>× ${recipe.resultCount}</dd></div><div><dt>${labels.station}</dt><dd><a href="${escapeHtml(recipe.station.url)}">${escapeHtml(recipe.station.title)}</a></dd></div><div><dt>${labels.age}</dt><dd>${recipe.requiredAge > 6 ? '—' : recipe.requiredAge}</dd></div><div><dt>${labels.identifier}</dt><dd>${escapeHtml(recipe.id)}</dd></div></dl></aside>
          </div>`;
        document.title = `${recipe.result.title} — ${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks(`recipes/${encodeURIComponent(recipe.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function balanceNumberText(value, language) {
      return new Intl.NumberFormat(language === 'ru' ? 'ru-RU' : 'en-US', { maximumFractionDigits: 2 }).format(value ?? 0);
    }

    function balanceItemChip(item, count, language) {
      return `<a class="balance-item-chip" href="${itemUrl(item.id, language)}">${itemIcon(item, 32)}<span><strong>${escapeHtml(item.title)}</strong><small>${escapeHtml(item.id)} · × ${balanceNumberText(count, language)}</small></span></a>`;
    }

    function renderBalanceChainNode(node, language, labels, root = false) {
      const title = `${escapeHtml(node.item.title)} × ${balanceNumberText(node.count, language)}`;
      if (!node.children?.length) {
        const note = node.cycle ? 'cycle' : labels.raw;
        return `<div class="balance-chain__leaf">${itemIcon(node.item, 24)} <a href="${itemUrl(node.item.id, language)}">${title}</a> <span class="balance-chain__raw">· ${escapeHtml(note)}</span></div>`;
      }
      const recipeLink = node.recipeId ? `<a href="${recipeUrl(node.recipeId, language)}"><code>${escapeHtml(node.recipeId)}</code></a>` : '';
      return `<details${root ? ' open' : ''}><summary>${itemIcon(node.item, 24)} <strong>${title}</strong> · ${balanceNumberText(node.crafts, language)} ${labels.crafts} ${recipeLink}</summary>${node.children.map((child) => renderBalanceChainNode(child, language, labels)).join('')}</details>`;
    }

    function balancePrompt(recipe, language, labels) {
      const direct = recipe.ingredients.map((ingredient) => `${ingredient.id} × ${balanceNumberText(ingredient.count, language)}`).join(' + ');
      const raw = recipe.rawResources.map((resource) => `${resource.id} × ${balanceNumberText(resource.count, language)}`).join(', ');
      if (language === 'ru') {
        return `Измени рецепт \`${recipe.id}\` (${recipe.title}).\n\nСейчас: ${direct} → ${recipe.result.id} × ${recipe.resultCount}.\nЭпоха: ${recipe.requiredAge}. Категория: ${recipe.category}.\nИтоговые входы цепочки крафта: ${balanceNumberText(recipe.rawTotal, language)} ед. (${raw || 'нет данных'}).\nФайл: ${recipe.sourcePath}.\n\n${labels.promptChange}\n\n${labels.promptKeep}`;
      }
      return `Change recipe \`${recipe.id}\` (${recipe.title}).\n\nCurrent: ${direct} → ${recipe.result.id} × ${recipe.resultCount}.\nAge: ${recipe.requiredAge}. Category: ${recipe.category}.\nTerminal crafting-chain inputs: ${balanceNumberText(recipe.rawTotal, language)} units (${raw || 'no data'}).\nFile: ${recipe.sourcePath}.\n\n${labels.promptChange}\n\n${labels.promptKeep}`;
    }

    async function renderCraftingBalance(language) {
      const labels = craftingBalanceUi[language];
      const article = document.querySelector('#crafting-balance-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/crafting-balance`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.title}</h1>
          <p class="catalog-intro">${labels.intro}</p>
          <p class="balance-source-note"><strong>${labels.source}:</strong> <code>${escapeHtml(data.source)}</code><br>${labels.liveNote}</p>
          <div class="balance-stats">
            <div class="balance-stat"><strong>${labels.recipes}</strong><span>${data.count}</span></div>
            <div class="balance-stat"><strong>${labels.rawResources}</strong><span>${data.rawResourceCount}</span></div>
            <div class="balance-stat is-warning"><strong>${labels.warnings}</strong><span>${data.warningCount}</span></div>
            <div class="balance-stat is-error"><strong>${labels.errors}</strong><span>${data.errorCount}</span></div>
          </div>
          <div class="balance-controls">
            <label class="balance-control"><span>${labels.search}</span><input id="balance-search" type="search" placeholder="${labels.search}"></label>
            <label class="balance-control"><span>${labels.age}</span><select id="balance-age"><option value="">${labels.allAges}</option>${data.ages.map((age) => `<option value="${age}">${labels.age} ${age > 6 ? '—' : age}</option>`).join('')}</select></label>
            <label class="balance-control"><span>${labels.category}</span><select id="balance-category"><option value="">${labels.allCategories}</option>${data.categories.map((category) => `<option value="${escapeHtml(category.id)}">${escapeHtml(category.title)} (${category.count})</option>`).join('')}</select></label>
            <label class="balance-control"><span>${labels.status}</span><select id="balance-status"><option value="">${labels.allStatuses}</option><option value="warning">${labels.onlyWarnings}</option><option value="error">${labels.onlyErrors}</option><option value="ok">${labels.noWarnings}</option></select></label>
            <label class="balance-control"><span>${labels.sort}</span><select id="balance-sort"><option value="progression">${labels.sortProgression}</option><option value="cost-desc">${labels.sortCostDesc}</option><option value="cost-asc">${labels.sortCostAsc}</option><option value="depth">${labels.sortDepth}</option><option value="name">${labels.sortName}</option></select></label>
            <button class="balance-button is-secondary" id="balance-refresh" type="button">${labels.refresh}</button>
          </div>
          <p class="balance-results-count" id="balance-results-count"></p>
          <div class="balance-table-wrap"><table class="balance-table"><thead><tr><th>${labels.recipe}</th><th>${labels.age}</th><th>${labels.category}</th><th>${labels.direct}</th><th>${labels.rawCost}</th><th>${labels.depth}</th><th>${labels.operations}</th><th>${labels.usage}</th><th>${labels.status}</th></tr></thead><tbody id="balance-table-body"></tbody></table></div>
          <section class="balance-detail" id="balance-detail" hidden></section>`;

        const search = article.querySelector('#balance-search');
        const age = article.querySelector('#balance-age');
        const category = article.querySelector('#balance-category');
        const status = article.querySelector('#balance-status');
        const sort = article.querySelector('#balance-sort');
        const tableBody = article.querySelector('#balance-table-body');
        const resultCount = article.querySelector('#balance-results-count');
        const detail = article.querySelector('#balance-detail');
        let selectedRecipeId = new URLSearchParams(window.location.search).get('recipe') ?? '';

        const openRecipe = async (recipeId, scroll = true) => {
          selectedRecipeId = recipeId;
          article.querySelectorAll('[data-balance-row]').forEach((row) => row.classList.toggle('is-selected', row.dataset.balanceRow === recipeId));
          detail.hidden = false;
          detail.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
          const response = await fetchWikiJson(`/api/v1/${language}/crafting-balance/${encodeURIComponent(recipeId)}`);
          const recipe = response.recipe;
          const warningMarkup = recipe.warnings.length
            ? recipe.warnings.map((warning) => `<li class="balance-warning is-${escapeHtml(warning.severity)}"><strong>${escapeHtml(warning.severity.toUpperCase())}</strong> — ${escapeHtml(warning.message)}</li>`).join('')
            : `<li class="balance-warning"><strong>${labels.ok}</strong></li>`;
          const usedIn = recipe.usedIn.length
            ? `<div class="catalog-grid">${recipe.usedIn.map((entry) => `<a class="catalog-card" href="${recipeUrl(entry.id, language)}">${itemIcon(entry.result, 48)}<span><strong>${escapeHtml(entry.title)}</strong><small><code>${escapeHtml(entry.id)}</code></small></span></a>`).join('')}</div>`
            : `<p class="empty-section">${labels.noUses}</p>`;
          const prompt = balancePrompt(recipe, language, labels);
          detail.innerHTML = `
            <div class="balance-detail__heading"><div><h2>${labels.details}: ${escapeHtml(recipe.title)}</h2><p>${labels.sourceFile}: <code>${escapeHtml(recipe.sourcePath)}</code></p></div><a class="balance-button is-secondary" href="${recipeUrl(recipe.id, language)}">${labels.open}</a></div>
            <section class="biome-section"><h2>${labels.formula}</h2><div class="balance-formula"><div class="balance-formula__items">${recipe.ingredients.map((ingredient) => balanceItemChip(ingredient, ingredient.count, language)).join('')}</div><span class="balance-formula__arrow">→</span><div class="balance-formula__items">${balanceItemChip(recipe.result, recipe.resultCount, language)}</div></div></section>
            <section class="biome-section"><h2>${labels.metrics}</h2><div class="balance-stats"><div class="balance-stat"><strong>${labels.rawCost}</strong><span>${balanceNumberText(recipe.rawTotal, language)}</span></div><div class="balance-stat"><strong>${labels.rawResources}</strong><span>${recipe.rawKinds}</span></div><div class="balance-stat"><strong>${labels.depth}</strong><span>${recipe.depth}</span></div><div class="balance-stat"><strong>${labels.operations}</strong><span>${balanceNumberText(recipe.operations, language)}</span></div></div></section>
            <section class="biome-section"><h2>${labels.issues}</h2><ul class="balance-warning-list">${warningMarkup}</ul></section>
            <section class="biome-section"><h2>${labels.rawBreakdown}</h2><div class="balance-raw-grid">${recipe.rawResources.map((resource) => balanceItemChip(resource, resource.count, language)).join('') || `<p class="empty-section">—</p>`}</div></section>
            <section class="biome-section"><h2>${labels.chain}</h2><div class="balance-chain">${renderBalanceChainNode(recipe.chain, language, labels, true)}</div></section>
            <section class="biome-section"><h2>${labels.usedIn}</h2>${usedIn}</section>
            <section class="biome-section"><h2>${labels.copyPrompt}</h2><p>${labels.promptHint}</p><textarea class="balance-prompt" id="balance-prompt">${escapeHtml(prompt)}</textarea><div class="balance-prompt-actions"><button class="balance-button" id="balance-copy" type="button">${labels.copy}</button><span class="balance-copy-status" id="balance-copy-status"></span></div></section>`;
          const copyButton = detail.querySelector('#balance-copy');
          copyButton.addEventListener('click', async () => {
            const textarea = detail.querySelector('#balance-prompt');
            const copyStatus = detail.querySelector('#balance-copy-status');
            try {
              if (navigator.clipboard?.writeText) await navigator.clipboard.writeText(textarea.value);
              else { textarea.select(); document.execCommand('copy'); }
              copyStatus.textContent = labels.copied;
            } catch (error) {
              textarea.select();
              copyStatus.textContent = labels.copyFailed;
            }
          });
          const url = new URL(window.location.href);
          url.searchParams.set('recipe', recipeId);
          window.history.replaceState({}, '', url);
          if (scroll) detail.scrollIntoView({ behavior: 'smooth', block: 'start' });
        };

        const applyFilters = () => {
          const query = search.value.trim().toLocaleLowerCase(language);
          let filtered = data.recipes.filter((recipe) => {
            if (query && !`${recipe.title} ${recipe.id} ${recipe.result.id}`.toLocaleLowerCase(language).includes(query)) return false;
            if (age.value && String(recipe.requiredAge) !== age.value) return false;
            if (category.value && recipe.category !== category.value) return false;
            if (status.value === 'warning' && recipe.warningCount === 0) return false;
            if (status.value === 'error' && recipe.errorCount === 0) return false;
            if (status.value === 'ok' && recipe.warningCount > 0) return false;
            return true;
          });
          const comparators = {
            progression: (left, right) => left.requiredAge - right.requiredAge || left.id.localeCompare(right.id),
            'cost-desc': (left, right) => right.rawTotal - left.rawTotal || left.id.localeCompare(right.id),
            'cost-asc': (left, right) => left.rawTotal - right.rawTotal || left.id.localeCompare(right.id),
            depth: (left, right) => right.depth - left.depth || right.rawTotal - left.rawTotal,
            name: (left, right) => left.title.localeCompare(right.title, language),
          };
          filtered = filtered.sort(comparators[sort.value] ?? comparators.progression);
          resultCount.textContent = `${labels.shown} ${filtered.length} ${labels.of} ${data.count}`;
          tableBody.innerHTML = filtered.length ? filtered.map((recipe) => {
            const statusBadge = recipe.errorCount > 0
              ? `<span class="balance-badge is-error">${recipe.errorCount} error</span>`
              : recipe.warningCount > 0 ? `<span class="balance-badge is-warning">${recipe.warningCount}</span>` : `<span class="balance-badge">${labels.ok}</span>`;
            return `<tr data-balance-row="${escapeHtml(recipe.id)}" class="${recipe.id === selectedRecipeId ? 'is-selected' : ''}"><td><button class="balance-recipe-button" data-open-balance="${escapeHtml(recipe.id)}" type="button">${itemIcon(recipe.result, 36)}<span>${escapeHtml(recipe.title)}<br><small><code>${escapeHtml(recipe.id)}</code></small></span></button></td><td>${recipe.requiredAge > 6 ? '—' : recipe.requiredAge}</td><td>${escapeHtml(recipe.categoryTitle)}</td><td>${recipe.ingredients.length} / ${balanceNumberText(recipe.directIngredientTotal, language)}</td><td><strong>${balanceNumberText(recipe.rawTotal, language)}</strong> <small>(${recipe.rawKinds})</small></td><td>${recipe.depth}</td><td>${balanceNumberText(recipe.operations, language)}</td><td>${recipe.usedInCount}</td><td>${statusBadge}</td></tr>`;
          }).join('') : `<tr><td colspan="9" class="empty-section">${labels.noResults}</td></tr>`;
          tableBody.querySelectorAll('[data-open-balance]').forEach((button) => button.addEventListener('click', () => openRecipe(button.dataset.openBalance)));
        };

        [search, age, category, status, sort].forEach((control) => control.addEventListener(control === search ? 'input' : 'change', applyFilters));
        article.querySelector('#balance-refresh').addEventListener('click', () => renderCraftingBalance(language));
        applyFilters();
        if (selectedRecipeId && data.recipes.some((recipe) => recipe.id === selectedRecipeId)) await openRecipe(selectedRecipeId, false);
        document.title = `${labels.title} — InfiniteForge Wiki`;
        updateLanguageLinks('crafting-balance');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function bossUrl(bossId, language) {
      return `/${language}/bosses/${encodeURIComponent(bossId)}`;
    }

    function bossPortrait(boss, size) {
      const color = boss.color ?? [0.45, 0.55, 0.62, 1];
      const style = `position:relative;width:${size}px;height:${size}px;--boss-color:rgba(${Math.round(color[0] * 255)},${Math.round(color[1] * 255)},${Math.round(color[2] * 255)},${color[3] ?? 1})`;
      if (boss.portrait) return `<span class="boss-portrait" style="${style}" aria-hidden="true"><img src="${escapeHtml(boss.portrait)}" onload="fitLoadedPixelImage(this,${Number(size)},true)" alt=""></span>`;
      return `<span class="boss-portrait" style="${style}" aria-hidden="true">${escapeHtml(boss.title.slice(0, 1))}</span>`;
    }

    function bossItemMarkup(item, language, showCount = true) {
      const title = escapeHtml(item.title);
      const linkedTitle = item.exists ? `<a href="${itemUrl(item.id, language)}">${title}</a>` : title;
      return `<span class="recipe-item">${item.texture ? itemIcon(item, 28) : ''}${linkedTitle}${showCount ? ` × ${item.count}` : ''}</span>`;
    }

    function abilityCard(ability, title, language) {
      const labels = bossUi[language];
      if (!ability) return `<article class="ability-card"><h3>${title}</h3><p class="empty-section">${labels.noAbility}</p></article>`;
      const rows = [
        [labels.attackType, localizedValue(specialTypeTitles, ability.type, language)],
        ability.effect && [labels.effect, readableId(ability.effect)],
        ability.range !== null && [labels.range, ability.range],
        ability.radius !== null && [labels.radius, ability.radius],
        ability.damageMultiplier !== null && [labels.multiplier, `× ${ability.damageMultiplier}`],
        ability.cooldown !== null && [labels.cooldown, `${ability.cooldown} ${language === 'en' ? 'sec' : 'с'}`],
        ability.summonedMob && [labels.summonedMob, readableId(ability.summonedMob)],
        ability.count !== null && [labels.count, ability.count],
      ].filter(Boolean);
      return `<article class="ability-card"><h3>${title}</h3><dl>${rows.map(([key, value]) => `<dt>${escapeHtml(key)}</dt><dd>${escapeHtml(value)}</dd>`).join('')}</dl></article>`;
    }

    async function renderBossCatalog(language) {
      const labels = bossUi[language];
      const article = document.querySelector('#boss-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/bosses`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="catalog-toolbar"><input id="boss-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="boss-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.bosses}</span></div>
          <div class="boss-grid">${data.bosses.map((boss) => `<a class="boss-card" data-boss-card data-search="${escapeHtml(`${boss.title} ${boss.id} ${boss.biomeTitle}`.toLocaleLowerCase(language))}" href="${bossUrl(boss.id, language)}">${bossPortrait(boss, 82)}<span><h2>${escapeHtml(boss.title)}</h2><p>${escapeHtml(boss.biomeTitle)} · ${labels.health}: ${boss.maxHp}</p></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('bosses');
        const filter = article.querySelector('#boss-filter');
        const count = article.querySelector('#boss-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-boss-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.bosses}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderBossArticle(language, bossId) {
      const labels = bossUi[language];
      const article = document.querySelector('#boss-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/bosses/${encodeURIComponent(bossId)}`);
        const boss = data.boss;
        const biomeLink = `<a href="/${language}/worlds/overworld/biomes/${boss.biomeId}">${escapeHtml(boss.biomeTitle)}</a>`;
        const lootRows = boss.loot.map((item) => `<tr><td>${bossItemMarkup(item, language, false)}</td><td>${item.count}</td></tr>`).join('');
        const extraDrops = [boss.pageDrop && [labels.pageDrop, boss.pageDrop], boss.summonerItem && [labels.summoner, boss.summonerItem]].filter(Boolean);
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(boss.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(boss.title)}</strong> — ${escapeHtml(boss.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#boss-characteristics">${labels.characteristics}</a></li><li><a href="#boss-abilities">${labels.abilities}</a></li><li><a href="#boss-loot">${labels.loot}</a></li></ol></nav>
              <section class="biome-section" id="boss-characteristics"><h2>${labels.characteristics}</h2><table class="wiki-data-table"><tbody><tr><th>${labels.biome}</th><td>${biomeLink}</td></tr><tr><th>${labels.health}</th><td>${boss.maxHp}</td></tr><tr><th>${labels.contactDamage}</th><td>${boss.contactDamage}</td></tr><tr><th>${labels.speed}</th><td>${boss.speed}</td></tr></tbody></table></section>
              <section class="biome-section" id="boss-abilities"><h2>${labels.abilities}</h2><div class="ability-grid">${abilityCard(boss.special, labels.phaseOne, language)}${abilityCard(boss.phaseTwoSpecial, labels.phaseTwo, language)}</div></section>
              <section class="biome-section" id="boss-loot"><h2>${labels.loot}</h2>${lootRows ? `<table class="wiki-data-table"><thead><tr><th>${labels.guaranteedLoot}</th><th>${labels.count}</th></tr></thead><tbody>${lootRows}</tbody></table>` : `<p class="empty-section">${labels.noLoot}</p>`}${extraDrops.length ? `<table class="wiki-data-table"><tbody>${extraDrops.map(([key, item]) => `<tr><th>${key}</th><td>${bossItemMarkup(item, language)}</td></tr>`).join('')}</tbody></table>` : ''}</section>
            </div>
            <aside class="infobox boss-infobox"><h2>${escapeHtml(boss.title)}</h2>${bossPortrait(boss, 126)}<p class="infobox-caption">${escapeHtml(boss.description)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.boss}</dd></div><div><dt>${labels.biome}</dt><dd>${biomeLink}</dd></div><div><dt>${labels.health}</dt><dd>${boss.maxHp}</dd></div><div><dt>${labels.contactDamage}</dt><dd>${boss.contactDamage}</dd></div></dl></aside>
          </div>`;
        document.title = `${boss.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`bosses/${encodeURIComponent(boss.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function mobUrl(mobId, language) {
      return `/${language}/mobs/${encodeURIComponent(mobId)}`;
    }

    async function renderMobCatalog(language) {
      const labels = mobUi[language];
      const article = document.querySelector('#mob-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/mobs`);
        const groups = new Map();
        data.mobs.forEach((mob) => {
          if (!groups.has(mob.biomeId)) groups.set(mob.biomeId, { title: mob.biomeTitle, mobs: [] });
          groups.get(mob.biomeId).mobs.push(mob);
        });
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="catalog-toolbar"><input id="mob-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="mob-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.mobs}</span></div>
          <div>${Array.from(groups.entries()).map(([biomeId, group]) => `<section class="catalog-section" data-mob-section><h2><a class="catalog-heading-link" href="/${language}/worlds/overworld/biomes/${encodeURIComponent(biomeId)}">${escapeHtml(group.title)}</a></h2><div class="boss-grid">${group.mobs.map((mob) => `<a class="boss-card" data-mob-card data-search="${escapeHtml(`${mob.title} ${mob.id} ${mob.roleTitle} ${mob.biomeTitle}`.toLocaleLowerCase(language))}" href="${mobUrl(mob.id, language)}">${bossPortrait(mob, 82)}<span><h2>${escapeHtml(mob.title)}</h2><p>${escapeHtml(mob.roleTitle)} · ${labels.health}: ${mob.hp}</p></span></a>`).join('')}</div></section>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('mobs');
        const filter = article.querySelector('#mob-filter');
        const count = article.querySelector('#mob-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-mob-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          article.querySelectorAll('[data-mob-section]').forEach((section) => { section.hidden = !section.querySelector('[data-mob-card]:not([hidden])'); });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.mobs}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderMobArticle(language, mobId) {
      const labels = mobUi[language];
      const article = document.querySelector('#mob-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/mobs/${encodeURIComponent(mobId)}`);
        const mob = data.mob;
        const biomeLink = `<a href="/${language}/worlds/overworld/biomes/${encodeURIComponent(mob.biomeId)}">${escapeHtml(mob.biomeTitle)}</a>`;
        const behavior = labels.roleBehavior[mob.role] ?? labels.roleBehavior.skirmisher;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(mob.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(mob.title)}</strong> — ${escapeHtml(mob.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#mob-characteristics">${labels.characteristics}</a></li><li><a href="#mob-behavior">${labels.behavior}</a></li><li><a href="#mob-loot">${labels.loot}</a></li></ol></nav>
              <section class="biome-section" id="mob-characteristics"><h2>${labels.characteristics}</h2><table class="wiki-data-table"><tbody><tr><th>${labels.role}</th><td>${escapeHtml(mob.roleTitle)}</td></tr><tr><th>${labels.biome}</th><td>${biomeLink}</td></tr><tr><th>${labels.health}</th><td>${mob.hp}</td></tr><tr><th>${labels.damage}</th><td>${mob.damage}</td></tr><tr><th>${labels.speed}</th><td>${mob.speed}</td></tr></tbody></table></section>
              <section class="biome-section" id="mob-behavior"><h2>${labels.behavior}</h2><p>${escapeHtml(behavior)}</p></section>
              <section class="biome-section" id="mob-loot"><h2>${labels.loot}</h2><table class="wiki-data-table"><thead><tr><th>${labels.item}</th><th>${labels.count}</th><th>${labels.guaranteed}</th></tr></thead><tbody><tr><td>${bossItemMarkup(mob.loot, language, false)}</td><td>${mob.loot.count}</td><td>100%</td></tr></tbody></table></section>
            </div>
            <aside class="infobox boss-infobox"><h2>${escapeHtml(mob.title)}</h2>${bossPortrait(mob, 126)}<p class="infobox-caption">${escapeHtml(mob.description)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.mob}</dd></div><div><dt>${labels.role}</dt><dd>${escapeHtml(mob.roleTitle)}</dd></div><div><dt>${labels.biome}</dt><dd>${biomeLink}</dd></div><div><dt>${labels.health}</dt><dd>${mob.hp}</dd></div></dl></aside>
          </div>`;
        document.title = `${mob.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`mobs/${encodeURIComponent(mob.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function machineUrl(machineId, language) {
      return `/${language}/machines/${encodeURIComponent(machineId)}`;
    }

    function formatMachineMetric(key, value, language) {
      const labels = machineUi[language];
      if (key === 'outputItem') return `<a href="${itemUrl(value, language)}">${escapeHtml(readableId(value))}</a>`;
      const unit = labels.units[key];
      return `${escapeHtml(value)}${unit ? ` ${unit}` : ''}`;
    }

    async function renderMachineCatalog(language) {
      const labels = machineUi[language];
      const article = document.querySelector('#machine-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/machines`);
        const categoryOrder = ['machines', 'generators', 'conveyors', 'storage'];
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="catalog-toolbar"><input id="machine-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="machine-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.machinesCount}</span></div>
          <div>${categoryOrder.map((category) => {
            const machines = data.machines.filter((machine) => machine.category === category);
            if (!machines.length) return '';
            return `<section class="catalog-section" data-machine-section><h2>${labels.categories[category]}</h2><div class="catalog-grid">${machines.map((machine) => `<a class="catalog-card" data-machine-card data-search="${escapeHtml(`${machine.title} ${machine.id} ${machine.categoryTitle}`.toLocaleLowerCase(language))}" href="${machineUrl(machine.id, language)}">${itemIcon(machine, 48)}<span><strong>${escapeHtml(machine.title)}</strong><small>${escapeHtml(machine.id)}</small></span></a>`).join('')}</div></section>`;
          }).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('machines');
        const filter = article.querySelector('#machine-filter');
        const count = article.querySelector('#machine-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-machine-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          article.querySelectorAll('[data-machine-section]').forEach((section) => { section.hidden = !section.querySelector('[data-machine-card]:not([hidden])'); });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.machinesCount}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderMachineArticle(language, machineId) {
      const labels = machineUi[language];
      const article = document.querySelector('#machine-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/machines/${encodeURIComponent(machineId)}`);
        const machine = data.machine;
        const itemLink = `<a href="${itemUrl(machine.item.id, language)}">${escapeHtml(machine.item.title)}</a>`;
        const characteristics = [
          [labels.category, machine.categoryTitle],
          [labels.health, machine.health],
          [labels.requiredTool, localizedValue(toolTypeTitles, machine.requiredTool, language)],
          [labels.size, `${machine.size.x} × ${machine.size.y}`],
          [labels.rotatable, machine.rotatable ? labels.yes : labels.no],
          [labels.interactive, machine.interactive ? labels.yes : labels.no],
          machine.interactive && machine.interactType && [labels.interface, readableId(machine.interactType)],
        ].filter(Boolean);
        const metricRows = Object.entries(machine.metrics).map(([key, value]) => `<tr><th>${escapeHtml(labels.metrics[key] ?? readableId(key))}</th><td>${formatMachineMetric(key, value, language)}</td></tr>`).join('');
        const fluidProcesses = data.fluidProcesses.map((recipe) => fluidRecipeCard(recipe, language, fluidUi[language])).join('');
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(machine.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(machine.title)}</strong> — ${escapeHtml(machine.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#machine-characteristics">${labels.characteristics}</a></li><li><a href="#machine-technical">${labels.technical}</a></li><li><a href="#machine-crafting">${labels.crafting}</a></li>${fluidProcesses ? `<li><a href="#machine-fluids">${labels.fluidProcesses}</a></li>` : ''}</ol></nav>
              <section class="biome-section" id="machine-characteristics"><h2>${labels.characteristics}</h2><table class="wiki-data-table"><tbody>${characteristics.map(([key, value]) => `<tr><th>${escapeHtml(key)}</th><td>${escapeHtml(value)}</td></tr>`).join('')}</tbody></table></section>
              <section class="biome-section" id="machine-technical"><h2>${labels.technical}</h2>${metricRows ? `<table class="wiki-data-table"><tbody>${metricRows}</tbody></table>` : `<p class="empty-section">${labels.noTechnical}</p>`}</section>
              <section class="biome-section" id="machine-crafting"><h2>${labels.crafting}</h2>${recipeTable(data.recipes, language, 'crafting')}</section>
              ${fluidProcesses ? `<section class="biome-section" id="machine-fluids"><h2>${labels.fluidProcesses}</h2><div class="fluid-recipes">${fluidProcesses}</div></section>` : ''}
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(machine.title)}</h2>${itemIcon(machine, 112)}<p class="infobox-caption">${escapeHtml(machine.description)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.category}</dt><dd>${escapeHtml(machine.categoryTitle)}</dd></div><div><dt>${labels.item}</dt><dd>${itemLink}</dd></div><div><dt>${labels.health}</dt><dd>${machine.health}</dd></div><div><dt>${labels.size}</dt><dd>${machine.size.x} × ${machine.size.y}</dd></div><div><dt>${labels.identifier}</dt><dd>${escapeHtml(machine.id)}</dd></div></dl></aside>
          </div>`;
        document.title = `${machine.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`machines/${encodeURIComponent(machine.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function technologyUrl(technologyId, language) {
      return `/${language}/technologies/${encodeURIComponent(technologyId)}`;
    }

    async function renderTechnologyCatalog(language) {
      const labels = technologyUi[language];
      const article = document.querySelector('#technology-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/technologies`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="technology-path">${data.technologies.map((technology, index) => `
            <a class="technology-card" href="${technologyUrl(technology.id, language)}"><span class="technology-index">${index + 1}</span><span><h2>${escapeHtml(technology.title)}</h2><p>${escapeHtml(technology.description)}</p></span><span class="technology-meta">${technology.biome ? escapeHtml(technology.biome.title) : labels.available}<br>${technology.outputCount} ${labels.unlocks}</span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('technologies');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function technologyOutputCard(output, language) {
      const href = output.kind === 'machine' ? machineUrl(output.id, language) : itemUrl(output.id, language);
      const title = escapeHtml(output.title);
      return output.exists === false
        ? `<span class="biome-resource">${itemIcon(output, 44)}<span><strong>${title}</strong><small>${escapeHtml(output.id)}</small></span></span>`
        : `<a class="biome-resource" href="${href}">${itemIcon(output, 44)}<span><strong>${title}</strong><small>${escapeHtml(output.id)}</small></span></a>`;
    }

    function localizedBalanceValue(value, language) {
      if (language !== 'ru') return value;
      return String(value).replace(/\bmin\b/g, 'мин').replace(/\bs\b/g, 'с');
    }

    async function renderTechnologyArticle(language, technologyId) {
      const labels = technologyUi[language];
      const article = document.querySelector('#technology-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/technologies/${encodeURIComponent(technologyId)}`);
        const technology = data.technology;
        const research = technology.research.map((item) => `<span class="recipe-item">${bossItemMarkup(item, language, false)} × ${item.count}</span>`).join('');
        const requirements = [
          technology.biome && [labels.biome, `<a href="/${language}/worlds/overworld/biomes/${technology.biome.id}">${escapeHtml(technology.biome.title)}</a>`],
          technology.boss && [labels.boss, `<a href="${bossUrl(technology.boss.id, language)}">${escapeHtml(technology.boss.title)}</a>`],
          technology.research.length && [labels.research, research],
        ].filter(Boolean);
        const balanceRows = technology.balance ? [
          [labels.targets, technology.balance.targetCount],
          [labels.rawUnits, technology.balance.rawUnits],
          [labels.machineTime, localizedBalanceValue(technology.balance.machineTime, language)],
          [labels.estimatedTime, localizedBalanceValue(technology.balance.estimatedTime, language)],
        ] : [];
        const pagination = [
          technology.previous && `<a href="${technologyUrl(technology.previous.id, language)}"><small>← ${language === 'ru' ? 'Предыдущий этап' : 'Previous stage'}</small><strong>${escapeHtml(technology.previous.title)}</strong></a>`,
          technology.next && `<a href="${technologyUrl(technology.next.id, language)}"><small>${language === 'ru' ? 'Следующий этап' : 'Next stage'} →</small><strong>${escapeHtml(technology.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(technology.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(technology.title)}</strong> — ${escapeHtml(technology.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#technology-overview">${labels.overview}</a></li><li><a href="#technology-requirements">${labels.requirements}</a></li><li><a href="#technology-outputs">${labels.outputs}</a></li><li><a href="#technology-balance">${labels.balance}</a></li></ol></nav>
              <section class="biome-section" id="technology-overview"><h2>${labels.overview}</h2><p>${escapeHtml(technology.description)}</p>${technology.nextBiome ? `<p class="biome-notice"><strong>${labels.nextBiome}:</strong> <a href="/${language}/worlds/overworld/biomes/${technology.nextBiome.id}">${escapeHtml(technology.nextBiome.title)}</a>.</p>` : ''}</section>
              <section class="biome-section" id="technology-requirements"><h2>${labels.requirements}</h2>${requirements.length ? `<table class="wiki-data-table"><tbody>${requirements.map(([key, value]) => `<tr><th>${key}</th><td>${value}</td></tr>`).join('')}</tbody></table>` : `<p>${labels.available}</p>`}</section>
              <section class="biome-section" id="technology-outputs"><h2>${labels.outputs}</h2>${technology.machines.length ? `<h3>${labels.machines}</h3><div class="technology-output-grid">${technology.machines.map((output) => technologyOutputCard(output, language)).join('')}</div>` : ''}${technology.components.length ? `<h3>${labels.components}</h3><div class="technology-output-grid">${technology.components.map((output) => technologyOutputCard(output, language)).join('')}</div>` : ''}</section>
              <section class="biome-section" id="technology-balance"><h2>${labels.balance}</h2>${balanceRows.length ? `<table class="wiki-data-table"><tbody>${balanceRows.map(([key, value]) => `<tr><th>${key}</th><td>${escapeHtml(value)}</td></tr>`).join('')}</tbody></table>` : `<p class="empty-section">${labels.noBalance}</p>`}</section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(technology.title)}</h2>${technology.machines[0] ? itemIcon(technology.machines[0], 112) : ''}<p class="infobox-caption">${escapeHtml(technology.description)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.stage}</dt><dd>${escapeHtml(technology.id)}</dd></div><div><dt>${labels.biome}</dt><dd>${technology.biome ? `<a href="/${language}/worlds/overworld/biomes/${technology.biome.id}">${escapeHtml(technology.biome.title)}</a>` : labels.available}</dd></div><div><dt>${labels.outputs}</dt><dd>${technology.machines.length + technology.components.length}</dd></div>${technology.balance ? `<div><dt>${labels.estimatedTime}</dt><dd>${escapeHtml(localizedBalanceValue(technology.balance.estimatedTime, language))}</dd></div>` : ''}</dl></aside>
          </div>`;
        document.title = `${technology.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`technologies/${encodeURIComponent(technology.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function systemUrl(systemId, language) {
      return `/${language}/systems/${encodeURIComponent(systemId)}`;
    }

    function systemColor(system) {
      const color = system.color ?? [0.3, 0.55, 0.72, 1];
      return `rgba(${Math.round(color[0] * 255)},${Math.round(color[1] * 255)},${Math.round(color[2] * 255)},${color[3] ?? 1})`;
    }

    function systemOutputLink(output, language) {
      const href = output.kind === 'machine' ? machineUrl(output.id, language) : itemUrl(output.id, language);
      return output.exists === false ? `<span>${escapeHtml(output.title)}</span>` : `<a href="${href}">${escapeHtml(output.title)}</a>`;
    }

    async function renderSystemCatalog(language) {
      const labels = systemUi[language];
      const article = document.querySelector('#system-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/systems`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="system-grid">${data.systems.map((system) => `
            <a class="system-card" style="--system-color:${systemColor(system)}" href="${systemUrl(system.id, language)}"><span class="system-mark">${escapeHtml(system.title.slice(0, 1))}</span><span><h2>${escapeHtml(system.title)}</h2><p>${escapeHtml(system.subtitle)}</p><small>${system.stageCount} ${labels.steps} · ${system.equipmentCount} ${labels.related.toLocaleLowerCase(language)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('systems');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderSystemArticle(language, systemId) {
      const labels = systemUi[language];
      const article = document.querySelector('#system-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/systems/${encodeURIComponent(systemId)}`);
        const system = data.system;
        const color = systemColor(system);
        const facts = system.facts.map((fact) => `<article class="system-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const stages = system.stages.map((stage) => `<article class="system-step"><h3>${escapeHtml(stage.title)}</h3><p>${escapeHtml(stage.text)}</p>${stage.links.length ? `<div class="system-step__links">${stage.links.map((output) => systemOutputLink(output, language)).join(' · ')}</div>` : ''}</article>`).join('');
        const equipment = system.equipment.map((output) => technologyOutputCard(output, language)).join('');
        const pagination = [
          system.previous && `<a href="${systemUrl(system.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(system.previous.title)}</strong></a>`,
          system.next && `<a href="${systemUrl(system.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(system.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = system.equipment.find((output) => output.texture);
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(system.title)}</h1>
          <div class="article-layout" style="--system-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(system.title)}</strong> — ${escapeHtml(system.intro)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#system-facts">${labels.facts}</a></li><li><a href="#system-setup">${labels.setup}</a></li><li><a href="#system-equipment">${labels.equipment}</a></li><li><a href="#system-tips">${labels.tips}</a></li></ol></nav>
              <section class="biome-section" id="system-facts"><h2>${labels.facts}</h2><div class="system-facts">${facts}</div></section>
              <section class="biome-section" id="system-setup"><h2>${labels.setup}</h2><div class="system-steps">${stages}</div></section>
              <section class="biome-section" id="system-equipment"><h2>${labels.equipment}</h2><div class="technology-output-grid">${equipment}</div></section>
              <section class="biome-section" id="system-tips"><h2>${labels.tips}</h2><ul class="system-tips">${system.tips.map((tip) => `<li>${escapeHtml(tip)}</li>`).join('')}</ul></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(system.title)}</h2>${icon ? itemIcon(icon, 112) : `<span class="system-mark" style="margin:7px auto 12px;--system-color:${color}">${escapeHtml(system.title.slice(0, 1))}</span>`}<p class="infobox-caption">${escapeHtml(system.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.setup}</dt><dd>${system.stageCount}</dd></div><div><dt>${labels.related}</dt><dd>${system.equipmentCount}</dd></div></dl></aside>
          </div>`;
        document.title = `${system.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`systems/${encodeURIComponent(system.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function fluidUrl(fluidId, language) {
      return `/${language}/fluids/${encodeURIComponent(fluidId)}`;
    }

    function fluidSwatch(fluid, size = 44) {
      return `<span class="fluid-swatch" style="--fluid-size:${size}px;--fluid-color:${systemColor(fluid)}" aria-hidden="true"><span>${escapeHtml(fluid.title.slice(0, 1))}</span></span>`;
    }

    function fluidRecipePart(part, language, labels) {
      const amount = Number.isInteger(part.amount) ? part.amount : Number(part.amount).toLocaleString(language, { maximumFractionDigits: 2 });
      if (part.type === 'fluid') return `<span class="fluid-part"><span class="fluid-dot" style="--fluid-color:${systemColor(part)}"></span><a href="${fluidUrl(part.id, language)}">${escapeHtml(part.title)}</a> ${amount} L</span>`;
      if (part.type === 'energy') return `<span class="fluid-part"><span class="fluid-dot" style="--fluid-color:${systemColor(part)}"></span>${escapeHtml(part.title)} ${amount} EU</span>`;
      const title = part.exists ? `<a href="${itemUrl(part.id, language)}">${escapeHtml(part.title)}</a>` : escapeHtml(part.title);
      return `<span class="fluid-part">${title} × ${amount}${part.catalyst ? ` (${labels.catalyst})` : ''}</span>`;
    }

    function fluidRecipeCard(recipe, language, labels) {
      const inputs = recipe.inputs.map((part) => fluidRecipePart(part, language, labels)).join('');
      const outputs = recipe.outputs.map((part) => fluidRecipePart(part, language, labels)).join('');
      const metadata = [
        recipe.processTime !== null && `${labels.time}: ${recipe.processTime} ${language === 'ru' ? 'с' : 's'}`,
        recipe.power !== null && `${labels.power}: ${recipe.power} EU/${language === 'ru' ? 'с' : 's'}`,
        recipe.note,
      ].filter(Boolean).join(' · ');
      return `<article class="fluid-recipe">${itemIcon(recipe.machine, 54)}<div><h3><a href="${machineUrl(recipe.machine.id, language)}">${escapeHtml(recipe.machine.title)}</a></h3><div class="fluid-flow">${inputs || (recipe.note ? `<span class="fluid-part">${escapeHtml(recipe.note)}</span>` : '—')}<span class="fluid-arrow">→</span>${outputs || '—'}</div>${metadata ? `<small>${escapeHtml(metadata)}</small>` : ''}</div></article>`;
    }

    async function renderFluidCatalog(language) {
      const labels = fluidUi[language];
      const article = document.querySelector('#fluid-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/fluids`);
        const groups = new Map();
        data.fluids.forEach((fluid) => {
          if (!groups.has(fluid.category)) groups.set(fluid.category, { title: fluid.categoryTitle, fluids: [] });
          groups.get(fluid.category).fluids.push(fluid);
        });
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="catalog-toolbar"><input id="fluid-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="fluid-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.fluids}</span></div>
          <div>${[...groups.values()].map((group) => `<section class="catalog-section" data-fluid-section><h2>${escapeHtml(group.title)}</h2><div class="fluid-grid">${group.fluids.map((fluid) => `<a class="fluid-card" data-fluid-card data-search="${escapeHtml(`${fluid.title} ${fluid.id} ${fluid.categoryTitle}`.toLocaleLowerCase(language))}" href="${fluidUrl(fluid.id, language)}">${fluidSwatch(fluid, 48)}<span><strong>${escapeHtml(fluid.title)}</strong><small>${escapeHtml(fluid.id)}</small><small>${fluid.sourceCount} ${labels.sources.toLocaleLowerCase(language)} · ${fluid.useCount} ${labels.uses.toLocaleLowerCase(language)}</small></span></a>`).join('')}</div></section>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('fluids');
        const filter = article.querySelector('#fluid-filter');
        const count = article.querySelector('#fluid-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-fluid-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          article.querySelectorAll('[data-fluid-section]').forEach((section) => { section.hidden = !section.querySelector('[data-fluid-card]:not([hidden])'); });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.fluids}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderFluidArticle(language, fluidId) {
      const labels = fluidUi[language];
      const article = document.querySelector('#fluid-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/fluids/${encodeURIComponent(fluidId)}`);
        const fluid = data.fluid;
        const sources = fluid.sources.map((recipe) => fluidRecipeCard(recipe, language, labels)).join('');
        const uses = fluid.uses.map((recipe) => fluidRecipeCard(recipe, language, labels)).join('');
        const pagination = [
          fluid.previous && `<a href="${fluidUrl(fluid.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(fluid.previous.title)}</strong></a>`,
          fluid.next && `<a href="${fluidUrl(fluid.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(fluid.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(fluid.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(fluid.title)}</strong> — ${escapeHtml(fluid.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#fluid-overview">${labels.overview}</a></li><li><a href="#fluid-production">${labels.production}</a></li><li><a href="#fluid-usage">${labels.usage}</a></li></ol></nav>
              <section class="biome-section" id="fluid-overview"><h2>${labels.overview}</h2><p>${escapeHtml(fluid.description)}</p></section>
              <section class="biome-section" id="fluid-production"><h2>${labels.production}</h2>${sources ? `<div class="fluid-recipes">${sources}</div>` : `<p class="empty-section">${labels.noSources}</p>`}</section>
              <section class="biome-section" id="fluid-usage"><h2>${labels.usage}</h2>${uses ? `<div class="fluid-recipes">${uses}</div>` : `<p class="empty-section">${labels.noUses}</p>`}</section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox"><h2>${escapeHtml(fluid.title)}</h2>${fluidSwatch(fluid, 112)}<p class="infobox-caption">${escapeHtml(fluid.description)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.category}</dt><dd>${escapeHtml(fluid.categoryTitle)}</dd></div><div><dt>${labels.sources}</dt><dd>${fluid.sourceCount}</dd></div><div><dt>${labels.uses}</dt><dd>${fluid.useCount}</dd></div><div><dt>ID</dt><dd>${escapeHtml(fluid.id)}</dd></div></dl></aside>
          </div>`;
        document.title = `${fluid.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`fluids/${encodeURIComponent(fluid.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function achievementUrl(achievementId, language) {
      return `/${language}/achievements/${encodeURIComponent(achievementId)}`;
    }

    function achievementEmblem(achievement, size = 48) {
      return `<span class="achievement-emblem" style="--achievement-color:${systemColor(achievement)};width:${size + 10}px;height:${size + 10}px" aria-hidden="true">${itemIcon(achievement.icon, size)}</span>`;
    }

    async function renderAchievementCatalog(language) {
      const labels = achievementUi[language];
      const article = document.querySelector('#achievement-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/achievements`);
        const groups = data.categories.map((category) => {
          const entries = data.achievements.filter((achievement) => achievement.category === category.id);
          const color = entries[0] ? systemColor(entries[0]) : '#318db8';
          return `<section class="achievement-group" data-achievement-group style="--achievement-color:${color}"><h2>${escapeHtml(category.title)} · ${category.count}</h2><div class="achievement-grid">${entries.map((achievement) => {
            const search = `${achievement.title} ${achievement.description} ${achievement.requirement} ${achievement.id} ${achievement.categoryTitle}`.toLocaleLowerCase(language);
            return `<a class="achievement-card" data-achievement-card data-search="${escapeHtml(search)}" href="${achievementUrl(achievement.id, language)}">${achievementEmblem(achievement)}<span><h3>${escapeHtml(achievement.title)}</h3><p>${escapeHtml(achievement.description)}</p><small>${escapeHtml(achievement.id)}</small></span></a>`;
          }).join('')}</div></section>`;
        }).join('');
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro}</p>
          <div class="catalog-toolbar"><input id="achievement-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="achievement-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.achievements}</span></div>
          <div class="achievement-groups">${groups}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('achievements');
        const filter = article.querySelector('#achievement-filter');
        const count = article.querySelector('#achievement-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-achievement-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          article.querySelectorAll('[data-achievement-group]').forEach((group) => { group.hidden = !group.querySelector('[data-achievement-card]:not([hidden])'); });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.achievements}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderAchievementArticle(language, achievementId) {
      const labels = achievementUi[language];
      const article = document.querySelector('#achievement-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/achievements/${encodeURIComponent(achievementId)}`);
        const achievement = data.achievement;
        const color = systemColor(achievement);
        const related = achievement.related.map((entry) => `<a href="${escapeHtml(entry.url)}">${escapeHtml(entry.title)}</a>`).join('');
        const pagination = [
          achievement.previous && `<a href="${achievementUrl(achievement.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(achievement.previous.title)}</strong></a>`,
          achievement.next && `<a href="${achievementUrl(achievement.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(achievement.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = achievement.icon.exists === false
          ? achievementEmblem(achievement, 96)
          : `<a href="${itemUrl(achievement.icon.id, language)}">${achievementEmblem(achievement, 96)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(achievement.title)}</h1>
          <div class="article-layout" style="--achievement-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(achievement.title)}</strong> — ${escapeHtml(achievement.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#achievement-overview">${labels.overview}</a></li><li><a href="#achievement-requirement">${labels.requirement}</a></li><li><a href="#achievement-related">${labels.related}</a></li><li><a href="#achievement-tracking">${labels.tracking}</a></li></ol></nav>
              <section class="biome-section" id="achievement-overview"><h2>${labels.overview}</h2><p>${escapeHtml(achievement.description)}</p></section>
              <section class="biome-section" id="achievement-requirement"><h2>${labels.requirement}</h2><p class="achievement-requirement">${escapeHtml(achievement.requirement)}</p></section>
              <section class="biome-section" id="achievement-related"><h2>${labels.related}</h2><div class="achievement-related">${related}</div></section>
              <section class="biome-section" id="achievement-tracking"><h2>${labels.tracking}</h2><table class="wiki-data-table"><tbody><tr><th>${labels.automaticCheck}</th><td>${escapeHtml(achievement.check)}</td></tr><tr><th>${labels.profileStorage}</th><td>${escapeHtml(achievement.storage)}</td></tr></tbody></table></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(achievement.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(achievement.description)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.category}</dt><dd>${escapeHtml(achievement.categoryTitle)}</dd></div><div><dt>${labels.emblem}</dt><dd>${achievement.icon.exists === false ? escapeHtml(achievement.icon.title) : `<a href="${itemUrl(achievement.icon.id, language)}">${escapeHtml(achievement.icon.title)}</a>`}</dd></div><div><dt>${labels.identifier}</dt><dd>${escapeHtml(achievement.id)}</dd></div></dl></aside>
          </div>`;
        document.title = `${achievement.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`achievements/${encodeURIComponent(achievement.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function mechanicUrl(mechanicId, language) {
      return `/${language}/mechanics/${encodeURIComponent(mechanicId)}`;
    }

    function mechanicLink(link) {
      return link.exists === false ? `<span>${escapeHtml(link.title)}</span>` : `<a href="${escapeHtml(link.url)}">${escapeHtml(link.title)}</a>`;
    }

    async function renderMechanicCatalog(language) {
      const labels = mechanicUi[language];
      const article = document.querySelector('#mechanic-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/mechanics`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.mechanics.map((mechanic) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(mechanic)}" href="${mechanicUrl(mechanic.id, language)}"><span class="mechanic-mark">${itemIcon(mechanic.icon, 54)}</span><span><h2>${escapeHtml(mechanic.title)}</h2><p>${escapeHtml(mechanic.description)}</p><small>${escapeHtml(mechanic.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('mechanics');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderMechanicArticle(language, mechanicId) {
      const labels = mechanicUi[language];
      const article = document.querySelector('#mechanic-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/mechanics/${encodeURIComponent(mechanicId)}`);
        const mechanic = data.mechanic;
        const color = systemColor(mechanic);
        const facts = mechanic.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = mechanic.sections.map((section, sectionIndex) => `<section class="biome-section" id="mechanic-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(mechanic.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          mechanic.previous && `<a href="${mechanicUrl(mechanic.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(mechanic.previous.title)}</strong></a>`,
          mechanic.next && `<a href="${mechanicUrl(mechanic.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(mechanic.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(mechanic.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(mechanic.title)}</strong> — ${escapeHtml(mechanic.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#mechanic-values">${labels.keyValues}</a></li>${mechanic.sections.map((section, index) => `<li><a href="#mechanic-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#mechanic-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="mechanic-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="mechanic-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(mechanic.title)}</h2><a href="${itemUrl(mechanic.icon.id, language)}">${itemIcon(mechanic.icon, 112)}</a><p class="infobox-caption">${escapeHtml(mechanic.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${mechanic.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${mechanic.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`mechanics/${encodeURIComponent(mechanic.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function gatheringUrl(guideId, language) {
      return `/${language}/gathering/${encodeURIComponent(guideId)}`;
    }

    async function renderGatheringCatalog(language) {
      const labels = gatheringUi[language];
      const article = document.querySelector('#gathering-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/gathering`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.gathering.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${gatheringUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('gathering');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderGatheringArticle(language, guideId) {
      const labels = gatheringUi[language];
      const article = document.querySelector('#gathering-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/gathering/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const renderGatheringEntry = (entry) => {
          if (entry.stats?.length) {
            const heading = entry.icon?.url
              ? `<a class="ore-entry__icon" href="${escapeHtml(entry.icon.url)}">${itemIcon(entry.icon, 48)}</a>`
              : `<span class="ore-entry__icon">${itemIcon(entry.icon, 48)}</span>`;
            return `<article class="mechanic-entry ore-entry">
              <header class="ore-entry__header">${heading}<div><h3>${entry.icon?.url ? `<a href="${escapeHtml(entry.icon.url)}">${escapeHtml(entry.title)}</a>` : escapeHtml(entry.title)}</h3><span class="ore-frequency">${escapeHtml(entry.value)}</span></div></header>
              <div class="ore-stats">${entry.stats.map((stat) => `<div class="ore-stat"><strong>${escapeHtml(stat.label)}</strong><span>${escapeHtml(stat.value)}</span></div>`).join('')}</div>
              ${entry.links.length ? `<div class="mechanic-links"><span>${escapeHtml(entry.locationLabel)}:</span>${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}
            </article>`;
          }
          return `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`;
        };
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="gathering-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries${section.entries.some((entry) => entry.stats?.length) ? ' is-ore-catalog' : ''}">${section.entries.map((entry) => renderGatheringEntry(entry)).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${gatheringUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${gatheringUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#gathering-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#gathering-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#gathering-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="gathering-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="gathering-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`gathering/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function interfaceUrl(guideId, language) {
      return `/${language}/interface/${encodeURIComponent(guideId)}`;
    }

    async function renderInterfaceCatalog(language) {
      const labels = interfaceUi[language];
      const article = document.querySelector('#interface-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/interface`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${interfaceUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('interface');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderInterfaceArticle(language, guideId) {
      const labels = interfaceUi[language];
      const article = document.querySelector('#interface-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/interface/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="interface-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${interfaceUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${interfaceUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#interface-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#interface-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#interface-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="interface-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="interface-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`interface/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function explorationUrl(guideId, language) {
      return `/${language}/exploration/${encodeURIComponent(guideId)}`;
    }

    async function renderExplorationCatalog(language) {
      const labels = explorationUi[language];
      const article = document.querySelector('#exploration-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/exploration`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${explorationUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('exploration');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderExplorationArticle(language, guideId) {
      const labels = explorationUi[language];
      const article = document.querySelector('#exploration-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/exploration/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="exploration-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${explorationUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${explorationUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#exploration-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#exploration-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#exploration-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="exploration-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="exploration-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`exploration/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function optimizationUrl(guideId, language) {
      return `/${language}/optimization/${encodeURIComponent(guideId)}`;
    }

    async function renderOptimizationCatalog(language) {
      const labels = optimizationUi[language];
      const article = document.querySelector('#optimization-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/optimization`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${optimizationUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('optimization');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderOptimizationArticle(language, guideId) {
      const labels = optimizationUi[language];
      const article = document.querySelector('#optimization-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/optimization/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="optimization-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${optimizationUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${optimizationUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#optimization-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#optimization-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#optimization-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="optimization-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="optimization-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`optimization/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function multiplayerUrl(guideId, language) {
      return `/${language}/multiplayer/${encodeURIComponent(guideId)}`;
    }

    async function renderMultiplayerCatalog(language) {
      const labels = multiplayerUi[language];
      const article = document.querySelector('#multiplayer-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/multiplayer`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${multiplayerUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('multiplayer');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderMultiplayerArticle(language, guideId) {
      const labels = multiplayerUi[language];
      const article = document.querySelector('#multiplayer-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/multiplayer/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="multiplayer-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${multiplayerUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${multiplayerUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#multiplayer-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#multiplayer-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#multiplayer-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="multiplayer-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="multiplayer-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`multiplayer/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function energyUrl(guideId, language) {
      return `/${language}/energy/${encodeURIComponent(guideId)}`;
    }

    async function renderEnergyCatalog(language) {
      const labels = energyUi[language];
      const article = document.querySelector('#energy-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/energy`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${energyUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('energy');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderEnergyArticle(language, guideId) {
      const labels = energyUi[language];
      const article = document.querySelector('#energy-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/energy/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="energy-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${energyUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${energyUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#energy-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#energy-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#energy-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="energy-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="energy-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`energy/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function logisticsUrl(guideId, language) {
      return `/${language}/logistics/${encodeURIComponent(guideId)}`;
    }

    async function renderLogisticsCatalog(language) {
      const labels = logisticsUi[language];
      const article = document.querySelector('#logistics-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/logistics`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${logisticsUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('logistics');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderLogisticsArticle(language, guideId) {
      const labels = logisticsUi[language];
      const article = document.querySelector('#logistics-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/logistics/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="logistics-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${logisticsUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${logisticsUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#logistics-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#logistics-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#logistics-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="logistics-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="logistics-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`logistics/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function steamUrl(guideId, language) {
      return `/${language}/steam/${encodeURIComponent(guideId)}`;
    }

    async function renderSteamCatalog(language) {
      const labels = steamUi[language];
      const article = document.querySelector('#steam-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/steam`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${steamUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('steam');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderSteamArticle(language, guideId) {
      const labels = steamUi[language];
      const article = document.querySelector('#steam-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/steam/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="steam-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${steamUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${steamUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#steam-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#steam-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#steam-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="steam-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="steam-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`steam/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function oreProcessingUrl(guideId, language) {
      return `/${language}/ore-processing/${encodeURIComponent(guideId)}`;
    }

    async function renderOreProcessingCatalog(language) {
      const labels = oreProcessingUi[language];
      const article = document.querySelector('#ore-processing-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/ore-processing`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.guides}.</p>
          <div class="mechanic-grid">${data.guides.map((guide) => `
            <a class="mechanic-card" style="--mechanic-color:${systemColor(guide)}" href="${oreProcessingUrl(guide.id, language)}"><span class="mechanic-mark">${itemIcon(guide.icon, 54)}</span><span><h2>${escapeHtml(guide.title)}</h2><p>${escapeHtml(guide.description)}</p><small>${escapeHtml(guide.subtitle)}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('ore-processing');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderOreProcessingArticle(language, guideId) {
      const labels = oreProcessingUi[language];
      const article = document.querySelector('#ore-processing-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/ore-processing/${encodeURIComponent(guideId)}`);
        const guide = data.guide;
        const color = systemColor(guide);
        const facts = guide.facts.map((fact) => `<article class="mechanic-fact"><strong>${escapeHtml(fact.label)}</strong><span>${escapeHtml(fact.value)}</span></article>`).join('');
        const sections = guide.sections.map((section, sectionIndex) => `<section class="biome-section" id="ore-processing-section-${sectionIndex}"><h2>${escapeHtml(section.title)}</h2><p>${escapeHtml(section.intro)}</p><div class="mechanic-entries">${section.entries.map((entry) => `<article class="mechanic-entry"><h3>${escapeHtml(entry.title)}</h3>${entry.text ? `<p>${escapeHtml(entry.text)}</p>` : ''}${entry.value ? `<strong>${escapeHtml(entry.value)}</strong>` : ''}${entry.links.length ? `<div class="mechanic-links">${entry.links.map((link) => mechanicLink(link)).join(' · ')}</div>` : ''}</article>`).join('')}</div></section>`).join('');
        const related = [...new Map(guide.related.map((entry) => [entry.url, entry])).values()];
        const pagination = [
          guide.previous && `<a href="${oreProcessingUrl(guide.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(guide.previous.title)}</strong></a>`,
          guide.next && `<a href="${oreProcessingUrl(guide.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(guide.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const icon = guide.icon.exists === false ? itemIcon(guide.icon, 112) : `<a href="${escapeHtml(guide.icon.url)}">${itemIcon(guide.icon, 112)}</a>`;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(guide.title)}</h1>
          <div class="article-layout" style="--mechanic-color:${color}">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(guide.title)}</strong> — ${escapeHtml(guide.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#ore-processing-values">${labels.keyValues}</a></li>${guide.sections.map((section, index) => `<li><a href="#ore-processing-section-${index}">${escapeHtml(section.title)}</a></li>`).join('')}<li><a href="#ore-processing-related">${labels.related}</a></li></ol></nav>
              <section class="biome-section" id="ore-processing-values"><h2>${labels.keyValues}</h2><div class="mechanic-facts">${facts}</div></section>
              ${sections}
              <section class="biome-section" id="ore-processing-related"><h2>${labels.related}</h2><div class="achievement-related">${related.map((entry) => mechanicLink(entry)).join('')}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox item-infobox"><h2>${escapeHtml(guide.title)}</h2>${icon}<p class="infobox-caption">${escapeHtml(guide.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.type}</dt><dd>${labels.guide}</dd></div><div><dt>${labels.sections}</dt><dd>${guide.sections.length}</dd></div><div><dt>${labels.links}</dt><dd>${related.length}</dd></div></dl></aside>
          </div>`;
        document.title = `${guide.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`ore-processing/${encodeURIComponent(guide.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function questAgeUrl(age, language) {
      return `/${language}/quests/${age}`;
    }

    function questTargetLink(target, language) {
      if (!target) return '';
      const urls = { item: itemUrl(target.id, language), machine: machineUrl(target.id, language), boss: bossUrl(target.id, language) };
      return `<a href="${urls[target.type]}">${escapeHtml(target.title)}</a>`;
    }

    async function renderQuestCatalog(language) {
      const labels = questUi[language];
      const article = document.querySelector('#quest-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/quests`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.count} ${labels.quests}.</p>
          <div class="quest-age-grid">${data.ages.map((age) => `
            <a class="quest-age-card" href="${questAgeUrl(age.age, language)}"><span class="quest-age-number">${age.age}</span><span><h2>${escapeHtml(age.title)}</h2><p>${escapeHtml(age.subtitle)}</p><small>${age.chapterCount} ${labels.chapters} · ${age.questCount} ${labels.quests}${age.tutorialCount ? ` · ${age.tutorialCount} ${labels.tutorials}` : ''}</small></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('quests');
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderQuestAge(language, ageNumber) {
      const labels = questUi[language];
      const article = document.querySelector('#quest-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/quests/${encodeURIComponent(ageNumber)}`);
        const age = data.age;
        const chapters = age.chapters.map((chapter, chapterIndex) => `
          <section class="quest-chapter" data-quest-chapter><h2 id="quest-chapter-${chapterIndex}">${escapeHtml(chapter.title)}</h2><div class="quest-list">${chapter.quests.map((quest) => {
            const objectives = quest.objectives.map((objective) => `<li>${escapeHtml(objective.description)}${objective.count > 1 ? ` × ${objective.count}` : ''}${objective.target ? ` — ${questTargetLink(objective.target, language)}` : ''}</li>`).join('');
            const unlocks = quest.unlocks.map((unlock) => `<li>${escapeHtml(unlock)}</li>`).join('');
            const prerequisites = quest.prerequisites.map((id) => `<code>${escapeHtml(id)}</code>`).join(', ');
            const search = `${quest.title} ${quest.description} ${quest.id} ${chapter.title}`.toLocaleLowerCase(language);
            return `<details class="quest-card" data-quest-card data-search="${escapeHtml(search)}"><summary><span><strong>${escapeHtml(quest.title)}${quest.tutorial ? `<span class="quest-badge">${labels.tutorial}</span>` : ''}</strong><small>${escapeHtml(quest.id)}</small></span></summary><div class="quest-card__body"><p>${escapeHtml(quest.description)}</p><h3>${labels.objectives}</h3><ol class="quest-objectives">${objectives}</ol>${unlocks ? `<h3>${labels.unlocks}</h3><ul class="quest-objectives">${unlocks}</ul>` : ''}${prerequisites ? `<h3>${labels.prerequisites}</h3><p>${prerequisites}</p>` : ''}</div></details>`;
          }).join('')}</div></section>`).join('');
        const previousAge = age.age > 1 ? age.age - 1 : null;
        const nextAge = age.age < 6 ? age.age + 1 : null;
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(age.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description">${escapeHtml(age.subtitle)}</p>
              <div class="catalog-toolbar"><input id="quest-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="quest-count">${labels.shown} ${age.questCount} ${labels.of} ${age.questCount} ${labels.quests}</span></div>
              ${chapters}
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${previousAge ? `<a href="${questAgeUrl(previousAge, language)}"><small>← ${labels.previous}</small><strong>${previousAge}</strong></a>` : ''}${nextAge ? `<a href="${questAgeUrl(nextAge, language)}"><small>${labels.next} →</small><strong>${nextAge}</strong></a>` : ''}</nav>
            </div>
            <aside class="infobox"><h2>${escapeHtml(age.title)}</h2><img src="/assets/textures/items/placeholders/misc/codex.png" alt=""><p class="infobox-caption">${escapeHtml(age.subtitle)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.age}</dt><dd>${age.age} / 6</dd></div><div><dt>${labels.chapterCount}</dt><dd>${age.chapterCount}</dd></div><div><dt>${labels.questCount}</dt><dd>${age.questCount}</dd></div>${age.tutorialCount ? `<div><dt>${labels.tutorial}</dt><dd>${age.tutorialCount}</dd></div>` : ''}</dl></aside>
          </div>`;
        document.title = `${age.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`quests/${age.age}`);
        const filter = article.querySelector('#quest-filter');
        const count = article.querySelector('#quest-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-quest-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          article.querySelectorAll('[data-quest-chapter]').forEach((chapter) => { chapter.hidden = !chapter.querySelector('[data-quest-card]:not([hidden])'); });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${age.questCount} ${labels.quests}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function npcUrl(npcId, language) {
      return `/${language}/npcs/${encodeURIComponent(npcId)}`;
    }

    function npcColor(npc) {
      const color = npc.color ?? [0.2, 0.58, 0.36, 1];
      return `rgba(${Math.round(color[0] * 255)},${Math.round(color[1] * 255)},${Math.round(color[2] * 255)},${color[3] ?? 1})`;
    }

    async function renderNpcCatalog(language) {
      const labels = npcUi[language];
      const article = document.querySelector('#npc-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/npcs`);
        article.innerHTML = `
          <h1 class="article-heading">${labels.catalogTitle}</h1>
          <p class="catalog-intro">${labels.catalogIntro} ${data.questCount} ${labels.quests}.</p>
          <div class="catalog-toolbar"><input id="npc-filter" data-catalog-filter type="search" placeholder="${labels.search}" aria-label="${labels.search}"><span class="catalog-count" id="npc-count">${labels.shown} ${data.count} ${labels.of} ${data.count} ${labels.characters}</span></div>
          <div class="boss-grid">${data.npcs.map((npc) => `<a class="boss-card" data-npc-card data-search="${escapeHtml(`${npc.title} ${npc.role} ${npc.biome?.title ?? ''} ${npc.id}`.toLocaleLowerCase(language))}" href="${npcUrl(npc.id, language)}">${bossPortrait(npc, 82)}<span><h2>${escapeHtml(npc.title)}</h2><p>${escapeHtml(npc.role)} · ${escapeHtml(npc.biome?.title ?? '')}</p><p>${npc.questCount} ${labels.quests}</p></span></a>`).join('')}</div>`;
        document.title = `${labels.catalogTitle} — InfiniteForge Wiki`;
        updateLanguageLinks('npcs');
        const filter = article.querySelector('#npc-filter');
        const count = article.querySelector('#npc-count');
        const applyFilter = () => {
          const query = filter.value.trim().toLocaleLowerCase(language);
          let visible = 0;
          article.querySelectorAll('[data-npc-card]').forEach((card) => {
            card.hidden = query !== '' && !card.dataset.search.includes(query);
            if (!card.hidden) visible += 1;
          });
          count.textContent = `${labels.shown} ${visible} ${labels.of} ${data.count} ${labels.characters}`;
        };
        filter.addEventListener('input', applyFilter);
        const query = new URLSearchParams(window.location.search).get('q');
        if (query) { filter.value = query; applyFilter(); }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    async function renderNpcArticle(language, npcId) {
      const labels = npcUi[language];
      const article = document.querySelector('#npc-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/npcs/${encodeURIComponent(npcId)}`);
        const npc = data.npc;
        const quests = npc.quests.map((quest) => {
          const objectives = quest.objectives.map((objective) => `<li>${escapeHtml(objective.description)}${objective.count > 1 ? ` × ${objective.count}` : ''}${objective.target ? ` — ${questTargetLink(objective.target, language)}` : ''}</li>`).join('');
          const rewards = quest.rewards.map((reward) => bossItemMarkup(reward, language)).join('');
          const unlocks = quest.unlocks.length ? `<ul class="quest-objectives">${quest.unlocks.map((unlock) => `<li>${escapeHtml(unlock)}</li>`).join('')}</ul>` : `<p class="empty-section">${labels.noUnlocks}</p>`;
          return `<article class="npc-quest" data-npc-quest="${escapeHtml(quest.id)}"><h3>${escapeHtml(quest.title)}</h3><p>${escapeHtml(quest.description)}</p><h4>${labels.objectives}</h4><ol class="quest-objectives">${objectives}</ol><h4>${labels.rewards}</h4><div class="npc-rewards">${rewards}</div><h4>${labels.unlocks}</h4>${unlocks}</article>`;
        }).join('');
        const pagination = [
          npc.previous && `<a href="${npcUrl(npc.previous.id, language)}"><small>← ${labels.previous}</small><strong>${escapeHtml(npc.previous.title)}</strong></a>`,
          npc.next && `<a href="${npcUrl(npc.next.id, language)}"><small>${labels.next} →</small><strong>${escapeHtml(npc.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        const color = npcColor(npc);
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(npc.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="item-description"><strong>${escapeHtml(npc.title)}</strong> — ${escapeHtml(npc.role)}.</p>
              <blockquote class="npc-greeting" style="--npc-color:${color}">«${escapeHtml(npc.greeting)}»</blockquote>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#npc-overview">${labels.overview}</a></li><li><a href="#npc-location">${labels.location}</a></li><li><a href="#npc-quests">${labels.questChain}</a></li></ol></nav>
              <section class="biome-section" id="npc-overview"><h2>${labels.overview}</h2><table class="wiki-data-table"><tbody><tr><th>${labels.role}</th><td>${escapeHtml(npc.role)}</td></tr><tr><th>${labels.greeting}</th><td>${escapeHtml(npc.greeting)}</td></tr></tbody></table></section>
              <section class="biome-section" id="npc-location"><h2>${labels.location}</h2><p>${labels.biome}: ${npc.biome ? `<a href="/${language}/worlds/overworld/biomes/${npc.biome.id}">${escapeHtml(npc.biome.title)}</a>` : '—'}.</p></section>
              <section class="biome-section" id="npc-quests"><h2>${labels.questChain}</h2><div class="npc-quest-chain" style="--npc-color:${color}">${quests}</div></section>
              <nav class="article-pagination" aria-label="${labels.catalogTitle}">${pagination}</nav>
            </div>
            <aside class="infobox boss-infobox"><h2>${escapeHtml(npc.title)}</h2>${bossPortrait(npc, 112)}<p class="infobox-caption">${escapeHtml(npc.greeting)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.role}</dt><dd>${escapeHtml(npc.role)}</dd></div><div><dt>${labels.biome}</dt><dd>${npc.biome ? `<a href="/${language}/worlds/overworld/biomes/${npc.biome.id}">${escapeHtml(npc.biome.title)}</a>` : '—'}</dd></div><div><dt>${labels.sideQuests}</dt><dd>${npc.questCount}</dd></div></dl></aside>
          </div>`;
        document.title = `${npc.title} — InfiniteForge Wiki`;
        const query = new URLSearchParams(window.location.search).get('q');
        updateLanguageLinks(`npcs/${encodeURIComponent(npc.id)}${query ? `?q=${encodeURIComponent(query)}` : ''}`);
        if (query) {
          const target = [...article.querySelectorAll('[data-npc-quest]')].find((element) => element.dataset.npcQuest === query);
          if (target) {
            target.classList.add('is-target');
            window.requestAnimationFrame(() => target.scrollIntoView({ block: 'start' }));
          }
        }
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function searchResultIcon(result) {
      if (result.texture) return itemIcon(result, 56);
      if (result.portrait || result.color) return bossPortrait(result, 56);
      if (result.image) return `<span class="search-result__icon" aria-hidden="true"><img src="${escapeHtml(result.image)}" alt=""></span>`;
      return `<span class="search-result__icon" aria-hidden="true">${escapeHtml(result.title.slice(0, 1))}</span>`;
    }

    async function renderSearchPage(language) {
      const labels = searchUi[language];
      const article = document.querySelector('#search-page');
      const query = new URLSearchParams(window.location.search).get('q')?.trim() ?? '';
      showArticlePage(article);
      searchInput.value = query;
      const form = `<form class="search-page-form" action="/${language}/search" method="get"><input name="q" type="search" value="${escapeHtml(query)}" placeholder="${labels.input}" aria-label="${labels.input}" autofocus><button type="submit">${labels.button}</button></form>`;
      if (!query) {
        article.innerHTML = `<h1 class="article-heading">${labels.title}</h1><p class="catalog-intro">${labels.intro}</p>${form}<p class="loading-message">${labels.prompt}</p>`;
        document.title = `${labels.title} — InfiniteForge Wiki`;
        updateLanguageLinks('search');
        return;
      }
      article.innerHTML = `<h1 class="article-heading">${labels.title}</h1><p class="catalog-intro">${labels.intro}</p>${form}<p class="loading-message">${labels.loading}</p>`;
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/search?q=${encodeURIComponent(query)}`);
        if (!data.results.length) {
          article.innerHTML = `<h1 class="article-heading">${labels.title}</h1><p class="catalog-intro">${labels.intro}</p>${form}<p class="loading-message">${labels.noResults}</p>`;
        } else {
          const groups = new Map();
          data.results.forEach((result) => {
            if (!groups.has(result.type)) groups.set(result.type, []);
            groups.get(result.type).push(result);
          });
          const summary = data.total > data.count
            ? `${labels.found} ${data.total} ${labels.results}. ${labels.showing} ${data.count}.`
            : `${labels.found} ${data.total} ${labels.results}.`;
          const groupMarkup = [...groups.entries()].map(([type, results]) => {
            return `<section class="search-group"><h2>${labels.types[type]} · ${results.length}</h2><div class="search-results-grid">${results.map((result) => `<a class="search-result" href="${escapeHtml(result.url)}">${searchResultIcon(result)}<span><strong>${escapeHtml(result.title)}</strong><p>${escapeHtml(result.description)}</p><small>${escapeHtml(result.meta || result.id)}</small></span></a>`).join('')}</div></section>`;
          }).join('');
          article.innerHTML = `<h1 class="article-heading">${labels.title}</h1><p class="catalog-intro">${labels.intro}</p>${form}<p class="search-summary">${summary}</p>${groupMarkup}`;
        }
        document.title = `${query} — ${labels.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`search?q=${encodeURIComponent(query)}`);
      } catch (error) {
        article.innerHTML = `<h1 class="article-heading">${labels.title}</h1><p class="catalog-intro">${labels.intro}</p>${form}<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function renderGettingStarted(language) {
      const content = gettingStartedContent[language];
      const article = document.querySelector('#guide-page');
      article.innerHTML = `
        <h1 class="article-heading">${content.title}</h1>
        <div class="article-layout">
          <div class="article-copy">
            <p class="item-description">${content.intro}</p>
            <nav class="table-of-contents" aria-label="${content.contents}"><strong>${content.contents}</strong><ol><li><a href="#guide-checklist">${content.checklist}</a></li><li><a href="#guide-factory">${content.factory}</a></li><li><a href="#guide-exploration">${content.exploration}</a></li><li><a href="#guide-progression">${content.progression}</a></li></ol></nav>
            <section class="biome-section" id="guide-checklist"><h2>${content.checklist}</h2><div class="guide-steps">${content.steps.map(([title, text]) => `<article class="guide-step"><h3>${title}</h3><p>${text}</p></article>`).join('')}</div></section>
            <section class="biome-section" id="guide-factory"><h2>${content.factory}</h2><p>${language === 'ru' ? `Начните с <a href="${machineUrl('furnace', language)}">печи</a> и <a href="${machineUrl('primitive_crusher', language)}">примитивной дробилки</a>. Следующая устойчивая цель — связать воду, <a href="${machineUrl('steam_boiler', language)}">паровой котёл</a>, машины и хранилище трубами и конвейерами.` : `Begin with a <a href="${machineUrl('furnace', language)}">furnace</a> and <a href="${machineUrl('primitive_crusher', language)}">primitive crusher</a>. Your next stable goal is to connect water, a <a href="${machineUrl('steam_boiler', language)}">steam boiler</a>, machines, and storage with pipes and conveyors.`}</p></section>
            <section class="biome-section" id="guide-exploration"><h2>${content.exploration}</h2><p>${language === 'ru' ? `Первую базу безопаснее строить в <a href="/${language}/worlds/overworld/biomes/forest">центральном лесу</a>. Изучите его мобов и подготовьтесь к <a href="${bossUrl('ent', language)}">Энту</a>. Каждый следующий босс открывает рецепт защиты для нового опасного биома.` : `Build your first base in the safe <a href="/${language}/worlds/overworld/biomes/forest">central forest</a>. Learn its mobs and prepare for the <a href="${bossUrl('ent', language)}">Ent</a>. Each later boss unlocks the protection recipe for a new hazardous biome.`}</p></section>
            <section class="biome-section" id="guide-progression"><h2>${content.progression}</h2><p>${language === 'ru' ? `<a href="/${language}/quests">Квестовая книга</a> ведёт через шесть учебных эпох — от первых инструментов до молекулярных технологий. Параллельно <a href="/${language}/technologies">дерево технологий</a> делит производство на одиннадцать этапов, а <a href="/${language}/systems">руководства по системам</a> объясняют подключение энергии, труб, конвейеров и ME-сети.` : `The <a href="/${language}/quests">quest book</a> leads through six teaching ages, from first tools to molecular technology. In parallel, the <a href="/${language}/technologies">technology tree</a> divides production into eleven stages, while the <a href="/${language}/systems">system guides</a> explain power, pipes, conveyors, and the ME network.`}</p></section>
          </div>
          <aside class="infobox"><h2>${content.title}</h2><img src="/assets/textures/entities/Player.png" alt=""><p class="infobox-caption">${content.intro}</p><h3>${content.information}</h3><dl><div><dt>${content.type}</dt><dd>${content.guide}</dd></div><div><dt>${content.audience}</dt><dd>${content.newPlayers}</dd></div><div><dt>${content.startBiome}</dt><dd><a href="/${language}/worlds/overworld/biomes/forest">${content.forest}</a></dd></div></dl></aside>
        </div>`;
      showArticlePage(article);
      document.title = `${content.title} — InfiniteForge Wiki`;
      updateLanguageLinks('guides/getting-started');
    }

    async function renderBiomeArticle(language, biomeId) {
      const labels = biomeUi[language];
      const article = document.querySelector('#overworld-page');
      article.innerHTML = `<p class="loading-message">${labels.loading}</p>`;
      showArticlePage(article);
      try {
        const data = await fetchWikiJson(`/api/v1/${language}/worlds/overworld/biomes/${encodeURIComponent(biomeId)}`);
        const biome = data.biome;
        const accessItem = biome.accessItem ? bossItemMarkup(biome.accessItem, language, false) : labels.safe;
        const unlockRequirement = biome.requiredBoss
          ? `${labels.defeat} <a href="${bossUrl(biome.requiredBoss.id, language)}">${escapeHtml(biome.requiredBoss.title)}</a>`
          : labels.available;
        const hazardRows = [
          [labels.hazard, biome.hazardTitle || labels.safe],
          biome.hazardRate > 0 && [labels.exposure, `${biome.hazardRate} ${labels.pointsPerSecond}`],
          biome.exposureSeconds > 0 && [labels.exposureTime, `≈ ${biome.exposureSeconds} ${labels.seconds}`],
          biome.accessItem && [labels.protection, accessItem],
          [labels.unlock, unlockRequirement],
        ].filter(Boolean);
        const resourceCards = biome.resources.map((resource) => `
          <a class="biome-resource" href="${itemUrl(resource.id, language)}">${itemIcon(resource, 44)}<span><strong>${escapeHtml(resource.title)}</strong><small>${labels[resource.source] ?? resource.source}</small></span></a>`).join('');
        const mobCards = biome.mobs.map((mob) => `
          <a class="boss-card" href="${mobUrl(mob.id, language)}">${bossPortrait(mob, 76)}<span><h2>${escapeHtml(mob.title)}</h2><p>${escapeHtml(mob.roleTitle)} · ${mob.hp} ${labels.health} · ${mob.damage} ${labels.damage}</p></span></a>`).join('');
        const bossCard = biome.boss ? `
          <a class="boss-card biome-boss-card" href="${bossUrl(biome.boss.id, language)}">${bossPortrait(biome.boss, 82)}<span><h2>${escapeHtml(biome.boss.title)}</h2><p>${escapeHtml(biome.boss.description)} · ${biome.boss.maxHp} ${labels.health}</p></span></a>` : `<p class="empty-section">${labels.noBoss}</p>`;
        const npcCard = biome.npc ? `
          <a class="boss-card biome-boss-card" href="${npcUrl(biome.npc.id, language)}">${bossPortrait(biome.npc, 82)}<span><h2>${escapeHtml(biome.npc.title)}</h2><p>${escapeHtml(biome.npc.role)} · ${biome.npc.questCount} ${npcUi[language].quests}</p></span></a>` : '';
        const pagination = [
          biome.previous && `<a href="/${language}/worlds/overworld/biomes/${biome.previous.id}"><small>← ${labels.previous}</small><strong>${escapeHtml(biome.previous.title)}</strong></a>`,
          biome.next && `<a href="/${language}/worlds/overworld/biomes/${biome.next.id}"><small>${labels.next} →</small><strong>${escapeHtml(biome.next.title)}</strong></a>`,
        ].filter(Boolean).join('');
        article.innerHTML = `
          <h1 class="article-heading">${escapeHtml(biome.title)}</h1>
          <div class="article-layout">
            <div class="article-copy">
              <p class="biome-lead"><strong>${escapeHtml(biome.title)}</strong> — ${escapeHtml(biome.description)}</p>
              <nav class="table-of-contents" aria-label="${labels.contents}"><strong>${labels.contents}</strong><ol><li><a href="#biome-overview">${labels.overview}</a></li><li><a href="#biome-progression">${labels.progression}</a></li><li><a href="#biome-resources">${labels.resources}</a></li><li><a href="#biome-inhabitants">${labels.inhabitants}</a></li>${biome.npc ? `<li><a href="#biome-npc">${labels.npc}</a></li>` : ''}<li><a href="#biome-boss">${labels.boss}</a></li><li><a href="#biome-preparation">${labels.preparation}</a></li></ol></nav>
              <section class="biome-section" id="biome-overview"><h2>${labels.overview}</h2><p>${escapeHtml(biome.description)}</p></section>
              <section class="biome-section" id="biome-progression"><h2>${labels.progression}</h2><table class="wiki-data-table"><tbody>${hazardRows.map(([key, value]) => `<tr><th>${escapeHtml(key)}</th><td>${value}</td></tr>`).join('')}</tbody></table></section>
              <section class="biome-section" id="biome-resources"><h2>${labels.resources}</h2>${biome.resourceInheritance ? `<p class="biome-notice"><strong>${labels.inherited}:</strong> ${escapeHtml(biome.resourceInheritance)}.</p>` : ''}${resourceCards ? `<div class="biome-resource-grid">${resourceCards}</div>` : `<p class="empty-section">${labels.noResources}</p>`}</section>
              <section class="biome-section" id="biome-inhabitants"><h2>${labels.inhabitants}</h2>${mobCards ? `<div class="boss-grid">${mobCards}</div>` : `<p class="empty-section">${labels.noMobs}</p>`}</section>
              ${biome.npc ? `<section class="biome-section" id="biome-npc"><h2>${labels.npc}</h2>${npcCard}</section>` : ''}
              <section class="biome-section" id="biome-boss"><h2>${labels.boss}</h2>${bossCard}</section>
              <section class="biome-section" id="biome-preparation"><h2>${labels.preparation}</h2><p>${escapeHtml(biome.preparation)}</p></section>
              <nav class="article-pagination" aria-label="${labels.progression}">${pagination}</nav>
            </div>
            <aside class="infobox biome-infobox"><h2>${escapeHtml(biome.title)}</h2><img src="${escapeHtml(biome.image)}" alt=""><p class="infobox-caption">${escapeHtml(biome.description)}</p><h3>${labels.information}</h3><dl><div><dt>${labels.worldLabel}</dt><dd><a href="/${language}/worlds/overworld">${labels.world}</a></dd></div><div><dt>${labels.tier}</dt><dd>${escapeHtml(biome.tierTitle)}</dd></div><div><dt>${labels.direction}</dt><dd>${escapeHtml(biome.directionTitle)}</dd></div><div><dt>${labels.hazard}</dt><dd>${escapeHtml(biome.hazardTitle || labels.safe)}</dd></div>${biome.accessItem ? `<div><dt>${labels.protection}</dt><dd>${accessItem}</dd></div>` : ''}${biome.npc ? `<div><dt>${labels.npc}</dt><dd><a href="${npcUrl(biome.npc.id, language)}">${escapeHtml(biome.npc.title)}</a></dd></div>` : ''}${biome.boss ? `<div><dt>${labels.boss}</dt><dd><a href="${bossUrl(biome.boss.id, language)}">${escapeHtml(biome.boss.title)}</a></dd></div>` : ''}</dl></aside>
          </div>`;
        document.title = `${biome.title} — InfiniteForge Wiki`;
        updateLanguageLinks(`worlds/overworld/biomes/${encodeURIComponent(biome.id)}`);
      } catch (error) {
        article.innerHTML = `<p class="loading-message">${labels.loadError}</p>`;
      }
    }

    function renderOverworld(language) {
      const content = overworldBiomes[language];
      const article = document.querySelector('#overworld-page');
      article.innerHTML = `
        <h1 class="article-heading">${content.title}</h1>
        <div class="article-layout">
          <div class="article-copy">
            ${content.paragraphs.map((paragraph) => `<p>${paragraph}</p>`).join('')}
            <nav class="table-of-contents" aria-label="${language === 'en' ? 'Contents' : 'Содержание'}"><strong>${language === 'en' ? 'Contents' : 'Содержание'}</strong><ol>${content.contents.map((title, index) => `<li><a href="#overworld-section-${index}">${title}</a></li>`).join('')}</ol></nav>
            <section class="biome-section" id="overworld-section-0"><h2>${content.mapTitle}</h2><p>${content.mapText}</p></section>
            ${content.groups.map((group, index) => `
              <section class="biome-section" id="overworld-section-${index + 1}"><h2>${group.title}</h2><div class="biome-cards">
                ${group.biomes.map(([id, title, text, image]) => `<article class="biome-card"><img src="/assets/textures/environment/biomes/${image}" alt=""><div><h3><a href="/${language}/worlds/overworld/biomes/${id}">${title}</a></h3><p>${text}</p></div></article>`).join('')}
              </div></section>`).join('')}
          </div>
          <aside class="infobox"><h2>${content.title}</h2><img src="/assets/textures/environment/biomes/Grass.png" alt=""><p class="infobox-caption">${content.infobox.caption}</p><h3>${language === 'en' ? 'Information' : 'Информация'}</h3><dl>${content.infobox.rows.map(([key, value]) => `<div><dt>${key}</dt><dd>${value}</dd></div>`).join('')}</dl></aside>
        </div>`;
      showArticlePage(article);
      updateLanguageLinks('worlds/overworld');
    }

    if (routePage === 'worlds' && routeParts[2] === 'overworld' && routeParts.length === 3) {
      renderOverworld(currentLanguage);
    }
    if (routePage === 'worlds' && routeParts[2] === 'overworld' && routeParts[3] === 'biomes' && routeParts.length === 5) {
      renderBiomeArticle(currentLanguage, routeParts[4]);
    }
    if (routePage === 'items') {
      if (routeParts.length === 2) renderItemCatalog(currentLanguage);
      if (routeParts.length === 3) renderItemArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'recipes') {
      if (routeParts.length === 2) renderRecipeCatalog(currentLanguage);
      if (routeParts.length === 3) renderRecipeArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'crafting-balance' && routeParts.length === 2) {
      renderCraftingBalance(currentLanguage);
    }
    if (routePage === 'bosses') {
      if (routeParts.length === 2) renderBossCatalog(currentLanguage);
      if (routeParts.length === 3) renderBossArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'mobs') {
      if (routeParts.length === 2) renderMobCatalog(currentLanguage);
      if (routeParts.length === 3) renderMobArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'machines') {
      if (routeParts.length === 2) renderMachineCatalog(currentLanguage);
      if (routeParts.length === 3) renderMachineArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'technologies') {
      if (routeParts.length === 2) renderTechnologyCatalog(currentLanguage);
      if (routeParts.length === 3) renderTechnologyArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'systems') {
      if (routeParts.length === 2) renderSystemCatalog(currentLanguage);
      if (routeParts.length === 3) renderSystemArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'fluids') {
      if (routeParts.length === 2) renderFluidCatalog(currentLanguage);
      if (routeParts.length === 3) renderFluidArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'achievements') {
      if (routeParts.length === 2) renderAchievementCatalog(currentLanguage);
      if (routeParts.length === 3) renderAchievementArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'mechanics') {
      if (routeParts.length === 2) renderMechanicCatalog(currentLanguage);
      if (routeParts.length === 3) renderMechanicArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'gathering') {
      if (routeParts.length === 2) renderGatheringCatalog(currentLanguage);
      if (routeParts.length === 3) renderGatheringArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'interface') {
      if (routeParts.length === 2) renderInterfaceCatalog(currentLanguage);
      if (routeParts.length === 3) renderInterfaceArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'exploration') {
      if (routeParts.length === 2) renderExplorationCatalog(currentLanguage);
      if (routeParts.length === 3) renderExplorationArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'optimization') {
      if (routeParts.length === 2) renderOptimizationCatalog(currentLanguage);
      if (routeParts.length === 3) renderOptimizationArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'multiplayer') {
      if (routeParts.length === 2) renderMultiplayerCatalog(currentLanguage);
      if (routeParts.length === 3) renderMultiplayerArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'energy') {
      if (routeParts.length === 2) renderEnergyCatalog(currentLanguage);
      if (routeParts.length === 3) renderEnergyArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'logistics') {
      if (routeParts.length === 2) renderLogisticsCatalog(currentLanguage);
      if (routeParts.length === 3) renderLogisticsArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'steam') {
      if (routeParts.length === 2) renderSteamCatalog(currentLanguage);
      if (routeParts.length === 3) renderSteamArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'ore-processing') {
      if (routeParts.length === 2) renderOreProcessingCatalog(currentLanguage);
      if (routeParts.length === 3) renderOreProcessingArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'quests') {
      if (routeParts.length === 2) renderQuestCatalog(currentLanguage);
      if (routeParts.length === 3) renderQuestAge(currentLanguage, routeParts[2]);
    }
    if (routePage === 'npcs') {
      if (routeParts.length === 2) renderNpcCatalog(currentLanguage);
      if (routeParts.length === 3) renderNpcArticle(currentLanguage, routeParts[2]);
    }
    if (routePage === 'search' && routeParts.length === 2) {
      renderSearchPage(currentLanguage);
    }
    if (routePage === 'guides' && routeParts[2] === 'getting-started') {
      renderGettingStarted(currentLanguage);
    }
