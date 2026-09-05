extends Node

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 8

# Отдельный порт для UDP-маяков обнаружения серверов в локальной сети.
# ENet не умеет широковещание, поэтому LAN-список строится поверх своего UDP-сокета.
const DISCOVERY_PORT := 7778
const PROTOCOL_VERSION := 1
const BROADCAST_INTERVAL := 1.0   # как часто хост шлёт маяк (сек)
const SERVER_TIMEOUT_MS := 4000   # через сколько мс молчания сервер пропадает из списка

signal server_created
signal join_succeeded
signal join_failed(reason: String)
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal disconnected
# Список LAN-серверов изменился. servers — массив словарей {name, ip, port, players, max}.
signal lan_servers_updated(servers: Array)

# --- Игровая синхронизация (см. секцию GAME SYNC ниже) ---
# Клиент получил описание мира хоста (сид, блоки, время) — можно грузить Game.tscn.
signal world_info_received
# Удалённый игрок вошёл в мир / вышел из него.
signal player_joined(peer_id: int, display_name: String)
signal player_left(peer_id: int, display_name: String)
# Снимок состояния удалённого игрока (позиция/анимация), шлётся каждый тик.
signal player_state_received(peer_id: int, state: Dictionary)
# Удалённый игрок поставил/сломал блок.
signal remote_block_placed(anchor: Vector2i, block_id: String, facing: int)
signal remote_block_removed(anchor: Vector2i)
# Удалённый игрок сделал тик добычи конечного тайла (руда/дерево/куст).
signal remote_ore_mined(global_tile_pos: Vector2i, tool_power: int, tool_type: String)
# Удалённый игрок УДАРИЛ по тайлу: снимаем столько же HP из общего пула тайла,
# чтобы вдвоём тайл выбивался вдвое быстрее, а не «каждый свой» пул.
signal remote_ore_hit(global_tile_pos: Vector2i, damage: float)
# Удалённый игрок выбросил предмет. payload: {id, stack, pos, impulse, delay, wait}.
signal remote_drop_spawned(payload: Dictionary)
# Хост разрешил подбор дропа. claimer_peer_id == 0 — дроп неизвестен хосту,
# все просто убирают свою копию.
signal drop_claimed(net_id: String, claimer_peer_id: int)
# Пришло состояние одной машины/сундука (extra_save_data блока по якорю).
signal remote_machine_state(anchor: Vector2i, extra_data: Dictionary)
signal machine_state_submitted(anchor: Vector2i, extra_data: Dictionary, sender_peer_id: int)
# Периодический снимок состояний всех машин от хоста ({"x,y": {..., extra_data}}).
signal remote_machines_snapshot(blocks: Dictionary)
# Client request validated and applied by the host before the canonical machine
# state is broadcast back to every peer.
signal machine_config_submitted(anchor: Vector2i, config: Dictionary, sender_peer_id: int)
signal factory_progression_received(state: Dictionary)
signal factory_alert_received(alert: Dictionary)
# Сообщение чата от удалённого игрока.
signal chat_received(peer_id: int, text: String)
# Пинг «смотри сюда» (Alt+ЛКМ): метка в мире и на карте. Эмитится и для
# собственных пингов (RPC не вызывает локальный обработчик).
signal map_ping_received(peer_id: int, pos: Vector2)
# Хост сменил погоду (WeatherManager слушает).
signal weather_sync_received(state: int)

var _peer: ENetMultiplayerPeer = null

# --- Ростер сессии ---
# Удалённые игроки, вошедшие в мир: peer_id -> {"name": String}.
# Себя в этот словарь не кладём — свой игрок и так локальный.
var players: Dictionary = {}
# Мы уже "представились" (вошли в игровую сцену и разослали announce).
var _announced := false

# --- Выпавшие предметы ---
# Живые дропы (только у ХОСТА — он арбитр подбора): net_id -> payload спавна.
var _alive_drops: Dictionary = {}
# Счётчик для генерации net_id ("peer_seq") локально выброшенных дропов.
var _drop_seq := 0
# Клиент: дропы, лежавшие в мире до нашего входа (из world info).
# NetSync спавнит их при входе в игровую сцену и очищает список.
var pending_world_drops: Array = []

# --- UPnP (игра через интернет) ---
# Хост при старте пытается автоматически пробросить UDP-порт на роутере.
# Результат: {} = ещё не готов; {ok, ip, port} = финальный статус (его читает
# GameChat при входе в мир — сигнал мог уйти, пока грузилась сцена).
signal upnp_completed(ok: bool, external_ip: String)
var upnp_status: Dictionary = {}
var _upnp: UPNP = null
var _upnp_thread: Thread = null
var _upnp_mapped_port := 0

