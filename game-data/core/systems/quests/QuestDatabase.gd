class_name QuestDatabase

## Number of chapters in the progression.
const AGE_COUNT := 6

const PROGRESSION_TAB_ORDER := {
	1: ["I. Первые шаги", "II. Руда и плавка", "III. Бронзовый век", "IV. Железо под землёй", "V. Хранение", "VI. Первая автоматизация", "Обучение: технологии"],
	2: ["I. Медная промышленность", "II. Прокат и детали", "III. Сила пара", "IV. Кокс и сталь", "V. Стальные инструменты", "VII. Сертификация паровой фабрики"],
	3: ["I. Железный прокат", "II. Стальные детали", "III. Каркасы машин", "IV. Логистика", "V. Буровая техника", "VI. Хранитель леса"],
	4: ["I. Исследование электричества", "II. Электросеть", "III. Дробилка и резина", "IV. Компоненты машин", "V. Исследование автоматизации", "VI. Снежные руды", "VII. Пар в ток", "Обучение: энергия", "Обучение: конвейеры", "Обучение: модули"],
	5: ["I. Тяжёлая промышленность", "II. Руды болот", "III. Пластик и электроника", "IV. Машины второго тира", "V. Сухая переработка", "VI. Титановые материалы", "VII. Промышленная химия", "VIII. Биотехнологии", "IX. Защита и возобновляемые ресурсы", "X. Солнечная энергия"],
	6: ["I. Солнечная индустрия", "II. Развитая энергетика", "III. Промышленное ядро", "IV. Компоненты третьего тира", "V. Вычислительный центр", "VI. Энергия будущего", "VII. Титановый бур", "VIII. Редкие руды", "IX. Продвинутый бур и мифрил", "X. Исследование Бездны", "XI. Молекулярные технологии", "XII. Исследование фронтира", "XIII. Технологии фронтира", "XIV. Квантовое исследование", "XV. Жидкости и химия", "XVI. Цифровое хранилище", "XVII. Легенда"],
}

const PROGRESSION_QUEST_PRIORITY := {
	"circuit_t2_first": -20,
	"advanced_casing": -10,
	"titanium_rush": -30,
	"titanium_processing": -20,
	"titanium_smelting": -10,
}


## Metadata for each chapter (index 0 = chapter 1).
static func get_ages() -> Array[Dictionary]:
	return [
		{"age": 1, "title": "Основание фабрики",   "subtitle": "От ручных инструментов до стали и первой автоматической линии."},
		{"age": 2, "title": "Индустриализация",    "subtitle": "Прокат, точные детали, сила пара и кокс."},
		{"age": 3, "title": "Железный век",        "subtitle": "Стальные каркасы, расширение логистики и бурового парка."},
		{"age": 4, "title": "Электрификация",      "subtitle": "Электричество, резина, автоматизация и руды Снежных земель."},
		{"age": 5, "title": "Электрический век",   "subtitle": "Болотные и джунглевые руды, электроника, сухая переработка и солнечная энергия."},
		{"age": 6, "title": "Промышленный век",    "subtitle": "Редкие руды, продвинутые буры, молекулярные технологии, жидкости и ME-сеть."},
	]


static func get_age_info(age: int) -> Dictionary:
	for info: Dictionary in get_ages():
		if int(info.get("age", 0)) == age:
			return info
	return {"age": age, "title": "Глава %d" % age, "subtitle": ""}


static func get_all_quests() -> Array[QuestData]:
	var quests: Array[QuestData] = []
	quests.append_array(_chapter_1())
	quests.append_array(_tutorials_chapter_1())
	quests.append_array(_chapter_2())
	quests.append_array(_chapter_3())
	quests.append_array(_chapter_4())
	quests.append_array(_tutorials_chapter_4())
	quests.append_array(_chapter_5())
	quests.append_array(_chapter_6())
	quests.append_array(_progression_additions())
	_refine_main_progression(quests)
	quests.append_array(_farming_quests())
	quests.append_array(_boss_quests())
	return quests


## Research milestones keep the main path synchronized with the separate boss
## tab without putting boss-kill objectives back into progression chapters.
static func _progression_additions() -> Array[QuestData]:
	return [
		_quest("research_electricity", 4, "I. Исследование электричества", "Электрическая эра",
			"Победи Энта во вкладке боссов, подготовь паровые исследовательские наборы и заверши анализ электричества.",
			[_obj("Исследовать электричество", "research_completed", "electricity", 1)],
			["Экстрактор, изоляция и электрические компоненты"]),
		_quest("research_automation", 4, "V. Исследование автоматизации", "Автоматизация",
			"Исследуй образец Песчаного колосса и докажи, что электрическая фабрика готова к массовому производству.",
			[_obj("Исследовать автоматизацию", "research_completed", "automation", 1)],
			["Компрессор, разветвители и новые производственные линии"]),
		_quest("research_industry", 5, "I. Тяжёлая промышленность", "Тяжёлая промышленность",
			"Победа над Ледяным стражем и наборы автоматизации открывают тяжёлые машины и доступ к болотным рудам.",
			[_obj("Исследовать тяжёлую промышленность", "research_completed", "industry", 1)],
			["Продвинутая переработка руды"]),
		_quest("nickel_discovery", 5, "II. Руды болот", "Никелевая жила",
			"Добудь никель в Болоте и переработай часть руды в пыль.",
			[
				_obj("Добыть никелевую руду", "mine_yield", "nickel_ore", 20),
				_obj("Получить никелевую пыль", "item_processed", "nickel_dust", 10),
			],
			["Никель для побочных и будущих сплавов"]),
		_quest("research_chemistry", 5, "VII. Промышленная химия", "Промышленная химия",
			"Проанализируй железу Болотной гидры и подготовь промышленную фабрику к химическим процессам.",
			[_obj("Исследовать промышленную химию", "research_completed", "chemistry", 1)],
			["Химический реактор и нефтепереработка"]),
		_quest("research_bioengineering", 5, "VIII. Биотехнологии", "Биоинженерия",
			"Исследуй сердце Шипастой матриархини и открой возобновляемое производство.",
			[_obj("Исследовать биоинженерию", "research_completed", "bioengineering", 1)],
			["Фермстанция, генератор булыжника и солнечная энергия"]),
		_quest("research_solar_industry", 6, "I. Солнечная индустрия", "Солнечная индустрия",
			"Заверши анализ ядра Солнечного тирана, чтобы перейти к усиленной энергетике.",
			[_obj("Исследовать солнечную индустрию", "research_completed", "solar_industry", 1)],
			["Продвинутые панели и энергохранилища"]),
		_quest("research_abyss_engineering", 6, "X. Исследование Бездны", "Инженерия Бездны",
			"Проанализируй чешую Левиафана бездны и подготовь фабрику к молекулярной обработке.",
			[_obj("Исследовать инженерию Бездны", "research_completed", "abyss_engineering", 1)],
			["Молекулярный трансформер и элитная энергетика"]),
		_quest("research_frontier", 6, "XII. Исследование фронтира", "Технологии фронтира",
			"Изучи корону Короля гнили и открой предельные промышленные технологии.",
			[_obj("Исследовать технологии фронтира", "research_completed", "frontier", 1)],
			["Абсолютная энергетика и конвейеры T5"]),
		_quest("research_quantum", 6, "XIV. Квантовое исследование", "Квантовая логистика",
			"Исследуй ядро Первобытного стража и заверши технологический путь Верхнего мира.",
			[_obj("Исследовать квантовую логистику", "research_completed", "quantum", 1)],
			["ME-сеть и квантовая логистика"]),
	]


## Reassigns legacy quests to a biome- and technology-safe order while keeping
## every quest id intact for existing save files.
static func _refine_main_progression(quests: Array[QuestData]) -> void:
	var original_order := {}
	for index: int in range(quests.size()):
		var quest: QuestData = quests[index]
		original_order[quest.quest_id] = index
		match quest.age:
			4:
				quest.tab = {
					"I. Первый ток": "II. Электросеть",
					"II. Дробилка и резонит": "III. Дробилка и резина",
					"III. Компоненты машин": "IV. Компоненты машин",
					"V. Пар в ток": "VII. Пар в ток",
				}.get(quest.tab, quest.tab)
			5:
				quest.tab = {
					"I. Солнечная энергия": "X. Солнечная энергия",
					"II. Пластик и электроника": "III. Пластик и электроника",
					"III. Машины второго тира": "IV. Машины второго тира",
					"IV. Полная переработка": "V. Сухая переработка",
					"V. Глубокая переработка": "V. Сухая переработка",
					"IX. Защита и материалы": "IX. Защита и возобновляемые ресурсы",
				}.get(quest.tab, quest.tab)
			6:
				quest.tab = {
					"I. Промышленное ядро": "III. Промышленное ядро",
					"II. Компоненты третьего тира": "IV. Компоненты третьего тира",
					"III. Вычислительный центр": "V. Вычислительный центр",
					"IV. Энергия будущего": "VI. Энергия будущего",
					"V. Титановые буры и мифрил": "IX. Продвинутый бур и мифрил",
					"VI. Молекулярные технологии": "XI. Молекулярные технологии",
					"VII. Жидкостные сплавы": "XV. Жидкости и химия",
					"VIII. Легенда": "XVII. Легенда",
				}.get(quest.tab, quest.tab)

	_set_layout(quests, ["lead_vein"], 4, "VI. Снежные руды")
	_set_layout(quests, ["silver_vein", "silver_smelting"], 4, "VI. Снежные руды")
	_set_layout(quests, ["red_dust_source", "magnetic_rods"], 4, "I. Первый ток")
	_set_layout(quests, ["gold_rush", "gold_smelting", "nickel_discovery"], 5, "II. Руды болот")
	_set_layout(quests, ["gold_rods", "gold_springs", "foil_press", "lens_grinding", "gold_wires", "sensors_quest", "emitters_quest"], 5, "III. Пластик и электроника")
	_set_layout(quests, ["titanium_rush", "titanium_processing", "titanium_smelting"], 5, "VI. Титановые материалы")
	_set_layout(quests, ["cobblegen_quest", "farming_quest", "carbon_tech", "hazard_suits"], 5, "IX. Защита и возобновляемые ресурсы")
	_set_layout(quests, ["solar_dawn", "solar_opened", "solar_farm"], 5, "X. Солнечная энергия")
	_set_layout(quests, ["advanced_solar", "energy_bank"], 6, "II. Развитая энергетика")
	_set_layout(quests, ["drill_head_titanium_quest", "titanium_drill_quest"], 6, "VII. Титановый бур")
	_set_layout(quests, ["platinum_industry", "uranium_agenda", "uranium_industry"], 6, "VIII. Редкие руды")
	_set_layout(quests, ["drill_head_advanced_quest", "advanced_drill_quest", "mythril_bore", "mythril_purity", "mythril_smelting", "mythril_dust_quest"], 6, "IX. Продвинутый бур и мифрил")
	_set_layout(quests, ["molecular_transformer_quest"], 6, "XI. Молекулярные технологии")
	_set_layout(quests, ["elite_solar_quest"], 6, "XI. Молекулярные технологии")
	_set_layout(quests, ["ultimate_solar_quest", "conveyor_t5_quest"], 6, "XIII. Технологии фронтира")

	var liquid_quests := [
		"water_logistics", "pump_opened", "fluid_pipes_quest", "fluid_tanks", "oil_extraction", "oil_opened",
		"ore_washing", "washer_opened", "washed_iron", "washed_copper", "ore_melter_quest", "melter_opened",
		"mold_making", "chemical_reactor_quest", "reactor_opened", "first_casting", "concrete_works",
		"carbon_chemistry", "big_tanks", "oil_refining", "distillation_opened", "maximum_fluid_storage",
		"mixer_quest", "mixer_placed", "mixer_opened", "molten_alloys",
	]
	_set_layout(quests, liquid_quests, 6, "XV. Жидкости и химия")
	_set_layout(quests, ["me_network", "me_cables_quest", "me_crafting", "me_automation", "me_cells_upgrade", "me_fluids", "me_assembler_quest", "me_64k_quest"], 6, "XVI. Цифровое хранилище")

	quests.sort_custom(_quest_precedes.bind(original_order))


static func _set_layout(quests: Array[QuestData], ids: Array, age: int, tab: String) -> void:
	for quest: QuestData in quests:
		if ids.has(quest.quest_id):
			quest.age = age
			quest.tab = tab


static func _quest_precedes(a: QuestData, b: QuestData, original_order: Dictionary) -> bool:
	if a.age != b.age:
		return a.age < b.age
	var tabs: Array = PROGRESSION_TAB_ORDER.get(a.age, [])
	var a_tab := tabs.find(a.tab)
	var b_tab := tabs.find(b.tab)
	a_tab = a_tab if a_tab >= 0 else 999
	b_tab = b_tab if b_tab >= 0 else 999
	if a_tab != b_tab:
		return a_tab < b_tab
	var a_priority := int(PROGRESSION_QUEST_PRIORITY.get(a.quest_id, 0))
	var b_priority := int(PROGRESSION_QUEST_PRIORITY.get(b.quest_id, 0))
	if a_priority != b_priority:
		return a_priority < b_priority
	return int(original_order.get(a.quest_id, 0)) < int(original_order.get(b.quest_id, 0))


## Independent combat quests shown in the Farming tab. Age 0 keeps them out of
## progression chapters; optional keeps every hunt available independently.
static func _farming_quests() -> Array[QuestData]:
	var quests: Array[QuestData] = []
	for biome: String in MobRegistry.ENTRIES:
		for mob: Dictionary in MobRegistry.get_for_biome(biome):
			var mob_id := str(mob.get("id", ""))
			if mob_id.is_empty():
				continue
			var quest := _quest(
				"farm_%s" % mob_id,
				0,
				"Фармилка",
				"mob.%s.name" % mob_id,
				"Убей 100 мобов этого вида.",
				[_obj("Убить 100 мобов", "mob_defeated", mob_id, 100)],
				[]
			)
			quest.optional = true
			quests.append(quest)
	return quests


## One independent quest per registered boss. The Ent keeps its historic quest
## id so existing progress files continue to recognize its completion.
static func _boss_quests() -> Array[QuestData]:
	var quests: Array[QuestData] = []
	for boss: Dictionary in BossRegistry.get_all():
		var boss_id := str(boss.get("id", ""))
		if boss_id.is_empty():
			continue
		var quest_id := "defeat_ent" if boss_id == "ent" else "defeat_boss_%s" % boss_id
		var quest := _quest(
			quest_id,
			0,
			"Боссы",
			"boss.%s.name" % boss_id,
			"Победи этого босса один раз.",
			[_obj("Убить босса", "boss_defeated", boss_id, 1)],
			[]
		)
		quest.optional = true
		quests.append(quest)
	return quests


