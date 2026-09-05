extends Node
class_name LogisticsNetworkManager

const ALERT_SCAN_INTERVAL := 2.0
const ALERT_PERSIST_SECONDS := 8.0
const ALERT_COOLDOWN_SECONDS := 120.0

var _overlay: LogisticsNetworkOverlay = null
var _alert_scan_timer := 0.0
var _critical_problem_first_seen: Dictionary = {}
var _active_alert_groups: Dictionary = {}
var _last_alert_at: Dictionary = {}


func _ready() -> void:
	# Логистическая диагностика больше не рисуется поверх игрового мира.
	set_process(false)


func _process(delta: float) -> void:
	_alert_scan_timer -= delta
	if _alert_scan_timer > 0.0:
		return
	_alert_scan_timer = ALERT_SCAN_INTERVAL
	_evaluate_critical_alerts(get_network_snapshot(), _now_seconds())


func get_network_snapshot() -> Dictionary:
	var snapshot := {
		"requesters": 0,
		"providers": 0,
		"routes": [],
		"requester_tiles": [],
		"provider_tiles": [],
		"blocked_tiles": [],
		"missing_total": 0,
		"in_transit_total": 0,
		"supply_total": 0,
		"blocked_routes": 0,
		"priority_waits": 0,
		"shortages": {},
		"supply": {},
		"request_entries": [],
		"problems": [],
	}
	var request_targets_seen := {}
	for node: Node in get_tree().get_nodes_in_group("world_block"):
		var block := node as WorldBlock
		if block == null or not is_instance_valid(block):
			continue
		_collect_block_requests(block, snapshot, request_targets_seen)
		_collect_block_provider(block, snapshot)
		_collect_route(block, snapshot)
		_collect_blockage(block, snapshot)
	_finalize_snapshot(snapshot)
	return snapshot


func _collect_block_requests(
		block: WorldBlock,
		snapshot: Dictionary,
		request_targets_seen: Dictionary
) -> void:
	var context: Dictionary = {}
	if block.chest_inventory != null:
		context = block.chest_inventory.ingredient_request_context()
	elif block.machine != null and not (block.machine is ConveyorContainer) \
			and block.machine.has_method("ingredient_request_context"):
		var context_value: Variant = block.machine.ingredient_request_context()
		if context_value is Dictionary:
			context = context_value as Dictionary
	if not bool(context.get("active", false)):
		return
	snapshot["requesters"] = int(snapshot["requesters"]) + 1
	(snapshot["requester_tiles"] as Array).append(block.center_tile())
	var requests := context.get("requests", {}) as Dictionary
	var reserved := context.get("reserved", {}) as Dictionary
	var allocations := context.get("allocations", {}) as Dictionary
	for item_value: Variant in allocations:
		var item_id := str(item_value)
		var entries: Array = allocations[item_value] if allocations[item_value] is Array else []
		for entry_value: Variant in entries:
			if not entry_value is Dictionary:
				continue
			var target_key := str((entry_value as Dictionary).get("key", ""))
			var unique_key := "%s|%s" % [target_key, item_id]
			if target_key.is_empty() or request_targets_seen.has(unique_key):
				continue
			request_targets_seen[unique_key] = true
			var missing := maxi(int(requests.get(item_id, 0)), 0)
			var in_transit := maxi(int(reserved.get(item_id, 0)), 0)
			_add_metric(snapshot["shortages"] as Dictionary, item_id, "missing", missing)
			_add_metric(snapshot["shortages"] as Dictionary, item_id, "in_transit", in_transit)
			snapshot["missing_total"] = int(snapshot["missing_total"]) + missing
			snapshot["in_transit_total"] = int(snapshot["in_transit_total"]) + in_transit
			(snapshot["request_entries"] as Array).append({
				"kind": "shortage",
				"tile": block.center_tile(),
				"item_id": item_id,
				"missing": missing,
				"in_transit": in_transit,
				"severity": 1,
			})