# --- Пароль / аутентификация ---
# ВНИМАНИЕ: пароль передаётся по ENet открытым текстом — приемлемо только для
# LAN. Перед выходом в интернет/Steam заменить на канал с шифрованием
# (DTLS через server_setup_dtls/client_setup_dtls или Steam networking).
var _host_password := ""      # пароль текущего хоста ("" = открытый сервер)
var _client_password := ""    # пароль, который вводит клиент при подключении
var _session_active := false  # клиент реально подключился (прошёл auth)
var _join_failed_reported := false
# Свой таймаут подключения: ENet может «висеть» дольше, чем готов ждать игрок,
# а меню тем временем выглядит зависшим. Счётчик отсекает устаревшие таймеры.
const JOIN_TIMEOUT := 10.0
var _join_attempt := 0

# --- Переподключение ---
# Параметры последнего join(): после обрыва связи клиент может переподключиться
# к тому же хосту без повторного ввода адреса (см. reconnect()).
# Очищается только осознанным выходом из сессии (disconnect_net).
var _last_join: Dictionary = {}

# --- LAN-обнаружение ---
var _broadcast_socket: PacketPeerUDP = null
var _broadcast_accum := 0.0
var _server_meta := {}                  # {name, port, max} активного хоста
var _listen_socket: PacketPeerUDP = null
var _discovered: Dictionary = {}        # "ip:port" -> {name, ip, port, players, max, last_seen}


func _ready() -> void:
	# Сеть должна жить и на паузе: пауза локальная, а пиры продолжают слать данные.
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Аутентификация по паролю поверх стандартного хендшейка SceneMultiplayer.
	if multiplayer is SceneMultiplayer:
		var sm: SceneMultiplayer = multiplayer
		sm.auth_callback = _on_auth_received
		sm.auth_timeout = 5.0
		sm.peer_authenticating.connect(_on_peer_authenticating)
		sm.peer_authentication_failed.connect(_on_peer_authentication_failed)

	set_process(false)


# ─────────────────────────────────────────────
#  PUBLIC API  (не меняется при переходе на Steam)
# ─────────────────────────────────────────────

func host(port: int = DEFAULT_PORT, max_players: int = MAX_PLAYERS, server_name: String = "", password: String = "") -> void:
	_cleanup_peer()
	_host_password = password.strip_edges()
	_peer = _create_host_peer(port, max_players)
	if _peer == null:
		join_failed.emit("Cannot bind port %d" % port)
		return
	multiplayer.multiplayer_peer = _peer
	_server_meta = {
		"name": _resolve_server_name(server_name),
		"port": port,
		"max": max_players,
		"locked": not _host_password.is_empty(),
	}
	_start_broadcast()
	_start_upnp(port)
	server_created.emit()


func join(ip: String, port: int = DEFAULT_PORT, password: String = "") -> void:
	_cleanup_peer()
	_last_join = {"ip": ip, "port": port, "password": password}
	_client_password = password
	_session_active = false
	_join_failed_reported = false
	_join_attempt += 1
	_peer = _create_client_peer(ip, port)
	if _peer == null:
		join_failed.emit("Cannot connect to %s:%d" % [ip, port])
		return
	multiplayer.multiplayer_peer = _peer

	var attempt := _join_attempt
	get_tree().create_timer(JOIN_TIMEOUT).timeout.connect(
		func() -> void:
			if attempt == _join_attempt and not _session_active:
				_report_join_failed("Connection timed out (%s:%d unreachable)" % [ip, port])
	)


## Есть сохранённые параметры прошлого подключения — reconnect() имеет смысл.
func can_reconnect() -> bool:
	return not _last_join.is_empty()


## Повторяет последнее клиентское подключение (после обрыва связи).
## Результат придёт теми же сигналами, что и у join(): join_succeeded /
## join_failed, затем world_info_received.
func reconnect() -> void:
	if _last_join.is_empty():
		join_failed.emit("No previous connection to retry")
		return
	join(str(_last_join["ip"]), int(_last_join["port"]), str(_last_join["password"]))


func disconnect_net() -> void:
	_last_join = {}
	_join_attempt += 1  # гасит отложенный таймер подключения
	_stop_broadcast()
	_stop_upnp()
	_cleanup_peer()
	multiplayer.multiplayer_peer = null
	_session_active = false
	_host_password = ""
	players.clear()
	_announced = false
	_alive_drops.clear()
	pending_world_drops.clear()


func is_server() -> bool:
	return multiplayer.is_server()


