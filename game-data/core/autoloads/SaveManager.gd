# res://core/autoloads/SaveManager.gd
extends Node

const PROFILES_DIR := "user://profiles/"
const WORLDS_DIR := "user://worlds/"
const SAVES_DIR := "user://saves/"
const SETTINGS_PATH := "user://settings.cfg"
# Избранное храним отдельным лёгким файлом, чтобы не перезаписывать
# тяжёлые .tres миров (могут весить мегабайты) ради одной звёздочки.
const FAVORITES_PATH := "user://favorites.cfg"

# Суффиксы атомарной записи: сначала пишем в *.tmp.tres, затем подменяем
# оригинал (rename), а прошлую версию держим рядом как *.bak.
# Расширение .tres у временного файла обязательно — ResourceSaver выбирает
# формат по расширению.
const TMP_SUFFIX := ".tmp.tres"
const BAK_SUFFIX := ".bak"
# Сколько поколений резервных копий держим рядом с файлом:
# .bak (свежая), .bak2, .bak3 (самая старая). Ротация — при каждой записи.
const BAK_GENERATIONS := 3
const MAX_NOTIFICATION_LOG_ENTRIES := 120

# Текущая версия формата сохранений. Повышается на 1 при каждом несовместимом
# изменении структуры сейва/мира; на загрузке старые файлы прогоняются через
# цепочку миграций (см. _migrate_save / _migrate_world).
const SAVE_VERSION := 5

# Размеры инвентарей игрока. Единственное место, где они задаются.
# 36 = 4 строки по 9: 2 боевые (мешок) + 2 строительные. Хотбар — «окно» на
# одну из этих строк и собственного хранилища не имеет.
const PLAYER_INVENTORY_SIZE := 36
# Легаси: раньше хотбар был отдельным хранилищем. Слот-данные из старых
# quickbar-сейвов переносятся в инвентарь при загрузке (HotbarUI.from_save_data).
const QUICKBAR_SIZE := 0
const ARMOR_SIZE := 8

var current_profile: ProfileData = null
var current_world: WorldData = null
var current_save: WorldSaveData = null
var settings: Dictionary = {}
var current_slot_name: String = ""

# Текущая сессия — чужой мир, пришедший по сети (мы клиент мультиплеера).
# Отдельный флаг, а не MultiplayerManager.is_client(): при выходе из игры сеть
# может закрыться РАНЬШЕ автосейва мира, и без флага клиент записал бы чужой
# мир себе на диск. Сбрасывается только стартом новой локальной сессии.
var is_remote_session := false

# Сообщается всем подписчикам (HUD, камера и т.п.) после каждого применения настроек,
# чтобы они могли перечитать актуальные значения (например, показ FPS или зум).
signal settings_applied(settings: Dictionary)

# Запись на диск не удалась (нет места, файл заблокирован и т.п.).
# UI должен показать игроку предупреждение — прогресс не сохраняется.
signal save_failed(path: String, error: int)

# Игра успешно сохранена (вручную или автосейвом) — HUD показывает «Сохранено».
signal game_saved

var _autosave_timer: Timer = null

# Снимок стандартных привязок из project.godot (action -> Array[InputEvent]),
# чтобы сброс/переприменение всегда восстанавливали дефолт перед оверрайдами.
var _default_action_events: Dictionary = {}


func _ready() -> void:
	ensure_directories()
	_snapshot_default_keybinds() # Запоминаем стандартные привязки ДО применения оверрайдов
	load_last_profile()
	load_settings()
	apply_settings() # Применяем сохранённые настройки сразу при запуске игры
	_setup_autosave_timer() # Запускаем фоновый таймер автосохранения


# ============================================
# ИЗБРАННОЕ (миры / персонажи)
# ============================================

func is_world_favorite(world_key: String) -> bool:
	return _fav_get("worlds", world_key)

func set_world_favorite(world_key: String, value: bool) -> void:
	_fav_set("worlds", world_key, value)

func is_profile_favorite(profile_id: String) -> bool:
	return _fav_get("profiles", profile_id)

func set_profile_favorite(profile_id: String, value: bool) -> void:
	_fav_set("profiles", profile_id, value)

# Кеш файла избранного: UI-списки дёргают is_*_favorite на каждый элемент,
# читать ConfigFile с диска каждый раз незачем.
var _fav_cache: ConfigFile = null

func _fav_config() -> ConfigFile:
	if _fav_cache == null:
		_fav_cache = ConfigFile.new()
		_fav_cache.load(FAVORITES_PATH) # если файла нет — просто пусто
	return _fav_cache

func _fav_get(section: String, key: String) -> bool:
	if key.is_empty():
		return false
	return bool(_fav_config().get_value(section, key.sha256_text(), false))