static func _tutorials_chapter_1() -> Array[QuestData]:
	return [
		_tutorial(
			"tutorial_technology_tree", 1, "Обучение: технологии", "Путь развития",
			"Нажми N и открой дерево технологий. Новые биомы открывают направления исследований, а победы над боссами снимают блокировку со следующих уровней фабрики.",
			[_obj("Открыть дерево технологий [N]", "technology_tree_opened", "technology_tree", 1)],
			["Изучено: как открываются технологии"]
		),
	]


static func _tutorials_chapter_4() -> Array[QuestData]:
	return [
		_tutorial(
			"tutorial_power_grid", 4, "Обучение: энергия", "Рабочая энергосеть",
			"Поставь генератор, загрузи топливо и соедини его проводом с потребителем. Сеть считается рабочей, когда в ней есть генератор и машина, а дефицит энергии отсутствует.",
			[_obj("Запустить стабильную энергосеть", "power_grid_online", "healthy", 1)],
			["Изучено: производство, потребление и дефицит EU"],
			["lay_cables"]
		),
		_tutorial(
			"tutorial_conveyor_transport", 4, "Обучение: конвейеры", "Первый груз",
			"Соедини источник и приёмник лентой и подключи её к энергосети. Конвейер не забирает предметы сам: бур или машина должны передать груз на первую секцию, а направление ленты задаёт дальнейший маршрут.",
			[_obj("Переместить груз через 5 секций конвейера", "conveyor_item_moved", "", 5)],
			["Изучено: питание, направление и передача грузов"],
			["tutorial_power_grid"]
		),
		_tutorial(
			"tutorial_conveyor_filter", 4, "Обучение: конвейеры", "Умная сортировка",
			"Открой конвейер клавишей взаимодействия. Укажи ID предмета в фильтре либо измени режим и приоритет: разрешающий фильтр пропускает только список, блокирующий — всё кроме списка.",
			[_obj("Настроить непустой фильтр или приоритет", "conveyor_configured", "filter", 1)],
			["Изучено: фильтры и приоритеты"],
			["tutorial_conveyor_transport"]
		),
		_tutorial(
			"tutorial_power_overlay", 4, "Обучение: энергия", "Стабильная сеть",
			"Подключи генератор и потребителя проводом. Энергия распределяется автоматически между подключёнными машинами.",
			[_obj("Запустить стабильную энергосеть", "power_grid_online", "healthy", 1)],
			["Изучено: подключение генераторов и машин"],
			["tutorial_power_grid"]
		),
		_tutorial(
			"tutorial_module_craft", 4, "Обучение: модули", "Модернизация машины",
			"Создай модуль скорости. Он ускоряет обработку на 20%, но повышает расход энергии на 10%. Модули эффективности, вместимости и продуктивности меняют другие параметры машины.",
			[_obj("Скрафтить модуль скорости", "item_crafted", "machine_module_speed", 1)],
			["Изучено: преимущества и цена модулей"],
			["electric_smelting"]
		),
		_tutorial(
			"tutorial_module_install", 4, "Обучение: модули", "Установка модуля",
			"Открой производственную машину, возьми модуль скорости курсором и нажми на соответствующий слот. В машину можно установить до трёх модулей каждого типа.",
			[_obj("Установить модуль скорости в машину", "module_installed", "speed", 1)],
			["Изучено: установка и снятие модулей"],
			["tutorial_module_craft"]
		),
	]


# ══ Chapter 1: Основание фабрики ═════════════════════════════════════════════
# Единая последовательная цепочка прогресса (порядок = ход получения).
static func _chapter_1() -> Array[QuestData]:
	return [
		# ── I. Первые шаги ──────────────────────────────────────────────────
		_quest("gather_wood", 1, "I. Первые шаги", "Сруби дерево",
			"Собери древесину — первый ресурс выживания.",
			[_obj("Добыть древесину", "mine_yield", "wood", 10)],
			["Доски и палки"]),

		_quest("gather_stone", 1, "I. Первые шаги", "Собери камни",
			"Набей камней для первых инструментов.",
			[_obj("Добыть камень", "mine_yield", "stone", 10)],
			["Примитивные инструменты"]),

		_quest("gather_sticks", 1, "I. Первые шаги", "Собери палки",
			"Подбери сухие ветки — рукояти для первых инструментов.",
			[_obj("Собрать палки", "mine_yield", "stick", 6)],
			["Рецепты первых инструментов"]),

		_quest("wood_planks", 1, "I. Первые шаги", "Первые доски",
			"Расщепи брёвна на доски — универсальный материал.",
			[_obj("Скрафтить доски", "item_crafted", "wood_plank", 8)],
			["Верстак и сундуки"]),

		_quest("primitive_axe", 1, "I. Первые шаги", "Примитивный топор",
			"Свяжи камень и палку — получи топор.",
			[_obj("Скрафтить топор", "item_crafted", "primitive_axe", 1)],
			["Быстрая добыча дерева"]),

		_quest("lumberjack", 1, "I. Первые шаги", "Дровосек",
			"С топором дело идёт быстрее. Заготовь дров впрок.",
			[_obj("Добыть древесину", "mine_yield", "wood", 50)],
			["Запас досок на стройку"]),

		_quest("workbench", 1, "I. Первые шаги", "Верстак",
			"Собери верстак — основу всего крафта.",
			[_obj("Скрафтить верстак", "item_crafted", "workbench", 1)],
			["Базовые рецепты крафта"]),

		_quest("workbench_opened", 1, "I. Первые шаги", "Рабочее место",
			"Поставь верстак и загляни в него.",
			[_obj("Открыть верстак", "machine_opened", "workbench", 1)],
			["Меню крафта"]),

		_quest("stone_pickaxe", 1, "I. Первые шаги", "Каменная кирка",
			"Сделай кирку, чтобы добывать руду.",
			[_obj("Скрафтить кирку", "item_crafted", "primitive_pickaxe", 1)],
			["Добыча руды и угля"]),

		_quest("primitive_bucket", 1, "I. Первые шаги", "Деревянное ведро",
			"Сколоти ведро — пригодится для жидкостей.",
			[_obj("Скрафтить ведро", "item_crafted", "primitive_bucket", 1)],
			["Перенос воды"]),

		_quest("codex_book", 1, "I. Первые шаги", "Кодекс",
			"Собери кодекс — справочник по всему миру.",
			[_obj("Скрафтить кодекс", "item_crafted", "codex", 1)],
			["Справочник предметов и машин"]),

		_quest("gatherer", 1, "I. Первые шаги", "Собиратель",
			"Пройдись по округе и собери растительное волокно.",
			[_obj("Собрать волокно", "mine_yield", "plant_fiber", 10)],
			["Материал для ткани"]),

		# ── II. Руда и плавка ───────────────────────────────────────────────
		_quest("first_coal", 1, "II. Руда и плавка", "Чёрный камень",
			"Найди угольную жилу — топливо всей ранней игры.",
			[_obj("Добыть уголь", "mine_yield", "coal", 10)],
			["Топливо для печи"]),

		_quest("first_ore", 1, "II. Руда и плавка", "Первая руда",
			"Добудь свою первую медную руду.",
			[_obj("Добыть медную руду", "mine_yield", "copper_ore", 20)],
			["Медные слитки"]),

		_quest("stone_miner", 1, "II. Руда и плавка", "Каменотёс",
			"Камень нужен всегда: печи, механизмы, постройки.",
			[_obj("Добыть камень", "mine_yield", "stone", 50)],
			["Материал для печей"]),

		_quest("first_furnace", 1, "II. Руда и плавка", "Первая печь",
			"Построй печь для плавки руды.",
			[_obj("Скрафтить каменную печь", "item_crafted", "furnace", 1)],
			["Плавка руды"]),

		_quest("furnace_opened", 1, "II. Руда и плавка", "Разжечь огонь",
			"Поставь печь, загрузи руду и уголь.",
			[_obj("Открыть печь", "machine_opened", "furnace", 1)],
			["Интерфейс плавки"]),

		_quest("starter_drill", 1, "II. Руда и плавка", "Первый автоматический шахтёр",
			"Собери примитивный бур и поставь его на медную или угольную жилу. Он работает без энергии, но хранит добычу только внутри — забирай её вручную.",
			[
				_obj("Скрафтить примитивный бур", "item_crafted", "primitive_drill", 1),
				_obj("Открыть внутреннее хранилище бура", "machine_opened", "drill", 1),
			],
			["Пассивная добыча меди и угля", "Внутреннее хранилище без автовыгрузки"]),

		_quest("copper_age", 1, "II. Руда и плавка", "Медный век",
			"Выплавь медь из руды.",
			[_obj("Выплавить медные слитки", "item_smelted", "copper_ingot", 10)],
			["Медные инструменты и детали"]),

		_quest("fuel_for_progress", 1, "II. Руда и плавка", "Топливо для прогресса",
			"Печь прожорлива. Накопи угля про запас.",
			[_obj("Добыть уголь", "mine_yield", "coal", 30)],
			["Бесперебойная плавка"]),

		_quest("copper_reserve", 1, "II. Руда и плавка", "Медный запас",
			"Меди много не бывает — она уйдёт на провода и пластины.",
			[_obj("Выплавить медные слитки", "item_smelted", "copper_ingot", 25)],
			["Задел на индустриализацию"]),

		# ── III. Бронзовый век ──────────────────────────────────────────────
		_quest("tin_discovery", 1, "III. Бронзовый век", "Открытие олова",
			"Найди и добудь оловянную руду.",
			[_obj("Добыть оловянную руду", "mine_yield", "tin_ore", 20)],
			["Компонент бронзы"]),

		_quest("tin_smelting", 1, "III. Бронзовый век", "Оловянные слитки",
			"Выплавь олово — вторая половина бронзы.",
			[_obj("Выплавить олово", "item_smelted", "tin_ingot", 10)],
			["Рецепт: Бронзовый слиток"]),

		_quest("bronze_age_begins", 1, "III. Бронзовый век", "Начало бронзового века",
			"Соедини медь и олово в бронзовый сплав.",
			[_obj("Создать бронзовые слитки", "item_crafted", "bronze_ingot", 10)],
			["Бронзовые инструменты"]),

		_quest("bronze_pickaxe", 1, "III. Бронзовый век", "Бронзовая кирка",
			"Улучши инструмент до бронзы.",
			[_obj("Скрафтить бронзовую кирку", "item_crafted", "bronze_pickaxe", 1)],
			["Быстрая добыча руды"]),

		_quest("bronze_axe", 1, "III. Бронзовый век", "Бронзовый топор",
			"Смени каменный топор на бронзовый.",
			[_obj("Скрафтить бронзовый топор", "item_crafted", "bronze_axe", 1)],
			["Быстрая рубка леса"]),

		_quest("bronze_reserve", 1, "III. Бронзовый век", "Бронзовый запас",
			"Паровые машины будущего съедят много бронзы.",
			[_obj("Создать бронзовые слитки", "item_crafted", "bronze_ingot", 20)],
			["Задел на паровую эру"]),

		# ── IV. Железо под землёй ───────────────────────────────────────────
		_quest("iron_beneath", 1, "IV. Железо под землёй", "Железо под землёй",
			"Добудь железную руду из глубин.",
			[_obj("Добыть железную руду", "mine_yield", "iron_ore", 20)],
			["Железные слитки"]),

		_quest("iron_power", 1, "IV. Железо под землёй", "Сила железа",
			"Выплавь железо.",
			[_obj("Выплавить железные слитки", "item_smelted", "iron_ingot", 10)],
			["Железные изделия"]),

		_quest("primitive_sword", 1, "IV. Железо под землёй", "Первый клинок",
			"Выкуй простой меч — в мире есть кому огрызаться.",
			[_obj("Скрафтить примитивный меч", "item_crafted", "primitive_sword", 1)],
			["Защита от врагов"]),

		_quest("bronze_sword", 1, "IV. Железо под землёй", "Бронзовый клинок",
			"Бронза держит заточку лучше камня.",
			[_obj("Скрафтить бронзовый меч", "item_crafted", "bronze_sword", 1)],
			["Оружие бронзового века"]),

		_quest("lead_vein", 1, "IV. Железо под землёй", "Свинцовая жила",
			"Найди свинец в Снежных землях и переработай часть руды в пыль.",
			[
				_obj("Добыть свинцовую руду", "mine_yield", "lead_ore", 10),
				_obj("Получить свинцовую пыль", "item_processed", "lead_dust", 10),
			],
			["Свинцовая пыль для будущих компонентов"]),

		_quest("deep_miner", 1, "IV. Железо под землёй", "Шахтёр",
			"Углубись в шахту и набей железа впрок.",
			[_obj("Добыть железную руду", "mine_yield", "iron_ore", 50)],
			["Запас железа"]),

		_quest("iron_reserve", 1, "IV. Железо под землёй", "Железный запас",
			"Переплавь добытое — слитки скоро понадобятся все разом.",
			[_obj("Выплавить железные слитки", "item_smelted", "iron_ingot", 30)],
			["Задел на машины"]),

		# ── V. Хранение ─────────────────────────────────────────────────────
		_quest("first_storage", 1, "V. Хранение", "Первое хранилище",
			"Собери сундук для хранения добычи.",
			[_obj("Скрафтить сундук Tier 1", "item_crafted", "CHEST_T1", 1)],
			["Хранение предметов"]),

		_quest("chest_placed", 1, "V. Хранение", "Свой угол",
			"Поставь сундук в удобном месте базы.",
			[_obj("Поставить сундук", "block_placed", "chest_t1", 1)],
			["Начало склада"]),

		_quest("chest_opened", 1, "V. Хранение", "Инвентаризация",
			"Открой сундук и разложи вещи.",
			[_obj("Открыть сундук", "machine_opened", "chest", 1)],
			["Интерфейс хранилища"]),

		_quest("organized_warehouse", 1, "V. Хранение", "Организованный склад",
			"Заполни сундуки ресурсами.",
			[_obj("Хранить предметы в сундуках", "items_stored", "", 100)],
			["Порядок в делах"]),

		_quest("chest_upgrade_kit", 1, "V. Хранение", "Набор расширения",
			"Собери модификатор сундука второго уровня.",
			[_obj("Скрафтить модификатор T2", "item_crafted", "CHEST_MODIFIER_T2", 1)],
			["Рецепт: Сундук Tier 2"]),

		_quest("chest_t2_quest", 1, "V. Хранение", "Сундук побольше",
			"Улучши сундук до второго уровня.",
			[_obj("Скрафтить сундук Tier 2", "item_crafted", "CHEST_T2", 1)],
			["Больше слотов"]),

		_quest("big_warehouse", 1, "V. Хранение", "Большой склад",
			"Склад настоящего промышленника начинается с полтысячи вещей.",
			[_obj("Хранить предметы в сундуках", "items_stored", "", 500)],
			["Крепкое хозяйство"]),

		# ── VI. От механики к автоматизации ─────────────────────────────────
		_quest("starter_resonite", 1, "VI. Первая автоматизация", "Сигнал в камне",
			"Найди в Лесу фиолетовую резонитовую жилу. Осколки реагируют на слабый ток и служат логическим сердцем первых схем.",
			[
				_obj("Добыть резонитовые осколки", "mine_yield", "resonite_shard", 8),
				_obj("Скрафтить первую схему T1", "item_crafted", "circuit_t1", 1),
			],
			["Схемы T1 и простые датчики"]),

		_quest("starter_machine_parts", 1, "VI. Первая автоматизация", "Детали машин",
			"Подготовь простые детали вручную. Пластины образуют корпус, шестерни передают движение, а провода и катушки связывают механику с электричеством.",
			[
				_obj("Скрафтить железные пластины", "item_crafted", "iron_plate", 12),
				_obj("Скрафтить бронзовые пластины", "item_crafted", "bronze_plate", 8),
				_obj("Скрафтить шестерни", "item_crafted", "gear", 4),
				_obj("Изолировать медные провода", "item_crafted", "insulated_copper_wire", 12),
				_obj("Скрафтить катушки", "item_crafted", "coil", 2),
				_obj("Скрафтить корпуса машин", "item_crafted", "basic_machine_casing", 3),
				_obj("Скрафтить электромоторы", "item_crafted", "electric_motor_t1", 2),
			],
			["Корпуса, моторы и электрические машины"]),

		_quest("starter_blast_furnace", 1, "VI. Первая автоматизация", "Сталь",
			"Улучши обычную печь до примитивной домны. На старте она принимает уголь; кокс позже ускорит и удешевит выплавку.",
			[
				_obj("Скрафтить примитивную доменную печь", "item_crafted", "primitive_blast_furnace", 1),
				_obj("Выплавить стальные слитки", "item_smelted", "steel_ingot", 4),
			],
			["Стальные пластины", "Электрические машины"]),

		_quest("starter_power_grid", 1, "VI. Первая автоматизация", "Первый ток",
			"Собери угольный генератор и проложи безопасный изолированный медный провод. Его 40 EU/с хватает на один стартовый комплекс: бронзовый бур, дробилку и электропечь.",
			[
				_obj("Скрафтить угольный генератор", "item_crafted", "coal_generator", 1),
				_obj("Проложить изолированные медные провода", "block_placed", "insulated_copper_wire", 6),
			],
			["Электрическая сеть 40 EU/с"]),

		_quest("starter_electric_crusher", 1, "VI. Первая автоматизация", "Удвоение руды",
			"Подключи электрическую дробилку. Одна единица металлической руды превращается в две единицы пыли.",
			[
				_obj("Скрафтить электрическую дробилку", "item_crafted", "crusher", 1),
				_obj("Получить медную пыль", "item_processed", "copper_dust", 10),
			],
			["Удвоение медной руды"]),

		_quest("starter_conveyors", 1, "VI. Первая автоматизация", "Первая лента",
			"Собери направленную конвейерную линию. Машины сами выталкивают готовый продукт на ленту, а лента передаёт его следующей машине.",
			[
				_obj("Скрафтить конвейеры", "item_crafted", "conveyor", 8),
				_obj("Поставить конвейеры", "block_placed", "conveyor", 6),
				_obj("Переместить предметы по ленте", "conveyor_item_moved", "", 6),
			],
			["Автоматическая передача предметов"]),

		_quest("starter_bronze_drill", 1, "VI. Первая автоматизация", "Бур с выходом",
			"Улучши примитивный бур до бронзового. Он требует 10 EU/с и выдаёт руду со стороны стрелки. Поставь конвейер вплотную к этой стороне: добытый предмет появится на ленте и поедет по её направлению.",
			[
				_obj("Скрафтить бронзовую буровую головку", "item_crafted", "drill_head_bronze", 1),
				_obj("Скрафтить бронзовый бур", "item_crafted", "bronze_drill", 1),
				_obj("Поставить бронзовый бур", "block_placed", "bronze_drill", 1),
				_obj("Подключить конвейер к выходу бура", "drill_output_connected", "conveyor", 1),
			],
			["Автовыгрузка руды", "Добыча олова и железа"]),

		_quest("starter_electric_furnace", 1, "VI. Первая автоматизация", "Плавка без топлива",
			"Собери электропечь и подключи её после дробилки. Ей не нужен уголь внутри — только питание сети.",
			[_obj("Скрафтить электропечь", "item_crafted", "electric_furnace", 1)],
			["Непрерывная электрическая плавка"]),

		_quest("first_automatic_resource", 1, "VI. Первая автоматизация", "Автоматическая медь",
			"Замкни первую производственную цепочку: бронзовый бур → конвейер → дробилка → конвейер → электропечь → выходной конвейер или сундук.",
			[
				_obj("Произвести медную пыль", "item_processed", "copper_dust", 20),
				_obj("Выплавить медные слитки", "item_smelted", "copper_ingot", 10),
				_obj("Переместить предметы конвейерами", "conveyor_item_moved", "", 20),
			],
			["Первая полностью автоматическая линия", "Открывает Главу 2"]),
	]