func _collect_block_provider(block: WorldBlock, snapshot: Dictionary) -> void:
	if block.chest_inventory == null or block.chest_inventory.data == null:
		return
	var chest := block.chest_inventory
	var data := chest.data
	data.ensure_logistics_rule_capacity()
	var active := false
	var item_ids := {}
	for rule: Dictionary in data.provider_rules:
		if not bool(rule.get("enabled", false)):
			continue
		active = true
		var item_id := str(rule.get("item_id", ""))
		if not item_id.is_empty():
			item_ids[item_id] = true
	if not active:
		return
	for slot_value: Variant in data.inventory_slots:
		if slot_value is Dictionary:
			var stored_item_id := str((slot_value as Dictionary).get("id", ""))
			if not stored_item_id.is_empty() and chest.provider_allows_item(stored_item_id):
				item_ids[stored_item_id] = true
	snapshot["providers"] = int(snapshot["providers"]) + 1
	(snapshot["provider_tiles"] as Array).append(block.center_tile())
	for item_value: Variant in item_ids:
		var item_id := str(item_value)
		var available := chest.supply_available(item_id)
		_add_metric(snapshot["supply"] as Dictionary, item_id, "available", available)
		snapshot["supply_total"] = int(snapshot["supply_total"]) + available


func _collect_route(block: WorldBlock, snapshot: Dictionary) -> void:
	if not (block.machine is ConveyorContainer):
		return
	var conveyor := block.machine as ConveyorContainer
	var context := conveyor.ingredient_request_context()
	if not bool(context.get("active", false)):
		return
	(snapshot["routes"] as Array).append({
		"tile": block.center_tile(),
		"facing": conveyor.facing,
		"missing": _dictionary_total(context.get("requests", {}) as Dictionary),
		"in_transit": int(context.get("reserved_total", 0)),
		"jammed": conveyor.jammed,
	})


func _collect_blockage(block: WorldBlock, snapshot: Dictionary) -> void:
	var blocked := false
	if block.machine is ConveyorContainer:
		blocked = (block.machine as ConveyorContainer).jammed
	elif block.machine is MechanicalInserterContainer:
		var inserter := block.machine as MechanicalInserterContainer
		if inserter.provider_deferred:
			snapshot["priority_waits"] = int(snapshot["priority_waits"]) + 1
			(snapshot["problems"] as Array).append({
				"kind": "priority_wait",
				"tile": block.center_tile(),
				"severity": 1,
			})
		blocked = inserter.status_key == "Destination blocked"
	if not blocked:
		return
	snapshot["blocked_routes"] = int(snapshot["blocked_routes"]) + 1
	(snapshot["blocked_tiles"] as Array).append(block.center_tile())
	(snapshot["problems"] as Array).append({
		"kind": "conveyor_jam" if block.machine is ConveyorContainer else "inserter_blocked",
		"tile": block.center_tile(),
		"severity": 3,
	})


func _finalize_snapshot(snapshot: Dictionary) -> void:
	var shortages: Array[Dictionary] = []
	var supply := snapshot["supply"] as Dictionary
	for item_value: Variant in (snapshot["shortages"] as Dictionary):
		var item_id := str(item_value)
		var entry := (snapshot["shortages"] as Dictionary)[item_value] as Dictionary
		shortages.append({
			"item_id": item_id,
			"missing": int(entry.get("missing", 0)),
			"in_transit": int(entry.get("in_transit", 0)),
			"supply": int((supply.get(item_id, {}) as Dictionary).get("available", 0)),
		})
	shortages.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_missing := int(first.get("missing", 0))
		var second_missing := int(second.get("missing", 0))
		return str(first.get("item_id", "")) < str(second.get("item_id", "")) \
			if first_missing == second_missing else first_missing > second_missing
	)
	snapshot["shortages"] = shortages
	snapshot["uncovered_types"] = 0
	for entry: Dictionary in shortages:
		if int(entry.get("missing", 0)) > 0 and int(entry.get("supply", 0)) <= 0:
			snapshot["uncovered_types"] = int(snapshot["uncovered_types"]) + 1
	for request_value: Variant in snapshot["request_entries"]:
		if not request_value is Dictionary:
			continue
		var request := (request_value as Dictionary).duplicate(true)
		if int(request.get("missing", 0)) <= 0:
			continue
		var item_id := str(request.get("item_id", ""))
		var available_supply := int((supply.get(item_id, {}) as Dictionary).get("available", 0))
		request["supply"] = available_supply
		if available_supply <= 0:
			request["kind"] = "uncovered_shortage"
			request["severity"] = 2
		(snapshot["problems"] as Array).append(request)
	(snapshot["problems"] as Array).sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_severity := int(first.get("severity", 0))
		var second_severity := int(second.get("severity", 0))
		if first_severity != second_severity:
			return first_severity > second_severity
		var first_tile := first.get("tile", Vector2i.ZERO) as Vector2i
		var second_tile := second.get("tile", Vector2i.ZERO) as Vector2i
		return first_tile.x < second_tile.x if first_tile.x != second_tile.x \
			else first_tile.y < second_tile.y
	)
	snapshot.erase("request_entries")