func _fav_set(section: String, key: String, value: bool) -> void:
	if key.is_empty():
		return
	var cfg := _fav_config()
	var safe_key := key.sha256_text() # хэшируем: ключ может содержать пути/юникод
	if value:
		cfg.set_value(section, safe_key, true)
	elif cfg.has_section(section) and cfg.has_section_key(section, safe_key):
		cfg.erase_section_key(section, safe_key)
	cfg.save(FAVORITES_PATH)


func ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute(PROFILES_DIR)
	DirAccess.make_dir_recursive_absolute(WORLDS_DIR)
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	_cleanup_temp_files()


# Убираем остатки прерванной атомарной записи (крах между записью tmp и rename).
func _cleanup_temp_files() -> void:
	for dir_path: String in [PROFILES_DIR, WORLDS_DIR, SAVES_DIR]:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		for file_name in dir.get_files():
			if file_name.ends_with(TMP_SUFFIX):
				dir.remove(file_name)


# ============================================
# АТОМАРНАЯ ЗАПИСЬ / БЕЗОПАСНАЯ ЗАГРУЗКА
# ============================================

## Пишет ресурс атомарно: tmp-файл -> rename поверх оригинала, прошлые версии
## остаются как .bak/.bak2/.bak3 (ротация поколений). Крах посреди записи не
## портит существующее сохранение.
## Возвращает false (и эмитит save_failed), если записать не удалось.
func save_resource_safe(resource: Resource, path: String) -> bool:
	var tmp_path := path.get_basename() + TMP_SUFFIX
	var err := ResourceSaver.save(resource, tmp_path)
	if err != OK:
		push_error("SaveManager: не удалось записать '%s' (ошибка %d)" % [path, err])
		DirAccess.remove_absolute(tmp_path)
		save_failed.emit(path, err)
		return false
	if FileAccess.file_exists(path):
		_rotate_backups(path)
		DirAccess.rename_absolute(path, _bak_path(path, 1))
	err = DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		push_error("SaveManager: не удалось подменить '%s' (ошибка %d)" % [path, err])
		save_failed.emit(path, err)
		return false
	return true


## Путь резервной копии данного поколения: 1 -> ".bak", 2 -> ".bak2", ...
func _bak_path(path: String, generation: int) -> String:
	return path + BAK_SUFFIX + ("" if generation == 1 else str(generation))


## Сдвигает поколения бэкапов на шаг назад (.bak2 -> .bak3, .bak -> .bak2),
## освобождая место под свежую копию. Самое старое поколение удаляется.
func _rotate_backups(path: String) -> void:
	DirAccess.remove_absolute(_bak_path(path, BAK_GENERATIONS))
	for gen in range(BAK_GENERATIONS - 1, 0, -1):
		if FileAccess.file_exists(_bak_path(path, gen)):
			DirAccess.rename_absolute(_bak_path(path, gen), _bak_path(path, gen + 1))


## Загружает ресурс, не роняя игру на битом файле. Если основной файл
## повреждён или отсутствует — пытается восстановиться из резервных копий
## от свежей к старой (битый файл сохраняется рядом как .corrupt для
## диагностики). Возвращает null, если не удалось загрузить ни основной
## файл, ни одну из копий.
func load_resource_safe(path: String) -> Resource:
	if FileAccess.file_exists(path):
		var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if res != null:
			return res
		push_error("SaveManager: файл повреждён: '%s'" % path)
		DirAccess.remove_absolute(path + ".corrupt")
		DirAccess.rename_absolute(path, path + ".corrupt")
	for gen in range(1, BAK_GENERATIONS + 1):
		var bak_path := _bak_path(path, gen)
		if not FileAccess.file_exists(bak_path):
			continue
		if DirAccess.copy_absolute(bak_path, path) != OK:
			continue
		var restored: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if restored != null:
			push_warning("SaveManager: '%s' восстановлен из резервной копии №%d." % [path, gen])
			return restored
	return null


## Удаляет файл сохранения вместе со служебными копиями (.bak*/.corrupt),
## иначе load_resource_safe «воскресит» удалённый файл из бэкапа.
func delete_resource_file(path: String) -> void:
	DirAccess.remove_absolute(path)
	for gen in range(1, BAK_GENERATIONS + 1):
		DirAccess.remove_absolute(_bak_path(path, gen))
	DirAccess.remove_absolute(path + ".corrupt")


# ============================================
# НАСТРОЙКИ (SETTINGS)
# ============================================

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		# Стартуем от дефолтов, чтобы у старых конфигов появились новые ключи
		set_default_settings_dict()
		var saved_has_display_mode := false
		for key in config.get_section_keys("settings"):
			settings[key] = config.get_value("settings", key)
			if key == "display_mode":
				saved_has_display_mode = true
		_migrate_settings(saved_has_display_mode)
	else:
		set_default_settings()