# ══ Chapter 2: Индустриализация ══════════════════════════════════════════════
static func _chapter_2() -> Array[QuestData]:
	var quests: Array[QuestData] = [
		# ── I. Медная промышленность ────────────────────────────────────────
		_quest("copper_miner", 2, "I. Медная промышленность", "Медный рудокоп",
			"Накопи меди для производства.",
			[_obj("Добыть медную руду", "mine_yield", "copper_ore", 40)],
			["Сырьё для проката"]),

		_quest("copper_plates", 2, "I. Медная промышленность", "Медные пластины",
			"Наладь выпуск медных пластин.",
			[_obj("Скрафтить медные пластины", "item_crafted", "copper_plate", 16)],
			["Корпуса и котлы"]),

		_quest("copper_wires", 2, "I. Медная промышленность", "Безопасная проводка",
			"Вытяни медь в провод и оберни его растительным волокном. Голый провод под напряжением опасен.",
			[_obj("Изолировать медные провода", "item_crafted", "insulated_copper_wire", 16)],
			["Безопасная проводка для будущих машин"]),

		_quest("copper_rods", 2, "I. Медная промышленность", "Медные стержни",
			"Прокатай медные стержни.",
			[_obj("Скрафтить медные стержни", "item_crafted", "copper_rod", 8)],
			["Детали механизмов"]),

		_quest("copper_block_quest", 2, "I. Медная промышленность", "Медный блок",
			"Спрессуй слитки в цельные блоки для компактного хранения.",
			[_obj("Скрафтить медные блоки", "item_crafted", "copper_block", 2)],
			["Компактное хранение меди"]),

		_quest("primitive_drill_quest", 2, "I. Медная промышленность", "Сеть простых буров",
			"Расширь ручную добычу несколькими дешёвыми бурами. Их внутренние хранилища по-прежнему нужно разгружать вручную.",
			[_obj("Иметь три скрафченных примитивных бура", "item_crafted", "primitive_drill", 3)],
			["Параллельная добыча меди и угля"]),

		_quest("drill_opened", 2, "I. Медная промышленность", "Бур в работе",
			"Поставь бур на жилу и проверь его.",
			[_obj("Открыть бур", "machine_opened", "drill", 1)],
			["Пассивная добыча руды"]),

		# ── II. Прокат и детали ─────────────────────────────────────────────
		_quest("iron_plates", 2, "II. Прокат и детали", "Железный прокат",
			"Прокатай железо в пластины — основной конструкционный материал.",
			[_obj("Скрафтить железные пластины", "item_crafted", "iron_plate", 16)],
			["Корпуса машин"]),

		_quest("iron_bolts", 2, "II. Прокат и детали", "Железные болты",
			"Нарежь болтов — без крепежа ничего не соберёшь.",
			[_obj("Скрафтить железные болты", "item_crafted", "iron_bolt", 12)],
			["Крепёж для машин"]),

		_quest("bronze_plates", 2, "II. Прокат и детали", "Бронзовый прокат",
			"Прокатай бронзу в пластины — материал паровых машин.",
			[_obj("Скрафтить бронзовые пластины", "item_crafted", "bronze_plate", 12)],
			["Паровые машины"]),

		_quest("bronze_rods", 2, "II. Прокат и детали", "Бронзовые стержни",
			"Вытяни бронзовые стержни.",
			[_obj("Скрафтить бронзовые стержни", "item_crafted", "bronze_rod", 8)],
			["Кольца и роторы"]),

		_quest("bronze_rings", 2, "II. Прокат и детали", "Бронзовые кольца",
			"Согни стержни в кольца.",
			[_obj("Скрафтить бронзовые кольца", "item_crafted", "bronze_ring", 8)],
			["Детали насосов"]),

		_quest("bronze_bolts", 2, "II. Прокат и детали", "Бронзовый крепёж",
			"Бронзовые болты для паровой техники.",
			[_obj("Скрафтить бронзовые болты", "item_crafted", "bronze_bolt", 12)],
			["Сборка роторов"]),

		_quest("bronze_pipes", 2, "II. Прокат и детали", "Бронзовые трубы",
			"Сверни пластины в трубы.",
			[_obj("Скрафтить бронзовые трубы", "item_crafted", "bronze_pipe", 6)],
			["Трубопроводы"]),

		_quest("bronze_rotor_quest", 2, "II. Прокат и детали", "Бронзовый ротор",
			"Собери ротор из пластин, колец и болтов.",
			[_obj("Скрафтить бронзовые роторы", "item_crafted", "bronze_rotor", 2)],
			["Сердце насосов и турбин"]),

		_quest("small_bronze_gears", 2, "II. Прокат и детали", "Малые шестерни",
			"Выточи малые бронзовые шестерни.",
			[_obj("Скрафтить малые шестерни", "item_crafted", "small_bronze_gear", 6)],
			["Точная механика"]),

		_quest("mechanical_parts", 2, "II. Прокат и детали", "Механические детали",
			"Изготовь большие шестерни для механизмов.",
			[_obj("Скрафтить шестерёнки", "item_crafted", "gear", 8)],
			["Паровые дробилки и прессы"]),

		_quest("basic_boards", 2, "II. Прокат и детали", "Монтажные платы",
			"Собери базовые платы — основа будущей электроники.",
			[_obj("Скрафтить базовые платы", "item_crafted", "basic_board", 4)],
			["Задел на схемы"]),

		_quest("first_casing", 2, "II. Прокат и детали", "Корпус машины",
			"Собери первый корпус механизма.",
			[_obj("Скрафтить базовый корпус", "item_crafted", "basic_machine_casing", 2)],
			["Основа всех машин"]),

		# ── III. Сила пара ──────────────────────────────────────────────────
		_quest("steam_waterworks", 2, "III. Сила пара", "Механическое водоснабжение",
			"Поставь бронзовую помпу на воду и соедини её с будущим котлом трубами.",
			[
				_obj("Скрафтить механическую водяную помпу", "item_crafted", "mechanical_water_pump", 1),
				_obj("Скрафтить ранние жидкостные трубы", "item_crafted", "fluid_pipe", 12),
				_obj("Поставить механическую водяную помпу", "block_placed", "mechanical_water_pump", 1),
				_obj("Проложить трубы к котельной", "block_placed", "fluid_pipe", 8),
			],
			["Автоматическая подача воды без электричества"]),

		_quest("refractory_bricks", 2, "III. Сила пара", "Огнеупоры",
			"Замеси огнеупорный кирпич из камня и угольной пыли.",
			[_obj("Скрафтить огнеупорный кирпич", "item_crafted", "refractory_brick", 16)],
			["Материал паровых корпусов, коксовой печи и домны"]),

		_quest("steam_thermal_unit", 2, "III. Сила пара", "Тепловой узел",
			"Объедини обычную печь и котельные трубки в сменный тепловой блок для ранних паровых машин.",
			[_obj("Скрафтить тепловой узел", "item_crafted", "thermal_unit", 1)],
			["Стандартизированный нагрев котлов и печей"]),

		_quest("steam_boiler", 2, "III. Сила пара", "Паровой котёл",
			"Собери котёл, залей воду и разожги уголь — получи пар.",
			[_obj("Скрафтить паровой котёл", "item_crafted", "steam_boiler", 1)],
			["Пар — энергия до электричества"]),

		_quest("boiler_opened", 2, "III. Сила пара", "Под давлением",
			"Запусти котёл: топливо вниз, вода в бак.",
			[_obj("Открыть паровой котёл", "machine_opened", "steam_boiler", 1)],
			["Производство пара"]),

		_quest("steam_press_quest", 2, "III. Сила пара", "Паровой пресс",
			"Собери базовый пресс и подключи его к котлу — он откроет точные паровые детали.",
			[_obj("Скрафтить паровой пресс", "item_crafted", "steam_press", 1)],
			["Прокат и точная механика"]),

		_quest("steam_network_diagnostics", 2, "III. Сила пара", "Стабильная паровая сеть",
			"Подключи пресс к котлу трубами и запусти устойчивую подачу пара.",
			[_obj("Запустить стабильную паровую сеть", "steam_grid_online", "healthy", 1)],
			["Надёжное питание паровых машин"]),

		_quest("pressed_iron", 2, "III. Сила пара", "Прессованное железо",
			"Прокатай железо через пресс — вдвое выгоднее верстака.",
			[_obj("Спрессовать железные пластины", "item_processed", "iron_plate", 12)],
			["Пластины за полцены"]),

		_quest("pressed_copper", 2, "III. Сила пара", "Прессованная медь",
			"Медные пластины тоже лучше катать прессом.",
			[_obj("Спрессовать медные пластины", "item_processed", "copper_plate", 12)],
			["Эффективный прокат"]),

		_quest("first_steam_precision", 2, "III. Сила пара", "Точная механика",
			"Запусти пресс и выпусти первые детали для машин высокого давления.",
			[
				_obj("Спрессовать клапаны давления", "item_processed", "pressure_valve", 2),
				_obj("Спрессовать паровые поршни", "item_processed", "steam_piston", 2),
				_obj("Сбалансировать маховики", "item_processed", "precision_flywheel", 2),
			],
			["Сборка продвинутых паровых машин"]),

		_quest("steam_fluid_manifold", 2, "III. Сила пара", "Жидкостный коллектор",
			"Соедини бронзовые трубы и клапан давления в единый распределительный узел для подачи пара.",
			[_obj("Скрафтить жидкостный коллектор", "item_crafted", "fluid_manifold", 1)],
			["Стандартное подключение паровых машин"]),

		_quest("steam_assembler_quest", 2, "III. Сила пара", "Паровой сборщик",
			"Собери паровой сборщик и выбери рецепт, чтобы заменить ручную обработку бронзовых деталей.",
			[
				_obj("Скрафтить паровой сборщик", "item_crafted", "steam_assembler", 1),
				_obj("Поставить паровой сборщик", "block_placed", "steam_assembler", 1),
				_obj("Открыть паровой сборщик", "machine_opened", "steam_assembler", 1),
				_obj("Выбрать рецепт бронзовых стержней", "machine_recipe_selected", "bronze_rod", 1),
			],
			["Автоматическая сборка компонентов"]),

		_quest("automated_bronze_workshop", 2, "III. Сила пара", "Автоматизированная бронзовая мастерская",
			"Подай детали манипуляторами и собери запас промежуточных компонентов без верстака.",
			[
				_obj("Собрать бронзовые стержни", "component_assembled", "bronze_rod", 16),
				_obj("Собрать бронзовые кольца", "component_assembled", "bronze_ring", 16),
				_obj("Собрать бронзовые болты", "component_assembled", "bronze_bolt", 32),
				_obj("Собрать бронзовые подшипники", "component_assembled", "bronze_bearing", 8),
				_obj("Собрать бронзовые роторы", "component_assembled", "bronze_rotor", 4),
				_obj("Собрать механические приводные узлы", "component_assembled", "mechanical_drive_unit", 4),
				_obj("Собрать механические управляющие узлы", "component_assembled", "mechanical_control_unit", 4),
				_obj("Собрать корпуса паровых машин", "component_assembled", "steam_machine_casing", 2),
				_obj("Собрать тепловые узлы", "component_assembled", "thermal_unit", 2),
				_obj("Собрать жидкостные коллекторы", "component_assembled", "fluid_manifold", 2),
			],
			["Серийное производство паровых машин"]),

		_quest("steam_belt_logistics", 2, "III. Сила пара", "Механическая логистика",
			"Поставь манипулятор между источником и лентой: жёлтый порт забирает предмет, зелёный выдаёт.",
			[
				_obj("Скрафтить механические манипуляторы", "item_crafted", "mechanical_inserter", 2),
				_obj("Скрафтить механические конвейеры", "item_crafted", "conveyor", 12),
				_obj("Поставить механические манипуляторы", "block_placed", "mechanical_inserter", 2),
				_obj("Поставить механические конвейеры", "block_placed", "conveyor", 8),
				_obj("Настроить фильтр манипулятора", "inserter_configured", "filter", 1),
				_obj("Переместить предметы манипуляторами", "item_transferred", "mechanical_inserter", 20),
				_obj("Передать запрос ингредиентов через конвейер", "conveyor_demand_signal", "ingredient", 1),
				_obj("Настроить запрашивающий склад", "warehouse_request_configured", "requester", 1),
				_obj("Настроить склад-поставщик", "warehouse_provider_configured", "provider", 1),
				_obj("Настроить несколько правил одного склада", "warehouse_multi_rule_configured", "multi", 1),
			],
			["Автоматическая загрузка и выгрузка машин"]),

		_quest("steam_crusher_quest", 2, "III. Сила пара", "Паровая дробилка",
			"Собери дробилку вокруг готового парового привода, затем подведи пар.",
			[_obj("Скрафтить паровую дробилку", "item_crafted", "steam_crusher", 1)],
			["Удвоение руды"]),

		_quest("steam_ore_doubling", 2, "III. Сила пара", "Двойной выход",
			"Паровая дробилка даёт две железные пыли из одной руды.",
			[_obj("Получить железную пыль", "item_processed", "iron_dust", 20)],
			["Экономия каждой жилы"]),

		_quest("steam_furnace_quest", 2, "III. Сила пара", "Паровая печь",
			"Установи клапан давления и собери безопасную печь для непрерывной плавки.",
			[_obj("Скрафтить паровую печь", "item_crafted", "steam_furnace", 1)],
			["Быстрая плавка"]),

		_quest("steam_smelting", 2, "III. Сила пара", "Плавка на пару",
			"Прогони плавку через паровую печь.",
			[_obj("Выплавить железные слитки", "item_smelted", "iron_ingot", 20)],
			["Массовая плавка"]),

		_quest("steam_iron_line", 2, "III. Сила пара", "Железная производственная линия",
			"Соедини паровую дробилку с паровой печью и выходным сундуком минимум двумя манипуляторами. Панель диагностики покажет разрыв, затор или машину, ограничивающую выпуск.",
			[
				_obj("Произвести железную пыль", "item_processed", "iron_dust", 20),
				_obj("Выплавить железные слитки на линии", "item_smelted", "iron_ingot", 20),
				_obj("Переместить предметы манипуляторами линии", "item_transferred", "mechanical_inserter", 40),
				_obj("Запустить соединённую железную линию", "factory_line_online", "iron", 1),
			],
			["Автоматическая переработка железа", "Диагностика узких мест"]),

		# ── IV. Кокс и сталь ────────────────────────────────────────────────
		_quest("coke_oven_quest", 2, "IV. Кокс и сталь", "Коксовая печь",
			"Сложи печь из огнеупорного кирпича — она займёт площадку 2×2.",
			[_obj("Скрафтить коксовую печь", "item_crafted", "coke_oven", 1)],
			["Кокс и креозот"]),

		_quest("coke_oven_opened", 2, "IV. Кокс и сталь", "Медленный жар",
			"Загрузи уголь в коксовую печь и жди.",
			[_obj("Открыть коксовую печь", "machine_opened", "coke_oven", 1)],
			["Пережиг угля"]),

		_quest("first_coke", 2, "IV. Кокс и сталь", "Первый кокс",
			"Пережги уголь в кокс. Каждый цикл одновременно даёт 1 л креозота.",
			[
				_obj("Получить кокс", "item_processed", "coke", 16),
				_obj("Получить креозот при коксовании", "fluid_produced", "creosote", 16),
			],
			["Топливо для домны", "Креозот для котлов и углехимии"]),

		_quest("steam_creosote_loop", 2, "IV. Кокс и сталь", "Креозотный контур",
			"Не сливай побочный продукт. Соедини коксовую печь, резервуар T1 и паровой котёл жидкостными трубами.",
			[
				_obj("Скрафтить ранний резервуар T1", "item_crafted", "fluid_tank_t1", 1),
				_obj("Установить буфер креозота", "block_placed", "fluid_tank_t1", 1),
				_obj("Замкнуть креозотный контур", "factory_line_online", "creosote", 1),
				_obj("Сжечь креозот в паровом котле", "fluid_burned", "creosote", 8),
			],
			["Буфер побочного продукта", "1 л креозота даёт 2 секунды горения котла"]),

		_quest("coke_dust_grinding", 2, "IV. Кокс и сталь", "Коксовая пыль",
			"Раздроби кокс в пыль — горит так же долго, а идёт и в химию.",
			[_obj("Получить коксовую пыль", "item_processed", "coke_dust", 8)],
			["Топливо и углехимия"]),

		_quest("blast_furnace_quest", 2, "IV. Кокс и сталь", "Примитивная домна",
			"Сталь не плавится в обычной печи: только домна, только кокс. Займёт площадку 2×2.",
			[_obj("Скрафтить примитивную домну", "item_crafted", "primitive_blast_furnace", 1)],
			["Выплавка стали"]),

		_quest("first_steel", 2, "IV. Кокс и сталь", "Настоящая сталь",
			"Железо плюс два кокса — и домна выдаст сталь.",
			[_obj("Выплавить сталь в домне", "item_smelted", "steel_ingot", 5)],
			["Материал нового тира"]),

		_quest("steel_reserve", 2, "IV. Кокс и сталь", "Стальной задел",
			"Одной плавкой сыт не будешь — накопи стали.",
			[_obj("Выплавить сталь", "item_smelted", "steel_ingot", 15)],
			["Стальные инструменты и детали"]),

		_quest("steam_component_certification", 2, "IV. Кокс и сталь", "Сертификация компонентов",
			"Подтверди серийный выпуск полного набора деталей: от шестерён и подшипников до управляющих узлов. Ранее произведённые компоненты тоже засчитываются.",
			[
				_obj("Собрать малые бронзовые шестерни", "component_assembled", "small_bronze_gear", 8),
				_obj("Собрать бронзовые подшипники", "component_assembled", "bronze_bearing", 8),
				_obj("Спрессовать паровые поршни", "item_processed", "steam_piston", 4),
				_obj("Собрать бронзовые трубы", "component_assembled", "bronze_pipe", 16),
				_obj("Собрать корпуса паровых машин", "component_assembled", "steam_machine_casing", 4),
				_obj("Собрать тепловые узлы", "component_assembled", "thermal_unit", 4),
				_obj("Собрать жидкостные коллекторы", "component_assembled", "fluid_manifold", 4),
				_obj("Собрать бронзовые роторы", "component_assembled", "bronze_rotor", 4),
				_obj("Собрать механические приводные узлы", "component_assembled", "mechanical_drive_unit", 4),
				_obj("Собрать механические управляющие узлы", "component_assembled", "mechanical_control_unit", 4),
				_obj("Собрать стальные трубы", "component_assembled", "steel_pipe", 8),
				_obj("Собрать стальные подшипники", "component_assembled", "steel_bearing", 4),
				_obj("Собрать стальные роторы", "component_assembled", "steel_rotor", 2),
				_obj("Собрать паровые приводные узлы", "component_assembled", "steam_drive_unit", 2),
				_obj("Собрать паровые управляющие узлы", "component_assembled", "steam_control_unit", 2),
			],
			["Ранний доступ к паровой турбине", "Ранний доступ к паровому водяному насосу", "Котёл высокого давления"]),

		_quest("high_pressure_steam_boiler", 2, "IV. Кокс и сталь", "Котёл высокого давления",
			"Усиль обычный котёл стальным корпусом, коллекторами и автоматикой. Новая установка занимает площадку 2×2.",
			[
				_obj("Скрафтить котёл высокого давления", "item_crafted", "high_pressure_steam_boiler", 1),
				_obj("Установить котёл высокого давления", "block_placed", "high_pressure_steam_boiler", 1),
				_obj("Открыть котёл высокого давления", "machine_opened", "high_pressure_steam_boiler", 1),
			],
			["Производство 12 л пара в секунду", "Расход топлива в 2 раза быстрее"]),

		_quest("high_pressure_boiler_load_test", 2, "IV. Кокс и сталь", "Испытание котельной",
			"Подай воду и топливо, затем проверь котёл под длительной нагрузкой нескольких паровых машин.",
			[
				_obj("Произвести пар высокого давления", "fluid_produced", "high_pressure_steam", 480),
				_obj("Поддерживать стабильную паровую сеть", "steam_grid_online", "healthy", 1),
			],
			["Стабильное питание расширенной паровой фабрики"]),

		_quest("steam_steel_line", 2, "IV. Кокс и сталь", "Стальная производственная линия",
			"Соедини коксовую печь, примитивную домну, паровой пресс и выходной сундук минимум тремя манипуляторами.",
			[
				_obj("Произвести кокс на линии", "item_processed", "coke", 24),
				_obj("Выплавить стальные слитки на линии", "item_smelted", "steel_ingot", 12),
				_obj("Прокатать стальные пластины на линии", "item_processed", "steel_plate", 24),
				_obj("Переместить предметы стальной линии", "item_transferred", "mechanical_inserter", 40),
				_obj("Запустить соединённую стальную линию", "factory_line_online", "steel", 1),
			],
			["Автоматическая выплавка и прокат стали", "Диагностика кокса и креозота"]),

		_quest("steam_fluid_routing", 2, "IV. Кокс и сталь", "Напорная гидравлика",
			"Замени магистраль стальными трубами и раздели воду, пар и креозот направленными фильтрующими клапанами.",
			[
				_obj("Скрафтить трубы высокого давления", "item_crafted", "fluid_pipe_t2", 8),
				_obj("Скрафтить фильтрующий клапан", "item_crafted", "fluid_valve", 1),
				_obj("Установить фильтрующий клапан", "block_placed", "fluid_valve", 1),
				_obj("Выбрать жидкость в фильтре клапана", "fluid_valve_configured", "filter", 1),
				_obj("Настроить направление клапана", "fluid_valve_configured", "direction", 1),
				_obj("Настроить переливной режим клапана", "fluid_valve_configured", "overflow", 1),
			],
			["30 л/с по полностью улучшенной магистрали", "Раздельные контуры воды, пара и креозота"]),

		_quest("steam_closed_water_loop", 2, "IV. Кокс и сталь", "Замкнутый водяной цикл",
			"Улучши механическую помпу. Паровой насос возвращает в котельную больше воды, чем потребляет пара, но для запуска ему нужна первая порция пара.",
			[
				_obj("Скрафтить паровой водяной насос", "item_crafted", "steam_water_pump", 1),
				_obj("Установить паровой водяной насос", "block_placed", "steam_water_pump", 1),
				_obj("Открыть паровой водяной насос", "machine_opened", "steam_water_pump", 1),
				_obj("Назначить насосу высокий приоритет пара", "fluid_priority_configured", "high", 1),
				_obj("Настроить автоматическое отключение насоса", "machine_output_control_configured", "hysteresis", 1),
				_obj("Запустить замкнутый водяной цикл", "steam_pump_online", "water", 1),
			],
			["16 л воды из 1 л пара", "Стабильное питание нескольких котлов"]),

		# ── V. Стальные инструменты ─────────────────────────────────────────
		_quest("steel_pickaxe", 2, "V. Стальные инструменты", "Стальная кирка",
			"Создай прочную стальную кирку — она берёт золото и титан.",
			[_obj("Скрафтить стальную кирку", "item_crafted", "steel_pickaxe", 1)],
			["Добыча золота, серебра и титана"]),

		_quest("steel_axe_quest", 2, "V. Стальные инструменты", "Стальной топор",
			"Заверши комплект лесоруба.",
			[_obj("Скрафтить стальной топор", "item_crafted", "steel_axe", 1)],
			["Максимальная скорость рубки"]),

		_quest("steel_sword_quest", 2, "V. Стальные инструменты", "Стальной меч",
			"Выкуй стальной клинок.",
			[_obj("Скрафтить стальной меч", "item_crafted", "steel_sword", 1)],
			["Оружие стального века"]),

		# ── VI. Драгоценные жилы ────────────────────────────────────────────
		_quest("gold_rush", 2, "VI. Драгоценные жилы", "Золотая лихорадка",
			"Стальная кирка открыла золотые жилы — вперёд.",
			[_obj("Добыть золотую руду", "mine_yield", "gold_ore", 15)],
			["Золото для электроники"]),

		_quest("gold_smelting", 2, "VI. Драгоценные жилы", "Золотые слитки",
			"Переплавь золотую руду.",
			[_obj("Выплавить золото", "item_smelted", "gold_ingot", 10)],
			["Проводники и фольга"]),

		_quest("silver_vein", 2, "VI. Драгоценные жилы", "Серебряная жила",
			"Найди серебро для слитков и продвинутых электронных компонентов.",
			[_obj("Добыть серебряную руду", "mine_yield", "silver_ore", 15)],
			["Серебро для схем"]),

		_quest("silver_smelting", 2, "VI. Драгоценные жилы", "Серебряные слитки",
			"Переплавь часть серебра — остальное прибереги для дробилки.",
			[_obj("Выплавить серебро", "item_smelted", "silver_ingot", 10)],
			["Открывает Главу 3"]),
	]


