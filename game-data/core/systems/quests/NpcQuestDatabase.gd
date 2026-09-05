class_name NpcQuestDatabase

## NPC side-quests: each NPC has its own small, mostly
## self-contained quest chain (see [[project_npcs]]). These are handed in AT the
## NPC (the player claims the reward), unlike the age-progression quests which
## auto-complete. Loaded alongside the age quests by QuestManager; the shared
## event/progress/save machinery tracks them automatically.
##
## Each NPC quest has `age = 0` so it never counts toward the age chapters, and a
## non-empty `npc` field naming its owner. Quests within one NPC unlock
## sequentially (definition order = the chain).


## NPC metadata. `biome` matches the BiomeData.biome_name used by BiomeGenerator,
## so NpcRegistry can place each NPC deep inside the right biome band.
static func get_npcs() -> Array[Dictionary]:
	return [
		{
			"id": "mechanic_sam", "name": "Механик Сэм", "role": "Механик",
			"biome": "ForestBiome", "color": Color(0.24, 0.66, 0.34),
			"greeting": "О, свежие руки! Тут, в центральном лесу, всё начинается с металла и первой автоматизации. Поможешь — научу паре трюков.",
		},
		{
			"id": "forester_ted", "name": "Лесник Тэд", "role": "Лесник",
			"biome": "ForestBiome", "color": Color(0.24, 0.66, 0.34),
			"greeting": "Лес кормит и греет. Дерево, смола, волокно — всё в дело. Займёшься деревообработкой?",
		},
		{
			"id": "chemist_boris", "name": "Химик Борис", "role": "Химик",
			"biome": "SwampBiome", "color": Color(0.50, 0.62, 0.28),
			"greeting": "Болото воняет? Это запах прогресса, друг. Здесь рождается химпром: трубы, помпы, газ.",
		},
		{
			"id": "naturalist_lily", "name": "Натуралист Лили", "role": "Натуралист",
			"biome": "JungleBiome", "color": Color(0.42, 0.85, 0.32),
			"greeting": "Джунгли — фабрика природы. Собери каучук, а я покажу, как делать резину и быстрые ленты.",
		},
		{
			"id": "engineer_frost", "name": "Инженер Мороз", "role": "Инженер",
			"biome": "SnowBiome", "color": Color(0.72, 0.88, 0.98),
			"greeting": "Холодно? Заводы встают на морозе. Строим бойлеры и теплотрассы — иначе тут не выжить.",
		},
		{
			"id": "sheikh_silicon", "name": "Шейх Кремний", "role": "Магнат",
			"biome": "DesertBiome", "color": Color(0.93, 0.82, 0.46),
			"greeting": "Песок — это кремний. Кремний — это микросхемы. Микросхемы — это власть. Работаем?",
		},
		{
			"id": "doctor_acid", "name": "Доктор Кислота", "role": "Токсиколог",
			"biome": "RottingBogBiome", "color": Color(0.58, 0.36, 0.66),
			"greeting": "Кислотные дожди разъедают всё живое и неживое. Нужны стойкие материалы и герметичные цеха.",
		},
		{
			"id": "archaeologist_sterling", "name": "Археолог Стерлинг", "role": "Археолог",
			"biome": "PrimevalThicketBiome", "color": Color(0.28, 0.62, 0.24),
			"greeting": "Древние знали толк в технологиях. В этих руинах — квантовые схемы и энергия без потерь.",
		},
		{
			"id": "warden_absolute", "name": "Смотритель «Абсолют»", "role": "Смотритель",
			"biome": "IcyAbyssBiome", "color": Color(0.45, 0.80, 0.96),
			"greeting": "Ниже −150°C обычные обогреватели бесполезны. Но холод открывает сверхпроводимость. И ядерное тепло.",
		},
		{
			"id": "scrap_ranger", "name": "Скрап-Рейнджер", "role": "Рейнджер",
			"biome": "SunnyCanyonBiome", "color": Color(0.96, 0.46, 0.22),
			"greeting": "Метеоритные дожди рушат постройки, а под ногами — спекшееся кварцевое стекло. Нужны тяжёлые буры и щиты.",
		},
	]