func _migrate_settings(saved_has_display_mode: bool) -> void:
	# Старые сохранения хранили булев "fullscreen" вместо "display_mode"
	if settings.has("fullscreen") and not saved_has_display_mode:
		settings["display_mode"] = DISPLAY_MODE_FULLSCREEN if settings["fullscreen"] else DISPLAY_MODE_WINDOWED
	settings.erase("fullscreen")


func save_settings_to_file() -> void:
	var config := ConfigFile.new()
	for key: String in settings:
		config.set_value("settings", key, settings[key])
	config.save(SETTINGS_PATH)


## Serialises only player preferences, never save-game or profile data.
func export_settings_json() -> String:
	return JSON.stringify({"format": "InfiniteForgeSettings", "version": 1, "settings": settings}, "  ")


## Imports known settings from a clipboard/file JSON payload and applies them immediately.
func import_settings_json(payload: String) -> bool:
	var json := JSON.new()
	if json.parse(payload) != OK or not (json.data is Dictionary):
		return false
	var root := json.data as Dictionary
	var imported_value: Variant = root.get("settings", root)
	if not (imported_value is Dictionary):
		return false
	var imported := imported_value as Dictionary
	set_default_settings_dict()
	var merged := settings.duplicate(true)
	for key: String in imported:
		if merged.has(key):
			merged[key] = imported[key]
	settings = merged
	_migrate_settings(settings.has("display_mode"))
	apply_settings()
	save_settings_to_file()
	return true


# Возможные режимы окна. Значения совпадают с индексами в выпадающем списке настроек.
const DISPLAY_MODE_WINDOWED := 0
const DISPLAY_MODE_BORDERLESS := 1
const DISPLAY_MODE_FULLSCREEN := 2


func set_default_settings_dict() -> void:
	settings = {
		# Видео
		"display_mode": DISPLAY_MODE_FULLSCREEN,
		"resolution": "1920x1080",
		"vsync": true,
		"max_fps": 0,        # 0 = без ограничения
		# Звук
		"master_volume": 80.0,
		"music_volume": 70.0,
		"sfx_volume": 85.0,
		# Геймплей
		"show_fps": false,
		"autosave_minutes": 5,
		# Язык интерфейса ("en" / "ru"). См. LocalizationManager.LANGUAGES
		"language": "en",
		# Пользовательские привязки клавиш: { action: {"t": "key", "code": <int>} }.
		# Пустой словарь = стандартные привязки из project.godot.
		"keybinds": {},
	}


func set_default_settings() -> void:
	set_default_settings_dict()
	save_settings_to_file()


func get_setting(key: String, default_value: Variant = null) -> Variant:
	return settings.get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	save_settings_to_file()


func reset_settings() -> void:
	set_default_settings()
	apply_settings()


func apply_settings() -> void:
	_apply_display_mode()

	if settings.get("vsync", true):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Ограничение кадров (0 = без лимита)
	Engine.max_fps = int(settings.get("max_fps", 0))

	_apply_volume("Master", "master_volume", 80.0)
	_apply_volume("Music", "music_volume", 70.0)
	_apply_volume("SFX", "sfx_volume", 85.0)

	# Обновляем интервал автосохранения на лету
	_apply_autosave_interval()

	# Применяем пользовательские привязки клавиш
	_apply_keybinds()

	settings_applied.emit(settings)


## Applies one changed preference without re-applying the display mode for
## unrelated settings. Re-setting the window mode can blank the swapchain for
## a frame, which made every click in the settings menu look like a flash.
func apply_setting(key: String) -> void:
	match key:
		"display_mode":
			_apply_display_mode()
		"resolution":
			# Resolution only controls a regular window. Borderless/fullscreen use
			# the screen size and must not be recreated for this preference.
			if int(settings.get("display_mode", DISPLAY_MODE_FULLSCREEN)) == DISPLAY_MODE_WINDOWED:
				_apply_windowed_size()
		"vsync":
			if settings.get("vsync", true):
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"max_fps":
			Engine.max_fps = int(settings.get("max_fps", 0))
		"master_volume":
			_apply_volume("Master", "master_volume", 80.0)
		"music_volume":
			_apply_volume("Music", "music_volume", 70.0)
		"sfx_volume":
			_apply_volume("SFX", "sfx_volume", 85.0)
		"autosave_minutes":
			_apply_autosave_interval()
		"keybinds":
			_apply_keybinds()

	# Some preferences (show_fps, language) are applied by listeners/UI, so the
	# notification is intentionally emitted even when no manager action is needed.
	settings_applied.emit(settings)