func my_peer_id() -> int:
	return multiplayer.get_unique_id()


## Сессия реально активна (хост поднят или клиент подключён).
## Без сети multiplayer_peer — OfflineMultiplayerPeer, его считаем неактивным.
func is_active() -> bool:
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Мы — клиент чужого мира (не хост). Клиент никогда не пишет сейвы на диск.
func is_client() -> bool:
	return is_active() and not multiplayer.is_server()


## RTT до хоста в миллисекундах (имеет смысл только у клиента).
## -1 — сессии нет или статистика ещё недоступна.
func get_ping_ms() -> int:
	if not is_client() or _peer == null:
		return -1
	var host_peer: ENetPacketPeer = _peer.get_peer(1)
	if host_peer == null:
		return -1
	return int(host_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))


func local_display_name() -> String:
	if SaveManager and SaveManager.current_profile:
		var profile_name := String(SaveManager.current_profile.profile_name)
		if not profile_name.is_empty():
			return profile_name
	return "Player %d" % my_peer_id()


func peer_display_name(peer_id: int) -> String:
	var info: Variant = players.get(peer_id)
	if info is Dictionary:
		return str(info.get("name", "Player %d" % peer_id))
	return "Player %d" % peer_id


# ─────────────────────────────────────────────
#  TRANSPORT LAYER
#  Для перехода на Steam SDK: заменить тела
#  _create_host_peer / _create_client_peer на
#  SteamMultiplayerPeer.create_host() / .create_client().
#  Всё выше этой черты остаётся без изменений.
# ─────────────────────────────────────────────

func _create_host_peer(port: int, max_players: int) -> ENetMultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(port, max_players) != OK:
		return null
	return peer


func _create_client_peer(ip: String, port: int) -> ENetMultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip, port) != OK:
		return null
	return peer


func _cleanup_peer() -> void:
	if _peer != null:
		_peer.close()
		_peer = null


# ─────────────────────────────────────────────
#  ВНУТРЕННИЕ ОБРАБОТЧИКИ
# ─────────────────────────────────────────────

func _on_peer_connected(peer_id: int) -> void:
	player_connected.emit(peer_id)
	# Хост высылает новичку мир (сид/блоки/время), чтобы тот сгенерировал такой же.
	if multiplayer.is_server():
		_send_world_info(peer_id)
	# Если мы уже в мире — представляемся новичку адресно (он нашего
	# широковещательного announce не застал).
	if _announced:
		_rpc_announce.rpc_id(peer_id, local_display_name())


func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		var display_name := peer_display_name(peer_id)
		players.erase(peer_id)
		player_left.emit(peer_id, display_name)
	player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	_session_active = true
	join_succeeded.emit()


func _on_connection_failed() -> void:
	_report_join_failed("Connection timed out")


func _on_server_disconnected() -> void:
	_stop_broadcast()
	players.clear()
	_announced = false
	_alive_drops.clear()
	pending_world_drops.clear()
	if _session_active:
		_session_active = false
		_cleanup_peer()
		multiplayer.multiplayer_peer = null
		disconnected.emit()
	else:
		# Соединение оборвалось ещё на этапе аутентификации — почти всегда неверный пароль.
		_report_join_failed("Wrong password or rejected by host")


func _report_join_failed(reason: String) -> void:
	if _join_failed_reported:
		return
	_join_failed_reported = true
	_cleanup_peer()
	multiplayer.multiplayer_peer = null
	join_failed.emit(reason)


# ─────────────────────────────────────────────
#  АУТЕНТИФИКАЦИЯ ПО ПАРОЛЮ
# ─────────────────────────────────────────────

func _on_peer_authenticating(id: int) -> void:
	var sm: SceneMultiplayer = multiplayer
	if multiplayer.is_server():
		# Сервер ждёт пароль клиента — он придёт в _on_auth_received.
		return
	# Клиент отправляет свой пароль серверу и доверяет серверу без проверки.
	sm.send_auth(id, _client_password.to_utf8_buffer())
	sm.complete_auth(id)


func _on_auth_received(id: int, data: PackedByteArray) -> void:
	if not multiplayer.is_server():
		return  # клиенту проверять нечего
	var sm: SceneMultiplayer = multiplayer
	var given := data.get_string_from_utf8()
	if given == _host_password:
		sm.complete_auth(id)
	elif multiplayer.multiplayer_peer != null:
		# Неверный пароль — мгновенно отклоняем подключение.
		multiplayer.multiplayer_peer.disconnect_peer(id)


func _on_peer_authentication_failed(_id: int) -> void:
	if not multiplayer.is_server():
		_report_join_failed("Wrong password or rejected by host")