func _add_metric(values: Dictionary, item_id: String, key: String, amount: int) -> void:
	var entry := values.get(item_id, {}) as Dictionary
	entry[key] = int(entry.get(key, 0)) + maxi(amount, 0)
	values[item_id] = entry


func _dictionary_total(values: Dictionary) -> int:
	var result := 0
	for value: Variant in values.values():
		result += int(value)
	return result


func _evaluate_critical_alerts(snapshot: Dictionary, now: float) -> void:
	var groups := {
		"blockages": [],
		"uncovered_supply": [],
	}
	var active_keys := {}
	for problem_value: Variant in snapshot.get("problems", []):
		if not problem_value is Dictionary:
			continue
		var problem := problem_value as Dictionary
		var group := _critical_group(problem)
		if group.is_empty():
			continue
		var key := _problem_key(problem)
		active_keys[key] = true
		(groups[group] as Array).append(problem)
		if not _critical_problem_first_seen.has(key):
			_critical_problem_first_seen[key] = now
	for key_value: Variant in _critical_problem_first_seen.keys():
		if not active_keys.has(key_value):
			_critical_problem_first_seen.erase(key_value)
	NotificationCenter.resolve_action_entries("open_logistics_problem", active_keys)
	for group_value: Variant in groups:
		var group := str(group_value)
		var matured: Array[Dictionary] = []
		for problem_value: Variant in groups[group]:
			var problem := problem_value as Dictionary
			var first_seen := float(_critical_problem_first_seen.get(_problem_key(problem), now))
			if now - first_seen >= ALERT_PERSIST_SECONDS:
				matured.append(problem)
		if matured.is_empty():
			_active_alert_groups.erase(group)
			continue
		if bool(_active_alert_groups.get(group, false)):
			continue
		if now - float(_last_alert_at.get(group, -ALERT_COOLDOWN_SECONDS)) < ALERT_COOLDOWN_SECONDS:
			continue
		_push_critical_alert(group, matured)
		_active_alert_groups[group] = true
		_last_alert_at[group] = now


func _critical_group(problem: Dictionary) -> String:
	match str(problem.get("kind", "")):
		"conveyor_jam", "inserter_blocked":
			return "blockages"
		"uncovered_shortage":
			return "uncovered_supply"
	return ""


func _push_critical_alert(group: String, problems: Array[Dictionary]) -> void:
	var problem_keys: Array[String] = []
	for problem: Dictionary in problems:
		problem_keys.append(_problem_key(problem))
	if group == "blockages":
		NotificationCenter.push(
			"factory",
			tr("Logistics blockage"),
			tr("Blocked logistics machines: %d. Press L and use [ / ] to inspect.") % problems.size(),
			"danger",
			{
				"type": "open_logistics_problem",
				"problem_keys": problem_keys,
				"filter": LogisticsNetworkOverlay.FILTER_BLOCKAGES,
			}
		)
		return
	var item_names := PackedStringArray()
	for problem: Dictionary in problems:
		var item_id := str(problem.get("item_id", ""))
		var item := ItemDatabase.registry.get(item_id) as ItemData
		var item_name := tr(item.name) if item != null else item_id
		if not item_names.has(item_name):
			item_names.append(item_name)
	NotificationCenter.push(
		"factory",
		tr("Logistics supply missing"),
		tr("No provider configured for: %s. Press L to inspect.") % ", ".join(item_names),
		"warning",
		{
			"type": "open_logistics_problem",
			"problem_keys": problem_keys,
			"filter": LogisticsNetworkOverlay.FILTER_SHORTAGES,
		}
	)


func _on_notification_action_requested(action: Dictionary) -> void:
	if str(action.get("type", "")) != "open_logistics_problem" or _overlay == null:
		return
	var problem_keys: Array = action.get("problem_keys", []) as Array
	_overlay.open_from_notification(problem_keys, int(action.get("filter", LogisticsNetworkOverlay.FILTER_ALL)))


func _problem_key(problem: Dictionary) -> String:
	var tile := problem.get("tile", Vector2i.ZERO) as Vector2i
	return "%s|%d:%d|%s" % [
		str(problem.get("kind", "")),
		tile.x,
		tile.y,
		str(problem.get("item_id", "")),
	]


func _now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0
