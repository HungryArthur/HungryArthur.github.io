# res://core/systems/achievements/AchievementDB.gd
#
# Реестр достижений игры. Определения статичны; факт разблокировки хранится
# в профиле игрока (ProfileData.achievements: Array[String] — список id).
#
# Поля определения:
#   id    — уникальный идентификатор (пишется в профиль при разблокировке)
#   title — заголовок (англ. текст = ключ локализации)
#   desc  — описание (англ. текст = ключ локализации)
#   icon  — id предмета из ItemDatabase, чья текстура рисуется как эмблема ("" = без иконки)
class_name AchievementDB
extends RefCounted

const LIST: Array[Dictionary] = [
	{ "id": "quest_first", "title": "First Step", "desc": "Complete your first quest", "icon": "codex", "quest_count": 1 },
	{ "id": "quest_25", "title": "Reliable Engineer", "desc": "Complete 25 quests", "icon": "advanced_board", "quest_count": 25 },
	{ "id": "quest_100", "title": "Master of Progress", "desc": "Complete 100 quests", "icon": "processor", "quest_count": 100 },
	{ "id": "age_1", "title": "Stone Age",         "desc": "Complete the Stone Age chapter",       "icon": "furnace",                   "age": 1 },
	{ "id": "age_2", "title": "Industrialization", "desc": "Complete the Industrialization chapter", "icon": "basic_machine_casing",    "age": 2 },
	{ "id": "age_3", "title": "Iron Age",          "desc": "Complete the Iron Age chapter",        "icon": "advanced_machine_casing",   "age": 3 },
	{ "id": "age_4", "title": "Electrification",   "desc": "Complete the Electrification chapter", "icon": "circuit_t1",                "age": 4 },
	{ "id": "age_5", "title": "Electric Age",      "desc": "Complete the Electric Age chapter",    "icon": "crusher",                   "age": 5 },
	{ "id": "age_6", "title": "Industrial Age",    "desc": "Complete the Industrial Age chapter",  "icon": "industrial_machine_casing", "age": 6 },
	{ "id": "boss_ent", "title": "Forest Cleared", "desc": "Defeat the Ent", "icon": "ent_totem", "boss": "ent" },
	{ "id": "boss_dune_colossus", "title": "Sandbreaker", "desc": "Defeat the Dune Colossus", "icon": "sand", "boss": "dune_colossus" },
	{ "id": "boss_frost_warden", "title": "Thaw the Warden", "desc": "Defeat the Frost Warden", "icon": "ice_shard", "boss": "frost_warden" },
	{ "id": "boss_mire_hydra", "title": "Cut Every Head", "desc": "Defeat the Mire Hydra", "icon": "reed", "boss": "mire_hydra" },
	{ "id": "boss_thorn_matriarch", "title": "No More Thorns", "desc": "Defeat the Thorn Matriarch", "icon": "tree_resin", "boss": "thorn_matriarch" },
	{ "id": "boss_solar_tyrant", "title": "Eclipse", "desc": "Defeat the Solar Tyrant", "icon": "gold_ore", "boss": "solar_tyrant" },
	{ "id": "boss_abyss_leviathan", "title": "Abyss Conquered", "desc": "Defeat the Abyss Leviathan", "icon": "silver_ore", "boss": "abyss_leviathan" },
	{ "id": "boss_rot_king", "title": "Cleanse the Bog", "desc": "Defeat the Rot King", "icon": "mushroom", "boss": "rot_king" },
	{ "id": "boss_primal_guardian", "title": "Ancient Falls", "desc": "Defeat the Primal Guardian", "icon": "titanium_ore", "boss": "primal_guardian" },
	{ "id": "boss_all", "title": "World Boss Hunter", "desc": "Defeat every Overworld boss", "icon": "steel_sword", "boss_count": 9 },
	{ "id": "factory_25", "title": "Factory Floor", "desc": "Build a factory with 25 machines", "icon": "basic_machine_casing", "machine_count": 25 },
	{ "id": "factory_100", "title": "Industrial Skyline", "desc": "Build a factory with 100 machines", "icon": "industrial_machine_casing", "machine_count": 100 },
	{ "id": "efficient_grid", "title": "Stable Current", "desc": "Power at least 5 consumers without a deficit", "icon": "copper_wire", "stable_grid": true },
]


# Разблокировано ли достижение у текущего профиля.
static func is_unlocked(id: String) -> bool:
	if SaveManager == null or SaveManager.current_profile == null:
		return false
	return id in SaveManager.current_profile.achievements


# Помечает достижение разблокированным в текущем профиле (без записи на диск).
# Возвращает true, если это первое получение.
static func unlock(id: String) -> bool:
	if SaveManager == null or SaveManager.current_profile == null:
		return false
	if id in SaveManager.current_profile.achievements:
		return false
	SaveManager.current_profile.achievements.append(id)
	var entry := _entry_by_id(id)
	if not entry.is_empty():
		NotificationCenter.push(
			"achievement",
			TranslationServer.translate("Achievement unlocked"),
			TranslationServer.translate(str(entry.get("title", id))),
			"success"
		)
	return true


# Сверяет достижения-эпохи с состоянием QuestBook (QuestManager) и разблокирует
# те эпохи, что уже пройдены. Профиль сохраняется, если что-то изменилось.
# Возвращает true, если появились новые достижения.
static func sync_from_quests() -> bool:
	if SaveManager == null or SaveManager.current_profile == null:
		return false
	var changed := false
	var completed_quests := 0
	for quest: QuestData in QuestManager.get_all_quests():
		if QuestManager.is_completed(quest.quest_id):
			completed_quests += 1
	for entry: Dictionary in LIST:
		var age := int(entry.get("age", 0))
		var quest_count := int(entry.get("quest_count", 0))
		if (age > 0 and QuestManager.is_age_complete(age)) or (quest_count > 0 and completed_quests >= quest_count):
			if unlock(String(entry.get("id", ""))):
				changed = true
	_save_if_changed(changed)
	return changed


static func sync_from_bosses() -> bool:
	if SaveManager.current_save == null or SaveManager.current_profile == null:
		return false
	var defeated := SaveManager.current_save.defeated_bosses
	var changed := false
	for entry: Dictionary in LIST:
		var boss_id := str(entry.get("boss", ""))
		var boss_count := int(entry.get("boss_count", 0))
		if (not boss_id.is_empty() and defeated.has(boss_id)) or (boss_count > 0 and defeated.size() >= boss_count):
			changed = unlock(str(entry.get("id", ""))) or changed
	_save_if_changed(changed)
	return changed


static func sync_from_factory(machine_count: int, stable_grid: bool) -> bool:
	if SaveManager.current_profile == null:
		return false
	var changed := false
	for entry: Dictionary in LIST:
		var required_machines := int(entry.get("machine_count", 0))
		var needs_stable_grid := bool(entry.get("stable_grid", false))
		if (required_machines > 0 and machine_count >= required_machines) or (needs_stable_grid and stable_grid):
			changed = unlock(str(entry.get("id", ""))) or changed
	_save_if_changed(changed)
	return changed


static func _entry_by_id(id: String) -> Dictionary:
	for entry: Dictionary in LIST:
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func _save_if_changed(changed: bool) -> void:
	if changed:
		SaveManager.save_current_profile()