# ─────────────────────────────────────────────
#  ОБНАРУЖЕНИЕ СЕРВЕРОВ В ЛОКАЛЬНОЙ СЕТИ (LAN)
#  Хост раз в секунду шлёт UDP-маяк; клиент в меню
#  слушает их и строит список доступных миров.
# ─────────────────────────────────────────────

# Вызывается меню при входе во вкладку "Join", чтобы начать собирать список серверов.
func start_browsing() -> void:
	_stop_listen()
	_discovered.clear()
	_listen_socket = PacketPeerUDP.new()
	_listen_socket.set_broadcast_enabled(true)
	if _listen_socket.bind(DISCOVERY_PORT, "*") != OK:
		# Порт занят (например, второй браузер на этой же машине) — список будет пуст.
		_listen_socket = null
	_update_process_state()
	lan_servers_updated.emit(get_server_list())


func stop_browsing() -> void:
	_stop_listen()
	_discovered.clear()
	_update_process_state()


func get_server_list() -> Array:
	var list: Array = []
	for key: String in _discovered:
		list.append(_discovered[key])
	list.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return list


func _process(delta: float) -> void:
	if _broadcast_socket != null:
		_broadcast_accum += delta
		if _broadcast_accum >= BROADCAST_INTERVAL:
			_broadcast_accum = 0.0
			_send_beacon()

	if _listen_socket != null:
		_poll_listen()
		_expire_servers()


func _start_broadcast() -> void:
	_stop_broadcast()
	_broadcast_socket = PacketPeerUDP.new()
	_broadcast_socket.set_broadcast_enabled(true)
	_broadcast_accum = BROADCAST_INTERVAL  # отправить первый маяк сразу
	_update_process_state()


func _stop_broadcast() -> void:
	if _broadcast_socket != null:
		_broadcast_socket.close()
		_broadcast_socket = null
	_server_meta = {}
	_update_process_state()


func _stop_listen() -> void:
	if _listen_socket != null:
		_listen_socket.close()
		_listen_socket = null


func _update_process_state() -> void:
	set_process(_broadcast_socket != null or _listen_socket != null)


func _send_beacon() -> void:
	var info := {
		"name": _server_meta.get("name", "InfiniteForge Server"),
		"port": _server_meta.get("port", DEFAULT_PORT),
		"players": _player_count(),
		"max": _server_meta.get("max", MAX_PLAYERS),
		"locked": _server_meta.get("locked", false),
		"ver": PROTOCOL_VERSION,
	}
	var payload := JSON.stringify(info).to_utf8_buffer()
	# Шлём и широковещательно (вся LAN), и на loopback (хост + клиент на одной машине).
	_broadcast_socket.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	_broadcast_socket.put_packet(payload)
	_broadcast_socket.set_dest_address("127.0.0.1", DISCOVERY_PORT)
	_broadcast_socket.put_packet(payload)


func _poll_listen() -> void:
	var changed := false
	while _listen_socket.get_available_packet_count() > 0:
		var bytes := _listen_socket.get_packet()
		var ip := _listen_socket.get_packet_ip()
		var data: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if typeof(data) != TYPE_DICTIONARY:
			continue
		if int(data.get("ver", -1)) != PROTOCOL_VERSION:
			continue
		var port := int(data.get("port", DEFAULT_PORT))
		var key := "%s:%d" % [ip, port]
		_discovered[key] = {
			"name": str(data.get("name", "InfiniteForge Server")),
			"ip": ip,
			"port": port,
			"players": int(data.get("players", 0)),
			"max": int(data.get("max", MAX_PLAYERS)),
			"locked": bool(data.get("locked", false)),
			"last_seen": Time.get_ticks_msec(),
		}
		changed = true
	if changed:
		lan_servers_updated.emit(get_server_list())


func _expire_servers() -> void:
	var now := Time.get_ticks_msec()
	var stale: Array = []
	for key: String in _discovered:
		if now - int(_discovered[key]["last_seen"]) > SERVER_TIMEOUT_MS:
			stale.append(key)
	if stale.is_empty():
		return
	for key: String in stale:
		_discovered.erase(key)
	lan_servers_updated.emit(get_server_list())


func _player_count() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1
	if multiplayer.is_server():
		return multiplayer.get_peers().size() + 1
	return 1


# ─────────────────────────────────────────────
#  UPnP: АВТОПРОБРОС ПОРТА ДЛЯ ИГРЫ ЧЕРЕЗ ИНТЕРНЕТ
#  discover() блокирует на секунды — только в отдельном потоке.
# ─────────────────────────────────────────────