# ══ Chapter 3: Железный век ══════════════════════════════════════════════════
	quests.append_array(_steam_factory_certification())
	return quests


static func _steam_factory_certification() -> Array[QuestData]:
	return [
		_quest("steam_casing_batch", 2, "VII. Сертификация паровой фабрики", "Стандартизированные корпуса",
			"Автоматизируй выпуск одинаковых корпусов и котельных труб для расширения парового цеха.",
			[
				_obj("Собрать паровые корпуса", "component_assembled", "steam_machine_casing", 6),
				_obj("Собрать бронзовые котельные трубки", "component_assembled", "bronze_boiler_tube", 16),
			],
			["Серийная сборка паровых машин"]),

		_quest("steam_precision_batch", 2, "VII. Сертификация паровой фабрики", "Точная механика",
			"Запусти пресс и выпусти стандартизированные детали под давлением.",
			[
				_obj("Спрессовать клапаны давления", "item_processed", "pressure_valve", 12),
				_obj("Спрессовать паровые поршни", "item_processed", "steam_piston", 12),
				_obj("Сбалансировать маховики", "item_processed", "precision_flywheel", 6),
			],
			["Точные детали для исследовательских наборов"]),

		_quest("steam_factory_throughput", 2, "VII. Сертификация паровой фабрики", "Смена без остановки",
			"Докажи что цех способен долго перерабатывать руду а не выпускать единичные образцы.",
			[
				_obj("Произвести железную пыль", "item_processed", "iron_dust", 64),
				_obj("Спрессовать металлические пластины", "item_processed", "iron_plate", 48),
				_obj("Произвести кокс", "item_processed", "coke", 32),
				_obj("Выплавить сталь", "item_smelted", "steel_ingot", 24),
			],
			["Промышленная производительность парового цеха"]),

		_quest("steam_research_batch", 2, "VII. Сертификация паровой фабрики", "Пакетный анализ",
			"Соедини два сборщика: первый выпускает исследовательские ядра, второй упаковывает их со сталью и коксом.",
			[
				_obj("Установить два паровых сборщика", "block_placed", "steam_assembler", 2),
				_obj("Выбрать рецепт исследовательского ядра", "machine_recipe_selected", "steam_research_core", 1),
				_obj("Выбрать рецепт парового набора", "machine_recipe_selected", "steam_science_pack", 1),
				_obj("Собрать исследовательские ядра", "component_assembled", "steam_research_core", 6),
				_obj("Собрать паровые исследовательские наборы", "component_assembled", "steam_science_pack", 6),
				_obj("Запустить соединённую исследовательскую линию", "factory_line_online", "steam_research", 1),
			],
			["Готовность к исследованию электричества"]),
	]


