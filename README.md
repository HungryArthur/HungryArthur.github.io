# InfiniteForge Wiki

Сайт хранится отдельно от игры и запускается без установки зависимостей. Если рядом
есть папка `InfiniteForge`, сервер автоматически читает из неё актуальные рецепты,
предметы и изображения. В остальных случаях используется сохранённый снимок из
`game-data`.

## Быстрый запуск

Из папки `InfiniteForge_Wiki`:

```powershell
npm start
```

Команда запускает Node.js-сервер и открывает `http://localhost:8080/ru/home`.
Если порт 8080 занят уже запущенной вики, сервер откроет существующий сайт без ошибки.

## Обновление данных из игры

Когда папки `InfiniteForge` и `InfiniteForge_Wiki` лежат рядом:

```powershell
npm run sync
```

Если игра находится в другом месте:

```powershell
npm run sync -- --game-root "D:\Projects\InfiniteForge"
```

Команда атомарно обновляет `game-data`: копирует только те игровые ресурсы, которые
реально читает сервер вики. Этот снимок можно закоммитить в отдельный репозиторий,
чтобы сайт продолжал работать без репозитория игры.

Для чтения данных напрямую из произвольной папки можно задать переменную окружения
`INFINITEFORGE_GAME_ROOT` перед запуском сервера.

## Структура проекта

```text
wiki/
├── client/
│   ├── styles/       # оформление сайта
│   ├── pages/        # маршрутизация и отрисовка страниц
│   ├── components/   # переиспользуемые UI-компоненты
│   └── api/          # клиент для Wiki API
├── server/
│   ├── loaders/      # чтение игровых данных
│   ├── routes/       # HTTP-маршрутизация и раздача файлов
│   ├── balance/      # расчёты баланса
│   └── localization/ # поддерживаемые языки
└── tests/            # автоматические проверки сервера и API
```

Крупные файлы страницы разделены на HTML-каркас, таблицу стилей и JavaScript-модули.
Сервер использует отдельные модули инфраструктуры, а предметы, рецепты и игровые
справочники по-прежнему формируются из реальных ресурсов InfiniteForge.

## Проверка перед изменениями

```powershell
npm test
npm run check
```

`npm test` проверяет запуск, локализованные страницы, API, изображения, клиентские
модули, `HEAD`/redirect-ответы и блокировку опасных путей. Состояние сервера доступно
по адресу `http://localhost:8080/api/v1/health`.

## Страницы

- `http://localhost:8080/ru/home`
- `http://localhost:8080/en/home`
- `http://localhost:8080/ru/items`
- `http://localhost:8080/en/items/bronze_pickaxe`
- `http://localhost:8080/ru/recipes`
- `http://localhost:8080/en/recipes/steam_boiler`
- `http://localhost:8080/ru/crafting-balance`
- `http://localhost:8080/ru/mobs`
- `http://localhost:8080/en/mobs/forest_wolf`
- `http://localhost:8080/ru/bosses`
- `http://localhost:8080/en/bosses/ent`
- `http://localhost:8080/ru/machines`
- `http://localhost:8080/en/machines/conveyor_t3`
- `http://localhost:8080/ru/technologies`
- `http://localhost:8080/en/technologies/steam`
- `http://localhost:8080/ru/systems`
- `http://localhost:8080/en/systems/power`
- `http://localhost:8080/ru/fluids`
- `http://localhost:8080/en/fluids/crude_oil`
- `http://localhost:8080/ru/quests`
- `http://localhost:8080/en/quests/1`
- `http://localhost:8080/ru/achievements`
- `http://localhost:8080/en/achievements/efficient_grid`
- `http://localhost:8080/ru/mechanics`
- `http://localhost:8080/en/mechanics/environmental-hazards`
- `http://localhost:8080/ru/gathering`
- `http://localhost:8080/en/gathering/ore-deposits`
- `http://localhost:8080/ru/interface`
- `http://localhost:8080/en/interface/building-tools`
- `http://localhost:8080/ru/exploration`
- `http://localhost:8080/en/exploration/world-generation`
- `http://localhost:8080/ru/optimization`
- `http://localhost:8080/en/optimization/stock-control`
- `http://localhost:8080/ru/multiplayer`
- `http://localhost:8080/en/multiplayer/hosting-joining`
- `http://localhost:8080/ru/energy`
- `http://localhost:8080/en/energy/solar-weather`
- `http://localhost:8080/ru/logistics`
- `http://localhost:8080/en/logistics/ingredient-demand`
- `http://localhost:8080/ru/steam`
- `http://localhost:8080/en/steam/steam-network`
- `http://localhost:8080/ru/ore-processing`
- `http://localhost:8080/en/ore-processing/centrifuge-yields`
- `http://localhost:8080/ru/npcs`
- `http://localhost:8080/en/npcs/mechanic_sam`
- `http://localhost:8080/ru/guides/getting-started`
- `http://localhost:8080/ru/search?q=паровой`
- `http://localhost:8080/ru/worlds/overworld`
- `http://localhost:8080/en/worlds/overworld/biomes/desert`