func _start_upnp(port: int) -> void:
	if _upnp_thread != null:
		return  # предыдущая попытка ещё не завершилась
	upnp_status = {}
	_upnp_thread = Thread.new()
	_upnp_thread.start(_upnp_worker.bind(port))


func _upnp_worker(port: int) -> void:
	var upnp := UPNP.new()
	var ok := false
	var ip := ""
	if upnp.discover() == UPNP.UPNP_RESULT_SUCCESS \
			and upnp.get_gateway() != null and upnp.get_gateway().is_valid_gateway():
		# ENet работает по UDP — его и пробрасываем.
		ok = upnp.add_port_mapping(port, port, "InfinityForge", "UDP") == UPNP.UPNP_RESULT_SUCCESS
		if ok:
			ip = upnp.query_external_address()
	call_deferred("_on_upnp_done", ok, ip, port, upnp)


func _on_upnp_done(ok: bool, ip: String, port: int, upnp: UPNP) -> void:
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	if ok:
		_upnp = upnp
		_upnp_mapped_port = port
	upnp_status = {"ok": ok, "ip": ip, "port": port}
	upnp_completed.emit(ok, ip)


## Убирает проброс при закрытии сервера (лучшее усилие — ошибки игнорируем).
func _stop_upnp() -> void:
	if _upnp != null and _upnp_mapped_port > 0:
		_upnp.delete_port_mapping(_upnp_mapped_port, "UDP")
	_upnp = null
	_upnp_mapped_port = 0
	upnp_status = {}


func _resolve_server_name(server_name: String) -> String:
	var trimmed := server_name.strip_edges()
	if not trimmed.is_empty():
		return trimmed
	# Падаем назад на имя текущего мира, затем на имя профиля.
	if SaveManager and SaveManager.current_world and not String(SaveManager.current_world.world_name).is_empty():
		return SaveManager.current_world.world_name
	if SaveManager and SaveManager.current_profile:
		return "%s's World" % SaveManager.current_profile.profile_name
	return "InfiniteForge Server"


# ─────────────────────────────────────────────
#  GAME SYNC
#  Все игровые RPC ходят через этот автолоад: он существует на обоих
#  концах с одинаковым путём, поэтому не зависит от имён нод в сцене.
#  Игровая сцена (NetSync) подписывается на сигналы выше.
# ─────────────────────────────────────────────

# --- Передача мира клиенту -------------------------------------------------

## Хост: собирает снимок мира для нового пира. Сид + настройки генерации дают
## клиенту идентичный процедурный мир; placed_blocks/chunk_changes — то, что
## игроки уже изменили.
func _send_world_info(peer_id: int) -> void:
	var world: WorldData = SaveManager.current_world
	if world == null:
		return
	# Пакуем живое состояние мира, если хост уже в игре.
	var world_node: Variant = get_tree().get_first_node_in_group("world")
	if world_node and world_node.has_method("pack_runtime_world_state"):
		world_node.pack_runtime_world_state()
	if world_node and world_node.has_method("pack_chunk_changes"):
		for chunk_pos: Vector2i in world.loaded_chunks:
			world_node.pack_chunk_changes(world.loaded_chunks[chunk_pos])
	TechnologyTree.refresh_unlocks()
	var save := SaveManager.current_save
	var info := {
		"seed": world.world_seed,
		"name": world.world_name,
		"difficulty": world.difficulty,
		"resource_richness": world.resource_richness,
		"vegetation_density": world.vegetation_density,
		"resource_distribution": world.resource_distribution,
		"placed_blocks": world.saved_placed_blocks,
		"chunk_changes": world.saved_chunk_changes,
		"minutes": TimeManager.minutes,
		"weather": WeatherManager.state,
		"drops": _alive_drops.values(),
		"discovered_biomes": world.discovered_biomes,
		"researched_technologies": Array(save.researched_technologies) if save != null else [],
		"defeated_bosses": Array(save.defeated_bosses) if save != null else [],
		"unlocked_recipes": Array(save.unlocked_recipes) if save != null else [],
		"permanent_biome_access": Array(save.permanent_biome_access) if save != null else [],
	}
	_rpc_world_info.rpc_id(peer_id, info)