## Переключение полноэкранного режима (F11). Гоняет между «Оконный» и
## «Полный экран», сохраняет выбор и уведомляет меню настроек.
func toggle_fullscreen() -> void:
	var cur := int(settings.get("display_mode", DISPLAY_MODE_FULLSCREEN))
	var new_mode := DISPLAY_MODE_WINDOWED if cur == DISPLAY_MODE_FULLSCREEN else DISPLAY_MODE_FULLSCREEN
	settings["display_mode"] = new_mode
	_apply_display_mode()
	save_settings_to_file()
	settings_applied.emit(settings)


func _apply_display_mode() -> void:
	var mode := int(settings.get("display_mode", DISPLAY_MODE_FULLSCREEN))
	# Локальный тест мультиплеера: с флагом --windowed (или -w) окно
	# принудительно оконное, чтобы два экземпляра игры поместились на экране.
	var args := OS.get_cmdline_args()
	if args.has("--windowed") or args.has("-w"):
		mode = DISPLAY_MODE_WINDOWED
	match mode:
		DISPLAY_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			_apply_windowed_size()
		DISPLAY_MODE_BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(DisplayServer.screen_get_size())
			DisplayServer.window_set_position(Vector2i.ZERO)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _apply_windowed_size() -> void:
	var res: String = settings.get("resolution", "1920x1080")
	var parts := res.split("x")
	if parts.size() != 2:
		return
	var size := Vector2i(int(parts[0]), int(parts[1]))
	# Окно не может быть больше монитора, на котором оно находится
	var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	size.x = mini(size.x, screen.x)
	size.y = mini(size.y, screen.y)
	DisplayServer.window_set_size(size)
	# Центрируем окно по экрану (целочисленное деление координат — намеренно)
	@warning_ignore("integer_division")
	DisplayServer.window_set_position((screen - size) / 2)


