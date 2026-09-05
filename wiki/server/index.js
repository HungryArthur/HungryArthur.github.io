import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { extname, relative, resolve } from 'node:path';
import { exec } from 'node:child_process';
import { balanceNumber } from './balance/numbers.js';
import { parseCsvLine } from './loaders/csv.js';
import { assetsRoot, gameDataSource, projectRoot, repositoryRoot } from './loaders/game-root.js';
import { languages } from './localization/languages.js';
import { createWikiServer } from './routes/create-server.js';
import { sendJson } from './routes/http.js';


const clientRoot = resolve(repositoryRoot, 'wiki/client');
const itemDefinitionsRoot = resolve(projectRoot, 'core/resources/items/definitions');
const recipeDefinitionsRoot = resolve(projectRoot, 'core/resources/crafting/recipes');
const itemTexturesRoot = resolve(assetsRoot, 'textures/items');
const bossRegistryPath = resolve(projectRoot, 'core/systems/bosses/BossRegistry.gd');
const mobRegistryPath = resolve(projectRoot, 'core/systems/mobs/MobRegistry.gd');
const blockDefinitionsRoot = resolve(projectRoot, 'core/resources/blocks/definitions');
const chestDefinitionsRoot = resolve(projectRoot, 'core/resources/chests/definitions');
const oreDefinitionsRoot = resolve(projectRoot, 'core/resources/ores/definitions');
const forageDefinitionsRoot = resolve(projectRoot, 'core/resources/forage/definitions');
const technologyTreePath = resolve(projectRoot, 'core/systems/quests/TechnologyTree.gd');
const questDatabasePath = resolve(projectRoot, 'core/systems/quests/QuestDatabase.gd');
const npcQuestDatabasePath = resolve(projectRoot, 'core/systems/quests/NpcQuestDatabase.gd');
const achievementDatabasePath = resolve(projectRoot, 'core/systems/achievements/AchievementDB.gd');
const playerScriptPath = resolve(projectRoot, 'entities/player/player.gd');
const equipmentBonusPath = resolve(projectRoot, 'core/systems/equipment/EquipmentBonusSystem.gd');
const cropDefinitionsRoot = resolve(projectRoot, 'core/resources/farming/definitions');
const toolTierPath = resolve(projectRoot, 'core/systems/mining/ToolTierSystem.gd');
const miningComponentPath = resolve(projectRoot, 'core/systems/mining/MiningComponent.gd');
const drillContainerPath = resolve(projectRoot, 'core/systems/machines/DrillContainer.gd');
const oreDatabasePath = resolve(projectRoot, 'core/autoloads/OreDatabase.gd');
const oilDepositGeneratorPath = resolve(projectRoot, 'core/systems/generation/OilDepositGenerator.gd');
const projectSettingsPath = resolve(projectRoot, 'project.godot');
const worldInteractionPath = resolve(projectRoot, 'core/systems/world/WorldInteractionManager.gd');
const inventoryUiPath = resolve(projectRoot, 'ui/hud/inventory/InventoryUI.gd');
const hotbarUiPath = resolve(projectRoot, 'ui/hud/inventory/HotbarUI.gd');
const saveManagerPath = resolve(projectRoot, 'core/autoloads/SaveManager.gd');
const multiplayerManagerPath = resolve(projectRoot, 'core/autoloads/MultiplayerManager.gd');
const netSyncPath = resolve(projectRoot, 'core/systems/multiplayer/NetSync.gd');
const gameChatPath = resolve(projectRoot, 'ui/hud/chat/GameChat.gd');
const pingIndicatorPath = resolve(projectRoot, 'ui/hud/PingIndicator.gd');
const timeManagerPath = resolve(projectRoot, 'core/autoloads/TimeManager.gd');
const weatherManagerPath = resolve(projectRoot, 'core/autoloads/WeatherManager.gd');
const mapSystemPath = resolve(projectRoot, 'ui/hud/map/MapSystem.gd');
const obeliskManagerPath = resolve(projectRoot, 'core/systems/obelisks/ObeliskManager.gd');
const obeliskRegistryPath = resolve(projectRoot, 'core/systems/obelisks/ObeliskRegistry.gd');
const biomeGeneratorPath = resolve(projectRoot, 'core/systems/generation/generators/BiomeGenerator.gd');
const structureGeneratorPath = resolve(projectRoot, 'core/systems/generation/StructureGenerator.gd');
const droppedItemPath = resolve(projectRoot, 'entities/items/DroppedItem.gd');
const gameConstantsPath = resolve(projectRoot, 'core/constants/GameConstants.gd');
const chunkPath = resolve(projectRoot, 'core/systems/world/Chunk.gd');
const machineContainerPath = resolve(projectRoot, 'core/systems/machines/MachineContainer.gd');
const steamAssemblerPath = resolve(projectRoot, 'core/systems/machines/SteamAssemblerContainer.gd');
const conveyorContainerPath = resolve(projectRoot, 'core/systems/machines/ConveyorContainer.gd');
const ingredientReservationsPath = resolve(projectRoot, 'core/systems/machines/IngredientDemandReservations.gd');
const productionAnalyzerPath = resolve(projectRoot, 'core/systems/machines/ProductionChainAnalyzer.gd');
const cokeOvenPath = resolve(projectRoot, 'core/systems/machines/CokeOvenContainer.gd');
const factorySystemsHudPath = resolve(projectRoot, 'ui/hud/FactorySystemsHUD.gd');
const powerNetworkPath = resolve(projectRoot, 'core/systems/power/PowerNetworkManager.gd');
const powerOverlayPath = resolve(projectRoot, 'ui/hud/power/PowerNetworkOverlay.gd');
const energyStoragePath = resolve(projectRoot, 'core/systems/power/EnergyStorageContainer.gd');
const logisticsNetworkPath = resolve(projectRoot, 'core/systems/logistics/LogisticsNetworkManager.gd');
const logisticsOverlayPath = resolve(projectRoot, 'ui/hud/logistics/LogisticsNetworkOverlay.gd');
const mechanicalInserterPath = resolve(projectRoot, 'core/systems/machines/MechanicalInserterContainer.gd');
const conveyorSplitterPath = resolve(projectRoot, 'core/systems/machines/ConveyorSplitterContainer.gd');
const chestDataPath = resolve(projectRoot, 'core/resources/chests/ChestData.gd');
const coalGeneratorPath = resolve(projectRoot, 'core/systems/machines/CoalGeneratorContainer.gd');
const steamTurbinePath = resolve(projectRoot, 'core/systems/machines/SteamTurbineContainer.gd');
const fluidNetworkPath = resolve(projectRoot, 'core/systems/fluids/FluidNetworkManager.gd');
const fluidOverlayPath = resolve(projectRoot, 'ui/hud/fluids/FluidNetworkOverlay.gd');
const waterPumpPath = resolve(projectRoot, 'core/systems/fluids/WaterPumpContainer.gd');
const fluidValvePath = resolve(projectRoot, 'core/systems/fluids/FluidValveContainer.gd');
const steamBoilerPath = resolve(projectRoot, 'core/systems/machines/SteamBoilerContainer.gd');
const steamMachinePath = resolve(projectRoot, 'core/systems/machines/SteamMachineContainer.gd');
const steamMachinePaths = {
  crusher: resolve(projectRoot, 'core/systems/machines/SteamCrusherContainer.gd'),
  furnace: resolve(projectRoot, 'core/systems/machines/SteamFurnaceContainer.gd'),
  press: resolve(projectRoot, 'core/systems/machines/SteamPressContainer.gd'),
  assembler: resolve(projectRoot, 'core/systems/machines/SteamAssemblerContainer.gd'),
};
const oreProcessingPaths = {
  primitiveCrusher: resolve(projectRoot, 'core/systems/machines/PrimitiveCrusherContainer.gd'),
  steamCrusher: resolve(projectRoot, 'core/systems/machines/SteamCrusherContainer.gd'),
  crusher: resolve(projectRoot, 'core/systems/machines/CrusherContainer.gd'),
  washer: resolve(projectRoot, 'core/systems/machines/OreWasherContainer.gd'),
  separator: resolve(projectRoot, 'core/systems/machines/MagneticSeparatorContainer.gd'),
  centrifuge: resolve(projectRoot, 'core/systems/machines/CentrifugeContainer.gd'),
  melter: resolve(projectRoot, 'core/systems/machines/OreMelterContainer.gd'),
  furnace: resolve(projectRoot, 'core/systems/machines/FurnaceContainer.gd'),
  electricFurnace: resolve(projectRoot, 'core/systems/machines/ElectricFurnaceContainer.gd'),
};
const solarPanelPaths = [
  resolve(projectRoot, 'core/systems/machines/SolarPanelContainer.gd'),
  resolve(projectRoot, 'core/systems/machines/AdvancedSolarPanelContainer.gd'),
  resolve(projectRoot, 'core/systems/machines/EliteSolarPanelContainer.gd'),
  resolve(projectRoot, 'core/systems/machines/UltimateSolarPanelContainer.gd'),
  resolve(projectRoot, 'core/systems/machines/QuantumSolarPanelContainer.gd'),
];
const fluidDatabasePath = resolve(projectRoot, 'core/autoloads/FluidDatabase.gd');
const fluidMachinePaths = {
  distillation: resolve(projectRoot, 'core/systems/fluids/DistillationColumnContainer.gd'),
  mixer: resolve(projectRoot, 'core/systems/machines/MixerContainer.gd'),
  reactor: resolve(projectRoot, 'core/systems/machines/ChemicalReactorContainer.gd'),
  melter: resolve(projectRoot, 'core/systems/machines/OreMelterContainer.gd'),
};
const questTranslationsPath = resolve(assetsRoot, 'locale/quests.csv');
const menuTranslationsPath = resolve(assetsRoot, 'locale/menu.csv');
const balanceReportPath = resolve(projectRoot, 'docs/generated/overworld_balance_report.md');
const wikiPage = resolve(clientRoot, 'index.html');
const host = process.env.WIKI_HOST ?? '127.0.0.1';
const port = Number(process.env.WIKI_PORT ?? 8080);

const biomeDefinitions = [
  { id: 'forest', resource: 'ForestBiome', title: { ru: 'Лес', en: 'Forest' }, tier: 'safe', direction: 'center', image: 'Grass.png', boss: 'ent' },
  { id: 'desert', resource: 'DesertBiome', title: { ru: 'Пустыня', en: 'Desert' }, tier: 'normal', direction: 'west', image: 'Desert.png', hazard: 'heat', hazardRate: 12, accessItem: 'sand_amulet', requiredBoss: 'ent', boss: 'dune_colossus' },
  { id: 'snow', resource: 'SnowBiome', title: { ru: 'Снежные земли', en: 'Snowlands' }, tier: 'normal', direction: 'north', image: 'Snow.png', hazard: 'cold', hazardRate: 12, accessItem: 'thermal_gloves', requiredBoss: 'dune_colossus', boss: 'frost_warden' },
  { id: 'swamp', resource: 'SwampBiome', title: { ru: 'Болото', en: 'Swamp' }, tier: 'normal', direction: 'south', image: 'Swamp.png', hazard: 'miasma', hazardRate: 13, accessItem: 'miasma_boots', requiredBoss: 'frost_warden', boss: 'mire_hydra' },
  { id: 'jungle', resource: 'JungleBiome', title: { ru: 'Джунгли', en: 'Jungle' }, tier: 'normal', direction: 'east', image: 'Jungle.png', hazard: 'spores', hazardRate: 12, accessItem: 'savage_belt', requiredBoss: 'mire_hydra', boss: 'thorn_matriarch' },
  { id: 'sunny-canyon', resource: 'SunnyCanyonBiome', resourceBase: 'DesertBiome', title: { ru: 'Солнечный каньон', en: 'Sunny Canyon' }, tier: 'hard', direction: 'outer-west', image: 'SunnyCanyon.png', hazard: 'scorching_heat', hazardRate: 16, accessItem: 'sun_crown', requiredBoss: 'thorn_matriarch', boss: 'solar_tyrant' },
  { id: 'icy-abyss', resource: 'IcyAbyssBiome', resourceBase: 'SnowBiome', title: { ru: 'Ледяная бездна', en: 'Icy Abyss' }, tier: 'hard', direction: 'outer-north', image: 'IcyAbyss.png', hazard: 'severe_cold', hazardRate: 16, accessItem: 'cryo_mantle', requiredBoss: 'solar_tyrant', boss: 'abyss_leviathan' },
  { id: 'rotting-bog', resource: 'RottingBogBiome', resourceBase: 'SwampBiome', title: { ru: 'Гниющее болото', en: 'Rotting Bog' }, tier: 'hard', direction: 'outer-south', image: 'RottingBog.png', hazard: 'toxins', hazardRate: 16, accessItem: 'void_respirator', requiredBoss: 'abyss_leviathan', boss: 'rot_king' },
  { id: 'primeval-thicket', resource: 'PrimevalThicketBiome', resourceBase: 'JungleBiome', title: { ru: 'Первобытные дебри', en: 'Primeval Thicket' }, tier: 'hard', direction: 'outer-east', image: 'PrimevalThicket.png', hazard: 'ancient_spores', hazardRate: 16, accessItem: 'primeval_potion', requiredBoss: 'rot_king', boss: 'primal_guardian' },
];

const biomeText = {
  forest: {
    description: { ru: 'Густой лес занимает весь безопасный центр Верхнего мира. Между деревьями появляются три вида противников, а глубже находится арена Энта.', en: 'Dense forest fills the entire safe centre of the Overworld. Three enemy species roam between the trees, with the Ent arena farther inside.' },
    preparation: { ru: 'Возьмите оружие, еду и топор. Перед боем с Энтом полезно расчистить пространство для уклонений и подготовить свободные ячейки под добычу.', en: 'Bring a weapon, food, and an axe. Clear room to dodge before fighting the Ent and leave inventory slots free for its loot.' },
  },
  desert: {
    description: { ru: 'Западный сектор обычного кольца. Песок и кактусы дополняют залежи угля и меди, а постоянная жара требует Песчаный амулет.', en: 'The western sector of the normal ring. Sand and cacti join coal and copper deposits, while constant heat requires a Sand Amulet.' },
    preparation: { ru: 'Наденьте Песчаный амулет, возьмите кирку и держите дистанцию от быстрых скарабеев. Для Песчаного колосса оставьте широкую площадку под песчаные взрывы и рывки.', en: 'Equip the Sand Amulet, bring a pickaxe, and keep space from fast scarabs. Fight the Dune Colossus in an open area to avoid sand bursts and charges.' },
  },
  snow: {
    description: { ru: 'Северный сектор обычного кольца. Снежные земли дают лёд, железо и свинец, но без Тепловых перчаток холод быстро заполняет шкалу воздействия.', en: 'The northern sector of the normal ring. Snowlands provide ice, iron, and lead, but cold rapidly fills the exposure meter without Thermal Gloves.' },
    preparation: { ru: 'Наденьте Тепловые перчатки и возьмите оружие с хорошим уроном по одиночной цели. В бою с Ледяным стражем отходите от ледяной волны и покидайте отмеченную область кометы.', en: 'Equip Thermal Gloves and bring strong single-target damage. Back away from the Frost Warden\'s ice wave and leave the marked comet area.' },
  },
  swamp: {
    description: { ru: 'Южный сектор обычного кольца с мелководьем, грибами и тростником. Миазмы требуют герметичных ботинок, а местные существа часто навязывают бой на близкой дистанции.', en: 'The southern sector of the normal ring, filled with shallows, mushrooms, and reeds. Miasma requires sealed boots, and local creatures often force close-range fights.' },
    preparation: { ru: 'Наденьте Ботинки миазмов, возьмите еду и не позволяйте пиявкам окружить персонажа. Во второй фазе Болотная гидра призывает новых пиявок — уничтожайте их до продолжения атаки на босса.', en: 'Equip Miasma Boots, carry food, and avoid being surrounded by leeches. The Mire Hydra summons more leeches in phase two; clear them before returning to the boss.' },
  },
  jungle: {
    description: { ru: 'Восточный сектор обычного кольца с густой растительностью и ценными высокоуровневыми рудами. Споры опасны без Пояса дикаря, а пантеры быстро сокращают дистанцию.', en: 'The eastern sector of the normal ring, with dense vegetation and valuable high-tier ores. Spores are dangerous without a Savage Belt, and panthers close distance quickly.' },
    preparation: { ru: 'Наденьте Пояс дикаря, возьмите прочную кирку и сохраняйте свободный путь для отхода. Арена Шипастой матриархини должна позволять выйти из шипастого поля и уклониться от рывка лозами.', en: 'Equip the Savage Belt, bring a strong pickaxe, and keep a clear escape path. The Thorn Matriarch arena should leave room to exit thorn fields and dodge vine lunges.' },
  },
  'sunny-canyon': {
    description: { ru: 'Внешняя западная зона и усиленное продолжение пустыни. Она наследует пустынные ресурсы, но населена более выносливыми существами и охвачена испепеляющим зноем.', en: 'The outer western zone and a harder continuation of the desert. It inherits desert resources, but houses tougher creatures and inflicts searing heat.' },
    preparation: { ru: 'Обязательна Солнечная корона. Возьмите улучшенное оружие, восстановление здоровья и сражайтесь с Солнечным тираном на большой открытой арене: обе его фазы покрывают значительную область.', en: 'The Sun Crown is mandatory. Bring upgraded weapons and healing, and fight the Solar Tyrant in a large open arena because both phases cover wide areas.' },
  },
  'icy-abyss': {
    description: { ru: 'Внешняя северная зона с усиленным морозом и особенно живучими противниками. Ресурсный набор наследуется от снежных земель, а опасность воздействия возрастает.', en: 'The outer northern zone has harsher cold and especially durable enemies. Its resources follow Snowlands while environmental exposure becomes more severe.' },
    preparation: { ru: 'Наденьте Крио-мантию и подготовьте мобильную экипировку. Левиафан бездны сочетает круговой ледокол с дальним рывком, поэтому не зажимайте себя препятствиями.', en: 'Equip the Cryo Mantle and favor mobility. The Abyss Leviathan combines a circular icebreaker with a long dash, so avoid fighting near obstacles.' },
  },
  'rotting-bog': {
    description: { ru: 'Внешняя южная зона, где болотные ресурсы соседствуют со смертельными токсинами. Тяжёлые слизни прикрывают быстрых гончих и дальнобойных ведьм.', en: 'The outer southern zone, where swamp resources meet deadly toxins. Heavy slimes screen fast hounds and ranged witches.' },
    preparation: { ru: 'Используйте Респиратор пустоты и оружие, способное быстро убирать призванных существ. Король гнили создаёт опасную область и во второй фазе вызывает токсичных слизней.', en: 'Use the Void Respirator and a weapon that can quickly remove summoned creatures. The Rot King creates hazardous areas and summons toxic slimes in phase two.' },
  },
  'primeval-thicket': {
    description: { ru: 'Финальная внешняя зона на востоке. Древние споры, самые сильные обычные мобы и Первобытный страж делают дебри вершиной текущей прогрессии Верхнего мира.', en: 'The final outer zone in the east. Ancient spores, the strongest common mobs, and the Primal Guardian make it the peak of current Overworld progression.' },
    preparation: { ru: 'Используйте Первозданное зелье для постоянного доступа, возьмите лучшую доступную броню и оставьте место для титановой и мифриловой добычи. Против стража чередуйте отход от круговой атаки и уклонение от рывка.', en: 'Use a Primeval Potion for permanent access, bring the best available armor, and reserve space for titanium and mythril loot. Alternate between retreating from the guardian\'s circular attack and dodging its charge.' },
  },
};

const biomeLabels = {
  tiers: { safe: { ru: 'Безопасная зона', en: 'Safe zone' }, normal: { ru: 'Обычный биом', en: 'Normal biome' }, hard: { ru: 'Сложный биом', en: 'Hard biome' } },
  directions: {
    center: { ru: 'Центр мира', en: 'World centre' }, 'inner-ring': { ru: 'Внутреннее кольцо', en: 'Inner ring' },
    west: { ru: 'Запад', en: 'West' }, north: { ru: 'Север', en: 'North' }, south: { ru: 'Юг', en: 'South' }, east: { ru: 'Восток', en: 'East' },
    'outer-west': { ru: 'Внешний запад', en: 'Outer west' }, 'outer-north': { ru: 'Внешний север', en: 'Outer north' }, 'outer-south': { ru: 'Внешний юг', en: 'Outer south' }, 'outer-east': { ru: 'Внешний восток', en: 'Outer east' },
  },
  hazards: {
    heat: { ru: 'Жара', en: 'Heat' }, cold: { ru: 'Холод', en: 'Cold' }, miasma: { ru: 'Миазмы', en: 'Miasma' }, spores: { ru: 'Споры', en: 'Spores' },
    scorching_heat: { ru: 'Испепеляющий зной', en: 'Searing heat' }, severe_cold: { ru: 'Лютый мороз', en: 'Severe cold' }, toxins: { ru: 'Токсины', en: 'Toxins' }, ancient_spores: { ru: 'Древние споры', en: 'Ancient spores' },
  },
};

const technologyTranslations = {
  foundation: { title: 'Основы', description: 'Ручные инструменты, первая плавка и примитивная переработка ресурсов.' },
  steam: { title: 'Эпоха пара', description: 'Автоматизированная бронзовая мастерская, водоснабжение, пар и точные механические детали.' },
  electricity: { title: 'Электричество', description: 'Переход от проверенной паровой линии к генераторам, резине и низковольтным схемам.' },
  automation: { title: 'Автоматизация', description: 'Серийное производство электрических деталей, маршрутизация, сжатие и смешивание жидкостей.' },
  industry: { title: 'Тяжёлая промышленность', description: 'Многоступенчатая переработка руды, плотные материалы и промышленные машины.' },
  chemistry: { title: 'Промышленная химия', description: 'Прямая переработка руды в пыль и выделение побочных металлов перед химическим производством.' },
  bioengineering: { title: 'Биоинженерия', description: 'Переработка нефти и коксовых продуктов в материалы для возобновляемого производства.' },
  solar_industry: { title: 'Солнечная промышленность', description: 'Устойчивая энергетика на основе сельского хозяйства, модулей продуктивности и электроники.' },
  abyss_engineering: { title: 'Инженерия бездны', description: 'Масштабирование солнечной генерации и хранилищ энергии перед молекулярной переработкой.' },
  frontier: { title: 'Пограничные технологии', description: 'Стабильная поздняя производственная линия для плотной материи и высокоуровневой электроники.' },
  quantum: { title: 'Квантовая логистика', description: 'Завершение промышленной цепочки Верхнего мира и открытие цифрового хранения ME.' },
};

const questAgeText = [
  { age: 1, title: { ru: 'Каменный век', en: 'Stone Age' }, subtitle: { ru: 'От палок и камней до бронзы и первых механизмов.', en: 'From sticks and stones to bronze and the first machines.' } },
  { age: 2, title: { ru: 'Индустриализация', en: 'Industrialization' }, subtitle: { ru: 'Прокат, детали, сила пара, кокс и первая сталь.', en: 'Rolling, components, steam power, coke, and the first steel.' } },
  { age: 3, title: { ru: 'Железный век', en: 'Iron Age' }, subtitle: { ru: 'Стальные детали, каркасы машин и конвейеры.', en: 'Steel components, machine frames, and conveyors.' } },
  { age: 4, title: { ru: 'Электрификация', en: 'Electrification' }, subtitle: { ru: 'Первый ток, компоненты машин и жидкости.', en: 'First power, machine components, and fluids.' } },
  { age: 5, title: { ru: 'Электрический век', en: 'Electric Age' }, subtitle: { ru: 'Солнце, электроника, переработка руды и ME-сеть.', en: 'Solar power, electronics, ore processing, and an ME network.' } },
  { age: 6, title: { ru: 'Промышленный век', en: 'Industrial Age' }, subtitle: { ru: 'Титан, вычисления и молекулярные технологии.', en: 'Titanium, computing, and molecular technology.' } },
];

const systemGuides = [
  {
    id: 'power', color: [0.98, 0.72, 0.16, 1],
    title: { ru: 'Энергосеть', en: 'Power grid' },
    subtitle: { ru: 'Генераторы, провода, потребители и накопители EU.', en: 'Generators, conductors, consumers, and EU storage.' },
    intro: { ru: 'Электрическая сеть объединяет соседние по сторонам провода, конвейеры, генераторы, накопители и машины. Производство сначала питает потребителей, затем заряжает накопители; при дефиците накопители отдают запас обратно в сеть.', en: 'The power grid connects orthogonally adjacent wires, conveyors, generators, storage, and machines. Generation serves consumers first and then charges storage; storage discharges when generation cannot meet demand.' },
    facts: [
      { label: { ru: 'Базовые генераторы', en: 'Base generators' }, value: { ru: '40 EU/с', en: '40 EU/s' } },
      { label: { ru: 'Потребление конвейеров', en: 'Conveyor draw' }, value: { ru: 'T1: 0; T2–T5: 2–5 EU/с', en: 'T1: 0; T2–T5: 2–5 EU/s' } },
      { label: { ru: 'Накопитель T1', en: 'Storage T1' }, value: { ru: '100 000 EU · 128 EU/с', en: '100,000 EU · 128 EU/s' } },
      { label: { ru: 'Накопитель T3', en: 'Storage T3' }, value: { ru: '2 000 000 EU · 2 048 EU/с', en: '2,000,000 EU · 2,048 EU/s' } },
    ],
    stages: [
      { title: { ru: '1. Поставьте источник', en: '1. Place a source' }, text: { ru: 'Угольный генератор и паровая турбина дают до 40 EU/с. Генераторы на топливе расходуют его только тогда, когда сети действительно нужна энергия.', en: 'The coal generator and steam turbine provide up to 40 EU/s. Fuel generators consume fuel only while the grid actually needs energy.' }, links: ['coal_generator', 'steam_turbine'] },
      { title: { ru: '2. Соедините проводом', en: '2. Connect conductors' }, text: { ru: 'Подведите медный или изолированный медный провод к стороне генератора и машины. Конвейеры тоже проводят электричество вдоль всей линии, поэтому достаточно подключить один участок ленты.', en: 'Run copper or insulated copper wire to the side of a generator and machine. Conveyors also conduct power along the full belt line, so one wired belt segment can power the chain.' }, links: ['copper_wire', 'insulated_copper_wire', 'conveyor_t2'] },
      { title: { ru: '3. Добавьте запас', en: '3. Add storage' }, text: { ru: 'Накопитель принимает излишек генерации и покрывает кратковременный дефицит. Его максимальный ввод и вывод ограничивает скорость компенсации.', en: 'Storage absorbs surplus generation and covers short deficits. Its maximum input/output rate limits how quickly it can compensate.' }, links: ['energy_storage_t1', 'energy_storage_t2', 'energy_storage_t3'] },
      { title: { ru: '4. Следите за балансом', en: '4. Watch the balance' }, text: { ru: 'Сеть считается устойчивой, когда у неё есть генератор, потребитель и нулевой дефицит. Если машина останавливается, сначала проверьте непрерывность проводов, топливо и суммарный спрос.', en: 'A grid is stable when it has a generator, a consumer, and no deficit. If a machine stops, check conductor continuity, fuel, and total demand first.' }, links: [] },
    ],
    tips: [
      { ru: 'Солнечные панели имеют внутренний буфер на 30 секунд номинальной выработки; дождь и гроза снижают их мощность.', en: 'Solar panels have an internal buffer equal to 30 seconds of nominal production; rain and storms reduce their output.' },
      { ru: 'Распределение идёт пропорционально свободному месту во внутренних буферах машин — одна машина не забирает весь поток.', en: 'Distribution is proportional to free room in machine buffers, so one consumer cannot take the entire supply.' },
    ],
    equipment: ['coal_generator', 'steam_turbine', 'solar_panel', 'advanced_solar_panel', 'energy_storage_t1', 'energy_storage_t2', 'energy_storage_t3', 'copper_wire', 'insulated_copper_wire'],
  },
  {
    id: 'fluids', color: [0.16, 0.62, 0.91, 1],
    title: { ru: 'Жидкости и пар', en: 'Fluids and steam' },
    subtitle: { ru: 'Насосы, котлы, трубы, клапаны и резервуары.', en: 'Pumps, boilers, pipes, valves, and tanks.' },
    intro: { ru: 'Жидкостная сеть переносит воду, пар, нефть и продукты переработки между соседними машинами. Пропускная способность всей связной сети равна скорости самого слабого участка.', en: 'A fluid network moves water, steam, oil, and processed fluids between adjacent machines. The throughput of an entire connected network is limited by its slowest segment.' },
    facts: [
      { label: { ru: 'Труба T1', en: 'Pipe T1' }, value: { ru: '12 л/с', en: '12 L/s' } },
      { label: { ru: 'Труба T2 и клапан', en: 'Pipe T2 and valve' }, value: { ru: '30 л/с', en: '30 L/s' } },
      { label: { ru: 'Насосы воды', en: 'Water pumps' }, value: { ru: '4 / 16 / 8 л/с', en: '4 / 16 / 8 L/s' } },
      { label: { ru: 'Электронасос', en: 'Electric pump' }, value: { ru: '10 EU/с', en: '10 EU/s' } },
    ],
    stages: [
      { title: { ru: '1. Добудьте воду', en: '1. Pump water' }, text: { ru: 'Насос должен стоять на клетке воды. Механический насос даёт 4 л/с, паровой — 16 л/с и тратит 1 литр пара на 16 литров воды, электрический — 8 л/с при 10 EU/с.', en: 'A pump must stand on a water tile. The mechanical pump outputs 4 L/s, the steam pump outputs 16 L/s and consumes 1 litre of steam per 16 litres of water, and the electric pump outputs 8 L/s at 10 EU/s.' }, links: ['mechanical_water_pump', 'steam_water_pump', 'water_pump'] },
      { title: { ru: '2. Получите пар', en: '2. Produce steam' }, text: { ru: 'Подайте воду и топливо в паровой котёл. Для устойчивой линии производительность котлов и трубы должна быть не ниже суммарного расхода активных паровых машин.', en: 'Feed water and fuel into a steam boiler. For a stable line, boiler production and pipe throughput must meet the combined draw of active steam machines.' }, links: ['steam_boiler', 'steam_furnace', 'steam_crusher', 'steam_press', 'steam_assembler'] },
      { title: { ru: '3. Разведите трубы', en: '3. Route pipes' }, text: { ru: 'Машина подключается, когда касается трубы стороной. Не смешивайте длинные загруженные ветви: одна труба T1 внутри сети ограничит её целиком до 12 л/с.', en: 'A machine connects when one of its sides touches a pipe. Avoid mixing long saturated branches: one T1 pipe anywhere in the network caps the whole network at 12 L/s.' }, links: ['fluid_pipe', 'fluid_pipe_t2'] },
      { title: { ru: '4. Управляйте потоком', en: '4. Control flow' }, text: { ru: 'Клапан задаёт направление и фильтр жидкости. В режиме перелива он открывается только после заполнения источника до заданного порога; стандартный порог — 80%.', en: 'A valve sets flow direction and a fluid filter. In overflow mode it opens only when the source reaches the configured fill threshold; the default is 80%.' }, links: ['fluid_valve', 'fluid_tank_t1'] },
    ],
    tips: [
      { ru: 'Резервуары служат буфером, но сеть намеренно не переливает жидкость напрямую из одного резервуара в другой.', en: 'Tanks provide buffering, but the network intentionally does not transfer directly from one storage tank to another.' },
      { ru: 'Предупреждение о голодании означает, что у паровой машины есть работа, но во входном баке нет пара.', en: 'A starvation warning means a steam machine has pending work but no steam in its input tank.' },
    ],
    equipment: ['mechanical_water_pump', 'steam_water_pump', 'water_pump', 'steam_boiler', 'fluid_pipe', 'fluid_pipe_t2', 'fluid_valve', 'fluid_tank_t1', 'fluid_tank_t3', 'oil_pump'],
  },
  {
    id: 'logistics', color: [0.92, 0.38, 0.12, 1],
    title: { ru: 'Предметная логистика', en: 'Item logistics' },
    subtitle: { ru: 'Конвейеры, манипуляторы, фильтры и разделители.', en: 'Conveyors, inserters, filters, and splitters.' },
    intro: { ru: 'Конвейеры перемещают предметы в направлении стрелки, а манипуляторы забирают их из блока позади и кладут в блок впереди. Машины и буры сами выталкивают готовую продукцию на подходящую ленту — конвейер не вытягивает предметы из инвентаря.', en: 'Conveyors move items in their facing direction, while inserters pull from the block behind and place into the block ahead. Machines and drills push completed output onto a suitable belt; conveyors do not pull from inventories.' },
    facts: [
      { label: { ru: 'Груз конвейера', en: 'Belt payload' }, value: { ru: '1 стек на клетке', en: '1 stack per tile' } },
      { label: { ru: 'Манипулятор', en: 'Inserter' }, value: { ru: '1 предмет / 1,5 с', en: '1 item / 1.5 s' } },
      { label: { ru: 'Фильтр', en: 'Filter' }, value: { ru: 'до 24 ID', en: 'up to 24 IDs' } },
      { label: { ru: 'Питание лент', en: 'Belt power' }, value: { ru: 'T1 без EU; T2–T5 требуют EU', en: 'T1 uses no EU; T2–T5 require EU' } },
    ],
    stages: [
      { title: { ru: '1. Направьте поток', en: '1. Direct the line' }, text: { ru: 'Поверните каждую ленту к следующему блоку. Конвейер передаёт груз другой ленте, сундуку, входу машины или правильному порту бура.', en: 'Rotate each belt toward the next block. A conveyor hands its payload to another belt, a chest, a machine input, or the correct drill port.' }, links: ['conveyor', 'conveyor_t2'] },
      { title: { ru: '2. Заберите из инвентаря', en: '2. Extract from inventory' }, text: { ru: 'Поставьте механический манипулятор между источником и приёмником: источник должен быть сзади стрелки, приёмник — спереди. Он работает с сундуками, выходами машин и конвейерами.', en: 'Place a mechanical inserter between source and destination: the source belongs behind its arrow and the destination ahead. It works with chests, machine outputs, and conveyors.' }, links: ['mechanical_inserter', 'chest_t1'] },
      { title: { ru: '3. Настройте фильтры', en: '3. Configure filters' }, text: { ru: 'Режим разрешения пропускает только перечисленные предметы, режим блокировки — все, кроме перечисленных. Без фильтра линия принимает любой подходящий предмет.', en: 'Allow mode passes only listed items; block mode passes everything except listed items. With no filter, the line accepts every compatible item.' }, links: ['mechanical_inserter', 'conveyor_t3'] },
      { title: { ru: '4. Разделите производство', en: '4. Split production' }, text: { ru: 'Разделитель принимает поток сзади и отправляет его влево или вправо. При равных приоритетах стороны чередуются; если одна заблокирована, используется другая. Фильтры и запросы машин влияют на выбор выхода.', en: 'A splitter accepts input from behind and sends it left or right. Equal-priority sides alternate; if one is blocked, the other is used. Filters and downstream machine requests affect output selection.' }, links: ['conveyor_splitter'] },
    ],
    tips: [
      { ru: 'Конвейерная линия передаёт запросы ингредиентов назад до 128 узлов, поэтому манипулятор может подавать только реально нужные машине материалы.', en: 'A belt line propagates ingredient requests backward for up to 128 nodes, allowing an inserter to supply only what the destination machine currently needs.' },
      { ru: 'Затор возникает, когда следующий блок не принимает груз. Освободите выход, проверьте направление и фильтры.', en: 'A jam occurs when the next block cannot accept the payload. Clear the destination and check direction and filters.' },
    ],
    equipment: ['mechanical_inserter', 'conveyor', 'conveyor_t2', 'conveyor_t3', 'conveyor_t4', 'conveyor_t5', 'conveyor_splitter', 'chest_t1'],
  },
  {
    id: 'me-network', color: [0.55, 0.30, 0.88, 1],
    title: { ru: 'ME-сеть', en: 'ME network' },
    subtitle: { ru: 'Цифровое хранение предметов и жидкостей, терминалы и шины.', en: 'Digital item and fluid storage, terminals, and buses.' },
    intro: { ru: 'ME-сеть объединяет контроллер, кабели, дисководы, терминалы, шины, интерфейсы и молекулярные сборщики, соприкасающиеся сторонами. Каналы не ограничены: важны только связность и работающий контроллер.', en: 'An ME network joins orthogonally adjacent controllers, cables, drives, terminals, buses, interfaces, and molecular assemblers. Channels are unlimited; only connectivity and an online controller matter.' },
    facts: [
      { label: { ru: 'Контроллер', en: 'Controller' }, value: { ru: '12 EU/с', en: '12 EU/s' } },
      { label: { ru: 'Цикл шин', en: 'Bus interval' }, value: { ru: '0,4 с', en: '0.4 s' } },
      { label: { ru: 'Перенос предметов', en: 'Item transfer' }, value: { ru: 'до 64 за цикл', en: 'up to 64 per cycle' } },
      { label: { ru: 'Перенос жидкостей', en: 'Fluid transfer' }, value: { ru: 'до 50 л за цикл', en: 'up to 50 L per cycle' } },
    ],
    stages: [
      { title: { ru: '1. Запитайте контроллер', en: '1. Power the controller' }, text: { ru: 'Подключите ME-контроллер к обычной энергосети. Пока во внутреннем буфере есть энергия, связанный компонент ME считается активным.', en: 'Connect the ME controller to the regular power grid. Its connected ME component remains online while the controller has energy in its internal buffer.' }, links: ['me_controller', 'copper_wire'] },
      { title: { ru: '2. Соберите связный компонент', en: '2. Build one connected component' }, text: { ru: 'Соединяйте блоки сторонами напрямую или через ME-кабель. Диагональное касание не соединяет сеть; ограничений по числу каналов нет.', en: 'Connect blocks along their sides directly or with ME cable. Diagonal contact does not connect the network, and there is no channel limit.' }, links: ['me_cable', 'me_drive', 'me_terminal', 'me_crafting_terminal'] },
      { title: { ru: '3. Установите ячейки', en: '3. Install storage cells' }, text: { ru: 'Дисковод принимает предметные и жидкостные ячейки. Ёмкость ограничена одновременно общим количеством и числом разных типов, поэтому большие объёмы одного материала и много редких предметов требуют разного планирования.', en: 'A drive accepts item and fluid cells. Capacity is limited by both total quantity and distinct types, so bulk materials and many rare items require different planning.' }, links: ['me_drive', 'me_item_cell_1k', 'me_item_cell_64k', 'me_fluid_cell_1k', 'me_fluid_cell_64k'] },
      { title: { ru: '4. Автоматизируйте ввод и вывод', en: '4. Automate import and export' }, text: { ru: 'Шина импорта забирает предметы и жидкости из соседнего блока; пустой фильтр означает «всё». Шина экспорта отправляет только перечисленные фильтром ресурсы. Для каждой категории доступно до четырёх фильтров.', en: 'An import bus pulls items and fluids from an adjacent block; an empty filter means everything. An export bus pushes only resources listed in its filters. Each bus supports up to four item and four fluid filters.' }, links: ['me_import_bus', 'me_export_bus', 'me_interface', 'me_molecular_assembler'] },
    ],
    tips: [
      { ru: 'Ячейка 1K хранит 2 000 предметов пяти типов; 64K — 128 000 предметов пятидесяти типов.', en: 'A 1K item cell holds 2,000 items across five types; a 64K cell holds 128,000 items across fifty types.' },
      { ru: 'Жидкостные ячейки хранят и газы: 1K вмещает 4 000 л двух типов, 64K — 256 000 л девяти типов.', en: 'Fluid cells also store gases: 1K holds 4,000 L across two types, while 64K holds 256,000 L across nine types.' },
    ],
    equipment: ['me_controller', 'me_cable', 'me_drive', 'me_terminal', 'me_crafting_terminal', 'me_import_bus', 'me_export_bus', 'me_interface', 'me_molecular_assembler', 'me_item_cell_1k', 'me_item_cell_64k', 'me_fluid_cell_1k', 'me_fluid_cell_64k'],
  },
];

const fluidNamesRu = {
  water: 'Вода', steam: 'Пар', creosote: 'Креозот', crude_oil: 'Сырая нефть', lava: 'Лава', refinery_gas: 'Нефтезаводской газ', gasoline: 'Бензин', kerosene: 'Керосин', diesel: 'Дизель', heavy_oil: 'Мазут', bitumen: 'Битум', fuel_blend: 'Топливная смесь',
  molten_iron: 'Расплавленное железо', molten_copper: 'Расплавленная медь', molten_tin: 'Расплавленное олово', molten_gold: 'Расплавленное золото', molten_silver: 'Расплавленное серебро', molten_steel: 'Расплавленная сталь', molten_bronze: 'Расплавленная бронза', molten_titanium: 'Расплавленный титан', molten_mythril: 'Расплавленный мифрил', molten_electrum: 'Расплавленный электрум',
};

const fluidDescriptions = {
  water: { ru: 'Основная технологическая жидкость. Используется для производства пара, промывки руды, закалки и химических рецептов.', en: 'The basic process fluid, used for steam generation, ore washing, quenching, and chemical recipes.' },
  steam: { ru: 'Рабочее тело паровой эпохи. Питает паровые машины, насос и турбину.', en: 'The working fluid of the Steam Age, powering steam machines, the steam pump, and the turbine.' },
  creosote: { ru: 'Жидкий побочный продукт коксовой печи. Служит резервным топливом котла и компонентом углехимии.', en: 'A liquid by-product of the coke oven, used as reserve boiler fuel and in carbon chemistry.' },
  crude_oil: { ru: 'Сырьё нефтехимии, добываемое насосом из месторождений и разделяемое дистилляционной колонной.', en: 'Petrochemical feedstock pumped from deposits and separated in a distillation column.' },
  lava: { ru: 'Горячая природная жидкость из подземных месторождений. Перемещается теми же насосами, трубами и ячейками, что и другие жидкости.', en: 'A hot natural fluid from underground deposits, moved by the same pumps, pipes, and cells as other fluids.' },
  refinery_gas: { ru: 'Лёгкая газовая фракция перегонки нефти. В трубах и ME-хранилище учитывается как обычная жидкость.', en: 'A light gaseous fraction of crude-oil distillation, handled as an ordinary fluid by pipes and ME storage.' },
  gasoline: { ru: 'Лёгкое моторное топливо и основной компонент топливной смеси.', en: 'A light motor fuel and primary component of fuel blend.' },
  kerosene: { ru: 'Средняя нефтяная фракция, повышающая выход улучшенных рецептов топливной смеси.', en: 'A middle petroleum fraction that improves higher-yield fuel-blend recipes.' },
  diesel: { ru: 'Тяжёлая топливная фракция, используемая в нескольких вариантах топливной смеси.', en: 'A heavier fuel fraction used by several fuel-blend recipes.' },
  heavy_oil: { ru: 'Тяжёлый остаток перегонки, применяемый в самом эффективном четырёхкомпонентном смешивании топлива.', en: 'A heavy distillation residue used by the most efficient four-component fuel-blend recipe.' },
  bitumen: { ru: 'Самая тяжёлая фракция нефти, получаемая в дистилляционной колонне.', en: 'The heaviest crude-oil fraction produced by the distillation column.' },
  fuel_blend: { ru: 'Смешанное жидкое топливо. Смеситель производит его по рецептам из двух, трёх или четырёх нефтяных фракций.', en: 'A blended liquid fuel produced in two-, three-, or four-fraction mixer recipes.' },
};

const fluidCategoryTitles = {
  basic: { ru: 'Вода и пар', en: 'Water and steam' },
  petroleum: { ru: 'Нефть и топливо', en: 'Petroleum and fuels' },
  molten: { ru: 'Расплавы металлов', en: 'Molten metals' },
};

const pageRoutes = new Set(['home', 'about', 'items', 'recipes', 'crafting-balance', 'bosses', 'mobs', 'machines', 'technologies', 'quests', 'npcs', 'systems', 'fluids', 'achievements', 'mechanics', 'gathering', 'interface', 'exploration', 'optimization', 'multiplayer', 'energy', 'logistics', 'steam', 'ore-processing', 'search']);

const bossNames = {
  ent: { ru: 'Энт', en: 'The Ent' },
  dune_colossus: { ru: 'Песчаный колосс', en: 'Dune Colossus' },
  frost_warden: { ru: 'Ледяной страж', en: 'Frost Warden' },
  mire_hydra: { ru: 'Болотная гидра', en: 'Mire Hydra' },
  thorn_matriarch: { ru: 'Шипастая матриархиня', en: 'Thorn Matriarch' },
  solar_tyrant: { ru: 'Солнечный тиран', en: 'Solar Tyrant' },
  abyss_leviathan: { ru: 'Левиафан бездны', en: 'Abyss Leviathan' },
  rot_king: { ru: 'Король гнили', en: 'Rot King' },
  primal_guardian: { ru: 'Первобытный страж', en: 'Primal Guardian' },
};

const bossDescriptions = {
  ent: { ru: 'Древний хранитель леса, управляющий корнями и молодыми энтами.', en: 'An ancient forest guardian that commands roots and young ents.' },
  dune_colossus: { ru: 'Массивный страж пустыни, поднимающий песчаные взрывы и сокрушительные атаки.', en: 'A massive desert guardian that unleashes sand bursts and crushing attacks.' },
  frost_warden: { ru: 'Ледяной страж северных земель, создающий морозные волны и ледяные удары.', en: 'An icy guardian of the northern lands that creates frost waves and ice strikes.' },
  mire_hydra: { ru: 'Многоголовый хищник болот, атакующий кислотой и призывающий болотных существ.', en: 'A many-headed swamp predator that attacks with acid and summons mire creatures.' },
  thorn_matriarch: { ru: 'Хозяйка джунглей, покрывающая арену шипами и стремительно атакующая лозами.', en: 'The ruler of the jungle, covering the arena with thorns and lunging with vines.' },
  solar_tyrant: { ru: 'Повелитель солнечного каньона, использующий огненные удары и взрывы света.', en: 'The ruler of Sunny Canyon, wielding fiery strikes and bursts of light.' },
  abyss_leviathan: { ru: 'Ледяное чудовище бездны, способное раскалывать лёд и сметать игрока рывком.', en: 'An icy abyssal beast that shatters ice and overwhelms the player with charging attacks.' },
  rot_king: { ru: 'Владыка гниющего болота, распространяющий токсины и призывающий слизней.', en: 'The ruler of the Rotting Bog, spreading toxins and summoning slimes.' },
  primal_guardian: { ru: 'Последний хранитель первобытных дебрей, сочетающий древнюю силу и быстрые атаки.', en: 'The final guardian of the Primeval Thicket, combining ancient power with swift attacks.' },
};

const bossBiomeIds = {
  ForestBiome: 'forest', DesertBiome: 'desert', SnowBiome: 'snow', SwampBiome: 'swamp', JungleBiome: 'jungle',
  SunnyCanyonBiome: 'sunny-canyon', IcyAbyssBiome: 'icy-abyss', RottingBogBiome: 'rotting-bog', PrimevalThicketBiome: 'primeval-thicket',
};

const mobNamesRu = {
  woodling: 'Древесник', forest_wolf: 'Лесной волк', bark_beetle: 'Короковый жук', sand_scarab: 'Песчаный скарабей', cactus_stalker: 'Кактусовый охотник', dust_wisp: 'Пыльный дух',
  frost_wolf: 'Морозный волк', ice_wisp: 'Ледяной дух', snow_golem: 'Снежный голем', mire_leech: 'Болотная пиявка', bog_slime: 'Болотный слизень', mosquito_swarm: 'Рой комаров',
  jungle_panther: 'Пантера джунглей', vine_lurker: 'Лозовый скрытень', sporeling: 'Споровик', ember_beetle: 'Огненный жук', ash_hound: 'Пепельная гончая', flare_wisp: 'Солнечный дух',
  ice_stalker: 'Ледяной охотник', shardling: 'Осколочник', frost_golem: 'Морозный голем', toxic_slime: 'Токсичный слизень', rot_hound: 'Гнилая гончая', bog_witch: 'Болотная ведьма',
  razor_raptor: 'Бритвенный раптор', ancient_vine: 'Древняя лоза', primal_beetle: 'Первобытный жук',
};

const mobRoleTitles = {
  brute: { ru: 'Тяжёлый боец', en: 'Brute' },
  rusher: { ru: 'Штурмовик', en: 'Rusher' },
  skirmisher: { ru: 'Застрельщик', en: 'Skirmisher' },
};

const machineCategoryTitles = {
  conveyors: { ru: 'Конвейеры', en: 'Conveyors' },
  generators: { ru: 'Генераторы', en: 'Generators' },
  machines: { ru: 'Машины', en: 'Machines' },
  storage: { ru: 'Хранилища', en: 'Storage' },
};


function loadItemTranslations() {
  const translations = new Map();
  const lines = readFileSync(resolve(assetsRoot, 'locale/items.csv'), 'utf8').split(/\r?\n/);
  for (const line of lines.slice(1)) {
    if (!line) continue;
    const [key, en, ru] = parseCsvLine(line);
    if (key) translations.set(key, { en, ru });
  }
  return translations;
}


function loadQuestTranslations() {
  const translations = new Map();
  const lines = readFileSync(questTranslationsPath, 'utf8').split(/\r?\n/);
  for (const line of lines.slice(1)) {
    if (!line) continue;
    const [key, en, ru] = parseCsvLine(line);
    if (key) translations.set(key, { en: en || key, ru: ru || key });
  }
  return translations;
}


function loadMenuTranslations() {
  const translations = new Map();
  const lines = readFileSync(menuTranslationsPath, 'utf8').split(/\r?\n/);
  for (const line of lines.slice(1)) {
    if (!line) continue;
    const [key, en, ru] = parseCsvLine(line);
    if (key) translations.set(key, { en: en || key, ru: ru || key });
  }
  return translations;
}


function tresString(content, field) {
  const match = content.match(new RegExp(`^${field} = "([^"]*)"$`, 'm'));
  return match?.[1] ?? '';
}


function tresNumber(content, field) {
  const match = content.match(new RegExp(`^${field} = (-?\\d+(?:\\.\\d+)?)$`, 'm'));
  return match ? Number(match[1]) : null;
}


function tresBoolean(content, field) {
  const value = content.match(new RegExp(`^${field} = (true|false)$`, 'm'))?.[1];
  return value === undefined ? null : value === 'true';
}


function tresVector2(content, field) {
  const match = content.match(new RegExp(`^${field} = Vector2i\\((-?\\d+), (-?\\d+)\\)$`, 'm'));
  return match ? { x: Number(match[1]), y: Number(match[2]) } : { x: 1, y: 1 };
}


function tresDictionary(content, field) {
  const declaration = content.match(new RegExp(`^${field} = \\{`, 'm'));
  if (!declaration) return {};
  const openingIndex = declaration.index + declaration[0].lastIndexOf('{');
  const closingIndex = findClosingBrace(content, openingIndex);
  if (closingIndex <= openingIndex) return {};
  const values = {};
  for (const match of content.slice(openingIndex + 1, closingIndex).matchAll(/"([^"]+)"\s*:\s*(-?\d+(?:\.\d+)?)/g)) values[match[1]] = Number(match[2]);
  return values;
}


function packedStrings(content, field) {
  const match = content.match(new RegExp(`^${field} = PackedStringArray\\((.*)\\)$`, 'm'));
  return match ? [...match[1].matchAll(/"([^"]+)"/g)].map((entry) => entry[1]) : [];
}


function packedNumbers(content, field) {
  const match = content.match(new RegExp(`^${field} = PackedInt32Array\\((.*)\\)$`, 'm'));
  return match ? match[1].split(',').map((value) => Number(value.trim())).filter(Number.isFinite) : [];
}


function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}


function pngDimensions(texturePath) {
  if (!texturePath.endsWith('.png')) return null;
  const filePath = resolve(projectRoot, texturePath);
  if (!existsSync(filePath)) return null;
  const buffer = readFileSync(filePath);
  if (buffer.length < 24 || buffer.toString('ascii', 1, 4) !== 'PNG') return null;
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}


function itemTexture(content) {
  const textures = new Map();
  const externalPattern = /\[ext_resource type="Texture2D" path="res:\/\/([^"]+)"[^\]]*id="([^"]+)"\]/g;
  for (const match of content.matchAll(externalPattern)) textures.set(match[2], match[1]);
  const assignment = content.match(/^texture = (ExtResource|SubResource)\("([^"]+)"\)$/m);
  if (!assignment) return { path: '', atlas: null, dimensions: null };

  let texturePath = '';
  let atlas = null;
  if (assignment[1] === 'ExtResource') {
    texturePath = textures.get(assignment[2]) ?? '';
  } else {
    const blockPattern = new RegExp(`\\[sub_resource type="AtlasTexture" id="${escapeRegExp(assignment[2])}"\\]([\\s\\S]*?)(?=\\n\\[|$)`);
    const block = content.match(blockPattern)?.[1] ?? '';
    const atlasId = block.match(/^atlas = ExtResource\("([^"]+)"\)$/m)?.[1];
    const region = block.match(/^region = Rect2\(([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+)\)$/m);
    texturePath = atlasId ? textures.get(atlasId) ?? '' : '';
    if (region) atlas = { x: Number(region[1]), y: Number(region[2]), width: Number(region[3]), height: Number(region[4]) };
  }

  return {
    path: texturePath ? `/assets/${texturePath.replace(/^assets\//, '')}` : '',
    atlas,
    dimensions: texturePath ? pngDimensions(texturePath) : null,
  };
}


function itemColor(content) {
  const match = content.match(/^item_color = Color\(([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+)\)$/m);
  return match ? match.slice(1).map(Number) : [0.35, 0.55, 0.68, 1];
}


function buildItemTextureIndex() {
  const index = new Map();
  const directories = [itemTexturesRoot];
  while (directories.length) {
    const directory = directories.pop();
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const entryPath = resolve(directory, entry.name);
      if (entry.isDirectory()) {
        directories.push(entryPath);
        continue;
      }
      const extension = extname(entry.name).toLowerCase();
      if (!['.png', '.webp', '.jpg', '.jpeg'].includes(extension)) continue;
      const key = entry.name.slice(0, -extension.length).toLowerCase();
      if (!index.has(key)) index.set(key, entryPath);
    }
  }
  return index;
}


const itemTextureIndex = buildItemTextureIndex();


function fallbackItemTexture(id) {
  const filePath = itemTextureIndex.get(id.toLowerCase());
  if (!filePath) return { path: '', atlas: null, dimensions: null };
  const pathFromProject = `assets/${relative(assetsRoot, filePath).replaceAll('\\', '/')}`;
  return { path: `/${pathFromProject}`, atlas: null, dimensions: pngDimensions(pathFromProject) };
}


function itemCategory(item) {
  const id = item.id.toLowerCase();
  if (id.startsWith('page_') || item.useAction === 'open_codex' || id === 'codex') return 'knowledge';
  if (item.foodValue > 0 || /^(apple|berry|beet|carrot|cucumber|flower|mushroom|potato|pumpkin|tomato)/.test(id)) return 'food';
  if (item.toolType === 'armor') return 'equipment';
  if (['sword', 'spear', 'hammer', 'wand'].includes(item.toolType)) return 'weapons';
  if (item.toolType || /(_drill|drill_head|bucket)/.test(id)) return 'tools';
  if (item.fluidCapacity > 0 || /(fluid|pipe|pump|tank)/.test(id)) return 'fluids';
  if (item.blockId || /(furnace|generator|compressor|crusher|centrifuge|reactor|oven|machine|conveyor|terminal|controller|solar_panel)/.test(id)) return 'machines';
  if (/(_ore|raw_|coal$|coke$|sand$|stone$|wood$|fiber$|resin$|shard$)/.test(id)) return 'resources';
  if (/(_ingot|_plate|_wire|_gear|_rod|_bolt|_dust|_foil|_ring|_spring|_rotor|circuit|board|processor|casing|frame|coil|capacitor|diode)/.test(id)) return 'components';
  return 'materials';
}


function loadItems(translations) {
  const items = new Map();
  for (const fileName of readdirSync(itemDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const content = readFileSync(resolve(itemDefinitionsRoot, fileName), 'utf8');
    const id = tresString(content, 'id');
    if (!id) continue;
    const texture = itemTexture(content);
    const item = {
      id,
      descriptionKey: tresString(content, 'description'),
      nameKey: tresString(content, 'name'),
      rarity: tresString(content, 'rarity') || 'common',
      power: tresNumber(content, 'power'),
      maxStack: tresNumber(content, 'max_stack') ?? 99,
      texture: texture.path ? texture : fallbackItemTexture(id),
      toolType: tresString(content, 'tool_type'),
      equipSlot: tresString(content, 'equip_slot'),
      useAction: tresString(content, 'use_action'),
      fluidCapacity: tresNumber(content, 'fluid_capacity') ?? 0,
      foodValue: tresNumber(content, 'food_value') ?? 0,
      blockId: tresString(content, 'block_id'),
      color: itemColor(content),
    };
    item.category = itemCategory(item);
    items.set(id, item);
  }
  return { items, translations };
}


function fallbackItemTitle(id) {
  return id.replaceAll('_', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());
}


const categoryTitles = {
  components: { ru: 'Компоненты', en: 'Components' },
  equipment: { ru: 'Снаряжение', en: 'Equipment' },
  fluids: { ru: 'Жидкости', en: 'Fluids' },
  food: { ru: 'Еда и растения', en: 'Food and plants' },
  knowledge: { ru: 'Знания', en: 'Knowledge' },
  machines: { ru: 'Машины и блоки', en: 'Machines and blocks' },
  materials: { ru: 'Материалы', en: 'Materials' },
  resources: { ru: 'Ресурсы', en: 'Resources' },
  tools: { ru: 'Инструменты', en: 'Tools' },
  weapons: { ru: 'Оружие', en: 'Weapons' },
};

const recipeCategoryTitles = {
  blocks: { ru: 'Строительные блоки', en: 'Building blocks' },
  components: { ru: 'Компоненты', en: 'Components' },
  cooking: { ru: 'Кулинария', en: 'Cooking' },
  electrical: { ru: 'Электротехника', en: 'Electrical engineering' },
  fluids: { ru: 'Жидкостные системы', en: 'Fluid systems' },
  machines: { ru: 'Машины', en: 'Machines' },
  materials: { ru: 'Материалы', en: 'Materials' },
  misc: { ru: 'Основы и разное', en: 'Basics and misc.' },
  storage: { ru: 'Хранилища', en: 'Storage' },
  tools: { ru: 'Инструменты и снаряжение', en: 'Tools and equipment' },
};

const rarityTitles = {
  common: { ru: 'Обычная', en: 'Common' },
  uncommon: { ru: 'Необычная', en: 'Uncommon' },
  rare: { ru: 'Редкая', en: 'Rare' },
  epic: { ru: 'Эпическая', en: 'Epic' },
  legendary: { ru: 'Легендарная', en: 'Legendary' },
};


function localizedResourceText(value, language) {
  const translated = itemTranslations.get(value)?.[language];
  if (translated) return translated;
  if (value.startsWith('item.')) return '';
  if (language === 'ru' || /^[\x00-\x7F]*$/.test(value)) return value;
  return '';
}


function localizedItem(item, language) {
  const name = localizedResourceText(item.nameKey, language) || fallbackItemTitle(item.id);
  const description = localizedResourceText(item.descriptionKey, language);
  return {
    ...item,
    title: name,
    description,
    categoryTitle: categoryTitles[item.category]?.[language] ?? item.category,
    rarityTitle: rarityTitles[item.rarity]?.[language] ?? item.rarity,
  };
}


const { items: itemsById, translations: itemTranslations } = loadItems(loadItemTranslations());


function loadBiomeResourceIds() {
  const resources = new Map();
  const add = (biomeResource, itemId, source) => {
    if (!resources.has(biomeResource)) resources.set(biomeResource, new Map());
    resources.get(biomeResource).set(itemId, source);
  };

  for (const fileName of readdirSync(oreDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const content = readFileSync(resolve(oreDefinitionsRoot, fileName), 'utf8');
    const itemId = tresString(content, 'resource_item_id');
    for (const biomeResource of packedStrings(content, 'spawn_biomes')) {
      if (itemId) add(biomeResource, itemId, 'ore');
    }
  }

  for (const fileName of readdirSync(forageDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const content = readFileSync(resolve(forageDefinitionsRoot, fileName), 'utf8');
    const itemId = tresString(content, 'resource_item_id');
    const spawnBlock = content.match(/^spawn_chance_by_biome = \{([\s\S]*?)^\}$/m)?.[1] ?? '';
    for (const match of spawnBlock.matchAll(/^"([^"]+)":\s*([\d.]+)/gm)) {
      if (itemId && Number(match[2]) > 0) add(match[1], itemId, 'forage');
    }
  }
  return resources;
}


const biomeResourceIds = loadBiomeResourceIds();


function loadRecipes() {
  const recipes = [];
  for (const fileName of readdirSync(recipeDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const content = readFileSync(resolve(recipeDefinitionsRoot, fileName), 'utf8');
    const resultId = tresString(content, 'result_item_id');
    if (!resultId) continue;
    const ingredientIds = packedStrings(content, 'ingredient_ids');
    const ingredientCounts = packedNumbers(content, 'ingredient_counts');
    recipes.push({
      id: fileName.slice(0, -5),
      resultId,
      resultCount: tresNumber(content, 'result_count') ?? 1,
      category: tresString(content, 'category'),
      sortOrder: tresNumber(content, 'sort_order') ?? 0,
      requiredAge: tresNumber(content, 'required_age') ?? 1,
      unlockedByQuest: tresString(content, 'unlocked_by_quest'),
      unlockedByItem: tresString(content, 'unlocked_by_item'),
      sourcePath: relative(projectRoot, resolve(recipeDefinitionsRoot, fileName)).replaceAll('\\', '/'),
      ingredients: ingredientIds.map((id, index) => ({ id, count: ingredientCounts[index] ?? 1 })),
    });
  }
  return recipes.sort((left, right) => left.sortOrder - right.sortOrder || left.id.localeCompare(right.id));
}


const recipes = loadRecipes();


function localizedBalanceItem(itemId, language) {
  const item = itemsById.get(itemId);
  const localized = item ? localizedItem(item, language) : null;
  return localized
    ? { id: itemId, title: localized.title, texture: localized.texture, color: localized.color, exists: true, url: `/${language}/items/${encodeURIComponent(itemId)}` }
    : { id: itemId, title: fallbackItemTitle(itemId), texture: null, color: null, exists: false, url: `/${language}/items/${encodeURIComponent(itemId)}` };
}


function balanceWarning(kind, details, language) {
  const ru = language === 'ru';
  const itemTitle = details.itemId ? localizedBalanceItem(details.itemId, language).title : '';
  const messages = {
    missing_result: ru ? 'У результата нет определения предмета.' : 'The result has no item definition.',
    missing_ingredient: ru ? `Не найден ингредиент «${itemTitle}» (${details.itemId}).` : `Ingredient “${itemTitle}” (${details.itemId}) is missing.`,
    later_ingredient: ru ? `Ингредиент «${itemTitle}» открывается в эпохе ${details.ingredientAge}, позже самого рецепта.` : `Ingredient “${itemTitle}” unlocks in age ${details.ingredientAge}, later than this recipe.`,
    cycle: ru ? `Обнаружен цикл крафта через «${itemTitle}».` : `A crafting cycle was detected through “${itemTitle}”.`,
    duplicate_output: ru ? `Для результата существует ${details.count} рецепта. Проверь альтернативы и баланс выхода.` : `This result has ${details.count} recipes. Check alternative paths and output balance.`,
    unused_component: ru ? 'Компонент не используется ни в одном другом рецепте.' : 'This component is not used by any other recipe.',
    tier_regression: ru ? `Этот уровень не дороже предыдущего по итоговым входам цепочки (${details.current} против ${details.previous}).` : `This tier is not more expensive than the previous one in terminal chain inputs (${details.current} vs ${details.previous}).`,
    long_chain: ru ? `Цепочка содержит ${details.depth} уровней — игроку может быть трудно её читать и собирать.` : `The chain is ${details.depth} levels deep and may be difficult to understand and assemble.`,
  };
  const severities = {
    missing_result: 'error', missing_ingredient: 'error', cycle: 'error', later_ingredient: 'warning',
    duplicate_output: 'info', unused_component: 'info', tier_regression: 'warning', long_chain: 'warning',
  };
  return { kind, severity: severities[kind] ?? 'info', message: messages[kind] ?? kind, ...details };
}


function analyzeCraftingRecipes(liveRecipes, language) {
  const recipesByResult = new Map();
  for (const recipe of liveRecipes) {
    if (!recipesByResult.has(recipe.resultId)) recipesByResult.set(recipe.resultId, []);
    recipesByResult.get(recipe.resultId).push(recipe);
  }
  for (const alternatives of recipesByResult.values()) {
    alternatives.sort((left, right) => left.requiredAge - right.requiredAge || left.sortOrder - right.sortOrder || left.id.localeCompare(right.id));
  }
  const preferredRecipe = (itemId) => recipesByResult.get(itemId)?.[0] ?? null;

  const analyze = (recipe, includeChain = false) => {
    const raw = new Map();
    const intermediate = new Set();
    const cycles = new Set();
    let operations = 1;
    let maximumDepth = 1;

    const expand = (itemId, amount, depth, trail) => {
      maximumDepth = Math.max(maximumDepth, depth);
      if (trail.includes(itemId)) {
        cycles.add(itemId);
        raw.set(itemId, (raw.get(itemId) ?? 0) + amount);
        return;
      }
      const childRecipe = preferredRecipe(itemId);
      if (!childRecipe) {
        raw.set(itemId, (raw.get(itemId) ?? 0) + amount);
        return;
      }
      intermediate.add(itemId);
      const crafts = amount / Math.max(childRecipe.resultCount, 1);
      operations += crafts;
      for (const ingredient of childRecipe.ingredients) {
        expand(ingredient.id, ingredient.count * crafts, depth + 1, [...trail, itemId]);
      }
    };

    for (const ingredient of recipe.ingredients) expand(ingredient.id, ingredient.count, 2, [recipe.resultId]);

    const warnings = [];
    if (!itemsById.has(recipe.resultId)) warnings.push(balanceWarning('missing_result', {}, language));
    for (const ingredient of recipe.ingredients) {
      if (!itemsById.has(ingredient.id)) warnings.push(balanceWarning('missing_ingredient', { itemId: ingredient.id }, language));
      const childRecipe = preferredRecipe(ingredient.id);
      if (childRecipe && childRecipe.requiredAge > recipe.requiredAge) {
        warnings.push(balanceWarning('later_ingredient', { itemId: ingredient.id, ingredientAge: childRecipe.requiredAge }, language));
      }
    }
    for (const itemId of cycles) warnings.push(balanceWarning('cycle', { itemId }, language));
    const alternatives = recipesByResult.get(recipe.resultId) ?? [];
    if (alternatives.length > 1) warnings.push(balanceWarning('duplicate_output', { count: alternatives.length }, language));
    const usedIn = liveRecipes.filter((candidate) => candidate.ingredients.some((ingredient) => ingredient.id === recipe.resultId));
    const resultCategory = itemsById.get(recipe.resultId)?.category ?? '';
    if (usedIn.length === 0 && ['components', 'materials', 'resources'].includes(resultCategory)) {
      warnings.push(balanceWarning('unused_component', {}, language));
    }
    if (maximumDepth >= 10) warnings.push(balanceWarning('long_chain', { depth: maximumDepth }, language));

    const rawResources = [...raw.entries()]
      .map(([itemId, count]) => ({ ...localizedBalanceItem(itemId, language), count: balanceNumber(count) }))
      .sort((left, right) => right.count - left.count || left.title.localeCompare(right.title, language));
    const rawTotal = balanceNumber(rawResources.reduce((total, entry) => total + entry.count, 0));
    const localized = localizedRecipe(recipe, language);
    const result = {
      id: recipe.id,
      title: localized.result.title,
      result: localized.result,
      resultCount: recipe.resultCount,
      category: recipe.category,
      categoryTitle: localized.categoryTitle,
      requiredAge: recipe.requiredAge,
      station: localized.station,
      ingredients: localized.ingredients,
      directIngredientTotal: recipe.ingredients.reduce((total, ingredient) => total + ingredient.count, 0),
      rawResources,
      rawTotal,
      rawKinds: rawResources.length,
      depth: maximumDepth,
      operations: balanceNumber(operations),
      intermediateKinds: intermediate.size,
      usedInCount: usedIn.length,
      warningCount: warnings.filter((warning) => warning.severity !== 'info').length,
      errorCount: warnings.filter((warning) => warning.severity === 'error').length,
      warnings,
      sourcePath: recipe.sourcePath,
    };

    if (includeChain) {
      const chainNode = (itemId, amount, trail) => {
        const item = localizedBalanceItem(itemId, language);
        if (trail.includes(itemId)) return { item, count: balanceNumber(amount), cycle: true, recipeId: null, children: [] };
        const childRecipe = preferredRecipe(itemId);
        if (!childRecipe) return { item, count: balanceNumber(amount), raw: true, recipeId: null, children: [] };
        const crafts = amount / Math.max(childRecipe.resultCount, 1);
        return {
          item,
          count: balanceNumber(amount),
          raw: false,
          cycle: false,
          recipeId: childRecipe.id,
          crafts: balanceNumber(crafts),
          outputPerCraft: childRecipe.resultCount,
          children: childRecipe.ingredients.map((ingredient) => chainNode(ingredient.id, ingredient.count * crafts, [...trail, itemId])),
        };
      };
      result.chain = {
        item: localized.result,
        count: recipe.resultCount,
        recipeId: recipe.id,
        crafts: 1,
        outputPerCraft: recipe.resultCount,
        children: recipe.ingredients.map((ingredient) => chainNode(ingredient.id, ingredient.count, [recipe.resultId])),
      };
      result.usedIn = usedIn.map((candidate) => localizedRecipeSummary(candidate, language));
    }
    return result;
  };

  const analyses = liveRecipes.map((recipe) => analyze(recipe));
  const analysisById = new Map(analyses.map((entry) => [entry.id, entry]));
  for (const analysis of analyses) {
    const tierMatch = analysis.id.match(/^(.*)_t(\d+)$/);
    if (!tierMatch || Number(tierMatch[2]) <= 1) continue;
    const previous = analysisById.get(`${tierMatch[1]}_t${Number(tierMatch[2]) - 1}`);
    if (previous && analysis.rawTotal <= previous.rawTotal) {
      analysis.warnings.push(balanceWarning('tier_regression', { current: analysis.rawTotal, previous: previous.rawTotal }, language));
      analysis.warningCount += 1;
    }
  }
  return { analyses, analyze, recipesByResult };
}


function craftingBalanceCatalog(language) {
  const liveRecipes = loadRecipes();
  const { analyses } = analyzeCraftingRecipes(liveRecipes, language);
  const rawIds = new Set(analyses.flatMap((recipe) => recipe.rawResources.map((resource) => resource.id)));
  return {
    generatedAt: new Date().toISOString(),
    source: 'core/resources/crafting/recipes/*.tres',
    count: analyses.length,
    rawResourceCount: rawIds.size,
    warningCount: analyses.reduce((total, recipe) => total + recipe.warningCount, 0),
    errorCount: analyses.reduce((total, recipe) => total + recipe.errorCount, 0),
    categories: Object.keys(recipeCategoryTitles).map((id) => ({
      id,
      title: recipeCategoryTitles[id][language],
      count: analyses.filter((recipe) => recipe.category === id).length,
    })).filter((category) => category.count > 0),
    ages: [...new Set(analyses.map((recipe) => recipe.requiredAge))].sort((left, right) => left - right),
    recipes: analyses,
  };
}


function craftingBalanceDetails(recipeId, language) {
  const liveRecipes = loadRecipes();
  const recipe = liveRecipes.find((entry) => entry.id === recipeId);
  if (!recipe) return null;
  const { analyze } = analyzeCraftingRecipes(liveRecipes, language);
  return analyze(recipe, true);
}


function localizedRecipe(recipe, language) {
  const resultItem = itemsById.get(recipe.resultId);
  const localizedResult = resultItem ? localizedItem(resultItem, language) : null;
  const stationId = recipe.category === 'cooking' ? 'cooking_station' : 'workbench';
  const stationItem = itemsById.get(stationId);
  const localizedStation = stationItem ? localizedItem(stationItem, language) : null;
  return {
    ...recipe,
    categoryTitle: recipeCategoryTitles[recipe.category]?.[language] ?? recipe.category,
    station: {
      id: stationId,
      title: localizedStation?.title ?? (recipe.category === 'cooking' ? (language === 'ru' ? 'Костёр' : 'Campfire') : (language === 'ru' ? 'Верстак' : 'Workbench')),
      url: `/${language}/machines/${stationId}`,
      texture: localizedStation?.texture ?? null,
      color: localizedStation?.color ?? null,
      exists: Boolean(stationItem),
    },
    result: resultItem ? { id: resultItem.id, title: localizedResult.title, description: localizedResult.description, texture: localizedResult.texture, color: localizedResult.color, exists: true, url: `/${language}/items/${encodeURIComponent(resultItem.id)}` } : { id: recipe.resultId, title: fallbackItemTitle(recipe.resultId), texture: null, color: null, exists: false, url: `/${language}/items/${encodeURIComponent(recipe.resultId)}` },
    ingredients: recipe.ingredients.map((ingredient) => {
      const item = itemsById.get(ingredient.id);
      const localized = item ? localizedItem(item, language) : null;
      return { ...ingredient, title: localized?.title ?? fallbackItemTitle(ingredient.id), description: localized?.description ?? '', texture: localized?.texture ?? null, color: localized?.color ?? null, exists: Boolean(item), url: `/${language}/items/${encodeURIComponent(ingredient.id)}` };
    }),
    unlocks: localizedRecipeUnlocks(recipe, language),
  };
}


function itemDetails(item, language) {
  return {
    item: localizedItem(item, language),
    recipes: recipes.filter((recipe) => recipe.resultId === item.id).map((recipe) => localizedRecipe(recipe, language)),
    usedIn: recipes.filter((recipe) => recipe.ingredients.some((ingredient) => ingredient.id === item.id)).map((recipe) => localizedRecipe(recipe, language)),
  };
}


function findClosingBrace(source, openingIndex) {
  let depth = 0;
  let quoted = false;
  let escaped = false;
  let comment = false;
  for (let index = openingIndex; index < source.length; index += 1) {
    const character = source[index];
    if (comment) {
      if (character === '\n') comment = false;
      continue;
    }
    if (!quoted && character === '#') {
      comment = true;
      continue;
    }
    if (character === '"' && !escaped) quoted = !quoted;
    escaped = character === '\\' && !escaped;
    if (character !== '\\') escaped = false;
    if (quoted) continue;
    if (character === '{') depth += 1;
    if (character === '}') {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return -1;
}


function findClosingDelimiter(source, openingIndex, openingCharacter, closingCharacter) {
  let depth = 0;
  let quoted = false;
  let escaped = false;
  let comment = false;
  for (let index = openingIndex; index < source.length; index += 1) {
    const character = source[index];
    if (comment) {
      if (character === '\n') comment = false;
      continue;
    }
    if (!quoted && character === '#') {
      comment = true;
      continue;
    }
    if (character === '"' && !escaped) quoted = !quoted;
    escaped = character === '\\' && !escaped;
    if (character !== '\\') escaped = false;
    if (quoted) continue;
    if (character === openingCharacter) depth += 1;
    if (character === closingCharacter) {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return -1;
}


function splitTopLevelArguments(source) {
  const values = [];
  let value = '';
  let quoted = false;
  let escaped = false;
  let comment = false;
  let parenthesisDepth = 0;
  let bracketDepth = 0;
  let braceDepth = 0;
  for (let index = 0; index < source.length; index += 1) {
    const character = source[index];
    if (comment) {
      if (character === '\n') comment = false;
      continue;
    }
    if (!quoted && character === '#') {
      comment = true;
      continue;
    }
    if (character === '"' && !escaped) quoted = !quoted;
    escaped = character === '\\' && !escaped;
    if (character !== '\\') escaped = false;
    if (!quoted) {
      if (character === '(') parenthesisDepth += 1;
      if (character === ')') parenthesisDepth -= 1;
      if (character === '[') bracketDepth += 1;
      if (character === ']') bracketDepth -= 1;
      if (character === '{') braceDepth += 1;
      if (character === '}') braceDepth -= 1;
      if (character === ',' && parenthesisDepth === 0 && bracketDepth === 0 && braceDepth === 0) {
        values.push(value.trim());
        value = '';
        continue;
      }
    }
    value += character;
  }
  if (value.trim()) values.push(value.trim());
  return values;
}


function gdQuotedValue(value) {
  const trimmed = value.trim();
  if (!trimmed.startsWith('"') || !trimmed.endsWith('"')) return '';
  try {
    return JSON.parse(trimmed);
  } catch {
    return trimmed.slice(1, -1);
  }
}


function gdQuotedArray(value) {
  return [...value.matchAll(/"((?:\\.|[^"\\])*)"/g)].map((match) => {
    try {
      return JSON.parse(`"${match[1]}"`);
    } catch {
      return match[1];
    }
  });
}


function gdDictionaryBlock(source, field) {
  const match = source.match(new RegExp(`"${field}": \\{`));
  if (!match) return '';
  const openingIndex = match.index + match[0].lastIndexOf('{');
  const closingIndex = findClosingBrace(source, openingIndex);
  return closingIndex > openingIndex ? source.slice(openingIndex + 1, closingIndex) : '';
}


function gdString(source, field) {
  return source.match(new RegExp(`"${field}": "([^"]*)"`))?.[1] ?? '';
}


function gdNumber(source, field) {
  const value = source.match(new RegExp(`"${field}": (-?\\d+(?:\\.\\d+)?)`))?.[1];
  return value === undefined ? null : Number(value);
}


function gdColor(source) {
  const match = source.match(/"color": Color\(([-\d.]+), ([-\d.]+), ([-\d.]+)(?:, ([-\d.]+))?\)/);
  return match ? [Number(match[1]), Number(match[2]), Number(match[3]), Number(match[4] ?? 1)] : [0.45, 0.55, 0.62, 1];
}


function gdItemCounts(source) {
  return [...source.matchAll(/"([^"]+)": (\d+(?:\.\d+)?)/g)].map((match) => ({ id: match[1], count: Number(match[2]) }));
}


function gdStringArray(source, field) {
  const block = source.match(new RegExp(`"${field}": \\[([^\\]]*)\\]`))?.[1] ?? '';
  return [...block.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
}


function gdSpecial(source, field) {
  const block = gdDictionaryBlock(source, field);
  if (!block) return null;
  return {
    type: gdString(block, 'type'),
    effect: gdString(block, 'fx'),
    range: gdNumber(block, 'range'),
    radius: gdNumber(block, 'radius') ?? gdNumber(block, 'hit_radius'),
    damageMultiplier: gdNumber(block, 'damage_mult'),
    cooldown: gdNumber(block, 'cooldown'),
    summonedMob: gdString(block, 'mob'),
    count: gdNumber(block, 'count'),
  };
}


function loadBosses() {
  const source = readFileSync(bossRegistryPath, 'utf8');
  const bosses = new Map();
  for (const match of source.matchAll(/^\t"([^"]+)": \{\r?$/gm)) {
    const id = match[1];
    const openingIndex = source.indexOf('{', match.index);
    const closingIndex = findClosingBrace(source, openingIndex);
    if (closingIndex < 0) continue;
    const block = source.slice(openingIndex + 1, closingIndex);
    const boss = {
      id,
      biomeResource: gdString(block, 'biome'),
      maxHp: gdNumber(block, 'max_hp') ?? 0,
      contactDamage: gdNumber(block, 'contact_damage') ?? 0,
      speed: gdNumber(block, 'speed') ?? 0,
      pageDrop: gdString(block, 'page_drop'),
      summonerItem: gdString(block, 'summoner_item'),
      color: gdColor(block),
      loot: gdItemCounts(gdDictionaryBlock(block, 'loot')),
      special: gdSpecial(block, 'special'),
      phaseTwoSpecial: gdSpecial(block, 'phase_two_special'),
      portrait: id === 'ent' ? '/assets/textures/entities/mobs/ent.png' : '',
    };
    if (id === 'ent') {
      boss.special = { type: 'target_aoe', effect: 'root_spikes', range: 460, radius: 78, damageMultiplier: 0.9, cooldown: 5, summonedMob: '', count: null };
      boss.phaseTwoSpecial = { type: 'summon', effect: 'ent_saplings', range: 620, radius: null, damageMultiplier: null, cooldown: 18, summonedMob: 'ent_sapling', count: 3 };
    }
    bosses.set(id, boss);
  }
  return bosses;
}


const bossesById = loadBosses();


function localizedBossItem(itemId, count, language) {
  const item = itemsById.get(itemId);
  return {
    id: itemId,
    count,
    exists: Boolean(item),
    title: item ? localizedItem(item, language).title : fallbackItemTitle(itemId),
    texture: item ? item.texture : null,
    color: item ? item.color : null,
  };
}


function localizedBoss(boss, language) {
  const biomeId = bossBiomeIds[boss.biomeResource] ?? '';
  const biome = biomeDefinitions.find((entry) => entry.id === biomeId);
  return {
    ...boss,
    title: bossNames[boss.id]?.[language] ?? fallbackItemTitle(boss.id),
    description: bossDescriptions[boss.id]?.[language] ?? '',
    biomeId,
    biomeTitle: biome?.title[language] ?? boss.biomeResource,
    loot: boss.loot.map((entry) => localizedBossItem(entry.id, entry.count, language)),
    pageDrop: boss.pageDrop ? localizedBossItem(boss.pageDrop, 1, language) : null,
    summonerItem: boss.summonerItem ? localizedBossItem(boss.summonerItem, 1, language) : null,
  };
}


function loadMobs() {
  const source = readFileSync(mobRegistryPath, 'utf8');
  const mobs = new Map();
  let biomeResource = '';
  for (const line of source.split(/\r?\n/)) {
    const biomeMatch = line.match(/^\t"([^"]+Biome)": \[$/);
    if (biomeMatch) {
      biomeResource = biomeMatch[1];
      continue;
    }
    if (!biomeResource || !line.trimStart().startsWith('{"id":')) continue;
    const id = gdString(line, 'id');
    if (!id) continue;
    const portraitPath = resolve(assetsRoot, `textures/entities/mobs/${id}.png`);
    mobs.set(id, {
      id,
      nameEn: gdString(line, 'name') || fallbackItemTitle(id),
      role: gdString(line, 'role'),
      hp: gdNumber(line, 'hp') ?? 0,
      damage: gdNumber(line, 'damage') ?? 0,
      speed: gdNumber(line, 'speed') ?? 0,
      color: gdColor(line),
      lootId: gdString(line, 'loot'),
      biomeResource,
      portrait: existsSync(portraitPath) ? `/assets/textures/entities/mobs/${id}.png` : '',
    });
  }
  return mobs;
}


const mobsById = loadMobs();


function localizedMob(mob, language) {
  const biomeId = bossBiomeIds[mob.biomeResource] ?? '';
  const biome = biomeDefinitions.find((entry) => entry.id === biomeId);
  const title = language === 'ru' ? mobNamesRu[mob.id] ?? mob.nameEn : mob.nameEn;
  const roleTitle = mobRoleTitles[mob.role]?.[language] ?? mob.role;
  const description = language === 'ru'
    ? `${roleTitle} из биома «${biome?.title.ru ?? mob.biomeResource}». После победы оставляет один предмет добычи.`
    : `${roleTitle} from the ${biome?.title.en ?? mob.biomeResource} biome. Drops one item when defeated.`;
  return {
    ...mob,
    title,
    roleTitle,
    description,
    biomeId,
    biomeTitle: biome?.title[language] ?? mob.biomeResource,
    loot: localizedBossItem(mob.lootId, 1, language),
  };
}


function machineCategory(block) {
  const id = block.id.toLowerCase();
  if (id.startsWith('conveyor')) return 'conveyors';
  if (id.startsWith('chest_') || id.startsWith('energy_storage_') || id.startsWith('fluid_tank_') || id === 'me_drive') return 'storage';
  if (id.includes('solar_panel') || ['coal_generator', 'steam_turbine', 'cobblestone_generator'].includes(id)) return 'generators';
  if (block.interactive && block.interactType !== 'chest') return 'machines';
  return '';
}


function loadChestSlots() {
  const slots = new Map();
  for (const fileName of readdirSync(chestDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const content = readFileSync(resolve(chestDefinitionsRoot, fileName), 'utf8');
    const blockId = tresString(content, 'block_id');
    if (blockId) slots.set(blockId, tresNumber(content, 'slot_count') ?? 0);
  }
  return slots;
}


const chestSlots = loadChestSlots();


function machineMetrics(id, block) {
  const metrics = {};
  if (block.category === 'conveyors') {
    metrics.beltTier = block.beltTier;
    metrics.crossTime = block.crossTime;
    metrics.beltFps = block.beltFps;
    metrics.energyUse = block.beltTier;
  }
  if (chestSlots.has(id)) metrics.slotCount = chestSlots.get(id);
  const energyStorage = {
    energy_storage_t1: [100000, 128], energy_storage_t2: [500000, 512], energy_storage_t3: [2000000, 2048],
  }[id];
  if (energyStorage) [metrics.energyCapacity, metrics.maxIo] = energyStorage;
  const fluidCapacity = { fluid_tank_t1: 200, fluid_tank_t2: 350, fluid_tank_t3: 500, fluid_tank_t4: 750, fluid_tank_t5: 1000 }[id];
  if (fluidCapacity) metrics.fluidCapacity = fluidCapacity;
  const generation = {
    coal_generator: 30, solar_panel: 40, advanced_solar_panel: 120, elite_solar_panel: 360,
    ultimate_solar_panel: 1080, quantum_solar_panel: 3240, steam_turbine: 40,
  }[id];
  if (generation) metrics.energyOutput = generation;
  if (id.includes('solar_panel') && generation) metrics.energyBuffer = generation * 30;
  if (id === 'cobblestone_generator') {
    metrics.energyUse = 20;
    metrics.processTime = 3;
    metrics.outputItem = 'stone';
  }
  return metrics;
}


function loadMachines() {
  const machines = new Map();
  for (const fileName of readdirSync(blockDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const content = readFileSync(resolve(blockDefinitionsRoot, fileName), 'utf8');
    const id = tresString(content, 'block_id');
    if (!id) continue;
    const block = {
      id,
      displayName: tresString(content, 'display_name') || fallbackItemTitle(id),
      health: tresNumber(content, 'health') ?? 3,
      requiredTool: tresString(content, 'required_tool') || 'none',
      itemId: tresString(content, 'drop_item_id') || id,
      interactive: tresBoolean(content, 'is_interactive') ?? false,
      interactType: tresString(content, 'interact_type'),
      size: tresVector2(content, 'size'),
      rotatable: tresBoolean(content, 'rotatable') ?? false,
      beltTier: tresNumber(content, 'belt_tier') ?? 1,
      crossTime: tresNumber(content, 'belt_cross_time') ?? 0.8,
      beltFps: tresNumber(content, 'belt_fps') ?? 0,
      color: content.match(/^color = Color\(([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+)\)$/m)?.slice(1).map(Number) ?? [0.45, 0.55, 0.62, 1],
    };
    block.category = machineCategory(block);
    if (!block.category) continue;
    const item = itemsById.get(block.itemId) ?? itemsById.get(id);
    const texture = itemTexture(content);
    block.texture = texture.path ? texture : item?.texture ?? fallbackItemTexture(block.itemId);
    block.metrics = machineMetrics(id, block);
    machines.set(id, block);
  }
  return machines;
}


const machinesById = loadMachines();


function localizedMachine(machine, language) {
  const item = itemsById.get(machine.itemId) ?? itemsById.get(machine.id);
  const localized = item ? localizedItem(item, language) : null;
  return {
    ...machine,
    title: localized?.title || (language === 'en' ? machine.displayName : fallbackItemTitle(machine.id)),
    description: localized?.description || (language === 'ru' ? 'Устанавливаемый технический блок.' : 'A placeable technical block.'),
    categoryTitle: machineCategoryTitles[machine.category]?.[language] ?? machine.category,
    item: localized ? { id: localized.id, title: localized.title, exists: true } : { id: machine.itemId, title: fallbackItemTitle(machine.itemId), exists: false },
  };
}


function machineDetails(machine, language) {
  const localized = localizedMachine(machine, language);
  const recipeMatches = recipes.filter((recipe) => recipe.resultId === machine.itemId || recipe.resultId === machine.id);
  const fluidRecipes = new Map();
  for (const fluid of fluidsById.values()) {
    for (const recipe of [...fluid.sources, ...fluid.uses]) {
      if (recipe.machineId === machine.id) fluidRecipes.set(recipe.id, recipe);
    }
  }
  return {
    machine: localized,
    recipes: recipeMatches.map((recipe) => localizedRecipe(recipe, language)),
    fluidProcesses: [...fluidRecipes.values()].map((recipe) => localizedFluidRecipe(recipe, language)),
  };
}


function loadTechnologyStages() {
  const source = readFileSync(technologyTreePath, 'utf8');
  const stages = [];
  for (const match of source.matchAll(/\{"id":/g)) {
    const openingIndex = match.index;
    const closingIndex = findClosingBrace(source, openingIndex);
    if (closingIndex < 0) continue;
    const block = source.slice(openingIndex + 1, closingIndex);
    const id = gdString(block, 'id');
    if (!id) continue;
    stages.push({
      id,
      titleEn: gdString(block, 'title'),
      descriptionEn: gdString(block, 'description'),
      biomeResource: gdString(block, 'biome'),
      bossId: gdString(block, 'boss'),
      research: gdItemCounts(gdDictionaryBlock(block, 'research')),
      machines: gdStringArray(block, 'machines'),
      components: gdStringArray(block, 'components'),
    });
  }
  return stages;
}


function loadRecommendedBalance() {
  if (!existsSync(balanceReportPath)) return new Map();
  const source = readFileSync(balanceReportPath, 'utf8');
  const section = source.match(/## Recommended progression package([\s\S]*?)## Stage details/)?.[1] ?? '';
  const balance = new Map();
  for (const line of section.split(/\r?\n/)) {
    const match = line.match(/^\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|\s*([\d.]+)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$/);
    if (!match || match[1] === 'Stage') continue;
    balance.set(match[1], {
      targetCount: Number(match[2]),
      rawUnits: Number(match[3]),
      machineTime: match[4],
      estimatedTime: match[5],
    });
  }
  return balance;
}


const technologyStages = loadTechnologyStages();
const recommendedBalance = loadRecommendedBalance();


function parseQuestObjectives(value) {
  const objectives = [];
  for (const match of value.matchAll(/_obj\s*\(/g)) {
    const openingIndex = value.indexOf('(', match.index);
    const closingIndex = findClosingDelimiter(value, openingIndex, '(', ')');
    if (closingIndex < 0) continue;
    const args = splitTopLevelArguments(value.slice(openingIndex + 1, closingIndex));
    if (args.length < 4) continue;
    objectives.push({
      description: gdQuotedValue(args[0]),
      eventType: gdQuotedValue(args[1]),
      eventDetail: gdQuotedValue(args[2]),
      count: Number(args[3]) || 1,
    });
  }
  return objectives;
}


function loadQuests() {
  const source = readFileSync(questDatabasePath, 'utf8');
  const quests = [];
  for (const match of source.matchAll(/_(quest|tutorial)\s*\(/g)) {
    const openingIndex = source.indexOf('(', match.index);
    const closingIndex = findClosingDelimiter(source, openingIndex, '(', ')');
    if (closingIndex < 0) continue;
    const args = splitTopLevelArguments(source.slice(openingIndex + 1, closingIndex));
    const id = gdQuotedValue(args[0] ?? '');
    if (!id || args.length < 7) continue;
    quests.push({
      id,
      age: Number(args[1]) || 1,
      tab: gdQuotedValue(args[2]),
      title: gdQuotedValue(args[3]),
      description: gdQuotedValue(args[4]),
      objectives: parseQuestObjectives(args[5]),
      unlocks: gdQuotedArray(args[6]),
      prerequisites: args[7] ? gdQuotedArray(args[7]) : [],
      tutorial: match[1] === 'tutorial',
      sourceIndex: match.index,
    });
  }
  return quests;
}


function parseNpcReward(value) {
  const match = value.match(/^(.+?):(\d+(?:\.\d+)?)$/);
  return match ? { id: match[1], count: Number(match[2]) } : { id: value, count: 1 };
}


function loadNpcs() {
  const source = readFileSync(npcQuestDatabasePath, 'utf8');
  const metadataSource = source.slice(0, source.indexOf('static func get_all_quests'));
  const npcs = [];
  for (const match of metadataSource.matchAll(/\{\s*"id":\s*"([^"]+)"/g)) {
    const openingIndex = match.index;
    const closingIndex = findClosingBrace(metadataSource, openingIndex);
    if (closingIndex < 0) continue;
    const block = metadataSource.slice(openingIndex + 1, closingIndex);
    npcs.push({
      id: gdString(block, 'id'),
      name: gdString(block, 'name'),
      role: gdString(block, 'role'),
      biomeResource: gdString(block, 'biome'),
      greeting: gdString(block, 'greeting'),
      color: gdColor(block),
      quests: [],
    });
  }
  for (const match of source.matchAll(/_add\s*\(/g)) {
    const openingIndex = source.indexOf('(', match.index);
    const closingIndex = findClosingDelimiter(source, openingIndex, '(', ')');
    if (closingIndex < 0) continue;
    const args = splitTopLevelArguments(source.slice(openingIndex + 1, closingIndex));
    const npcId = gdQuotedValue(args[1] ?? '');
    const npc = npcs.find((entry) => entry.id === npcId);
    if (!npc || !args[2]) continue;
    for (const questMatch of args[2].matchAll(/_q\s*\(/g)) {
      const questOpeningIndex = args[2].indexOf('(', questMatch.index);
      const questClosingIndex = findClosingDelimiter(args[2], questOpeningIndex, '(', ')');
      if (questClosingIndex < 0) continue;
      const questArgs = splitTopLevelArguments(args[2].slice(questOpeningIndex + 1, questClosingIndex));
      if (questArgs.length < 6) continue;
      npc.quests.push({
        id: gdQuotedValue(questArgs[0]),
        title: gdQuotedValue(questArgs[1]),
        description: gdQuotedValue(questArgs[2]),
        objectives: parseQuestObjectives(questArgs[3]),
        rewards: gdQuotedArray(questArgs[4]).map(parseNpcReward),
        unlocks: gdQuotedArray(questArgs[5]),
      });
    }
  }
  return npcs.sort((left, right) => {
    const leftIndex = biomeDefinitions.findIndex((biome) => biome.resource === left.biomeResource);
    const rightIndex = biomeDefinitions.findIndex((biome) => biome.resource === right.biomeResource);
    return leftIndex - rightIndex;
  });
}


const questTranslations = loadQuestTranslations();
const menuTranslations = loadMenuTranslations();
const quests = loadQuests();
const npcs = loadNpcs();


function gdConstBlock(source, name, openingCharacter, closingCharacter) {
  const declarationIndex = source.indexOf(`const ${name}`);
  if (declarationIndex < 0) return '';
  const equalsIndex = source.indexOf('=', declarationIndex);
  const openingIndex = source.indexOf(openingCharacter, equalsIndex > declarationIndex ? equalsIndex : declarationIndex);
  if (openingIndex < 0) return '';
  const closingIndex = findClosingDelimiter(source, openingIndex, openingCharacter, closingCharacter);
  return closingIndex > openingIndex ? source.slice(openingIndex + 1, closingIndex) : '';
}


function loadAchievements() {
  const source = readFileSync(achievementDatabasePath, 'utf8');
  return splitTopLevelArguments(gdConstBlock(source, 'LIST', '[', ']'))
    .filter((block) => block.startsWith('{'))
    .map((block) => {
      const questCount = gdNumber(block, 'quest_count');
      const age = gdNumber(block, 'age');
      const bossId = gdString(block, 'boss');
      const bossCount = gdNumber(block, 'boss_count');
      const machineCount = gdNumber(block, 'machine_count');
      const stableGrid = /"stable_grid":\s*true/.test(block);
      let category = 'factory';
      let requirementType = 'stable_grid';
      let requirementValue = 1;
      if (questCount) { category = 'quests'; requirementType = 'quest_count'; requirementValue = questCount; }
      else if (age) { category = 'ages'; requirementType = 'age'; requirementValue = age; }
      else if (bossId) { category = 'bosses'; requirementType = 'boss'; requirementValue = bossId; }
      else if (bossCount) { category = 'bosses'; requirementType = 'boss_count'; requirementValue = bossCount; }
      else if (machineCount) { requirementType = 'machine_count'; requirementValue = machineCount; }
      else if (stableGrid) { requirementType = 'stable_grid'; }
      return {
        id: gdString(block, 'id'),
        titleEn: gdString(block, 'title'),
        descriptionEn: gdString(block, 'desc'),
        iconId: gdString(block, 'icon'),
        category,
        requirementType,
        requirementValue,
      };
    })
    .filter((achievement) => achievement.id);
}


const achievements = loadAchievements();


function numericConstants(source) {
  const values = {};
  for (const match of source.matchAll(/^const ([A-Z][A-Z0-9_]*) := (\d+(?:\.\d+)?)/gm)) values[match[1]] = Number(match[2]);
  return values;
}


const mechanicDefinitions = [
  {
    id: 'health-respawn', iconId: 'apple', color: [0.86, 0.22, 0.18, 1],
    title: { ru: 'Здоровье и возрождение', en: 'Health and respawning' },
    subtitle: { ru: 'Урон, лечение, смерть и возвращение на базу', en: 'Damage, healing, death, and returning to base' },
    description: { ru: 'Как рассчитывается здоровье персонажа, чем отличается голодание от боевого урона и что происходит после смерти.', en: 'How player health is calculated, how starvation differs from combat damage, and what happens after death.' },
  },
  {
    id: 'hunger-food', iconId: 'veggie_stew', color: [0.90, 0.55, 0.12, 1],
    title: { ru: 'Голод и еда', en: 'Hunger and food' },
    subtitle: { ru: 'Расход сытости, штраф скорости и ценность продуктов', en: 'Hunger drain, movement penalty, and food values' },
    description: { ru: 'Полная таблица съедобных предметов и точные пороги системы голода.', en: 'A complete food table and the exact thresholds used by the hunger system.' },
  },
  {
    id: 'environmental-hazards', iconId: 'sand_amulet', color: [0.24, 0.66, 0.46, 1],
    title: { ru: 'Опасности биомов', en: 'Environmental hazards' },
    subtitle: { ru: 'Воздействие, защитные предметы и выброс в безопасную зону', en: 'Exposure, protection items, and safe-zone ejection' },
    description: { ru: 'Все восемь опасных биомов, скорость накопления воздействия и необходимая защита.', en: 'All eight hazardous biomes, their exposure rates, and the protection each one requires.' },
  },
  {
    id: 'equipment-sets', iconId: 'cryo_mantle', color: [0.48, 0.35, 0.82, 1],
    title: { ru: 'Экипировка и комплекты', en: 'Equipment and sets' },
    subtitle: { ru: 'Восемь слотов, индивидуальные бонусы и эффекты комплектов', en: 'Eight slots, individual bonuses, and set effects' },
    description: { ru: 'Какие предметы помещаются в каждый слот и как складываются бонусы комплектов первопроходца и вознесения.', en: 'Which items fit each slot and how the Frontier and Ascendant set bonuses stack.' },
  },
  {
    id: 'combat-movement', iconId: 'steel_sword', color: [0.18, 0.48, 0.78, 1],
    title: { ru: 'Бой и передвижение', en: 'Combat and movement' },
    subtitle: { ru: 'Оружие, формулы урона, бег и рывок', en: 'Weapons, damage formulas, running, and dashing' },
    description: { ru: 'Дальность и множители четырёх классов оружия, а также параметры ходьбы, бега и неуязвимого рывка.', en: 'Reach and damage multipliers for four weapon classes, plus walking, running, and the invulnerable dash.' },
  },
];


function loadEquipmentMechanics() {
  const source = readFileSync(equipmentBonusPath, 'utf8');
  const bonusKeys = ['move_speed', 'attack_damage', 'damage_reduction', 'mining_power', 'max_health', 'dash_cooldown', 'loot_bonus'];
  const bonuses = [];
  for (const entry of splitTopLevelArguments(gdConstBlock(source, 'ITEM_BONUSES', '{', '}'))) {
    const id = entry.match(/^"([^"]+)"\s*:/)?.[1];
    if (!id) continue;
    const values = {};
    for (const key of bonusKeys) {
      const value = gdNumber(entry, key);
      if (value !== null) values[key] = value;
    }
    bonuses.push({ id, values });
  }
  const sets = [];
  for (const entry of splitTopLevelArguments(gdConstBlock(source, 'SETS', '{', '}'))) {
    const id = entry.match(/^"([^"]+)"\s*:/)?.[1];
    if (!id) continue;
    const thresholds = [];
    const thresholdSource = gdDictionaryBlock(entry, 'thresholds');
    for (const match of thresholdSource.matchAll(/(\d+)\s*:\s*\{/g)) {
      const openingIndex = match.index + match[0].lastIndexOf('{');
      const closingIndex = findClosingBrace(thresholdSource, openingIndex);
      const block = closingIndex > openingIndex ? thresholdSource.slice(openingIndex + 1, closingIndex) : '';
      const values = {};
      for (const key of bonusKeys) {
        const value = gdNumber(block, key);
        if (value !== null) values[key] = value;
      }
      thresholds.push({ count: Number(match[1]), values });
    }
    sets.push({ id, titleEn: gdString(entry, 'title'), items: gdStringArray(entry, 'items'), thresholds });
  }
  return { bonuses, sets };
}


const playerConstants = numericConstants(readFileSync(playerScriptPath, 'utf8'));
const equipmentMechanics = loadEquipmentMechanics();

const gatheringDefinitions = [
  { id: 'manual-mining', iconId: 'steel_pickaxe', color: [0.38, 0.56, 0.68, 1], title: { ru: 'Ручная добыча', en: 'Manual mining' }, subtitle: { ru: 'Сила инструментов, удары и восстановление прогресса', en: 'Tool power, swings, and mining progress recovery' }, description: { ru: 'Формула урона по залежам, требования уровней и сравнение всех кирок.', en: 'Deposit damage formulas, level requirements, and a comparison of every pickaxe.' } },
  { id: 'ore-deposits', iconId: 'iron_ore', color: [0.62, 0.46, 0.30, 1], title: { ru: 'Рудные месторождения', en: 'Ore deposits' }, subtitle: { ru: 'Тринадцать руд, уровни кирок и скважины для буров', en: 'Thirteen ores, pickaxe levels, and drill boreholes' }, description: { ru: 'Полный каталог руд Верхнего мира с уровнями добычи, прочностью жил и местами появления.', en: 'The complete Overworld ore catalog with mining levels, vein durability, and spawn locations.' } },
  { id: 'automated-drilling', iconId: 'advanced_drill', color: [0.22, 0.60, 0.72, 1], title: { ru: 'Автоматические буры', en: 'Automated drilling' }, subtitle: { ru: 'Пять уровней буров, энергия, буферы и направление выдачи', en: 'Five drill tiers, power, buffers, and output direction' }, description: { ru: 'Как поставить бур на ядро жилы и подобрать уровень машины для нужной руды.', en: 'How to place a drill on a vein core and choose a machine tier for the target ore.' } },
  { id: 'farming', iconId: 'hoe', color: [0.34, 0.66, 0.24, 1], title: { ru: 'Фермерство', en: 'Farming' }, subtitle: { ru: 'Подготовка грядок, четыре культуры, рост и урожай', en: 'Preparing plots, four crops, growth, and yields' }, description: { ru: 'Пошаговый цикл фермерства и точные сроки созревания каждой культуры.', en: 'The complete farming loop and exact maturation time for every crop.' } },
  { id: 'foraging', iconId: 'berry', color: [0.56, 0.42, 0.72, 1], title: { ru: 'Собирательство', en: 'Foraging' }, subtitle: { ru: 'Дикорастущие ресурсы, шанс появления и урожайность', en: 'Wild resources, spawn chances, and yields' }, description: { ru: 'Одиннадцать видов растений и природных объектов с их биомами и условиями появления.', en: 'Eleven wild plants and natural objects with their biomes and spawn conditions.' } },
  { id: 'fluid-deposits', iconId: 'oil_pump', color: [0.28, 0.30, 0.34, 1], title: { ru: 'Жидкостные залежи', en: 'Fluid deposits' }, subtitle: { ru: 'Нефтяные и лавовые поля, объём и откачка', en: 'Oil and lava fields, capacity, and pumping' }, description: { ru: 'Где искать нефть и лаву, как устроены поля и чем их откачивать.', en: 'Where to find oil and lava, how their fields are generated, and how to pump them.' } },
];

const interfaceDefinitions = [
  { id: 'controls', iconId: 'codex', color: [0.26, 0.58, 0.78, 1], title: { ru: 'Управление', en: 'Controls' }, subtitle: { ru: 'Клавиатура, мышь и контекстные действия', en: 'Keyboard, mouse, and contextual actions' }, description: { ru: 'Полная памятка по стандартным клавишам, передвижению и действиям в мире.', en: 'A complete reference for default keys, movement, and actions in the world.' } },
  { id: 'inventory-hotbar', iconId: 'CHEST_T1', color: [0.70, 0.48, 0.22, 1], title: { ru: 'Инвентарь и хотбар', en: 'Inventory and hotbar' }, subtitle: { ru: 'Тридцать шесть слотов, четыре строки и быстрые переносы', en: 'Thirty-six slots, four rows, and quick transfers' }, description: { ru: 'Как переключать строки хотбара, делить стаки, распределять предметы и быстро переносить их.', en: 'How to cycle hotbar rows, split stacks, distribute items, and move them quickly.' } },
  { id: 'building-tools', iconId: 'workbench', color: [0.30, 0.68, 0.62, 1], title: { ru: 'Строительство', en: 'Building' }, subtitle: { ru: 'Установка, направление, демонтаж и протяжка', en: 'Placement, facing, dismantling, and drag building' }, description: { ru: 'Практическое руководство по строительному радиусу, установке блоков и их направлению.', en: 'A practical guide to build radius, block placement, and facing.' } },
  { id: 'books-map', iconId: 'codex', color: [0.54, 0.38, 0.76, 1], title: { ru: 'Книги и карта', en: 'Books and map' }, subtitle: { ru: 'Рецепты, квесты, технологии, Кодекс и карта', en: 'Recipes, quests, technology, Codex, and map' }, description: { ru: 'Где находятся основные справочные экраны игры и какими клавишами их открывать.', en: 'Where to find the main reference screens and which keys open them.' } },
  { id: 'saves-multiplayer', iconId: 'computer', color: [0.34, 0.52, 0.82, 1], title: { ru: 'Сохранения и совместная игра', en: 'Saves and multiplayer' }, subtitle: { ru: 'Автосохранение, хост, подключение, чат и метки', en: 'Autosave, hosting, joining, chat, and pings' }, description: { ru: 'Как сохраняется локальный мир и как устроена совместная сессия до восьми игроков.', en: 'How a local world is saved and how an online session for up to eight players works.' } },
];

const explorationDefinitions = [
  { id: 'time-weather', iconId: 'solar_panel', color: [0.96, 0.68, 0.22, 1], title: { ru: 'Время и погода', en: 'Time and weather' }, subtitle: { ru: 'Суточный цикл, освещение, дождь и грозы', en: 'Day cycle, lighting, rain, and storms' }, description: { ru: 'Как идут игровые сутки, когда наступают рассвет и ночь и насколько погода снижает солнечную генерацию.', en: 'How the game day advances, when dawn and night begin, and how weather reduces solar generation.' } },
  { id: 'map-exploration', iconId: 'codex', color: [0.28, 0.62, 0.76, 1], title: { ru: 'Карта и разведка', en: 'Map and exploration' }, subtitle: { ru: 'Открытие биомов, ресурсы, боссы и командные метки', en: 'Biome discovery, resources, bosses, and team pings' }, description: { ru: 'Что появляется на карте по мере загрузки мира, как открываются биомы и какие метки сохраняются.', en: 'What appears as the world loads, how biomes are discovered, and which markers persist.' } },
  { id: 'obelisks-fast-travel', iconId: 'ent_totem', color: [0.58, 0.42, 0.82, 1], title: { ru: 'Обелиски и быстрое перемещение', en: 'Obelisks and fast travel' }, subtitle: { ru: 'Двадцать пять узлов, открытие и телепортация', en: 'Twenty-five nodes, discovery, and teleportation' }, description: { ru: 'Расположение сети обелисков, условия открытия и использование узлов на полноэкранной карте.', en: 'The obelisk network layout, discovery conditions, and using nodes from the fullscreen map.' } },
  { id: 'world-generation', iconId: 'workbench', color: [0.34, 0.68, 0.42, 1], title: { ru: 'Генерация мира', en: 'World generation' }, subtitle: { ru: 'Сид, кольца биомов, чанки и заброшенные структуры', en: 'Seed, biome rings, chunks, and abandoned structures' }, description: { ru: 'Как сид формирует конечный радиальный Верхний мир, его направления, берег и руины с добычей.', en: 'How the seed creates the finite radial Overworld, its directions, coastline, and loot ruins.' } },
  { id: 'dropped-items', iconId: 'copper_ore', color: [0.82, 0.48, 0.20, 1], title: { ru: 'Предметы на земле', en: 'Dropped items' }, subtitle: { ru: 'Задержка, магнитный подбор, остатки и сетевая защита', en: 'Delay, magnetic pickup, leftovers, and network arbitration' }, description: { ru: 'Как выброшенные предметы притягиваются к персонажу, попадают в сумку и ведут себя при заполненном инвентаре.', en: 'How dropped items are pulled toward the player, enter storage, and behave when the inventory is full.' } },
];

const optimizationDefinitions = [
  { id: 'machine-modules', iconId: 'machine_module_speed', color: [0.84, 0.48, 0.22, 1], title: { ru: 'Модули машин', en: 'Machine modules' }, subtitle: { ru: 'Скорость, эффективность, ёмкость и продуктивность', en: 'Speed, efficiency, capacity, and productivity' }, description: { ru: 'Все четыре типа модулей, их формулы, максимальные уровни и сочетания эффектов.', en: 'All four module types, their formulas, maximum levels, and combined effects.' } },
  { id: 'output-control', iconId: 'computer', color: [0.36, 0.66, 0.82, 1], title: { ru: 'Контроль выходного буфера', en: 'Output-buffer control' }, subtitle: { ru: 'Автоматическая остановка и гистерезис', en: 'Automatic stopping and hysteresis' }, description: { ru: 'Как машина останавливается при заполнении выхода и возобновляет работу без частых переключений.', en: 'How a machine stops as output fills and resumes without rapid switching.' } },
  { id: 'stock-control', iconId: 'CHEST_T3', color: [0.64, 0.48, 0.26, 1], title: { ru: 'Контроль запасов', en: 'Stock control' }, subtitle: { ru: 'Целевые количества, приоритеты и несколько производителей', en: 'Stock targets, priorities, and multiple producers' }, description: { ru: 'Как считать предметы в выходной логистической сети и координировать до четырёх машин.', en: 'How to count items in an output logistics network and coordinate up to four machines.' } },
  { id: 'assembler-coordination', iconId: 'steam_assembler', color: [0.26, 0.72, 0.72, 1], title: { ru: 'Координация сборщиков', en: 'Assembler coordination' }, subtitle: { ru: 'Общий план склада и запрос недостающих ингредиентов', en: 'Shared warehouse planning and missing-ingredient requests' }, description: { ru: 'Специальные режимы паровых сборщиков для распределения рецептов и адресной подачи компонентов.', en: 'Steam Assembler modes for distributing recipes and requesting only missing components.' } },
  { id: 'factory-diagnostics', iconId: 'computer', color: [0.58, 0.40, 0.78, 1], title: { ru: 'Диагностика фабрики', en: 'Factory diagnostics' }, subtitle: { ru: 'Телеметрия, спящие машины, заторы и удалённая симуляция', en: 'Telemetry, sleeping machines, jams, and remote simulation' }, description: { ru: 'Как читать сводку фабрики и почему простаивающие или далёкие машины тикают реже без изменения производительности.', en: 'How to read the factory summary and why idle or distant machines tick less often without changing production rates.' } },
  { id: 'production-lines', iconId: 'steam_crusher', color: [0.72, 0.58, 0.36, 1], title: { ru: 'Анализ производственных линий', en: 'Production-line analysis' }, subtitle: { ru: 'Железо, исследования, сталь и поиск узких мест', en: 'Iron, research, steel, and bottleneck detection' }, description: { ru: 'Встроенные анализаторы трёх цепочек, требования к связности и расчётная пропускная способность.', en: 'Built-in analyzers for three chains, their connectivity requirements, and rated throughput.' } },
];

const multiplayerDefinitions = [
  { id: 'hosting-joining', iconId: 'computer', color: [0.32, 0.58, 0.84, 1], title: { ru: 'Создание и поиск сессии', en: 'Hosting and joining' }, subtitle: { ru: 'LAN, прямой адрес, пароль и переподключение', en: 'LAN, direct address, passwords, and reconnecting' }, description: { ru: 'Как открыть мир для друзей, найти сервер в локальной сети и подключиться через интернет.', en: 'How to open a world to friends, find a LAN server, and connect over the internet.' } },
  { id: 'host-world-sync', iconId: 'codex', color: [0.48, 0.42, 0.78, 1], title: { ru: 'Мир хоста и синхронизация', en: 'Host world and synchronization' }, subtitle: { ru: 'Снимок мира, общий прогресс и защита локальных сейвов', en: 'World snapshot, shared progression, and local-save protection' }, description: { ru: 'Какие данные задаёт хост, что получает новый участник и почему удалённый мир не записывается поверх локального.', en: 'Which data the host controls, what a new peer receives, and why a remote world never overwrites a local save.' } },
  { id: 'building-mining-sync', iconId: 'steel_pickaxe', color: [0.72, 0.50, 0.24, 1], title: { ru: 'Строительство и добыча', en: 'Building and mining' }, subtitle: { ru: 'Игроки, блоки, общая прочность залежей и финальный удар', en: 'Players, blocks, shared deposit health, and the final hit' }, description: { ru: 'Как передаются движения участников, постройки, демонтаж и совместная разработка одной залежи.', en: 'How player movement, placement, dismantling, and shared mining of one deposit are transmitted.' } },
  { id: 'drops-machines-sync', iconId: 'copper_ore', color: [0.30, 0.70, 0.62, 1], title: { ru: 'Предметы и машины в сети', en: 'Networked items and machines' }, subtitle: { ru: 'Арбитраж добычи, состояние меню и контроль хоста', en: 'Drop arbitration, menu state, and host validation' }, description: { ru: 'Почему один предмет нельзя подобрать дважды и как хост выравнивает состояние машин у всех игроков.', en: 'Why one item cannot be collected twice and how the host reconciles machine state for every player.' } },
  { id: 'chat-pings', iconId: 'codex', color: [0.86, 0.66, 0.24, 1], title: { ru: 'Чат, команды и метки', en: 'Chat, commands, and pings' }, subtitle: { ru: 'Сообщения, автодополнение, командные отметки и RTT', en: 'Messages, completion, team markers, and RTT' }, description: { ru: 'Клавиши чата, локальные команды, метки «смотри сюда» и цветовой индикатор задержки.', en: 'Chat controls, local commands, “look here” markers, and the color-coded latency indicator.' } },
];

const energyDefinitions = [
  { id: 'generation', iconId: 'coal_generator', color: [0.92, 0.56, 0.18, 1], title: { ru: 'Генераторы и топливо', en: 'Generators and fuel' }, subtitle: { ru: 'Уголь, кокс, пар и производство по спросу', en: 'Coal, coke, steam, and demand-driven generation' }, description: { ru: 'Как угольный генератор и паровая турбина превращают топливо в EU и почему не расходуют его без спроса.', en: 'How the Coal Generator and Steam Turbine turn fuel into EU and why they consume nothing without demand.' } },
  { id: 'grid-distribution', iconId: 'copper_wire', color: [0.96, 0.76, 0.20, 1], title: { ru: 'Энергосеть и распределение', en: 'Power grid and distribution' }, subtitle: { ru: 'Провода, конвейеры, буферы и порядок доставки', en: 'Wires, conveyors, buffers, and delivery order' }, description: { ru: 'Как строятся независимые сети, какие блоки проводят ток и как EU делятся между потребителями.', en: 'How independent grids are formed, which blocks conduct power, and how EU is shared among consumers.' } },
  { id: 'storage', iconId: 'energy_storage_t1', color: [0.28, 0.66, 0.88, 1], title: { ru: 'Накопители энергии', en: 'Energy storage' }, subtitle: { ru: 'Три уровня, ёмкость, ввод и аварийный резерв', en: 'Three tiers, capacity, I/O, and backup power' }, description: { ru: 'Характеристики накопителей T1–T3, ограничения скорости и расчёт времени автономной работы.', en: 'T1–T3 storage specifications, transfer limits, and backup-runtime calculations.' } },
  { id: 'solar-weather', iconId: 'solar_panel', color: [0.98, 0.68, 0.14, 1], title: { ru: 'Солнечная энергия и погода', en: 'Solar power and weather' }, subtitle: { ru: 'Пять панелей, внутренний буфер, дождь и гроза', en: 'Five panels, internal buffer, rain, and storms' }, description: { ru: 'Полная линейка солнечных панелей и влияние погоды на их реальную выработку.', en: 'The complete solar-panel line and how weather changes actual output.' } },
  { id: 'diagnostics', iconId: 'computer', color: [0.34, 0.78, 0.56, 1], title: { ru: 'Проверка энергосети', en: 'Power-grid checks' }, subtitle: { ru: 'Подключение, генерация и поиск дефицита без оверлея', en: 'Connections, generation, and finding deficits without an overlay' }, description: { ru: 'Как находить причины остановки машин по соединениям, генераторам и состоянию самих механизмов.', en: 'How to find why machines stopped by checking connections, generators, and machine state.' } },
];

const logisticsDefinitions = [
  { id: 'conveyor-tiers', iconId: 'conveyor_t2', color: [0.92, 0.48, 0.16, 1], title: { ru: 'Уровни конвейеров', en: 'Conveyor tiers' }, subtitle: { ru: 'Скорость T1–T5, энергопотребление и буфер ленты', en: 'T1–T5 speed, power draw, and belt buffering' }, description: { ru: 'Сравнение пяти лент, расчёт пропускной способности и правила передачи предметов.', en: 'A comparison of five belts, throughput calculations, and item handoff rules.' } },
  { id: 'inserters', iconId: 'mechanical_inserter', color: [0.74, 0.60, 0.28, 1], title: { ru: 'Механические манипуляторы', en: 'Mechanical inserters' }, subtitle: { ru: 'Источник, приёмник, фильтры и состояния ожидания', en: 'Source, destination, filters, and waiting states' }, description: { ru: 'Как манипулятор забирает предметы из сундуков, машин и лент и передаёт их дальше.', en: 'How an inserter pulls items from chests, machines, and belts and delivers them downstream.' } },
  { id: 'filters-splitters', iconId: 'conveyor_splitter', color: [0.42, 0.68, 0.88, 1], title: { ru: 'Фильтры и разветвители', en: 'Filters and splitters' }, subtitle: { ru: 'Белые и чёрные списки, приоритеты и разделение 1→2', en: 'Allowlists, blocklists, priorities, and 1→2 routing' }, description: { ru: 'Настройка фильтров лент и манипуляторов, боковых выходов и порядка распределения.', en: 'Configuring belt and inserter filters, side outputs, and routing order.' } },
  { id: 'ingredient-demand', iconId: 'CHEST_T2', color: [0.50, 0.38, 0.82, 1], title: { ru: 'Запросы ингредиентов', en: 'Ingredient demand' }, subtitle: { ru: 'Запрашивающие склады, поставщики и резервирование пути', en: 'Requester warehouses, providers, and in-transit reservations' }, description: { ru: 'Как склады формируют дефицит, поставщики сохраняют минимальный запас, а предмет получает адрес назначения.', en: 'How warehouses create demand, providers preserve minimum stock, and items receive destinations.' } },
  { id: 'logistics-diagnostics', iconId: 'computer', color: [0.34, 0.76, 0.58, 1], title: { ru: 'Проверка логистики', en: 'Logistics checks' }, subtitle: { ru: 'Заторы, дефициты и приоритеты без отдельного окна', en: 'Jams, shortages, and priorities without a separate window' }, description: { ru: 'Как находить заблокированные маршруты по лентам, манипуляторам и состоянию складов.', en: 'How to locate blocked routes by inspecting belts, inserters, and storage state.' } },
];

const steamDefinitions = [
  { id: 'water-supply', iconId: 'mechanical_water_pump', color: [0.22, 0.66, 0.88, 1], title: { ru: 'Водоснабжение', en: 'Water supply' }, subtitle: { ru: 'Три насоса, водная клетка и выходные буферы', en: 'Three pumps, water tiles, and output buffers' }, description: { ru: 'Как выбрать и установить насос, сопоставить его подачу с расходом котлов и не замкнуть паровой насос на истощающуюся линию.', en: 'How to choose and place a pump, match its supply to boiler demand, and avoid trapping a steam pump in a shrinking feedback loop.' } },
  { id: 'boilers-fuel', iconId: 'steam_boiler', color: [0.72, 0.42, 0.20, 1], title: { ru: 'Котлы и топливо', en: 'Boilers and fuel' }, subtitle: { ru: 'Вода 1:1, твёрдое топливо, креозот и три бака', en: '1:1 water, solid fuel, creosote, and three tanks' }, description: { ru: 'Точные параметры парового котла, приоритет топлива и расчёт устойчивой паровой мощности.', en: 'Exact Steam Boiler parameters, fuel priority, and calculations for sustainable steam capacity.' } },
  { id: 'steam-network', iconId: 'fluid_pipe_t2', color: [0.30, 0.70, 0.78, 1], title: { ru: 'Паровая сеть', en: 'Steam network' }, subtitle: { ru: 'Трубы T1/T2, слабое звено, клапаны и буферы', en: 'T1/T2 pipes, bottlenecks, valves, and buffers' }, description: { ru: 'Как связана жидкостная сеть, почему одна труба T1 ограничивает всю линию и как клапанами отделять потоки.', en: 'How a fluid network connects, why one T1 pipe caps the entire line, and how valves separate and prioritize flows.' } },
  { id: 'steam-machines', iconId: 'steam_crusher', color: [0.76, 0.60, 0.28, 1], title: { ru: 'Паровые машины', en: 'Steam machines' }, subtitle: { ru: 'Дробилка, печь, пресс и сборщик', en: 'Crusher, furnace, press, and assembler' }, description: { ru: 'Сравнение циклов и расхода пара четырёх машин, их входного бака и условий запуска рецепта.', en: 'A comparison of cycle times and steam draw for four machines, their input tank, and recipe start conditions.' } },
  { id: 'steam-diagnostics', iconId: 'computer', color: [0.34, 0.78, 0.56, 1], title: { ru: 'Проверка паровой сети', en: 'Steam-network checks' }, subtitle: { ru: 'Мощность, расход и поиск нехватки пара без оверлея', en: 'Capacity, draw, and finding shortages without an overlay' }, description: { ru: 'Как отличать нехватку котлов от лимита трубы по параметрам машин и соединениям.', en: 'How to distinguish insufficient boiler capacity from a pipe bottleneck using machine values and connections.' } },
];

const oreProcessingDefinitions = [
  { id: 'chain-overview', iconId: 'iron_dust', color: [0.66, 0.54, 0.40, 1], title: { ru: 'Переработка руды', en: 'Ore processing' }, subtitle: { ru: 'Руда → обычная металлическая пыль', en: 'Ore → standard metal dust' }, description: { ru: 'Как выбрать машину для прямой переработки руды в пыль и получения побочных металлов.', en: 'How to choose a machine that converts ore directly into dust and recovers byproduct metals.' } },
  { id: 'crushing', iconId: 'steam_crusher', color: [0.72, 0.48, 0.24, 1], title: { ru: 'Измельчение руды', en: 'Ore grinding' }, subtitle: { ru: 'Примитивная, паровая и электрическая дробилки', en: 'Primitive, steam, and electric crushers' }, description: { ru: 'Сравнение трёх дробилок: цикл, энергия и прямой выход металлической пыли.', en: 'A comparison of three crushers: cycle time, power source, and direct metal-dust output.' } },
  { id: 'washing-separation', iconId: 'ore_washer', color: [0.24, 0.64, 0.86, 1], title: { ru: 'Промывка и сепарация', en: 'Washing and separation' }, subtitle: { ru: 'Прямая переработка руды и побочные пыли', en: 'Direct ore processing and byproduct dusts' }, description: { ru: 'Параметры промывочной машины и магнитного сепаратора, поток воды и правила двух выходных слотов.', en: 'Ore Washer and Magnetic Separator parameters, water flow, and rules for two output slots.' } },
  { id: 'centrifuge-yields', iconId: 'centrifuge', color: [0.48, 0.38, 0.78, 1], title: { ru: 'Центрифуга и выход', en: 'Centrifuge yields' }, subtitle: { ru: 'Двойная основная пыль, побочный металл и баланс', en: 'Double primary dust, byproduct metal, and balance' }, description: { ru: 'Как центрифуга напрямую разделяет руду на две основные пыли и одну полноценную побочную.', en: 'How the centrifuge directly separates ore into two primary dusts and one full byproduct dust.' } },
  { id: 'smelting-melting', iconId: 'ore_melter', color: [0.92, 0.42, 0.16, 1], title: { ru: 'Плавка и расплавы', en: 'Smelting and molten metals' }, subtitle: { ru: 'Печи, индукционная плавильня, 90 л и выходной бак', en: 'Furnaces, induction melting, 90 L, and the output tank' }, description: { ru: 'Выбор между обычной, паровой и электрической печью и перевод руды или пыли в расплав.', en: 'Choosing between regular, steam, and electric furnaces, then converting ore or dust into molten metal.' } },
];


function numericAssignment(source, name, fallback) {
  const value = source.match(new RegExp(`(?:const\\s+${name}\\s*(?::=|=)|${name}[^=\\n]*=)\\s*(-?\\d+(?:\\.\\d+)?)`))?.[1];
  return value === undefined ? fallback : Number(value);
}


function projectActionKey(source, action) {
  const match = source.match(new RegExp(`^${action}=\\{([\\s\\S]*?)^\\}`, 'm'));
  if (!match) return '';
  const code = Number(match[1].match(/physical_keycode":(\d+)/)?.[1] ?? 0);
  const special = { 4194305: 'Esc', 4194306: 'Tab', 4194309: 'Enter', 4194325: 'Shift' };
  let label = special[code] ?? (code >= 32 && code <= 126 ? String.fromCharCode(code).toUpperCase() : String(code));
  if (match[1].includes('ctrl_pressed":true')) label = `Ctrl+${label}`;
  return label;
}


function loadInterfaceMechanics() {
  const project = readFileSync(projectSettingsPath, 'utf8');
  const world = readFileSync(worldInteractionPath, 'utf8');
  const inventory = readFileSync(inventoryUiPath, 'utf8');
  const hotbar = readFileSync(hotbarUiPath, 'utf8');
  const saves = readFileSync(saveManagerPath, 'utf8');
  const multiplayer = readFileSync(multiplayerManagerPath, 'utf8');
  const actions = ['up', 'down', 'left', 'right', 'run', 'dash', 'interact', 'inventory', 'recipe_book', 'quest_book', 'toggle_map', 'chat', 'technology_tree'];
  return {
    keys: Object.fromEntries(actions.map((action) => [action, projectActionKey(project, action)])),
    inventorySlots: numericAssignment(inventory, 'TOTAL_INV_SLOTS', 36),
    visibleInventorySlots: numericAssignment(inventory, 'VISIBLE_SLOTS', 27),
    rowSize: numericAssignment(inventory, 'ROW_SIZE', 9),
    hotbarSlots: numericAssignment(hotbar, 'TOTAL_HOTBAR_SLOTS', 9),
    buildRadius: numericAssignment(world, 'build_radius_tiles', 4),
    autosaveMinutes: Number(saves.match(/"autosave_minutes":\s*(\d+)/)?.[1] ?? 5),
    multiplayerPort: numericAssignment(multiplayer, 'DEFAULT_PORT', 7777),
    maxPlayers: numericAssignment(multiplayer, 'MAX_PLAYERS', 8),
  };
}

const interfaceMechanics = loadInterfaceMechanics();


function loadExplorationMechanics() {
  const time = readFileSync(timeManagerPath, 'utf8');
  const weather = readFileSync(weatherManagerPath, 'utf8');
  const map = readFileSync(mapSystemPath, 'utf8');
  const obeliskManager = readFileSync(obeliskManagerPath, 'utf8');
  const obeliskRegistry = readFileSync(obeliskRegistryPath, 'utf8');
  const biomes = readFileSync(biomeGeneratorPath, 'utf8');
  const structures = readFileSync(structureGeneratorPath, 'utf8');
  const drops = readFileSync(droppedItemPath, 'utf8');
  const constants = readFileSync(gameConstantsPath, 'utf8');
  const chunk = readFileSync(chunkPath, 'utf8');
  const directionCount = (obeliskRegistry.match(/"key":\s*"/g) ?? []).length || 4;
  return {
    minutesPerSecond: numericAssignment(time, 'MINUTES_PER_REAL_SECOND', 1),
    minutesPerDay: 24 * 60,
    startHour: 8,
    clearMin: numericAssignment(weather, 'CLEAR_MIN', 300),
    clearMax: numericAssignment(weather, 'CLEAR_MAX', 720),
    rainMin: numericAssignment(weather, 'RAIN_MIN', 90),
    rainMax: numericAssignment(weather, 'RAIN_MAX', 240),
    stormChance: numericAssignment(weather, 'STORM_CHANCE', 0.25),
    rainParticles: numericAssignment(weather, 'RAIN_AMOUNT', 260),
    stormParticles: numericAssignment(weather, 'STORM_AMOUNT', 600),
    mapKey: interfaceMechanics.keys.toggle_map,
    pingLifetime: numericAssignment(map, 'PING_LIFETIME', 15),
    pingSize: numericAssignment(map, 'PING_SIZE', 60),
    dragThreshold: numericAssignment(map, 'DRAG_CLICK_THRESHOLD', 8),
    resourceMarkerSize: numericAssignment(map, 'RESOURCE_MARKER_SIZE', 44),
    obeliskClickRange: numericAssignment(map, 'OBELISK_CLICK_RANGE', 600),
    discoverRange: numericAssignment(obeliskManager, 'DISCOVER_RANGE', 100),
    fadeTime: numericAssignment(obeliskManager, 'FADE_TIME', 0.18),
    directionCount,
    obeliskCount: 1 + directionCount + directionCount * 2 + directionCount * 3,
    normalSpread: numericAssignment(obeliskRegistry, 'NORMAL_SPREAD', 18),
    hardSpread: numericAssignment(obeliskRegistry, 'HARD_SPREAD', 22),
    beachWidth: numericAssignment(biomes, 'BOUNDARY_BEACH', 22),
    forestRadius: numericAssignment(biomes, 'forest_radius', 480),
    sectorRadius: numericAssignment(biomes, 'sector_radius', 1280),
    hardRadius: numericAssignment(biomes, 'hard_radius', 2560),
    radialWarp: numericAssignment(biomes, 'radial_warp', 45),
    sectorWarp: numericAssignment(biomes, 'sector_warp', 70),
    targetStructures: numericAssignment(structures, 'TARGET_COUNT', 24),
    structureAttempts: numericAssignment(structures, 'MAX_ATTEMPTS', 120),
    structureSpacing: numericAssignment(structures, 'MIN_SPACING', 96),
    structureSpawnDistance: numericAssignment(structures, 'MIN_SPAWN_DIST', 120),
    lootMin: numericAssignment(structures, 'LOOT_STACKS_MIN', 3),
    lootMax: numericAssignment(structures, 'LOOT_STACKS_MAX', 5),
    tileSize: numericAssignment(constants, 'TILE_SIZE', 32),
    renderRadius: numericAssignment(constants, 'RENDER_RADIUS', 4),
    chunkSize: numericAssignment(chunk, 'SIZE', 16),
    magnetRadius: numericAssignment(drops, 'MAGNET_RADIUS', 64),
    pickupRadius: numericAssignment(drops, 'PICKUP_RADIUS', 20),
    magnetSpeed: numericAssignment(drops, 'MAGNET_SPEED', 220),
    pickupDelay: numericAssignment(drops, 'DEFAULT_PICKUP_DELAY', 0.35),
  };
}

const explorationMechanics = loadExplorationMechanics();


function loadOptimizationMechanics() {
  const machine = readFileSync(machineContainerPath, 'utf8');
  const assembler = readFileSync(steamAssemblerPath, 'utf8');
  const conveyor = readFileSync(conveyorContainerPath, 'utf8');
  const reservations = readFileSync(ingredientReservationsPath, 'utf8');
  const analyzer = readFileSync(productionAnalyzerPath, 'utf8');
  const cokeOven = readFileSync(cokeOvenPath, 'utf8');
  const hud = readFileSync(factorySystemsHudPath, 'utf8');
  const decimalFrom = (source, expression, fallback) => Number(source.match(expression)?.[1] ?? fallback);
  const assemblerProcess = numericAssignment(assembler, 'PROCESS_TIME', 5);
  const cokeProcess = numericAssignment(cokeOven, 'PROCESS_TIME', 15);
  return {
    defaultTick: numericAssignment(machine, 'DEFAULT_TICK_INTERVAL', 0.1),
    outputMinGap: numericAssignment(machine, 'ITEM_OUTPUT_CONTROL_MIN_GAP', 0.05),
    stockScan: numericAssignment(machine, 'STOCK_CONTROL_SCAN_INTERVAL_MSEC', 500),
    stockResumeRatio: numericAssignment(machine, 'STOCK_CONTROL_RESUME_RATIO', 0.75),
    stockMaxNodes: numericAssignment(machine, 'STOCK_CONTROL_MAX_NETWORK_NODES', 512),
    stockClaimTimeout: numericAssignment(machine, 'STOCK_CONTROL_CLAIM_TIMEOUT_MSEC', 1200),
    stockMaxProducers: numericAssignment(machine, 'STOCK_CONTROL_MAX_ACTIVE_PRODUCERS', 4),
    idleMultiplier: numericAssignment(machine, 'IDLE_TICK_MULTIPLIER', 5),
    idleGrace: numericAssignment(machine, 'IDLE_GRACE', 2),
    remoteDistance: numericAssignment(machine, 'REMOTE_DISTANCE', 1600),
    remoteTick: numericAssignment(machine, 'REMOTE_TICK_INTERVAL', 0.5),
    moduleLimit: numericAssignment(machine, 'MODULE_LIMIT', 3),
    moduleTypes: (machine.match(/"(speed|efficiency|capacity|productivity)":\s*"machine_module_/g) ?? []).length,
    speedBonus: decimalFrom(machine, /processing_speed_multiplier[\s\S]*?\+\s*(\d+(?:\.\d+)?)\s*\*/, 0.2),
    efficiencyBonus: decimalFrom(machine, /energy_use_multiplier[\s\S]*?-\s*(\d+(?:\.\d+)?)\s*\*\s*get_module_level\("efficiency"\)/, 0.15),
    speedEnergyPenalty: decimalFrom(machine, /energy_use_multiplier[\s\S]*?\+\s*(\d+(?:\.\d+)?)\s*\*\s*get_module_level\("speed"\)/, 0.1),
    energyFloor: decimalFrom(machine, /energy_use_multiplier[\s\S]*?maxf\((\d+(?:\.\d+)?)/, 0.45),
    capacityBonus: decimalFrom(machine, /capacity_multiplier[\s\S]*?\+\s*(\d+(?:\.\d+)?)\s*\*/, 0.35),
    productivityBonus: decimalFrom(machine, /productivity_bonus[\s\S]*?return\s*(\d+(?:\.\d+)?)\s*\*/, 0.08),
    defaultOutputStart: numericAssignment(machine, 'item_output_start_below', 0.25),
    defaultOutputStop: numericAssignment(machine, 'item_output_stop_above', 0.85),
    defaultStockTarget: numericAssignment(machine, 'stock_control_target', 200),
    stockMaxTarget: 9999,
    assemblerInputSlots: numericAssignment(assembler, 'INPUT_SLOT_COUNT', 4),
    assemblerRequestBatches: numericAssignment(assembler, 'INGREDIENT_REQUEST_BATCHES', 4),
    distributionScan: numericAssignment(assembler, 'RECIPE_DISTRIBUTION_SCAN_INTERVAL_MSEC', 500),
    distributionTimeout: numericAssignment(assembler, 'RECIPE_DISTRIBUTION_CLAIM_TIMEOUT_MSEC', 1200),
    conveyorRequestMaxNodes: numericAssignment(conveyor, 'INGREDIENT_DEMAND_MAX_NODES', 128),
    reservationTtl: numericAssignment(reservations, 'RESERVATION_TTL_MSEC', 600000),
    alertCooldown: numericAssignment(hud, 'ALERT_COOLDOWN', 12),
    ironRate: numericAssignment(analyzer, 'IRON_LINE_CAPACITY_PER_MINUTE', 20),
    researchRate: 60 / assemblerProcess,
    steelRate: 60 / (cokeProcess * 2) * 2,
  };
}

const optimizationMechanics = loadOptimizationMechanics();


function loadMultiplayerMechanics() {
  const manager = readFileSync(multiplayerManagerPath, 'utf8');
  const sync = readFileSync(netSyncPath, 'utf8');
  const chat = readFileSync(gameChatPath, 'utf8');
  const ping = readFileSync(pingIndicatorPath, 'utf8');
  return {
    gamePort: numericAssignment(manager, 'DEFAULT_PORT', 7777),
    maxPlayers: numericAssignment(manager, 'MAX_PLAYERS', 8),
    discoveryPort: numericAssignment(manager, 'DISCOVERY_PORT', 7778),
    protocolVersion: numericAssignment(manager, 'PROTOCOL_VERSION', 1),
    beaconInterval: numericAssignment(manager, 'BROADCAST_INTERVAL', 1),
    serverTimeout: numericAssignment(manager, 'SERVER_TIMEOUT_MS', 4000),
    joinTimeout: numericAssignment(manager, 'JOIN_TIMEOUT', 10),
    machineSync: numericAssignment(sync, 'MACHINE_SYNC_INTERVAL', 0.5),
    machineSnapshot: numericAssignment(sync, 'MACHINES_SNAPSHOT_INTERVAL', 10),
    progressionSync: numericAssignment(sync, 'PROGRESSION_SYNC_INTERVAL', 1),
    editRangeTiles: 10,
    fadeDelay: numericAssignment(chat, 'FADE_DELAY', 7),
    fadeDuration: numericAssignment(chat, 'FADE_DURATION', 1),
    maxSuggestions: numericAssignment(chat, 'MAX_VISIBLE_SUGGESTIONS', 8),
    pingUpdate: numericAssignment(ping, 'UPDATE_INTERVAL', 0.5),
    goodPing: numericAssignment(ping, 'GOOD_MS', 60),
    warnPing: numericAssignment(ping, 'WARN_MS', 150),
    mapPingLifetime: explorationMechanics.pingLifetime,
  };
}

const multiplayerMechanics = loadMultiplayerMechanics();


function loadEnergyMechanics() {
  const network = readFileSync(powerNetworkPath, 'utf8');
  const overlay = readFileSync(powerOverlayPath, 'utf8');
  const storage = readFileSync(energyStoragePath, 'utf8');
  const coal = readFileSync(coalGeneratorPath, 'utf8');
  const turbine = readFileSync(steamTurbinePath, 'utf8');
  const weather = readFileSync(weatherManagerPath, 'utf8');
  const solarSources = solarPanelPaths.map((path) => readFileSync(path, 'utf8'));
  const uniqueNumbers = (matches) => [...new Set([...matches].map((match) => Number(match[1])))];
  const fuelBlock = coal.match(/const FUEL_BURN_TIME[\s\S]*?=\s*\{([\s\S]*?)\n\}/)?.[1] ?? '';
  const fuels = Object.fromEntries([...fuelBlock.matchAll(/"([^"]+)":\s*(\d+(?:\.\d+)?)/g)].map((match) => [match[1], Number(match[2])]));
  const solarRates = solarSources.map((source) => numericAssignment(source, 'EU_PER_SECOND', numericAssignment(source, 'eu_per_second', 0)));
  const weatherMatch = weather.match(/const SOLAR_FACTORS[^=]*=\s*\{CLEAR:\s*(\d+(?:\.\d+)?),\s*RAIN:\s*(\d+(?:\.\d+)?),\s*STORM:\s*(\d+(?:\.\d+)?)/);
  return {
    conductorWireTypes: (network.match(/const WIRE_IDS[\s\S]*?\{([\s\S]*?)\n\}/)?.[1].match(/"[^"]+"/g) ?? []).length,
    tutorialCheck: Number(network.match(/_tutorial_report_timer\s*=\s*(\d+(?:\.\d+)?)/)?.[1] ?? 0.75),
    healthyDeficit: Number(network.match(/deficit[^\n]*>\s*(\d+(?:\.\d+)?)/)?.[1] ?? 0.01),
    overlayRefresh: Number([...overlay.matchAll(/_refresh_timer\s*=\s*(\d+(?:\.\d+)?)/g)].at(-1)?.[1] ?? 0.2),
    loadedRatio: Number(overlay.match(/generation\s*\/\s*demand\s*<\s*(\d+(?:\.\d+)?)/)?.[1] ?? 1.15),
    coalRate: numericAssignment(coal, 'EU_PER_SECOND', 40),
    fuels,
    turbineRate: numericAssignment(turbine, 'EU_PER_SECOND', 40),
    turbineEuPerLiter: numericAssignment(turbine, 'EU_PER_LITER', 10),
    turbineIntake: numericAssignment(turbine, 'INTAKE_RATE', 8),
    turbineBuffer: numericAssignment(turbine, 'BUFFER_CAPACITY', 100),
    storageCapacities: uniqueNumbers(storage.matchAll(/capacity\s*=\s*(\d+(?:\.\d+)?)/g)),
    storageIo: uniqueNumbers(storage.matchAll(/max_io\s*=\s*(\d+(?:\.\d+)?)/g)),
    solarRates,
    solarBufferSeconds: numericAssignment(solarSources[0], 'BUFFER_SECONDS', 30),
    solarFactors: weatherMatch ? weatherMatch.slice(1).map(Number) : [1, 0.5, 0.25],
    stormChance: numericAssignment(weather, 'STORM_CHANCE', 0.25),
  };
}

const energyMechanics = loadEnergyMechanics();


function loadLogisticsMechanics() {
  const conveyor = readFileSync(conveyorContainerPath, 'utf8');
  const splitter = readFileSync(conveyorSplitterPath, 'utf8');
  const inserter = readFileSync(mechanicalInserterPath, 'utf8');
  const reservations = readFileSync(ingredientReservationsPath, 'utf8');
  const manager = readFileSync(logisticsNetworkPath, 'utf8');
  const overlay = readFileSync(logisticsOverlayPath, 'utf8');
  const chest = readFileSync(chestDataPath, 'utf8');
  const project = readFileSync(projectSettingsPath, 'utf8');
  const beltFiles = ['conveyor.tres', 'conveyor_t2.tres', 'conveyor_t3.tres', 'conveyor_t4.tres', 'conveyor_t5.tres'];
  const defaultCrossTime = numericAssignment(conveyor, 'CROSS_TIME', 0.8);
  const belts = beltFiles.map((file, index) => {
    const source = readFileSync(resolve(blockDefinitionsRoot, file), 'utf8');
    const tier = numericAssignment(source, 'belt_tier', index + 1);
    return {
      id: index === 0 ? 'conveyor' : `conveyor_t${index + 1}`,
      tier,
      crossTime: numericAssignment(source, 'belt_cross_time', defaultCrossTime),
      power: tier === 1 ? 0 : tier,
    };
  });
  const capacityBlock = chest.match(/static func get_logistics_rule_capacity_for_tier[\s\S]*?\n\n/)?.[0] ?? '';
  return {
    belts,
    demandMaxNodes: numericAssignment(conveyor, 'INGREDIENT_DEMAND_MAX_NODES', 128),
    beltJamVisualDelay: Number(conveyor.match(/jam_time\s*>=\s*(\d+(?:\.\d+)?)/)?.[1] ?? 0.35),
    beltFilterLimit: Number(conveyor.match(/result\.size\(\)\s*>=\s*(\d+)/)?.[1] ?? 24),
    beltPriorityMin: -10,
    beltPriorityMax: 10,
    splitterOutputs: Number(splitter.match(/var output_filters[^\n]*/)?.[0].match(/PackedStringArray\(\)/g)?.length ?? 2),
    inserterInterval: numericAssignment(inserter, 'TRANSFER_INTERVAL', 1.5),
    inserterFilterLimit: numericAssignment(inserter, 'MAX_FILTER_IDS', 24),
    reservationTtl: numericAssignment(reservations, 'RESERVATION_TTL_MSEC', 600000),
    ruleCapacities: [...capacityBlock.matchAll(/return\s+(\d+)/g)].map((match) => Number(match[1])).sort((a, b) => a - b),
    requestTargetMax: Number(chest.match(/target_stock[^\n]*clampi\([^,]+,\s*1,\s*(\d+)/)?.[1] ?? 9999),
    providerMinMax: Number(chest.match(/minimum_stock[^\n]*clampi\([^,]+,\s*0,\s*(\d+)/)?.[1] ?? 9999),
    providerPriorityMin: -2,
    providerPriorityMax: 2,
    alertScan: numericAssignment(manager, 'ALERT_SCAN_INTERVAL', 2),
    alertPersist: numericAssignment(manager, 'ALERT_PERSIST_SECONDS', 8),
    alertCooldown: numericAssignment(manager, 'ALERT_COOLDOWN_SECONDS', 120),
    overlayRefresh: Number(overlay.match(/_refresh_timer\s*=\s*(\d+(?:\.\d+)?)/)?.[1] ?? 0.25),
    overlayFilters: numericAssignment(overlay, 'FILTER_COUNT', 4),
    cameraFocus: numericAssignment(overlay, 'CAMERA_FOCUS_DURATION', 0.35),
    snoozeSeconds: numericAssignment(overlay, 'PROBLEM_SNOOZE_SECONDS', 60),
    keys: {
      overlay: projectActionKey(project, 'toggle_logistics_overlay'),
      previous: projectActionKey(project, 'logistics_previous_problem'),
      next: projectActionKey(project, 'logistics_next_problem'),
      filter: projectActionKey(project, 'logistics_cycle_problem_filter'),
      snooze: projectActionKey(project, 'logistics_snooze_problem'),
    },
  };
}

const logisticsMechanics = loadLogisticsMechanics();


function loadSteamMechanics() {
  const pump = readFileSync(waterPumpPath, 'utf8');
  const boiler = readFileSync(steamBoilerPath, 'utf8');
  const machine = readFileSync(steamMachinePath, 'utf8');
  const network = readFileSync(fluidNetworkPath, 'utf8');
  const overlay = readFileSync(fluidOverlayPath, 'utf8');
  const valve = readFileSync(fluidValvePath, 'utf8');
  const project = readFileSync(projectSettingsPath, 'utf8');
  const fuelBlock = boiler.match(/const FUEL_BURN_TIME[\s\S]*?=\s*\{([\s\S]*?)\n\}/)?.[1] ?? '';
  const fuels = Object.fromEntries([...fuelBlock.matchAll(/"([^"]+)":\s*(\d+(?:\.\d+)?)/g)].map((match) => [match[1], Number(match[2])]));
  const machines = Object.fromEntries(Object.entries(steamMachinePaths).map(([id, path]) => {
    const source = readFileSync(path, 'utf8');
    return [id, {
      processTime: numericAssignment(source, 'PROCESS_TIME', 5),
      steamRate: numericAssignment(source, 'STEAM_PER_SECOND', 2),
    }];
  }));
  const ratioMatch = pump.match(/const STEAM_PER_WATER\s*:=\s*(\d+(?:\.\d+)?)\s*\/\s*(\d+(?:\.\d+)?)/);
  return {
    pumpRates: {
      mechanical: numericAssignment(pump, 'MECHANICAL_PUMP_RATE', 4),
      electric: numericAssignment(pump, 'PUMP_RATE', 8),
      steam: numericAssignment(pump, 'STEAM_PUMP_RATE', 16),
    },
    electricPumpPower: numericAssignment(pump, 'POWER_CONSUMPTION', 10),
    pumpBuffer: Number(pump.match(/output_tanks\s*=\s*\[FluidTank\.new\((\d+(?:\.\d+)?)\)\]/)?.[1] ?? 150),
    steamPumpInput: numericAssignment(pump, 'STEAM_BUFFER_CAPACITY', 30),
    steamPumpOutput: numericAssignment(pump, 'STEAM_PUMP_OUTPUT_CAPACITY', 300),
    steamPerWater: ratioMatch ? Number(ratioMatch[1]) / Number(ratioMatch[2]) : 1 / 16,
    boilerRate: numericAssignment(boiler, 'STEAM_PER_SECOND', 4),
    boilerWaterTank: numericAssignment(boiler, 'WATER_TANK_CAPACITY', 100),
    boilerSteamTank: numericAssignment(boiler, 'STEAM_TANK_CAPACITY', 200),
    boilerCreosoteTank: numericAssignment(boiler, 'CREOSOTE_TANK_CAPACITY', 100),
    creosoteBurn: numericAssignment(boiler, 'CREOSOTE_BURN_PER_LITER', 2),
    fuels,
    machineTank: numericAssignment(machine, 'STEAM_TANK_CAPACITY', 50),
    machines,
    pipeT1: numericAssignment(network, 'TRANSFER_RATE', 12),
    pipeT2: numericAssignment(network, 'T2_TRANSFER_RATE', 30),
    alertInterval: numericAssignment(network, 'ALERT_INTERVAL', 20),
    valveThreshold: numericAssignment(valve, 'overflow_threshold', 0.8),
    saturationThreshold: Number(network.match(/utilization\s*<\s*(\d+(?:\.\d+)?)/)?.[1] ?? 0.98),
    overlayRefresh: Number(overlay.match(/_refresh_timer\s*=\s*(\d+(?:\.\d+)?)/)?.[1] ?? 0.2),
    overlayKey: projectActionKey(project, 'toggle_fluid_overlay'),
  };
}

const steamMechanics = loadSteamMechanics();


function loadOreProcessingMechanics() {
  const sources = Object.fromEntries(Object.entries(oreProcessingPaths).map(([id, path]) => [id, readFileSync(path, 'utf8')]));
  const steamFurnace = readFileSync(steamMachinePaths.furnace, 'utf8');
  const recipeCount = (source, name) => {
    const block = source.match(new RegExp(`const\\s+${name}[\\s\\S]*?=\\s*\\{([\\s\\S]*?)\\n\\}`))?.[1] ?? '';
    return (block.match(/^\s*"[^"]+"\s*:/gm) ?? []).length;
  };
  return {
    primitive: { time: numericAssignment(sources.primitiveCrusher, 'PROCESS_TIME', 8), recipes: recipeCount(sources.primitiveCrusher, 'CRUSHER_RECIPES') },
    steam: { time: numericAssignment(sources.steamCrusher, 'PROCESS_TIME', 6), steam: numericAssignment(sources.steamCrusher, 'STEAM_PER_SECOND', 2), recipes: recipeCount(sources.steamCrusher, 'RECIPES') },
    electric: { time: numericAssignment(sources.crusher, 'PROCESS_TIME', 4), power: numericAssignment(sources.crusher, 'POWER_CONSUMPTION', 20), recipes: recipeCount(sources.crusher, 'CRUSHER_RECIPES') },
    washer: { time: numericAssignment(sources.washer, 'PROCESS_TIME', 4), power: numericAssignment(sources.washer, 'POWER_CONSUMPTION', 15), water: numericAssignment(sources.washer, 'WATER_PER_OP', 10), tank: numericAssignment(sources.washer, 'WATER_TANK_CAPACITY', 100), recipes: recipeCount(sources.washer, 'RECIPES') },
    separator: { time: numericAssignment(sources.separator, 'PROCESS_TIME', 5), power: numericAssignment(sources.separator, 'POWER_CONSUMPTION', 25), byproducts: numericAssignment(sources.separator, 'BYPRODUCT_COUNT', 1), recipes: recipeCount(sources.separator, 'RECIPES') },
    centrifuge: { time: numericAssignment(sources.centrifuge, 'PROCESS_TIME', 5), power: numericAssignment(sources.centrifuge, 'POWER_CONSUMPTION', 30), byproducts: numericAssignment(sources.centrifuge, 'BYPRODUCT_COUNT', 1), recipes: recipeCount(sources.centrifuge, 'RECIPES') },
    melter: { time: numericAssignment(sources.melter, 'PROCESS_TIME', 4), power: numericAssignment(sources.melter, 'POWER_CONSUMPTION', 40), ingotLiters: numericAssignment(sources.melter, 'INGOT_L', 90), tank: numericAssignment(sources.melter, 'TANK_CAPACITY', 540), recipes: recipeCount(sources.melter, 'MELT_RECIPES') },
    furnace: { time: numericAssignment(sources.furnace, 'SMELT_TIME', 3), recipes: recipeCount(sources.furnace, 'SMELT_RECIPES') },
    steamFurnace: { time: numericAssignment(steamFurnace, 'PROCESS_TIME', 2.5), steam: numericAssignment(steamFurnace, 'STEAM_PER_SECOND', 2), recipes: recipeCount(steamFurnace, 'RECIPES') },
    electricFurnace: { time: numericAssignment(sources.electricFurnace, 'PROCESS_TIME', 1), power: numericAssignment(sources.electricFurnace, 'POWER_CONSUMPTION', 30), recipes: recipeCount(sources.electricFurnace, 'SMELT_RECIPES') },
  };
}

const oreProcessingMechanics = loadOreProcessingMechanics();


function loadOreMechanics() {
  const ores = [];
  for (const fileName of readdirSync(oreDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const source = readFileSync(resolve(oreDefinitionsRoot, fileName), 'utf8');
    const id = tresString(source, 'deposit_id');
    if (!id) continue;
    ores.push({
      id, itemId: tresString(source, 'resource_item_id'), level: tresNumber(source, 'mining_level_required') ?? 1,
      miningHealth: tresNumber(source, 'mining_health') ?? 10, yieldAmount: tresNumber(source, 'yield_amount') ?? 1,
      atlas: tresNumber(source, 'atlas_x') ?? 0, weight: tresNumber(source, 'spawn_weight') ?? 0,
      biomes: packedStrings(source, 'spawn_biomes'),
    });
  }
  return ores.sort((left, right) => left.atlas - right.atlas);
}


function loadCropMechanics() {
  const crops = [];
  for (const fileName of readdirSync(cropDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const source = readFileSync(resolve(cropDefinitionsRoot, fileName), 'utf8');
    const id = tresString(source, 'crop_id');
    if (!id) continue;
    const stages = tresNumber(source, 'stages') ?? 4;
    const minutesPerStage = tresNumber(source, 'minutes_per_stage') ?? 90;
    crops.push({ id, itemId: tresString(source, 'plant_item_id'), stages, minutesPerStage, totalMinutes: minutesPerStage * Math.max(stages - 1, 0), yieldMin: tresNumber(source, 'yield_min') ?? 2, yieldMax: tresNumber(source, 'yield_max') ?? 3 });
  }
  return crops.sort((left, right) => left.totalMinutes - right.totalMinutes);
}


function loadForageMechanics() {
  const entries = [];
  for (const fileName of readdirSync(forageDefinitionsRoot)) {
    if (!fileName.endsWith('.tres')) continue;
    const source = readFileSync(resolve(forageDefinitionsRoot, fileName), 'utf8');
    const id = tresString(source, 'deposit_id');
    if (!id) continue;
    entries.push({
      id, displayName: tresString(source, 'display_name'), itemId: tresString(source, 'resource_item_id'),
      health: tresNumber(source, 'health') ?? 1, amount: tresNumber(source, 'total_resource_amount') ?? 1,
      spacing: tresNumber(source, 'minimum_spacing') ?? 1, water: tresBoolean(source, 'requires_water') ?? false,
      defaultChance: tresNumber(source, 'default_spawn_chance') ?? 0, chances: tresDictionary(source, 'spawn_chance_by_biome'),
    });
  }
  return entries.sort((left, right) => left.id.localeCompare(right.id));
}


function loadDrillMechanics() {
  const source = readFileSync(drillContainerPath, 'utf8');
  const tiers = [];
  for (const entry of splitTopLevelArguments(gdConstBlock(source, 'TIERS', '{', '}'))) {
    const id = entry.match(/^"([^"]+)"\s*:/)?.[1];
    if (!id) continue;
    tiers.push({ id, power: gdNumber(entry, 'power') ?? 0, interval: gdNumber(entry, 'interval') ?? 0, euPerSecond: gdNumber(entry, 'eu_per_s') ?? 0, noOutput: /"no_output":\s*true/.test(entry) });
  }
  return { tiers, powerBufferSeconds: Number(source.match(/POWER_BUFFER_SECONDS := (\d+(?:\.\d+)?)/)?.[1] ?? 10), bufferSlots: Number(source.match(/BUFFER_SLOTS := (\d+)/)?.[1] ?? 2) };
}


function loadMiningMechanics() {
  const tierSource = readFileSync(toolTierPath, 'utf8');
  const componentSource = readFileSync(miningComponentPath, 'utf8');
  const oreDbSource = readFileSync(oreDatabasePath, 'utf8');
  const oilSource = readFileSync(oilDepositGeneratorPath, 'utf8');
  return {
    damageBase: Number(tierSource.match(/DAMAGE_BASE := (\d+(?:\.\d+)?)/)?.[1] ?? 18),
    damagePerPower: Number(tierSource.match(/DAMAGE_PER_POWER := (\d+(?:\.\d+)?)/)?.[1] ?? 20),
    swingIntervals: (tierSource.match(/SWING_INTERVALS[^=]*= \[([^\]]+)\]/)?.[1] ?? '').split(',').map((value) => Number(value.trim())).filter(Number.isFinite),
    regenDelay: Number(componentSource.match(/REGEN_DELAY := (\d+(?:\.\d+)?)/)?.[1] ?? 5),
    wrongToolMultiplier: Number(componentSource.match(/WRONG_TOOL_MULT := (\d+(?:\.\d+)?)/)?.[1] ?? 0.5),
    depositCellSize: Number(oreDbSource.match(/DEPOSIT_CELL_SIZE := (\d+)/)?.[1] ?? 40),
    depositSpawnChance: Number(oreDbSource.match(/BASE_DEPOSIT_SPAWN_CHANCE := (\d+(?:\.\d+)?)/)?.[1] ?? 0.28),
    fluidCellSize: Number(oilSource.match(/CELL_SIZE := (\d+)/)?.[1] ?? 46),
    oilSpawnChance: Number(oilSource.match(/SPAWN_CHANCE := (\d+(?:\.\d+)?)/)?.[1] ?? 0.18),
    lavaSpawnChance: 0.5,
    fluidCapacity: Number(oilSource.match(/MAX_LITERS := (\d+(?:\.\d+)?)/)?.[1] ?? 1000),
    fluidShapeTiles: [...gdConstBlock(oilSource, 'SHAPE', '[', ']').matchAll(/Vector2i\(/g)].length,
  };
}


const oreMechanics = loadOreMechanics();
const cropMechanics = loadCropMechanics();
const forageMechanics = loadForageMechanics();
const drillMechanics = loadDrillMechanics();
const miningMechanics = loadMiningMechanics();


function gdFluidAmounts(source, constants = {}) {
  const values = [];
  for (const match of source.matchAll(/"([^"]+)":\s*([A-Z][A-Z0-9_]*|\d+(?:\.\d+)?)/g)) {
    const amount = constants[match[2]] ?? Number(match[2]);
    if (Number.isFinite(amount)) values.push({ type: 'fluid', id: match[1], amount });
  }
  return values;
}


function loadFluidRecipes() {
  const recipes = [];
  const add = (recipe) => recipes.push({ processTime: null, power: null, ...recipe });

  add({ id: 'water_mechanical', machineId: 'mechanical_water_pump', inputs: [], outputs: [{ type: 'fluid', id: 'water', amount: 4 }], processTime: 1, note: 'world_water' });
  add({ id: 'water_steam', machineId: 'steam_water_pump', inputs: [{ type: 'fluid', id: 'steam', amount: 1 }], outputs: [{ type: 'fluid', id: 'water', amount: 16 }], processTime: 1 });
  add({ id: 'water_electric', machineId: 'water_pump', inputs: [], outputs: [{ type: 'fluid', id: 'water', amount: 8 }], processTime: 1, power: 10, note: 'world_water' });
  add({ id: 'steam_boiling', machineId: 'steam_boiler', inputs: [{ type: 'fluid', id: 'water', amount: 4 }], outputs: [{ type: 'fluid', id: 'steam', amount: 4 }], processTime: 1, note: 'fuel_required' });
  add({ id: 'creosote_coking', machineId: 'coke_oven', inputs: [{ type: 'item', id: 'coal', amount: 1 }], outputs: [{ type: 'item', id: 'coke', amount: 1 }, { type: 'fluid', id: 'creosote', amount: 0.5 }], processTime: 15 });
  add({ id: 'crude_pumping', machineId: 'oil_pump', inputs: [], outputs: [{ type: 'fluid', id: 'crude_oil', amount: 4 }], processTime: 1, power: 15, note: 'deposit' });
  add({ id: 'lava_pumping', machineId: 'oil_pump', inputs: [], outputs: [{ type: 'fluid', id: 'lava', amount: 4 }], processTime: 1, power: 15, note: 'deposit' });
  add({ id: 'steam_turbine_use', machineId: 'steam_turbine', inputs: [{ type: 'fluid', id: 'steam', amount: 4 }], outputs: [{ type: 'energy', id: 'eu', amount: 40 }], processTime: 1 });
  add({ id: 'steam_furnace_use', machineId: 'steam_furnace', inputs: [{ type: 'fluid', id: 'steam', amount: 2 }], outputs: [], processTime: 1, note: 'while_working' });
  add({ id: 'steam_crusher_use', machineId: 'steam_crusher', inputs: [{ type: 'fluid', id: 'steam', amount: 2 }], outputs: [], processTime: 1, note: 'while_working' });
  add({ id: 'steam_press_use', machineId: 'steam_press', inputs: [{ type: 'fluid', id: 'steam', amount: 2 }], outputs: [], processTime: 1, note: 'while_working' });
  add({ id: 'steam_assembler_use', machineId: 'steam_assembler', inputs: [{ type: 'fluid', id: 'steam', amount: 1.5 }], outputs: [], processTime: 1, note: 'while_working' });
  add({ id: 'ore_washer_water', machineId: 'ore_washer', inputs: [{ type: 'fluid', id: 'water', amount: 10 }], outputs: [], processTime: 4, power: 15, note: 'per_operation' });

  const distillationSource = readFileSync(fluidMachinePaths.distillation, 'utf8');
  const distillationOutputs = gdFluidAmounts(gdConstBlock(distillationSource, 'PRODUCTS', '{', '}'));
  add({
    id: 'crude_distillation', machineId: 'distillation_column',
    inputs: [{ type: 'fluid', id: 'crude_oil', amount: Number(distillationSource.match(/CRUDE_PER_BATCH := (\d+(?:\.\d+)?)/)?.[1] ?? 10) }],
    outputs: distillationOutputs,
    processTime: Number(distillationSource.match(/PROCESS_TIME := (\d+(?:\.\d+)?)/)?.[1] ?? 5),
    power: Number(distillationSource.match(/POWER_CONSUMPTION := (\d+(?:\.\d+)?)/)?.[1] ?? 60),
  });

  const mixerSource = readFileSync(fluidMachinePaths.mixer, 'utf8');
  const mixerConstants = numericConstants(mixerSource);
  splitTopLevelArguments(gdConstBlock(mixerSource, 'RECIPES', '[', ']')).forEach((block, index) => {
    if (!block.startsWith('{')) return;
    add({
      id: `mixer_${index + 1}`, machineId: 'mixer',
      inputs: gdFluidAmounts(gdDictionaryBlock(block, 'inputs'), mixerConstants),
      outputs: [{ type: 'fluid', id: gdString(block, 'output'), amount: gdNumber(block, 'output_liters') ?? 0 }],
      processTime: mixerConstants.PROCESS_TIME ?? 5,
      power: mixerConstants.POWER_CONSUMPTION ?? 50,
    });
  });

  const reactorSource = readFileSync(fluidMachinePaths.reactor, 'utf8');
  const reactorConstants = numericConstants(reactorSource);
  splitTopLevelArguments(gdConstBlock(reactorSource, 'RECIPES', '[', ']')).forEach((block, index) => {
    if (!block.startsWith('{')) return;
    const inputs = gdFluidAmounts(gdDictionaryBlock(block, 'fluids'), reactorConstants);
    const itemId = gdString(block, 'item');
    const catalystId = gdString(block, 'catalyst');
    if (itemId) inputs.push({ type: 'item', id: itemId, amount: gdNumber(block, 'item_count') ?? 1 });
    if (catalystId) inputs.push({ type: 'catalyst', id: catalystId, amount: 1 });
    add({
      id: `reactor_${index + 1}`, machineId: 'chemical_reactor', inputs,
      outputs: [{ type: 'item', id: gdString(block, 'output'), amount: gdNumber(block, 'output_count') ?? 1 }],
      processTime: reactorConstants.PROCESS_TIME ?? 4,
      power: reactorConstants.POWER_CONSUMPTION ?? 30,
    });
  });

  const melterSource = readFileSync(fluidMachinePaths.melter, 'utf8');
  const melterConstants = numericConstants(melterSource);
  const melterRecipes = gdConstBlock(melterSource, 'MELT_RECIPES', '{', '}');
  let melterIndex = 0;
  for (const match of melterRecipes.matchAll(/"([^"]+)":\s*\{"fluid":\s*"([^"]+)",\s*"liters":\s*([A-Z][A-Z0-9_]*|\d+(?:\.\d+)?)\}/g)) {
    melterIndex += 1;
    add({
      id: `melter_${melterIndex}`, machineId: 'ore_melter',
      inputs: [{ type: 'item', id: match[1], amount: 1 }],
      outputs: [{ type: 'fluid', id: match[2], amount: melterConstants[match[3]] ?? Number(match[3]) }],
      processTime: melterConstants.PROCESS_TIME ?? 4,
      power: melterConstants.POWER_CONSUMPTION ?? 40,
    });
  }
  return recipes;
}


function fluidCategory(id) {
  if (id === 'water' || id === 'steam') return 'basic';
  if (id.startsWith('molten_')) return 'molten';
  return 'petroleum';
}


function fluidDescription(id, language) {
  if (fluidDescriptions[id]) return fluidDescriptions[id][language];
  if (id.startsWith('molten_')) {
    return language === 'ru'
      ? 'Жидкий металл из индукционной плавильни. Используется для литья деталей в химическом реакторе или для получения сплавов в смесителе.'
      : 'Liquid metal from the induction melter, used for casting components in the chemical reactor or making alloys in the mixer.';
  }
  return '';
}


function loadFluids() {
  const source = readFileSync(fluidDatabasePath, 'utf8');
  const recipes = loadFluidRecipes();
  const fluids = new Map();
  for (const match of source.matchAll(/^\s*"([^"]+)": \{"name": "([^"]+)", "color": Color\(([-\d.]+), ([-\d.]+), ([-\d.]+)(?:, ([-\d.]+))?\)\}/gm)) {
    const id = match[1];
    fluids.set(id, {
      id, nameEn: match[2], category: fluidCategory(id),
      color: [Number(match[3]), Number(match[4]), Number(match[5]), Number(match[6] ?? 1)],
      sources: recipes.filter((recipe) => recipe.outputs.some((entry) => entry.type === 'fluid' && entry.id === id)),
      uses: recipes.filter((recipe) => recipe.inputs.some((entry) => entry.type === 'fluid' && entry.id === id)),
    });
  }
  return fluids;
}


const fluidsById = loadFluids();
const questEnglishOverrides = new Map([
  ['Энт охраняет переход к электрической эре. Стальной меч наносит достаточно урона, чтобы пробить его кору.', 'The Ent guards the transition to the electrical era. A steel sword deals enough damage to break through its bark.'],
]);


function localizedQuestText(value, language) {
  if (language === 'ru' || !value) return value;
  return questTranslations.get(value)?.en || questEnglishOverrides.get(value) || value;
}


function questObjectiveTarget(objective, language) {
  const id = objective.eventDetail;
  if (!id) return null;
  if (objective.eventType.includes('boss') && bossesById.has(id)) {
    const boss = localizedBoss(bossesById.get(id), language);
    return { type: 'boss', id, title: boss.title };
  }
  if ((objective.eventType.includes('machine') || objective.eventType.includes('block')) && machinesById.has(id)) {
    const machine = localizedMachine(machinesById.get(id), language);
    return { type: 'machine', id, title: machine.title };
  }
  if (itemsById.has(id)) {
    const item = localizedItem(itemsById.get(id), language);
    return { type: 'item', id, title: item.title };
  }
  if (machinesById.has(id)) {
    const machine = localizedMachine(machinesById.get(id), language);
    return { type: 'machine', id, title: machine.title };
  }
  return null;
}


function localizedQuest(quest, language) {
  return {
    id: quest.id,
    age: quest.age,
    tab: localizedQuestText(quest.tab, language),
    title: localizedQuestText(quest.title, language),
    description: localizedQuestText(quest.description, language),
    objectives: quest.objectives.map((objective) => ({
      ...objective,
      description: localizedQuestText(objective.description, language),
      target: questObjectiveTarget(objective, language),
    })),
    unlocks: quest.unlocks.map((unlock) => localizedQuestText(unlock, language)),
    prerequisites: quest.prerequisites,
    tutorial: quest.tutorial,
  };
}


function localizedQuestAgeSummary(ageInfo, language) {
  const ageQuests = quests.filter((quest) => quest.age === ageInfo.age);
  return {
    age: ageInfo.age,
    title: ageInfo.title[language],
    subtitle: ageInfo.subtitle[language],
    questCount: ageQuests.length,
    chapterCount: new Set(ageQuests.map((quest) => quest.tab)).size,
    tutorialCount: ageQuests.filter((quest) => quest.tutorial).length,
  };
}


function localizedQuestAge(ageInfo, language) {
  const ageQuests = quests.filter((quest) => quest.age === ageInfo.age);
  const groups = new Map();
  for (const quest of ageQuests) {
    if (!groups.has(quest.tab)) groups.set(quest.tab, []);
    groups.get(quest.tab).push(localizedQuest(quest, language));
  }
  const chapters = [...groups.entries()]
    .map(([sourceTitle, chapterQuests]) => ({ title: localizedQuestText(sourceTitle, language), tutorial: chapterQuests.every((quest) => quest.tutorial), quests: chapterQuests }))
    .sort((left, right) => Number(left.tutorial) - Number(right.tutorial));
  return { ...localizedQuestAgeSummary(ageInfo, language), chapters };
}


function localizedNpcQuest(quest, language) {
  return {
    id: quest.id,
    title: localizedQuestText(quest.title, language),
    description: localizedQuestText(quest.description, language),
    objectives: quest.objectives.map((objective) => ({
      ...objective,
      description: localizedQuestText(objective.description, language),
      target: questObjectiveTarget(objective, language),
    })),
    rewards: quest.rewards.map((reward) => localizedBossItem(reward.id, reward.count, language)),
    unlocks: quest.unlocks.map((unlock) => localizedQuestText(unlock, language)),
  };
}


function localizedNpcSummary(npc, language) {
  const biome = biomeDefinitions.find((entry) => entry.resource === npc.biomeResource);
  return {
    id: npc.id,
    title: localizedQuestText(npc.name, language),
    role: localizedQuestText(npc.role, language),
    greeting: localizedQuestText(npc.greeting, language),
    color: npc.color,
    biome: biome ? localizedBiomeSummary(biome, language) : null,
    questCount: npc.quests.length,
  };
}


function localizedNpc(npc, language) {
  const summary = localizedNpcSummary(npc, language);
  const npcIndex = npcs.indexOf(npc);
  return {
    ...summary,
    quests: npc.quests.map((quest) => localizedNpcQuest(quest, language)),
    previous: npcIndex > 0 ? localizedNpcSummary(npcs[npcIndex - 1], language) : null,
    next: npcIndex < npcs.length - 1 ? localizedNpcSummary(npcs[npcIndex + 1], language) : null,
  };
}


function localizedRecipeSummary(recipe, language) {
  const localized = localizedRecipe(recipe, language);
  return {
    id: localized.id,
    title: localized.result.title,
    result: localized.result,
    resultCount: localized.resultCount,
    category: localized.category,
    categoryTitle: localized.categoryTitle,
    requiredAge: localized.requiredAge,
    ingredientKinds: localized.ingredients.length,
    ingredientTotal: localized.ingredients.reduce((total, ingredient) => total + ingredient.count, 0),
    station: localized.station,
  };
}


function localizedRecipeUnlocks(recipe, language) {
  const unlocks = [];
  if (recipe.requiredAge <= 6) {
    unlocks.push({
      kind: 'age',
      title: language === 'ru' ? `Эпоха ${recipe.requiredAge}` : `Age ${recipe.requiredAge}`,
      description: language === 'ru' ? 'Открывается основной прогрессией квестовой книги.' : 'Unlocked through the main quest-book progression.',
      url: `/${language}/quests/${recipe.requiredAge}`,
    });
  }
  if (recipe.unlockedByQuest) {
    const owner = npcs.find((npc) => npc.quests.some((quest) => quest.id === recipe.unlockedByQuest));
    const quest = owner?.quests.find((entry) => entry.id === recipe.unlockedByQuest);
    if (owner && quest) {
      unlocks.push({
        kind: 'quest',
        title: localizedQuestText(quest.title, language),
        description: language === 'ru' ? 'Побочное задание открывает рецепт раньше основной эпохи.' : 'This side quest can unlock the recipe ahead of its normal age.',
        url: `/${language}/npcs/${encodeURIComponent(owner.id)}?q=${encodeURIComponent(quest.id)}`,
      });
    }
  }
  if (recipe.unlockedByItem) {
    const item = itemsById.get(recipe.unlockedByItem);
    const localized = item ? localizedItem(item, language) : null;
    unlocks.push({
      kind: 'item',
      title: localized?.title ?? fallbackItemTitle(recipe.unlockedByItem),
      description: language === 'ru' ? 'Изучается при наличии страницы рецепта, выпадающей из босса.' : 'Learned while carrying the boss-dropped recipe page.',
      url: `/${language}/items/${encodeURIComponent(recipe.unlockedByItem)}`,
      texture: localized?.texture ?? null,
      color: localized?.color ?? null,
    });
  }
  return unlocks;
}


function localizedRecipeDetails(recipe, language) {
  const localized = localizedRecipe(recipe, language);
  const index = recipes.indexOf(recipe);
  const technology = technologyStages.find((stage) => [...stage.machines, ...stage.components].includes(recipe.resultId));
  return {
    ...localized,
    unlocks: localizedRecipeUnlocks(recipe, language),
    technology: technology ? localizedTechnologySummary(technology, language) : null,
    usedIngredientCount: recipes.filter((candidate) => candidate.ingredients.some((ingredient) => ingredient.id === recipe.resultId)).length,
    previous: index > 0 ? localizedRecipeSummary(recipes[index - 1], language) : null,
    next: index < recipes.length - 1 ? localizedRecipeSummary(recipes[index + 1], language) : null,
  };
}


function localizedTechnologyOutput(id, language) {
  const machine = machinesById.get(id);
  if (machine) {
    const localized = localizedMachine(machine, language);
    return { id, title: localized.title, texture: localized.texture, color: localized.color, exists: true, kind: 'machine' };
  }
  const item = itemsById.get(id);
  if (item) return { ...localizedBossItem(id, 1, language), kind: 'component' };
  return { id, title: fallbackItemTitle(id), texture: null, color: null, exists: false, kind: 'component' };
}


function localizedFluidSummary(fluid, language) {
  return {
    id: fluid.id,
    title: language === 'ru' ? fluidNamesRu[fluid.id] ?? fluid.nameEn : fluid.nameEn,
    description: fluidDescription(fluid.id, language),
    category: fluid.category,
    categoryTitle: fluidCategoryTitles[fluid.category][language],
    color: fluid.color,
    sourceCount: fluid.sources.length,
    useCount: fluid.uses.length,
  };
}


function localizedFluidRecipePart(part, language) {
  if (part.type === 'energy') return { type: 'energy', id: part.id, title: language === 'ru' ? 'Энергия' : 'Energy', amount: part.amount, exists: true, color: [0.98, 0.72, 0.16, 1] };
  if (part.type === 'fluid' && fluidsById.has(part.id)) {
    const fluid = localizedFluidSummary(fluidsById.get(part.id), language);
    return { type: 'fluid', id: part.id, title: fluid.title, color: fluid.color, amount: part.amount, exists: true };
  }
  const item = localizedBossItem(part.id, part.amount, language);
  return { ...item, amount: part.amount, type: part.type, catalyst: part.type === 'catalyst' };
}


function localizedFluidRecipe(recipe, language) {
  const machine = machinesById.has(recipe.machineId) ? localizedMachine(machinesById.get(recipe.machineId), language) : null;
  const notes = {
    world_water: { ru: 'Требуется клетка воды', en: 'Requires a water tile' },
    fuel_required: { ru: 'Требуется твёрдое топливо или креозот', en: 'Requires solid fuel or creosote' },
    deposit: { ru: 'Требуется месторождение жидкости', en: 'Requires a fluid deposit' },
    while_working: { ru: 'Расходуется только во время обработки', en: 'Consumed only while processing' },
    per_operation: { ru: 'Расход на одну операцию', en: 'Consumption per operation' },
  };
  return {
    id: recipe.id,
    machine: machine ? { id: machine.id, title: machine.title, texture: machine.texture, color: machine.color } : { id: recipe.machineId, title: fallbackItemTitle(recipe.machineId), texture: null, color: null },
    inputs: recipe.inputs.map((part) => localizedFluidRecipePart(part, language)),
    outputs: recipe.outputs.map((part) => localizedFluidRecipePart(part, language)),
    processTime: recipe.processTime,
    power: recipe.power,
    note: recipe.note ? notes[recipe.note]?.[language] ?? recipe.note : '',
  };
}


function localizedFluid(fluid, language) {
  const fluidIndex = [...fluidsById.values()].indexOf(fluid);
  const allFluids = [...fluidsById.values()];
  return {
    ...localizedFluidSummary(fluid, language),
    sources: fluid.sources.map((recipe) => localizedFluidRecipe(recipe, language)),
    uses: fluid.uses.map((recipe) => localizedFluidRecipe(recipe, language)),
    previous: fluidIndex > 0 ? localizedFluidSummary(allFluids[fluidIndex - 1], language) : null,
    next: fluidIndex < allFluids.length - 1 ? localizedFluidSummary(allFluids[fluidIndex + 1], language) : null,
  };
}


function localizedSystemGuideSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    intro: guide.intro[language],
    color: guide.color,
    stageCount: guide.stages.length,
    equipmentCount: guide.equipment.length,
  };
}


function localizedSystemGuide(guide, language) {
  const guideIndex = systemGuides.indexOf(guide);
  return {
    ...localizedSystemGuideSummary(guide, language),
    facts: guide.facts.map((fact) => ({ label: fact.label[language], value: fact.value[language] })),
    stages: guide.stages.map((stage) => ({
      title: stage.title[language],
      text: stage.text[language],
      links: stage.links.map((id) => localizedTechnologyOutput(id, language)),
    })),
    tips: guide.tips.map((tip) => tip[language]),
    equipment: guide.equipment.map((id) => localizedTechnologyOutput(id, language)),
    previous: guideIndex > 0 ? localizedSystemGuideSummary(systemGuides[guideIndex - 1], language) : null,
    next: guideIndex < systemGuides.length - 1 ? localizedSystemGuideSummary(systemGuides[guideIndex + 1], language) : null,
  };
}


const achievementCategoryTitles = {
  quests: { ru: 'Квесты', en: 'Quests' },
  ages: { ru: 'Эпохи', en: 'Ages' },
  bosses: { ru: 'Боссы', en: 'Bosses' },
  factory: { ru: 'Фабрика', en: 'Factory' },
};

const achievementCategoryColors = {
  quests: [0.13, 0.55, 0.82, 1],
  ages: [0.58, 0.34, 0.78, 1],
  bosses: [0.82, 0.25, 0.18, 1],
  factory: [0.94, 0.58, 0.10, 1],
};


function localizedMenuText(value, language) {
  return menuTranslations.get(value)?.[language] || value;
}


function achievementRequirement(achievement, language) {
  const value = achievement.requirementValue;
  if (achievement.requirementType === 'quest_count') {
    return language === 'ru'
      ? `Завершить не менее ${value} основных или побочных заданий. Счётчик учитывает все задания, отмеченные выполненными в текущем профиле.`
      : `Complete at least ${value} main or side quests. The counter includes every quest marked complete in the current profile.`;
  }
  if (achievement.requirementType === 'age') {
    const ageInfo = questAgeText.find((entry) => entry.age === value);
    const title = ageInfo?.title[language] ?? String(value);
    return language === 'ru'
      ? `Завершить все обязательные задания эпохи ${value} «${title}». Необязательные задачи не мешают завершению главы.`
      : `Complete every required quest in Age ${value}, “${title}”. Optional tasks do not block chapter completion.`;
  }
  if (achievement.requirementType === 'boss') {
    const boss = bossesById.has(value) ? localizedBoss(bossesById.get(value), language) : null;
    return language === 'ru' ? `Победить босса «${boss?.title ?? value}».` : `Defeat the ${boss?.title ?? value} boss.`;
  }
  if (achievement.requirementType === 'boss_count') {
    return language === 'ru'
      ? `Победить ${value} разных боссов Верхнего мира — это вся текущая цепочка боссов.`
      : `Defeat ${value} different Overworld bosses—the entire current boss chain.`;
  }
  if (achievement.requirementType === 'machine_count') {
    return language === 'ru'
      ? `Одновременно иметь в мире не менее ${value} объектов из игровой группы factory_machine. Проверка считает размещённые машины фабрики.`
      : `Have at least ${value} nodes from the factory_machine group in the world at the same time. The check counts placed factory machines.`;
  }
  return language === 'ru'
    ? 'Создать работающую электросеть с генератором и минимум пятью потребителями. Сеть должна передавать энергию, а дефицит не должен превышать 0,01 EU.'
    : 'Build an active power network with a generator and at least five consumers. It must deliver power and its deficit may not exceed 0.01 EU.';
}


function achievementRelated(achievement, language) {
  if (achievement.requirementType === 'quest_count') {
    return [{ type: 'quests', id: 'quests', title: language === 'ru' ? 'Квестовая книга' : 'Quest book', url: `/${language}/quests` }];
  }
  if (achievement.requirementType === 'age') {
    const ageInfo = questAgeText.find((entry) => entry.age === achievement.requirementValue);
    return [{ type: 'age', id: String(achievement.requirementValue), title: ageInfo?.title[language] ?? String(achievement.requirementValue), url: `/${language}/quests/${achievement.requirementValue}` }];
  }
  if (achievement.requirementType === 'boss') {
    const boss = bossesById.get(achievement.requirementValue);
    const localized = boss ? localizedBoss(boss, language) : null;
    return [{ type: 'boss', id: achievement.requirementValue, title: localized?.title ?? achievement.requirementValue, url: `/${language}/bosses/${encodeURIComponent(achievement.requirementValue)}` }];
  }
  if (achievement.requirementType === 'boss_count') {
    return [{ type: 'bosses', id: 'bosses', title: language === 'ru' ? 'Цепочка боссов' : 'Boss chain', url: `/${language}/bosses` }];
  }
  if (achievement.requirementType === 'machine_count') {
    return [
      { type: 'machines', id: 'machines', title: language === 'ru' ? 'Каталог техники' : 'Machine catalog', url: `/${language}/machines` },
      { type: 'system', id: 'logistics', title: language === 'ru' ? 'Предметная логистика' : 'Item logistics', url: `/${language}/systems/logistics` },
    ];
  }
  return [{ type: 'system', id: 'power', title: language === 'ru' ? 'Энергосеть' : 'Power network', url: `/${language}/systems/power` }];
}


function localizedAchievementSummary(achievement, language) {
  const icon = itemsById.has(achievement.iconId)
    ? localizedTechnologyOutput(achievement.iconId, language)
    : { id: achievement.iconId, title: fallbackItemTitle(achievement.iconId), texture: null, color: achievementCategoryColors[achievement.category], exists: false, kind: 'component' };
  return {
    id: achievement.id,
    title: localizedMenuText(achievement.titleEn, language),
    description: localizedMenuText(achievement.descriptionEn, language),
    category: achievement.category,
    categoryTitle: achievementCategoryTitles[achievement.category][language],
    color: achievementCategoryColors[achievement.category],
    icon,
    requirementType: achievement.requirementType,
    requirementValue: achievement.requirementValue,
    requirement: achievementRequirement(achievement, language),
  };
}


function localizedAchievement(achievement, language) {
  const summary = localizedAchievementSummary(achievement, language);
  const achievementIndex = achievements.indexOf(achievement);
  return {
    ...summary,
    related: achievementRelated(achievement, language),
    storage: language === 'ru'
      ? 'После первого открытия ID достижения записывается в список achievements текущего профиля и сохраняется автоматически.'
      : 'After the first unlock, the achievement ID is added to the current profile’s achievements list and saved automatically.',
    check: language === 'ru'
      ? 'Условие сверяется автоматически при изменении прогресса квестов, победе над боссом или очередной проверке фабрики.'
      : 'The condition is checked automatically when quest progress changes, a boss is defeated, or the factory state is evaluated.',
    previous: achievementIndex > 0 ? localizedAchievementSummary(achievements[achievementIndex - 1], language) : null,
    next: achievementIndex < achievements.length - 1 ? localizedAchievementSummary(achievements[achievementIndex + 1], language) : null,
  };
}


const mechanicBonusTitles = {
  move_speed: { ru: 'Скорость передвижения', en: 'Movement speed' },
  attack_damage: { ru: 'Урон атак', en: 'Attack damage' },
  damage_reduction: { ru: 'Снижение урона', en: 'Damage reduction' },
  mining_power: { ru: 'Сила добычи', en: 'Mining power' },
  max_health: { ru: 'Максимальное здоровье', en: 'Maximum health' },
  dash_cooldown: { ru: 'Сокращение перезарядки рывка', en: 'Dash cooldown reduction' },
  loot_bonus: { ru: 'Дополнительная добыча с боссов', en: 'Bonus boss loot' },
};

const equipmentSlotTitles = {
  suit: { ru: 'Костюм', en: 'Suit' }, mask: { ru: 'Маска', en: 'Mask' }, amulet: { ru: 'Амулет', en: 'Amulet' },
  hands: { ru: 'Перчатки', en: 'Hands' }, feet: { ru: 'Ботинки', en: 'Feet' }, waist: { ru: 'Пояс', en: 'Waist' },
  head: { ru: 'Голова', en: 'Head' }, back: { ru: 'Плащ', en: 'Back' },
};

const mechanicSetTitles = {
  frontier: { ru: 'Комплект первопроходца', en: 'Frontier set' },
  ascendant: { ru: 'Комплект вознесения', en: 'Ascendant set' },
};


function localizedMechanicItem(id, language) {
  const item = itemsById.get(id);
  if (!item) return { id, title: fallbackItemTitle(id), description: '', texture: null, color: [0.35, 0.55, 0.68, 1], exists: false, url: `/${language}/items/${encodeURIComponent(id)}` };
  const localized = localizedItem(item, language);
  return { id, title: localized.title, description: localized.description, texture: localized.texture, color: localized.color, exists: true, url: `/${language}/items/${encodeURIComponent(id)}` };
}


function localizedMechanicBiome(biome, language) {
  const localized = localizedBiomeSummary(biome, language);
  return { id: biome.id, title: localized.title, image: localized.image, exists: true, url: `/${language}/worlds/overworld/biomes/${encodeURIComponent(biome.id)}` };
}


function formatMechanicNumber(value, language, maximumFractionDigits = 2) {
  return Number(value).toLocaleString(language, { maximumFractionDigits });
}


function formatMechanicDuration(seconds, language) {
  if (seconds >= 60) {
    const minutes = Math.floor(seconds / 60);
    const remainder = Math.round(seconds % 60);
    return language === 'ru' ? `${minutes} мин ${remainder} с` : `${minutes} min ${remainder} sec`;
  }
  return language === 'ru' ? `${formatMechanicNumber(seconds, language, 1)} с` : `${formatMechanicNumber(seconds, language, 1)} sec`;
}


function localizedBonusLines(values, language) {
  return Object.entries(values).map(([key, value]) => {
    const title = mechanicBonusTitles[key]?.[language] ?? key;
    const formatted = ['move_speed', 'attack_damage', 'damage_reduction', 'dash_cooldown', 'loot_bonus'].includes(key)
      ? `+${formatMechanicNumber(value * 100, language)}%`
      : `+${formatMechanicNumber(value, language)}`;
    return `${title}: ${formatted}`;
  });
}


function localizedMechanicSummary(mechanic, language) {
  const icon = localizedMechanicItem(mechanic.iconId, language);
  return {
    id: mechanic.id,
    title: mechanic.title[language],
    subtitle: mechanic.subtitle[language],
    description: mechanic.description[language],
    color: mechanic.color,
    icon,
  };
}


function mechanicHealthContent(language) {
  const maxHealth = playerConstants.MAX_HEALTH;
  const starvationFloor = playerConstants.STARVATION_MIN_HEALTH;
  const damageCap = 75;
  return {
    facts: [
      { label: language === 'ru' ? 'Базовое здоровье' : 'Base health', value: `${maxHealth} HP` },
      { label: language === 'ru' ? 'Предел снижения урона' : 'Damage reduction cap', value: `${damageCap}%` },
      { label: language === 'ru' ? 'Минимум при голодании' : 'Starvation floor', value: `${starvationFloor} HP` },
      { label: language === 'ru' ? 'Потеря предметов' : 'Item loss', value: language === 'ru' ? 'Нет' : 'None' },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Получение урона' : 'Taking damage',
        intro: language === 'ru' ? 'Боевой урон сначала уменьшается суммарной защитой экипировки. Неуязвимость во время рывка полностью отменяет попадание.' : 'Combat damage is reduced by total equipment protection first. Invulnerability during a dash cancels the hit entirely.',
        entries: [
          { title: language === 'ru' ? 'Формула' : 'Formula', text: language === 'ru' ? 'Полученный урон = исходный урон × (1 − снижение урона). Итоговое снижение ограничено 75%.' : 'Damage taken = incoming damage × (1 − damage reduction). Total reduction is capped at 75%.', value: 'damage × (1 − reduction)', links: [] },
          { title: language === 'ru' ? 'Голодание' : 'Starvation', text: language === 'ru' ? `Голод снимает здоровье отдельно и никогда не опускает его ниже ${starvationFloor} HP.` : `Starvation damages health separately and never reduces it below ${starvationFloor} HP.`, value: language === 'ru' ? 'Не смертельно' : 'Non-lethal', links: [] },
        ],
      },
      {
        title: language === 'ru' ? 'Смерть и возрождение' : 'Death and respawning',
        intro: language === 'ru' ? 'При нуле здоровья проигрывается анимация смерти, после чего персонаж возвращается на базовую точку появления.' : 'At zero health, the death animation plays and the character returns to the base spawn point.',
        entries: [
          { title: language === 'ru' ? 'Полное восстановление' : 'Full recovery', text: language === 'ru' ? 'Здоровье и сытость полностью восстанавливаются, а шкала воздействия обнуляется.' : 'Health and hunger are fully restored, while exposure is cleared.', value: language === 'ru' ? 'HP 100% · голод 100%' : 'HP 100% · hunger 100%', links: [] },
          { title: language === 'ru' ? 'Инвентарь сохраняется' : 'Inventory is retained', text: language === 'ru' ? 'Смерть не удаляет и не выбрасывает предметы. Персонаж просто телепортируется на базу.' : 'Death does not remove or drop items. The character simply teleports back to base.', value: language === 'ru' ? 'Без потерь' : 'No loss', links: [] },
        ],
      },
    ],
    related: ['heat_suit', 'savage_belt', 'insulated_suit', 'cryo_mantle'].map((id) => localizedMechanicItem(id, language)),
  };
}


function mechanicHungerContent(language) {
  const max = playerConstants.MAX_HUNGER;
  const drain = playerConstants.HUNGER_DRAIN;
  const low = playerConstants.HUNGER_LOW;
  const slow = playerConstants.HUNGER_SLOW_MULT;
  const starvation = playerConstants.STARVE_DAMAGE_PER_SEC;
  const foods = [...itemsById.values()].filter((item) => item.foodValue > 0).sort((left, right) => right.foodValue - left.foodValue);
  return {
    facts: [
      { label: language === 'ru' ? 'Максимум сытости' : 'Maximum hunger', value: String(max) },
      { label: language === 'ru' ? 'Расход в секунду' : 'Drain per second', value: formatMechanicNumber(drain, language) },
      { label: language === 'ru' ? 'Порог замедления' : 'Slow threshold', value: `< ${low}` },
      { label: language === 'ru' ? 'От полного до пустого' : 'Full to empty', value: formatMechanicDuration(max / drain, language) },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Пороги голода' : 'Hunger thresholds',
        intro: language === 'ru' ? 'Сытость расходуется постоянно, пока персонаж жив. Еда используется правой кнопкой мыши и не тратится при полной шкале.' : 'Hunger drains continuously while the character is alive. Food is used with the right mouse button and is not consumed when the meter is full.',
        entries: [
          { title: language === 'ru' ? 'Низкая сытость' : 'Low hunger', text: language === 'ru' ? `Ниже ${low} единиц скорость ходьбы и бега умножается на ${formatMechanicNumber(slow, language)}.` : `Below ${low}, walking and running speed are multiplied by ${formatMechanicNumber(slow, language)}.`, value: language === 'ru' ? `−${formatMechanicNumber((1 - slow) * 100, language)}% скорости` : `−${formatMechanicNumber((1 - slow) * 100, language)}% speed`, links: [] },
          { title: language === 'ru' ? 'Пустая шкала' : 'Empty meter', text: language === 'ru' ? `При нулевой сытости персонаж теряет ${starvation} HP в секунду, но голодание не может убить.` : `At zero hunger, the character loses ${starvation} HP per second, but starvation cannot kill.`, value: `${starvation} HP/s`, links: [] },
        ],
      },
      {
        title: language === 'ru' ? `Еда · ${foods.length}` : `Food · ${foods.length}`,
        intro: language === 'ru' ? 'Значение показывает, сколько единиц сытости восстанавливает одна порция.' : 'The value is the amount of hunger restored by one serving.',
        entries: foods.map((food) => {
          const item = localizedMechanicItem(food.id, language);
          return { title: item.title, text: item.description, value: `+${food.foodValue}`, links: [item] };
        }),
      },
    ],
    related: foods.slice(0, 4).map((food) => localizedMechanicItem(food.id, language)),
  };
}


function mechanicHazardContent(language) {
  const max = playerConstants.EXPOSURE_MAX;
  const recover = playerConstants.EXPOSURE_RECOVER;
  const reset = playerConstants.EXPOSURE_EJECT_RESET;
  const hazardousBiomes = biomeDefinitions.filter((biome) => biome.hazard);
  return {
    facts: [
      { label: language === 'ru' ? 'Максимум воздействия' : 'Maximum exposure', value: String(max) },
      { label: language === 'ru' ? 'Восстановление' : 'Recovery', value: `${recover}/s` },
      { label: language === 'ru' ? 'После выброса' : 'After ejection', value: String(reset) },
      { label: language === 'ru' ? 'Опасных биомов' : 'Hazardous biomes', value: String(hazardousBiomes.length) },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Как работает воздействие' : 'How exposure works',
        intro: language === 'ru' ? 'В опасном биоме без правильного предмета шкала растёт. В безопасной зоне или с защитой она убывает; сам защитный предмет должен быть экипирован, а не просто лежать в инвентаре.' : 'Without the matching item, exposure rises in a hazardous biome. It falls in a safe area or while protected; the protection item must be equipped, not merely carried.',
        entries: [
          { title: language === 'ru' ? 'Выброс в безопасность' : 'Ejection to safety', text: language === 'ru' ? `При ${max} единицах персонаж возвращается на последнюю безопасную клетку. Смерти и потери предметов нет, но шкала остаётся на ${reset}.` : `At ${max}, the character returns to the last safe tile. There is no death or item loss, but exposure remains at ${reset}.`, value: `${max} → ${reset}`, links: [] },
          { title: language === 'ru' ? 'Сброс шкалы' : 'Clearing the meter', text: language === 'ru' ? `Восстановление идёт со скоростью ${recover} единицы в секунду. Полная шкала очищается примерно за ${formatMechanicDuration(max / recover, language)}.` : `Recovery runs at ${recover} points per second. A full meter clears in about ${formatMechanicDuration(max / recover, language)}.`, value: formatMechanicDuration(max / recover, language), links: [] },
        ],
      },
      {
        title: language === 'ru' ? `Биомы и защита · ${hazardousBiomes.length}` : `Biomes and protection · ${hazardousBiomes.length}`,
        intro: language === 'ru' ? 'Время до выброса рассчитано от пустой шкалы без защиты.' : 'Time to ejection is calculated from an empty meter without protection.',
        entries: hazardousBiomes.map((biome) => {
          const localized = localizedBiomeSummary(biome, language);
          const protection = localizedMechanicItem(biome.accessItem, language);
          return {
            title: localized.title,
            text: language === 'ru' ? `${localized.hazardTitle}: ${biome.hazardRate} ед./с. Требуемая защита — ${protection.title}.` : `${localized.hazardTitle}: ${biome.hazardRate} points/sec. Required protection: ${protection.title}.`,
            value: language === 'ru' ? `≈ ${formatMechanicDuration(max / biome.hazardRate, language)} до выброса` : `≈ ${formatMechanicDuration(max / biome.hazardRate, language)} to ejection`,
            links: [localizedMechanicBiome(biome, language), protection],
          };
        }),
      },
    ],
    related: hazardousBiomes.map((biome) => localizedMechanicItem(biome.accessItem, language)),
  };
}


function mechanicEquipmentContent(language) {
  const equipment = equipmentMechanics.bonuses.map((entry) => {
    const source = itemsById.get(entry.id);
    const item = localizedMechanicItem(entry.id, language);
    const slot = source?.equipSlot || (entry.id === 'gas_mask' ? 'mask' : 'suit');
    return { title: item.title, text: localizedBonusLines(entry.values, language).join(' · '), value: equipmentSlotTitles[slot]?.[language] ?? slot, links: [item] };
  });
  const setEntries = equipmentMechanics.sets.flatMap((set) => {
    const setTitle = mechanicSetTitles[set.id]?.[language] ?? set.titleEn;
    const links = set.items.map((id) => localizedMechanicItem(id, language));
    return set.thresholds.map((threshold) => ({
      title: `${setTitle} · ${threshold.count}/${set.items.length}`,
      text: localizedBonusLines(threshold.values, language).join(' · '),
      value: language === 'ru' ? `${threshold.count} предмета` : `${threshold.count} pieces`,
      links,
    }));
  });
  return {
    facts: [
      { label: language === 'ru' ? 'Слотов экипировки' : 'Equipment slots', value: '8' },
      { label: language === 'ru' ? 'Предметов с бонусами' : 'Items with bonuses', value: String(equipment.length) },
      { label: language === 'ru' ? 'Комплектов' : 'Sets', value: String(equipmentMechanics.sets.length) },
      { label: language === 'ru' ? 'Бонусы складываются' : 'Bonuses stack', value: language === 'ru' ? 'Да' : 'Yes' },
    ],
    sections: [
      { title: language === 'ru' ? 'Предметы и слоты' : 'Items and slots', intro: language === 'ru' ? 'Предмет можно поместить только в слот, совпадающий с его типом. Индивидуальные бонусы всех надетых предметов суммируются.' : 'An item can only enter a slot matching its declared type. Individual bonuses from all equipped items are added together.', entries: equipment },
      { title: language === 'ru' ? 'Бонусы комплектов' : 'Set bonuses', intro: language === 'ru' ? 'Каждый достигнутый порог комплекта добавляется поверх индивидуальных эффектов и более раннего порога.' : 'Every reached set threshold is added on top of individual effects and earlier thresholds.', entries: setEntries },
    ],
    related: equipment.map((entry) => entry.links[0]),
  };
}


function mechanicCombatContent(language) {
  const weaponConfig = {
    sword: { multiplier: playerConstants.ATTACK_DAMAGE_PER_POWER, reach: playerConstants.ATTACK_REACH, cooldown: 1, label: { ru: 'Меч', en: 'Sword' } },
    spear: { multiplier: 7.5, reach: playerConstants.SPEAR_REACH, cooldown: 1.15, label: { ru: 'Копьё', en: 'Spear' } },
    hammer: { multiplier: 11, reach: playerConstants.HAMMER_REACH, cooldown: 1.55, label: { ru: 'Молот', en: 'Hammer' } },
    wand: { multiplier: 7, reach: null, cooldown: 1.25, label: { ru: 'Жезл', en: 'Wand' } },
  };
  const weapons = [...itemsById.values()].filter((item) => weaponConfig[item.toolType]).sort((left, right) => left.power - right.power);
  return {
    facts: [
      { label: language === 'ru' ? 'Скорость ходьбы' : 'Walk speed', value: String(playerConstants.WALK_SPEED ?? 100) },
      { label: language === 'ru' ? 'Скорость бега' : 'Run speed', value: String(playerConstants.RUN_SPEED ?? 2000) },
      { label: language === 'ru' ? 'Скорость рывка' : 'Dash speed', value: String(playerConstants.DASH_SPEED) },
      { label: language === 'ru' ? 'Перезарядка рывка' : 'Dash cooldown', value: `${formatMechanicNumber(playerConstants.DASH_COOLDOWN, language)} ${language === 'ru' ? 'с' : 'sec'}` },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Передвижение и рывок' : 'Movement and dashing',
        intro: language === 'ru' ? 'Рывок идёт в направлении движения или взгляда, если персонаж стоит. Во время короткого окна персонаж не получает боевой урон.' : 'A dash follows movement input, or facing direction while stationary. The player ignores combat damage during its short invulnerability window.',
        entries: [
          { title: language === 'ru' ? 'Рывок' : 'Dash', text: language === 'ru' ? `Длительность ${formatMechanicNumber(playerConstants.DASH_DURATION, language)} с, скорость ${playerConstants.DASH_SPEED}, базовая перезарядка ${formatMechanicNumber(playerConstants.DASH_COOLDOWN, language)} с.` : `Duration ${formatMechanicNumber(playerConstants.DASH_DURATION, language)} sec, speed ${playerConstants.DASH_SPEED}, base cooldown ${formatMechanicNumber(playerConstants.DASH_COOLDOWN, language)} sec.`, value: language === 'ru' ? `${formatMechanicNumber(playerConstants.DASH_INVULNERABILITY, language)} с неуязвимости` : `${formatMechanicNumber(playerConstants.DASH_INVULNERABILITY, language)} sec invulnerable`, links: [localizedMechanicItem('void_respirator', language)] },
          { title: language === 'ru' ? 'Мелководье болота' : 'Swamp shallows', text: language === 'ru' ? `Скорость на болотной воде умножается на ${formatMechanicNumber(playerConstants.SWAMP_SPEED_MULT, language)}. Эффект складывается с голодом и бонусами экипировки.` : `Speed in swamp water is multiplied by ${formatMechanicNumber(playerConstants.SWAMP_SPEED_MULT, language)}. This combines with hunger and equipment modifiers.`, value: language === 'ru' ? `−${formatMechanicNumber((1 - playerConstants.SWAMP_SPEED_MULT) * 100, language)}%` : `−${formatMechanicNumber((1 - playerConstants.SWAMP_SPEED_MULT) * 100, language)}%`, links: [localizedMechanicBiome(biomeDefinitions.find((biome) => biome.id === 'swamp'), language)] },
        ],
      },
      {
        title: language === 'ru' ? `Оружие · ${weapons.length}` : `Weapons · ${weapons.length}`,
        intro: language === 'ru' ? 'Базовый урон равен силе предмета, умноженной на коэффициент класса. Бонус атаки экипировки применяется после этого расчёта.' : 'Base damage is item power multiplied by the class coefficient. Equipment attack bonuses apply after this calculation.',
        entries: weapons.map((weapon) => {
          const config = weaponConfig[weapon.toolType];
          const item = localizedMechanicItem(weapon.id, language);
          const damage = weapon.power * config.multiplier;
          const reach = config.reach ? (language === 'ru' ? `дальность ${config.reach}` : `reach ${config.reach}`) : (language === 'ru' ? 'дальний снаряд' : 'ranged projectile');
          return { title: item.title, text: `${config.label[language]} · ${language === 'ru' ? 'сила' : 'power'} ${weapon.power} · ${reach} · ${language === 'ru' ? 'множитель задержки' : 'cooldown multiplier'} ×${config.cooldown}`, value: language === 'ru' ? `${formatMechanicNumber(damage, language)} базового урона` : `${formatMechanicNumber(damage, language)} base damage`, links: [item] };
        }),
      },
    ],
    related: weapons.map((weapon) => localizedMechanicItem(weapon.id, language)),
  };
}


function localizedMechanic(mechanic, language) {
  const summary = localizedMechanicSummary(mechanic, language);
  const content = {
    'health-respawn': mechanicHealthContent,
    'hunger-food': mechanicHungerContent,
    'environmental-hazards': mechanicHazardContent,
    'equipment-sets': mechanicEquipmentContent,
    'combat-movement': mechanicCombatContent,
  }[mechanic.id](language);
  const index = mechanicDefinitions.indexOf(mechanic);
  return {
    ...summary,
    ...content,
    previous: index > 0 ? localizedMechanicSummary(mechanicDefinitions[index - 1], language) : null,
    next: index < mechanicDefinitions.length - 1 ? localizedMechanicSummary(mechanicDefinitions[index + 1], language) : null,
  };
}


function localizedGatheringSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedGatheringMachine(id, language) {
  const machine = machinesById.get(id);
  if (!machine) return localizedMechanicItem(id, language);
  const localized = localizedMachine(machine, language);
  return { id, title: localized.title, description: localized.description, texture: localized.texture, color: localized.color, exists: true, url: `/${language}/machines/${encodeURIComponent(id)}` };
}


function localizedGatheringFluid(id, language) {
  const fluid = fluidsById.get(id);
  if (!fluid) return { id, title: fallbackItemTitle(id), exists: false, url: `/${language}/fluids/${encodeURIComponent(id)}` };
  const localized = localizedFluidSummary(fluid, language);
  return { id, title: localized.title, description: localized.description, color: localized.color, exists: true, url: `/${language}/fluids/${encodeURIComponent(id)}` };
}


function biomeByResource(resource) {
  return biomeDefinitions.find((biome) => biome.resource === resource) ?? null;
}


function gatheringManualMiningContent(language) {
  const pickaxes = [...itemsById.values()].filter((item) => item.toolType === 'pickaxe').sort((left, right) => left.power - right.power);
  return {
    facts: [
      { label: language === 'ru' ? 'Базовый урон удара' : 'Base swing damage', value: String(miningMechanics.damageBase) },
      { label: language === 'ru' ? 'За уровень силы' : 'Per power level', value: `+${miningMechanics.damagePerPower}` },
      { label: language === 'ru' ? 'Неверный инструмент' : 'Wrong tool', value: `×${miningMechanics.wrongToolMultiplier}` },
      { label: language === 'ru' ? 'Восстановление прогресса' : 'Progress recovery', value: `${miningMechanics.regenDelay} ${language === 'ru' ? 'с' : 'sec'}` },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Правила добычи' : 'Mining rules',
        intro: language === 'ru' ? 'Первый удар происходит сразу, затем удары повторяются по ритму уровня инструмента. Удерживайте левую кнопку мыши на ресурсе.' : 'The first swing lands immediately, then attacks repeat at the tool tier rhythm. Hold the left mouse button over a resource.',
        entries: [
          { title: language === 'ru' ? 'Урон за удар' : 'Damage per swing', text: language === 'ru' ? `Урон = ${miningMechanics.damageBase} + ${miningMechanics.damagePerPower} × max(сила, 1). Неподходящий тип инструмента наносит половину.` : `Damage = ${miningMechanics.damageBase} + ${miningMechanics.damagePerPower} × max(power, 1). A mismatched tool type deals half damage.`, value: `${miningMechanics.damageBase} + ${miningMechanics.damagePerPower} × power`, links: [] },
          { title: language === 'ru' ? 'Порог уровня' : 'Power gate', text: language === 'ru' ? 'Если сила ниже требования залежи, анимация проигрывается, но прочность не уменьшается. Основную залежь и её ядро может добывать только бур.' : 'Below a deposit’s required power, the swing animation plays but removes no health. Only a drill can extract the main deposit and its core.', value: language === 'ru' ? 'Сила ≥ уровень руды' : 'Power ≥ ore level', links: [] },
          { title: language === 'ru' ? 'Частично разбитая клетка' : 'Partially mined tile', text: language === 'ru' ? `Повреждение клетки хранится ${miningMechanics.regenDelay} секунд. Если вернуться позже, её шкала уже полностью восстановлена.` : `Tile damage is remembered for ${miningMechanics.regenDelay} seconds. Return later and its health bar has fully recovered.`, value: `${miningMechanics.regenDelay} ${language === 'ru' ? 'с' : 'sec'}`, links: [] },
        ],
      },
      {
        title: language === 'ru' ? `Кирки · ${pickaxes.length}` : `Pickaxes · ${pickaxes.length}`,
        intro: language === 'ru' ? 'Перчатки первопроходца добавляют один уровень силы добычи поверх силы удерживаемого инструмента.' : 'Frontier gloves add one mining power level on top of the held tool’s power.',
        entries: pickaxes.map((pickaxe) => {
          const item = localizedMechanicItem(pickaxe.id, language);
          const power = Math.max(pickaxe.power ?? 1, 1);
          const damage = miningMechanics.damageBase + miningMechanics.damagePerPower * power;
          const interval = miningMechanics.swingIntervals[Math.min(power, miningMechanics.swingIntervals.length) - 1] ?? 0.55;
          return { title: item.title, text: language === 'ru' ? `Сила ${power} · ${damage} урона за удар · интервал ${formatMechanicNumber(interval, language)} с.` : `Power ${power} · ${damage} damage per swing · ${formatMechanicNumber(interval, language)} sec interval.`, value: language === 'ru' ? `≈ ${formatMechanicNumber(damage / interval, language)} урона/с` : `≈ ${formatMechanicNumber(damage / interval, language)} damage/sec`, links: [item] };
        }),
      },
    ],
    related: [...pickaxes.map((item) => localizedMechanicItem(item.id, language)), localizedMechanicItem('thermal_gloves', language)],
  };
}


function gatheringOreContent(language) {
  const oreAmount = (count) => language === 'ru' ? `${count} ед. ресурса` : `${count} resource units`;
  const frequencyTitle = (weight) => {
    if (weight >= 80) return language === 'ru' ? 'Очень часто' : 'Very common';
    if (weight >= 45) return language === 'ru' ? 'Часто' : 'Common';
    if (weight >= 20) return language === 'ru' ? 'Обычно' : 'Uncommon';
    if (weight >= 8) return language === 'ru' ? 'Редко' : 'Rare';
    return language === 'ru' ? 'Очень редко' : 'Very rare';
  };
  return {
    facts: [
      { label: language === 'ru' ? 'Видов руды' : 'Ore types', value: String(oreMechanics.length) },
      { label: language === 'ru' ? 'Размер ячейки генерации' : 'Generation cell size', value: `${miningMechanics.depositCellSize}×${miningMechanics.depositCellSize}` },
      { label: language === 'ru' ? 'Базовый шанс жилы' : 'Base vein chance', value: `${formatMechanicNumber(miningMechanics.depositSpawnChance * 100, language)}%` },
      { label: language === 'ru' ? 'Диаметр жилы' : 'Vein footprint', value: '9×9' },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Устройство жилы' : 'Vein structure',
        intro: language === 'ru' ? 'Жила образует круг радиусом четыре клетки. Любую рудную клетку можно бесконечно добывать киркой, а в центре находится скважина для установки бура. Четыре соседние со скважиной клетки оставляются свободными для подключения машин и конвейеров.' : 'A vein forms a radius-four disc. Every ore tile can be mined forever with a pickaxe, while the center is a borehole for placing a drill. The four cells next to it stay clear for machines and conveyors.',
        entries: [
          { title: language === 'ru' ? 'Ручная добыча' : 'Manual mining', text: language === 'ru' ? 'Кирка нужного уровня уменьшает прочность выбранной клетки. Когда шкала опустеет, игрок получает руду, а клетка сразу восстанавливается и остаётся на месте.' : 'A pickaxe of the required level reduces the selected tile’s durability. When the bar empties, the player receives ore and the tile immediately resets without disappearing.', value: language === 'ru' ? 'Бесконечный источник' : 'Infinite source', links: [] },
          { title: language === 'ru' ? 'Скважина для бура' : 'Drill borehole', text: language === 'ru' ? 'Центральную клетку нельзя добывать киркой. На неё устанавливается бур, который автоматически извлекает руду и может передавать её дальше по конвейеру.' : 'The center tile cannot be mined with a pickaxe. A drill placed over it extracts ore automatically and can pass it onward to a conveyor.', value: language === 'ru' ? 'Центр каждой жилы' : 'Center of every vein', links: [localizedGatheringMachine('conveyor', language)] },
        ],
      },
      {
        title: language === 'ru' ? `Каталог руд · ${oreMechanics.length}` : `Ore catalog · ${oreMechanics.length}`,
        intro: language === 'ru' ? 'Частота показывает, насколько легко встретить жилу среди подходящих месторождений. Сложные биомы наследуют руды обычного биома в том же направлении.' : 'Frequency shows how easy a vein is to encounter among suitable deposits. Hard biomes inherit the ore pool of the normal biome in the same direction.',
        entries: oreMechanics.map((ore) => {
          const item = localizedMechanicItem(ore.itemId, language);
          const biomeLinks = ore.biomes.map((resource) => biomeByResource(resource)).filter(Boolean).map((biome) => localizedMechanicBiome(biome, language));
          return {
            title: item.title,
            icon: item,
            value: language === 'ru' ? `Встречается: ${frequencyTitle(ore.weight).toLocaleLowerCase(language)}` : `Frequency: ${frequencyTitle(ore.weight).toLocaleLowerCase(language)}`,
            stats: [
              { label: language === 'ru' ? 'Нужная кирка' : 'Required pickaxe', value: language === 'ru' ? `Уровень ${ore.level}` : `Level ${ore.level}` },
              { label: language === 'ru' ? 'Прочность жилы' : 'Vein durability', value: language === 'ru' ? `${ore.miningHealth} ед.` : `${ore.miningHealth} points` },
              { label: language === 'ru' ? 'Ручная добыча' : 'Manual mining', value: language === 'ru' ? `${oreAmount(ore.yieldAmount)} за полную шкалу` : `${oreAmount(ore.yieldAmount)} per full bar` },
              { label: language === 'ru' ? 'Автоматическая добыча' : 'Automated extraction', value: language === 'ru' ? `${oreAmount(ore.yieldAmount)} за операцию бура` : `${oreAmount(ore.yieldAmount)} per drill operation` },
            ],
            locationLabel: language === 'ru' ? 'Где найти' : 'Found in',
            links: biomeLinks,
          };
        }),
      },
    ],
    related: oreMechanics.map((ore) => localizedMechanicItem(ore.itemId, language)),
  };
}


function gatheringDrillContent(language) {
  const drills = drillMechanics.tiers.map((tier) => ({ ...tier, machine: localizedGatheringMachine(tier.id, language) }));
  return {
    facts: [
      { label: language === 'ru' ? 'Уровней буров' : 'Drill tiers', value: String(drills.length) },
      { label: language === 'ru' ? 'Размер' : 'Footprint', value: '3×3' },
      { label: language === 'ru' ? 'Выходных слотов' : 'Output slots', value: String(drillMechanics.bufferSlots) },
      { label: language === 'ru' ? 'Буфер энергии' : 'Power buffer', value: `${drillMechanics.powerBufferSeconds} ${language === 'ru' ? 'с' : 'sec'}` },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Установка и выдача' : 'Placement and output',
        intro: language === 'ru' ? 'Бур ставится только так, чтобы центр блока 3×3 совпал с ядром жилы. Обычные буры выдают руду со стороны направления и принимают предметы с противоположной стороны.' : 'A drill can only be placed with the center of its 3×3 footprint over a vein core. Standard drills eject ore from their facing side and accept belt items from the opposite side.',
        entries: [
          { title: language === 'ru' ? 'Обратное давление' : 'Back-pressure', text: language === 'ru' ? 'Если внутренние выходные слоты или примыкающее хранилище заполнены, бур приостанавливается и не тратит энергию.' : 'When the internal output slots or attached storage are full, the drill pauses and consumes no power.', value: language === 'ru' ? 'Без потерь руды' : 'No ore loss', links: [localizedGatheringMachine('conveyor', language), localizedGatheringMachine('chest_t1', language)] },
          { title: language === 'ru' ? 'Примитивный бур' : 'Primitive drill', text: language === 'ru' ? 'Не имеет выходной стороны и складывает руду во внутреннее хранилище, которое нужно открывать и очищать вручную.' : 'It has no output side and stores ore in an internal inventory that must be opened and emptied manually.', value: language === 'ru' ? 'Энергия не нужна' : 'No power required', links: [localizedGatheringMachine('primitive_drill', language)] },
        ],
      },
      {
        title: language === 'ru' ? `Уровни буров · ${drills.length}` : `Drill tiers · ${drills.length}`,
        intro: language === 'ru' ? 'Сила бура должна быть не ниже уровня руды. Энергия расходуется только во время активной добычи.' : 'Drill power must meet the ore’s required level. Energy is consumed only while actively mining.',
        entries: drills.map((drill) => ({ title: drill.machine.title, text: language === 'ru' ? `Сила ${drill.power} · одна добыча занимает ${formatMechanicNumber(drill.interval, language)} с · до ${formatMechanicNumber(60 / drill.interval, language)} добыч/мин${drill.euPerSecond ? ` · ${drill.euPerSecond} EU/с` : ' · без энергии'}.` : `Power ${drill.power} · one extraction takes ${formatMechanicNumber(drill.interval, language)} sec · up to ${formatMechanicNumber(60 / drill.interval, language)} extractions/min${drill.euPerSecond ? ` · ${drill.euPerSecond} EU/sec` : ' · no power'}.`, value: drill.noOutput ? (language === 'ru' ? 'Ручной внутренний буфер' : 'Manual internal buffer') : (language === 'ru' ? 'Автоматическая выдача' : 'Automatic output'), links: [drill.machine] })),
      },
    ],
    related: drills.map((drill) => drill.machine),
  };
}


function gatheringFarmingContent(language) {
  const hoe = localizedMechanicItem('hoe', language);
  return {
    facts: [
      { label: language === 'ru' ? 'Культур' : 'Crops', value: String(cropMechanics.length) },
      { label: language === 'ru' ? 'Стадий роста' : 'Growth stages', value: String(Math.max(...cropMechanics.map((crop) => crop.stages))) },
      { label: language === 'ru' ? 'Семена' : 'Seeds', value: language === 'ru' ? 'Сам овощ' : 'The vegetable itself' },
      { label: language === 'ru' ? 'Повторное использование грядки' : 'Plot reuse', value: language === 'ru' ? 'Да' : 'Yes' },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Цикл фермерства' : 'Farming loop',
        intro: language === 'ru' ? 'Работать можно только в радиусе строительства. Грядка должна находиться на свободной сухой клетке.' : 'Farming actions work only inside the build radius. A plot must be created on a clear, dry tile.',
        entries: [
          { title: language === 'ru' ? '1. Подготовьте землю' : '1. Prepare the soil', text: language === 'ru' ? 'Возьмите мотыгу и нажмите правую кнопку мыши на свободной сухой земле.' : 'Hold a hoe and right-click a clear, dry ground tile.', value: language === 'ru' ? 'ПКМ с мотыгой' : 'RMB with hoe', links: [hoe] },
          { title: language === 'ru' ? '2. Посадите овощ' : '2. Plant a vegetable', text: language === 'ru' ? 'Правой кнопкой используйте сам овощ на пустой грядке. Одна единица предмета расходуется.' : 'Right-click an empty plot with the vegetable itself. One item is consumed.', value: language === 'ru' ? '−1 предмет' : '−1 item', links: [] },
          { title: language === 'ru' ? '3. Соберите урожай' : '3. Harvest', text: language === 'ru' ? 'После последней стадии нажмите левую кнопку. Грядка станет пустой, но останется вспаханной для следующей посадки.' : 'After the final growth stage, left-click to harvest. The plot becomes empty but stays tilled for replanting.', value: language === 'ru' ? 'ЛКМ по зрелой культуре' : 'LMB on mature crop', links: [] },
        ],
      },
      {
        title: language === 'ru' ? `Культуры · ${cropMechanics.length}` : `Crops · ${cropMechanics.length}`,
        intro: language === 'ru' ? 'Время указано в игровых минутах монотонного возраста мира и сохраняется вместе с участком.' : 'Time is measured in monotonic in-game world minutes and persists with the plot.',
        entries: cropMechanics.map((crop) => {
          const item = localizedMechanicItem(crop.itemId, language);
          const food = itemsById.get(crop.itemId)?.foodValue ?? 0;
          return { title: item.title, text: language === 'ru' ? `${crop.stages} стадии · ${formatMechanicNumber(crop.minutesPerStage, language)} мин на стадию · урожай ${crop.yieldMin}–${crop.yieldMax} · сытость +${food}.` : `${crop.stages} stages · ${formatMechanicNumber(crop.minutesPerStage, language)} min per stage · yield ${crop.yieldMin}–${crop.yieldMax} · hunger +${food}.`, value: language === 'ru' ? `${formatMechanicNumber(crop.totalMinutes, language)} игровых минут` : `${formatMechanicNumber(crop.totalMinutes, language)} in-game minutes`, links: [item] };
        }),
      },
    ],
    related: [hoe, ...cropMechanics.map((crop) => localizedMechanicItem(crop.itemId, language))],
  };
}


function gatheringForageContent(language) {
  return {
    facts: [
      { label: language === 'ru' ? 'Видов объектов' : 'Wild object types', value: String(forageMechanics.length) },
      { label: language === 'ru' ? 'Водных ресурсов' : 'Water-only resources', value: String(forageMechanics.filter((entry) => entry.water).length) },
      { label: language === 'ru' ? 'Минимальная прочность' : 'Minimum health', value: String(Math.min(...forageMechanics.map((entry) => entry.health))) },
      { label: language === 'ru' ? 'Максимальный сбор' : 'Maximum yield', value: String(Math.max(...forageMechanics.map((entry) => entry.amount))) },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Как собирать' : 'How gathering works',
        intro: language === 'ru' ? 'Дикорастущий объект — конечный ресурс. Его можно разбить любым инструментом или рукой; после полного истощения он исчезает из мира.' : 'A wild object is a finite resource. It can be broken with any tool or bare hands, and disappears after its full yield is collected.',
        entries: [
          { title: language === 'ru' ? 'Распределённый урожай' : 'Distributed yield', text: language === 'ru' ? 'Ресурс выдаётся постепенно по мере снижения прочности. Последний удар гарантированно выдаёт весь оставшийся объём.' : 'Resources are awarded gradually as health drops. The final hit guarantees all remaining yield.', value: language === 'ru' ? 'Без потери остатка' : 'No remainder lost', links: [] },
          { title: language === 'ru' ? 'Вероятность появления' : 'Spawn chance', text: language === 'ru' ? 'Шанс применяется к подходящим клеткам биома и дополнительно ограничивается минимальным расстоянием между объектами.' : 'The chance is evaluated on eligible biome tiles and further constrained by the minimum spacing between objects.', value: language === 'ru' ? 'Зависит от биома' : 'Biome-dependent', links: [] },
        ],
      },
      {
        title: language === 'ru' ? `Дикорастущие ресурсы · ${forageMechanics.length}` : `Wild resources · ${forageMechanics.length}`,
        intro: language === 'ru' ? 'Процент — вероятность появления на подходящей клетке до применения общего множителя растительности мира.' : 'Percentages are per eligible tile before the world vegetation multiplier is applied.',
        entries: forageMechanics.map((entry) => {
          const item = localizedMechanicItem(entry.itemId, language);
          const biomeLinks = Object.keys(entry.chances).map((resource) => biomeByResource(resource)).filter(Boolean).map((biome) => localizedMechanicBiome(biome, language));
          const chances = Object.entries(entry.chances).map(([resource, chance]) => {
            const biome = biomeByResource(resource);
            const title = biome ? biome.title[language] : resource;
            return `${title} ${formatMechanicNumber(chance * 100, language, 2)}%`;
          }).join(' · ');
          return { title: item.title, text: language === 'ru' ? `Прочность ${entry.health} · общий сбор ${entry.amount} · расстояние ${entry.spacing}${entry.water ? ' · только вода' : ' · суша'}. ${chances}` : `Health ${entry.health} · total yield ${entry.amount} · spacing ${entry.spacing}${entry.water ? ' · water only' : ' · dry land'}. ${chances}`, value: entry.water ? (language === 'ru' ? 'Водное растение' : 'Aquatic plant') : (language === 'ru' ? 'Наземный объект' : 'Land object'), links: [item, ...biomeLinks] };
        }),
      },
    ],
    related: [...new Map(forageMechanics.map((entry) => { const item = localizedMechanicItem(entry.itemId, language); return [item.url, item]; })).values()],
  };
}


function gatheringFluidDepositContent(language) {
  const oil = localizedGatheringFluid('crude_oil', language);
  const lava = localizedGatheringFluid('lava', language);
  const pump = localizedGatheringMachine('oil_pump', language);
  const snow = localizedMechanicBiome(biomeDefinitions.find((biome) => biome.id === 'snow'), language);
  const desert = localizedMechanicBiome(biomeDefinitions.find((biome) => biome.id === 'desert'), language);
  return {
    facts: [
      { label: language === 'ru' ? 'Объём залежи' : 'Deposit capacity', value: `${miningMechanics.fluidCapacity} L` },
      { label: language === 'ru' ? 'Размер ячейки' : 'Generation cell', value: `${miningMechanics.fluidCellSize}×${miningMechanics.fluidCellSize}` },
      { label: language === 'ru' ? 'Клеток в полном поле' : 'Tiles in a full field', value: String(miningMechanics.fluidShapeTiles) },
      { label: language === 'ru' ? 'Машина добычи' : 'Extraction machine', value: pump.title },
    ],
    sections: [
      {
        title: language === 'ru' ? 'Устройство поля' : 'Field structure',
        intro: language === 'ru' ? 'Нефть и лава используют круглое поле радиусом четыре клетки. Общий объём хранится в центральной клетке; край поля обрезается границей требуемого биома и водой.' : 'Oil and lava use a radius-four circular field. Total capacity is stored at the center tile; the pool is clipped by the required biome boundary and water.',
        entries: [
          { title: language === 'ru' ? 'Откачка' : 'Pumping', text: language === 'ru' ? 'Нефтекачка должна стоять на клетке жидкостного поля. За один запрос можно получить не больше оставшегося объёма, после чего состояние сохраняется.' : 'An oil pump must stand on a fluid-field tile. Each request returns no more than the remaining capacity, and the new amount is persisted.', value: `${miningMechanics.fluidCapacity} L max`, links: [pump] },
          { title: language === 'ru' ? 'Истощение' : 'Depletion', text: language === 'ru' ? 'По мере откачки визуальный размер поля уменьшается. При нулевом остатке дальнейшая добыча прекращается.' : 'The visible field shrinks as fluid is extracted. Production stops when the remaining capacity reaches zero.', value: language === 'ru' ? 'Конечный ресурс' : 'Finite resource', links: [] },
        ],
      },
      {
        title: language === 'ru' ? 'Типы залежей' : 'Deposit types',
        intro: language === 'ru' ? 'Каждая ячейка генерации делает независимую попытку создать поле; центр и все клетки должны оставаться внутри заданного биома.' : 'Each generation cell independently rolls for a field; its center and tiles must remain inside the required biome.',
        entries: [
          { title: oil.title, text: language === 'ru' ? `Появляется только в снежных землях. Шанс поля на ячейку — ${miningMechanics.oilSpawnChance * 100}%.` : `Spawns only in Snowlands. Field chance per cell: ${miningMechanics.oilSpawnChance * 100}%.`, value: `${miningMechanics.fluidCapacity} L`, links: [oil, snow] },
          { title: lava.title, text: language === 'ru' ? `Появляется только в пустыне. Шанс поля на ячейку — ${miningMechanics.lavaSpawnChance * 100}%.` : `Spawns only in the Desert. Field chance per cell: ${miningMechanics.lavaSpawnChance * 100}%.`, value: `${miningMechanics.fluidCapacity} L`, links: [lava, desert] },
        ],
      },
    ],
    related: [pump, oil, lava, snow, desert],
  };
}


function localizedGathering(guide, language) {
  const summary = localizedGatheringSummary(guide, language);
  const content = {
    'manual-mining': gatheringManualMiningContent,
    'ore-deposits': gatheringOreContent,
    'automated-drilling': gatheringDrillContent,
    farming: gatheringFarmingContent,
    foraging: gatheringForageContent,
    'fluid-deposits': gatheringFluidDepositContent,
  }[guide.id](language);
  const index = gatheringDefinitions.indexOf(guide);
  return {
    ...summary,
    ...content,
    previous: index > 0 ? localizedGatheringSummary(gatheringDefinitions[index - 1], language) : null,
    next: index < gatheringDefinitions.length - 1 ? localizedGatheringSummary(gatheringDefinitions[index + 1], language) : null,
  };
}


function localizedInterfaceSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedInterfacePageLink(id, titleRu, titleEn, language, section = 'interface') {
  const path = section ? `${section}/${encodeURIComponent(id)}` : encodeURIComponent(id);
  return { id, title: language === 'ru' ? titleRu : titleEn, exists: true, url: `/${language}/${path}` };
}


function interfaceControlsContent(language) {
  const key = (action) => interfaceMechanics.keys[action];
  const controlEntries = [
    ['W / A / S / D', 'Передвижение', 'Movement', 'Движение персонажа по четырём направлениям.', 'Moves the character in four directions.'],
    [key('run'), 'Бег', 'Run', 'Удерживайте клавишу во время движения.', 'Hold while moving.'],
    [key('dash'), 'Рывок', 'Dash', 'Короткий рывок в направлении движения.', 'A short burst in the movement direction.'],
    [key('interact'), 'Взаимодействие', 'Interact', 'Открывает верстаки, машины, сундуки, NPC и другие интерактивные объекты.', 'Opens workbenches, machines, chests, NPCs, and other interactive objects.'],
    [key('inventory'), 'Инвентарь', 'Inventory', 'Открывает сумку и экипировку персонажа.', 'Opens the player inventory and equipment.'],
  ];
  return {
    facts: [
      { label: language === 'ru' ? 'Передвижение' : 'Movement', value: 'WASD' },
      { label: language === 'ru' ? 'Взаимодействие' : 'Interact', value: key('interact') },
      { label: language === 'ru' ? 'Инвентарь' : 'Inventory', value: key('inventory') },
      { label: language === 'ru' ? 'Карта' : 'Map', value: key('toggle_map') },
    ],
    sections: [
      { title: language === 'ru' ? 'Основные клавиши' : 'Core keys', intro: language === 'ru' ? 'Это стандартная раскладка проекта. Клавиши можно переназначить в настройках профиля.' : 'These are the project defaults. Keys can be rebound in profile settings.', entries: controlEntries.map(([binding, ru, en, textRu, textEn]) => ({ title: language === 'ru' ? ru : en, text: language === 'ru' ? textRu : textEn, value: binding, links: [] })) },
      { title: language === 'ru' ? 'Мышь в мире' : 'Mouse actions in the world', intro: language === 'ru' ? 'Действие кнопки зависит от предмета в руке и клетки под курсором.' : 'A mouse button’s action depends on the held item and tile under the cursor.', entries: [
        { title: language === 'ru' ? 'Левая кнопка' : 'Left mouse button', text: language === 'ru' ? 'Атакует, добывает залежь, собирает культуру или разбирает установленный блок.' : 'Attacks, mines a deposit, harvests a crop, or dismantles a placed block.', value: language === 'ru' ? 'Действие / разбор' : 'Action / dismantle', links: [localizedInterfacePageLink('manual-mining', 'Ручная добыча', 'Manual mining', language, 'gathering')] },
        { title: language === 'ru' ? 'Правая кнопка' : 'Right mouse button', text: language === 'ru' ? 'Использует ведро или предмет, обрабатывает и засаживает грядку, улучшает блок либо начинает строительство.' : 'Uses a bucket or item, tills and plants a plot, upgrades a block, or starts placement.', value: language === 'ru' ? 'Использование / строительство' : 'Use / build', links: [localizedInterfacePageLink('building-tools', 'Строительство', 'Building', language)] },
        { title: 'Alt + LMB', text: language === 'ru' ? 'Ставит общую метку в мире и на карте для участников сетевой сессии.' : 'Places a shared marker in the world and on the map for session members.', value: language === 'ru' ? 'Командная метка' : 'Team ping', links: [localizedInterfacePageLink('saves-multiplayer', 'Совместная игра', 'Multiplayer', language)] },
      ] },
    ],
    related: [localizedInterfacePageLink('inventory-hotbar', 'Инвентарь и хотбар', 'Inventory and hotbar', language), localizedInterfacePageLink('building-tools', 'Строительство', 'Building', language), localizedInterfacePageLink('books-map', 'Книги и карта', 'Books and map', language)],
  };
}


function interfaceInventoryContent(language) {
  return {
    facts: [
      { label: language === 'ru' ? 'Всего слотов' : 'Total slots', value: String(interfaceMechanics.inventorySlots) },
      { label: language === 'ru' ? 'Видно в сумке' : 'Visible in inventory', value: String(interfaceMechanics.visibleInventorySlots) },
      { label: language === 'ru' ? 'Слотов хотбара' : 'Hotbar slots', value: String(interfaceMechanics.hotbarSlots) },
      { label: language === 'ru' ? 'Строк хранения' : 'Storage rows', value: String(interfaceMechanics.inventorySlots / interfaceMechanics.rowSize) },
    ],
    sections: [
      { title: language === 'ru' ? 'Единое хранилище' : 'Unified storage', intro: language === 'ru' ? 'Хотбар не дублирует предметы: он всегда показывает первую строку тех же 36 слотов.' : 'The hotbar does not duplicate items: it always displays the first row of the same 36-slot storage.', entries: [
        { title: language === 'ru' ? 'Постоянная строка' : 'Fixed row', text: language === 'ru' ? 'Девять слотов первой строки образуют хотбар. Остальные три строки остаются видны в открытом инвентаре.' : 'The first row’s nine slots form the hotbar. The other three rows remain visible in the open inventory.', value: language === 'ru' ? 'Первая строка' : 'First row', links: [] },
        { title: language === 'ru' ? 'Выбор слота' : 'Select a slot', text: language === 'ru' ? 'Используйте цифры 1–9 или колесо мыши. Один из девяти слотов всегда остаётся активным.' : 'Use number keys 1–9 or the mouse wheel. One of the nine slots always remains active.', value: '1–9 / wheel', links: [] },
      ] },
      { title: language === 'ru' ? 'Работа со стаками' : 'Working with stacks', intro: language === 'ru' ? 'Одни и те же правила действуют в сумке, хотбаре, сундуках и интерфейсах машин.' : 'The same rules apply in the inventory, hotbar, chests, and machine interfaces.', entries: [
        { title: language === 'ru' ? 'ЛКМ и перетаскивание' : 'LMB and drag', text: language === 'ru' ? 'ЛКМ берёт или кладёт стак. Протяжка с предметами на курсоре равномерно распределяет их по совместимым слотам.' : 'LMB picks up or places a stack. Dragging while carrying items distributes them evenly across compatible slots.', value: language === 'ru' ? 'Равномерное распределение' : 'Even distribution', links: [] },
        { title: language === 'ru' ? 'ПКМ' : 'RMB', text: language === 'ru' ? 'ПКМ по стакy берёт половину; протяжка ПКМ кладёт по одному предмету в каждый слот.' : 'RMB on a stack takes half; RMB dragging places one item in each slot.', value: language === 'ru' ? 'Половина / по одному' : 'Half / one each', links: [] },
        { title: 'Shift + LMB', text: language === 'ru' ? 'Быстро переносит стак между хотбаром, сумкой и открытым контейнером.' : 'Quickly moves a stack between the hotbar, inventory, and open container.', value: language === 'ru' ? 'Быстрый перенос' : 'Quick transfer', links: [localizedMechanicItem('CHEST_T1', language)] },
        { title: language === 'ru' ? 'Двойной ЛКМ' : 'Double LMB', text: language === 'ru' ? 'Собирает совпадающие предметы из доступных слотов в один стак до его предела.' : 'Collects matching items from accessible slots into one stack up to its limit.', value: language === 'ru' ? 'Собрать одинаковые' : 'Gather matching', links: [] },
      ] },
    ],
    related: [localizedMechanicItem('CHEST_T1', language), localizedInterfacePageLink('controls', 'Управление', 'Controls', language), localizedInterfacePageLink('logistics', 'Предметная логистика', 'Item logistics', language, 'systems')],
  };
}


function interfaceBuildingContent(language) {
  return {
    facts: [
      { label: language === 'ru' ? 'Радиус строительства' : 'Build radius', value: `${interfaceMechanics.buildRadius} ${language === 'ru' ? 'клетки' : 'tiles'}` },
      { label: language === 'ru' ? 'Рабочая область' : 'Working area', value: `${interfaceMechanics.buildRadius * 2 + 1}×${interfaceMechanics.buildRadius * 2 + 1}` },
      { label: language === 'ru' ? 'Установка' : 'Placement', value: 'RMB' },
      { label: language === 'ru' ? 'Разбор' : 'Dismantling', value: 'LMB' },
    ],
    sections: [
      { title: language === 'ru' ? 'Простое строительство' : 'Simple building', intro: language === 'ru' ? 'Строительство определяется предметом в руке: блок можно поставить, любой другой предмет — нельзя.' : 'The held item determines building: a block can be placed, while any other item cannot.', entries: [
        { title: language === 'ru' ? 'Поставить блок' : 'Place a block', text: language === 'ru' ? 'Возьмите предмет-блок в активную руку и нажмите ПКМ по свободной допустимой клетке. Удерживание кнопки протягивает линию.' : 'Hold a block item and RMB a clear valid tile. Holding the button drags a line.', value: 'RMB / drag', links: [localizedMechanicItem('conveyor', language)] },
        { title: language === 'ru' ? 'Направление блока' : 'Block facing', text: language === 'ru' ? 'Поворачиваемый блок при установке смотрит туда же, куда персонаж. Направление определяет входы, выходы и движение конвейеров.' : 'A rotatable block faces the same direction as the player when placed. Facing controls ports, outputs, and belt movement.', value: language === 'ru' ? 'По взгляду игрока' : 'Follows player', links: [localizedMechanicItem('mechanical_inserter', language)] },
        { title: language === 'ru' ? 'Разобрать блок' : 'Dismantle a block', text: language === 'ru' ? 'Удерживайте ЛКМ по построенному блоку. После заполнения шкалы блок возвращается предметом с сохранёнными данными.' : 'Hold LMB on a placed block. When the progress bar completes, the block returns as an item with its saved data.', value: 'LMB', links: [] },
      ] },
    ],
    related: [localizedMechanicItem('workbench', language), localizedMechanicItem('conveyor', language), localizedInterfacePageLink('logistics', 'Предметная логистика', 'Item logistics', language, 'systems')],
  };
}


function interfaceBooksContent(language) {
  const key = (action) => interfaceMechanics.keys[action];
  return {
    facts: [
      { label: language === 'ru' ? 'Книга рецептов' : 'Recipe book', value: key('recipe_book') },
      { label: language === 'ru' ? 'Книга квестов' : 'Quest book', value: key('quest_book') },
      { label: language === 'ru' ? 'Карта' : 'Map', value: key('toggle_map') },
      { label: language === 'ru' ? 'Технологии' : 'Technology', value: key('technology_tree') },
    ],
    sections: [
      { title: language === 'ru' ? 'Книги прогрессии' : 'Progression books', intro: language === 'ru' ? 'Каждый экран отвечает за отдельную часть развития и не заменяет остальные.' : 'Each screen covers a different part of progression rather than replacing the others.', entries: [
        { title: language === 'ru' ? 'Книга рецептов' : 'Recipe book', text: language === 'ru' ? 'Показывает открытые способы изготовления и ингредиенты. Для самого крафта взаимодействуйте с верстаком или кулинарной станцией.' : 'Shows unlocked crafting formulas and ingredients. Use a workbench or cooking station to craft.', value: key('recipe_book'), links: [localizedInterfacePageLink('recipes', 'Каталог рецептов', 'Recipe catalog', language, '')] },
        { title: language === 'ru' ? 'Книга квестов' : 'Quest book', text: language === 'ru' ? 'Содержит шесть эпох основных заданий, их зависимости, цели и открываемые возможности.' : 'Contains six ages of main quests, their dependencies, objectives, and unlocks.', value: key('quest_book'), links: [localizedInterfacePageLink('quests', 'Квестовая книга', 'Quest book', language, '')] },
        { title: language === 'ru' ? 'Дерево технологий' : 'Technology tree', text: language === 'ru' ? 'Показывает одиннадцать промышленных этапов и требования исследований.' : 'Shows eleven industrial stages and their research requirements.', value: key('technology_tree'), links: [localizedInterfacePageLink('technologies', 'Технологическое развитие', 'Technology progression', language, '')] },
        { title: language === 'ru' ? 'Книга Первопроходца' : 'Frontier Codex', text: language === 'ru' ? 'Кодекс открывается ПКМ по предмету и хранит восемь страниц защитного снаряжения для опасных биомов.' : 'The Codex opens by RMB-using its item and stores eight pages for hazardous-biome protection gear.', value: 'RMB', links: [localizedMechanicItem('codex', language)] },
      ] },
      { title: language === 'ru' ? 'Карта мира' : 'World map', intro: language === 'ru' ? 'Карта помогает ориентироваться в мире, искать открытые области и командные метки.' : 'The map helps with navigation, discovered areas, and team pings.', entries: [
		{ title: language === 'ru' ? 'Карта мира' : 'World map', text: language === 'ru' ? 'M переключает полноэкранную карту. Командные метки, поставленные Alt+ЛКМ, видны и на карте.' : 'M toggles the full-screen map. Team pings placed with Alt+LMB are visible on it.', value: key('toggle_map'), links: [localizedInterfacePageLink('overworld', 'Верхний мир', 'Overworld', language, 'worlds')] },
      ] },
    ],
    related: [localizedMechanicItem('codex', language), localizedInterfacePageLink('recipes', 'Рецепты', 'Recipes', language, ''), localizedInterfacePageLink('quests', 'Квесты', 'Quests', language, ''), localizedInterfacePageLink('technologies', 'Технологии', 'Technologies', language, '')],
  };
}


function interfaceSaveMultiplayerContent(language) {
  const key = (action) => interfaceMechanics.keys[action];
  return {
    facts: [
      { label: language === 'ru' ? 'Автосохранение' : 'Autosave', value: `${interfaceMechanics.autosaveMinutes} ${language === 'ru' ? 'мин' : 'min'}` },
      { label: language === 'ru' ? 'Игроков' : 'Players', value: String(interfaceMechanics.maxPlayers) },
      { label: language === 'ru' ? 'Стандартный порт' : 'Default port', value: String(interfaceMechanics.multiplayerPort) },
      { label: language === 'ru' ? 'Чат' : 'Chat', value: key('chat') },
    ],
    sections: [
      { title: language === 'ru' ? 'Сохранение мира' : 'Saving the world', intro: language === 'ru' ? 'Локальная сессия хранит состояние мира, игрока, инвентаря, машин, карты, квестов и открытий.' : 'A local session stores the world, player, inventory, machines, map, quests, and unlocks.', entries: [
        { title: language === 'ru' ? 'Автосохранение' : 'Autosave', text: language === 'ru' ? `По умолчанию мир сохраняется каждые ${interfaceMechanics.autosaveMinutes} минут. В настройках интервал можно изменить или отключить значением 0.` : `By default, the world saves every ${interfaceMechanics.autosaveMinutes} minutes. The interval can be changed in settings or disabled with 0.`, value: `${interfaceMechanics.autosaveMinutes} ${language === 'ru' ? 'мин' : 'min'}`, links: [] },
        { title: language === 'ru' ? 'Что входит в снимок' : 'What a snapshot contains', text: language === 'ru' ? 'Сохраняются позиция и параметры персонажа, 36 слотов, экипировка, размещённые блоки с внутренними данными, изменения чанков, карта, технологии, боссы и рецепты.' : 'The snapshot includes player position and stats, 36 slots, equipment, placed blocks with internal data, chunk changes, map, technology, bosses, and recipes.', value: language === 'ru' ? 'Полное состояние сессии' : 'Full session state', links: [localizedInterfacePageLink('inventory-hotbar', 'Инвентарь и хотбар', 'Inventory and hotbar', language)] },
      ] },
      { title: language === 'ru' ? 'Сетевая сессия' : 'Online session', intro: language === 'ru' ? 'Хост создаёт авторитетный мир, а подключившиеся игроки получают его актуальное состояние.' : 'The host creates the authoritative world, and joining players receive its current state.', entries: [
        { title: language === 'ru' ? 'Создать игру' : 'Host a game', text: language === 'ru' ? `Стандартная сессия использует порт ${interfaceMechanics.multiplayerPort} и допускает до ${interfaceMechanics.maxPlayers} игроков. Хост может задать имя и пароль.` : `A default session uses port ${interfaceMechanics.multiplayerPort} and supports up to ${interfaceMechanics.maxPlayers} players. The host can set a name and password.`, value: `${interfaceMechanics.maxPlayers} max · ${interfaceMechanics.multiplayerPort}`, links: [] },
        { title: language === 'ru' ? 'Прогресс клиента' : 'Client progress', text: language === 'ru' ? 'Подключённый игрок играет в копии мира хоста. Такая удалённая сессия не записывается поверх его локального сохранения при выходе.' : 'A joining player uses the host’s world state. This remote session is not written over the player’s local save when leaving.', value: language === 'ru' ? 'Локальный мир защищён' : 'Local world protected', links: [] },
        { title: language === 'ru' ? 'Чат и метки' : 'Chat and pings', text: language === 'ru' ? 'Клавиша / открывает чат. Alt+ЛКМ отправляет позиционную метку всем участникам — она появляется в мире и на карте.' : '/ opens chat. Alt+LMB sends a positional ping to every participant, visible in the world and on the map.', value: `${key('chat')} · Alt+LMB`, links: [localizedInterfacePageLink('books-map', 'Книги и карта', 'Books and map', language)] },
      ] },
    ],
    related: [localizedInterfacePageLink('controls', 'Управление', 'Controls', language), localizedInterfacePageLink('books-map', 'Книги и карта', 'Books and map', language), localizedMechanicItem('computer', language)],
  };
}


function localizedInterface(guide, language) {
  const content = {
    controls: interfaceControlsContent,
    'inventory-hotbar': interfaceInventoryContent,
    'building-tools': interfaceBuildingContent,
    'books-map': interfaceBooksContent,
    'saves-multiplayer': interfaceSaveMultiplayerContent,
  }[guide.id](language);
  const index = interfaceDefinitions.indexOf(guide);
  return {
    ...localizedInterfaceSummary(guide, language),
    ...content,
    previous: index > 0 ? localizedInterfaceSummary(interfaceDefinitions[index - 1], language) : null,
    next: index < interfaceDefinitions.length - 1 ? localizedInterfaceSummary(interfaceDefinitions[index + 1], language) : null,
  };
}


function localizedExplorationSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedWikiPageLink(path, titleRu, titleEn, language, id = path) {
  return { id, title: language === 'ru' ? titleRu : titleEn, exists: true, url: `/${language}/${path}` };
}


function localizedExplorationPageLink(id, titleRu, titleEn, language) {
  return localizedWikiPageLink(`exploration/${encodeURIComponent(id)}`, titleRu, titleEn, language, id);
}


function explorationTimeWeatherContent(language) {
  const m = explorationMechanics;
  const realDayMinutes = m.minutesPerDay / (m.minutesPerSecond * 60);
  return {
    facts: [
      { label: language === 'ru' ? 'Темп времени' : 'Time scale', value: `${m.minutesPerSecond} ${language === 'ru' ? 'игр. мин/с' : 'game min/s'}` },
      { label: language === 'ru' ? 'Полные сутки' : 'Full day', value: `${realDayMinutes} ${language === 'ru' ? 'реальных мин' : 'real min'}` },
      { label: language === 'ru' ? 'Начало нового мира' : 'New-world start', value: `${String(m.startHour).padStart(2, '0')}:00` },
      { label: language === 'ru' ? 'Шанс грозы' : 'Storm chance', value: `${m.stormChance * 100}%` },
    ],
    sections: [
      { title: language === 'ru' ? 'Суточный цикл' : 'Day cycle', intro: language === 'ru' ? 'Часы идут непрерывно: одна реальная секунда равна одной игровой минуте.' : 'The clock advances continuously: one real second equals one game minute.', entries: [
        { title: language === 'ru' ? 'Рассвет' : 'Dawn', text: language === 'ru' ? 'С 05:00 до 08:00 освещение плавно усиливается от полной темноты до дневного уровня.' : 'From 05:00 to 08:00, world lighting smoothly rises from darkness to full daylight.', value: '05:00–08:00', links: [] },
        { title: language === 'ru' ? 'День' : 'Daylight', text: language === 'ru' ? 'Полное дневное освещение сохраняется десять игровых часов.' : 'Full daylight lasts for ten game hours.', value: '08:00–18:00', links: [localizedMechanicItem('solar_panel', language)] },
        { title: language === 'ru' ? 'Сумерки и ночь' : 'Dusk and night', text: language === 'ru' ? 'С 18:00 до 21:00 свет плавно гаснет. Глубокая ночь длится с 21:00 до 05:00.' : 'Light fades from 18:00 to 21:00. Deep night lasts from 21:00 until 05:00.', value: '18:00–21:00 · 21:00–05:00', links: [] },
        { title: language === 'ru' ? 'Возраст мира' : 'World age', text: language === 'ru' ? 'Отдельный счётчик игровых минут не сбрасывается в полночь, сохраняется вместе с миром и используется для роста культур.' : 'A separate game-minute counter never wraps at midnight, is saved with the world, and drives crop growth.', value: language === 'ru' ? 'Сохраняется' : 'Persistent', links: [localizedWikiPageLink('gathering/farming', 'Фермерство', 'Farming', language, 'farming')] },
      ] },
      { title: language === 'ru' ? 'Погода' : 'Weather', intro: language === 'ru' ? 'Ясная фаза сменяется дождём или грозой, затем цикл возвращается к ясной погоде.' : 'A clear phase changes into rain or a storm, then the cycle returns to clear weather.', entries: [
        { title: language === 'ru' ? 'Ясно' : 'Clear', text: language === 'ru' ? `Обычная ясная фаза длится от ${m.clearMin / 60} до ${m.clearMax / 60} минут. Первая фаза нового запуска вдвое короче.` : `A normal clear phase lasts ${m.clearMin / 60}–${m.clearMax / 60} minutes. The first phase after startup is half as long.`, value: `${m.clearMin / 60}–${m.clearMax / 60} min`, links: [] },
        { title: language === 'ru' ? 'Дождь' : 'Rain', text: language === 'ru' ? `Дождь длится от ${m.rainMin / 60} до ${m.rainMax / 60} минут, использует ${m.rainParticles} частиц и снижает выработку солнечных панелей до 50%.` : `Rain lasts ${m.rainMin / 60}–${m.rainMax / 60} minutes, uses ${m.rainParticles} particles, and reduces solar-panel output to 50%.`, value: 'Solar ×0.50 · light ×0.82', links: [localizedMechanicItem('solar_panel', language)] },
        { title: language === 'ru' ? 'Гроза' : 'Storm', text: language === 'ru' ? `Гроза выбирается с вероятностью ${m.stormChance * 100}% вместо дождя, использует ${m.stormParticles} частиц и оставляет четверть солнечной выработки.` : `A storm replaces rain with a ${m.stormChance * 100}% chance, uses ${m.stormParticles} particles, and leaves one quarter of solar output.`, value: 'Solar ×0.25 · light ×0.62', links: [] },
        { title: language === 'ru' ? 'Совместная игра' : 'Multiplayer', text: language === 'ru' ? 'Таймер погоды обновляет только хост или одиночная игра. Клиенты получают авторитетное состояние по сети.' : 'Only the host or a single-player session advances the weather timer. Clients receive the authoritative state over the network.', value: language === 'ru' ? 'Управляет хост' : 'Host controlled', links: [localizedWikiPageLink('interface/saves-multiplayer', 'Совместная игра', 'Multiplayer', language, 'saves-multiplayer')] },
      ] },
    ],
    related: [localizedExplorationPageLink('map-exploration', 'Карта и разведка', 'Map and exploration', language), localizedWikiPageLink('gathering/farming', 'Фермерство', 'Farming', language, 'farming'), localizedMechanicItem('solar_panel', language)],
  };
}


function explorationMapContent(language) {
  const m = explorationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Клавиша карты' : 'Map key', value: m.mapKey },
      { label: language === 'ru' ? 'Время жизни метки' : 'Ping lifetime', value: `${m.pingLifetime} ${language === 'ru' ? 'с' : 's'}` },
      { label: language === 'ru' ? 'Маркер ресурса' : 'Resource marker', value: `${m.resourceMarkerSize} px` },
      { label: language === 'ru' ? 'Порог перетаскивания' : 'Drag threshold', value: `${m.dragThreshold} px` },
    ],
    sections: [
      { title: language === 'ru' ? 'Как карта открывается' : 'How the map is revealed', intro: language === 'ru' ? 'Карта пополняется данными тех чанков, которые действительно загрузились вокруг игрока.' : 'The map gains data from chunks that have actually loaded around the player.', entries: [
        { title: language === 'ru' ? 'Местность и объекты' : 'Terrain and objects', text: language === 'ru' ? 'Загруженный чанк переносит на карту рельеф, деревья и размещённые игроком блоки. Исследованная область сохраняется между запусками.' : 'A loaded chunk adds terrain, trees, and player-placed blocks to the map. Explored areas persist between sessions.', value: `${m.chunkSize}×${m.chunkSize} ${language === 'ru' ? 'тайлов/чанк' : 'tiles/chunk'}`, links: [localizedExplorationPageLink('world-generation', 'Генерация мира', 'World generation', language)] },
        { title: language === 'ru' ? 'Открытие биома' : 'Biome discovery', text: language === 'ru' ? 'Биом отмечается открытым, когда персонаж входит в него, но только если этот биом уже разрешён текущей прогрессией.' : 'A biome is marked discovered when the player enters it, but only if current progression has already unlocked that biome.', value: language === 'ru' ? 'При входе' : 'On entry', links: [localizedWikiPageLink('worlds/overworld', 'Верхний мир', 'Overworld', language, 'overworld')] },
        { title: language === 'ru' ? 'Ресурсы и боссы' : 'Resources and bosses', text: language === 'ru' ? 'Карта показывает ядра рудных жил и центры нефтяных или лавовых полей. Метки боссов появляются только в открытых биомах.' : 'The map marks ore-vein cores and the centres of oil or lava fields. Boss markers appear only for discovered biomes.', value: language === 'ru' ? 'Жилы · жидкости · боссы' : 'Veins · fluids · bosses', links: [localizedWikiPageLink('gathering/ore-deposits', 'Рудные месторождения', 'Ore deposits', language, 'ore-deposits'), localizedWikiPageLink('bosses', 'Боссы', 'Bosses', language, 'bosses')] },
      ] },
      { title: language === 'ru' ? 'Полноэкранный режим' : 'Fullscreen mode', intro: language === 'ru' ? 'На большой карте можно панорамировать обзор, ставить общие метки и выбирать открытые обелиски.' : 'The fullscreen map supports panning, shared pings, and selecting discovered obelisks.', entries: [
        { title: language === 'ru' ? 'Перемещение карты' : 'Panning', text: language === 'ru' ? `Удерживайте ЛКМ и тяните. Движение до ${m.dragThreshold} пикселей считается кликом, а не перетаскиванием.` : `Hold LMB and drag. Movement up to ${m.dragThreshold} pixels counts as a click rather than a pan.`, value: `LMB · ${m.dragThreshold} px`, links: [] },
        { title: language === 'ru' ? 'Командная метка' : 'Team ping', text: language === 'ru' ? `Alt+ЛКМ создаёт метку «смотри сюда» размером ${m.pingSize} пикселей. Она видна ${m.pingLifetime} секунд и передаётся участникам сессии.` : `Alt+LMB creates a ${m.pingSize}-pixel “look here” ping. It remains for ${m.pingLifetime} seconds and is shared with session members.`, value: `Alt+LMB · ${m.pingLifetime} s`, links: [localizedWikiPageLink('interface/saves-multiplayer', 'Совместная игра', 'Multiplayer', language, 'saves-multiplayer')] },
        { title: language === 'ru' ? 'Быстрое перемещение' : 'Fast travel', text: language === 'ru' ? `Клик в пределах ${m.obeliskClickRange} пикселей мира от открытого обелиска выбирает ближайший узел и начинает телепортацию.` : `Clicking within ${m.obeliskClickRange} world pixels of a discovered obelisk selects the nearest node and starts teleportation.`, value: `${m.obeliskClickRange} px`, links: [localizedExplorationPageLink('obelisks-fast-travel', 'Обелиски', 'Obelisks', language)] },
      ] },
    ],
    related: [localizedExplorationPageLink('obelisks-fast-travel', 'Обелиски и быстрое перемещение', 'Obelisks and fast travel', language), localizedExplorationPageLink('world-generation', 'Генерация мира', 'World generation', language), localizedWikiPageLink('interface/books-map', 'Книги и карта', 'Books and map', language, 'books-map')],
  };
}


function explorationObelisksContent(language) {
  const m = explorationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Всего обелисков' : 'Total obelisks', value: String(m.obeliskCount) },
      { label: language === 'ru' ? 'Радиус открытия' : 'Discovery radius', value: `${m.discoverRange} px` },
      { label: language === 'ru' ? 'Затухание телепорта' : 'Teleport fade', value: `${m.fadeTime} ${language === 'ru' ? 'с × 2' : 's × 2'}` },
      { label: language === 'ru' ? 'Направлений' : 'Directions', value: String(m.directionCount) },
    ],
    sections: [
      { title: language === 'ru' ? 'Устройство сети' : 'Network layout', intro: language === 'ru' ? 'Позиции вычисляются детерминированно из радиусов колец мира и не меняются между загрузками одного мира.' : 'Positions are computed deterministically from world-ring radii and do not change between loads of the same world.', entries: [
        { title: language === 'ru' ? 'Центр леса' : 'Forest centre', text: language === 'ru' ? 'Один домашний узел находится в центре мира, на стартовой клетке.' : 'One home node sits at the world centre on the spawn tile.', value: '1', links: [localizedWikiPageLink('worlds/overworld/biomes/forest', 'Лес', 'Forest', language, 'forest')] },
        { title: language === 'ru' ? 'Лесные стороны света' : 'Forest landmarks', text: language === 'ru' ? 'Ещё четыре обелиска стоят по сторонам света внутри лесного биома.' : 'Four more obelisks sit on the cardinal axes inside the forest biome.', value: '4', links: [localizedWikiPageLink('worlds/overworld/biomes/forest', 'Лес', 'Forest', language, 'forest')] },
        { title: language === 'ru' ? 'Обычные сектора' : 'Normal sectors', text: language === 'ru' ? `В каждом из четырёх направлений расположено по два узла с отклонением ±${m.normalSpread}° от оси сектора.` : `Each of the four directions has two nodes offset ±${m.normalSpread}° from the sector axis.`, value: '4 × 2 = 8', links: [] },
        { title: language === 'ru' ? 'Сложные сектора' : 'Hard sectors', text: language === 'ru' ? `В каждом внешнем секторе стоят три узла: центральный и два боковых с отклонением ±${m.hardSpread}°.` : `Each outer sector has three nodes: one central and two flanks offset ±${m.hardSpread}°.`, value: '4 × 3 = 12', links: [] },
      ] },
      { title: language === 'ru' ? 'Открытие и переход' : 'Discovery and travel', intro: language === 'ru' ? 'Неоткрытые узлы видны на карте тускло, но использовать их нельзя.' : 'Undiscovered nodes appear faintly on the map but cannot be used.', entries: [
        { title: language === 'ru' ? 'Открытие' : 'Discovery', text: language === 'ru' ? `Подойдите на ${m.discoverRange} пикселей. Узел откроется только в уже разрешённом прогрессией биоме и сразу запишется в данные мира.` : `Walk within ${m.discoverRange} pixels. The node unlocks only in a progression-enabled biome and is immediately stored in world data.`, value: `${m.discoverRange} px`, links: [] },
        { title: language === 'ru' ? 'Телепортация' : 'Teleportation', text: language === 'ru' ? 'Выберите открытый узел в меню обелиска или на полноэкранной карте. Переход закрывается двумя короткими чёрными затуханиями.' : 'Choose a discovered node from an obelisk menu or the fullscreen map. Two short black fades mask the transfer.', value: `${m.fadeTime * 2} ${language === 'ru' ? 'с всего' : 's total'}`, links: [localizedExplorationPageLink('map-exploration', 'Карта и разведка', 'Map and exploration', language)] },
        { title: language === 'ru' ? 'После перехода' : 'After arrival', text: language === 'ru' ? 'Игрок переносится в центр клетки обелиска, интерполяция движения сбрасывается, а мир немедленно обновляет видимые чанки вокруг новой позиции.' : 'The player moves to the centre of the obelisk tile, movement interpolation resets, and visible chunks refresh around the new position.', value: language === 'ru' ? 'Обновление чанков' : 'Chunk refresh', links: [localizedExplorationPageLink('world-generation', 'Генерация мира', 'World generation', language)] },
      ] },
    ],
    related: [localizedExplorationPageLink('map-exploration', 'Карта и разведка', 'Map and exploration', language), localizedWikiPageLink('worlds/overworld', 'Верхний мир', 'Overworld', language, 'overworld'), localizedMechanicItem('ent_totem', language)],
  };
}


function explorationWorldGenerationContent(language) {
  const m = explorationMechanics;
  const visibleSide = m.renderRadius * 2 + 1;
  return {
    facts: [
      { label: language === 'ru' ? 'Размер чанка' : 'Chunk size', value: `${m.chunkSize}×${m.chunkSize} ${language === 'ru' ? 'тайлов' : 'tiles'}` },
      { label: language === 'ru' ? 'Видимая область' : 'Visible area', value: `${visibleSide}×${visibleSide} (${visibleSide ** 2}) ${language === 'ru' ? 'чанков' : 'chunks'}` },
      { label: language === 'ru' ? 'Радиус суши' : 'Land radius', value: `${m.hardRadius} ${language === 'ru' ? 'тайлов' : 'tiles'}` },
      { label: language === 'ru' ? 'Цель структур' : 'Structure target', value: String(m.targetStructures) },
    ],
    sections: [
      { title: language === 'ru' ? 'Кольца Верхнего мира' : 'Overworld rings', intro: language === 'ru' ? 'Генератор строит конечную радиальную сушу вокруг начала координат; границы слегка искажает шум.' : 'The generator builds a finite radial landmass around the origin, with noise gently warping its boundaries.', entries: [
        { title: language === 'ru' ? 'Центральный лес' : 'Central forest', text: language === 'ru' ? `Густой лес занимает весь безопасный центр до радиуса ${m.forestRadius} тайлов.` : `Dense forest fills the entire safe centre up to radius ${m.forestRadius} tiles.`, value: `0–${m.forestRadius}`, links: [localizedWikiPageLink('worlds/overworld', 'Карта биомов', 'Biome map', language, 'overworld')] },
        { title: language === 'ru' ? 'Обычные сектора' : 'Normal sectors', text: language === 'ru' ? `От леса до радиуса ${m.sectorRadius} находятся четыре направления: снег на севере, болото на юге, пустыня на западе и джунгли на востоке.` : `From the forest to radius ${m.sectorRadius}, four directions contain snow north, swamp south, desert west, and jungle east.`, value: `${m.forestRadius}–${m.sectorRadius}`, links: [] },
        { title: language === 'ru' ? 'Сложные сектора' : 'Hard sectors', text: language === 'ru' ? `До радиуса ${m.hardRadius} продолжаются Ледяная бездна, Гниющие топи, Солнечный каньон и Первобытные дебри. Дальше начинается бесконечный океан.` : `Icy Abyss, Rotting Bog, Sunny Canyon, and Primeval Thicket continue to radius ${m.hardRadius}. Infinite ocean begins beyond it.`, value: `${m.sectorRadius}–${m.hardRadius}`, links: [] },
        { title: language === 'ru' ? 'Берег и неровные границы' : 'Coast and warped borders', text: language === 'ru' ? `Перед океаном проходит пляж шириной ${m.beachWidth} тайла, кроме замёрзшего северного побережья. Шум смещает кольца до ${m.radialWarp}, а границы секторов — до ${m.sectorWarp} тайлов.` : `A ${m.beachWidth}-tile beach precedes the ocean except on the frozen northern coast. Noise shifts ring borders by up to ${m.radialWarp} and sector borders by up to ${m.sectorWarp} tiles.`, value: `${m.beachWidth} · ±${m.radialWarp} · ±${m.sectorWarp}`, links: [] },
      ] },
      { title: language === 'ru' ? 'Сид, чанки и структуры' : 'Seed, chunks, and structures', intro: language === 'ru' ? 'Одинаковый числовой или текстовый сид даёт одинаковую базовую генерацию; текст сначала преобразуется в хеш.' : 'The same numeric or text seed produces the same base generation; text seeds are hashed first.', entries: [
        { title: language === 'ru' ? 'Потоковая загрузка' : 'Chunk streaming', text: language === 'ru' ? `Вокруг игрока поддерживается квадрат радиусом ${m.renderRadius} чанка: ${visibleSide}×${visibleSide}, или до ${visibleSide ** 2} чанков. Данные генерируются рабочим потоком, а отображение применяется в главном.` : `A square radius of ${m.renderRadius} chunks is maintained around the player: ${visibleSide}×${visibleSide}, or up to ${visibleSide ** 2} chunks. Data is generated on a worker thread and rendered on the main thread.`, value: `${visibleSide ** 2} × ${m.chunkSize ** 2} ${language === 'ru' ? 'тайлов' : 'tiles'}`, links: [localizedExplorationPageLink('map-exploration', 'Карта и разведка', 'Map and exploration', language)] },
        { title: language === 'ru' ? 'Руины и лаборатории' : 'Ruins and laboratories', text: language === 'ru' ? `При первом запуске генератор пытается разместить до ${m.targetStructures} структур за ${m.structureAttempts} попыток. Между центрами нужно не менее ${m.structureSpacing} тайлов, а до спавна — ${m.structureSpawnDistance}.` : `On first creation, the generator tries to place up to ${m.targetStructures} structures in ${m.structureAttempts} attempts. Centres require ${m.structureSpacing} tiles of spacing and must be ${m.structureSpawnDistance} tiles from spawn.`, value: `${m.targetStructures} / ${m.structureAttempts}`, links: [] },
        { title: language === 'ru' ? 'Где их искать' : 'Where to search', text: language === 'ru' ? 'Структуры не появляются в океане, на пляже и в обычном болоте. Лаборатории встречаются только в обычных и сложных секторах; в лесном кольце есть лишь руины.' : 'Structures never appear in the ocean, on beaches, or in the normal swamp. Laboratories occur only in normal and hard sectors; the forest ring contains ruins only.', value: language === 'ru' ? '3 запретных биома' : '3 forbidden biomes', links: [] },
        { title: language === 'ru' ? 'Сундуки' : 'Loot chests', text: language === 'ru' ? `Каждая структура содержит сундук своего тира с ${m.lootMin}–${m.lootMax} стаками. Чем дальше кольцо, тем выше уровень таблицы добычи.` : `Each structure contains a tier-appropriate chest with ${m.lootMin}–${m.lootMax} stacks. Farther rings use higher-tier loot tables.`, value: `${m.lootMin}–${m.lootMax} ${language === 'ru' ? 'стаков' : 'stacks'}`, links: [localizedWikiPageLink('items', 'Каталог предметов', 'Item catalog', language, 'items')] },
      ] },
    ],
    related: [localizedWikiPageLink('worlds/overworld', 'Верхний мир', 'Overworld', language, 'overworld'), localizedExplorationPageLink('map-exploration', 'Карта и разведка', 'Map and exploration', language), localizedWikiPageLink('gathering/ore-deposits', 'Рудные месторождения', 'Ore deposits', language, 'ore-deposits')],
  };
}


function explorationDroppedItemsContent(language) {
  const m = explorationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Радиус магнита' : 'Magnet radius', value: `${m.magnetRadius} px (${m.magnetRadius / m.tileSize} ${language === 'ru' ? 'тайла' : 'tiles'})` },
      { label: language === 'ru' ? 'Радиус подбора' : 'Pickup radius', value: `${m.pickupRadius} px` },
      { label: language === 'ru' ? 'Скорость притяжения' : 'Magnet speed', value: `${m.magnetSpeed} px/s` },
      { label: language === 'ru' ? 'Стандартная задержка' : 'Default delay', value: `${m.pickupDelay} s` },
    ],
    sections: [
      { title: language === 'ru' ? 'От появления до инвентаря' : 'From spawn to inventory', intro: language === 'ru' ? 'После короткой защиты от мгновенного подбора предмет начинает искать ближайшего локального игрока.' : 'After a short protection against instant pickup, the item begins tracking the local player.', entries: [
        { title: language === 'ru' ? 'Задержка' : 'Pickup delay', text: language === 'ru' ? `Обычный выброс нельзя подобрать первые ${m.pickupDelay} секунды. Отдельные действия могут передать другую задержку или потребовать сначала отойти от предмета.` : `A normal drop cannot be collected for the first ${m.pickupDelay} seconds. Some actions can supply another delay or require the player to move away first.`, value: `${m.pickupDelay} s`, links: [localizedWikiPageLink('interface/inventory-hotbar', 'Инвентарь и хотбар', 'Inventory and hotbar', language, 'inventory-hotbar')] },
        { title: language === 'ru' ? 'Магнит' : 'Magnet', text: language === 'ru' ? `В пределах ${m.magnetRadius} пикселей предмет летит к игроку со скоростью ${m.magnetSpeed} пикселей в секунду. На дистанции ${m.pickupRadius} пикселей начинается подбор.` : `Within ${m.magnetRadius} pixels, the item moves toward the player at ${m.magnetSpeed} pixels per second. Pickup starts at ${m.pickupRadius} pixels.`, value: `${m.magnetRadius} → ${m.pickupRadius} px`, links: [] },
        { title: language === 'ru' ? 'Порядок заполнения' : 'Insertion order', text: language === 'ru' ? 'Стак сначала автоматически добавляется в общее хранилище хотбара, затем оставшаяся часть передаётся интерфейсу инвентаря.' : 'The stack is first auto-inserted into hotbar storage, then any remainder is passed to the inventory interface.', value: language === 'ru' ? 'Хотбар → сумка' : 'Hotbar → inventory', links: [] },
      ] },
      { title: language === 'ru' ? 'Остатки и сеть' : 'Leftovers and networking', intro: language === 'ru' ? 'Подбор соблюдает максимальный размер стака и не уничтожает то, что не помещается.' : 'Pickup respects maximum stack sizes and does not destroy anything that cannot fit.', entries: [
        { title: language === 'ru' ? 'Заполненный инвентарь' : 'Full inventory', text: language === 'ru' ? 'Если часть стака не поместилась, остаток остаётся на земле с обновлённым количеством и снова может притягиваться.' : 'If part of a stack does not fit, the remainder stays on the ground with its updated count and can be attracted again.', value: language === 'ru' ? 'Без потери остатка' : 'No lost remainder', links: [localizedWikiPageLink('interface/inventory-hotbar', 'Инвентарь и хотбар', 'Inventory and hotbar', language, 'inventory-hotbar')] },
        { title: language === 'ru' ? 'Сетевая арбитрация' : 'Network arbitration', text: language === 'ru' ? 'Для сетевого предмета клиент запрашивает подтверждение у хоста. Старый сетевой ID погашается один раз, поэтому два игрока не могут получить один и тот же стак.' : 'For a networked drop, the client requests host confirmation. The old network ID is consumed once, so two players cannot receive the same stack.', value: language === 'ru' ? 'Решает хост' : 'Host authoritative', links: [localizedWikiPageLink('interface/saves-multiplayer', 'Совместная игра', 'Multiplayer', language, 'saves-multiplayer')] },
        { title: language === 'ru' ? 'Сетевой остаток' : 'Network remainder', text: language === 'ru' ? 'После подтверждённого подбора невместившаяся часть создаётся заново как отдельный сетевой предмет с новым идентификатором.' : 'After confirmed pickup, any portion that does not fit is respawned as a separate network drop with a new identifier.', value: language === 'ru' ? 'Новый сетевой ID' : 'New network ID', links: [] },
        { title: language === 'ru' ? 'Исчезновение по времени' : 'Timed despawn', text: language === 'ru' ? 'У самого объекта предмета нет таймера автоматического исчезновения: он удаляется после успешного подбора или сетевого уведомления.' : 'The dropped-item object has no automatic despawn timer; it is removed after successful pickup or a network despawn notice.', value: language === 'ru' ? 'Таймера нет' : 'No timer', links: [] },
      ] },
    ],
    related: [localizedWikiPageLink('interface/inventory-hotbar', 'Инвентарь и хотбар', 'Inventory and hotbar', language, 'inventory-hotbar'), localizedWikiPageLink('interface/saves-multiplayer', 'Совместная игра', 'Multiplayer', language, 'saves-multiplayer'), localizedMechanicItem('copper_ore', language)],
  };
}


function localizedExploration(guide, language) {
  const content = {
    'time-weather': explorationTimeWeatherContent,
    'map-exploration': explorationMapContent,
    'obelisks-fast-travel': explorationObelisksContent,
    'world-generation': explorationWorldGenerationContent,
    'dropped-items': explorationDroppedItemsContent,
  }[guide.id](language);
  const index = explorationDefinitions.indexOf(guide);
  return {
    ...localizedExplorationSummary(guide, language),
    ...content,
    previous: index > 0 ? localizedExplorationSummary(explorationDefinitions[index - 1], language) : null,
    next: index < explorationDefinitions.length - 1 ? localizedExplorationSummary(explorationDefinitions[index + 1], language) : null,
  };
}


function localizedOptimizationSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedOptimizationPageLink(id, titleRu, titleEn, language) {
  return localizedWikiPageLink(`optimization/${encodeURIComponent(id)}`, titleRu, titleEn, language, id);
}


function optimizationModulesContent(language) {
  const m = optimizationMechanics;
  const percent = (value) => `${Math.round(value * 100)}%`;
  return {
    facts: [
      { label: language === 'ru' ? 'Типов модулей' : 'Module types', value: String(m.moduleTypes) },
      { label: language === 'ru' ? 'Уровней каждого типа' : 'Levels per type', value: String(m.moduleLimit) },
      { label: language === 'ru' ? 'Максимум скорости' : 'Maximum speed', value: `+${percent(m.speedBonus * m.moduleLimit)}` },
      { label: language === 'ru' ? 'Максимум продуктивности' : 'Maximum productivity', value: `+${percent(m.productivityBonus * m.moduleLimit)}` },
    ],
    sections: [
      { title: language === 'ru' ? 'Четыре специализации' : 'Four specializations', intro: language === 'ru' ? `Каждый тип можно улучшить до уровня ${m.moduleLimit}; уровни разных типов хранятся независимо.` : `Each type can reach level ${m.moduleLimit}; levels of different types are stored independently.`, entries: [
        { title: language === 'ru' ? 'Скорость' : 'Speed', text: language === 'ru' ? `Каждый уровень ускоряет симуляцию процесса на ${percent(m.speedBonus)}, но увеличивает фактический расход энергии на ${percent(m.speedEnergyPenalty)}.` : `Each level speeds up process simulation by ${percent(m.speedBonus)} but raises actual energy use by ${percent(m.speedEnergyPenalty)}.`, value: `+${percent(m.speedBonus)} speed · +${percent(m.speedEnergyPenalty)} EU`, links: [localizedMechanicItem('machine_module_speed', language)] },
        { title: language === 'ru' ? 'Эффективность' : 'Efficiency', text: language === 'ru' ? `Каждый уровень возвращает ${percent(m.efficiencyBonus)} потраченной энергии в буфер. Итоговый множитель не может быть ниже ${percent(m.energyFloor)}.` : `Each level rebates ${percent(m.efficiencyBonus)} of spent energy to the buffer. The final multiplier cannot fall below ${percent(m.energyFloor)}.`, value: `−${percent(m.efficiencyBonus)} EU`, links: [localizedMechanicItem('machine_module_efficiency', language)] },
        { title: language === 'ru' ? 'Ёмкость' : 'Capacity', text: language === 'ru' ? `Увеличивает внутренний энергетический буфер на ${percent(m.capacityBonus)} за уровень, до +${percent(m.capacityBonus * m.moduleLimit)}.` : `Increases the internal energy buffer by ${percent(m.capacityBonus)} per level, up to +${percent(m.capacityBonus * m.moduleLimit)}.`, value: `+${percent(m.capacityBonus)} buffer`, links: [localizedMechanicItem('machine_module_capacity', language)] },
        { title: language === 'ru' ? 'Продуктивность' : 'Productivity', text: language === 'ru' ? `За каждую единицу твёрдого выхода накапливается ${percent(m.productivityBonus)} бонусного прогресса. Целая накопленная единица добавляется в выход без новых ингредиентов.` : `Each solid output unit accumulates ${percent(m.productivityBonus)} bonus progress. Every whole accumulated unit is added to output without extra ingredients.`, value: `+${percent(m.productivityBonus)} output`, links: [localizedMechanicItem('machine_module_productivity', language)] },
      ] },
      { title: language === 'ru' ? 'Совместное действие' : 'Combining effects', intro: language === 'ru' ? 'Модули применяются вокруг одного машинного тика: сначала ускоряется его шаг, затем возвращается часть энергии и начисляется бонусный выход.' : 'Modules wrap a machine tick: its time step is accelerated first, then energy is rebated and bonus output is awarded.', entries: [
        { title: language === 'ru' ? 'Скорость и эффективность' : 'Speed and efficiency', text: language === 'ru' ? 'Энергетический множитель складывает штраф скорости и скидку эффективности. Три уровня обоих типов дают 85% базового расхода при 160% скорости.' : 'The energy multiplier combines the speed penalty and efficiency rebate. Three levels of both yield 85% base energy use at 160% speed.', value: '×1.60 speed · ×0.85 EU', links: [] },
        { title: language === 'ru' ? 'Сохранение состояния' : 'Persistence', text: language === 'ru' ? 'Уровни модулей и дробный прогресс продуктивности сохраняются вместе с машиной и синхронизируются в сетевой сессии.' : 'Module levels and fractional productivity progress are saved with the machine, while module configuration is synchronized online.', value: language === 'ru' ? 'Сейв + сеть' : 'Save + network', links: [localizedWikiPageLink('interface/saves-multiplayer', 'Сохранения и совместная игра', 'Saves and multiplayer', language, 'saves-multiplayer')] },
      ] },
    ],
    related: [localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language), localizedWikiPageLink('systems/power', 'Энергосистема', 'Power system', language, 'power'), localizedMechanicItem('machine_module_speed', language)],
  };
}


function optimizationOutputControlContent(language) {
  const m = optimizationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Старт по умолчанию' : 'Default start', value: `< ${m.defaultOutputStart * 100}%` },
      { label: language === 'ru' ? 'Стоп по умолчанию' : 'Default stop', value: `≥ ${m.defaultOutputStop * 100}%` },
      { label: language === 'ru' ? 'Минимальный разрыв' : 'Minimum gap', value: `${m.outputMinGap * 100}%` },
      { label: language === 'ru' ? 'Шаг ползунков' : 'Slider step', value: '5%' },
    ],
    sections: [
      { title: language === 'ru' ? 'Гистерезис выхода' : 'Output hysteresis', intro: language === 'ru' ? 'Две разные границы предотвращают включение и выключение машины на каждом колебании одного предмета.' : 'Two distinct thresholds prevent the machine from toggling whenever one item moves.', entries: [
        { title: language === 'ru' ? 'Остановка' : 'Stop threshold', text: language === 'ru' ? `Работа блокируется, когда самый заполненный выходной слот достигает верхней границы. По умолчанию это ${m.defaultOutputStop * 100}%.` : `Processing is blocked when the fullest output slot reaches the upper threshold, ${m.defaultOutputStop * 100}% by default.`, value: `≥ ${m.defaultOutputStop * 100}%`, links: [] },
        { title: language === 'ru' ? 'Возобновление' : 'Resume threshold', text: language === 'ru' ? `После остановки машина снова запускается только когда заполнение опускается до нижней границы — ${m.defaultOutputStart * 100}% по умолчанию.` : `After stopping, the machine resumes only when fill falls to the lower threshold, ${m.defaultOutputStart * 100}% by default.`, value: `≤ ${m.defaultOutputStart * 100}%`, links: [] },
        { title: language === 'ru' ? 'Несколько выходов' : 'Multiple outputs', text: language === 'ru' ? 'Система берёт максимальную долю заполнения среди всех слотов с ролью OUTPUT, поэтому один забитый побочный выход может остановить процесс.' : 'The system uses the highest fill ratio among all OUTPUT slots, so one blocked byproduct slot can stop processing.', value: language === 'ru' ? 'Максимум по выходам' : 'Maximum output fill', links: [localizedWikiPageLink('machines', 'Каталог машин', 'Machine catalog', language, 'machines')] },
      ] },
      { title: language === 'ru' ? 'Настройка и состояние' : 'Configuration and state', intro: language === 'ru' ? 'Панель доступна только машинам с предметным выходом.' : 'The panel is available only to machines with item output slots.', entries: [
        { title: language === 'ru' ? 'Допустимый диапазон' : 'Valid range', text: language === 'ru' ? `Нижняя граница регулируется от 0 до 90%, верхняя — от 10 до 100%. Между ними всегда сохраняется не менее ${m.outputMinGap * 100} процентных пунктов.` : `The lower threshold ranges from 0–90% and the upper from 10–100%. At least ${m.outputMinGap * 100} percentage points always separate them.`, value: '0–90% · 10–100%', links: [] },
        { title: language === 'ru' ? 'Автоматический статус' : 'Automatic status', text: language === 'ru' ? 'Интерфейс показывает текущее заполнение и состояние «готова к производству» либо «автоматическая остановка». Заблокированная машина не расходует ресурсы.' : 'The interface shows current fill and either “ready for production” or “automatic stop.” A blocked machine consumes no resources.', value: language === 'ru' ? 'Без расхода в стопе' : 'No consumption while stopped', links: [localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language)] },
        { title: language === 'ru' ? 'Сохранение и синхронизация' : 'Save and synchronization', text: language === 'ru' ? 'Флаг, обе границы и текущее состояние записываются в машину и передаются участникам сетевой сессии.' : 'The enabled flag, both thresholds, and running state are stored on the machine and sent to online peers.', value: language === 'ru' ? 'Полная конфигурация' : 'Full configuration', links: [localizedWikiPageLink('interface/saves-multiplayer', 'Совместная игра', 'Multiplayer', language, 'saves-multiplayer')] },
      ] },
    ],
    related: [localizedOptimizationPageLink('stock-control', 'Контроль запасов', 'Stock control', language), localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language), localizedWikiPageLink('systems/logistics', 'Предметная логистика', 'Item logistics', language, 'logistics')],
  };
}


function optimizationStockControlContent(language) {
  const m = optimizationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Цель по умолчанию' : 'Default target', value: String(m.defaultStockTarget) },
      { label: language === 'ru' ? 'Диапазон цели' : 'Target range', value: `1–${m.stockMaxTarget}` },
      { label: language === 'ru' ? 'Интервал сканирования' : 'Scan interval', value: `${m.stockScan} ms` },
      { label: language === 'ru' ? 'Максимум производителей' : 'Maximum producers', value: String(m.stockMaxProducers) },
    ],
    sections: [
      { title: language === 'ru' ? 'Что считается запасом' : 'What counts as stock', intro: language === 'ru' ? 'Машина идёт только по направлению своего выхода через конвейеры и манипуляторы и считает выбранный предмет в достигнутых сундуках.' : 'The machine follows its output direction through conveyors and inserters and counts the selected item in reachable chests.', entries: [
        { title: language === 'ru' ? 'Выходная сеть' : 'Output network', text: language === 'ru' ? `Обход ограничен ${m.stockMaxNodes} узлами. Фильтры и направление логистики учитываются; сундук вне реального пути не попадёт в сумму.` : `Traversal is capped at ${m.stockMaxNodes} nodes. Logistics direction and filters are respected, so an unreachable chest is not counted.`, value: `≤ ${m.stockMaxNodes} ${language === 'ru' ? 'узлов' : 'nodes'}`, links: [localizedWikiPageLink('systems/logistics', 'Предметная логистика', 'Item logistics', language, 'logistics')] },
        { title: language === 'ru' ? 'Цель и возврат' : 'Target and restart', text: language === 'ru' ? `При достижении цели производство останавливается. Оно возобновляется, когда запас падает до ${m.stockResumeRatio * 100}% цели, создавая устойчивый запас без дребезга.` : `Production stops at the target and resumes when stock falls to ${m.stockResumeRatio * 100}% of it, maintaining supply without rapid toggling.`, value: `100% → ${m.stockResumeRatio * 100}%`, links: [] },
        { title: language === 'ru' ? 'Нет хранилища' : 'No storage', text: language === 'ru' ? 'Если по выходному маршруту не найден ни один сундук, машина блокируется и показывает отдельную причину.' : 'If no chest is found along the output route, the machine blocks and reports a dedicated reason.', value: language === 'ru' ? 'Безопасная остановка' : 'Safe stop', links: [] },
      ] },
      { title: language === 'ru' ? 'Несколько производителей' : 'Multiple producers', intro: language === 'ru' ? 'Машины, следящие за одним предметом в одном наборе сундуков, образуют группу заявок.' : 'Machines tracking the same item in the same chest set form one claim group.', entries: [
        { title: language === 'ru' ? 'Приоритет' : 'Priority', text: language === 'ru' ? 'Высокий приоритет получает место раньше нормального и низкого. При равенстве порядок стабилизируется координатами машины.' : 'High priority receives a slot before normal and low. Equal priorities are ordered deterministically by machine coordinates.', value: language === 'ru' ? 'Высокий → обычный → низкий' : 'High → normal → low', links: [] },
        { title: language === 'ru' ? 'Масштабирование по дефициту' : 'Deficit scaling', text: language === 'ru' ? 'Работает 1 производитель при дефиците до 25%, 2 — свыше 25%, 3 — свыше 50% и 4 — свыше 75%.' : 'One producer runs at up to 25% deficit, two above 25%, three above 50%, and four above 75%.', value: '1 / 2 / 3 / 4', links: [] },
        { title: language === 'ru' ? 'Живые заявки' : 'Live claims', text: language === 'ru' ? `Скан выполняется каждые ${m.stockScan} мс, а заявка без обновления удаляется через ${m.stockClaimTimeout} мс. Это освобождает место после демонтажа или отключения машины.` : `Scanning occurs every ${m.stockScan} ms, and a claim without refresh expires after ${m.stockClaimTimeout} ms. This frees slots after a machine is removed or disconnected.`, value: `${m.stockScan} / ${m.stockClaimTimeout} ms`, links: [] },
      ] },
    ],
    related: [localizedOptimizationPageLink('output-control', 'Контроль выходного буфера', 'Output-buffer control', language), localizedOptimizationPageLink('assembler-coordination', 'Координация сборщиков', 'Assembler coordination', language), localizedWikiPageLink('systems/logistics', 'Предметная логистика', 'Item logistics', language, 'logistics')],
  };
}


function optimizationAssemblerContent(language) {
  const m = optimizationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Входных слотов' : 'Input slots', value: String(m.assemblerInputSlots) },
      { label: language === 'ru' ? 'Запас ингредиентов' : 'Ingredient buffer', value: `${m.assemblerRequestBatches} ${language === 'ru' ? 'партии' : 'batches'}` },
      { label: language === 'ru' ? 'Скан плана' : 'Plan scan', value: `${m.distributionScan} ms` },
      { label: language === 'ru' ? 'Глубина запроса' : 'Request traversal', value: `${m.conveyorRequestMaxNodes} ${language === 'ru' ? 'узлов' : 'nodes'}` },
    ],
    sections: [
      { title: language === 'ru' ? 'Общий производственный план' : 'Shared production plan', intro: language === 'ru' ? 'Режим доступен паровым сборщикам с включённым контролем запасов.' : 'This mode is available to Steam Assemblers with stock control enabled.', entries: [
        { title: language === 'ru' ? 'Распределение рецептов' : 'Recipe distribution', text: language === 'ru' ? 'Связанные сборщики сравнивают дефициты на складе и делят между собой недостающие рецепты, вместо слепого дублирования одной операции.' : 'Connected assemblers compare warehouse deficits and distribute missing recipes instead of blindly duplicating one operation.', value: language === 'ru' ? 'По дефициту склада' : 'By warehouse deficit', links: [localizedMechanicItem('steam_assembler', language)] },
        { title: language === 'ru' ? 'Смена выхода' : 'Output switching', text: language === 'ru' ? 'Сборщик ждёт освобождения выходного слота перед переключением на рецепт с другим результатом, поэтому стаки разных предметов не смешиваются.' : 'An assembler waits for its output slot to clear before switching to a recipe with a different result, preventing mixed stacks.', value: language === 'ru' ? 'Без смешивания' : 'No mixed output', links: [] },
        { title: language === 'ru' ? 'Обновление заявок' : 'Claim refresh', text: language === 'ru' ? `План пересчитывается каждые ${m.distributionScan} мс; неактивная заявка исчезает через ${m.distributionTimeout} мс.` : `The plan is recalculated every ${m.distributionScan} ms; an inactive claim expires after ${m.distributionTimeout} ms.`, value: `${m.distributionScan} / ${m.distributionTimeout} ms`, links: [] },
      ] },
      { title: language === 'ru' ? 'Запрос ингредиентов' : 'Ingredient requests', intro: language === 'ru' ? 'Вместо любых подходящих предметов входная логистика забирает только то, чего не хватает выбранному рецепту.' : 'Instead of taking any accepted item, input logistics pulls only what the selected recipe currently lacks.', entries: [
        { title: language === 'ru' ? 'Целевой объём' : 'Target amount', text: language === 'ru' ? `Для каждого ингредиента сборщик стремится держать количество на ${m.assemblerRequestBatches} производственные партии и вычитает уже лежащие во входах предметы.` : `For each ingredient, the assembler targets ${m.assemblerRequestBatches} production batches and subtracts items already present in its inputs.`, value: `${m.assemblerRequestBatches}× ${language === 'ru' ? 'рецепт' : 'recipe'}`, links: [] },
        { title: language === 'ru' ? 'Резервирование в пути' : 'In-transit reservations', text: language === 'ru' ? 'Забранный стак получает токен назначения. Зарезервированное количество вычитается из следующих запросов, чтобы несколько лент не везли один и тот же дефицит.' : 'A pulled stack receives a destination token. Reserved quantities are subtracted from later requests so multiple belts do not serve the same deficit twice.', value: `${m.reservationTtl / 60000} ${language === 'ru' ? 'мин TTL' : 'min TTL'}`, links: [] },
        { title: language === 'ru' ? 'Маршрут' : 'Traversal', text: language === 'ru' ? `Контекст запроса проходит через конвейеры, сундуки и машины, но не глубже ${m.conveyorRequestMaxNodes} узлов.` : `Request context travels through conveyors, chests, and machines, but no farther than ${m.conveyorRequestMaxNodes} nodes.`, value: `≤ ${m.conveyorRequestMaxNodes}`, links: [localizedWikiPageLink('systems/logistics', 'Предметная логистика', 'Item logistics', language, 'logistics')] },
      ] },
    ],
    related: [localizedOptimizationPageLink('stock-control', 'Контроль запасов', 'Stock control', language), localizedOptimizationPageLink('production-lines', 'Анализ линий', 'Production-line analysis', language), localizedMechanicItem('steam_assembler', language)],
  };
}


function optimizationDiagnosticsContent(language) {
  const m = optimizationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Обычный тик' : 'Normal tick', value: `${m.defaultTick} s` },
      { label: language === 'ru' ? 'Сон после простоя' : 'Idle sleep after', value: `${m.idleGrace} s` },
      { label: language === 'ru' ? 'Удалённая дистанция' : 'Remote distance', value: `${m.remoteDistance} px` },
      { label: language === 'ru' ? 'Удалённый тик' : 'Remote tick', value: `${m.remoteTick} s` },
    ],
    sections: [
      { title: language === 'ru' ? 'Внутренняя телеметрия' : 'Internal telemetry', intro: language === 'ru' ? 'Машины собирают техническую телеметрию внутри симуляции без отдельного окна поверх игры.' : 'Machines collect technical telemetry internally without a separate window over gameplay.', entries: [
        { title: language === 'ru' ? 'Пять показателей' : 'Five metrics', text: language === 'ru' ? 'Сводка показывает общее число машин, активные, спящие по дистанции, заторы конвейеров и суммарное время последнего тика в миллисекундах.' : 'The summary reports total machines, active machines, distance-sleeping machines, conveyor jams, and aggregate last-tick time in milliseconds.', value: language === 'ru' ? 'Всего · активны · спят · заторы · мс' : 'Total · active · sleeping · jams · ms', links: [localizedWikiPageLink('systems/power', 'Энергосистема', 'Power system', language, 'power')] },
        { title: language === 'ru' ? 'Статус машины' : 'Machine status', text: language === 'ru' ? 'Телеметрия различает отсутствие топлива, энергии, пара или входа, забитый выход, запрос ингредиентов и остановки системами контроля.' : 'Telemetry distinguishes missing fuel, power, steam, or input; blocked output; ingredient requests; and automation-control stops.', value: language === 'ru' ? 'Причина остановки' : 'Stop reason', links: [localizedOptimizationPageLink('output-control', 'Контроль выхода', 'Output control', language), localizedOptimizationPageLink('stock-control', 'Контроль запасов', 'Stock control', language)] },
        { title: language === 'ru' ? 'Предупреждения' : 'Alerts', text: language === 'ru' ? `Повторные сообщения о неисправностях ограничены паузой ${m.alertCooldown} секунд, чтобы HUD не заполнялся одинаковыми уведомлениями.` : `Repeated fault messages have a ${m.alertCooldown}-second cooldown so identical alerts do not flood the HUD.`, value: `${m.alertCooldown} s`, links: [] },
      ] },
      { title: language === 'ru' ? 'Экономия симуляции' : 'Simulation scaling', intro: language === 'ru' ? 'Все скорости рассчитываются через delta, поэтому более редкий тик получает больший шаг и сохраняет средний темп производства.' : 'All rates are delta-driven, so a less frequent tick receives a larger step and preserves average production speed.', entries: [
        { title: language === 'ru' ? 'Обычный режим' : 'Normal mode', text: language === 'ru' ? `Большинство машин обновляется каждые ${m.defaultTick} секунды. Фаза старта случайна, чтобы сотни машин не срабатывали в одном кадре.` : `Most machines update every ${m.defaultTick} seconds. Their starting phase is randomized so hundreds do not fire on one frame.`, value: `${1 / m.defaultTick} ${language === 'ru' ? 'тиков/с' : 'ticks/s'}`, links: [] },
        { title: language === 'ru' ? 'Простой' : 'Idle sleep', text: language === 'ru' ? `После ${m.idleGrace} секунд без работы интервал увеличивается в ${m.idleMultiplier} раз. Подача или извлечение предмета немедленно будит машину.` : `After ${m.idleGrace} idle seconds, the interval grows ${m.idleMultiplier}×. Pushing or pulling an item wakes the machine immediately.`, value: `${m.defaultTick * m.idleMultiplier} s`, links: [] },
        { title: language === 'ru' ? 'Удалённая фабрика' : 'Remote factory', text: language === 'ru' ? `Дальше ${m.remoteDistance} пикселей от игрока интервал составляет не менее ${m.remoteTick} секунды. Логика продолжает работать с накопленным временем.` : `Beyond ${m.remoteDistance} pixels from the player, the interval is at least ${m.remoteTick} seconds. Logic continues using accumulated time.`, value: `${m.remoteDistance} px · ${m.remoteTick} s`, links: [localizedExplorationPageLink('world-generation', 'Генерация мира', 'World generation', language)] },
      ] },
    ],
    related: [localizedOptimizationPageLink('production-lines', 'Анализ производственных линий', 'Production-line analysis', language), localizedOptimizationPageLink('machine-modules', 'Модули машин', 'Machine modules', language), localizedWikiPageLink('systems/power', 'Энергосистема', 'Power system', language, 'power')],
  };
}


function optimizationProductionLinesContent(language) {
  const m = optimizationMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Железная линия' : 'Iron line', value: `${m.ironRate} ${language === 'ru' ? 'слитков/мин' : 'ingots/min'}` },
      { label: language === 'ru' ? 'Исследовательская линия' : 'Research line', value: `${m.researchRate} ${language === 'ru' ? 'пакетов/мин' : 'packs/min'}` },
      { label: language === 'ru' ? 'Стальная линия' : 'Steel line', value: `${m.steelRate} ${language === 'ru' ? 'плит/мин' : 'plates/min'}` },
      { label: language === 'ru' ? 'Обновление HUD' : 'HUD refresh', value: '1 s' },
    ],
    sections: [
      { title: language === 'ru' ? 'Три распознаваемые цепочки' : 'Three recognized chains', intro: language === 'ru' ? 'Анализатор строит граф размещённых блоков по фактическим соединениям конвейеров, разветвителей и манипуляторов.' : 'The analyzer builds a graph of placed blocks using actual conveyor, splitter, and inserter connections.', entries: [
        { title: language === 'ru' ? 'Железо' : 'Iron', text: language === 'ru' ? 'Нужны паровая дробилка, паровая печь, выходной сундук и минимум два манипулятора в одной связной логистической компоненте.' : 'Requires a Steam Crusher, Steam Furnace, output chest, and at least two inserters in one connected logistics component.', value: `${m.ironRate} ${language === 'ru' ? 'слитков/мин' : 'ingots/min'}`, links: [localizedMechanicItem('steam_crusher', language), localizedMechanicItem('steam_furnace', language)] },
        { title: language === 'ru' ? 'Паровые исследования' : 'Steam research', text: language === 'ru' ? 'Нужны два паровых сборщика с рецептами исследовательского ядра и научного пакета, сундук и минимум два манипулятора.' : 'Requires two Steam Assemblers configured for the research core and science pack, a chest, and at least two inserters.', value: `${m.researchRate} ${language === 'ru' ? 'пакетов/мин' : 'packs/min'}`, links: [localizedMechanicItem('steam_assembler', language)] },
        { title: language === 'ru' ? 'Сталь' : 'Steel', text: language === 'ru' ? 'Нужны коксовая печь, примитивная доменная печь, паровой пресс, сундук и минимум три манипулятора.' : 'Requires a Coke Oven, Primitive Blast Furnace, Steam Press, chest, and at least three inserters.', value: `${m.steelRate} ${language === 'ru' ? 'плит/мин' : 'plates/min'}`, links: [localizedMechanicItem('coke_oven', language), localizedMechanicItem('primitive_blast_furnace', language), localizedMechanicItem('steam_press', language)] },
      ] },
      { title: language === 'ru' ? 'Поиск узкого места' : 'Bottleneck detection', intro: language === 'ru' ? 'После проверки состава и связности анализатор читает живую телеметрию каждой ключевой машины.' : 'After validating composition and connectivity, the analyzer reads live telemetry from each key machine.', entries: [
        { title: language === 'ru' ? 'Логистика' : 'Logistics', text: language === 'ru' ? 'Отдельно обнаруживаются разрыв цепи, затор конвейера и заблокированный выход манипулятора.' : 'Disconnected chains, conveyor jams, and blocked inserter destinations are detected separately.', value: language === 'ru' ? 'Разрыв · затор · блокировка' : 'Disconnect · jam · blockage', links: [localizedWikiPageLink('systems/logistics', 'Предметная логистика', 'Item logistics', language, 'logistics')] },
        { title: language === 'ru' ? 'Ресурсы процесса' : 'Process resources', text: language === 'ru' ? 'Панель указывает отсутствие пара, топлива или входных компонентов и отличает ожидание промежуточного продукта от забитого выхода.' : 'The panel reports missing steam, fuel, or inputs and distinguishes waiting for an intermediate product from blocked output.', value: language === 'ru' ? 'Точная причина' : 'Specific reason', links: [localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language)] },
        { title: language === 'ru' ? 'Возврат креозота' : 'Creosote recovery', text: language === 'ru' ? 'Для стальной цепочки дополнительно проверяется путь жидкости от коксовой печи к резервуару и паровому котлу.' : 'For the steel chain, the analyzer also checks the fluid path from Coke Oven to a tank and Steam Boiler.', value: language === 'ru' ? 'Печь → бак → котёл' : 'Oven → tank → boiler', links: [localizedWikiPageLink('fluids/creosote', 'Креозот', 'Creosote', language, 'creosote')] },
      ] },
    ],
    related: [localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language), localizedOptimizationPageLink('assembler-coordination', 'Координация сборщиков', 'Assembler coordination', language), localizedWikiPageLink('systems/logistics', 'Предметная логистика', 'Item logistics', language, 'logistics')],
  };
}


function localizedOptimization(guide, language) {
  const content = {
    'machine-modules': optimizationModulesContent,
    'output-control': optimizationOutputControlContent,
    'stock-control': optimizationStockControlContent,
    'assembler-coordination': optimizationAssemblerContent,
    'factory-diagnostics': optimizationDiagnosticsContent,
    'production-lines': optimizationProductionLinesContent,
  }[guide.id](language);
  const index = optimizationDefinitions.indexOf(guide);
  return {
    ...localizedOptimizationSummary(guide, language),
    ...content,
    previous: index > 0 ? localizedOptimizationSummary(optimizationDefinitions[index - 1], language) : null,
    next: index < optimizationDefinitions.length - 1 ? localizedOptimizationSummary(optimizationDefinitions[index + 1], language) : null,
  };
}


function localizedMultiplayerSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedMultiplayerPageLink(id, titleRu, titleEn, language) {
  return localizedWikiPageLink(`multiplayer/${encodeURIComponent(id)}`, titleRu, titleEn, language, id);
}


function multiplayerHostingContent(language) {
  const m = multiplayerMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Игровой UDP-порт' : 'Game UDP port', value: String(m.gamePort) },
      { label: language === 'ru' ? 'Порт поиска LAN' : 'LAN discovery port', value: String(m.discoveryPort) },
      { label: language === 'ru' ? 'Игроков в сессии' : 'Players per session', value: String(m.maxPlayers) },
      { label: language === 'ru' ? 'Тайм-аут входа' : 'Join timeout', value: `${m.joinTimeout} s` },
    ],
    sections: [
      { title: language === 'ru' ? 'Создание мира для команды' : 'Opening a world to the team', intro: language === 'ru' ? 'Хост загружает свой мир, задаёт имя сервера и при необходимости пароль; его игра становится источником состояния сессии.' : 'The host loads a local world, chooses a server name and optional password, and becomes the session state authority.', entries: [
        { title: language === 'ru' ? 'Локальная сеть' : 'Local network', text: language === 'ru' ? `Сервер отправляет маяк каждые ${m.beaconInterval} с. Запись показывает имя, адрес, число игроков и наличие пароля и исчезает из списка через ${m.serverTimeout / 1000} с без маяка.` : `The server emits a beacon every ${m.beaconInterval} s. Its entry shows name, address, player count, and lock state, then disappears after ${m.serverTimeout / 1000} s without a beacon.`, value: `${m.beaconInterval} s → ${m.serverTimeout / 1000} s`, links: [] },
        { title: language === 'ru' ? 'Игра через интернет' : 'Internet play', text: language === 'ru' ? 'Хост пытается автоматически пробросить игровой UDP-порт через UPnP. Если роутер это не поддерживает, тот же UDP-порт нужно перенаправить вручную; для LAN проброс не требуется.' : 'The host attempts to map the game UDP port automatically through UPnP. If the router does not support it, forward the same UDP port manually; LAN play needs no forwarding.', value: `UDP ${m.gamePort}`, links: [localizedMultiplayerPageLink('host-world-sync', 'Мир хоста', 'Host world', language)] },
        { title: language === 'ru' ? 'Пароль и безопасность' : 'Password security', text: language === 'ru' ? 'Пароль передаётся по ENet открытым текстом. Он пригоден для доверенной локальной сети, но не обеспечивает безопасную аутентификацию через интернет.' : 'The password is sent as plaintext over ENet. It is suitable for a trusted LAN but does not provide secure authentication over the internet.', value: language === 'ru' ? 'Только доверенная LAN' : 'Trusted LAN only', links: [] },
      ] },
      { title: language === 'ru' ? 'Поиск, вход и возврат' : 'Finding, joining, and returning', intro: language === 'ru' ? 'Клиент может выбрать найденную LAN-сессию либо ввести IP-адрес и порт напрямую.' : 'A client can select a discovered LAN session or enter an IP address and port directly.', entries: [
        { title: language === 'ru' ? 'Совместимость' : 'Compatibility', text: language === 'ru' ? `LAN-маяки с другой версией протокола игнорируются. Текущая версия протокола — ${m.protocolVersion}.` : `LAN beacons with a different protocol version are ignored. The current protocol version is ${m.protocolVersion}.`, value: `v${m.protocolVersion}`, links: [] },
        { title: language === 'ru' ? 'Прямое подключение' : 'Direct connection', text: language === 'ru' ? `Для одного компьютера подходит 127.0.0.1, для LAN — локальный IP хоста, для интернета — его внешний адрес и открытый UDP-порт ${m.gamePort}.` : `Use 127.0.0.1 on one computer, the host’s local IP on a LAN, or the external address and open UDP port ${m.gamePort} over the internet.`, value: `IP:${m.gamePort}`, links: [] },
        { title: language === 'ru' ? 'Переподключение' : 'Reconnect flow', text: language === 'ru' ? 'После непредвиденного обрыва игра ставится на паузу и предлагает повторить вход. Последние IP, порт и пароль сохраняются в памяти до намеренного выхода из сессии.' : 'After an unexpected disconnect, the game pauses and offers to reconnect. The last IP, port, and password remain in memory until a deliberate disconnect.', value: language === 'ru' ? 'Повтор без ввода адреса' : 'Retry without retyping', links: [localizedMultiplayerPageLink('chat-pings', 'Чат и индикатор задержки', 'Chat and latency', language)] },
      ] },
    ],
    related: [localizedWikiPageLink('interface/saves-multiplayer', 'Сохранения и совместная игра', 'Saves and multiplayer', language, 'saves-multiplayer'), localizedMultiplayerPageLink('host-world-sync', 'Мир хоста и синхронизация', 'Host world and synchronization', language), localizedMultiplayerPageLink('chat-pings', 'Чат, команды и метки', 'Chat, commands, and pings', language)],
  };
}


function multiplayerWorldContent(language) {
  const m = multiplayerMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Источник мира' : 'World authority', value: language === 'ru' ? 'Хост' : 'Host' },
      { label: language === 'ru' ? 'Полей первого снимка' : 'Initial snapshot fields', value: '16' },
      { label: language === 'ru' ? 'Общий прогресс' : 'Shared progression', value: `${m.progressionSync} s` },
      { label: language === 'ru' ? 'Файл мира клиента' : 'Client world file', value: language === 'ru' ? 'Не создаётся' : 'Not created' },
    ],
    sections: [
      { title: language === 'ru' ? 'Что присылает хост' : 'What the host sends', intro: language === 'ru' ? 'Перед входом нового участника хост упаковывает живые изменения загруженных чанков и отправляет надёжный начальный снимок.' : 'Before a new peer enters, the host packs live changes from loaded chunks and sends a reliable initial snapshot.', entries: [
        { title: language === 'ru' ? 'Генерация и настройки' : 'Generation and settings', text: language === 'ru' ? 'Сид, имя мира, сложность, богатство ресурсов, плотность растительности и распределение залежей дают клиенту ту же процедурную основу.' : 'Seed, world name, difficulty, resource richness, vegetation density, and deposit distribution give the client the same procedural base.', value: language === 'ru' ? '6 параметров основы' : '6 base parameters', links: [localizedWikiPageLink('exploration/world-generation', 'Генерация мира', 'World generation', language, 'world-generation')] },
        { title: language === 'ru' ? 'Живое состояние' : 'Live state', text: language === 'ru' ? 'Снимок включает поставленные блоки, изменения чанков, время, погоду, лежащие предметы и открытые биомы.' : 'The snapshot includes placed blocks, chunk changes, time, weather, live dropped items, and discovered biomes.', value: language === 'ru' ? 'Мир без ожидания нового сейва' : 'Current world state', links: [localizedMultiplayerPageLink('drops-machines-sync', 'Предметы и машины в сети', 'Networked items and machines', language)] },
        { title: language === 'ru' ? 'Развитие фабрики' : 'Factory progression', text: language === 'ru' ? `Исследованные технологии, побеждённые боссы, открытые рецепты и постоянные допуски в биомы передаются при входе; затем хост проверяет изменения каждые ${m.progressionSync} с.` : `Researched technologies, defeated bosses, unlocked recipes, and permanent biome access arrive on join; the host then checks for changes every ${m.progressionSync} s.`, value: `${m.progressionSync} s`, links: [localizedWikiPageLink('technologies', 'Технологии', 'Technologies', language, 'technologies')] },
      ] },
      { title: language === 'ru' ? 'Личные и локальные данные' : 'Personal and local data', intro: language === 'ru' ? 'Удалённая сессия создаёт временные объекты мира и сохранения только в памяти клиента.' : 'A remote session creates temporary world and save objects only in the client’s memory.', entries: [
        { title: language === 'ru' ? 'Защита сейва' : 'Save protection', text: language === 'ru' ? 'У временного мира нет пути к файлу, включён режим удалённой сессии, а слот сохранения пуст. Поэтому состояние хоста не перезаписывает локальный мир клиента.' : 'The temporary world has no file path, remote-session mode is enabled, and the save slot is blank. Host state therefore cannot overwrite the client’s local world.', value: language === 'ru' ? 'Только память' : 'Memory only', links: [localizedWikiPageLink('interface/saves-multiplayer', 'Сохранения и совместная игра', 'Saves and multiplayer', language, 'saves-multiplayer')] },
        { title: language === 'ru' ? 'Инвентарь при входе' : 'Inventory on join', text: language === 'ru' ? 'Клиент получает новый временный инвентарь и появляется у базы; содержимое его одиночного сохранения в чужую сессию не переносится.' : 'The client receives a fresh temporary inventory and spawns at the base; items from a solo save are not imported into another player’s session.', value: language === 'ru' ? 'Отдельный временный слот' : 'Separate temporary slot', links: [] },
        { title: language === 'ru' ? 'Квесты игрока' : 'Player quests', text: language === 'ru' ? 'Прогресс квестов остаётся личным и загружается по ключу из имени и сида мира хоста.' : 'Quest progress remains personal and is loaded using a key derived from the host world’s name and seed.', value: language === 'ru' ? 'Имя мира + сид' : 'World name + seed', links: [localizedWikiPageLink('quests', 'Квестовая книга', 'Quest book', language, 'quests')] },
      ] },
    ],
    related: [localizedMultiplayerPageLink('hosting-joining', 'Создание и поиск сессии', 'Hosting and joining', language), localizedMultiplayerPageLink('building-mining-sync', 'Строительство и добыча', 'Building and mining', language), localizedWikiPageLink('exploration/time-weather', 'Время и погода', 'Time and weather', language, 'time-weather')],
  };
}


function multiplayerBuildingContent(language) {
  return {
    facts: [
      { label: language === 'ru' ? 'Движение игрока' : 'Player movement', value: 'Unreliable ordered' },
      { label: language === 'ru' ? 'Установка блоков' : 'Block placement', value: 'Reliable' },
      { label: language === 'ru' ? 'Урон залежи' : 'Deposit damage', value: 'Unreliable' },
      { label: language === 'ru' ? 'Завершение добычи' : 'Mining completion', value: 'Reliable' },
    ],
    sections: [
      { title: language === 'ru' ? 'Игроки и строительство' : 'Players and construction', intro: language === 'ru' ? 'Каждый участник объявляет имя профиля и регулярно передаёт состояние персонажа; удалённые игроки представлены управляемыми сетью копиями.' : 'Each peer announces the profile name and continuously sends character state; remote players are represented by network-driven puppets.', entries: [
        { title: language === 'ru' ? 'Позиция и анимация' : 'Position and animation', text: language === 'ru' ? 'Частые пакеты движения упорядочены, но не требуют повторной доставки: более новое положение важнее потерянного старого кадра.' : 'Frequent movement packets are ordered but not retransmitted: a newer position matters more than a lost older frame.', value: language === 'ru' ? 'Плавность без очереди старых кадров' : 'No backlog of stale frames', links: [localizedMultiplayerPageLink('chat-pings', 'Имена и задержка', 'Names and latency', language)] },
        { title: language === 'ru' ? 'Установка' : 'Placement', text: language === 'ru' ? 'Координаты якоря, ID блока и направление передаются надёжно, чтобы у всех участников появилась одинаковая конструкция.' : 'Anchor coordinates, block ID, and facing are sent reliably so every peer creates the same structure.', value: language === 'ru' ? 'Якорь · ID · направление' : 'Anchor · ID · facing', links: [localizedWikiPageLink('interface/building-tools', 'Строительство', 'Building', language, 'building-tools')] },
        { title: language === 'ru' ? 'Демонтаж' : 'Removal', text: language === 'ru' ? 'Удаление блока также доставляется надёжно. Состояние содержимого машин отдельно выравнивается механизмом синхронизации фабрики.' : 'Block removal is also delivered reliably. Machine contents are reconciled separately by factory synchronization.', value: 'Reliable', links: [localizedMultiplayerPageLink('drops-machines-sync', 'Сетевые машины', 'Networked machines', language)] },
      ] },
      { title: language === 'ru' ? 'Совместная разработка залежи' : 'Shared deposit mining', intro: language === 'ru' ? 'Удары всех игроков уменьшают одну логическую шкалу прочности руды на каждом пире.' : 'Hits from every player reduce the same logical ore-health pool on each peer.', entries: [
        { title: language === 'ru' ? 'Промежуточные удары' : 'Intermediate hits', text: language === 'ru' ? 'Сетевое событие содержит мировую клетку и величину урона. Оно отправляется без гарантии доставки, потому что следующий удар быстро обновит состояние.' : 'The event contains the world tile and damage amount. It is sent without delivery guarantees because the next hit quickly advances state.', value: language === 'ru' ? 'Клетка + урон' : 'Tile + damage', links: [localizedWikiPageLink('gathering/ore-deposits', 'Рудные залежи', 'Ore deposits', language, 'ore-deposits')] },
        { title: language === 'ru' ? 'Финальный удар' : 'Final hit', text: language === 'ru' ? 'Событие полного разрушения надёжно передаёт клетку, силу инструмента и его тип, после чего залежь удаляется у остальных игроков.' : 'The completed-mining event reliably sends the tile, tool power, and tool type, then removes the deposit for the other peers.', value: language === 'ru' ? 'Надёжное завершение' : 'Reliable completion', links: [] },
        { title: language === 'ru' ? 'Кому достаётся ресурс' : 'Who gets the resource', text: language === 'ru' ? 'Добыча создаётся у игрока, чей удар завершил разработку. Дальнейший подбор сетевого предмета всё равно решает хост.' : 'The resource is created by the player whose hit completes mining. Pickup of the resulting networked drop is still arbitrated by the host.', value: language === 'ru' ? 'Завершивший удар' : 'Final hitter', links: [localizedMultiplayerPageLink('drops-machines-sync', 'Предметы и машины в сети', 'Networked items and machines', language)] },
      ] },
    ],
    related: [localizedWikiPageLink('interface/building-tools', 'Строительство', 'Building', language, 'building-tools'), localizedWikiPageLink('gathering/manual-mining', 'Ручная добыча', 'Manual mining', language, 'manual-mining'), localizedMultiplayerPageLink('drops-machines-sync', 'Предметы и машины в сети', 'Networked items and machines', language)],
  };
}


function multiplayerDropsMachinesContent(language) {
  const m = multiplayerMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Активное меню' : 'Open-menu sync', value: `${m.machineSync} s` },
      { label: language === 'ru' ? 'Полный снимок машин' : 'Full machine snapshot', value: `${m.machineSnapshot} s` },
      { label: language === 'ru' ? 'Радиус изменения' : 'Edit range', value: `${m.editRangeTiles} ${language === 'ru' ? 'клеток' : 'tiles'}` },
      { label: language === 'ru' ? 'Арбитр подбора' : 'Pickup authority', value: language === 'ru' ? 'Хост' : 'Host' },
    ],
    sections: [
      { title: language === 'ru' ? 'Предметы на земле' : 'Dropped items', intro: language === 'ru' ? 'Каждый сетевой предмет получает уникальный ID из номера пира и локальной последовательности; хост хранит список ещё не поднятых предметов.' : 'Every networked drop receives a unique ID from its peer number and local sequence; the host keeps the list of uncollected drops.', entries: [
        { title: language === 'ru' ? 'Вход в уже идущую игру' : 'Joining an active world', text: language === 'ru' ? 'Список живых предметов входит в начальный снимок мира, поэтому новый участник видит добычу, созданную до его подключения.' : 'The live-drop list is part of the initial world snapshot, so a new peer sees loot created before joining.', value: language === 'ru' ? 'Живые дропы в снимке' : 'Live drops in snapshot', links: [localizedMultiplayerPageLink('host-world-sync', 'Снимок мира хоста', 'Host world snapshot', language)] },
        { title: language === 'ru' ? 'Первый запрос побеждает' : 'First claim wins', text: language === 'ru' ? 'При касании клиент просит хоста выдать предмет. Хост удаляет ID из реестра и сообщает победителя: только его копия попадает в инвентарь, остальные исчезают.' : 'On contact, a client asks the host to grant the item. The host removes its ID and announces the winner: only that copy enters inventory and all others disappear.', value: language === 'ru' ? 'Один ID — один победитель' : 'One ID, one winner', links: [localizedWikiPageLink('exploration/dropped-items', 'Предметы на земле', 'Dropped items', language, 'dropped-items')] },
        { title: language === 'ru' ? 'Устаревший запрос' : 'Stale claim', text: language === 'ru' ? 'Если ID уже неизвестен хосту, всем отправляется подтверждение без победителя, чтобы удалить осиротевшие локальные копии.' : 'If the host no longer knows the ID, it sends a claim with no winner so every peer removes orphaned local copies.', value: language === 'ru' ? 'Очистка у всех' : 'Cleanup for all peers', links: [] },
      ] },
      { title: language === 'ru' ? 'Состояние машин' : 'Machine state', intro: language === 'ru' ? 'Машины симулируются локально, а хост периодически задаёт каноническое состояние и проверяет запросы клиентов.' : 'Machines simulate locally, while the host periodically supplies canonical state and validates client requests.', entries: [
        { title: language === 'ru' ? 'Открытое меню' : 'Open menu', text: language === 'ru' ? `При открытии клиент сразу запрашивает свежие данные. Пока меню активно, состояние блока передаётся каждые ${m.machineSync} с; для ME-терминала дополнительно рассылается его сеть.` : `On open, a client immediately requests fresh data. While the menu stays active, block state is sent every ${m.machineSync} s; an ME terminal also sends its network.`, value: `${m.machineSync} s`, links: [localizedWikiPageLink('systems/me-network', 'ME-хранилище', 'ME storage', language, 'me-network')] },
        { title: language === 'ru' ? 'Периодическая сверка' : 'Periodic reconciliation', text: language === 'ru' ? `Раз в ${m.machineSnapshot} с хост отправляет снимок всех поставленных блоков. Текущая открытая машина клиента не затирается таким снимком во время взаимодействия.` : `Every ${m.machineSnapshot} s, the host sends a snapshot of all placed blocks. A client’s currently open machine is not overwritten by that snapshot during interaction.`, value: `${m.machineSnapshot} s`, links: [localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language)] },
        { title: language === 'ru' ? 'Проверка изменений' : 'Change validation', text: language === 'ru' ? `Клиент может менять машину только в пределах ${m.editRangeTiles} клеток. Хост ограничивает уровни модулей и допустимые фильтры, направления и рецепты, затем рассылает принятый вариант.` : `A client may edit a machine only within ${m.editRangeTiles} tiles. The host constrains module-level changes and valid filters, directions, and recipes, then broadcasts the accepted state.`, value: `≤ ${m.editRangeTiles} ${language === 'ru' ? 'клеток' : 'tiles'}`, links: [localizedOptimizationPageLink('machine-modules', 'Модули машин', 'Machine modules', language)] },
      ] },
    ],
    related: [localizedMultiplayerPageLink('building-mining-sync', 'Строительство и добыча', 'Building and mining', language), localizedWikiPageLink('exploration/dropped-items', 'Предметы на земле', 'Dropped items', language, 'dropped-items'), localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language)],
  };
}


function multiplayerChatContent(language) {
  const m = multiplayerMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Сообщение видно' : 'Message hold', value: `${m.fadeDelay} s` },
      { label: language === 'ru' ? 'Затухание' : 'Fade duration', value: `${m.fadeDuration} s` },
      { label: language === 'ru' ? 'Подсказок команд' : 'Visible suggestions', value: String(m.maxSuggestions) },
      { label: language === 'ru' ? 'Жизнь метки' : 'Marker lifetime', value: `${m.mapPingLifetime} s` },
    ],
    sections: [
      { title: language === 'ru' ? 'Чат и команды' : 'Chat and commands', intro: language === 'ru' ? 'Имя в сетевом сообщении берётся из текущего профиля; обычный текст надёжно рассылается остальным участникам.' : 'A network message uses the current profile name, and ordinary text is delivered reliably to the other peers.', entries: [
        { title: language === 'ru' ? 'Открытие и отправка' : 'Open and send', text: language === 'ru' ? 'Enter открывает пустой чат, физическая клавиша / сразу начинает команду. Enter отправляет, Esc закрывает без отправки.' : 'Enter opens an empty chat, while the physical / key starts a command immediately. Enter sends and Esc closes without sending.', value: 'Enter · / · Esc', links: [localizedWikiPageLink('interface/controls', 'Управление', 'Controls', language, 'controls')] },
        { title: language === 'ru' ? 'Автодополнение' : 'Completion', text: language === 'ru' ? `До ${m.maxSuggestions} подходящих команд или ID предметов показываются над полем. Tab применяет вариант, стрелки вверх и вниз меняют выбор.` : `Up to ${m.maxSuggestions} matching commands or item IDs appear above the field. Tab applies a choice, while Up and Down change selection.`, value: `Tab · ↑ · ↓`, links: [] },
        { title: language === 'ru' ? 'Локальные команды' : 'Local commands', text: language === 'ru' ? 'Строки, начинающиеся с /, разбираются системой команд и не отправляются в общий чат как обычное сообщение.' : 'Lines beginning with / are handled by the command system and are not broadcast as ordinary chat messages.', value: language === 'ru' ? 'Не публикуются в чат' : 'Not broadcast to chat', links: [] },
      ] },
      { title: language === 'ru' ? 'Командные метки и задержка' : 'Team markers and latency', intro: language === 'ru' ? 'Alt+ЛКМ в мире или на полноэкранной карте создаёт надёжную общую отметку с именем игрока.' : 'Alt+left-click in the world or fullscreen map creates a reliable shared marker with the player’s name.', entries: [
        { title: language === 'ru' ? 'Метка «смотри сюда»' : '“Look here” marker', text: language === 'ru' ? `Метка появляется в мире и на карте и исчезает через ${m.mapPingLifetime} с. Она работает локально даже без сетевой сессии.` : `The marker appears in the world and on the map, then disappears after ${m.mapPingLifetime} s. It also works locally without a network session.`, value: `Alt+LMB · ${m.mapPingLifetime} s`, links: [localizedWikiPageLink('exploration/map-exploration', 'Карта и разведка', 'Map and exploration', language, 'map-exploration')] },
        { title: language === 'ru' ? 'Индикатор RTT' : 'RTT indicator', text: language === 'ru' ? `Клиент обновляет задержку до хоста каждые ${m.pingUpdate} с. Индикатор скрыт в одиночной игре и у самого хоста.` : `A client refreshes round-trip latency to the host every ${m.pingUpdate} s. The indicator is hidden in solo play and for the host itself.`, value: `${m.pingUpdate} s`, links: [localizedMultiplayerPageLink('hosting-joining', 'Подключение к сессии', 'Joining a session', language)] },
        { title: language === 'ru' ? 'Цветовые пороги' : 'Color thresholds', text: language === 'ru' ? `Зелёный означает меньше ${m.goodPing} мс, жёлтый — от ${m.goodPing} до ${m.warnPing - 1} мс, красный — ${m.warnPing} мс и выше.` : `Green means below ${m.goodPing} ms, yellow covers ${m.goodPing}–${m.warnPing - 1} ms, and red starts at ${m.warnPing} ms.`, value: `<${m.goodPing} · ${m.goodPing}–${m.warnPing - 1} · ≥${m.warnPing} ms`, links: [] },
      ] },
    ],
    related: [localizedMultiplayerPageLink('hosting-joining', 'Создание и поиск сессии', 'Hosting and joining', language), localizedWikiPageLink('interface/controls', 'Управление', 'Controls', language, 'controls'), localizedWikiPageLink('exploration/map-exploration', 'Карта и разведка', 'Map and exploration', language, 'map-exploration')],
  };
}


function localizedMultiplayer(guide, language) {
  const content = {
    'hosting-joining': multiplayerHostingContent,
    'host-world-sync': multiplayerWorldContent,
    'building-mining-sync': multiplayerBuildingContent,
    'drops-machines-sync': multiplayerDropsMachinesContent,
    'chat-pings': multiplayerChatContent,
  }[guide.id](language);
  const index = multiplayerDefinitions.indexOf(guide);
  return {
    ...localizedMultiplayerSummary(guide, language),
    ...content,
    previous: index > 0 ? localizedMultiplayerSummary(multiplayerDefinitions[index - 1], language) : null,
    next: index < multiplayerDefinitions.length - 1 ? localizedMultiplayerSummary(multiplayerDefinitions[index + 1], language) : null,
  };
}


function localizedEnergySummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedEnergyPageLink(id, titleRu, titleEn, language) {
  return localizedWikiPageLink(`energy/${encodeURIComponent(id)}`, titleRu, titleEn, language, id);
}


function energyGenerationContent(language) {
  const m = energyMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Угольный генератор' : 'Coal Generator', value: `${m.coalRate} EU/s` },
      { label: language === 'ru' ? 'Паровая турбина' : 'Steam Turbine', value: `${m.turbineRate} EU/s` },
      { label: language === 'ru' ? 'Цена энергии турбины' : 'Turbine conversion', value: `${m.turbineEuPerLiter} EU/L` },
      { label: language === 'ru' ? 'Буфер пара' : 'Steam buffer', value: `${m.turbineBuffer} L` },
    ],
    sections: [
      { title: language === 'ru' ? 'Твёрдое топливо' : 'Solid fuel', intro: language === 'ru' ? 'Угольный генератор запускает новый предмет топлива только тогда, когда соединённой сети требуется энергия.' : 'The Coal Generator starts a new fuel item only when its connected grid needs energy.', entries: [
        { title: language === 'ru' ? 'Уголь и угольная пыль' : 'Coal and Coal Dust', text: language === 'ru' ? `Одна единица горит ${m.fuels.coal} с и даёт до ${m.coalRate * m.fuels.coal} EU. Пыль имеет ту же продолжительность.` : `One unit burns for ${m.fuels.coal} s and yields up to ${m.coalRate * m.fuels.coal} EU. Coal Dust has the same duration.`, value: `${m.fuels.coal} s · ${m.coalRate * m.fuels.coal} EU`, links: [localizedMechanicItem('coal', language), localizedMechanicItem('coal_dust', language)] },
        { title: language === 'ru' ? 'Кокс и коксовая пыль' : 'Coke and Coke Dust', text: language === 'ru' ? `Кокс горит ${m.fuels.coke} с — вдвое дольше угля — и выдаёт до ${m.coalRate * m.fuels.coke} EU на предмет.` : `Coke burns for ${m.fuels.coke} s, twice as long as coal, and provides up to ${m.coalRate * m.fuels.coke} EU per item.`, value: `${m.fuels.coke} s · ${m.coalRate * m.fuels.coke} EU`, links: [localizedMechanicItem('coke', language), localizedMechanicItem('coke_dust', language)] },
        { title: language === 'ru' ? 'Угольный блок' : 'Coal Block', text: language === 'ru' ? `Поддерживаемый генератором ID угольного блока даёт ${m.fuels.coal_block} с работы и ${m.coalRate * m.fuels.coal_block} EU — столько же, сколько девять единиц угля. Отдельного предмета с этим ID в текущем каталоге пока нет.` : `The generator-supported Coal Block ID provides ${m.fuels.coal_block} s of operation and ${m.coalRate * m.fuels.coal_block} EU, equal to nine coal items. The current item catalog does not yet contain a separate item with this ID.`, value: `${m.fuels.coal_block} s · ${m.coalRate * m.fuels.coal_block} EU`, links: [localizedMechanicItem('coal', language)] },
      ] },
      { title: language === 'ru' ? 'Энергия из пара' : 'Power from steam', intro: language === 'ru' ? 'Турбина забирает пар только из соседней по стороне жидкостной машины: котла, резервуара или другого совместимого блока.' : 'The turbine pulls steam only from an orthogonally adjacent fluid machine such as a boiler or tank.', entries: [
        { title: language === 'ru' ? 'Подача пара' : 'Steam intake', text: language === 'ru' ? `Внутренний бак заполняется со скоростью до ${m.turbineIntake} L/s. Для полной мощности ${m.turbineRate} EU/s нужно ${m.turbineRate / m.turbineEuPerLiter} L/s, поэтому одна исправная подача успевает пополнять буфер.` : `The internal tank fills at up to ${m.turbineIntake} L/s. Full output of ${m.turbineRate} EU/s consumes ${m.turbineRate / m.turbineEuPerLiter} L/s, so one healthy intake can refill the buffer.`, value: `${m.turbineIntake} L/s in · ${m.turbineRate / m.turbineEuPerLiter} L/s used`, links: [localizedMechanicItem('steam_turbine', language), localizedMechanicItem('steam_boiler', language)] },
        { title: language === 'ru' ? 'Выработка по запросу' : 'Demand-driven output', text: language === 'ru' ? 'Турбина отдаёт не больше остатка спроса сети и списывает ровно соответствующий объём пара. Невостребованный пар остаётся в её баке.' : 'The turbine supplies no more than the grid’s remaining demand and consumes exactly the corresponding steam. Unneeded steam stays in its tank.', value: language === 'ru' ? 'Без холостого расхода' : 'No idle consumption', links: [localizedEnergyPageLink('grid-distribution', 'Распределение энергии', 'Power distribution', language)] },
        { title: language === 'ru' ? 'Выбор источника' : 'Choosing a source', text: language === 'ru' ? 'Оба базовых генератора дают одинаковую мощность. Угольный проще поставить, а турбина позволяет продолжить использовать паровую инфраструктуру после электрификации.' : 'Both base generators have the same output. Coal is simpler to deploy, while the turbine keeps steam infrastructure useful after electrification.', value: `${m.coalRate} = ${m.turbineRate} EU/s`, links: [localizedWikiPageLink('systems/fluids', 'Жидкости и пар', 'Fluids and steam', language, 'fluids')] },
      ] },
    ],
    related: [localizedEnergyPageLink('grid-distribution', 'Энергосеть и распределение', 'Power grid and distribution', language), localizedEnergyPageLink('storage', 'Накопители энергии', 'Energy storage', language), localizedWikiPageLink('systems/power', 'Обзор энергосистемы', 'Power-system overview', language, 'power')],
  };
}


function energyGridContent(language) {
  const m = energyMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Типов проводов' : 'Wire types', value: String(m.conductorWireTypes) },
      { label: language === 'ru' ? 'Направлений связи' : 'Connection directions', value: '4' },
      { label: language === 'ru' ? 'Жёлтая зона' : 'Yellow range', value: `< ${Math.round(m.loadedRatio * 100)}%` },
      { label: language === 'ru' ? 'Проверка обучения' : 'Tutorial check', value: `${m.tutorialCheck} s` },
    ],
    sections: [
      { title: language === 'ru' ? 'Как строится сеть' : 'How a grid is formed', intro: language === 'ru' ? 'Менеджер обходит проводники по четырём сторонам и создаёт независимую сеть для каждой несвязанной группы.' : 'The manager flood-fills conductors across four orthogonal directions and creates an independent grid for every disconnected group.', entries: [
        { title: language === 'ru' ? 'Провода' : 'Wires', text: language === 'ru' ? 'Медный и изолированный медный провод передают энергию одинаково. Диагональное касание не соединяет блоки.' : 'Copper Wire and Insulated Copper Wire conduct identically. Diagonal contact does not connect blocks.', value: language === 'ru' ? 'Только общая сторона' : 'Shared side only', links: [localizedMechanicItem('copper_wire', language), localizedMechanicItem('insulated_copper_wire', language)] },
        { title: language === 'ru' ? 'Конвейеры как проводники' : 'Conveyors as conductors', text: language === 'ru' ? 'Любая конвейерная лента продолжает электрическую сеть к соседним лентам. Поэтому длинную линию достаточно подключить проводом в одной точке.' : 'Every conveyor extends the power grid to adjacent belts, so a long line needs only one wired connection.', value: language === 'ru' ? 'Проводник + потребитель' : 'Conductor + consumer', links: [localizedWikiPageLink('systems/logistics', 'Предметная логистика', 'Item logistics', language, 'logistics')] },
        { title: language === 'ru' ? 'Машины на границе' : 'Machines at the edge', text: language === 'ru' ? 'Генератор, накопитель или электрическая машина подключаются, когда стоят сбоку от проводника. Обычная машина не проводит сеть дальше через себя.' : 'A generator, storage block, or powered machine connects when placed beside a conductor. An ordinary machine does not carry the grid through itself.', value: language === 'ru' ? 'Один сосед-проводник' : 'One conductor neighbor', links: [] },
      ] },
      { title: language === 'ru' ? 'Очередь энергии' : 'Energy flow order', intro: language === 'ru' ? 'Каждый тик сеть измеряет свободное место во внутренних буферах машин и доступную скорость зарядки накопителей.' : 'Each tick, the grid measures free room in machine buffers and the storage capacity available at the current charge rate.', entries: [
        { title: language === 'ru' ? '1. Генерация' : '1. Generation', text: language === 'ru' ? 'Генераторы вызываются только при ненулевом спросе и останавливаются, когда суммарная потребность уже закрыта.' : 'Generators are called only for nonzero demand and stop once the combined need has been met.', value: language === 'ru' ? 'Производство по спросу' : 'Demand-driven generation', links: [localizedEnergyPageLink('generation', 'Генераторы и топливо', 'Generators and fuel', language)] },
        { title: language === 'ru' ? '2. Потребители' : '2. Consumers', text: language === 'ru' ? 'Сначала EU распределяются между машинами пропорционально свободному месту в их буферах. Машина с полным буфером ничего не получает.' : 'EU first go to machines in proportion to free room in their buffers. A machine with a full buffer receives nothing.', value: language === 'ru' ? 'Пропорционально свободному месту' : 'Proportional to free room', links: [localizedOptimizationPageLink('machine-modules', 'Модули машин', 'Machine modules', language)] },
        { title: language === 'ru' ? '3. Резерв' : '3. Reserve', text: language === 'ru' ? 'Излишек заряжает накопители. Если генерации не хватило потребителям, накопители сначала покрывают остаток дефицита и лишь затем энергия доставляется машинам.' : 'Surplus charges storage. When generation cannot fill consumer buffers, storage first covers the remaining deficit before energy is delivered.', value: language === 'ru' ? 'Потребители → заряд / разряд → доставка' : 'Consumers → charge/discharge → delivery', links: [localizedEnergyPageLink('storage', 'Накопители энергии', 'Energy storage', language)] },
      ] },
    ],
    related: [localizedEnergyPageLink('generation', 'Генераторы и топливо', 'Generators and fuel', language), localizedEnergyPageLink('storage', 'Накопители энергии', 'Energy storage', language), localizedEnergyPageLink('diagnostics', 'Диагностика энергосети', 'Power-grid diagnostics', language)],
  };
}


function energyStorageContent(language) {
  const m = energyMechanics;
  const capacities = m.storageCapacities;
  const io = m.storageIo;
  const format = (value) => value.toLocaleString(language === 'ru' ? 'ru-RU' : 'en-US');
  return {
    facts: [
      { label: 'T1', value: `${format(capacities[0])} EU · ${format(io[0])} EU/s` },
      { label: 'T2', value: `${format(capacities[1])} EU · ${format(io[1])} EU/s` },
      { label: 'T3', value: `${format(capacities[2])} EU · ${format(io[2])} EU/s` },
      { label: language === 'ru' ? 'Направления I/O' : 'I/O directions', value: language === 'ru' ? 'Заряд и разряд' : 'Charge and discharge' },
    ],
    sections: [
      { title: language === 'ru' ? 'Три уровня накопителей' : 'Three storage tiers', intro: language === 'ru' ? 'Каждый уровень увеличивает не только полный запас EU, но и максимальную скорость ввода и вывода.' : 'Every tier increases both total EU capacity and the maximum input/output rate.', entries: [
        { title: 'T1', text: language === 'ru' ? `Хранит ${format(capacities[0])} EU и принимает или отдаёт не более ${format(io[0])} EU/s. Подходит для первой небольшой фабрики.` : `Stores ${format(capacities[0])} EU and accepts or supplies at most ${format(io[0])} EU/s. Suitable for an early small factory.`, value: `${format(capacities[0])} / ${format(io[0])}`, links: [localizedMechanicItem('energy_storage_t1', language)] },
        { title: 'T2', text: language === 'ru' ? `Ёмкость возрастает в ${capacities[1] / capacities[0]} раз, а пропускная способность — в ${io[1] / io[0]} раза относительно T1.` : `Capacity grows by ${capacities[1] / capacities[0]}× and throughput by ${io[1] / io[0]}× over T1.`, value: `${format(capacities[1])} / ${format(io[1])}`, links: [localizedMechanicItem('energy_storage_t2', language)] },
        { title: 'T3', text: language === 'ru' ? `Финальный накопитель содержит ${format(capacities[2])} EU и способен покрывать до ${format(io[2])} EU/s дефицита.` : `The final storage tier holds ${format(capacities[2])} EU and can cover up to ${format(io[2])} EU/s of deficit.`, value: `${format(capacities[2])} / ${format(io[2])}`, links: [localizedMechanicItem('energy_storage_t3', language)] },
      ] },
      { title: language === 'ru' ? 'Планирование резерва' : 'Planning reserve power', intro: language === 'ru' ? 'Большая ёмкость бесполезна, если ограничение I/O ниже текущего дефицита сети.' : 'Large capacity cannot help fully when the I/O limit is below the grid’s current deficit.', entries: [
        { title: language === 'ru' ? 'Время автономной работы' : 'Backup runtime', text: language === 'ru' ? 'При постоянном дефиците время работы равно запасу EU, делённому на дефицит в EU/с, пока требуемая мощность не превышает максимальный вывод.' : 'At a constant deficit, runtime equals stored EU divided by deficit in EU/s, provided the required power does not exceed maximum output.', value: language === 'ru' ? 'секунды = EU ÷ EU/с' : 'seconds = EU ÷ EU/s', links: [localizedEnergyPageLink('diagnostics', 'Измерение дефицита', 'Measuring deficit', language)] },
        { title: language === 'ru' ? 'Пример для T1' : 'T1 example', text: language === 'ru' ? `Полный T1 при нагрузке 100 EU/с поддерживает фабрику ${format(capacities[0] / 100)} с. При дефиците 200 EU/с он всё равно отдаст максимум ${io[0]} EU/с.` : `A full T1 sustains a 100 EU/s load for ${format(capacities[0] / 100)} s. At a 200 EU/s deficit it still supplies only ${io[0]} EU/s.`, value: `${format(capacities[0] / 100)} s @ 100 EU/s`, links: [] },
        { title: language === 'ru' ? 'Несколько накопителей' : 'Multiple storage blocks', text: language === 'ru' ? 'Ёмкость и доступная скорость нескольких блоков складываются в пределах одной сети. Разделённые проводами сети не делятся резервом.' : 'Capacity and available transfer rate add within one grid. Disconnected grids do not share reserve power.', value: language === 'ru' ? 'Только общая сеть' : 'Same grid only', links: [localizedEnergyPageLink('grid-distribution', 'Структура энергосети', 'Power-grid structure', language)] },
      ] },
    ],
    related: [localizedEnergyPageLink('grid-distribution', 'Энергосеть и распределение', 'Power grid and distribution', language), localizedEnergyPageLink('solar-weather', 'Солнечная энергия и погода', 'Solar power and weather', language), localizedEnergyPageLink('diagnostics', 'Диагностика энергосети', 'Power-grid diagnostics', language)],
  };
}


function energySolarContent(language) {
  const m = energyMechanics;
  const rates = m.solarRates;
  const tierNames = language === 'ru' ? ['Базовая', 'Продвинутая', 'Элитная', 'Ультимативная', 'Квантовая'] : ['Basic', 'Advanced', 'Elite', 'Ultimate', 'Quantum'];
  const itemIds = ['solar_panel', 'advanced_solar_panel', 'elite_solar_panel', 'ultimate_solar_panel', 'quantum_solar_panel'];
  return {
    facts: [
      { label: language === 'ru' ? 'Уровней панелей' : 'Panel tiers', value: String(rates.length) },
      { label: language === 'ru' ? 'Диапазон мощности' : 'Output range', value: `${rates[0]}–${rates.at(-1)} EU/s` },
      { label: language === 'ru' ? 'Внутренний запас' : 'Internal reserve', value: `${m.solarBufferSeconds} s` },
      { label: language === 'ru' ? 'Дождь / гроза' : 'Rain / storm', value: `${m.solarFactors[1] * 100}% / ${m.solarFactors[2] * 100}%` },
    ],
    sections: [
      { title: language === 'ru' ? 'Линейка панелей' : 'Panel progression', intro: language === 'ru' ? 'Каждый следующий уровень утраивает номинальную выработку и ёмкость собственного буфера.' : 'Each successive tier triples nominal output and its own internal buffer capacity.', entries: rates.map((rate, index) => ({
        title: `${tierNames[index]} · T${index + 1}`,
        text: language === 'ru' ? `Номинал ${rate} EU/с, внутренний запас ${rate * m.solarBufferSeconds} EU. Панель копит энергию даже без подключённой сети, пока буфер не заполнен.` : `Rated at ${rate} EU/s with an internal reserve of ${rate * m.solarBufferSeconds} EU. The panel accumulates energy even while disconnected until its buffer is full.`,
        value: `${rate} EU/s · ${rate * m.solarBufferSeconds} EU`,
        links: [localizedMechanicItem(itemIds[index], language)],
      })) },
      { title: language === 'ru' ? 'Погода и фактическая выработка' : 'Weather and actual output', intro: language === 'ru' ? 'Текущая реализация умножает выработку только на состояние погоды; отдельного ночного множителя у панелей нет.' : 'The current implementation multiplies output only by weather state; solar panels have no separate night-time modifier.', entries: [
        { title: language === 'ru' ? 'Ясно' : 'Clear', text: language === 'ru' ? 'Панель работает на полном номинале и заполняет 30-секундный буфер за 30 секунд, если сеть не забирает энергию.' : 'A panel runs at full rating and fills its 30-second buffer in 30 seconds when the grid draws no energy.', value: `${m.solarFactors[0] * 100}%`, links: [localizedWikiPageLink('exploration/time-weather', 'Время и погода', 'Time and weather', language, 'time-weather')] },
        { title: language === 'ru' ? 'Дождь' : 'Rain', text: language === 'ru' ? `Выработка падает до ${m.solarFactors[1] * 100}% номинала. Запас в панели сглаживает переход, пока не исчерпается.` : `Output falls to ${m.solarFactors[1] * 100}% of rating. Stored panel energy smooths the transition until depleted.`, value: `×${m.solarFactors[1]}`, links: [] },
        { title: language === 'ru' ? 'Гроза' : 'Storm', text: language === 'ru' ? `Выработка составляет ${m.solarFactors[2] * 100}% номинала. Гроза заменяет обычный дождь с вероятностью ${m.stormChance * 100}% при начале осадков.` : `Output is ${m.solarFactors[2] * 100}% of rating. A storm replaces ordinary rain with a ${m.stormChance * 100}% chance when precipitation begins.`, value: `×${m.solarFactors[2]} · ${m.stormChance * 100}%`, links: [localizedEnergyPageLink('storage', 'Резерв на непогоду', 'Weather reserve', language)] },
      ] },
    ],
    related: [localizedWikiPageLink('exploration/time-weather', 'Время и погода', 'Time and weather', language, 'time-weather'), localizedEnergyPageLink('storage', 'Накопители энергии', 'Energy storage', language), localizedEnergyPageLink('diagnostics', 'Диагностика энергосети', 'Power-grid diagnostics', language)],
  };
}


function energyDiagnosticsContent(language) {
  const m = energyMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Соединение' : 'Connection', value: language === 'ru' ? 'По сторонам' : 'Orthogonal' },
      { label: language === 'ru' ? 'Распределение' : 'Distribution', value: language === 'ru' ? 'Автоматическое' : 'Automatic' },
      { label: language === 'ru' ? 'Порог дефицита' : 'Deficit threshold', value: `> ${m.healthyDeficit} EU` },
      { label: language === 'ru' ? 'Рекомендуемый запас' : 'Recommended headroom', value: `≥ ${Math.round((m.loadedRatio - 1) * 100)}%` },
    ],
    sections: [
      { title: language === 'ru' ? 'Проверка без отдельного окна' : 'Checking without a separate window', intro: language === 'ru' ? 'Смотрите состояние конкретной машины и проверяйте линию от потребителя к источнику.' : 'Inspect the machine itself and follow its connection back to the power source.', entries: [
        { title: language === 'ru' ? 'Непрерывность' : 'Continuity', text: language === 'ru' ? 'Провода и конвейеры проводят ток только через общую сторону. Диагональное касание сеть не соединяет.' : 'Wires and conveyors conduct power only through a shared side. Diagonal contact does not connect a grid.', value: language === 'ru' ? 'Проверить линию' : 'Check the line', links: [localizedEnergyPageLink('grid-distribution', 'Как строится сеть', 'How grids are formed', language)] },
        { title: language === 'ru' ? 'Источник' : 'Source', text: language === 'ru' ? 'Проверьте топливо генератора, запас пара турбины или погоду для солнечной панели.' : 'Check generator fuel, turbine steam, or solar-panel weather conditions.', value: language === 'ru' ? 'Есть ли генерация' : 'Verify generation', links: [localizedEnergyPageLink('generation', 'Генераторы и топливо', 'Generators and fuel', language)] },
        { title: language === 'ru' ? 'Нагрузка' : 'Load', text: language === 'ru' ? `Оставляйте не менее ${Math.round((m.loadedRatio - 1) * 100)}% запаса генерации или добавляйте накопитель для пиков.` : `Keep at least ${Math.round((m.loadedRatio - 1) * 100)}% generation headroom or add storage for demand spikes.`, value: `≥ ${Math.round((m.loadedRatio - 1) * 100)}%`, links: [localizedEnergyPageLink('storage', 'Накопители энергии', 'Energy storage', language)] },
      ] },
      { title: language === 'ru' ? 'Поиск причины остановки' : 'Finding the cause of a stop', intro: language === 'ru' ? 'Проверяйте соединение, источник, накопитель и только затем сам рецепт машины.' : 'Check the connection, source, storage, and finally the machine recipe.', entries: [
        { title: language === 'ru' ? 'Разрыв сети' : 'Disconnected grid', text: language === 'ru' ? 'Проследите непрерывную цепь общих сторон от машины до генератора или накопителя.' : 'Trace an uninterrupted chain of shared sides from the machine to a generator or storage block.', value: language === 'ru' ? 'Проверить непрерывность' : 'Check continuity', links: [localizedEnergyPageLink('grid-distribution', 'Как строится сеть', 'How grids are formed', language)] },
        { title: language === 'ru' ? 'Недостаток генерации' : 'Insufficient generation', text: language === 'ru' ? 'Красная сеть с пустыми накопителями требует дополнительного источника или снижения нагрузки. У топлива, пара и солнечной погоды разные причины нулевой выдачи.' : 'A red grid with empty storage needs another source or lower load. Fuel, steam, and solar weather each have distinct causes of zero or reduced output.', value: language === 'ru' ? 'Источник или нагрузка' : 'Source or load', links: [localizedEnergyPageLink('generation', 'Генераторы и топливо', 'Generators and fuel', language)] },
        { title: language === 'ru' ? 'Ограничение накопителя' : 'Storage bottleneck', text: language === 'ru' ? 'Даже заполненный накопитель не спасает сеть, если его разрешённый вывод за текущий тик меньше недостающей энергии. Добавьте параллельный накопитель более высокого уровня или снизьте пиковую нагрузку.' : 'Even full storage cannot save a grid when its allowed output for the current tick is below the missing energy. Add parallel higher-tier storage or reduce peak load.', value: language === 'ru' ? 'Увеличить суммарный I/O' : 'Increase combined I/O', links: [localizedEnergyPageLink('storage', 'Накопители энергии', 'Energy storage', language)] },
      ] },
    ],
    related: [localizedEnergyPageLink('grid-distribution', 'Энергосеть и распределение', 'Power grid and distribution', language), localizedEnergyPageLink('generation', 'Генераторы и топливо', 'Generators and fuel', language), localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language)],
  };
}


function localizedEnergy(guide, language) {
  const content = {
    generation: energyGenerationContent,
    'grid-distribution': energyGridContent,
    storage: energyStorageContent,
    'solar-weather': energySolarContent,
    diagnostics: energyDiagnosticsContent,
  }[guide.id](language);
  const index = energyDefinitions.indexOf(guide);
  return {
    ...localizedEnergySummary(guide, language),
    ...content,
    previous: index > 0 ? localizedEnergySummary(energyDefinitions[index - 1], language) : null,
    next: index < energyDefinitions.length - 1 ? localizedEnergySummary(energyDefinitions[index + 1], language) : null,
  };
}


function localizedLogisticsSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedLogisticsPageLink(id, titleRu, titleEn, language) {
  return localizedWikiPageLink(`logistics/${encodeURIComponent(id)}`, titleRu, titleEn, language, id);
}


function logisticsConveyorContent(language) {
  const m = logisticsMechanics;
  const fastest = m.belts.at(-1);
  return {
    facts: [
      { label: language === 'ru' ? 'Уровней лент' : 'Belt tiers', value: String(m.belts.length) },
      { label: language === 'ru' ? 'Время на клетку' : 'Tile crossing time', value: `${m.belts[0].crossTime}–${fastest.crossTime} s` },
      { label: language === 'ru' ? 'Расход энергии' : 'Power draw', value: '0–5 EU/s' },
      { label: language === 'ru' ? 'Предметов на клетке' : 'Stacks per tile', value: '1' },
    ],
    sections: [
      { title: language === 'ru' ? 'Пять уровней' : 'Five tiers', intro: language === 'ru' ? 'Лента несёт один стек через клетку и передаёт его следующему блоку. Теоретическая частота рассчитана для непрерывной подачи и свободного приёмника.' : 'A belt carries one stack across its tile and hands it to the next block. Theoretical frequency assumes continuous input and an available destination.', entries: m.belts.map((belt) => ({
        title: `T${belt.tier}`,
        text: belt.tier === 1
          ? (language === 'ru' ? `Механическая лента проходит клетку за ${belt.crossTime} с и работает без EU.` : `The mechanical belt crosses one tile in ${belt.crossTime} s and requires no EU.`)
          : (language === 'ru' ? `Проходит клетку за ${belt.crossTime} с и постоянно расходует ${belt.power} EU/с, даже когда пуста.` : `Crosses a tile in ${belt.crossTime} s and continuously draws ${belt.power} EU/s, even while empty.`),
        value: `${(60 / belt.crossTime).toFixed(1)} ${language === 'ru' ? 'передач/мин' : 'handoffs/min'} · ${belt.power} EU/s`,
        links: [localizedMechanicItem(belt.id, language)],
      })) },
      { title: language === 'ru' ? 'Передача между блоками' : 'Block-to-block handoff', intro: language === 'ru' ? 'После достижения конца клетки стек остаётся на ленте, пока следующий блок не примет его полностью или частично.' : 'After reaching the end of a tile, the stack stays on the belt until the next block accepts it fully or partially.', entries: [
        { title: language === 'ru' ? 'Допустимые приёмники' : 'Valid destinations', text: language === 'ru' ? 'Лента передаёт стек другой ленте, входному порту бура, сундуку или подходящему входному слоту машины.' : 'A belt can hand a stack to another belt, a drill input port, a chest, or a compatible machine input slot.', value: language === 'ru' ? 'Лента · бур · сундук · машина' : 'Belt · drill · chest · machine', links: [localizedWikiPageLink('machines', 'Каталог техники', 'Machine catalog', language, 'machines')] },
        { title: language === 'ru' ? 'Поворот предмета' : 'Turning items', text: language === 'ru' ? 'При боковой подаче изображение стека движется к центру клетки, затем поворачивает в направление ленты. Направление выхода всегда задаёт ориентация блока.' : 'With side input, the stack visual moves to the tile center and then turns toward belt facing. Block orientation always defines output direction.', value: language === 'ru' ? 'Вход → центр → выход' : 'Input → center → output', links: [localizedWikiPageLink('interface/building-tools', 'Поворот построек', 'Rotating buildings', language, 'building-tools')] },
        { title: language === 'ru' ? 'Затор' : 'Jam', text: language === 'ru' ? `Если приёмник не забирает стек, прогресс остаётся на 100%. Через ${m.beltJamVisualDelay} с появляется визуальный признак затора; без питания он сбрасывается, потому что лента просто остановлена.` : `If the destination rejects the stack, progress stays at 100%. A jam marker appears after ${m.beltJamVisualDelay} s; without power it clears because the belt is merely stopped.`, value: `${m.beltJamVisualDelay} s`, links: [localizedLogisticsPageLink('logistics-diagnostics', 'Диагностика логистики', 'Logistics diagnostics', language)] },
      ] },
    ],
    related: [localizedLogisticsPageLink('inserters', 'Механические манипуляторы', 'Mechanical inserters', language), localizedLogisticsPageLink('filters-splitters', 'Фильтры и разветвители', 'Filters and splitters', language), localizedEnergyPageLink('grid-distribution', 'Энергосеть', 'Power grid', language)],
  };
}


function logisticsInsertersContent(language) {
  const m = logisticsMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Интервал передачи' : 'Transfer interval', value: `${m.inserterInterval} s` },
      { label: language === 'ru' ? 'Максимальная частота' : 'Maximum rate', value: `${60 / m.inserterInterval} ${language === 'ru' ? 'предм./мин' : 'items/min'}` },
      { label: language === 'ru' ? 'Размер переноса' : 'Transfer size', value: '1' },
      { label: language === 'ru' ? 'Лимит фильтра' : 'Filter limit', value: String(m.inserterFilterLimit) },
    ],
    sections: [
      { title: language === 'ru' ? 'Направление работы' : 'Working direction', intro: language === 'ru' ? 'Манипулятор читает блок позади себя и передаёт предмет в блок перед собой относительно текущего направления.' : 'An inserter reads the block behind it and sends an item to the block ahead according to its facing.', entries: [
        { title: language === 'ru' ? 'Источники' : 'Sources', text: language === 'ru' ? 'Из сундука выбирается первая разрешённая доступная ячейка, с ленты снимается один предмет текущего стека, а у машины читаются только слоты OUTPUT.' : 'A chest supplies the first allowed available slot, a belt supplies one item from its carried stack, and a machine exposes only OUTPUT slots.', value: language === 'ru' ? 'Сундук · лента · выход машины' : 'Chest · belt · machine output', links: [localizedMechanicItem('mechanical_inserter', language)] },
        { title: language === 'ru' ? 'Приёмники' : 'Destinations', text: language === 'ru' ? 'Целью может быть лента, сундук или подходящий входной слот машины. Если предмет не помещается, манипулятор удерживает его до следующей попытки.' : 'The target may be a belt, chest, or compatible machine input slot. If the item does not fit, the inserter holds it until the next attempt.', value: language === 'ru' ? 'Предмет не теряется' : 'Item is retained', links: [] },
        { title: language === 'ru' ? 'Производительность' : 'Throughput', text: language === 'ru' ? `За один цикл переносится ровно один предмет. Без задержек источника и приёмника предел составляет ${60 / m.inserterInterval} предметов в минуту.` : `Exactly one item moves per cycle. With no source or destination delay, the limit is ${60 / m.inserterInterval} items per minute.`, value: `${60 / m.inserterInterval}/min`, links: [localizedOptimizationPageLink('production-lines', 'Анализ линий', 'Production-line analysis', language)] },
      ] },
      { title: language === 'ru' ? 'Состояния и управление' : 'States and controls', intro: language === 'ru' ? 'Интерфейс различает причины простоя, поэтому отсутствие работы не всегда означает поломку.' : 'The interface distinguishes idle reasons, so inactivity does not always mean a fault.', entries: [
        { title: language === 'ru' ? 'Ожидание источника' : 'Waiting for source', text: language === 'ru' ? 'Источник отсутствует или не содержит разрешённых предметов. При активном фильтре отдельно показывается ожидание совпадающего предмета.' : 'The source is absent or has no allowed item. With an active filter, waiting for a matching item is reported separately.', value: language === 'ru' ? 'Пусто или фильтр' : 'Empty or filtered', links: [localizedLogisticsPageLink('filters-splitters', 'Настройка фильтров', 'Filter configuration', language)] },
        { title: language === 'ru' ? 'Приёмник заблокирован' : 'Destination blocked', text: language === 'ru' ? 'Если манипулятор уже держит предмет, но не отдаёт его, проверьте свободное место и совместимость цели.' : 'If an inserter is holding an item but cannot release it, check destination space and compatibility.', value: language === 'ru' ? 'Проверить приёмник' : 'Check destination', links: [localizedLogisticsPageLink('logistics-diagnostics', 'Проверка логистики', 'Logistics checks', language)] },
        { title: language === 'ru' ? 'Отключение' : 'Disabled state', text: language === 'ru' ? 'Манипулятор можно вручную отключить. Состояние, фильтр и направление сохраняются и синхронизируются в совместной игре.' : 'An inserter can be disabled manually. Enabled state, filter, and facing are saved and synchronized in multiplayer.', value: language === 'ru' ? 'Сохраняемая настройка' : 'Persistent setting', links: [localizedMultiplayerPageLink('drops-machines-sync', 'Синхронизация машин', 'Machine synchronization', language)] },
      ] },
    ],
    related: [localizedLogisticsPageLink('conveyor-tiers', 'Уровни конвейеров', 'Conveyor tiers', language), localizedLogisticsPageLink('ingredient-demand', 'Запросы ингредиентов', 'Ingredient demand', language), localizedMechanicItem('mechanical_inserter', language)],
  };
}


function logisticsFiltersContent(language) {
  const m = logisticsMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'ID в фильтре' : 'Filter IDs', value: String(m.beltFilterLimit) },
      { label: language === 'ru' ? 'Режимов фильтра' : 'Filter modes', value: '2' },
      { label: language === 'ru' ? 'Диапазон приоритета' : 'Priority range', value: `${m.beltPriorityMin}…${m.beltPriorityMax}` },
      { label: language === 'ru' ? 'Выходов разветвителя' : 'Splitter outputs', value: String(m.splitterOutputs) },
    ],
    sections: [
      { title: language === 'ru' ? 'Фильтрация потока' : 'Filtering flow', intro: language === 'ru' ? 'Ленты и манипуляторы принимают до 24 уникальных ID; пробелы заменяются подчёркиваниями, регистр приводится к нижнему.' : 'Belts and inserters accept up to 24 unique IDs; spaces become underscores and text is normalized to lowercase.', entries: [
        { title: language === 'ru' ? 'Пустой список' : 'Empty list', text: language === 'ru' ? 'Если фильтр пуст, разрешены все предметы. Это одинаково для ленты и манипулятора.' : 'An empty filter allows every item. This behavior is shared by belts and inserters.', value: language === 'ru' ? 'Разрешить всё' : 'Allow all', links: [] },
        { title: language === 'ru' ? 'Белый список' : 'Allowlist', text: language === 'ru' ? 'В режиме allow принимаются только перечисленные ID. Он подходит для выделенной линии одного компонента.' : 'In allow mode, only listed IDs are accepted. Use it for a dedicated component line.', value: 'allow', links: [localizedLogisticsPageLink('conveyor-tiers', 'Конвейерные линии', 'Conveyor lines', language)] },
        { title: language === 'ru' ? 'Чёрный список' : 'Blocklist', text: language === 'ru' ? 'В режиме block отклоняются перечисленные ID, а все остальные проходят дальше.' : 'In block mode, listed IDs are rejected and every other item may pass.', value: 'block', links: [] },
      ] },
      { title: language === 'ru' ? 'Разветвление 1→2' : '1→2 splitting', intro: language === 'ru' ? 'Разветвитель принимает поток сзади и отправляет его в левый или правый боковой выход.' : 'A splitter receives input from the back and sends it through its left or right side output.', entries: [
        { title: language === 'ru' ? 'Равномерный режим' : 'Round robin', text: language === 'ru' ? 'При равных приоритетах успешные передачи чередуют стороны. Если одна сторона заблокирована, предмет пробует другую.' : 'With equal priorities, successful handoffs alternate sides. If one side is blocked, the item tries the other.', value: language === 'ru' ? 'Лево ↔ право' : 'Left ↔ right', links: [localizedMechanicItem('conveyor_splitter', language)] },
        { title: language === 'ru' ? 'Фильтры выходов' : 'Output filters', text: language === 'ru' ? 'Каждая сторона имеет собственный список разрешённых ID. Пустой список выхода принимает любой предмет, прошедший общий фильтр ленты.' : 'Each side has its own allowed-ID list. An empty output list accepts any item that passed the belt’s main filter.', value: language === 'ru' ? 'Два независимых списка' : 'Two independent lists', links: [] },
        { title: language === 'ru' ? 'Приоритет и спрос' : 'Priority and demand', text: language === 'ru' ? 'Более высокий числовой приоритет проверяется первым. Однако активный выход, запрашивающий текущий предмет, рассматривается раньше пассивного маршрута.' : 'The numerically higher priority is tried first. However, an active output requesting the current item is considered before a passive route.', value: `${m.beltPriorityMin}…${m.beltPriorityMax}`, links: [localizedLogisticsPageLink('ingredient-demand', 'Запросы ингредиентов', 'Ingredient demand', language)] },
      ] },
    ],
    related: [localizedLogisticsPageLink('conveyor-tiers', 'Уровни конвейеров', 'Conveyor tiers', language), localizedLogisticsPageLink('ingredient-demand', 'Запросы ингредиентов', 'Ingredient demand', language), localizedLogisticsPageLink('logistics-diagnostics', 'Диагностика логистики', 'Logistics diagnostics', language)],
  };
}


function logisticsDemandContent(language) {
  const m = logisticsMechanics;
  const capacities = m.ruleCapacities.length === 3 ? m.ruleCapacities : [2, 4, 8];
  return {
    facts: [
      { label: language === 'ru' ? 'Правил склада T1–T3' : 'Warehouse rules T1–T3', value: capacities.join(' / ') },
      { label: language === 'ru' ? 'Целевой запас' : 'Target stock', value: `1–${m.requestTargetMax}` },
      { label: language === 'ru' ? 'Длина маршрута' : 'Route depth', value: `${m.demandMaxNodes} ${language === 'ru' ? 'узлов' : 'nodes'}` },
      { label: language === 'ru' ? 'Срок резерва' : 'Reservation TTL', value: `${m.reservationTtl / 60000} min` },
    ],
    sections: [
      { title: language === 'ru' ? 'Запрашивающий склад' : 'Requester warehouse', intro: language === 'ru' ? 'Правило запроса сравнивает целевой запас с текущим количеством предмета и передаёт остаточный дефицит вверх по направлению конвейеров.' : 'A requester rule compares target stock with the current item count and propagates the remaining shortage upstream through conveyors.', entries: [
        { title: language === 'ru' ? 'Несколько правил' : 'Multiple rules', text: language === 'ru' ? `Сундуки T1, T2 и T3 поддерживают соответственно ${capacities.join(', ')} правил запроса и столько же правил поставщика.` : `T1, T2, and T3 chests support ${capacities.join(', ')} requester rules and the same number of provider rules respectively.`, value: `T1 ${capacities[0]} · T2 ${capacities[1]} · T3 ${capacities[2]}`, links: [localizedWikiPageLink('machines', 'Сундуки', 'Chests', language, 'machines')] },
        { title: language === 'ru' ? 'Расчёт дефицита' : 'Shortage calculation', text: language === 'ru' ? 'Запрашиваемое количество равно цели минус предметы, уже лежащие в складе, и минус подтверждённые предметы в пути.' : 'Requested amount equals target stock minus items already stored and minus reserved items confirmed in transit.', value: language === 'ru' ? 'Цель − склад − в пути' : 'Target − stored − in transit', links: [] },
        { title: language === 'ru' ? 'Граница обхода' : 'Traversal limit', text: language === 'ru' ? `Сигнал проходит не более ${m.demandMaxNodes} лент и разветвителей и не зацикливается на уже посещённых блоках.` : `The signal traverses at most ${m.demandMaxNodes} belts and splitters and does not revisit blocks in a loop.`, value: `≤ ${m.demandMaxNodes}`, links: [localizedLogisticsPageLink('filters-splitters', 'Разветвители', 'Splitters', language)] },
      ] },
      { title: language === 'ru' ? 'Поставщики и предметы в пути' : 'Providers and in-transit items', intro: language === 'ru' ? 'Поставляющий склад может ограничить предмет, сохранить неприкосновенный минимум и задать приоритет от −2 до +2.' : 'A provider warehouse may restrict the item, preserve minimum stock, and set priority from −2 to +2.', entries: [
        { title: language === 'ru' ? 'Доступный запас' : 'Available supply', text: language === 'ru' ? `Поставщик отдаёт только количество сверх минимального запаса, который регулируется от 0 до ${m.providerMinMax}. Пустой ID правила работает как универсальное правило.` : `A provider supplies only the amount above minimum stock, configurable from 0 to ${m.providerMinMax}. An empty rule item ID acts as a wildcard.`, value: `0–${m.providerMinMax}`, links: [] },
        { title: language === 'ru' ? 'Приоритет поставщика' : 'Provider priority', text: language === 'ru' ? `Если несколько манипуляторов обслуживают одну цель, источник с более высоким приоритетом ${m.providerPriorityMin}…${m.providerPriorityMax} получает право первым.` : `When several inserters serve the same target, the source with higher priority in ${m.providerPriorityMin}…${m.providerPriorityMax} is allowed to supply first.`, value: `${m.providerPriorityMin}…${m.providerPriorityMax}`, links: [localizedLogisticsPageLink('inserters', 'Механические манипуляторы', 'Mechanical inserters', language)] },
        { title: language === 'ru' ? 'Резервирование' : 'Reservation', text: language === 'ru' ? `Отправленный стек получает токен цели, ID и количество. Резерв переносится при разделении стека и освобождается при доставке; забытая запись истекает через ${m.reservationTtl / 60000} минут.` : `A dispatched stack receives a target token, item ID, and amount. Its reservation follows stack splits and is released on delivery; a stale record expires after ${m.reservationTtl / 60000} minutes.`, value: `${m.reservationTtl / 60000} min`, links: [localizedLogisticsPageLink('logistics-diagnostics', 'Предметы в пути', 'Items in transit', language)] },
      ] },
    ],
    related: [localizedLogisticsPageLink('inserters', 'Механические манипуляторы', 'Mechanical inserters', language), localizedLogisticsPageLink('filters-splitters', 'Фильтры и разветвители', 'Filters and splitters', language), localizedOptimizationPageLink('assembler-coordination', 'Координация сборщиков', 'Assembler coordination', language)],
  };
}


function logisticsDiagnosticsContent(language) {
  const m = logisticsMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Длина маршрута' : 'Route depth', value: `≤ ${m.demandMaxNodes}` },
      { label: language === 'ru' ? 'Резерв предмета' : 'Item reservation', value: `${m.reservationTtl / 60000} min` },
      { label: language === 'ru' ? 'Проверка' : 'Inspection', value: language === 'ru' ? 'По компонентам' : 'By component' },
      { label: language === 'ru' ? 'Отдельное окно' : 'Separate window', value: language === 'ru' ? 'Нет' : 'None' },
    ],
    sections: [
      { title: language === 'ru' ? 'Проверка маршрута' : 'Checking a route', intro: language === 'ru' ? 'Отдельного окна диагностики нет: проверяйте линию от получателя к поставщику.' : 'There is no separate diagnostics window; inspect the line from requester back to provider.', entries: [
        { title: language === 'ru' ? 'Начните с получателя' : 'Start at the requester', text: language === 'ru' ? 'Проверьте рецепт машины или правило склада: нужный предмет должен быть запрошен, а во входе должно оставаться свободное место.' : 'Check the machine recipe or storage rule: the item must be requested and the input must have free space.', value: language === 'ru' ? 'Запрос · свободный вход' : 'Demand · free input', links: [localizedLogisticsPageLink('ingredient-demand', 'Запросы ингредиентов', 'Ingredient demand', language)] },
        { title: language === 'ru' ? 'Проследите путь' : 'Trace the path', text: language === 'ru' ? 'Идите по лентам против потока и проверяйте направление каждого блока, фильтры, разделители и наличие предмета у поставщика.' : 'Follow belts against the flow and check every block direction, filters, splitters, and provider stock.', value: language === 'ru' ? 'Направление · фильтр · запас' : 'Direction · filter · stock', links: [localizedLogisticsPageLink('conveyor-tiers', 'Конвейерные линии', 'Conveyor lines', language)] },
        { title: language === 'ru' ? 'Найдите блокировку' : 'Find the blockage', text: language === 'ru' ? 'Стек на конце ленты или предмет в руке манипулятора означает, что следующий блок не может его принять.' : 'A stack at the end of a belt or an item held by an inserter means the next block cannot accept it.', value: language === 'ru' ? 'Проверить следующий блок' : 'Check the next block', links: [localizedLogisticsPageLink('inserters', 'Манипуляторы', 'Inserters', language)] },
      ] },
      { title: language === 'ru' ? 'Проверка вручную' : 'Manual checks', intro: language === 'ru' ? 'Смотрите направление лент, предмет в руке манипулятора, свободное место и правила склада.' : 'Inspect belt direction, the inserter hand, free space, and storage rules.', entries: [
        { title: language === 'ru' ? 'Направление блоков' : 'Block direction', text: language === 'ru' ? 'Выход ленты и рабочее направление манипулятора задаются тем, куда смотрел игрок при установке блока.' : 'A belt output and inserter working direction follow the player facing at the moment the block is placed.', value: language === 'ru' ? 'Ориентация при установке' : 'Facing on placement', links: [localizedWikiPageLink('interface/building-tools', 'Строительство', 'Building', language, 'building-tools')] },
        { title: language === 'ru' ? 'Затор ленты' : 'Belt jam', text: language === 'ru' ? 'Если груз дошёл до конца клетки и не передаётся, освободите следующий блок или исправьте его направление и фильтр.' : 'If cargo reaches the end of a tile but is not handed off, free the next block or correct its direction and filter.', value: language === 'ru' ? 'Проверить выход' : 'Check output', links: [localizedLogisticsPageLink('conveyor-tiers', 'Заторы лент', 'Belt jams', language)] },
        { title: language === 'ru' ? 'Дефицит предмета' : 'Item shortage', text: language === 'ru' ? 'Если маршрут свободен, проверьте наличие предмета у поставщика и совпадение его ID с фильтрами линии.' : 'If the route is clear, check provider stock and ensure the item ID matches line filters.', value: language === 'ru' ? 'Запас · ID · фильтры' : 'Stock · ID · filters', links: [localizedLogisticsPageLink('filters-splitters', 'Фильтры', 'Filters', language)] },
      ] },
    ],
    related: [localizedLogisticsPageLink('conveyor-tiers', 'Уровни конвейеров', 'Conveyor tiers', language), localizedLogisticsPageLink('ingredient-demand', 'Запросы ингредиентов', 'Ingredient demand', language), localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language)],
  };
}


function localizedLogistics(guide, language) {
  const content = {
    'conveyor-tiers': logisticsConveyorContent,
    inserters: logisticsInsertersContent,
    'filters-splitters': logisticsFiltersContent,
    'ingredient-demand': logisticsDemandContent,
    'logistics-diagnostics': logisticsDiagnosticsContent,
  }[guide.id](language);
  const index = logisticsDefinitions.indexOf(guide);
  return {
    ...localizedLogisticsSummary(guide, language),
    ...content,
    previous: index > 0 ? localizedLogisticsSummary(logisticsDefinitions[index - 1], language) : null,
    next: index < logisticsDefinitions.length - 1 ? localizedLogisticsSummary(logisticsDefinitions[index + 1], language) : null,
  };
}


function localizedSteamSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedSteamPageLink(id, titleRu, titleEn, language) {
  return localizedWikiPageLink(`steam/${encodeURIComponent(id)}`, titleRu, titleEn, language, id);
}


function steamWaterSupplyContent(language) {
  const m = steamMechanics;
  const litersPerSteam = Math.round(1 / m.steamPerWater);
  return {
    facts: [
      { label: language === 'ru' ? 'Механический насос' : 'Mechanical pump', value: `${m.pumpRates.mechanical} ${language === 'ru' ? 'л/с' : 'L/s'}` },
      { label: language === 'ru' ? 'Паровой насос' : 'Steam pump', value: `${m.pumpRates.steam} ${language === 'ru' ? 'л/с' : 'L/s'}` },
      { label: language === 'ru' ? 'Электрический насос' : 'Electric pump', value: `${m.pumpRates.electric} ${language === 'ru' ? 'л/с' : 'L/s'} · ${m.electricPumpPower} EU/s` },
      { label: language === 'ru' ? 'Пар на воду' : 'Steam per water', value: `1:${litersPerSteam}` },
    ],
    sections: [
      { title: language === 'ru' ? 'Выбор и установка' : 'Choosing and placing a pump', intro: language === 'ru' ? 'Любой водяной насос работает только на клетке, которую мир считает водой.' : 'Every water pump works only when its placement tile is recognized as water by the world.', entries: [
        { title: language === 'ru' ? 'Механический' : 'Mechanical', text: language === 'ru' ? 'Не требует EU или пара. Его 4 л/с ровно покрывают один котёл, пока труба не занята другими жидкостями.' : 'Requires neither EU nor steam. Its 4 L/s exactly supplies one boiler while the pipe is not competing with other fluids.', value: `1 ${language === 'ru' ? 'насос : 1 котёл' : 'pump : 1 boiler'}`, links: [localizedMechanicItem('mechanical_water_pump', language), localizedSteamPageLink('boilers-fuel', 'Котлы и топливо', 'Boilers and fuel', language)] },
        { title: language === 'ru' ? 'Паровой' : 'Steam-driven', text: language === 'ru' ? `Подаёт ${m.pumpRates.steam} л/с из бака ${m.steamPumpOutput} л, потребляя 1 л пара на ${litersPerSteam} л воды. Входной бак пара вмещает ${m.steamPumpInput} л.` : `Outputs ${m.pumpRates.steam} L/s into a ${m.steamPumpOutput} L tank, consuming 1 L of steam per ${litersPerSteam} L of water. Its steam input tank holds ${m.steamPumpInput} L.`, value: `${m.steamPumpInput} → ${m.steamPumpOutput} L`, links: [localizedMechanicItem('steam_water_pump', language), localizedMechanicItem('fluid_pipe', language)] },
        { title: language === 'ru' ? 'Электрический' : 'Electric', text: language === 'ru' ? `Средний по подаче: ${m.pumpRates.electric} л/с из буфера ${m.pumpBuffer} л. Тратит ${m.electricPumpPower} EU/с только во время реальной накачки.` : `The middle option: ${m.pumpRates.electric} L/s from a ${m.pumpBuffer} L buffer. It draws ${m.electricPumpPower} EU/s only while actually pumping.`, value: `${m.electricPumpPower} EU/s`, links: [localizedMechanicItem('water_pump', language), localizedEnergyPageLink('grid-distribution', 'Энергосеть', 'Power grid', language)] },
      ] },
      { title: language === 'ru' ? 'Баланс линии' : 'Balancing the line', intro: language === 'ru' ? 'Насос останавливается при пустом приводе, полном выходе или неверной клетке.' : 'A pump stops when its drive is empty, its output is full, or it is not placed on a valid water tile.', entries: [
        { title: language === 'ru' ? 'Считайте котлы' : 'Count boilers', text: language === 'ru' ? `Каждый котёл требует ${m.boilerRate} л воды/с. Два котла значат 8 л/с, четыре — 16 л/с.` : `Each boiler needs ${m.boilerRate} L of water per second. Two boilers need 8 L/s, and four need 16 L/s.`, value: `${m.boilerRate} L/s × N`, links: [localizedSteamPageLink('boilers-fuel', 'Котлы и топливо', 'Boilers and fuel', language)] },
        { title: language === 'ru' ? 'Не стройте замкнутый круг' : 'Avoid a closed feedback loop', text: language === 'ru' ? 'Паровой насос может пиваться от той же линии, но ему всё равно нужен начальный пар и запас на потребителей.' : 'A steam pump can feed from the same line, but it still needs startup steam and headroom for other consumers.', value: language === 'ru' ? 'Нужен стартовый запас' : 'Startup reserve required', links: [localizedSteamPageLink('steam-network', 'Паровая сеть', 'Steam network', language)] },
        { title: language === 'ru' ? 'Буфер не равен мощности' : 'Buffer is not capacity', text: language === 'ru' ? 'Большой бак сглаживает всплески, но не исправляет постоянный дефицит л/с.' : 'A large tank smooths bursts but cannot correct a permanent L/s deficit.', value: language === 'ru' ? 'Запас ≠ поток' : 'Storage ≠ flow', links: [localizedSteamPageLink('steam-diagnostics', 'Диагностика пара', 'Steam diagnostics', language)] },
      ] },
    ],
    related: [localizedMechanicItem('mechanical_water_pump', language), localizedMechanicItem('steam_water_pump', language), localizedMechanicItem('water_pump', language), localizedWikiPageLink('systems/fluids', 'Жидкостная система', 'Fluid system', language, 'fluids')],
  };
}


function steamBoilersContent(language) {
  const m = steamMechanics;
  const bestFuel = Math.max(...Object.values(m.fuels));
  return {
    facts: [
      { label: language === 'ru' ? 'Выход пара' : 'Steam output', value: `${m.boilerRate} ${language === 'ru' ? 'л/с' : 'L/s'}` },
      { label: language === 'ru' ? 'Бак воды' : 'Water tank', value: `${m.boilerWaterTank} L` },
      { label: language === 'ru' ? 'Бак пара' : 'Steam tank', value: `${m.boilerSteamTank} L` },
      { label: language === 'ru' ? 'Бак креозота' : 'Creosote tank', value: `${m.boilerCreosoteTank} L` },
    ],
    sections: [
      { title: language === 'ru' ? 'Кипячение и баки' : 'Boiling and tanks', intro: language === 'ru' ? 'Котёл не требует EU: он превращает воду в пар и тратит топливо только пока может кипятить.' : 'The boiler needs no EU: it converts water into steam and burns fuel only while boiling is possible.', entries: [
        { title: language === 'ru' ? 'Баланс 1:1' : '1:1 conversion', text: language === 'ru' ? `За секунду из ${m.boilerRate} л воды получается ${m.boilerRate} л пара. При полном баке воды это ${m.boilerWaterTank / m.boilerRate} с непрерывной работы.` : `${m.boilerRate} L of water becomes ${m.boilerRate} L of steam each second. A full water tank lasts ${m.boilerWaterTank / m.boilerRate} seconds at continuous output.`, value: `${m.boilerRate} → ${m.boilerRate} L/s`, links: [localizedMechanicItem('steam_boiler', language), localizedWikiPageLink('fluids/steam', 'Пар', 'Steam', language, 'steam')] },
        { title: language === 'ru' ? 'Условия запуска' : 'Run conditions', text: language === 'ru' ? 'Нужны вода, свободное место в паровом баке и активное топливо. Если пар некуда выдавать, таймер горения не тратится.' : 'The boiler needs water, room in its steam tank, and active fuel. When steam has nowhere to go, the remaining burn timer is preserved.', value: language === 'ru' ? 'Без потерь при простое' : 'No idle fuel loss', links: [localizedSteamPageLink('steam-network', 'Паровая сеть', 'Steam network', language)] },
        { title: language === 'ru' ? 'Три раздельных бака' : 'Three separate tanks', text: language === 'ru' ? 'Вода и креозот маршрутизируются в свои входные баки, пар — в выходной. Одна жидкость не занимает бак другой.' : 'Water and creosote are routed into dedicated input tanks, while steam uses the output tank. One fluid cannot occupy another fluid\'s tank.', value: `${m.boilerWaterTank} / ${m.boilerCreosoteTank} / ${m.boilerSteamTank} L`, links: [localizedMechanicItem('fluid_pipe', language)] },
      ] },
      { title: language === 'ru' ? 'Топливо и масштаб' : 'Fuel and scaling', intro: language === 'ru' ? 'Твёрдое топливо в слоте всегда имеет приоритет; креозот подхватывает работу, когда слот пуст.' : 'Solid fuel in the slot always has priority; creosote takes over when the slot is empty.', entries: [
        { title: language === 'ru' ? 'Уголь и кокс' : 'Coal and coke', text: language === 'ru' ? `Уголь и угольная пыль горят ${m.fuels.coal} с; кокс и коксовая пыль — ${m.fuels.coke} с.` : `Coal and coal dust burn for ${m.fuels.coal} s; coke and coke dust burn for ${m.fuels.coke} s.`, value: `${m.fuels.coal} / ${m.fuels.coke} s`, links: [localizedMechanicItem('coal', language), localizedMechanicItem('coke', language)] },
        { title: language === 'ru' ? 'Сжатый уголь и креозот' : 'Compressed coal and creosote', text: language === 'ru' ? `Сжатый уголь даёт ${bestFuel} с. Каждый литр креозота даёт ${m.creosoteBurn} с горения и расходуется по 1 л.` : `Compressed coal gives ${bestFuel} s. Each litre of creosote gives ${m.creosoteBurn} s of burn time and is consumed in 1 L portions.`, value: `${bestFuel} s · ${m.creosoteBurn} s/L`, links: [localizedMechanicItem('compressed_coal', language), localizedWikiPageLink('fluids/creosote', 'Креозот', 'Creosote', language, 'creosote')] },
        { title: language === 'ru' ? 'Мощность котельной' : 'Boiler-house capacity', text: language === 'ru' ? `Умножьте ${m.boilerRate} л/с на число готовых котлов, затем ограничьте результат скоростью самой медленной трубы.` : `Multiply ${m.boilerRate} L/s by the number of ready boilers, then cap the result by the slowest pipe in the network.`, value: `min(${m.boilerRate} × N, ${m.pipeT1}/${m.pipeT2})`, links: [localizedSteamPageLink('steam-network', 'Паровая сеть', 'Steam network', language), localizedSteamPageLink('steam-machines', 'Паровые машины', 'Steam machines', language)] },
      ] },
    ],
    related: [localizedMechanicItem('steam_boiler', language), localizedSteamPageLink('water-supply', 'Водоснабжение', 'Water supply', language), localizedWikiPageLink('fluids/steam', 'Пар', 'Steam', language, 'steam'), localizedWikiPageLink('fluids/creosote', 'Креозот', 'Creosote', language, 'creosote')],
  };
}


function steamNetworkContent(language) {
  const m = steamMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Труба T1' : 'T1 pipe', value: `${m.pipeT1} ${language === 'ru' ? 'л/с' : 'L/s'}` },
      { label: language === 'ru' ? 'Труба T2' : 'T2 pipe', value: `${m.pipeT2} ${language === 'ru' ? 'л/с' : 'L/s'}` },
      { label: language === 'ru' ? 'Клапан' : 'Valve', value: `${m.pipeT2} ${language === 'ru' ? 'л/с' : 'L/s'}` },
      { label: language === 'ru' ? 'Порог перелива' : 'Overflow threshold', value: `${m.valveThreshold * 100}%` },
    ],
    sections: [
      { title: language === 'ru' ? 'Связность и пропускная способность' : 'Connectivity and throughput', intro: language === 'ru' ? 'Трубы и клапаны, соприкасающиеся сторонами, образуют одну сеть. Машина подключается с соседней клетки.' : 'Pipes and valves that touch along their sides form one network. A machine attaches from an adjacent tile.', entries: [
        { title: language === 'ru' ? 'Лимит слабого звена' : 'Weakest-link limit', text: language === 'ru' ? `Скорость всей связной сети равна минимальной скорости её проводников. Один сегмент T1 снижает T2-сеть с ${m.pipeT2} до ${m.pipeT1} л/с.` : `The whole connected network uses the minimum conductor rate. One T1 segment lowers a T2 network from ${m.pipeT2} to ${m.pipeT1} L/s.`, value: `min(${m.pipeT1}, ${m.pipeT2})`, links: [localizedMechanicItem('fluid_pipe', language), localizedMechanicItem('fluid_pipe_t2', language)] },
        { title: language === 'ru' ? 'Общий бюджет потока' : 'Shared flow budget', text: language === 'ru' ? 'Вода, пар и другие жидкости в одной сети делят общий лимит. Отдельные магистрали убирают эту конкуренцию.' : 'Water, steam, and other fluids in one network share its single transfer budget. Separate trunks remove that competition.', value: language === 'ru' ? 'Один лимит на сеть' : 'One budget per network', links: [localizedWikiPageLink('systems/fluids', 'Жидкостная система', 'Fluid system', language, 'fluids')] },
        { title: language === 'ru' ? 'Приоритеты' : 'Priorities', text: language === 'ru' ? 'Производители и потребители сортируются по приоритету. Паровой насос принимает пар с повышенным входным приоритетом.' : 'Producers and consumers are sorted by priority. The steam pump accepts steam at a higher input priority than ordinary steam machines.', value: language === 'ru' ? 'Насос раньше машин' : 'Pump before machines', links: [localizedSteamPageLink('water-supply', 'Водоснабжение', 'Water supply', language)] },
      ] },
      { title: language === 'ru' ? 'Клапаны и буферы' : 'Valves and buffers', intro: language === 'ru' ? 'Клапан не просто соединяет трубы: он задаёт направление, фильтр и условие открытия.' : 'A valve does more than connect pipes: it defines direction, a fluid filter, and an opening condition.', entries: [
        { title: language === 'ru' ? 'Направление и фильтр' : 'Direction and filter', text: language === 'ru' ? 'Поток проходит только от задней стороны к передней. Пустой фильтр разрешает любую жидкость, заданный — только совпадающий ID.' : 'Flow passes only from the back side to the front. An empty filter accepts any fluid; a configured filter accepts only the matching ID.', value: language === 'ru' ? 'Одно направление' : 'One-way flow', links: [localizedMechanicItem('fluid_valve', language)] },
        { title: language === 'ru' ? 'Режим перелива' : 'Overflow mode', text: language === 'ru' ? `По умолчанию клапан открывает резервную ветку только при заполнении источника на ${m.valveThreshold * 100}%. Порог можно задать от 10% до 100%.` : `By default, an overflow branch opens only when the source is ${m.valveThreshold * 100}% full. The threshold can be configured from 10% to 100%.`, value: '10–100%', links: [localizedSteamPageLink('steam-diagnostics', 'Диагностика пара', 'Steam diagnostics', language)] },
        { title: language === 'ru' ? 'Буферы' : 'Buffers', text: language === 'ru' ? 'Внутренние баки котлов и машин сглаживают краткие перерывы. Отдельный резервуар помогает при пиках, но не повышает лимит трубы.' : 'Internal boiler and machine tanks smooth short interruptions. A separate tank helps with bursts but does not raise the pipe limit.', value: language === 'ru' ? 'Резерв, не ускорение' : 'Reserve, not throughput', links: [localizedMechanicItem('fluid_tank_t1', language)] },
      ] },
    ],
    related: [localizedMechanicItem('fluid_pipe', language), localizedMechanicItem('fluid_pipe_t2', language), localizedMechanicItem('fluid_valve', language), localizedWikiPageLink('systems/fluids', 'Жидкостная система', 'Fluid system', language, 'fluids')],
  };
}


function steamMachinesContent(language) {
  const m = steamMechanics;
  const machines = [
    ['steam_crusher', language === 'ru' ? 'Паровая дробилка' : 'Steam Crusher', m.machines.crusher],
    ['steam_furnace', language === 'ru' ? 'Паровая печь' : 'Steam Furnace', m.machines.furnace],
    ['steam_press', language === 'ru' ? 'Паровой пресс' : 'Steam Press', m.machines.press],
    ['steam_assembler', language === 'ru' ? 'Паровой сборщик' : 'Steam Assembler', m.machines.assembler],
  ];
  return {
    facts: [
      { label: language === 'ru' ? 'Входной бак' : 'Input tank', value: `${m.machineTank} L` },
      { label: language === 'ru' ? 'Дробилка' : 'Crusher', value: `${m.machines.crusher.processTime} s · ${m.machines.crusher.steamRate} L/s` },
      { label: language === 'ru' ? 'Печь / пресс' : 'Furnace / press', value: `${m.machines.furnace.processTime}/${m.machines.press.processTime} s · 2 L/s` },
      { label: language === 'ru' ? 'Сборщик' : 'Assembler', value: `${m.machines.assembler.processTime} s · ${m.machines.assembler.steamRate} L/s` },
    ],
    sections: [
      { title: language === 'ru' ? 'Скорость и расход' : 'Speed and steam draw', intro: language === 'ru' ? 'Все четыре машины берут пар из одинакового входного бака, но их циклы и расход различаются.' : 'All four machines use the same-size steam input tank, but their cycle times and draw differ.', entries: machines.slice(0, 3).map(([id, title, spec]) => ({
        title,
        text: language === 'ru' ? `Цикл занимает ${spec.processTime} с и тратит ${spec.steamRate} л пара/с, то есть ${spec.processTime * spec.steamRate} л на непрерывный цикл.` : `A cycle takes ${spec.processTime} s at ${spec.steamRate} L/s, or ${spec.processTime * spec.steamRate} L for one uninterrupted cycle.`,
        value: `${spec.processTime * spec.steamRate} L/${language === 'ru' ? 'цикл' : 'cycle'}`,
        links: [localizedMechanicItem(id, language)],
      })) },
      { title: language === 'ru' ? 'Условия работы и баланс' : 'Run conditions and balance', intro: language === 'ru' ? 'Пар расходуется только во время обработки; при остановке прогресс текущего цикла сбрасывается.' : 'Steam is consumed only during processing; if processing stops, the current cycle progress resets.', entries: [
        { title: machines[3][1], text: language === 'ru' ? `Сборщик работает ${m.machines.assembler.processTime} с при ${m.machines.assembler.steamRate} л/с и имеет четыре входных слота для многокомпонентных рецептов.` : `The assembler runs for ${m.machines.assembler.processTime} s at ${m.machines.assembler.steamRate} L/s and has four input slots for multi-component recipes.`, value: `${m.machines.assembler.processTime * m.machines.assembler.steamRate} L/${language === 'ru' ? 'цикл' : 'cycle'}`, links: [localizedMechanicItem('steam_assembler', language)] },
        { title: language === 'ru' ? 'Три условия запуска' : 'Three run conditions', text: language === 'ru' ? 'Нужны пар в баке, достаточное число входных предметов и незаблокированный выход. Несовместимый или полный выходной стек останавливает машину.' : 'The machine needs steam in its tank, enough input items, and an unblocked output. An incompatible or full output stack stops processing.', value: language === 'ru' ? 'Пар · вход · выход' : 'Steam · input · output', links: [localizedLogisticsPageLink('inserters', 'Манипуляторы', 'Inserters', language)] },
        { title: language === 'ru' ? 'Сколько машин на котёл' : 'Machines per boiler', text: language === 'ru' ? `Один котёл устойчиво питает две машины по 2 л/с или два сборщика с запасом 1 л/с. Считайте сумму одновременно активных потребителей.` : `One boiler sustainably feeds two 2 L/s machines, or two assemblers with 1 L/s to spare. Add the draw of consumers that can be active together.`, value: `${m.boilerRate} ${language === 'ru' ? 'л/с на котёл' : 'L/s per boiler'}`, links: [localizedSteamPageLink('boilers-fuel', 'Котлы и топливо', 'Boilers and fuel', language), localizedSteamPageLink('steam-diagnostics', 'Диагностика пара', 'Steam diagnostics', language)] },
      ] },
    ],
    related: machines.map(([id]) => localizedMechanicItem(id, language)),
  };
}


function steamDiagnosticsContent(language) {
  const m = steamMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Проверка' : 'Inspection', value: language === 'ru' ? 'По машинам' : 'By machine' },
      { label: language === 'ru' ? 'Отдельное окно' : 'Separate window', value: language === 'ru' ? 'Нет' : 'None' },
      { label: language === 'ru' ? 'Расчёт' : 'Calculation', value: language === 'ru' ? 'Расход против подачи' : 'Draw vs supply' },
      { label: language === 'ru' ? 'Порог перегрузки' : 'Saturation warning', value: `${m.saturationThreshold * 100}%` },
    ],
    sections: [
      { title: language === 'ru' ? 'Проверка параметров' : 'Checking values', intro: language === 'ru' ? 'Отдельного окна нет: сравнивайте подачу котлов, расход машин и пропускную способность труб.' : 'There is no separate window; compare boiler supply, machine draw, and pipe throughput.', entries: [
        { title: language === 'ru' ? 'Установлено / доступно' : 'Installed / online', text: language === 'ru' ? 'Установленная мощность считает все котлы по 4 л/с. Доступная учитывает только котлы с водой и топливом.' : 'Installed capacity counts every boiler at 4 L/s. Online capacity counts only boilers that have water and fuel.', value: language === 'ru' ? 'Готово / всего' : 'Online / installed', links: [localizedSteamPageLink('boilers-fuel', 'Котлы и топливо', 'Boilers and fuel', language)] },
        { title: language === 'ru' ? 'Активный / подключённый спрос' : 'Active / connected demand', text: language === 'ru' ? 'Подключённый спрос суммирует паспортный расход всех паровых машин; активный — только тех, у кого есть или ожидается работа.' : 'Connected demand sums the rated draw of all steam machines; active demand includes only machines that are processing or have work waiting.', value: language === 'ru' ? 'Текущий / максимальный' : 'Current / maximum', links: [localizedSteamPageLink('steam-machines', 'Паровые машины', 'Steam machines', language)] },
        { title: language === 'ru' ? 'Поток, лимит и буфер' : 'Flow, limit, and buffer', text: language === 'ru' ? 'Сводка показывает реальный поток пара, лимит трубы, общую загрузку сети и сумму пара в котлах и машинах.' : 'The summary reports actual steam flow, the pipe limit, total network load, and steam stored in boilers and machines.', value: language === 'ru' ? 'л/с · % · л' : 'L/s · % · L', links: [localizedSteamPageLink('steam-network', 'Паровая сеть', 'Steam network', language)] },
      ] },
      { title: language === 'ru' ? 'Пошаговый поиск проблемы' : 'Step-by-step troubleshooting', intro: language === 'ru' ? 'Проверяйте линию от источника к потребителю: вода, топливо, пар в котле, маршрут и входной бак машины.' : 'Check the line from producer to consumer: water, fuel, boiler steam, route, and the machine input tank.', entries: [
        { title: language === 'ru' ? 'Машина без пара' : 'Machine without steam', text: language === 'ru' ? 'Если у машины есть сырьё, но входной бак пара пуст, проследите трубу до котла и проверьте воду с топливом.' : 'If a machine has input but its steam tank is empty, trace the pipe to the boiler and check water and fuel.', value: language === 'ru' ? 'Пустой бак + работа' : 'Empty tank + pending work', links: [localizedSteamPageLink('steam-machines', 'Паровые машины', 'Steam machines', language)] },
        { title: language === 'ru' ? 'Не хватает мощности' : 'Insufficient capacity', text: language === 'ru' ? 'Если активный спрос выше доступной мощности, добавьте готовый котёл или восстановите воду/топливо. Если ниже доступная, но выше установленной — нужны новые котлы.' : 'If active demand exceeds online capacity, add a ready boiler or restore water and fuel. If it is below online but above installed capacity, add boilers.', value: language === 'ru' ? 'Спрос > мощность' : 'Demand > capacity', links: [localizedSteamPageLink('boilers-fuel', 'Котлы и топливо', 'Boilers and fuel', language)] },
        { title: language === 'ru' ? 'Труба на пределе' : 'Pipe at capacity', text: language === 'ru' ? `Если суммарный расход достигает ${m.saturationThreshold * 100}% пропускной способности, замените все T1-сегменты на T2 или разделите сеть.` : `If total draw reaches ${m.saturationThreshold * 100}% of pipe capacity, replace every T1 segment with T2 or split the network.`, value: `≥ ${m.saturationThreshold * 100}%`, links: [localizedSteamPageLink('steam-network', 'Паровая сеть', 'Steam network', language), localizedMechanicItem('fluid_pipe_t2', language)] },
      ] },
    ],
    related: [localizedSteamPageLink('water-supply', 'Водоснабжение', 'Water supply', language), localizedSteamPageLink('steam-network', 'Паровая сеть', 'Steam network', language), localizedOptimizationPageLink('factory-diagnostics', 'Диагностика фабрики', 'Factory diagnostics', language), localizedWikiPageLink('interface/building-tools', 'Строительство', 'Building', language, 'building-tools')],
  };
}


function localizedSteam(guide, language) {
  const content = {
    'water-supply': steamWaterSupplyContent,
    'boilers-fuel': steamBoilersContent,
    'steam-network': steamNetworkContent,
    'steam-machines': steamMachinesContent,
    'steam-diagnostics': steamDiagnosticsContent,
  }[guide.id](language);
  const index = steamDefinitions.indexOf(guide);
  return {
    ...localizedSteamSummary(guide, language),
    ...content,
    previous: index > 0 ? localizedSteamSummary(steamDefinitions[index - 1], language) : null,
    next: index < steamDefinitions.length - 1 ? localizedSteamSummary(steamDefinitions[index + 1], language) : null,
  };
}


function localizedOreProcessingSummary(guide, language) {
  return {
    id: guide.id,
    title: guide.title[language],
    subtitle: guide.subtitle[language],
    description: guide.description[language],
    color: guide.color,
    icon: localizedMechanicItem(guide.iconId, language),
  };
}


function localizedOreProcessingPageLink(id, titleRu, titleEn, language) {
  return localizedWikiPageLink(`ore-processing/${encodeURIComponent(id)}`, titleRu, titleEn, language, id);
}


function oreChainOverviewContent(language) {
  const m = oreProcessingMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Способов переработки' : 'Processing options', value: '4' },
      { label: language === 'ru' ? 'Продвинутый выход' : 'Advanced output', value: '×2 dust' },
      { label: language === 'ru' ? 'Вода на промывку' : 'Wash water', value: `${m.washer.water} L` },
      { label: language === 'ru' ? 'Промежуточных форм' : 'Intermediate forms', value: '0' },
    ],
    sections: [
      { title: language === 'ru' ? 'Маршруты сырья' : 'Material routes', intro: language === 'ru' ? 'Все машины принимают обычную руду и сразу выдают стандартную пыль без отдельных состояний сырья.' : 'Every processing machine accepts raw ore and directly outputs standard dust without extra ore states.', entries: [
        { title: language === 'ru' ? 'Прямая плавка' : 'Direct smelting', text: language === 'ru' ? 'Руду можно сразу плавить в один слиток.' : 'Ore can be smelted directly into one ingot.', value: language === 'ru' ? 'Руда → слиток' : 'Ore → ingot', links: [localizedOreProcessingPageLink('smelting-melting', 'Плавка', 'Smelting', language)] },
        { title: language === 'ru' ? 'Удвоение пыли' : 'Dust doubling', text: language === 'ru' ? 'Паровая и электрическая дробилки превращают одну руду в две обычные металлические пыли.' : 'Steam and electric crushers turn one ore into two standard metal dusts.', value: '1 ore → 2 dust', links: [localizedOreProcessingPageLink('crushing', 'Измельчение руды', 'Ore grinding', language)] },
        { title: language === 'ru' ? 'Побочные металлы' : 'Byproduct metals', text: language === 'ru' ? 'Промывка, сепарация и центрифуга также работают напрямую с рудой и добавляют одну обычную побочную пыль.' : 'Washing, separation, and centrifuging also work directly from ore and add one standard byproduct dust.', value: '2 dust + 1 byproduct', links: [localizedOreProcessingPageLink('washing-separation', 'Промывка и сепарация', 'Washing and separation', language), localizedOreProcessingPageLink('centrifuge-yields', 'Центрифуга', 'Centrifuge', language)] },
      ] },
      { title: language === 'ru' ? 'Выбор и буферы' : 'Choosing and buffering', intro: language === 'ru' ? 'Промывка, сепарация и центрифуга — альтернативные маршруты одной руды. Их можно распределять параллельно по нужным побочным металлам.' : 'Washing, separation, and centrifuging are alternative routes for the same raw ore. They can run in parallel according to the byproduct metals you need.', entries: [
        { title: language === 'ru' ? 'Номинальная скорость' : 'Rated speed', text: language === 'ru' ? 'Промывка занимает 4 с и выполняет 15 операций/мин; сепарация и центрифуга занимают по 5 с и выполняют по 12 операций/мин.' : 'Washing takes 4 s for 15 operations/min; separation and centrifuging take 5 s for 12 operations/min each.', value: '15 / 12 / 12 op/min', links: [localizedOptimizationPageLink('production-lines', 'Анализ линии', 'Line analysis', language)] },
        { title: language === 'ru' ? 'Побочный выход' : 'Byproduct output', text: language === 'ru' ? 'Заблокированный основной или побочный слот останавливает операцию до её начала. Отводите оба выхода в отдельные буферы.' : 'A blocked primary or byproduct slot prevents an operation from starting. Route both outputs into separate buffers.', value: language === 'ru' ? '2 выхода' : '2 outputs', links: [localizedLogisticsPageLink('inserters', 'Манипуляторы', 'Inserters', language)] },
        { title: language === 'ru' ? 'Вода и EU' : 'Water and EU', text: language === 'ru' ? `На номинальные 15 промывок/мин нужно ${m.washer.water * 15} л воды/мин и ${m.washer.power} EU/с. Сухие альтернативы требуют ${m.separator.power} EU/с для сепаратора или ${m.centrifuge.power} EU/с для центрифуги.` : `At the rated 15 washes/min, the washer needs ${m.washer.water * 15} L of water per minute and ${m.washer.power} EU/s. Dry alternatives draw ${m.separator.power} EU/s for the separator or ${m.centrifuge.power} EU/s for the centrifuge.`, value: `${m.washer.water * 15} L/min · ${m.washer.power}/${m.separator.power}/${m.centrifuge.power} EU/s`, links: [localizedSteamPageLink('water-supply', 'Водоснабжение', 'Water supply', language), localizedEnergyPageLink('grid-distribution', 'Энергосеть', 'Power grid', language)] },
      ] },
    ],
    related: [localizedMechanicItem('iron_dust', language), localizedMechanicItem('ore_washer', language), localizedMechanicItem('magnetic_separator', language), localizedMechanicItem('centrifuge', language)],
  };
}


function oreCrushingContent(language) {
  const m = oreProcessingMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Примитивная' : 'Primitive', value: `${m.primitive.time} s · ×1` },
      { label: language === 'ru' ? 'Паровая' : 'Steam', value: `${m.steam.time} s · ${m.steam.steam} L/s · ×2` },
      { label: language === 'ru' ? 'Электрическая' : 'Electric', value: `${m.electric.time} s · ${m.electric.power} EU/s · ×2` },
      { label: language === 'ru' ? 'Рецептов' : 'Recipes', value: `${m.primitive.recipes} / ${m.steam.recipes} / ${m.electric.recipes}` },
    ],
    sections: [
      { title: language === 'ru' ? 'Три уровня дробления' : 'Three crushing tiers', intro: language === 'ru' ? 'Переход к пару даёт не только более быстрый цикл, но и удвоение основных руд.' : 'Moving to steam gives both a faster cycle and doubled output for primary ores.', entries: [
        { title: language === 'ru' ? 'Примитивная дробилка' : 'Primitive Crusher', text: language === 'ru' ? `Работает без энергии, но за ${m.primitive.time} с даёт только один выход из одного входа. Поддерживает железо, медь, уголь, кокс, камень и гравий.` : `Needs no power, but takes ${m.primitive.time} s and returns only one output per input. It supports iron, copper, coal, coke, stone, and gravel.`, value: `${60 / m.primitive.time} op/min`, links: [localizedMechanicItem('primitive_crusher', language)] },
        { title: language === 'ru' ? 'Паровая дробилка' : 'Steam Crusher', text: language === 'ru' ? `За ${m.steam.time} с потребляет ${m.steam.steam * m.steam.time} л пара и даёт две обычные пыли. Её список рецептов расширен до ${m.steam.recipes}.` : `A ${m.steam.time} s cycle consumes ${m.steam.steam * m.steam.time} L of steam and produces two standard dusts. Its recipe list expands to ${m.steam.recipes}.`, value: `${60 / m.steam.time} op/min`, links: [localizedMechanicItem('steam_crusher', language), localizedSteamPageLink('steam-machines', 'Паровые машины', 'Steam machines', language)] },
        { title: language === 'ru' ? 'Электрическая дробилка' : 'Electric Crusher', text: language === 'ru' ? `Цикл ${m.electric.time} с при ${m.electric.power} EU/с — ${m.electric.power * m.electric.time} EU на операцию. Основные руды также удваиваются.` : `A ${m.electric.time} s cycle at ${m.electric.power} EU/s costs ${m.electric.power * m.electric.time} EU per operation. Primary ores are also doubled.`, value: `${60 / m.electric.time} op/min`, links: [localizedMechanicItem('crusher', language), localizedEnergyPageLink('grid-distribution', 'Энергосеть', 'Power grid', language)] },
      ] },
      { title: language === 'ru' ? 'Рецепты и выход' : 'Recipes and outputs', intro: language === 'ru' ? 'Не все входы удваиваются: пыль топлива и фракции камня остаются 1:1.' : 'Not every input is doubled: fuel dust and stone fractions remain 1:1.', entries: [
        { title: language === 'ru' ? 'Удвоение руд' : 'Ore doubling', text: language === 'ru' ? 'Железо, медь, олово, золото, титан и мифрил дают по две обычные пыли в паровой или электрической машине.' : 'Iron, copper, tin, gold, titanium, and mythril yield two standard dusts in steam or electric machines.', value: '6 × 2', links: [localizedOreProcessingPageLink('chain-overview', 'Переработка руды', 'Ore processing', language)] },
        { title: language === 'ru' ? 'Серебро и резонит' : 'Silver and resonite', text: language === 'ru' ? 'Обе продвинутые дробилки дают две серебряные пыли. Логический материал теперь добывается отдельно: резонитовые жилы встречаются в Лесу.' : 'Both advanced crushers yield two silver dusts. Logic material is now mined separately from resonite veins in the Forest.', value: language === 'ru' ? 'Серебро ×2 · резонит: Лес' : 'Silver ×2 · resonite: Forest', links: [localizedMechanicItem('silver_dust', language), localizedMechanicItem('resonite_shard', language)] },
        { title: language === 'ru' ? 'Топливо и камень' : 'Fuel and stone', text: language === 'ru' ? 'Уголь и кокс превращаются в пыль 1:1, камень — в гравий, гравий — в песок.' : 'Coal and coke become dust 1:1; stone becomes gravel, and gravel becomes sand.', value: '1:1', links: [localizedMechanicItem('coal_dust', language), localizedMechanicItem('sand', language)] },
      ] },
    ],
    related: [localizedMechanicItem('primitive_crusher', language), localizedMechanicItem('steam_crusher', language), localizedMechanicItem('crusher', language), localizedOreProcessingPageLink('washing-separation', 'Промывка', 'Washing', language)],
  };
}


function oreWashingContent(language) {
  const m = oreProcessingMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Промывка' : 'Washing', value: `${m.washer.time} s · ${m.washer.power} EU/s` },
      { label: language === 'ru' ? 'Вода' : 'Water', value: `${m.washer.water} L/op · ${m.washer.tank} L` },
      { label: language === 'ru' ? 'Сепарация' : 'Separation', value: `${m.separator.time} s · ${m.separator.power} EU/s` },
      { label: language === 'ru' ? 'Рудных цепочек' : 'Ore chains', value: String(m.washer.recipes) },
    ],
    sections: [
      { title: language === 'ru' ? 'Промывочная машина' : 'Ore Washer', intro: language === 'ru' ? 'Промывочная машина принимает семь видов обычной руды и сразу выдаёт две пыли металла вместе с одной полноценной побочной пылью.' : 'The washer accepts seven raw ores and directly outputs two matching metal dusts plus one full byproduct dust.', entries: [
        { title: language === 'ru' ? 'Условия цикла' : 'Cycle conditions', text: language === 'ru' ? `Для запуска нужны руда, ${m.washer.water} л воды, EU и место в обоих выходах. Вода и предмет списываются после завершения.` : `A cycle needs raw ore, ${m.washer.water} L of water, EU, and room in both outputs. Water and the input are consumed on completion.`, value: `${m.washer.water} L/op`, links: [localizedMechanicItem('ore_washer', language), localizedWikiPageLink('fluids/water', 'Вода', 'Water', language, 'water')] },
        { title: language === 'ru' ? 'Бак и подача' : 'Tank and supply', text: language === 'ru' ? `Входной бак вмещает ${m.washer.tank} л — ровно ${m.washer.tank / m.washer.water} операций. Машина принимает по трубам только воду.` : `The ${m.washer.tank} L input tank holds exactly ${m.washer.tank / m.washer.water} operations. The machine accepts only water through pipes.`, value: `${m.washer.tank / m.washer.water} op/tank`, links: [localizedSteamPageLink('water-supply', 'Водоснабжение', 'Water supply', language)] },
        { title: language === 'ru' ? 'Побочные пыли' : 'Byproduct dust', text: language === 'ru' ? 'Каждая руда имеет свою полноценную побочку: например, железо даёт никелевую пыль, медь — золотую, титан — платиновую.' : 'Each ore has a full-size byproduct: for example, iron yields nickel dust, copper gold dust, and titanium platinum dust.', value: language === 'ru' ? '1 пыль' : '1 dust', links: [localizedMechanicItem('nickel_dust', language), localizedMechanicItem('gold_dust', language)] },
      ] },
      { title: language === 'ru' ? 'Магнитный сепаратор' : 'Magnetic Separator', intro: language === 'ru' ? 'Сепаратор принимает обычную руду и сразу выделяет две основные пыли и одну полноценную побочную пыль.' : 'The separator accepts raw ore and directly extracts two primary dusts plus one full byproduct dust.', entries: [
        { title: language === 'ru' ? 'Цикл и энергия' : 'Cycle and power', text: language === 'ru' ? `Одна операция идёт ${m.separator.time} с при ${m.separator.power} EU/с и стоит ${m.separator.time * m.separator.power} EU.` : `One operation takes ${m.separator.time} s at ${m.separator.power} EU/s, costing ${m.separator.time * m.separator.power} EU.`, value: `${m.separator.time * m.separator.power} EU/op`, links: [localizedMechanicItem('magnetic_separator', language)] },
        { title: language === 'ru' ? 'Сухой маршрут' : 'Dry route', text: language === 'ru' ? 'Сепаратор даёт тот же удвоенный выход основной пыли без промежуточных видов дроблёной руды и без воды.' : 'The separator gives the same doubled primary-dust output without intermediate crushed-ore variants or water.', value: '2 dust + 1 byproduct', links: [localizedOreProcessingPageLink('centrifuge-yields', 'Центрифуга', 'Centrifuge', language), localizedOreProcessingPageLink('crushing', 'Дробление', 'Crushing', language)] },
        { title: language === 'ru' ? 'Два выхода' : 'Two outputs', text: language === 'ru' ? 'Основной слот получает две пыли исходного металла, побочный — одну пыль другого металла. Несовместимый или полный стек остановит линию.' : 'The primary slot receives two dusts of the source metal; the byproduct slot receives one dust of another metal. An incompatible or full stack stops the line.', value: `×${m.separator.byproducts} ${language === 'ru' ? 'побочка' : 'byproduct'}`, links: [localizedLogisticsPageLink('logistics-diagnostics', 'Диагностика логистики', 'Logistics diagnostics', language)] },
      ] },
    ],
    related: [localizedMechanicItem('ore_washer', language), localizedMechanicItem('magnetic_separator', language), localizedMechanicItem('iron_dust', language), localizedMechanicItem('nickel_dust', language)],
  };
}


function oreCentrifugeContent(language) {
  const m = oreProcessingMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Цикл' : 'Cycle', value: `${m.centrifuge.time} s` },
      { label: language === 'ru' ? 'Энергия' : 'Power', value: `${m.centrifuge.power} EU/s` },
      { label: language === 'ru' ? 'Рецептов' : 'Recipes', value: String(m.centrifuge.recipes) },
      { label: language === 'ru' ? 'Побочных пылей' : 'Byproduct dust', value: String(m.centrifuge.byproducts) },
    ],
    sections: [
      { title: language === 'ru' ? 'Прямое разделение руды' : 'Direct ore separation', intro: language === 'ru' ? 'Центрифуга принимает обычную руду и без промежуточных предметов разделяет её на основную и побочную пыль.' : 'The centrifuge accepts raw ore and separates it directly into primary and byproduct dust without intermediate items.', entries: [
        { title: language === 'ru' ? 'Основной выход' : 'Primary output', text: language === 'ru' ? 'Одна руда даёт две пыли соответствующего металла.' : 'One ore yields two dusts of the matching metal.', value: '2 dust', links: [localizedMechanicItem('iron_dust', language)] },
        { title: language === 'ru' ? 'Побочный выход' : 'Byproduct output', text: language === 'ru' ? 'Вторая ячейка получает одну полноценную пыль другого металла — без мелких разновидностей и обратного крафта.' : 'The second slot receives one full dust of another metal, with no tiny variants or conversion crafting.', value: '1 dust', links: [localizedMechanicItem('tin_dust', language), localizedOreProcessingPageLink('washing-separation', 'Промывка и сепарация', 'Washing and separation', language)] },
        { title: language === 'ru' ? 'Семь металлов' : 'Seven metals', text: language === 'ru' ? 'Рецепты доступны для железа, меди, олова, золота, серебра, титана и мифрила.' : 'Recipes exist for iron, copper, tin, gold, silver, titanium, and mythril.', value: '7', links: [localizedMechanicItem('centrifuge', language)] },
      ] },
      { title: language === 'ru' ? 'Пропускная способность' : 'Throughput', intro: language === 'ru' ? 'Цикл сбрасывается при пропадании энергии, сырья или места в выходе, поэтому буферы важны для ровной линии.' : 'The cycle resets if power, input, or output room disappears, so buffers matter for a smooth line.', entries: [
        { title: language === 'ru' ? 'Номинал' : 'Rated throughput', text: language === 'ru' ? `Цикл ${m.centrifuge.time} с даёт ${60 / m.centrifuge.time} операций/мин и требует ${m.centrifuge.power} EU/с непрерывной мощности.` : `A ${m.centrifuge.time} s cycle gives ${60 / m.centrifuge.time} operations/min and requires ${m.centrifuge.power} EU/s of continuous power.`, value: `${60 / m.centrifuge.time} op/min`, links: [localizedEnergyPageLink('grid-distribution', 'Энергосеть', 'Power grid', language)] },
        { title: language === 'ru' ? 'Два выходных стека' : 'Two output stacks', text: language === 'ru' ? 'Основная пыль и побочка хранятся раздельно. Очищайте оба слота: полный побочный стек так же останавливает цепь.' : 'Primary dust and byproduct use separate stacks. Clear both slots because a full byproduct stack also stops the chain.', value: language === 'ru' ? 'Основной + побочный' : 'Primary + byproduct', links: [localizedLogisticsPageLink('inserters', 'Манипуляторы', 'Inserters', language)] },
        { title: language === 'ru' ? 'После центрифуги' : 'After centrifuging', text: language === 'ru' ? 'Металлическую пыль можно переплавить в слиток или расплав объёмом 90 л. Побочки накапливаются для последующих рецептов.' : 'Metal dust can be smelted into an ingot or melted into 90 L of fluid. Store byproducts for later recipes.', value: 'dust → ingot / 90 L', links: [localizedOreProcessingPageLink('smelting-melting', 'Плавка и расплавы', 'Smelting and molten metals', language)] },
      ] },
    ],
    related: [localizedMechanicItem('centrifuge', language), localizedMechanicItem('iron_dust', language), localizedMechanicItem('tin_dust', language), localizedOreProcessingPageLink('washing-separation', 'Промывка и сепарация', 'Washing and separation', language)],
  };
}


function oreSmeltingContent(language) {
  const m = oreProcessingMechanics;
  return {
    facts: [
      { label: language === 'ru' ? 'Обычная печь' : 'Regular furnace', value: `${m.furnace.time} s` },
      { label: language === 'ru' ? 'Паровая печь' : 'Steam Furnace', value: `${m.steamFurnace.time} s · ${m.steamFurnace.steam} L/s` },
      { label: language === 'ru' ? 'Электропечь' : 'Electric Furnace', value: `${m.electricFurnace.time} s · ${m.electricFurnace.power} EU/s` },
      { label: language === 'ru' ? 'Плавильня' : 'Ore Melter', value: `${m.melter.time} s · ${m.melter.power} EU/s` },
    ],
    sections: [
      { title: language === 'ru' ? 'Печи и слитки' : 'Furnaces and ingots', intro: language === 'ru' ? 'Печи дают готовые слитки из обычной руды или металлической пыли.' : 'Furnaces produce finished ingots from raw ore or metal dust.', entries: [
        { title: language === 'ru' ? 'Обычная печь' : 'Regular furnace', text: language === 'ru' ? `Плавит за ${m.furnace.time} с и использует твёрдое топливо в отдельном слоте. Это независимый резерв при аварии энергосети.` : `Smelts in ${m.furnace.time} s and consumes solid fuel from a separate slot. It is an independent fallback during grid failures.`, value: `${60 / m.furnace.time} op/min`, links: [localizedMechanicItem('furnace', language)] },
        { title: language === 'ru' ? 'Паровая печь' : 'Steam Furnace', text: language === 'ru' ? `Цикл ${m.steamFurnace.time} с при ${m.steamFurnace.steam} л пара/с стоит ${m.steamFurnace.time * m.steamFurnace.steam} л и не требует топливного слота.` : `A ${m.steamFurnace.time} s cycle at ${m.steamFurnace.steam} L/s costs ${m.steamFurnace.time * m.steamFurnace.steam} L of steam and needs no fuel slot.`, value: `${m.steamFurnace.time * m.steamFurnace.steam} L/op`, links: [localizedMechanicItem('steam_furnace', language), localizedSteamPageLink('steam-machines', 'Паровые машины', 'Steam machines', language)] },
        { title: language === 'ru' ? 'Электрическая печь' : 'Electric Furnace', text: language === 'ru' ? `Самая быстрая: ${m.electricFurnace.time} с при ${m.electricFurnace.power} EU/с. Одна операция стоит ${m.electricFurnace.time * m.electricFurnace.power} EU.` : `The fastest option: ${m.electricFurnace.time} s at ${m.electricFurnace.power} EU/s. One operation costs ${m.electricFurnace.time * m.electricFurnace.power} EU.`, value: `${60 / m.electricFurnace.time} op/min`, links: [localizedMechanicItem('electric_furnace', language), localizedEnergyPageLink('grid-distribution', 'Энергосеть', 'Power grid', language)] },
      ] },
      { title: language === 'ru' ? 'Индукционная плавильня' : 'Ore Melter', intro: language === 'ru' ? 'Плавильня не даёт предмет: она накапливает один вид расплава в выходном баке для дальнейшей жидкостной металлургии.' : 'The melter does not output an item: it stores one molten-metal type in its output tank for downstream fluid metallurgy.', entries: [
        { title: language === 'ru' ? 'Единое сырьё' : 'Unified feedstock', text: language === 'ru' ? `Слитки, обычная руда и пыль дают по ${m.melter.ingotLiters} л соответствующего расплава. Промежуточных сортов дроблёной руды больше нет.` : `Ingots, raw ore, and dust each yield ${m.melter.ingotLiters} L of matching molten metal. There are no intermediate crushed-ore grades.`, value: `${m.melter.ingotLiters} L`, links: [localizedMechanicItem('ore_melter', language), localizedWikiPageLink('fluids/molten_iron', 'Расплавленное железо', 'Molten iron', language, 'molten_iron')] },
        { title: language === 'ru' ? 'Одинаковый объём' : 'Consistent volume', text: language === 'ru' ? 'Все допустимые формы одного металла дают одинаковый объём, поэтому выбор маршрута переработки не усложняет жидкостную металлургию.' : 'Every accepted form of a metal gives the same volume, so the chosen processing route does not complicate fluid metallurgy.', value: `${m.melter.ingotLiters} L/op`, links: [localizedOreProcessingPageLink('chain-overview', 'Маршруты переработки', 'Processing routes', language)] },
        { title: language === 'ru' ? 'Бак и блокировка' : 'Tank and blocking', text: language === 'ru' ? `Бак ${m.melter.tank} л вмещает ${m.melter.tank / m.melter.ingotLiters} плавок. Другой тип металла не смешивается с уже залитым.` : `The ${m.melter.tank} L tank holds ${m.melter.tank / m.melter.ingotLiters} melts. A different metal type cannot mix with the existing fluid.`, value: `${m.melter.tank} L`, links: [localizedWikiPageLink('systems/fluids', 'Жидкостная система', 'Fluid system', language, 'fluids')] },
      ] },
    ],
    related: [localizedMechanicItem('furnace', language), localizedMechanicItem('steam_furnace', language), localizedMechanicItem('electric_furnace', language), localizedMechanicItem('ore_melter', language)],
  };
}


function localizedOreProcessing(guide, language) {
  const content = {
    'chain-overview': oreChainOverviewContent,
    crushing: oreCrushingContent,
    'washing-separation': oreWashingContent,
    'centrifuge-yields': oreCentrifugeContent,
    'smelting-melting': oreSmeltingContent,
  }[guide.id](language);
  const index = oreProcessingDefinitions.indexOf(guide);
  return {
    ...localizedOreProcessingSummary(guide, language),
    ...content,
    previous: index > 0 ? localizedOreProcessingSummary(oreProcessingDefinitions[index - 1], language) : null,
    next: index < oreProcessingDefinitions.length - 1 ? localizedOreProcessingSummary(oreProcessingDefinitions[index + 1], language) : null,
  };
}


function localizedTechnologySummary(stage, language) {
  const translation = technologyTranslations[stage.id];
  const biome = biomeDefinitions.find((entry) => entry.resource === stage.biomeResource);
  const boss = stage.bossId && bossesById.has(stage.bossId) ? localizedBoss(bossesById.get(stage.bossId), language) : null;
  return {
    id: stage.id,
    title: language === 'ru' ? translation?.title ?? stage.titleEn : stage.titleEn,
    description: language === 'ru' ? translation?.description ?? stage.descriptionEn : stage.descriptionEn,
    biome: biome ? localizedBiomeSummary(biome, language) : null,
    boss: boss ? { id: boss.id, title: boss.title } : null,
    outputCount: stage.machines.length + stage.components.length,
  };
}


function localizedTechnology(stage, language) {
  const summary = localizedTechnologySummary(stage, language);
  const balance = recommendedBalance.get(stage.titleEn) ?? null;
  const nextBiome = stage.bossId ? biomeDefinitions.find((entry) => entry.requiredBoss === stage.bossId) : null;
  const stageIndex = technologyStages.indexOf(stage);
  return {
    ...summary,
    research: stage.research.map((entry) => localizedBossItem(entry.id, entry.count, language)),
    machines: stage.machines.map((id) => localizedTechnologyOutput(id, language)),
    components: stage.components.map((id) => localizedTechnologyOutput(id, language)),
    balance,
    nextBiome: nextBiome ? localizedBiomeSummary(nextBiome, language) : null,
    previous: stageIndex > 0 ? localizedTechnologySummary(technologyStages[stageIndex - 1], language) : null,
    next: stageIndex < technologyStages.length - 1 ? localizedTechnologySummary(technologyStages[stageIndex + 1], language) : null,
  };
}


function localizedBiomeSummary(biome, language) {
  return {
    id: biome.id,
    title: biome.title[language],
    tier: biome.tier,
    tierTitle: biomeLabels.tiers[biome.tier][language],
    directionTitle: biomeLabels.directions[biome.direction][language],
    image: `/assets/textures/environment/biomes/${biome.image}`,
    hazardTitle: biome.hazard ? biomeLabels.hazards[biome.hazard][language] : '',
    bossId: biome.boss ?? '',
  };
}


function localizedBiome(biome, language) {
  const text = biomeText[biome.id];
  const resourceBiome = biome.resourceBase ?? biome.resource;
  const resources = [...(biomeResourceIds.get(resourceBiome) ?? new Map()).entries()]
    .map(([itemId, source]) => ({ ...localizedBossItem(itemId, 1, language), source }))
    .sort((left, right) => left.title.localeCompare(right.title, language));
  const mobs = [...mobsById.values()]
    .filter((mob) => mob.biomeResource === biome.resource)
    .map((mob) => localizedMob(mob, language));
  const boss = biome.boss && bossesById.has(biome.boss) ? localizedBoss(bossesById.get(biome.boss), language) : null;
  const accessItem = biome.accessItem ? localizedBossItem(biome.accessItem, 1, language) : null;
  const requiredBoss = biome.requiredBoss && bossesById.has(biome.requiredBoss) ? localizedBoss(bossesById.get(biome.requiredBoss), language) : null;
  const npc = npcs.find((entry) => entry.biomeResource === biome.resource);
  const biomeIndex = biomeDefinitions.indexOf(biome);
  return {
    ...localizedBiomeSummary(biome, language),
    description: text.description[language],
    preparation: text.preparation[language],
    resourceInheritance: biome.resourceBase ? biomeDefinitions.find((entry) => entry.resource === biome.resourceBase)?.title[language] ?? '' : '',
    hazardRate: biome.hazardRate ?? 0,
    exposureSeconds: biome.hazardRate ? Math.ceil(100 / biome.hazardRate) : 0,
    accessItem,
    requiredBoss,
    resources,
    mobs,
    boss,
    npc: npc ? localizedNpcSummary(npc, language) : null,
    previous: biomeIndex > 0 ? localizedBiomeSummary(biomeDefinitions[biomeIndex - 1], language) : null,
    next: biomeIndex < biomeDefinitions.length - 1 ? localizedBiomeSummary(biomeDefinitions[biomeIndex + 1], language) : null,
  };
}


function localizedWorld(language) {
  return {
    id: 'overworld',
    title: language === 'en' ? 'Overworld' : 'Верхний мир',
    description: language === 'en'
      ? 'The first world. Its biomes unlock from the safe hub outward.'
      : 'Первый мир. Биомы открываются от безопасного центра к внешним кольцам.',
    biomes: biomeDefinitions.map((biome) => localizedBiomeSummary(biome, language)),
  };
}


function wikiSearchEntries(language) {
  const entries = [];
  const sectionEntries = language === 'ru' ? [
    ['item', 'items', 'Предметы', 'Полный каталог игровых предметов, материалов, инструментов и компонентов.', '/ru/items'],
    ['recipe', 'recipes', 'Рецепты', 'Каталог ручного изготовления и кулинарии с ингредиентами, эпохами и особыми условиями открытия.', '/ru/recipes'],
    ['machine', 'machines', 'Техника', 'Каталог машин, генераторов, конвейеров и хранилищ.', '/ru/machines'],
    ['mob', 'mobs', 'Мобы', 'Обычные противники Верхнего мира, сгруппированные по биомам.', '/ru/mobs'],
    ['boss', 'bosses', 'Боссы', 'Цепочка боссов Верхнего мира, способности и добыча.', '/ru/bosses'],
    ['biome', 'overworld', 'Верхний мир', 'Карта биомов, опасности, ресурсы и подготовка к экспедициям.', '/ru/worlds/overworld'],
    ['technology', 'technology-tree', 'Технологическое развитие', 'Одиннадцать этапов промышленного развития и их требования.', '/ru/technologies'],
    ['system', 'systems', 'Производственные системы', 'Энергия, жидкости, предметная логистика и цифровое хранение ME.', '/ru/systems'],
    ['fluid', 'fluids', 'Жидкости и газы', 'Вода, пар, нефть, топливные фракции и расплавы металлов.', '/ru/fluids'],
    ['quest', 'quest-book', 'Квестовая книга', 'Шесть эпох квестов от первых ресурсов до промышленного финала.', '/ru/quests'],
    ['achievement', 'achievements', 'Достижения', 'Двадцать две контрольные цели за квесты, эпохи, боссов и развитие фабрики.', '/ru/achievements'],
    ['mechanic', 'mechanics', 'Игровые механики', 'Здоровье, голод, опасности биомов, экипировка, бой и передвижение.', '/ru/mechanics'],
    ['gathering', 'gathering', 'Добыча ресурсов', 'Ручная добыча, рудные жилы, буры, фермерство, собирательство и жидкостные залежи.', '/ru/gathering'],
    ['interface', 'interface', 'Управление и интерфейс', 'Клавиши, инвентарь, строительство, книги, карта, сохранения и совместная игра.', '/ru/interface'],
    ['exploration', 'exploration', 'Исследование мира', 'Время, погода, карта, обелиски, генерация мира и предметы на земле.', '/ru/exploration'],
    ['optimization', 'optimization', 'Оптимизация фабрики', 'Модули, контроль выхода и запасов, координация сборщиков, диагностика и анализ линий.', '/ru/optimization'],
    ['multiplayer', 'multiplayer', 'Совместная игра', 'Создание сессии, мир хоста, синхронизация строительства, предметов, машин, чат и метки.', '/ru/multiplayer'],
    ['energy', 'energy', 'Энергетика', 'Генераторы, распределение EU, накопители, солнечная энергия и диагностика сети.', '/ru/energy'],
    ['logistics', 'logistics', 'Предметная логистика', 'Конвейеры, манипуляторы, фильтры, запросы ингредиентов и диагностика заторов.', '/ru/logistics'],
    ['steam', 'steam', 'Паровые технологии', 'Водоснабжение, котлы, топливо, трубы, паровые машины и диагностика.', '/ru/steam'],
    ['ore-processing', 'ore-processing', 'Переработка руды', 'Дробление, промывка, магнитная сепарация, центрифуга, плавка и расплавы.', '/ru/ore-processing'],
    ['npc', 'npcs', 'Персонажи', 'Жители биомов Верхнего мира и их цепочки побочных заданий.', '/ru/npcs'],
  ] : [
    ['item', 'items', 'Items', 'The complete catalog of game items, materials, tools, and components.', '/en/items'],
    ['recipe', 'recipes', 'Recipes', 'A hand-crafting and cooking catalog with ingredients, ages, and special unlock conditions.', '/en/recipes'],
    ['machine', 'machines', 'Machines', 'A catalog of machines, generators, conveyors, and storage.', '/en/machines'],
    ['mob', 'mobs', 'Mobs', 'Common Overworld enemies grouped by biome.', '/en/mobs'],
    ['boss', 'bosses', 'Bosses', 'The Overworld boss chain, abilities, and loot.', '/en/bosses'],
    ['biome', 'overworld', 'Overworld', 'Biome map, hazards, resources, and expedition preparation.', '/en/worlds/overworld'],
    ['technology', 'technology-tree', 'Technology progression', 'Eleven stages of industrial progression and their requirements.', '/en/technologies'],
    ['system', 'systems', 'Factory systems', 'Power, fluids, item logistics, and ME digital storage.', '/en/systems'],
    ['fluid', 'fluids', 'Fluids and gases', 'Water, steam, petroleum fractions, fuels, and molten metals.', '/en/fluids'],
    ['quest', 'quest-book', 'Quest book', 'Six quest ages from first resources to the industrial finale.', '/en/quests'],
    ['achievement', 'achievements', 'Achievements', 'Twenty-two milestones covering quests, ages, bosses, and factory growth.', '/en/achievements'],
    ['mechanic', 'mechanics', 'Gameplay mechanics', 'Health, hunger, environmental hazards, equipment, combat, and movement.', '/en/mechanics'],
    ['gathering', 'gathering', 'Resource gathering', 'Manual mining, ore deposits, drills, farming, foraging, and fluid deposits.', '/en/gathering'],
    ['interface', 'interface', 'Controls and interface', 'Keys, inventory, building, books, map, saves, and multiplayer.', '/en/interface'],
    ['exploration', 'exploration', 'World exploration', 'Time, weather, map, obelisks, world generation, and dropped items.', '/en/exploration'],
    ['optimization', 'optimization', 'Factory optimization', 'Modules, output and stock control, assembler coordination, diagnostics, and line analysis.', '/en/optimization'],
    ['multiplayer', 'multiplayer', 'Multiplayer', 'Hosting, host-world synchronization, shared building, drops, machines, chat, and pings.', '/en/multiplayer'],
    ['energy', 'energy', 'Energy', 'Generators, EU distribution, storage, solar power, and grid diagnostics.', '/en/energy'],
    ['logistics', 'logistics', 'Item logistics', 'Conveyors, inserters, filters, ingredient demand, and jam diagnostics.', '/en/logistics'],
    ['steam', 'steam', 'Steam technology', 'Water supply, boilers, fuel, pipes, steam machines, and diagnostics.', '/en/steam'],
    ['ore-processing', 'ore-processing', 'Ore processing', 'Crushing, washing, magnetic separation, centrifuging, smelting, and molten metals.', '/en/ore-processing'],
    ['npc', 'npcs', 'Characters', 'Overworld biome residents and their side-quest chains.', '/en/npcs'],
  ];
  for (const [type, id, title, description, url] of sectionEntries) entries.push({ type, id, title, description, meta: language === 'ru' ? 'Раздел вики' : 'Wiki section', url });
  for (const item of itemsById.values()) {
    const localized = localizedItem(item, language);
    entries.push({ type: 'item', id: item.id, title: localized.title, description: localized.description || localized.categoryTitle, meta: localized.categoryTitle, url: `/${language}/items/${encodeURIComponent(item.id)}`, texture: localized.texture, color: localized.color });
  }
  for (const recipe of recipes) {
    const localized = localizedRecipe(recipe, language);
    const unlockMeta = recipe.unlockedByItem
      ? (language === 'ru' ? 'страница рецепта' : 'recipe page')
      : `${language === 'ru' ? 'эпоха' : 'age'} ${localized.requiredAge}`;
    entries.push({
      type: 'recipe', id: recipe.id, title: localized.result.title,
      description: language === 'ru'
        ? `${localized.ingredients.length} видов ингредиентов, результат × ${localized.resultCount}.`
        : `${localized.ingredients.length} ingredient types, result × ${localized.resultCount}.`,
      meta: `${localized.categoryTitle} · ${unlockMeta}`,
      searchText: localized.ingredients.map((ingredient) => `${ingredient.title} ${ingredient.id}`).join(' '),
      url: `/${language}/recipes/${encodeURIComponent(recipe.id)}`,
      texture: localized.result.texture,
      color: localized.result.color,
    });
  }
  for (const machine of machinesById.values()) {
    const localized = localizedMachine(machine, language);
    entries.push({ type: 'machine', id: machine.id, title: localized.title, description: localized.description, meta: localized.categoryTitle, url: `/${language}/machines/${encodeURIComponent(machine.id)}`, texture: localized.texture, color: localized.color });
  }
  for (const mob of mobsById.values()) {
    const localized = localizedMob(mob, language);
    entries.push({ type: 'mob', id: mob.id, title: localized.title, description: localized.description, meta: `${localized.biomeTitle} · ${localized.roleTitle}`, searchText: `${localized.loot.title} ${localized.loot.id}`, url: `/${language}/mobs/${encodeURIComponent(mob.id)}`, portrait: localized.portrait, color: localized.color });
  }
  for (const boss of bossesById.values()) {
    const localized = localizedBoss(boss, language);
    entries.push({ type: 'boss', id: boss.id, title: localized.title, description: localized.description, meta: localized.biomeTitle, searchText: localized.loot.map((item) => `${item.title} ${item.id}`).join(' '), url: `/${language}/bosses/${encodeURIComponent(boss.id)}`, portrait: localized.portrait, color: localized.color });
  }
  for (const biome of biomeDefinitions) {
    const localized = localizedBiome(biome, language);
    const searchText = [...localized.resources.map((item) => `${item.title} ${item.id}`), ...localized.mobs.map((mob) => `${mob.title} ${mob.id}`), localized.boss?.title ?? '', localized.accessItem?.title ?? ''].join(' ');
    entries.push({ type: 'biome', id: biome.id, title: localized.title, description: localized.description, meta: `${localized.tierTitle} · ${localized.directionTitle}`, searchText, url: `/${language}/worlds/overworld/biomes/${encodeURIComponent(biome.id)}`, image: localized.image });
  }
  for (const stage of technologyStages) {
    const localized = localizedTechnologySummary(stage, language);
    const icon = stage.machines.length ? localizedTechnologyOutput(stage.machines[0], language) : null;
    const searchText = [...stage.machines, ...stage.components, ...stage.research.map((entry) => entry.id), localized.boss?.title ?? ''].join(' ');
    entries.push({ type: 'technology', id: stage.id, title: localized.title, description: localized.description, meta: localized.biome?.title ?? '', searchText, url: `/${language}/technologies/${encodeURIComponent(stage.id)}`, texture: icon?.texture, color: icon?.color });
  }
  for (const guide of systemGuides) {
    const localized = localizedSystemGuide(guide, language);
    const icon = localized.equipment.find((entry) => entry.texture) ?? null;
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.stages.flatMap((stage) => [stage.title, stage.text, ...stage.links.flatMap((entry) => [entry.title, entry.id])]),
      ...localized.tips,
    ].join(' ');
    entries.push({
      type: 'system', id: guide.id, title: localized.title, description: localized.intro,
      meta: localized.subtitle, searchText, url: `/${language}/systems/${encodeURIComponent(guide.id)}`,
      texture: icon?.texture, color: localized.color,
    });
  }
  for (const fluid of fluidsById.values()) {
    const localized = localizedFluid(fluid, language);
    const searchText = [
      ...localized.sources.flatMap((recipe) => [recipe.machine.title, ...recipe.inputs.map((part) => part.title), ...recipe.outputs.map((part) => part.title)]),
      ...localized.uses.flatMap((recipe) => [recipe.machine.title, ...recipe.inputs.map((part) => part.title), ...recipe.outputs.map((part) => part.title)]),
    ].join(' ');
    entries.push({
      type: 'fluid', id: fluid.id, title: localized.title, description: localized.description,
      meta: localized.categoryTitle, searchText, url: `/${language}/fluids/${encodeURIComponent(fluid.id)}`,
      color: localized.color,
    });
  }
  for (const achievement of achievements) {
    const localized = localizedAchievement(achievement, language);
    entries.push({
      type: 'achievement', id: achievement.id, title: localized.title, description: localized.description,
      meta: localized.categoryTitle,
      searchText: [localized.requirement, localized.icon.title, ...localized.related.map((entry) => entry.title)].join(' '),
      url: `/${language}/achievements/${encodeURIComponent(achievement.id)}`,
      texture: localized.icon.texture,
      color: localized.color,
    });
  }
  for (const mechanic of mechanicDefinitions) {
    const localized = localizedMechanic(mechanic, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'mechanic', id: mechanic.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/mechanics/${encodeURIComponent(mechanic.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of gatheringDefinitions) {
    const localized = localizedGathering(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [
        section.title,
        section.intro,
        ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)]),
      ]),
    ].join(' ');
    entries.push({
      type: 'gathering', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/gathering/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of interfaceDefinitions) {
    const localized = localizedInterface(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'interface', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/interface/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of explorationDefinitions) {
    const localized = localizedExploration(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'exploration', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/exploration/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of optimizationDefinitions) {
    const localized = localizedOptimization(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'optimization', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/optimization/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of multiplayerDefinitions) {
    const localized = localizedMultiplayer(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'multiplayer', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/multiplayer/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of energyDefinitions) {
    const localized = localizedEnergy(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'energy', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/energy/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of logisticsDefinitions) {
    const localized = localizedLogistics(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'logistics', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/logistics/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of steamDefinitions) {
    const localized = localizedSteam(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'steam', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/steam/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const guide of oreProcessingDefinitions) {
    const localized = localizedOreProcessing(guide, language);
    const searchText = [
      ...localized.facts.flatMap((fact) => [fact.label, fact.value]),
      ...localized.sections.flatMap((section) => [section.title, section.intro, ...section.entries.flatMap((entry) => [entry.title, entry.text, entry.value, ...entry.links.map((link) => link.title)])]),
    ].join(' ');
    entries.push({
      type: 'ore-processing', id: guide.id, title: localized.title, description: localized.description,
      meta: localized.subtitle, searchText, url: `/${language}/ore-processing/${encodeURIComponent(guide.id)}`,
      texture: localized.icon.texture, color: localized.color,
    });
  }
  for (const quest of quests) {
    const localized = localizedQuest(quest, language);
    const age = questAgeText.find((entry) => entry.age === quest.age);
    const searchText = [...localized.objectives.flatMap((objective) => [objective.description, objective.eventDetail, objective.target?.title ?? '']), ...localized.unlocks].join(' ');
    entries.push({
      type: 'quest', id: quest.id, title: localized.title, description: localized.description,
      meta: `${age?.title[language] ?? ''} · ${localized.tab}`,
      searchText,
      url: `/${language}/quests/${quest.age}?q=${encodeURIComponent(quest.id)}`,
    });
  }
  for (const npc of npcs) {
    const localized = localizedNpc(npc, language);
    entries.push({
      type: 'npc', id: npc.id, title: localized.title, description: localized.greeting,
      meta: [localized.role, localized.biome?.title].filter(Boolean).join(' · '),
      searchText: localized.quests.map((quest) => `${quest.title} ${quest.description}`).join(' '),
      url: `/${language}/npcs/${encodeURIComponent(npc.id)}`,
      color: localized.color,
    });
    for (const quest of localized.quests) {
      const searchText = [
        ...quest.objectives.flatMap((objective) => [objective.description, objective.eventDetail, objective.target?.title ?? '']),
        ...quest.rewards.flatMap((reward) => [reward.title, reward.id]),
        ...quest.unlocks,
      ].join(' ');
      entries.push({
        type: 'npc', id: quest.id, title: quest.title, description: quest.description,
        meta: [localized.title, localized.biome?.title].filter(Boolean).join(' · '),
        searchText,
        url: `/${language}/npcs/${encodeURIComponent(npc.id)}?q=${encodeURIComponent(quest.id)}`,
        color: localized.color,
      });
    }
  }
  entries.push({
    type: 'guide', id: 'getting-started',
    title: language === 'ru' ? 'Начало игры' : 'Getting started',
    description: language === 'ru' ? 'Пошаговое руководство от первых ресурсов до паровой фабрики, Энта и дерева технологий.' : 'A step-by-step guide from first resources to a steam factory, the Ent, and the technology tree.',
    meta: language === 'ru' ? 'Руководство для новых игроков' : 'New player guide',
    url: `/${language}/guides/getting-started`,
  });
  return entries;
}


function wikiSearch(language, rawQuery) {
  const query = String(rawQuery ?? '').trim().slice(0, 100);
  if (!query) return { query, total: 0, count: 0, results: [] };
  const normalizedQuery = query.toLocaleLowerCase(language);
  const terms = normalizedQuery.split(/\s+/).filter(Boolean);
  const matches = [];
  for (const entry of wikiSearchEntries(language)) {
    const title = entry.title.toLocaleLowerCase(language);
    const id = entry.id.toLocaleLowerCase(language);
    const description = entry.description.toLocaleLowerCase(language);
    const meta = entry.meta.toLocaleLowerCase(language);
    const searchText = (entry.searchText ?? '').toLocaleLowerCase(language);
    const haystack = `${title} ${id} ${description} ${meta} ${searchText}`;
    if (!terms.every((term) => haystack.includes(term))) continue;
    let score = 0;
    if (title === normalizedQuery) score += 120;
    else if (title.startsWith(normalizedQuery)) score += 85;
    else if (title.includes(normalizedQuery)) score += 60;
    if (id === normalizedQuery) score += 110;
    else if (id.startsWith(normalizedQuery)) score += 70;
    else if (id.includes(normalizedQuery)) score += 45;
    for (const term of terms) {
      if (title.includes(term)) score += 12;
      if (id.includes(term)) score += 9;
      if (meta.includes(term)) score += 4;
      if (description.includes(term)) score += 2;
      if (searchText.includes(term)) score += 1;
    }
    matches.push({ ...entry, score });
  }
  matches.sort((left, right) => right.score - left.score || left.title.localeCompare(right.title, language));
  const results = matches.slice(0, 100).map(({ score, searchText, ...entry }) => entry);
  return { query, total: matches.length, count: results.length, results };
}


function handleItemsApi(response, route, language) {
  if (route.length === 4) {
    const items = [...itemsById.values()]
      .map((item) => localizedItem(item, language))
      .sort((left, right) => left.title.localeCompare(right.title, language));
    sendJson(response, 200, { count: items.length, items });
    return;
  }
  const item = itemsById.get(route[4]);
  if (!item) {
    sendJson(response, 404, { error: 'item_not_found' });
    return;
  }
  sendJson(response, 200, itemDetails(item, language));
}


function handleRecipesApi(response, route, language) {
  if (route.length === 4) {
    const categories = Object.keys(recipeCategoryTitles).map((id) => ({
      id,
      title: recipeCategoryTitles[id][language],
      count: recipes.filter((recipe) => recipe.category === id).length,
    })).filter((category) => category.count > 0);
    sendJson(response, 200, {
      count: recipes.length,
      categories,
      recipes: recipes.map((recipe) => localizedRecipeSummary(recipe, language)),
    });
    return;
  }
  const recipe = recipes.find((entry) => entry.id === route[4]);
  if (!recipe) {
    sendJson(response, 404, { error: 'recipe_not_found' });
    return;
  }
  sendJson(response, 200, { recipe: localizedRecipeDetails(recipe, language) });
}


function handleCraftingBalanceApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, craftingBalanceCatalog(language));
    return;
  }
  const recipe = craftingBalanceDetails(route[4], language);
  if (!recipe) {
    sendJson(response, 404, { error: 'recipe_not_found' });
    return;
  }
  sendJson(response, 200, { recipe });
}


function handleBossesApi(response, route, language) {
  if (route.length === 4) {
    const bosses = [...bossesById.values()].map((boss) => localizedBoss(boss, language));
    sendJson(response, 200, { count: bosses.length, bosses });
    return;
  }
  const boss = bossesById.get(route[4]);
  if (!boss) {
    sendJson(response, 404, { error: 'boss_not_found' });
    return;
  }
  sendJson(response, 200, { boss: localizedBoss(boss, language) });
}


function handleMobsApi(response, route, language) {
  if (route.length === 4) {
    const mobs = [...mobsById.values()].map((mob) => localizedMob(mob, language));
    sendJson(response, 200, { count: mobs.length, mobs });
    return;
  }
  const mob = mobsById.get(route[4]);
  if (!mob) {
    sendJson(response, 404, { error: 'mob_not_found' });
    return;
  }
  sendJson(response, 200, { mob: localizedMob(mob, language) });
}


function handleMachinesApi(response, route, language) {
  if (route.length === 4) {
    const machines = [...machinesById.values()].map((machine) => localizedMachine(machine, language));
    sendJson(response, 200, { count: machines.length, machines });
    return;
  }
  const machine = machinesById.get(route[4]);
  if (!machine) {
    sendJson(response, 404, { error: 'machine_not_found' });
    return;
  }
  sendJson(response, 200, machineDetails(machine, language));
}


function handleTechnologiesApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, { count: technologyStages.length, technologies: technologyStages.map((stage) => localizedTechnologySummary(stage, language)) });
    return;
  }
  const technology = technologyStages.find((stage) => stage.id === route[4]);
  if (!technology) {
    sendJson(response, 404, { error: 'technology_not_found' });
    return;
  }
  sendJson(response, 200, { technology: localizedTechnology(technology, language) });
}


function handleSystemsApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: systemGuides.length,
      systems: systemGuides.map((guide) => localizedSystemGuideSummary(guide, language)),
    });
    return;
  }
  const guide = systemGuides.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'system_not_found' });
    return;
  }
  sendJson(response, 200, { system: localizedSystemGuide(guide, language) });
}


function handleFluidsApi(response, route, language) {
  if (route.length === 4) {
    const fluids = [...fluidsById.values()].map((fluid) => localizedFluidSummary(fluid, language));
    sendJson(response, 200, { count: fluids.length, fluids });
    return;
  }
  const fluid = fluidsById.get(route[4]);
  if (!fluid) {
    sendJson(response, 404, { error: 'fluid_not_found' });
    return;
  }
  sendJson(response, 200, { fluid: localizedFluid(fluid, language) });
}


function handleAchievementsApi(response, route, language) {
  if (route.length === 4) {
    const categories = Object.keys(achievementCategoryTitles).map((id) => ({
      id,
      title: achievementCategoryTitles[id][language],
      count: achievements.filter((achievement) => achievement.category === id).length,
    }));
    sendJson(response, 200, {
      count: achievements.length,
      categories,
      achievements: achievements.map((achievement) => localizedAchievementSummary(achievement, language)),
    });
    return;
  }
  const achievement = achievements.find((entry) => entry.id === route[4]);
  if (!achievement) {
    sendJson(response, 404, { error: 'achievement_not_found' });
    return;
  }
  sendJson(response, 200, { achievement: localizedAchievement(achievement, language) });
}


function handleMechanicsApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: mechanicDefinitions.length,
      mechanics: mechanicDefinitions.map((mechanic) => localizedMechanicSummary(mechanic, language)),
    });
    return;
  }
  const mechanic = mechanicDefinitions.find((entry) => entry.id === route[4]);
  if (!mechanic) {
    sendJson(response, 404, { error: 'mechanic_not_found' });
    return;
  }
  sendJson(response, 200, { mechanic: localizedMechanic(mechanic, language) });
}


function handleGatheringApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: gatheringDefinitions.length,
      gathering: gatheringDefinitions.map((guide) => localizedGatheringSummary(guide, language)),
    });
    return;
  }
  const guide = gatheringDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'gathering_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedGathering(guide, language) });
}


function handleInterfaceApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: interfaceDefinitions.length,
      guides: interfaceDefinitions.map((guide) => localizedInterfaceSummary(guide, language)),
    });
    return;
  }
  const guide = interfaceDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'interface_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedInterface(guide, language) });
}


function handleExplorationApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: explorationDefinitions.length,
      guides: explorationDefinitions.map((guide) => localizedExplorationSummary(guide, language)),
    });
    return;
  }
  const guide = explorationDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'exploration_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedExploration(guide, language) });
}


function handleOptimizationApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: optimizationDefinitions.length,
      guides: optimizationDefinitions.map((guide) => localizedOptimizationSummary(guide, language)),
    });
    return;
  }
  const guide = optimizationDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'optimization_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedOptimization(guide, language) });
}


function handleMultiplayerApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: multiplayerDefinitions.length,
      guides: multiplayerDefinitions.map((guide) => localizedMultiplayerSummary(guide, language)),
    });
    return;
  }
  const guide = multiplayerDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'multiplayer_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedMultiplayer(guide, language) });
}


function handleEnergyApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: energyDefinitions.length,
      guides: energyDefinitions.map((guide) => localizedEnergySummary(guide, language)),
    });
    return;
  }
  const guide = energyDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'energy_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedEnergy(guide, language) });
}


function handleLogisticsApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: logisticsDefinitions.length,
      guides: logisticsDefinitions.map((guide) => localizedLogisticsSummary(guide, language)),
    });
    return;
  }
  const guide = logisticsDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'logistics_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedLogistics(guide, language) });
}


function handleSteamApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: steamDefinitions.length,
      guides: steamDefinitions.map((guide) => localizedSteamSummary(guide, language)),
    });
    return;
  }
  const guide = steamDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'steam_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedSteam(guide, language) });
}


function handleOreProcessingApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: oreProcessingDefinitions.length,
      guides: oreProcessingDefinitions.map((guide) => localizedOreProcessingSummary(guide, language)),
    });
    return;
  }
  const guide = oreProcessingDefinitions.find((entry) => entry.id === route[4]);
  if (!guide) {
    sendJson(response, 404, { error: 'ore_processing_guide_not_found' });
    return;
  }
  sendJson(response, 200, { guide: localizedOreProcessing(guide, language) });
}


function handleQuestsApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: quests.length,
      ages: questAgeText.map((ageInfo) => localizedQuestAgeSummary(ageInfo, language)),
    });
    return;
  }
  const age = Number(route[4]);
  const ageInfo = questAgeText.find((entry) => entry.age === age);
  if (!ageInfo) {
    sendJson(response, 404, { error: 'quest_age_not_found' });
    return;
  }
  sendJson(response, 200, { age: localizedQuestAge(ageInfo, language) });
}


function handleNpcsApi(response, route, language) {
  if (route.length === 4) {
    sendJson(response, 200, {
      count: npcs.length,
      questCount: npcs.reduce((total, npc) => total + npc.quests.length, 0),
      npcs: npcs.map((npc) => localizedNpcSummary(npc, language)),
    });
    return;
  }
  const npc = npcs.find((entry) => entry.id === route[4]);
  if (!npc) {
    sendJson(response, 404, { error: 'npc_not_found' });
    return;
  }
  sendJson(response, 200, { npc: localizedNpc(npc, language) });
}


function handleApi(response, route, searchParams) {
  const [, , language, resource, worldId, collection, biomeId] = route;
  if (!languages.has(language)) {
    sendJson(response, 404, { error: 'not_found' });
    return;
  }
  if (resource === 'items') {
    handleItemsApi(response, route, language);
    return;
  }
  if (resource === 'recipes') {
    handleRecipesApi(response, route, language);
    return;
  }
  if (resource === 'crafting-balance') {
    handleCraftingBalanceApi(response, route, language);
    return;
  }
  if (resource === 'bosses') {
    handleBossesApi(response, route, language);
    return;
  }
  if (resource === 'mobs') {
    handleMobsApi(response, route, language);
    return;
  }
  if (resource === 'machines') {
    handleMachinesApi(response, route, language);
    return;
  }
  if (resource === 'technologies') {
    handleTechnologiesApi(response, route, language);
    return;
  }
  if (resource === 'systems') {
    handleSystemsApi(response, route, language);
    return;
  }
  if (resource === 'fluids') {
    handleFluidsApi(response, route, language);
    return;
  }
  if (resource === 'achievements') {
    handleAchievementsApi(response, route, language);
    return;
  }
  if (resource === 'mechanics') {
    handleMechanicsApi(response, route, language);
    return;
  }
  if (resource === 'gathering') {
    handleGatheringApi(response, route, language);
    return;
  }
  if (resource === 'interface') {
    handleInterfaceApi(response, route, language);
    return;
  }
  if (resource === 'exploration') {
    handleExplorationApi(response, route, language);
    return;
  }
  if (resource === 'optimization') {
    handleOptimizationApi(response, route, language);
    return;
  }
  if (resource === 'multiplayer') {
    handleMultiplayerApi(response, route, language);
    return;
  }
  if (resource === 'energy') {
    handleEnergyApi(response, route, language);
    return;
  }
  if (resource === 'logistics') {
    handleLogisticsApi(response, route, language);
    return;
  }
  if (resource === 'steam') {
    handleSteamApi(response, route, language);
    return;
  }
  if (resource === 'ore-processing') {
    handleOreProcessingApi(response, route, language);
    return;
  }
  if (resource === 'quests') {
    handleQuestsApi(response, route, language);
    return;
  }
  if (resource === 'npcs') {
    handleNpcsApi(response, route, language);
    return;
  }
  if (resource === 'search-index' && route.length === 4) {
    sendJson(response, 200, { entries: wikiSearchEntries(language) });
    return;
  }
  if (resource === 'search' && route.length === 4) {
    sendJson(response, 200, wikiSearch(language, searchParams.get('q')));
    return;
  }
  if (resource !== 'worlds') {
    sendJson(response, 404, { error: 'not_found' });
    return;
  }
  if (route.length === 4) {
    sendJson(response, 200, { worlds: [localizedWorld(language)] });
    return;
  }
  if (worldId !== 'overworld') {
    sendJson(response, 404, { error: 'world_not_found' });
    return;
  }
  const world = localizedWorld(language);
  if (route.length === 5) {
    sendJson(response, 200, world);
    return;
  }
  if (collection !== 'biomes') {
    sendJson(response, 404, { error: 'not_found' });
    return;
  }
  if (route.length === 6) {
    sendJson(response, 200, { world: world.id, biomes: world.biomes });
    return;
  }
  const biome = biomeDefinitions.find((entry) => entry.id === biomeId);
  if (!biome) {
    sendJson(response, 404, { error: 'biome_not_found' });
    return;
  }
  sendJson(response, 200, { world: world.id, biome: localizedBiome(biome, language) });
}


function isWikiPageRoute(route) {
  if (!languages.has(route[0])) return false;
  if (route.length === 2) return pageRoutes.has(route[1]);
  if (route[1] === 'items') return route.length === 3 && itemsById.has(route[2]);
  if (route[1] === 'recipes') return route.length === 3 && recipes.some((recipe) => recipe.id === route[2]);
  if (route[1] === 'bosses') return route.length === 3 && bossesById.has(route[2]);
  if (route[1] === 'mobs') return route.length === 3 && mobsById.has(route[2]);
  if (route[1] === 'machines') return route.length === 3 && machinesById.has(route[2]);
  if (route[1] === 'technologies') return route.length === 3 && technologyStages.some((stage) => stage.id === route[2]);
  if (route[1] === 'systems') return route.length === 3 && systemGuides.some((guide) => guide.id === route[2]);
  if (route[1] === 'fluids') return route.length === 3 && fluidsById.has(route[2]);
  if (route[1] === 'achievements') return route.length === 3 && achievements.some((achievement) => achievement.id === route[2]);
  if (route[1] === 'mechanics') return route.length === 3 && mechanicDefinitions.some((mechanic) => mechanic.id === route[2]);
  if (route[1] === 'gathering') return route.length === 3 && gatheringDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'interface') return route.length === 3 && interfaceDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'exploration') return route.length === 3 && explorationDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'optimization') return route.length === 3 && optimizationDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'multiplayer') return route.length === 3 && multiplayerDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'energy') return route.length === 3 && energyDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'logistics') return route.length === 3 && logisticsDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'steam') return route.length === 3 && steamDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'ore-processing') return route.length === 3 && oreProcessingDefinitions.some((guide) => guide.id === route[2]);
  if (route[1] === 'quests') return route.length === 3 && questAgeText.some((entry) => entry.age === Number(route[2]));
  if (route[1] === 'npcs') return route.length === 3 && npcs.some((npc) => npc.id === route[2]);
  if (route[1] === 'guides') return route.length === 3 && route[2] === 'getting-started';
  if (route[1] !== 'worlds' || route[2] !== 'overworld') return false;
  if (route.length === 3 || route.length === 4 && route[3] === 'biomes') return true;
  return route.length === 5 && route[3] === 'biomes' && biomeDefinitions.some((biome) => biome.id === route[4]);
}


const server = createWikiServer({
  assetsRoot,
  clientRoot,
  getHealth: () => ({
    status: 'ok',
    source: gameDataSource,
    counts: {
      items: itemsById.size,
      recipes: recipes.length,
      machines: machinesById.size,
      mobs: mobsById.size,
      bosses: bossesById.size,
    },
  }),
  handleApi,
  host,
  isWikiPageRoute,
  wikiPage,
});


const wikiUrl = `http://${host}:${port}/ru/home`;

function openWiki() {
  const command = process.platform === 'win32' ? `start "" "${wikiUrl}"` : `xdg-open "${wikiUrl}"`;
  exec(command);
}

server.once('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.log(`InfiniteForge Wiki is already running: ${wikiUrl}`);
    if (process.argv.includes('--open')) openWiki();
    return;
  }
  throw error;
});

server.listen(port, host, () => {
  console.log(`InfiniteForge Wiki: ${wikiUrl}`);
  console.log(`Game data (${gameDataSource}): ${projectRoot}`);
  if (process.argv.includes('--open')) openWiki();
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.once(signal, () => server.close(() => process.exit(0)));
}