@rpc("authority", "call_remote", "reliable")
func _rpc_world_info(info: Dictionary) -> void:
	# Клиент: строим временный WorldData хоста. file_path пустой — этот мир
	# существует только в памяти и никогда не пишется на диск (см. is_client()).
	var world := WorldData.new()
	world.world_name = str(info.get("name", "Host World"))
	world.world_seed = str(info.get("seed", "0"))
	world.difficulty = str(info.get("difficulty", "Normal"))
	world.resource_richness = str(info.get("resource_richness", "Normal"))
	world.vegetation_density = str(info.get("vegetation_density", "Normal"))
	world.resource_distribution = str(info.get("resource_distribution", "Balanced"))
	var discovered_value: Variant = info.get("discovered_biomes", {})
	if discovered_value is Dictionary:
		world.discovered_biomes = (discovered_value as Dictionary).duplicate(true)
	var placed: Variant = info.get("placed_blocks", {})
	if placed is Dictionary:
		world.saved_placed_blocks = placed
	var changes: Variant = info.get("chunk_changes", {})
	if changes is Dictionary:
		world.saved_chunk_changes = changes
	world.file_path = ""
	SaveManager.current_world = world
	SaveManager.is_remote_session = true

	# Временный сейв-слот в памяти: пустые инвентари, спавн на базе.
	var save := WorldSaveData.new()
	save.world_id = ""
	SaveManager._ensure_save_inventories(save)
	SaveManager.current_save = save
	SaveManager.current_slot_name = ""
	for technology: Variant in info.get("researched_technologies", []):
		save.researched_technologies.append(str(technology))
	for boss_id: Variant in info.get("defeated_bosses", []):
		save.defeated_bosses.append(str(boss_id))
	for recipe_id: Variant in info.get("unlocked_recipes", []):
		save.unlocked_recipes.append(str(recipe_id))
	for access_id: Variant in info.get("permanent_biome_access", []):
		save.permanent_biome_access.append(str(access_id))

	var drops: Variant = info.get("drops", [])
	pending_world_drops = drops if drops is Array else []

	TimeManager.minutes = float(info.get("minutes", TimeManager.minutes))
	WeatherManager.apply_net_state(int(info.get("weather", 0)))
	# Свой (клиентский) прогресс квестов для этого мира хоста — из файла,
	# ключованного именем+сидом мира (см. QuestManager._save_path).
	QuestManager.reload_progress()
	world_info_received.emit()


# --- Ростер игроков --------------------------------------------------------

## Зовётся игровой сценой (NetSync), когда локальный игрок вошёл в мир.
func announce_self() -> void:
	if not is_active():
		return
	_announced = true
	_rpc_announce.rpc(local_display_name())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_announce(display_name: String) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	var is_new := not players.has(peer_id)
	players[peer_id] = {"name": display_name}
	if is_new:
		player_joined.emit(peer_id, display_name)


# --- Состояние игрока (позиция/анимация) -----------------------------------

func send_player_state(state: Dictionary) -> void:
	if is_active() and _announced:
		_rpc_player_state.rpc(state)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_player_state(state: Dictionary) -> void:
	player_state_received.emit(multiplayer.get_remote_sender_id(), state)


# --- Блоки -----------------------------------------------------------------

func broadcast_block_placed(anchor: Vector2i, block_id: String, facing: int) -> void:
	if is_active():
		_rpc_block_placed.rpc(anchor, block_id, facing)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_block_placed(anchor: Vector2i, block_id: String, facing: int) -> void:
	remote_block_placed.emit(anchor, block_id, facing)


func broadcast_block_removed(anchor: Vector2i) -> void:
	if is_active():
		_rpc_block_removed.rpc(anchor)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_block_removed(anchor: Vector2i) -> void:
	remote_block_removed.emit(anchor)


# --- Добыча ----------------------------------------------------------------

func broadcast_ore_mined(global_tile_pos: Vector2i, tool_power: int, tool_type: String) -> void:
	if is_active():
		_rpc_ore_mined.rpc(global_tile_pos, tool_power, tool_type)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_ore_mined(global_tile_pos: Vector2i, tool_power: int, tool_type: String) -> void:
	remote_ore_mined.emit(global_tile_pos, tool_power, tool_type)


## Один удар по тайлу (без выдачи ресурса — её шлёт broadcast_ore_mined).
## Unreliable: пропущенный удар лишь чуть рассинхронит полоску, а ударов много.
func broadcast_ore_hit(global_tile_pos: Vector2i, damage: float) -> void:
	if is_active():
		_rpc_ore_hit.rpc(global_tile_pos, damage)


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_ore_hit(global_tile_pos: Vector2i, damage: float) -> void:
	remote_ore_hit.emit(global_tile_pos, damage)


# --- Выпавшие предметы -----------------------------------------------------
# Спавн рассылается всем; подбор — через арбитраж ХОСТА: кто первым дотянулся,
# тому claim, остальные убирают копию. Так предмет нельзя поднять дважды.