static func _chapter_3() -> Array[QuestData]:
	return [
		# ── I. Железный прокат ──────────────────────────────────────────────
		_quest("iron_industry", 3, "I. Железный прокат", "Железная хватка",
			"Раскачай добычу железа до промышленных объёмов.",
			[_obj("Добыть железную руду", "mine_yield", "iron_ore", 60)],
			["Сырьё для стальной эры"]),

		_quest("iron_rods", 3, "I. Железный прокат", "Железные стержни",
			"Вытяни железо в стержни.",
			[_obj("Скрафтить железные стержни", "item_crafted", "iron_rod", 12)],
			["Основа моторов"]),

		_quest("iron_springs", 3, "I. Железный прокат", "Железные пружины",
			"Навей пружины из железа.",
			[_obj("Скрафтить железные пружины", "item_crafted", "iron_spring", 6)],
			["Амортизация механизмов"]),

		_quest("iron_blocks", 3, "I. Железный прокат", "Железные блоки",
			"Спрессуй железо в цельные блоки.",
			[_obj("Скрафтить железные блоки", "item_crafted", "iron_block", 2)],
			["Компактное хранение"]),

		_quest("steel_bolts", 3, "I. Железный прокат", "Стальной крепёж",
			"Нарежь стальных болтов.",
			[_obj("Скрафтить стальные болты", "item_crafted", "bolt", 16)],
			["Крепёж высокого тира"]),

		_quest("coal_industry", 3, "I. Железный прокат", "Угольный разрез",
			"Домна и котлы жгут топливо безостановочно.",
			[_obj("Добыть уголь", "mine_yield", "coal", 60)],
			["Топливная безопасность"]),

		# ── II. Стальные детали ─────────────────────────────────────────────
		_quest("steel_plates", 3, "II. Стальные детали", "Стальной прокат",
			"Прокатай сталь в пластины.",
			[_obj("Скрафтить стальные пластины", "item_crafted", "steel_plate", 16)],
			["Продвинутые корпуса"]),

		_quest("steel_rods", 3, "II. Стальные детали", "Стальные стержни",
			"Вытяни стальные стержни.",
			[_obj("Скрафтить стальные стержни", "item_crafted", "steel_rod", 12)],
			["Валы и оси"]),

		_quest("steel_rings", 3, "II. Стальные детали", "Стальные кольца",
			"Согни стальные кольца.",
			[_obj("Скрафтить стальные кольца", "item_crafted", "steel_ring", 8)],
			["Уплотнители машин"]),

		_quest("steel_springs", 3, "II. Стальные детали", "Стальные пружины",
			"Навей пружины из стали.",
			[_obj("Скрафтить стальные пружины", "item_crafted", "steel_spring", 6)],
			["Детали высоких нагрузок"]),

		_quest("steel_pipes", 3, "II. Стальные детали", "Стальные трубы",
			"Сверни стальные трубы — они держат нефть и пар.",
			[_obj("Скрафтить стальные трубы", "item_crafted", "steel_pipe", 6)],
			["Нефтекачка и турбина"]),

		_quest("steel_rotor_quest", 3, "II. Стальные детали", "Стальной ротор",
			"Собери стальные роторы.",
			[_obj("Скрафтить стальные роторы", "item_crafted", "steel_rotor", 2)],
			["Турбины и насосы"]),

		_quest("small_steel_gears", 3, "II. Стальные детали", "Малые стальные шестерни",
			"Выточи малые шестерни из стали.",
			[_obj("Скрафтить малые шестерни", "item_crafted", "small_steel_gear", 6)],
			["Точная механика"]),

		_quest("coils", 3, "II. Стальные детали", "Катушки",
			"Намотай провод на сердечник — получи катушки.",
			[_obj("Скрафтить катушки", "item_crafted", "coil", 8)],
			["Моторы и генераторы"]),

		_quest("gold_rods", 3, "II. Стальные детали", "Золотые стержни",
			"Вытяни золото в стержни для тонкой электроники.",
			[_obj("Скрафтить золотые стержни", "item_crafted", "gold_rod", 6)],
			["Чипы будущего"]),

		_quest("gold_springs", 3, "II. Стальные детали", "Золотые пружины",
			"Золотые контактные пружины.",
			[_obj("Скрафтить золотые пружины", "item_crafted", "gold_spring", 4)],
			["Контакты приборов"]),

		# ── III. Каркасы машин ──────────────────────────────────────────────
		_quest("machine_frames", 3, "III. Каркасы машин", "Каркас машины",
			"Свари каркасы — скелет тяжёлых машин.",
			[_obj("Скрафтить каркасы машин", "item_crafted", "machine_frame", 2)],
			["Тяжёлое машиностроение"]),

		_quest("advanced_boards", 3, "III. Каркасы машин", "Продвинутые платы",
			"Собери платы следующего поколения.",
			[_obj("Скрафтить продвинутые платы", "item_crafted", "advanced_board", 4)],
			["Схемы T2"]),

		_quest("bronze_springs", 3, "III. Каркасы машин", "Бронзовые пружины",
			"Мягкие бронзовые пружины для точных приборов.",
			[_obj("Скрафтить бронзовые пружины", "item_crafted", "bronze_spring", 4)],
			["Приборостроение"]),

		_quest("buckets", 3, "III. Каркасы машин", "Металлические вёдра",
			"Сделай вёдра покрепче деревянного.",
			[
				_obj("Скрафтить бронзовое ведро", "item_crafted", "bronze_bucket", 1),
				_obj("Скрафтить стальное ведро", "item_crafted", "steel_bucket", 1),
			],
			["Перенос лавы и нефти"]),

		# ── IV. Логистика ───────────────────────────────────────────────────
		_quest("conveyor_quest", 3, "IV. Логистика", "Конвейер",
			"Собери конвейерные ленты — предметы поедут сами.",
			[_obj("Скрафтить конвейеры", "item_crafted", "conveyor", 8)],
			["Автоматическая логистика"]),

		_quest("conveyor_line", 3, "IV. Логистика", "Первая линия",
			"Проложи конвейерную линию по базе.",
			[_obj("Поставить конвейеры", "block_placed", "conveyor", 6)],
			["Транспорт предметов"]),

		_quest("conveyor_splitters", 3, "IV. Логистика", "Разветвители",
			"Раздели потоки предметов разветвителями.",
			[_obj("Скрафтить разветвители", "item_crafted", "conveyor_splitter", 2)],
			["Сортировка на лету"]),

		_quest("conveyor_opened", 3, "IV. Логистика", "Пульт конвейера",
			"Настрой конвейер под свои маршруты.",
			[_obj("Открыть конвейер", "machine_opened", "conveyor", 1)],
			["Настройка направлений"]),

		_quest("warehouse_expansion", 3, "IV. Логистика", "Расширение склада",
			"Склад растёт вместе с производством.",
			[_obj("Хранить предметы в сундуках", "items_stored", "", 1000)],
			["Тысяча вещей под учётом"]),

		_quest("chest_t3_quest", 3, "IV. Логистика", "Сундук мастера",
			"Доведи сундук до третьего уровня.",
			[
				_obj("Скрафтить модификатор T3", "item_crafted", "CHEST_MODIFIER_T3", 1),
				_obj("Скрафтить сундук Tier 3", "item_crafted", "CHEST_T3", 1),
			],
			["Максимум слотов"]),

		# ── V. Буровая техника ──────────────────────────────────────────────
		_quest("drill_head_bronze_quest", 3, "V. Буровая техника", "Запасные головки",
			"Подготовь бронзовые головки для расширения автоматической добычи.",
			[_obj("Скрафтить бронзовые головки", "item_crafted", "drill_head_bronze", 2)],
			["Расширение буровой"]),

		_quest("bronze_drill_quest", 3, "V. Буровая техника", "Буровой парк",
			"Расширь первую автоматическую линию отдельными бронзовыми бурами для разных руд.",
			[_obj("Скрафтить бронзовые буры", "item_crafted", "bronze_drill", 2)],
			["Параллельная автоматическая добыча"]),

		_quest("bronze_drill_placed", 3, "V. Буровая техника", "Буровая площадка",
			"Поставь бронзовый бур на богатую жилу.",
			[_obj("Поставить бронзовый бур", "block_placed", "bronze_drill", 1)],
			["Пассивный доход руды"]),

		_quest("ent_totem_quest", 3, "V. Буровая техника", "Тотем энта",
			"Вырежи тотем — лес будет расти сам.",
			[_obj("Скрафтить тотем энта", "item_crafted", "ent_totem", 1)],
			["Возобновляемая древесина"]),

		_quest("tin_industry", 3, "V. Буровая техника", "Оловянный передел",
			"Олово уйдёт в бронзу и припой — добудь с запасом.",
			[_obj("Добыть оловянную руду", "mine_yield", "tin_ore", 40)],
			["Запас олова"]),

		_quest("steel_stockpile", 3, "V. Буровая техника", "Стальной резерв",
			"Подготовь запас стали для оружия и первых электрических машин.",
			[_obj("Выплавить сталь", "item_smelted", "steel_ingot", 12)],
			["Стальное оружие"]),

		_quest("ent_preparation", 3, "VI. Хранитель леса", "Оружие против Энта",
			"Энт охраняет переход к электрической эре. Стальной меч наносит достаточно урона, чтобы пробить его кору.",
			[_obj("Скрафтить стальной меч", "item_crafted", "steel_sword", 1)],
			["Готовность к первому боссу"]),

	]