Каталоги формируются автоматически из игровых ресурсов. Сейчас доступны 337 предметов,
полный набор рецептов ручного изготовления и кулинарии,
27 мобов, 9 боссов, 62 технических блока, 291 основной квест, 10 персонажей,
30 побочных заданий, 11 этапов развития, 4 руководства по производственным системам,
22 статьи о жидкостях и газах, 22 достижения, 5 руководств по игровым механикам, 6
руководств по добыче ресурсов, 5 руководств по управлению и интерфейсу, 5 статей об исследовании мира, 6 статей об оптимизации фабрики, 5 статей о совместной игре, 5 статей об энергетике, 5 статей о предметной логистике, 5 статей о паровых технологиях, 5 статей о переработке руды и 10 подробных статей о биомах на русском и английском
языках. Статьи о биомах содержат
условия доступа, опасности, ресурсы, обитателей, босса и советы по подготовке к
экспедиции. Для новых игроков доступно отдельное руководство по первым часам игры.

## API

Предметы:

- `http://localhost:8080/api/v1/ru/items`
- `http://localhost:8080/api/v1/en/items/bronze_pickaxe`

Рецепты:

- `http://localhost:8080/api/v1/ru/recipes`
- `http://localhost:8080/api/v1/en/recipes/steam_boiler`

Баланс крафтов (живой расчёт итоговых входов ручной цепочки, глубины и предупреждений):

- `http://localhost:8080/api/v1/ru/crafting-balance`
- `http://localhost:8080/api/v1/en/crafting-balance/energy_storage_t2`

Мобы:

- `http://localhost:8080/api/v1/ru/mobs`
- `http://localhost:8080/api/v1/en/mobs/forest_wolf`

Боссы:

- `http://localhost:8080/api/v1/ru/bosses`
- `http://localhost:8080/api/v1/en/bosses/ent`

Техника:

- `http://localhost:8080/api/v1/ru/machines`
- `http://localhost:8080/api/v1/en/machines/conveyor_t3`

Технологии:

- `http://localhost:8080/api/v1/ru/technologies`
- `http://localhost:8080/api/v1/en/technologies/steam`

Производственные системы:

- `http://localhost:8080/api/v1/ru/systems`
- `http://localhost:8080/api/v1/en/systems/power`

Жидкости и газы:

- `http://localhost:8080/api/v1/ru/fluids`
- `http://localhost:8080/api/v1/en/fluids/crude_oil`

Квесты:

- `http://localhost:8080/api/v1/ru/quests`
- `http://localhost:8080/api/v1/en/quests/1`

Достижения:

- `http://localhost:8080/api/v1/ru/achievements`
- `http://localhost:8080/api/v1/en/achievements/efficient_grid`

Игровые механики:

- `http://localhost:8080/api/v1/ru/mechanics`
- `http://localhost:8080/api/v1/en/mechanics/environmental-hazards`

Добыча ресурсов:

- `http://localhost:8080/api/v1/ru/gathering`
- `http://localhost:8080/api/v1/en/gathering/ore-deposits`

Управление и интерфейс:

- `http://localhost:8080/api/v1/ru/interface`
- `http://localhost:8080/api/v1/en/interface/building-tools`

Исследование мира:

- `http://localhost:8080/api/v1/ru/exploration`
- `http://localhost:8080/api/v1/en/exploration/world-generation`

Оптимизация фабрики:

- `http://localhost:8080/api/v1/ru/optimization`
- `http://localhost:8080/api/v1/en/optimization/stock-control`

Совместная игра:

- `http://localhost:8080/api/v1/ru/multiplayer`
- `http://localhost:8080/api/v1/en/multiplayer/hosting-joining`

Энергетика:

- `http://localhost:8080/api/v1/ru/energy`
- `http://localhost:8080/api/v1/en/energy/solar-weather`

Предметная логистика:

- `http://localhost:8080/api/v1/ru/logistics`
- `http://localhost:8080/api/v1/en/logistics/ingredient-demand`

Паровые технологии:

- `http://localhost:8080/api/v1/ru/steam`
- `http://localhost:8080/api/v1/en/steam/steam-network`

Переработка руды:

- `http://localhost:8080/api/v1/ru/ore-processing`
- `http://localhost:8080/api/v1/en/ore-processing/centrifuge-yields`

Персонажи и побочные задания:

- `http://localhost:8080/api/v1/ru/npcs`
- `http://localhost:8080/api/v1/en/npcs/mechanic_sam`

Поиск:

- `http://localhost:8080/api/v1/ru/search?q=медь`
- `http://localhost:8080/api/v1/en/search?q=steam`

Overworld:

- `http://localhost:8080/api/v1/ru/worlds`
- `http://localhost:8080/api/v1/en/worlds/overworld`
- `http://localhost:8080/api/v1/ru/worlds/overworld/biomes`
- `http://localhost:8080/api/v1/en/worlds/overworld/biomes/forest`

Поддерживаются маршруты `home`, `about`, `search`, `guides/getting-started`, `items`,
`items/:itemId`, `recipes`, `recipes/:recipeId`, `mobs`, `mobs/:mobId`, `bosses`, `bosses/:bossId`, `machines`,
`crafting-balance`,
`machines/:machineId`, `quests`, `quests/:age`, `achievements`, `achievements/:achievementId`, `mechanics`, `mechanics/:mechanicId`, `gathering`, `gathering/:guideId`, `interface`, `interface/:guideId`, `exploration`, `exploration/:guideId`, `optimization`, `optimization/:guideId`, `multiplayer`, `multiplayer/:guideId`, `energy`, `energy/:guideId`, `logistics`, `logistics/:guideId`, `steam`, `steam/:guideId`, `ore-processing`, `ore-processing/:guideId`, `npcs`, `npcs/:npcId`, `systems`, `systems/:systemId`, `fluids`, `fluids/:fluidId`, `technologies`, `technologies/:technologyId`,
`worlds/overworld` и `worlds/overworld/biomes/:biomeId`.