## Стек для передачи по сети: без полей-объектов (texture/resource) — их
## пересоберёт stack_from_net по id на принимающей стороне.
func stack_to_net(stack: Dictionary) -> Dictionary:
	var plain := stack.duplicate(true)
	plain.erase("texture")
	plain.erase("resource")
	return plain


## Восстанавливает полный стек: база из ItemDatabase по id, поверх — все
## переданные поля (count, fluid_id, кастомные имена и т.п.).
func stack_from_net(plain: Dictionary) -> Dictionary:
	var stack: Dictionary = ItemDatabase.create_existing_stack(
		str(plain.get("id", "")), int(plain.get("count", 1))
	)
	if stack.is_empty():
		return {}
	for key: Variant in plain:
		stack[key] = plain[key]
	return stack


## Регистрирует локально выброшенный дроп и рассылает его. Возвращает net_id
## (пустая строка вне сессии — дроп остаётся чисто локальным).
func broadcast_drop_spawned(
	stack: Dictionary,
	pos: Vector2,
	impulse: Vector2,
	pickup_delay: float,
	wait_for_player_to_leave: bool
) -> String:
	if not is_active():
		return ""
	var net_id := "%d_%d" % [my_peer_id(), _drop_seq]
	_drop_seq += 1
	var payload := {
		"id": net_id,
		"stack": stack_to_net(stack),
		"pos": pos,
		"impulse": impulse,
		"delay": pickup_delay,
		"wait": wait_for_player_to_leave,
	}
	if multiplayer.is_server():
		_alive_drops[net_id] = payload
	_rpc_drop_spawned.rpc(payload)
	return net_id


@rpc("any_peer", "call_remote", "reliable")
func _rpc_drop_spawned(payload: Dictionary) -> void:
	if multiplayer.is_server():
		_alive_drops[str(payload.get("id", ""))] = payload
	remote_drop_spawned.emit(payload)