# ══ Chapter 4: Электрификация ════════════════════════════════════════════════
static func _chapter_4() -> Array[QuestData]:
	return [
		# ── I. Первый ток ───────────────────────────────────────────────────
		_quest("coal_power", 4, "I. Первый ток", "Топливная база",
			"Генератору нужно что-то жечь. Много.",
			[_obj("Добыть уголь", "mine_yield", "coal", 100)],
			["Топливо для генератора"]),

		_quest("first_power", 4, "I. Первый ток", "Расширение генерации",
			"Первой линии уже тесно в пределах 40 EU/с. Добавь второй угольный генератор.",
			[_obj("Скрафтить угольные генераторы", "item_crafted", "coal_generator", 2)],
			["Электросеть 80 EU/с"]),

		_quest("generator_opened", 4, "I. Первый ток", "Запуск генератора",
			"Загрузи топливо и дай ток.",
			[_obj("Открыть генератор", "machine_opened", "coal_generator", 1)],
			["Первые EU"]),

		_quest("wire_network", 4, "I. Первый ток", "Провода",
			"Изолируй медные провода растительным волокном. Голая линия под напряжением ударит током.",
			[_obj("Изолировать медные провода", "item_crafted", "insulated_copper_wire", 24)],
			["Электросеть"]),

		_quest("lay_cables", 4, "I. Первый ток", "Прокладка сети",
			"Соедини генератор с потребителями.",
			[_obj("Проложить изолированный медный кабель", "block_placed", "insulated_copper_wire", 10)],
			["Передача энергии"]),

		_quest("first_circuit", 4, "I. Первый ток", "Первая схема",
			"Спаяй базовые электронные схемы.",
			[_obj("Скрафтить схемы T1", "item_crafted", "circuit_t1", 5)],
			["Электромашины"]),

		# ── II. Дробилка и резонит ──────────────────────────────────────────
		_quest("heavy_processing", 4, "II. Дробилка и резонит", "Вторая электродробилка",
			"Раздели потоки: одна дробилка обслуживает железо, другая — цветные металлы.",
			[_obj("Скрафтить электрические дробилки", "item_crafted", "crusher", 2)],
			["Параллельное удвоение руды"]),

		_quest("crusher_powered", 4, "II. Дробилка и резонит", "Дробилка под током",
			"Подключи дробилку к сети и запусти.",
			[_obj("Открыть дробилку", "machine_opened", "crusher", 1)],
			["Электропереработка"]),

		_quest("ore_doubling", 4, "II. Дробилка и резонит", "Конвейер руды",
			"Прогони железную руду через электродробилку.",
			[_obj("Получить железную пыль", "item_processed", "iron_dust", 40)],
			["Максимум из каждой жилы"]),

		_quest("red_dust_source", 4, "II. Дробилка и резонит", "Очистка резонита",
			"Прогрей резонитовые осколки в любой печи: примеси выгорят и кристалл подойдёт для схем T2 и терминалов.",
			[_obj("Получить очищенный резонит", "item_smelted", "purified_resonite", 8)],
			["Схемы T2 и терминалы"]),

		_quest("rubber_tech", 4, "II. Дробилка и резонит", "Экстрактор",
			"Собери экстрактор — он выжмет резину из латекса.",
			[_obj("Скрафтить экстрактор", "item_crafted", "extractor", 1)],
			["Резина и изоляция"]),

		_quest("rubber_harvest", 4, "II. Дробилка и резонит", "Сбор латекса",
			"Надрежь деревья: смола и латекс пойдут в экстрактор.",
			[
				_obj("Собрать латекс", "mine_yield", "latex", 10),
				_obj("Собрать смолу", "mine_yield", "tree_resin", 10),
			],
			["Сырьё для резины"]),

		_quest("insulated_wires", 4, "II. Дробилка и резонит", "Изолированные провода",
			"Обмотай провода резиной — надёжнее и безопаснее.",
			[_obj("Скрафтить изолированные провода", "item_crafted", "insulated_copper_wire", 12)],
			["Схемы T2"]),

		# ── III. Компоненты машин ───────────────────────────────────────────
		_quest("magnetic_rods", 4, "III. Компоненты машин", "Магнитные стержни",
			"Намагнить железные стержни резонитовыми осколками.",
			[_obj("Скрафтить магнитные стержни", "item_crafted", "magnetic_iron_rod", 4)],
			["Сердечники моторов"]),

		_quest("electric_motors", 4, "III. Компоненты машин", "Электромоторы",
			"Катушки, шестерня и железные стержни — сердце любой машины.",
			[_obj("Скрафтить электромоторы T1", "item_crafted", "electric_motor_t1", 4)],
			["Насосы, поршни, манипуляторы"]),

		_quest("electric_pumps", 4, "III. Компоненты машин", "Электронасосы",
			"Собери насосы для жидкостных машин.",
			[_obj("Скрафтить электронасосы T1", "item_crafted", "electric_pump_t1", 2)],
			["Водяные и нефтяные помпы"]),

		_quest("pistons", 4, "III. Компоненты машин", "Поршни",
			"Собери электропоршни.",
			[_obj("Скрафтить поршни T1", "item_crafted", "piston_t1", 2)],
			["Прессы и манипуляторы"]),

		_quest("robotic_arms", 4, "III. Компоненты машин", "Манипуляторы",
			"Роборука: поршень, мотор и схема.",
			[_obj("Скрафтить манипуляторы T1", "item_crafted", "robotic_arm_t1", 2)],
			["Автоматизация крафта"]),

		_quest("foil_press", 4, "III. Компоненты машин", "Фольга",
			"Раскатай пластины в тонкую фольгу.",
			[
				_obj("Скрафтить медную фольгу", "item_crafted", "copper_foil", 8),
				_obj("Скрафтить золотую фольгу", "item_crafted", "gold_foil", 4),
			],
			["Тонкая электроника"]),

		_quest("lens_grinding", 4, "III. Компоненты машин", "Шлифовка линз",
			"Отшлифуй линзы из стекла и золотой фольги.",
			[
				_obj("Скрафтить стеклянные линзы", "item_crafted", "glass_lens", 2),
				_obj("Скрафтить золотую линзу", "item_crafted", "gold_lens", 1),
			],
			["Сенсоры и эмиттеры"]),

		_quest("gold_wires", 4, "III. Компоненты машин", "Золотые провода",
			"Вытяни золото в провод и изолируй его для безопасных продвинутых схем.",
			[_obj("Изолировать золотые провода", "item_crafted", "insulated_gold_wire", 6)],
			["Прецизионные контакты"]),

		_quest("sensors_quest", 4, "III. Компоненты машин", "Сенсор",
			"Собери сенсор из линзы, серебра и схемы.",
			[_obj("Скрафтить сенсор T1", "item_crafted", "sensor_t1", 1)],
			["Зрение машин"]),

		_quest("emitters_quest", 4, "III. Компоненты машин", "Эмиттер",
			"Собери эмиттер — излучатель для машин.",
			[_obj("Скрафтить эмиттер T1", "item_crafted", "emitter_t1", 1)],
			["Излучатели машин"]),

		_quest("conveyor_modules", 4, "III. Компоненты машин", "Конвейерные модули",
			"Модуль конвейера: мотор и резина.",
			[_obj("Скрафтить конвейерные модули T1", "item_crafted", "conveyor_module_t1", 2)],
			["Машинная логистика"]),

		_quest("battery_tech", 4, "III. Компоненты машин", "Корпус аккумулятора",
			"Сверни корпуса для аккумуляторов.",
			[_obj("Скрафтить корпуса аккумуляторов", "item_crafted", "battery_casing", 2)],
			["Хранение энергии"]),

		_quest("first_batteries", 4, "III. Компоненты машин", "Аккумуляторы",
			"Собери первые аккумуляторные ячейки.",
			[_obj("Скрафтить аккумуляторные ячейки T1", "item_crafted", "battery_t1", 2)],
			["Модульное хранение энергии"]),

		# ── IV. Жидкости ────────────────────────────────────────────────────
		_quest("water_logistics", 4, "IV. Жидкости", "Водоснабжение",
			"Собери водяную помпу — вода нужна котлам и промывке.",
			[_obj("Скрафтить водяную помпу", "item_crafted", "water_pump", 1)],
			["Бесконечная вода"]),

		_quest("pump_opened", 4, "IV. Жидкости", "Насосная станция",
			"Поставь помпу у воды и запусти.",
			[_obj("Открыть водяную помпу", "machine_opened", "water_pump", 1)],
			["Подача воды"]),

		_quest("fluid_pipes_quest", 4, "IV. Жидкости", "Трубопровод",
			"Проложи жидкостные трубы.",
			[_obj("Скрафтить жидкостные трубы", "item_crafted", "fluid_pipe", 12)],
			["Транспорт жидкостей"]),

		_quest("fluid_tanks", 4, "IV. Жидкости", "Резервуары",
			"Собери баки для хранения жидкостей.",
			[
				_obj("Скрафтить резервуар T1", "item_crafted", "fluid_tank_t1", 1),
				_obj("Скрафтить резервуар T2", "item_crafted", "fluid_tank_t2", 1),
			],
			["Хранение воды и пара"]),

		_quest("oil_extraction", 4, "IV. Жидкости", "Чёрное золото",
			"Собери нефтекачку — начало нефтяной промышленности.",
			[_obj("Скрафтить нефтекачку", "item_crafted", "oil_pump", 1)],
			["Добыча сырой нефти"]),

		_quest("oil_opened", 4, "IV. Жидкости", "Качай нефть",
			"Поставь нефтекачку на месторождение.",
			[_obj("Открыть нефтекачку", "machine_opened", "oil_pump", 1)],
			["Сырая нефть"]),

		# ── V. Пар в ток ────────────────────────────────────────────────────
		_quest("steam_turbine", 4, "V. Пар в ток", "Паровая турбина",
			"Поставь турбину вплотную к котлу — пар станет током.",
			[_obj("Скрафтить паровую турбину", "item_crafted", "steam_turbine", 1)],
			["Пар превращается в EU"]),

		_quest("turbine_opened", 4, "V. Пар в ток", "Обороты турбины",
			"Запусти турбину и проверь выработку.",
			[_obj("Открыть турбину", "machine_opened", "steam_turbine", 1)],
			["Гибридная энергетика"]),

		_quest("advanced_casing", 4, "V. Пар в ток", "Продвинутый корпус",
			"Собери усиленные корпуса для электромашин.",
			[_obj("Скрафтить продвинутые корпуса", "item_crafted", "advanced_machine_casing", 2)],
			["Машины второго поколения"]),

		_quest("circuit_t2_first", 4, "V. Пар в ток", "Схемы T2",
			"Спаяй продвинутые схемы на серебре.",
			[_obj("Скрафтить схемы T2", "item_crafted", "circuit_t2", 3)],
			["Электропечь и тяжёлые машины"]),

		_quest("electric_smelting", 4, "V. Пар в ток", "Расширенная электроплавка",
			"Добавь вторую электропечь для параллельной плавки разных металлов.",
			[
				_obj("Скрафтить электропечи", "item_crafted", "electric_furnace", 2),
				_obj("Открыть электропечь", "machine_opened", "electric_furnace", 1),
			],
			["Плавка на электричестве"]),

		_quest("drill_upgrade", 4, "V. Пар в ток", "Стальной бур",
			"Собери стальной бур — третий уровень добычи.",
			[
				_obj("Скрафтить стальную головку", "item_crafted", "drill_head_steel", 1),
				_obj("Скрафтить стальной бур", "item_crafted", "steel_drill", 1),
			],
			["Открывает Главу 5"]),
	]