static func get_all_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []

	# ── Центральный лес · Механик Сэм ─────────────────────────────────────────
	_add(out, "mechanic_sam", [
		_q("sam_1", "Разведка недр", "Оцени, что скрывает лесная земля под ногами.",
			[_obj("Добыть медную руду", "mine_yield", "copper_ore", 15),
			 _obj("Добыть железную руду", "mine_yield", "iron_ore", 10)],
			["stone:20", "stick:10"], []),
		_q("sam_2", "Первая плавильня", "Наладь простейшую металлургию.",
			[_obj("Скрафтить печь", "item_crafted", "furnace", 1),
			 _obj("Скрафтить медные пластины", "item_crafted", "copper_plate", 8)],
			["iron_plate:8"], []),
		_q("sam_3", "Лента пошла", "Собери шестерни — сердце любой автоматизации.",
			[_obj("Скрафтить шестерёнки", "item_crafted", "gear", 4)],
			["iron_ingot:10"], ["Ранний доступ: Конвейер T1"]),
	])

	# ── Лес · Лесник Тэд ─────────────────────────────────────────────────────
	_add(out, "forester_ted", [
		_q("ted_1", "Лесоруб", "Лесу нужен уход, а тебе — древесина.",
			[_obj("Добыть древесину", "mine_yield", "wood", 40)],
			["wood_plank:16"], []),
		_q("ted_2", "Смола и волокно", "Собери органику для переработки.",
			[_obj("Собрать древесную смолу", "mine_yield", "tree_resin", 6),
			 _obj("Собрать растительное волокно", "mine_yield", "plant_fiber", 8)],
			["stick:20"], []),
		_q("ted_3", "Заготовки впрок", "Обеспечь склад досками и ящиком.",
			[_obj("Скрафтить доски", "item_crafted", "wood_plank", 20),
			 _obj("Скрафтить сундук", "item_crafted", "chest_t1", 1)],
			["apple:5", "coal:8"], []),
	])

	# ── Болото · Химик Борис ─────────────────────────────────────────────────
	_add(out, "chemist_boris", [
		_q("boris_1", "Болотные пробы", "Возьми образцы болотных руд.",
			[_obj("Добыть серебряную руду", "mine_yield", "silver_ore", 10),
			 _obj("Добыть свинцовую руду", "mine_yield", "lead_ore", 10)],
			["coal:12"], []),
		_q("boris_2", "Первые трубы", "Проложи основу для перекачки жидкостей.",
			[_obj("Скрафтить жидкостные трубы", "item_crafted", "fluid_pipe", 8),
			 _obj("Скрафтить резервуар T1", "item_crafted", "fluid_tank_t1", 1)],
			["iron_plate:6"], []),
		_q("boris_3", "Болотный газ", "Запусти первую перекачку.",
			[_obj("Скрафтить водяную помпу", "item_crafted", "water_pump", 1),
			 _obj("Открыть помпу", "machine_opened", "water_pump", 1)],
			["steel_ingot:4"], ["Ранний доступ: Нефтекачка"]),
	])

	# ── Джунгли · Натуралист Лили ────────────────────────────────────────────
	_add(out, "naturalist_lily", [
		_q("lily_1", "Сбор каучука", "Надрежь деревья и собери латекс.",
			[_obj("Собрать латекс", "mine_yield", "latex", 12)],
			["rubber:8"], []),
		_q("lily_2", "Вулканизация", "Переработай латекс в резину.",
			[_obj("Скрафтить резину", "item_crafted", "rubber", 10)],
			["plant_fiber:10"], []),
		_q("lily_3", "Скоростные ленты", "Собери детали для быстрых конвейеров.",
			[_obj("Скрафтить шестерёнки", "item_crafted", "gear", 6)],
			["copper_plate:10"], ["Ранний доступ: Компрессор"]),
	])

	# ── Зима · Инженер Мороз ─────────────────────────────────────────────────
	_add(out, "engineer_frost", [
		_q("frost_1", "Мерзлота", "Пробей промёрзший грунт.",
			[_obj("Собрать осколки льда", "mine_yield", "ice_shard", 10),
			 _obj("Добыть железную руду", "mine_yield", "iron_ore", 15)],
			["coal:16"], []),
		_q("frost_2", "Бойлерная", "Тепло начинается с печи и стали.",
			[_obj("Скрафтить печь", "item_crafted", "furnace", 1),
			 _obj("Скрафтить железные пластины", "item_crafted", "iron_plate", 10)],
			["steel_ingot:3"], []),
		_q("frost_3", "Теплотрасса", "Заготовь стальные плиты для обогрева.",
			[_obj("Скрафтить стальные пластины", "item_crafted", "steel_plate", 6)],
			["steel_plate:6"], ["Ранний доступ: Угольный генератор"]),
	])

	# ── Пустыня · Шейх Кремний ───────────────────────────────────────────────
	_add(out, "sheikh_silicon", [
		_q("silicon_1", "Пески богатств", "Просей пустыню в поисках золота.",
			[_obj("Добыть золотую руду", "mine_yield", "gold_ore", 12),
			 _obj("Собрать гравий", "mine_yield", "gravel", 20)],
			["gold_ingot:4"], []),
		_q("silicon_2", "Микросхемы", "Спаяй первые схемы.",
			[_obj("Скрафтить схему T1", "item_crafted", "circuit_t1", 3)],
			["copper_wire:16"], []),
		_q("silicon_3", "Солнечные поля", "Подготовь электронику для панелей.",
			[_obj("Скрафтить электронную плату", "item_crafted", "electronic_board", 2),
			 _obj("Скрафтить схему T1", "item_crafted", "circuit_t1", 2)],
			["gold_ingot:6"], ["Ранний доступ: Солнечная панель"]),
	])

	# ── Токсичная топь · Доктор Кислота ──────────────────────────────────────
	_add(out, "doctor_acid", [
		_q("acid_1", "Кислотный конденсат", "Добудь стойкую руду сквозь ядовитый туман.",
			[_obj("Добыть мифриловую руду", "mine_yield", "mythril_ore", 8)],
			["silver_ingot:4"], []),
		_q("acid_2", "Герметичные цеха", "Защити дыхание — собери противогаз.",
			[_obj("Скрафтить противогаз", "item_crafted", "gas_mask", 1)],
			["plastic:6"], []),
		_q("acid_3", "Нейтрализация", "Наладь выпуск кислотостойкого пластика.",
			[_obj("Скрафтить пластик", "item_crafted", "plastic", 8)],
			["mythril_ingot:3"], []),
	])

	# ── Древние руины · Археолог Стерлинг ────────────────────────────────────
	_add(out, "archaeologist_sterling", [
		_q("sterling_1", "Древние жилы", "Вскрой залежи, скрытые монолитами.",
			[_obj("Добыть титановую руду", "mine_yield", "titanium_ore", 8),
			 _obj("Добыть платиновую руду", "mine_yield", "platinum_ore", 6)],
			["titanium_ingot:2"], []),
		_q("sterling_2", "Квантовые процессоры", "Собери схемы уровня древних.",
			[_obj("Скрафтить схему T2", "item_crafted", "circuit_t2", 3)],
			["gold_ingot:6"], []),
		_q("sterling_3", "Энерго-пилоны", "Изготовь высшую схему для пилонов.",
			[_obj("Скрафтить схему T3", "item_crafted", "circuit_t3", 1)],
			["titanium_ingot:4"], []),
	])

	# ── Ледяная пустошь · Смотритель «Абсолют» ───────────────────────────────
	_add(out, "warden_absolute", [
		_q("absolute_1", "Абсолютный холод", "Добудь топливо для реактора.",
			[_obj("Добыть урановую руду", "mine_yield", "uranium_ore", 8)],
			["steel_plate:6"], []),
		_q("absolute_2", "Сверхпроводник", "Холод открывает нулевое сопротивление.",
			[_obj("Скрафтить электрумовый провод", "item_crafted", "electrum_wire", 8)],
			["circuit_t2:2"], []),
		_q("absolute_3", "Ядерное тепло", "Переработай уран для реактора.",
			[_obj("Обработать уран", "item_crafted", "uranium_processed", 2)],
			["steel_ingot:8"], []),
	])

	# ── Стеклянное плато · Скрап-Рейнджер ─────────────────────────────────────
	_add(out, "scrap_ranger", [
		_q("ranger_1", "Спекшееся стекло", "Выдержи жар — собери жаростойкий костюм.",
			[_obj("Скрафтить жаростойкий костюм", "item_crafted", "heat_suit", 1)],
			["plastic:8"], []),
		_q("ranger_2", "Тяжёлые буры", "Обычные буры кварц не берут — нужен стальной.",
			[_obj("Скрафтить стальной бур", "item_crafted", "steel_drill", 1)],
			["steel_plate:8"], []),
		_q("ranger_3", "Орбитальный щит", "Собери каркас и схему для силового щита.",
			[_obj("Скрафтить продвинутый корпус", "item_crafted", "advanced_machine_casing", 1),
			 _obj("Скрафтить схему T3", "item_crafted", "circuit_t3", 1)],
			["titanium_ingot:6"], []),
	])

	return out


# ── Builders ──────────────────────────────────────────────────────────────────

static func _add(out: Array[QuestData], npc_id: String, quests: Array) -> void:
	for q: QuestData in quests:
		q.npc = npc_id
		out.append(q)


static func _q(
	id: String, title: String, desc: String,
	objs: Array, rewards: Array, unlocks: Array
) -> QuestData:
	var q := QuestData.new()
	q.quest_id     = id
	q.age          = 0            # NPC quests are outside the age chapters
	q.tab          = ""
	q.title        = title
	q.description  = desc
	q.objectives.assign(objs)
	q.reward_items = PackedStringArray(rewards)
	q.unlocks      = PackedStringArray(unlocks)
	return q


static func _obj(desc: String, ev_type: String, ev_detail: String, count: int) -> QuestObjective:
	var o := QuestObjective.new()
	o.description    = desc
	o.event_type     = ev_type
	o.event_detail   = ev_detail
	o.required_count = count
	return o