## Просьба поднять дроп. Ответ придёт сигналом drop_claimed (нам или сопернику).
func request_drop_pickup(net_id: String) -> void:
	if not is_active():
		return
	if multiplayer.is_server():
		_grant_drop(net_id, 1)
	else:
		_rpc_request_drop_pickup.rpc_id(1, net_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_drop_pickup(net_id: String) -> void:
	if multiplayer.is_server():
		_grant_drop(net_id, multiplayer.get_remote_sender_id())


## Хост: отдаёт дроп первому попросившему. Неизвестный id (уже поднят или
## потерян) — claim с claimer 0, чтобы у всех вычистились осиротевшие копии.
func _grant_drop(net_id: String, claimer_peer_id: int) -> void:
	if not _alive_drops.has(net_id):
		claimer_peer_id = 0
	_alive_drops.erase(net_id)
	_rpc_drop_claimed.rpc(net_id, claimer_peer_id)
	drop_claimed.emit(net_id, claimer_peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_drop_claimed(net_id: String, claimer_peer_id: int) -> void:
	drop_claimed.emit(net_id, claimer_peer_id)


# --- Машины и сундуки ------------------------------------------------------
# Состояние машин уже сериализуется в плоские словари для сейвов
# (get_extra_save_data / load_extra_save_data) — их и гоняем по сети.
# Два потока данных: точечный (пока игрок держит меню машины открытым) и
# периодический снимок ВСЕХ машин от хоста, который гасит дрейф автономной
# симуляции (печи/дрели тикают у каждого пира сами).

## Рекурсивно чистит словарь сейва для сети: значения-объекты (текстуры,
## ресурсы предметов) не сериализуются ENet'ом и выбрасываются.
func data_to_net(value: Variant) -> Variant:
	if value is Dictionary:
		var out: Dictionary = {}
		for key: Variant in value:
			var entry: Variant = value[key]
			if entry is Object:
				continue
			out[key] = data_to_net(entry)
		return out
	if value is Array:
		var arr: Array = []
		for entry: Variant in value:
			arr.append(null if entry is Object else data_to_net(entry))
		return arr
	return value


## Обратная операция: словари-стеки предметов (по ключу "id") пересобираются
## через ItemDatabase, чтобы вернуть текстуры/ресурсы, вычищенные data_to_net.
func data_from_net(value: Variant) -> Variant:
	if value is Dictionary:
		var out: Dictionary = {}
		for key: Variant in value:
			out[key] = data_from_net(value[key])
		var item_id := str(out.get("id", ""))
		if not item_id.is_empty() and out.has("count") and ItemDatabase.registry.has(item_id):
			return stack_from_net(out)
		return out
	if value is Array:
		var arr: Array = []
		for entry: Variant in value:
			arr.append(data_from_net(entry))
		return arr
	return value


func broadcast_machine_state(anchor: Vector2i, extra_data: Dictionary) -> void:
	if not is_active() or extra_data.is_empty():
		return
	var net_data := data_to_net(extra_data) as Dictionary
	if multiplayer.is_server():
		_rpc_machine_state.rpc(anchor, net_data)
	else:
		_rpc_submit_machine_state.rpc_id(1, anchor, net_data)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_machine_state(anchor: Vector2i, extra_data: Dictionary) -> void:
	if multiplayer.is_server():
		machine_state_submitted.emit(anchor, data_from_net(extra_data), multiplayer.get_remote_sender_id())


func submit_machine_config(anchor: Vector2i, config: Dictionary) -> void:
	if not is_active() or config.is_empty():
		return
	var net_config := data_to_net(config) as Dictionary
	if multiplayer.is_server():
		machine_config_submitted.emit(anchor, net_config, my_peer_id())
	else:
		_rpc_submit_machine_config.rpc_id(1, anchor, net_config)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_machine_config(anchor: Vector2i, config: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	machine_config_submitted.emit(anchor, data_from_net(config), multiplayer.get_remote_sender_id())


@rpc("authority", "call_remote", "reliable")
func _rpc_machine_state(anchor: Vector2i, extra_data: Dictionary) -> void:
	remote_machine_state.emit(anchor, data_from_net(extra_data))


## Клиент при открытии меню машины просит у хоста её свежее состояние:
## локальная копия могла разойтись из-за автономной симуляции.
func request_machine_state(anchor: Vector2i) -> void:
	if is_client():
		_rpc_request_machine_state.rpc_id(1, anchor)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_machine_state(anchor: Vector2i) -> void:
	if not multiplayer.is_server():
		return
	var wim: Variant = get_tree().get_first_node_in_group("world_interaction")
	if wim == null or not wim.has_method("get_block_at"):
		return
	var block: Variant = wim.get_block_at(anchor)
	if block is WorldBlock:
		var extra: Dictionary = (block as WorldBlock).get_extra_save_data()
		if not extra.is_empty():
			_rpc_machine_state.rpc_id(
				multiplayer.get_remote_sender_id(), anchor, data_to_net(extra)
			)


## Хост: периодический снимок всех машин (формат serialize_placed_blocks).
func broadcast_machines_snapshot(blocks: Dictionary) -> void:
	if is_active() and multiplayer.is_server() and not blocks.is_empty():
		_rpc_machines_snapshot.rpc(data_to_net(blocks))


@rpc("authority", "call_remote", "reliable")
func _rpc_machines_snapshot(blocks: Dictionary) -> void:
	remote_machines_snapshot.emit(data_from_net(blocks))


func broadcast_factory_progression(state: Dictionary) -> void:
	if is_active() and multiplayer.is_server():
		_rpc_factory_progression.rpc(data_to_net(state))


@rpc("authority", "call_remote", "reliable")
func _rpc_factory_progression(state: Dictionary) -> void:
	factory_progression_received.emit(data_from_net(state))


func broadcast_factory_alert(alert: Dictionary) -> void:
	if is_active() and multiplayer.is_server() and not alert.is_empty():
		_rpc_factory_alert.rpc(data_to_net(alert))


@rpc("authority", "call_remote", "reliable")
func _rpc_factory_alert(alert: Dictionary) -> void:
	factory_alert_received.emit(data_from_net(alert))


# --- Пинги на карте --------------------------------------------------------

## Ставит метку «смотри сюда» в мировой точке pos и рассылает её тиммейтам.
## Работает и без сессии — своя метка видна всегда.
func send_map_ping(pos: Vector2) -> void:
	map_ping_received.emit(my_peer_id(), pos)
	if is_active():
		_rpc_map_ping.rpc(pos)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_map_ping(pos: Vector2) -> void:
	map_ping_received.emit(multiplayer.get_remote_sender_id(), pos)


# --- Погода ----------------------------------------------------------------

## Хост рассылает смену погоды. Клиенты применяют через weather_sync_received.
func broadcast_weather(state: int) -> void:
	if is_active() and multiplayer.is_server():
		_rpc_weather.rpc(state)


@rpc("authority", "call_remote", "reliable")
func _rpc_weather(state: int) -> void:
	weather_sync_received.emit(state)


# --- Чат -------------------------------------------------------------------

func send_chat(text: String) -> void:
	if is_active():
		_rpc_chat.rpc(text)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_chat(text: String) -> void:
	chat_received.emit(multiplayer.get_remote_sender_id(), text)