# ══ Chapter 5: Электрический век ═════════════════════════════════════════════
static func _chapter_5() -> Array[QuestData]:
	return [
		# ── I. Солнечная энергия ────────────────────────────────────────────
		_quest("solar_dawn", 5, "I. Солнечная энергия", "Солнечный рассвет",
			"Перейди на энергию солнца.",
			[_obj("Скрафтить солнечную панель", "item_crafted", "solar_panel", 1)],
			["Бесплатная энергия днём"]),

		_quest("solar_opened", 5, "I. Солнечная энергия", "К свету",
			"Установи панель под открытым небом.",
			[_obj("Открыть солнечную панель", "machine_opened", "solar_panel", 1)],
			["Солнечная генерация"]),

		_quest("solar_farm", 5, "I. Солнечная энергия", "Солнечная ферма",
			"Одна панель — не ферма. Расширь поле.",
			[_obj("Поставить солнечные панели", "block_placed", "solar_panel", 3)],
			["Масштабная генерация"]),

		_quest("advanced_solar", 5, "I. Солнечная энергия", "Продвинутая панель",
			"Собери панель второго поколения.",
			[_obj("Скрафтить продвинутую панель", "item_crafted", "advanced_solar_panel", 1)],
			["Вдвое больше EU"]),

		_quest("energy_bank", 5, "I. Солнечная энергия", "Энергохранилище",
			"Собери накопители — ночью панели спят.",
			[
				_obj("Скрафтить энергохранилище T1", "item_crafted", "energy_storage_t1", 1),
				_obj("Скрафтить энергохранилище T2", "item_crafted", "energy_storage_t2", 1),
			],
			["Запас энергии на ночь"]),

		# ── II. Пластик и электроника ───────────────────────────────────────
		_quest("plastic_age", 5, "II. Пластик и электроника", "Эра пластика",
			"Свари пластик из резины и угольной пыли.",
			[_obj("Скрафтить пластик", "item_crafted", "plastic", 8)],
			["Основа электроники"]),

		_quest("electronic_boards", 5, "II. Пластик и электроника", "Электронные платы",
			"Собери платы на пластиковой подложке.",
			[_obj("Скрафтить электронные платы", "item_crafted", "electronic_board", 4)],
			["Чипы и память"]),

		_quest("microchips", 5, "II. Пластик и электроника", "Микрочипы",
			"Спаяй первые микрочипы.",
			[_obj("Скрафтить микрочипы", "item_crafted", "microchip", 8)],
			["Процессоры"]),

		_quest("silicon_smelting", 5, "II. Пластик и электроника", "Технический кремний",
			"Выплави кремний из песка и угольной пыли.",
			[_obj("Скрафтить кремниевые слитки", "item_crafted", "silicon_ingot", 4)],
			["Кремниевые пластины"]),

		_quest("silicon_wafers", 5, "II. Пластик и электроника", "Кремниевые пластины",
			"Нарежь слитки на тонкие пластины.",
			[_obj("Скрафтить кремниевые пластины", "item_crafted", "silicon_wafer", 8)],
			["Транзисторы и диоды"]),

		_quest("transistors_diodes", 5, "II. Пластик и электроника", "Полупроводники",
			"Собери первые транзисторы и диоды.",
			[
				_obj("Скрафтить транзисторы", "item_crafted", "transistor", 8),
				_obj("Скрафтить диоды", "item_crafted", "diode", 8),
			],
			["Начинка процессоров"]),

		_quest("cpu_die_quest", 5, "II. Пластик и электроника", "Кристалл процессора",
			"Вытрави кристалл на кремниевой пластине.",
			[_obj("Скрафтить кристаллы", "item_crafted", "cpu_die", 2)],
			["Нанопроцессоры (Глава 6)"]),

		_quest("circuit_t2_quest", 5, "II. Пластик и электроника", "Серийные схемы",
			"Поставь выпуск схем T2 на поток.",
			[_obj("Скрафтить схемы T2", "item_crafted", "circuit_t2", 10)],
			["Машины пятой эпохи"]),

		_quest("processors", 5, "II. Пластик и электроника", "Процессоры",
			"Собери процессоры из чипов и схем.",
			[_obj("Скрафтить процессоры", "item_crafted", "processor", 4)],
			["Вычислительные машины"]),

		_quest("ram_quest", 5, "II. Пластик и электроника", "Память",
			"Собери планки памяти.",
			[_obj("Скрафтить память", "item_crafted", "ram", 4)],
			["Компьютеры"]),

		_quest("electrum_alloy", 5, "II. Пластик и электроника", "Электрум",
			"Сплавь золото и серебро в электрум.",
			[_obj("Скрафтить электрум", "item_crafted", "electrum_ingot", 8)],
			["Провода высшего класса"]),

		_quest("electrum_wires", 5, "II. Пластик и электроника", "Электрумовые провода",
			"Вытяни электрум в провод для схем T3.",
			[_obj("Скрафтить электрумовые провода", "item_crafted", "electrum_wire", 8)],
			["Схемы T3"]),

		_quest("capacitors", 5, "II. Пластик и электроника", "Конденсаторы",
			"Собери конденсаторы двух поколений.",
			[
				_obj("Скрафтить конденсаторы T1", "item_crafted", "capacitor_t1", 4),
				_obj("Скрафтить конденсаторы T2", "item_crafted", "capacitor_t2", 2),
			],
			["Энергетика приборов"]),

		_quest("battery_t2_quest", 5, "II. Пластик и электроника", "Аккумуляторы T2",
			"Улучши аккумуляторы.",
			[_obj("Скрафтить аккумуляторные ячейки T2", "item_crafted", "battery_t2", 2)],
			["Ёмкие аккумуляторы"]),

		# ── III. Машины второго тира ────────────────────────────────────────
		_quest("motors_t2", 5, "III. Машины второго тира", "Моторы T2",
			"Собери моторы второго поколения.",
			[_obj("Скрафтить электромоторы T2", "item_crafted", "electric_motor_t2", 4)],
			["Компоненты T2"]),

		_quest("components_t2", 5, "III. Машины второго тира", "Гидравлика T2",
			"Насосы и поршни второго тира.",
			[
				_obj("Скрафтить электронасосы T2", "item_crafted", "electric_pump_t2", 2),
				_obj("Скрафтить поршни T2", "item_crafted", "piston_t2", 2),
			],
			["Тяжёлые машины"]),

		_quest("arms_t2", 5, "III. Машины второго тира", "Манипуляторы T2",
			"Роборуки второго поколения.",
			[_obj("Скрафтить манипуляторы T2", "item_crafted", "robotic_arm_t2", 2)],
			["Продвинутая автоматика"]),

		_quest("sensors_t2", 5, "III. Машины второго тира", "Приборы T2",
			"Сенсор и эмиттер второго тира.",
			[
				_obj("Скрафтить сенсор T2", "item_crafted", "sensor_t2", 1),
				_obj("Скрафтить эмиттер T2", "item_crafted", "emitter_t2", 1),
			],
			["Точные приборы"]),

		_quest("conveyor_modules_t2", 5, "III. Машины второго тира", "Модули T2",
			"Конвейерные модули второго тира.",
			[_obj("Скрафтить конвейерные модули T2", "item_crafted", "conveyor_module_t2", 2)],
			["Быстрая логистика"]),

		_quest("conveyor_t3_quest", 5, "III. Машины второго тира", "Конвейеры T3",
			"Смонтируй скоростные конвейеры.",
			[_obj("Скрафтить конвейеры T3", "item_crafted", "conveyor_t3", 4)],
			["Скоростные линии"]),

		_quest("compressor_quest", 5, "III. Машины второго тира", "Компрессор",
			"Собери компрессор — прессует уголь и не только.",
			[
				_obj("Скрафтить компрессор", "item_crafted", "compressor", 1),
				_obj("Открыть компрессор", "machine_opened", "compressor", 1),
			],
			["Прессованное топливо"]),

		_quest("cobblegen_quest", 5, "III. Машины второго тира", "Генератор булыжника",
			"Бесконечный камень без кирки.",
			[_obj("Скрафтить генератор булыжника", "item_crafted", "cobblestone_generator", 1)],
			["Бесконечный камень"]),

		_quest("farming_quest", 5, "III. Машины второго тира", "Фермстанция",
			"Автоматизируй грядки фермстанцией.",
			[_obj("Скрафтить фермстанцию", "item_crafted", "farming_station", 1)],
			["Автоферма"]),

		# ── IV. Полная переработка ──────────────────────────────────────────
		_quest("ore_washing", 5, "IV. Полная переработка", "Промывка руды",
			"Собери промывочную машину — чище металл, больше выход.",
			[_obj("Скрафтить промывочную машину", "item_crafted", "ore_washer", 1)],
			["Цепочка обогащения"]),

		_quest("washer_opened", 5, "IV. Полная переработка", "Вода в дело",
			"Подведи воду и запусти промывку.",
			[_obj("Открыть промывочную машину", "machine_opened", "ore_washer", 1)],
			["Мокрое обогащение"]),

		_quest("washed_iron", 5, "IV. Полная переработка", "Промывка железа",
			"Промой железную руду и получи обычную железную пыль.",
			[_obj("Получить железную пыль", "item_processed", "iron_dust", 20)],
			["Никелевая пыль в бонус"]),

		_quest("washed_copper", 5, "IV. Полная переработка", "Промывка меди",
			"Промой медную руду и получи обычную медную пыль.",
			[_obj("Получить медную пыль", "item_processed", "copper_dust", 20)],
			["Золотая пыль в бонус"]),

		_quest("centrifuging", 5, "IV. Полная переработка", "Центрифуга",
			"Разделяй сырую руду на основную и побочную металлическую пыль.",
			[_obj("Скрафтить центрифугу", "item_crafted", "centrifuge", 1)],
			["Финал цепочки обогащения"]),

		_quest("iron_dust_cycle", 5, "IV. Полная переработка", "Железная пыль",
			"Прогони железо через полную цепочку.",
			[_obj("Получить железную пыль", "item_processed", "iron_dust", 20)],
			["Максимальный выход железа"]),

		_quest("copper_dust_cycle", 5, "IV. Полная переработка", "Медная пыль",
			"Полная переработка меди.",
			[_obj("Получить медную пыль", "item_processed", "copper_dust", 20)],
			["Максимальный выход меди"]),

		_quest("tiny_dust_recycling", 5, "IV. Полная переработка", "Побочные металлы",
			"Получи обычную никелевую пыль как побочный продукт переработки.",
			[_obj("Получить никелевую пыль", "item_processed", "nickel_dust", 2)],
			["Дополнительные металлы"]),

		_quest("titanium_processing", 5, "IV. Полная переработка", "Титановый передел",
			"Переработай титановую руду в пыль — впереди титановая эра.",
			[_obj("Получить титановую пыль", "item_processed", "titanium_dust", 20)],
			["Сырьё шестой эпохи"]),

		_quest("titanium_smelting", 5, "IV. Полная переработка", "Титановые слитки",
			"Выплавь титан.",
			[_obj("Выплавить титан", "item_smelted", "titanium_ingot", 10)],
			["Материал высшего тира"]),

		# ── V. Глубокая переработка ─────────────────────────────────────────
		_quest("magnetic_separator_quest", 5, "V. Глубокая переработка", "Магнитный сепаратор",
			"Собери сепаратор для прямого выделения пыли и побочных металлов из руды.",
			[_obj("Скрафтить магнитный сепаратор", "item_crafted", "magnetic_separator", 1)],
			["Металлическая пыль"]),

		_quest("separator_opened", 5, "V. Глубокая переработка", "Магнитное поле",
			"Подключи сепаратор и загрузи обычную руду.",
			[_obj("Открыть сепаратор", "machine_opened", "magnetic_separator", 1)],
			["Магнитная сепарация"]),

		_quest("refined_iron", 5, "V. Глубокая переработка", "Сепарация железа",
			"Прогони железную руду через магнитный сепаратор.",
			[_obj("Получить железную пыль", "item_processed", "iron_dust", 20)],
			["Двойная основная пыль", "Никелевая побочка"]),

		_quest("refined_copper", 5, "V. Глубокая переработка", "Сепарация меди",
			"Сепарируй медную руду — побочкой пойдёт золотая пыль.",
			[_obj("Получить медную пыль", "item_processed", "copper_dust", 20)],
			["Золотая пыль в бонус"]),

		_quest("double_dust", 5, "V. Глубокая переработка", "Двойная пыль",
			"Перерабатывающие машины дают две основные пыли из одной руды.",
			[_obj("Получить железную пыль", "item_processed", "iron_dust", 40)],
			["Прямая переработка руды в пыль"]),

		# ── VI. Плавильня и литьё ───────────────────────────────────────────
		_quest("ore_melter_quest", 5, "VI. Плавильня и литьё", "Индукционная плавильня",
			"Собери плавильню — руда и слитки станут жидким металлом.",
			[_obj("Скрафтить плавильню", "item_crafted", "ore_melter", 1)],
			["Жидкий металл (90 л = слиток)"]),

		_quest("melter_opened", 5, "VI. Плавильня и литьё", "Первый расплав",
			"Расплавь руду, пыль или слиток: каждая единица металла даёт 90 л.",
			[_obj("Открыть плавильню", "machine_opened", "ore_melter", 1)],
			["Расплав в трубы"]),

		_quest("mold_making", 5, "VI. Плавильня и литьё", "Литейные формы",
			"Выкуй стальные формы для литья. Они не расходуются.",
			[
				_obj("Скрафтить форму пластины", "item_crafted", "mold_plate", 1),
				_obj("Скрафтить форму стержня", "item_crafted", "mold_rod", 1),
				_obj("Скрафтить форму провода", "item_crafted", "mold_wire", 1),
				_obj("Скрафтить форму шестерни", "item_crafted", "mold_gear", 1),
			],
			["Литьё деталей из расплава"]),

		_quest("chemical_reactor_quest", 5, "VI. Плавильня и литьё", "Химический реактор",
			"Собери реактор: 1-2 жидкости плюс предмет — новый предмет.",
			[_obj("Скрафтить химический реактор", "item_crafted", "chemical_reactor", 1)],
			["Литьё и химия"]),

		_quest("reactor_opened", 5, "VI. Плавильня и литьё", "Запуск реактора",
			"Подведи трубы с жидкостями и вставь форму или сырьё.",
			[_obj("Открыть химический реактор", "machine_opened", "chemical_reactor", 1)],
			["Рецепты литья и химии"]),

		_quest("first_casting", 5, "VI. Плавильня и литьё", "Закалка стали",
			"Расплав стали, вода и железная пластина — плотная пластина.",
			[_obj("Получить плотные пластины", "item_processed", "dense_iron_plate", 2)],
			["Плотный прокат"]),

		_quest("concrete_works", 5, "VI. Плавильня и литьё", "Бетонный завод",
			"Замешай бетон из гравия и воды в реакторе.",
			[_obj("Получить бетон", "item_processed", "concrete", 16)],
			["Строительный материал"]),

		_quest("carbon_chemistry", 5, "VI. Плавильня и литьё", "Углехимия",
			"Свари углепластик из пластика и сырой нефти.",
			[_obj("Получить углепластик", "item_processed", "carbon_plastic", 4)],
			["Композитные материалы"]),

		# ── VII. Нефть и жидкости ───────────────────────────────────────────
		_quest("big_tanks", 5, "VII. Нефть и жидкости", "Большие резервуары",
			"Собери вместительные баки.",
			[
				_obj("Скрафтить резервуар T3", "item_crafted", "fluid_tank_t3", 1),
				_obj("Скрафтить резервуар T4", "item_crafted", "fluid_tank_t4", 1),
			],
			["Хранение сотен литров"]),

		_quest("oil_refining", 5, "VII. Нефть и жидкости", "Фракционирование нефти",
			"Собери ректификационную колонну.",
			[_obj("Скрафтить колонну", "item_crafted", "distillation_column", 1)],
			["Бензин, керосин, дизель"]),

		_quest("distillation_opened", 5, "VII. Нефть и жидкости", "Первая фракция",
			"Залей нефть и запусти колонну.",
			[_obj("Открыть колонну", "machine_opened", "distillation_column", 1)],
			["Продукты нефтепереработки"]),

		# ── VI. Цифровое хранилище ──────────────────────────────────────────
		_quest("me_network", 5, "VIII. Цифровое хранилище", "Цифровая сеть",
			"Собери ME-сеть: контроллер, накопитель, ячейку и терминал.",
			[
				_obj("Скрафтить ME Controller", "item_crafted", "me_controller", 1),
				_obj("Скрафтить ME Drive", "item_crafted", "me_drive", 1),
				_obj("Скрафтить ME-ячейку 1k", "item_crafted", "me_item_cell_1k", 1),
				_obj("Скрафтить ME Terminal", "item_crafted", "me_terminal", 1),
			],
			["Цифровое хранилище"]),

		_quest("me_cables_quest", 5, "VIII. Цифровое хранилище", "ME-магистраль",
			"Соедини сеть кабелями.",
			[
				_obj("Скрафтить ME-кабели", "item_crafted", "me_cable", 16),
				_obj("Проложить ME-кабели", "block_placed", "me_cable", 8),
			],
			["Расширение сети"]),

		_quest("me_crafting", 5, "VIII. Цифровое хранилище", "Крафт из сети",
			"Собери крафт-терминал — верстак с доступом ко всему складу.",
			[_obj("Скрафтить ME Crafting Terminal", "item_crafted", "me_crafting_terminal", 1)],
			["Крафт из хранилища"]),

		_quest("me_automation", 5, "VIII. Цифровое хранилище", "Автоматизация ME",
			"Свяжи сеть с машинами: шины и интерфейс.",
			[
				_obj("Скрафтить ME Import Bus", "item_crafted", "me_import_bus", 1),
				_obj("Скрафтить ME Export Bus", "item_crafted", "me_export_bus", 1),
				_obj("Скрафтить ME Interface", "item_crafted", "me_interface", 1),
			],
			["Автоввод/вывод предметов"]),

		_quest("me_cells_upgrade", 5, "VIII. Цифровое хранилище", "Ёмкие ячейки",
			"Расширь хранилище ячейками покрупнее.",
			[
				_obj("Скрафтить ячейку 4k", "item_crafted", "me_item_cell_4k", 1),
				_obj("Скрафтить ячейку 16k", "item_crafted", "me_item_cell_16k", 1),
			],
			["Тысячи предметов в сети"]),

		_quest("me_fluids", 5, "VIII. Цифровое хранилище", "Жидкости в цифре",
			"Заведи жидкостную ячейку — нефть тоже можно хранить в сети.",
			[_obj("Скрафтить жидкостную ячейку 1k", "item_crafted", "me_fluid_cell_1k", 1)],
			["Цифровое хранение жидкостей"]),

		# ── VII. Защита и материалы ─────────────────────────────────────────
		_quest("carbon_tech", 5, "IX. Защита и материалы", "Углеволокно",
			"Скрути углеволокно и сотки углеткань.",
			[
				_obj("Скрафтить углеволокно", "item_crafted", "carbon_fiber", 8),
				_obj("Скрафтить углеткань", "item_crafted", "carbon_cloth", 4),
			],
			["Лёгкая броня и фильтры"]),

		_quest("hazard_suits", 5, "IX. Защита и материалы", "Спецзащита",
			"Сшей костюмы для опасных биомов.",
			[
				_obj("Скрафтить термокостюм", "item_crafted", "heat_suit", 1),
				_obj("Скрафтить изолирующий костюм", "item_crafted", "insulated_suit", 1),
			],
			["Доступ в опасные зоны"]),

		_quest("uranium_agenda", 5, "IX. Защита и материалы", "Урановая программа",
			"Добудь уран — топливо далёкого будущего.",
			[_obj("Добыть урановую руду", "mine_yield", "uranium_ore", 20)],
			["Открывает Главу 6"]),
	]