func _apply_volume(bus_name: String, key: String, default_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var linear := float(settings.get(key, default_value)) / 100.0
	AudioServer.set_bus_mute(idx, linear <= 0.0)
	AudioServer.set_bus_volume_db(idx, maxf(linear_to_db(linear), -80.0))


func _apply_autosave_interval() -> void:
	if _autosave_timer == null:
		return
	var minutes := int(settings.get("autosave_minutes", 5))
	if minutes <= 0:
		_autosave_timer.stop()
	else:
		_autosave_timer.wait_time = minutes * 60.0
		if _autosave_timer.is_stopped():
			_autosave_timer.start()


# ============================================
# ПРИВЯЗКИ КЛАВИШ
# ============================================

func _snapshot_default_keybinds() -> void:
	# Только пользовательские (не встроенные "ui_*") действия можно менять,
	# но снимок делаем со всех — восстановление дефолта безопасно для любого.
	_default_action_events.clear()
	for action: StringName in InputMap.get_actions():
		var events: Array = []
		for ev: InputEvent in InputMap.action_get_events(action):
			events.append(ev)
		_default_action_events[action] = events


func _apply_keybinds() -> void:
	if _default_action_events.is_empty():
		return

	# Сначала откатываем всё к стандартным привязкам (идемпотентно),
	# затем накатываем пользовательские оверрайды поверх.
	for action: StringName in _default_action_events:
		InputMap.action_erase_events(action)
		for ev: InputEvent in _default_action_events[action]:
			InputMap.action_add_event(action, ev)

	var binds: Dictionary = settings.get("keybinds", {})
	for action: String in binds:
		if not InputMap.has_action(action):
			continue
		var data: Variant = binds[action]
		if typeof(data) == TYPE_DICTIONARY:
			var slots := data as Dictionary
			if slots.has("keyboard") or slots.has("mouse") or slots.has("gamepad"):
				if slots.has("keyboard"):
					_apply_binding_slot(action, "keyboard", slots["keyboard"])
				if slots.has("gamepad"):
					_apply_binding_slot(action, "gamepad", slots["gamepad"])
				# Старые настройки могли содержать отдельную колонку мыши.
				if slots.has("mouse"):
					_apply_binding_slot(action, "mouse", slots["mouse"])
				continue
		var kind := ""
		if typeof(data) == TYPE_DICTIONARY:
			kind = String((data as Dictionary).get("t", ""))
		# "none" — клавиша намеренно снята (её забрало другое действие):
		# стираем клавиатуру/мышь и НИЧЕГО не добавляем.
		if kind == "none":
			_erase_kbm_events(action)
			continue
		var ev := _deserialize_event(data)
		if ev == null:
			continue
		# Оверрайд заменяет только клавиатуру/мышь — геймпадные привязки
		# из project.godot остаются рядом с пользовательской клавишей.
		_erase_kbm_events(action)
		InputMap.action_add_event(action, ev)


func _apply_binding_slot(action: String, device: String, data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and String((data as Dictionary).get("t", "")) == "none":
		_erase_binding_device(action, device)
		return
	var event := _deserialize_event(data)
	if event == null:
		return
	_erase_binding_device(action, device)
	if device == "keyboard" and event is InputEventKey:
		InputMap.action_add_event(action, event)
	elif device == "mouse" and event is InputEventMouseButton:
		InputMap.action_add_event(action, event)
	elif device == "gamepad" and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		InputMap.action_add_event(action, event)


func _erase_binding_device(action: StringName, device: String) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if device == "keyboard" and event is InputEventKey:
			InputMap.action_erase_event(action, event)
		elif device == "mouse" and event is InputEventMouseButton:
			InputMap.action_erase_event(action, event)
		elif device == "gamepad" and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			InputMap.action_erase_event(action, event)


## Стирает у действия только клавиатурные/мышиные события; геймпад остаётся.
func _erase_kbm_events(action: StringName) -> void:
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey or ev is InputEventMouseButton:
			InputMap.action_erase_event(action, ev)


func _deserialize_event(data: Variant) -> InputEvent:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	match String(data.get("t", "")):
		"key":
			var ev := InputEventKey.new()
			ev.physical_keycode = int(data.get("code", 0)) as Key
			ev.ctrl_pressed = bool(data.get("ctrl", false))
			ev.alt_pressed = bool(data.get("alt", false))
			ev.shift_pressed = bool(data.get("shift", false))
			ev.meta_pressed = bool(data.get("meta", false))
			return ev
		"mb":
			var ev := InputEventMouseButton.new()
			ev.button_index = int(data.get("idx", 1)) as MouseButton
			ev.ctrl_pressed = bool(data.get("ctrl", false))
			ev.alt_pressed = bool(data.get("alt", false))
			ev.shift_pressed = bool(data.get("shift", false))
			ev.meta_pressed = bool(data.get("meta", false))
			return ev
		"jb":
			var ev := InputEventJoypadButton.new()
			ev.button_index = int(data.get("idx", 0)) as JoyButton
			return ev
		"jm":
			var ev := InputEventJoypadMotion.new()
			ev.axis = int(data.get("axis", 0)) as JoyAxis
			ev.axis_value = 1.0 if float(data.get("value", 1.0)) > 0.0 else -1.0
			return ev
	return null


# ============================================
# УПРАВЛЕНИЕ ПРОФИЛЯМИ
# ============================================

func create_profile(profile_name: String, skin_id: String = "default") -> ProfileData:
	var profile := ProfileData.new()
	profile.profile_name = profile_name
	profile.skin_id = skin_id
	
	var path := PROFILES_DIR + profile.profile_id + ".tres"
	save_resource_safe(profile, path)

	current_profile = profile
	save_last_profile()
	return profile


func save_current_profile() -> bool:
	# Пересохраняет текущий профиль (например, после разблокировки достижения)
	if current_profile == null:
		return false
	return save_resource_safe(current_profile, PROFILES_DIR + current_profile.profile_id + ".tres")


func load_profile(profile_id: String) -> ProfileData:
	var path := PROFILES_DIR + profile_id + ".tres"
	var profile := load_resource_safe(path) as ProfileData
	if profile == null:
		return null
	current_profile = profile
	save_last_profile()
	return profile


func get_all_profiles() -> Array[ProfileData]:
	var profiles: Array[ProfileData] = []
	for file_name in _list_save_files(PROFILES_DIR):
		var profile := load_resource_safe(PROFILES_DIR + file_name) as ProfileData
		if profile:
			profiles.append(profile)
	return profiles


# Имена .tres-файлов каталога без служебных (tmp-остатки атомарной записи).
func _list_save_files(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if file_name.ends_with(".tres") and not file_name.ends_with(TMP_SUFFIX):
			result.append(file_name)
	return result


func save_last_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("last", "profile_id", current_profile.profile_id if current_profile else "")
	config.save("user://last_profile.cfg")


func load_last_profile() -> void:
	var config := ConfigFile.new()
	if config.load("user://last_profile.cfg") == OK:
		var profile_id: String = config.get_value("last", "profile_id", "")
		if not profile_id.is_empty():
			current_profile = load_profile(profile_id)


# ============================================
# УПРАВЛЕНИЕ МИРАМИ
# ============================================

func create_world(world_name: String, world_seed: int = 0) -> WorldData:
	var world := WorldData.new()
	world.save_version = SAVE_VERSION
	world.world_name = world_name
	world.world_seed = str(randi()) if world_seed == 0 else str(world_seed)
	world.created_at = Time.get_unix_time_from_system()
	
	var safe_name := world_name.validate_filename()
	world.file_path = WORLDS_DIR + safe_name + "_world.tres"

	save_resource_safe(world, world.file_path)
	return world


func load_world(world_id_or_path: String) -> WorldData:
	var path := world_id_or_path
	if not path.contains("://"):
		path = WORLDS_DIR + world_id_or_path + "_world.tres"

	var world := load_resource_safe(path) as WorldData
	if world != null:
		_migrate_world(world)
		return world

	# Backwards compatibility: old saves stored world_name instead of file path
	for file_name in _list_save_files(WORLDS_DIR):
		var candidate := load_resource_safe(WORLDS_DIR + file_name) as WorldData
		if candidate and (candidate.world_name == world_id_or_path or file_name.get_basename() == world_id_or_path):
			_migrate_world(candidate)
			return candidate
	return null


func get_all_worlds() -> Array[WorldData]:
	var worlds: Array[WorldData] = []
	for file_name in _list_save_files(WORLDS_DIR):
		var world := load_resource_safe(WORLDS_DIR + file_name) as WorldData
		if world:
			worlds.append(world)
	return worlds


# ============================================
# ВЕРСИОНИРОВАНИЕ СЕЙВОВ И МИГРАЦИИ
# ============================================
# Файлы, записанные до появления версионирования, читаются как версия 0 и
# проходят всю цепочку. Каждый шаг поднимает версию ровно на 1 — при
# несовместимом изменении формата добавляйте новый case в match и повышайте
# SAVE_VERSION.

## Приводит сейв к текущей версии формата (безопасно звать повторно).
func _migrate_save(save: WorldSaveData) -> void:
	while save.save_version < SAVE_VERSION:
		match save.save_version:
			0:
				# v0 -> v1: сейвы без номера версии. Недостающие инвентари и
				# устаревшие размеры чинит _ensure_save_inventories.
				_ensure_save_inventories(save)
			1:
				# v1 -> v2: журнал, технологии и боссы получили строгую нормализацию.
				_normalize_progress_state(save)
			2:
				# v2 -> v3: постоянные рецепты боссов и расходуемые пропуски в биомы.
				_normalize_progress_state(save)
			3:
				_normalize_progress_state(save)
			4:
				_normalize_progress_state(save)
		save.save_version += 1
	# Нормализация нужна и актуальным сейвам: размеры инвентарей могли
	# поменяться константами без смены версии формата.
	_ensure_save_inventories(save)
	_normalize_progress_state(save)


func _normalize_progress_state(save: WorldSaveData) -> void:
	save.player_hunger = clampf(save.player_hunger, 0.0, 100.0)
	save.world_age_minutes = maxf(save.world_age_minutes, 0.0)
	save.research_progress = maxf(save.research_progress, 0.0)
	save.researched_technologies = _unique_non_empty_strings(save.researched_technologies)
	save.completed_research = _unique_non_empty_strings(save.completed_research)
	save.defeated_bosses = _unique_non_empty_strings(save.defeated_bosses)
	save.unlocked_recipes = _unique_non_empty_strings(save.unlocked_recipes)
	save.permanent_biome_access = _unique_non_empty_strings(save.permanent_biome_access)
	if not (save.progression_telemetry is Dictionary):
		save.progression_telemetry = {}

	var normalized_log: Array[Dictionary] = []
	for source: Dictionary in save.notification_log:
		var title := str(source.get("title", "")).strip_edges()
		var message := str(source.get("message", "")).strip_edges()
		if title.is_empty() and message.is_empty():
			continue
		normalized_log.append({
			"category": str(source.get("category", "progress")).strip_edges(),
			"title": title,
			"message": message,
			"severity": str(source.get("severity", "info")).strip_edges(),
			"timestamp": maxi(int(source.get("timestamp", 0)), 0),
			"count": maxi(int(source.get("count", 1)), 1),
		})
		if normalized_log.size() >= MAX_NOTIFICATION_LOG_ENTRIES:
			break
	save.notification_log = normalized_log


func _unique_non_empty_strings(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value: String in values:
		var normalized := value.strip_edges()
		if not normalized.is_empty() and not result.has(normalized):
			result.append(normalized)
	return result


## Приводит данные мира к текущей версии формата.
func _migrate_world(world: WorldData) -> void:
	while world.save_version < SAVE_VERSION:
		match world.save_version:
			0:
				pass  # v0 -> v1: структура мира не менялась, только штамп версии
		world.save_version += 1


# ============================================
# УПРАВЛЕНИЕ СОХРАНЕНИЯМИ (АВТОМАТИЧЕСКОЕ)
# ============================================

# Создаёт недостающие инвентари и приводит их размеры к актуальным константам
# (у старых сейвов могли быть другие размеры или null-поля).
func _ensure_save_inventories(save: WorldSaveData) -> void:
	if save.player_inventory == null:
		save.player_inventory = InventorySaveData.new()
	if save.quickbar == null:
		save.quickbar = InventorySaveData.new()
	if save.armor == null:
		save.armor = InventorySaveData.new()
	save.player_inventory.size = PLAYER_INVENTORY_SIZE
	save.quickbar.size = QUICKBAR_SIZE
	save.armor.size = ARMOR_SIZE


func create_save(slot_name: String, profile: ProfileData, world: WorldData, player_position: Vector2) -> WorldSaveData:
	var save := WorldSaveData.new()
	save.save_version = SAVE_VERSION
	save.profile_id = profile.profile_id
	save.world_id = world.file_path if not world.file_path.is_empty() else slot_name
	save.player_position = player_position

	_ensure_save_inventories(save)

	var path := SAVES_DIR + slot_name + ".tres"
	save_resource_safe(save, path)

	current_save = save
	current_slot_name = slot_name
	current_profile = profile
	current_world = world
	return save


func get_save_slot_name(world: WorldData) -> String:
	return world.world_name.validate_filename() + "_save"


func start_game_session(profile: ProfileData, world: WorldData) -> void:
	if profile == null or world == null:
		push_error("SaveManager.start_game_session: profile or world is null")
		return

	# Reload the world straight from disk, bypassing Godot's resource cache, so a
	# new session never reuses a stale in-memory WorldData (old runtime chunks or
	# the previous world after a name reuse) — that was the "same world" bug.
	if not world.file_path.is_empty() and ResourceLoader.exists(world.file_path):
		var fresh := ResourceLoader.load(
			world.file_path, "", ResourceLoader.CACHE_MODE_REPLACE
		) as WorldData
		if fresh != null:
			world = fresh
	_migrate_world(world)
	world.loaded_chunks = {}

	current_profile = profile
	current_world = world
	is_remote_session = false
	save_last_profile()

	current_slot_name = get_save_slot_name(world)
	var save_path := SAVES_DIR + current_slot_name + ".tres"

	current_save = load_resource_safe(save_path) as WorldSaveData
	if current_save != null:
		_migrate_save(current_save)
	else:
		# Файла нет, либо и основной, и .bak повреждены — начинаем слот заново.
		if FileAccess.file_exists(save_path):
			push_warning("SaveManager: сейв '%s' не читается, слот пересоздан." % current_slot_name)
		create_save(current_slot_name, profile, world, Vector2.ZERO)

	# Прогресс квестов лежит в отдельном файле на слот — перечитываем под
	# новую сессию (автолоад QuestManager живёт весь запуск приложения).
	QuestManager.reload_progress()


## Сохраняет текущую сессию. Возвращает false, если хотя бы одна запись
## на диск не удалась (подписчики save_failed уже уведомлены).
func save_game() -> bool:
	# Клиент мультиплеера играет в чужом (пришедшем по сети) мире — на диск
	# ничего не пишем, иначе затрём собственные сейвы временными данными.
	if is_remote_session:
		return true

	_sync_inventory_from_ui()

	if current_save == null or current_slot_name.is_empty():
		# Нормальный путь сюда не попадает (start_game_session всегда создаёт
		# сейв) — это подстраховка для запуска сцены напрямую из редактора (F6).
		push_warning("SaveManager.save_game: нет активной сессии, создаю debug-слот.")
		current_slot_name = "auto_debug_save"

		if current_profile == null:
			current_profile = ProfileData.new()
			current_profile.profile_name = "DebugPlayer"
			save_resource_safe(current_profile, PROFILES_DIR + "debug_player.tres")

		if current_world == null:
			current_world = WorldData.new()
			current_world.world_name = "DebugWorld"
			current_world.file_path = WORLDS_DIR + "auto_debug_save_world.tres"
			save_resource_safe(current_world, current_world.file_path)

		current_save = WorldSaveData.new()
		current_save.world_id = current_world.file_path
		_ensure_save_inventories(current_save)

	# Принудительно пакуем активные чанки перед сохранением.
	# Variant: методы мира зовутся динамически через has_method.
	var world_node: Variant = get_tree().get_first_node_in_group("world")
	if not world_node:
		world_node = get_tree().root.find_child("World", true, false)

	if world_node and world_node.has_method("pack_runtime_world_state"):
		world_node.pack_runtime_world_state()
		
	if world_node and world_node.has_method("pack_chunk_changes") and current_world:
		for chunk_pos: Vector2i in current_world.loaded_chunks:
			world_node.pack_chunk_changes(current_world.loaded_chunks[chunk_pos])

	# 1. Запись данных игрока
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		current_save.player_position = player.global_position
		if player.has_method("get_hunger"):
			current_save.player_hunger = player.get_hunger()
	current_save.world_age_minutes = TimeManager.world_age_minutes
	current_save.saved_at = Time.get_unix_time_from_system()
	current_save.save_version = SAVE_VERSION

	var save_path := SAVES_DIR + current_slot_name + ".tres"
	var ok := save_resource_safe(current_save, save_path)
	if current_profile:
		ok = save_current_profile() and ok

	if current_world:
		current_world.save_version = SAVE_VERSION
		var world_path: String = current_world.file_path
		if world_path.is_empty():
			world_path = WORLDS_DIR + current_slot_name + "_world.tres"
			current_world.file_path = world_path
		ok = save_resource_safe(current_world, world_path) and ok
	if ok:
		game_saved.emit()
	return ok


func load_save(slot_name: String) -> WorldSaveData:
	var path := SAVES_DIR + slot_name + ".tres"
	var save := load_resource_safe(path) as WorldSaveData
	if save == null:
		return null
	_migrate_save(save)
	current_profile = load_profile(save.profile_id)
	current_world = load_world(save.world_id)
	current_save = save
	current_slot_name = slot_name
	return save


func get_all_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for file_name in _list_save_files(SAVES_DIR):
		var save := load_resource_safe(SAVES_DIR + file_name) as WorldSaveData
		if save:
			var profile := load_profile(save.profile_id)
			var world := load_world(save.world_id)
			saves.append({
				"slot_name": file_name.replace(".tres", ""),
				"save": save,
				"profile": profile,
				"world": world
			})
	return saves


# Инициализация фонового таймера автосохранения
func _setup_autosave_timer() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.name = "AutosaveTimer"
	var minutes := int(settings.get("autosave_minutes", 5))
	_autosave_timer.wait_time = maxf(minutes, 1) * 60.0
	_autosave_timer.autostart = minutes > 0
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _on_autosave_timeout() -> void:
	# Проверяем, что игрок в мире и идет игровой процесс
	if current_save and current_world and not current_slot_name.is_empty():
		# Variant: map_system — динамическое свойство узла мира.
		var world_node: Variant = get_tree().get_first_node_in_group("world")
		if not world_node:
			world_node = get_tree().root.find_child("World", true, false)
			
		if world_node and world_node.map_system and world_node.map_system.has_method("save_current_map"):
			world_node.map_system.save_current_map(current_world)
			
		save_game()


func apply_profile_to_player(player_node: Node2D) -> void:
	if current_profile == null:
		return
	if player_node.has_method("set_skin"):
		player_node.set_skin(current_profile.skin_id, current_profile.skin_color)
	if player_node.has_method("set_armor_color"):
		player_node.set_armor_color(current_profile.armor_color)


func _sync_inventory_from_ui() -> void:
	if current_save == null:
		return
	var tree := get_tree()
	if tree == null:
		return

	# Variant: UI-ноды дёргаются динамически (has_method / to_save_data).
	var inv_ui: Variant = tree.get_first_node_in_group("inventory_ui")
	var hotbar_ui: Variant = tree.get_first_node_in_group("hotbar_ui")
	var chest_ui: Variant = tree.get_first_node_in_group("chest_ui")
	if chest_ui and chest_ui.visible and chest_ui.has_method("return_held_item"):
		chest_ui.return_held_item()
	_return_held_item_to_inventory(inv_ui, hotbar_ui)
	if inv_ui and inv_ui.has_method("to_save_data"):
		current_save.player_inventory = inv_ui.to_save_data()
	if hotbar_ui and hotbar_ui.has_method("to_save_data"):
		current_save.quickbar = hotbar_ui.to_save_data()
	var armor_ui: Variant = tree.get_first_node_in_group("armor_ui")
	if armor_ui and armor_ui.has_method("to_save_data"):
		current_save.armor = armor_ui.to_save_data()


func _return_held_item_to_inventory(inv_ui: Node, hotbar_ui: Node) -> void:
	if InventorySlot.held_item == null or not (InventorySlot.held_item is Dictionary):
		return

	var remaining: Variant = InventorySlot.held_item.duplicate(true)
	if inv_ui and inv_ui.has_method("auto_insert_item"):
		remaining = inv_ui.auto_insert_item(remaining)
		if remaining == null or int(remaining.get("count", 0)) <= 0:
			InventorySlot.clear_held_item_static()
			return

	if hotbar_ui and hotbar_ui.has_method("auto_insert_item"):
		remaining = hotbar_ui.auto_insert_item(remaining)
		if remaining == null or int(remaining.get("count", 0)) <= 0:
			InventorySlot.clear_held_item_static()
			return

	InventorySlot.held_item = remaining
	InventorySlot._update_held_preview_static()