# ══ Chapter 6: Промышленный век ══════════════════════════════════════════════
static func _chapter_6() -> Array[QuestData]:
	return [
		# ── I. Промышленное ядро ────────────────────────────────────────────
		_quest("titanium_rush", 6, "I. Промышленное ядро", "Титановая лихорадка",
			"Раскачай добычу титана.",
			[_obj("Добыть титановую руду", "mine_yield", "titanium_ore", 30)],
			["Сырьё промышленного века"]),

		_quest("titanium_reserve", 6, "I. Промышленное ядро", "Титановый запас",
			"Переплавь титан впрок.",
			[_obj("Выплавить титан", "item_smelted", "titanium_ingot", 20)],
			["Корпуса и буры"]),

		_quest("industrial_boards", 6, "I. Промышленное ядро", "Промышленные платы",
			"Собери платы высшего класса.",
			[_obj("Скрафтить промышленные платы", "item_crafted", "industrial_board", 4)],
			["Схемы T3"]),

		_quest("industrial_age", 6, "I. Промышленное ядро", "Промышленник",
			"Собери промышленные корпуса машин.",
			[_obj("Скрафтить промышленные корпуса", "item_crafted", "industrial_machine_casing", 2)],
			["Вершина машиностроения"]),

		_quest("advanced_frames", 6, "I. Промышленное ядро", "Продвинутые каркасы",
			"Свари каркасы из титана и стали.",
			[_obj("Скрафтить продвинутые каркасы", "item_crafted", "advanced_machine_frame", 2)],
			["Тяжёлая техника"]),

		_quest("circuit_t3_quest", 6, "I. Промышленное ядро", "Схемы T3",
			"Спаяй промышленные микросхемы.",
			[_obj("Скрафтить схемы T3", "item_crafted", "circuit_t3", 3)],
			["Электроника высшего тира"]),

		# ── II. Компоненты третьего тира ────────────────────────────────────
		_quest("motors_t3", 6, "II. Компоненты третьего тира", "Моторы T3",
			"Собери моторы высшего тира.",
			[_obj("Скрафтить электромоторы T3", "item_crafted", "electric_motor_t3", 2)],
			["Компоненты T3"]),

		_quest("components_t3", 6, "II. Компоненты третьего тира", "Гидравлика T3",
			"Насос и поршень высшего тира.",
			[
				_obj("Скрафтить электронасос T3", "item_crafted", "electric_pump_t3", 1),
				_obj("Скрафтить поршень T3", "item_crafted", "piston_t3", 1),
			],
			["Промышленные машины"]),

		_quest("arms_t3", 6, "II. Компоненты третьего тира", "Манипулятор T3",
			"Роборука высшего поколения.",
			[_obj("Скрафтить манипулятор T3", "item_crafted", "robotic_arm_t3", 1)],
			["Полная автоматизация"]),

		_quest("platinum_industry", 6, "II. Компоненты третьего тира", "Платина",
			"Добудь платину и раскатай её в пластины.",
			[
				_obj("Добыть платиновую руду", "mine_yield", "platinum_ore", 10),
				_obj("Скрафтить платиновые пластины", "item_crafted", "platinum_plate", 2),
			],
			["Прецизионные приборы"]),

		_quest("sensors_t3", 6, "II. Компоненты третьего тира", "Приборы T3",
			"Сенсор и эмиттер высшего тира.",
			[
				_obj("Скрафтить сенсор T3", "item_crafted", "sensor_t3", 1),
				_obj("Скрафтить эмиттер T3", "item_crafted", "emitter_t3", 1),
			],
			["Совершенные приборы"]),

		_quest("conveyor_modules_t3", 6, "II. Компоненты третьего тира", "Модули T3",
			"Конвейерные модули высшего тира.",
			[_obj("Скрафтить конвейерные модули T3", "item_crafted", "conveyor_module_t3", 2)],
			["Мгновенная логистика"]),

		_quest("conveyor_t4_quest", 6, "II. Компоненты третьего тира", "Конвейеры T4",
			"Смонтируй линию четвёртого поколения.",
			[_obj("Скрафтить конвейеры T4", "item_crafted", "conveyor_t4", 4)],
			["Сверхскоростные линии"]),

		_quest("conveyor_t5_quest", 6, "II. Компоненты третьего тира", "Конвейеры T5",
			"Предел скорости ленты.",
			[_obj("Скрафтить конвейеры T5", "item_crafted", "conveyor_t5", 4)],
			["Максимум логистики"]),

		# ── III. Вычислительный центр ───────────────────────────────────────
		_quest("advanced_processors", 6, "III. Вычислительный центр", "Продвинутые процессоры",
			"Собери процессоры нового поколения.",
			[_obj("Скрафтить продвинутые процессоры", "item_crafted", "advanced_processor", 2)],
			["Мощные вычисления"]),

		_quest("motherboard_quest", 6, "III. Вычислительный центр", "Материнская плата",
			"Распаяй материнскую плату.",
			[_obj("Скрафтить материнскую плату", "item_crafted", "motherboard", 1)],
			["Сборка компьютера"]),

		_quest("computer_quest", 6, "III. Вычислительный центр", "Компьютер",
			"Собери первый компьютер.",
			[_obj("Скрафтить компьютер", "item_crafted", "computer", 1)],
			["Управление производством"]),

		_quest("nano_processors", 6, "III. Вычислительный центр", "Нанопроцессоры",
			"Собери нанопроцессоры из кристаллов и транзисторов.",
			[_obj("Скрафтить нанопроцессоры", "item_crafted", "nano_processor", 2)],
			["Плотная электроника"]),

		_quest("crystal_processors", 6, "III. Вычислительный центр", "Кристальный процессор",
			"Оптическое ядро: нанопроцессор, диоды и золотая линза.",
			[_obj("Скрафтить кристальный процессор", "item_crafted", "crystal_processor", 1)],
			["Экзотические вычисления"]),

		_quest("quantum_processors", 6, "III. Вычислительный центр", "Квантовый процессор",
			"Шагни за предел классических вычислений.",
			[_obj("Скрафтить квантовый процессор", "item_crafted", "quantum_processor", 1)],
			["Квантовые технологии"]),

		_quest("super_computer_quest", 6, "III. Вычислительный центр", "Суперкомпьютер",
			"Собери суперкомпьютер — вершину вычислений.",
			[_obj("Скрафтить суперкомпьютер", "item_crafted", "super_computer", 1)],
			["Вершина вычислений"]),

		# ── IV. Энергия будущего ────────────────────────────────────────────
		_quest("battery_t3_quest", 6, "IV. Энергия будущего", "Аккумуляторы T3",
			"Собери аккумуляторные ячейки высшей ёмкости.",
			[_obj("Скрафтить аккумуляторные ячейки T3", "item_crafted", "battery_t3", 2)],
			["Максимум ёмкости"]),

		_quest("capacitor_t3_quest", 6, "IV. Энергия будущего", "Конденсаторы T3",
			"Конденсаторы высшего класса.",
			[_obj("Скрафтить конденсаторы T3", "item_crafted", "capacitor_t3", 2)],
			["Импульсная энергия"]),

		_quest("energy_bank_t3", 6, "IV. Энергия будущего", "Энергохранилище T3",
			"Построй хранилище энергии высшего тира.",
			[_obj("Скрафтить энергохранилище T3", "item_crafted", "energy_storage_t3", 1)],
			["Мегаватты про запас"]),

		_quest("elite_solar_quest", 6, "IV. Энергия будущего", "Элитная панель",
			"Собери элитную солнечную панель.",
			[_obj("Скрафтить элитную панель", "item_crafted", "elite_solar_panel", 1)],
			["Элитная генерация"]),

		_quest("ultimate_solar_quest", 6, "IV. Энергия будущего", "Абсолютная панель",
			"Предел солнечной энергетики.",
			[_obj("Скрафтить абсолютную панель", "item_crafted", "ultimate_solar_panel", 1)],
			["Пик солнечной энергии"]),

		_quest("uranium_industry", 6, "IV. Энергия будущего", "Урановый арсенал",
			"Добудь уран титановым буром, извлеки сырьё и подготовь его в электропечи.",
			[
				_obj("Добыть урановую руду", "mine_yield", "uranium_ore", 40),
				_obj("Извлечь урановое сырьё", "item_processed", "uranium_raw", 8),
				_obj("Обработать уран", "item_smelted", "uranium_processed", 4),
			],
			["Задел на ядерную эру"]),

		# ── V. Титановые буры и мифрил ──────────────────────────────────────
		_quest("drill_head_titanium_quest", 6, "V. Титановые буры и мифрил", "Титановая головка",
			"Выточи буровую головку из титана.",
			[_obj("Скрафтить титановую головку", "item_crafted", "drill_head_titanium", 1)],
			["Бур четвёртого тира"]),

		_quest("titanium_drill_quest", 6, "V. Титановые буры и мифрил", "Титановый бур",
			"Собери титановый бур.",
			[_obj("Скрафтить титановый бур", "item_crafted", "titanium_drill", 1)],
			["Добыча руды 4 уровня"]),

		_quest("drill_head_advanced_quest", 6, "V. Титановые буры и мифрил", "Продвинутая головка",
			"Собери буровую головку высшего класса.",
			[_obj("Скрафтить продвинутую головку", "item_crafted", "drill_head_advanced", 1)],
			["Бур пятого тира"]),

		_quest("advanced_drill_quest", 6, "V. Титановые буры и мифрил", "Продвинутый бур",
			"Вершина буровой техники — он берёт даже мифрил.",
			[_obj("Скрафтить продвинутый бур", "item_crafted", "advanced_drill", 1)],
			["Добыча мифрила"]),

		_quest("mythril_bore", 6, "V. Титановые буры и мифрил", "Мифриловая жила",
			"Поставь продвинутый бур на мифриловую жилу и добудь первую партию руды.",
			[_obj("Добыть мифриловую руду", "mine_yield", "mythril_ore", 10)],
			["Легендарный металл"]),

		_quest("mythril_purity", 6, "V. Титановые буры и мифрил", "Чистый мифрил",
			"Промой мифриловую руду и собери пыль.",
			[_obj("Получить мифриловую пыль", "item_processed", "mythril_dust", 10)],
			["Платиновая пыль в бонус"]),

		_quest("mythril_smelting", 6, "V. Титановые буры и мифрил", "Мифриловые слитки",
			"Выплавь мифрил.",
			[_obj("Выплавить мифрил", "item_smelted", "mythril_ingot", 5)],
			["Материал легенд"]),

		_quest("mythril_dust_quest", 6, "V. Титановые буры и мифрил", "Мифриловая пыль",
			"Прогони мифрил через центрифугу до чистой пыли.",
			[_obj("Получить мифриловую пыль", "item_processed", "mythril_dust", 5)],
			["Максимальный выход мифрила"]),

		# ── VI. Молекулярные технологии ─────────────────────────────────────
		_quest("molecular_transformer_quest", 6, "VI. Молекулярные технологии", "Молекулярный трансформер",
			"Машина, пересобирающая материю.",
			[
				_obj("Скрафтить трансформер", "item_crafted", "molecular_transformer", 1),
				_obj("Открыть трансформер", "machine_opened", "molecular_transformer", 1),
			],
			["Твёрдая материя"]),

		_quest("me_assembler_quest", 6, "VI. Молекулярные технологии", "Молекулярный сборщик",
			"Автокрафт прямо в ME-сети.",
			[_obj("Скрафтить ME Assembler", "item_crafted", "me_molecular_assembler", 1)],
			["Автоматический крафт"]),

		_quest("me_64k_quest", 6, "VI. Молекулярные технологии", "Ячейка 64k",
			"Максимальная ячейка хранения.",
			[_obj("Скрафтить ячейку 64k", "item_crafted", "me_item_cell_64k", 1)],
			["Предел цифрового склада"]),

		_quest("maximum_fluid_storage", 6, "VI. Молекулярные технологии", "Тысяча литров",
			"Доведи резервуар до максимального объёма.",
			[_obj("Скрафтить резервуар T5", "item_crafted", "fluid_tank_t5", 1)],
			["Резервуар на 1000 л"]),

		# ── VII. Жидкостные сплавы ──────────────────────────────────────────
		_quest("mixer_quest", 6, "VII. Жидкостные сплавы", "Смеситель",
			"Собери смеситель — огромную машину для сплавления жидкостей.",
			[_obj("Скрафтить смеситель", "item_crafted", "mixer", 1)],
			["Смешивание 2-4 жидкостей"]),

		_quest("mixer_placed", 6, "VII. Жидкостные сплавы", "Место под гиганта",
			"Расчисти площадку 3×3 и установи смеситель.",
			[_obj("Поставить смеситель", "block_placed", "mixer", 1)],
			["Машина занимает 9 клеток"]),

		_quest("mixer_opened", 6, "VII. Жидкостные сплавы", "Пуск смесителя",
			"Подведи трубы с расплавами и запитай машину.",
			[_obj("Открыть смеситель", "machine_opened", "mixer", 1)],
			["Жидкая бронза и электрум", "Топливные смеси"]),

		_quest("molten_alloys", 6, "VII. Жидкостные сплавы", "Литой электрум",
			"Смешай расплавы золота и серебра и отлей провода через форму.",
			[_obj("Отлить электрумовые провода", "item_processed", "electrum_wire", 8)],
			["Сплавы без верстака"]),

		# ── VIII. Легенда ───────────────────────────────────────────────────
		_quest("industrial_legend", 6, "VIII. Легенда", "Легенда индустрии",
			"Империя машин работает на тебя. Впереди — бесконечность.",
			[_obj("Хранить предметы в сундуках", "items_stored", "", 5000)],
			["Финал текущей прогрессии", "Дальше — путь к Infinity"]),
	]


static func _quest(
	id: String, age: int, tab: String, title: String, desc: String,
	objs: Array, unlocks: Array
) -> QuestData:
	var q := QuestData.new()
	q.quest_id    = id
	q.age         = age
	q.tab         = tab
	q.title       = title
	q.description = desc
	q.objectives.assign(objs)
	q.unlocks     = PackedStringArray(unlocks)
	return q


static func _tutorial(
	id: String, age: int, tab: String, title: String, desc: String,
	objs: Array, unlocks: Array, prerequisites: Array = []
) -> QuestData:
	var quest := _quest(id, age, tab, title, desc, objs, unlocks)
	quest.optional = true
	quest.is_tutorial = true
	quest.prerequisite_quests = PackedStringArray(prerequisites)
	return quest


static func _obj(desc: String, ev_type: String, ev_detail: String, count: int) -> QuestObjective:
	var o := QuestObjective.new()
	o.description   = desc
	o.event_type    = ev_type
	o.event_detail  = ev_detail
	o.required_count = count
	return o
