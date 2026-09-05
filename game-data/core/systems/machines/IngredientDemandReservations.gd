extends RefCounted
class_name IngredientDemandReservations

const STACK_META_KEY := "_ingredient_demand_reservation"
const RESERVATION_TTL_MSEC := 600000

static var _reservations: Dictionary = {}
static var _reserved_totals: Dictionary = {}
static var _next_token := 1


static func target_context(target_key: String, requests: Dictionary) -> Dictionary:
	var allocations: Dictionary = {}
	for item_value: Variant in requests:
		var item_id := str(item_value)
		var amount := maxi(int(requests[item_value]), 0)
		if not item_id.is_empty() and amount > 0:
			allocations[item_id] = [{"key": target_key, "amount": amount}]
	return context_from_allocations(true, allocations)


static func context_from_allocations(active: bool, allocations: Dictionary) -> Dictionary:
	_prune_expired()
	var available: Dictionary = {}
	var reserved: Dictionary = {}
	var normalized: Dictionary = {}
	for item_value: Variant in allocations:
		var item_id := str(item_value)
		var entries: Array = allocations[item_value] if allocations[item_value] is Array else []
		var normalized_entries: Array[Dictionary] = []
		var available_total := 0
		var reserved_total := 0
		for entry_value: Variant in entries:
			if not entry_value is Dictionary:
				continue
			var entry := entry_value as Dictionary
			var target_key := str(entry.get("key", ""))
			var raw_amount := maxi(int(entry.get("amount", 0)), 0)
			if target_key.is_empty() or raw_amount <= 0:
				continue
			var reserved_amount := mini(_reserved_amount(target_key, item_id), raw_amount)
			normalized_entries.append({"key": target_key, "amount": raw_amount})
			available_total += raw_amount - reserved_amount
			reserved_total += reserved_amount
		if not normalized_entries.is_empty():
			normalized[item_id] = normalized_entries
			if available_total > 0:
				available[item_id] = available_total
			if reserved_total > 0:
				reserved[item_id] = reserved_total
	return {
		"active": active,
		"requests": available,
		"reserved": reserved,
		"reserved_total": _dictionary_total(reserved),
		"allocations": normalized,
	}


static func reserve(context: Dictionary, item_id: String, amount: int = 1) -> Dictionary:
	if amount <= 0 or item_id.is_empty():
		return {}
	var allocations := context.get("allocations", {}) as Dictionary
	var entries: Array = allocations.get(item_id, []) if allocations.get(item_id, []) is Array else []
	var selected_key := ""
	var selected_available := 0
	for entry_value: Variant in entries:
		if not entry_value is Dictionary:
			continue
		var entry := entry_value as Dictionary
		var target_key := str(entry.get("key", ""))
		var available := maxi(int(entry.get("amount", 0)) - _reserved_amount(target_key, item_id), 0)
		if available > selected_available:
			selected_key = target_key
			selected_available = available
	if selected_key.is_empty() or selected_available <= 0:
		return {}
	return _create_reservation(selected_key, item_id, mini(amount, selected_available))


static func split_stack(original: Dictionary, extracted: Dictionary, remaining: Dictionary) -> Dictionary:
	var reservation := _reservation_from_stack(original)
	if reservation.is_empty():
		return {"extracted": extracted, "remaining": remaining}
	var clean_extracted := payload_without_reservation(extracted)
	var clean_remaining := payload_without_reservation(remaining)
	var target_key := str(reservation.get("key", ""))
	var item_id := str(reservation.get("item_id", ""))
	var reserved_amount := maxi(int(reservation.get("amount", 0)), 0)
	_release_token(str(reservation.get("token", "")))
	var extracted_amount := mini(reserved_amount, maxi(int(clean_extracted.get("count", 0)), 0))
	var remaining_amount := mini(
		maxi(reserved_amount - extracted_amount, 0),
		maxi(int(clean_remaining.get("count", 0)), 0)
	)
	if extracted_amount > 0:
		clean_extracted = attach_to_stack(
			clean_extracted,
			_create_reservation(target_key, item_id, extracted_amount)
		)
	if remaining_amount > 0:
		clean_remaining = attach_to_stack(
			clean_remaining,
			_create_reservation(target_key, item_id, remaining_amount)
		)
	return {"extracted": clean_extracted, "remaining": clean_remaining}


static func _create_reservation(target_key: String, item_id: String, amount: int) -> Dictionary:
	if target_key.is_empty() or item_id.is_empty() or amount <= 0:
		return {}
	var token := "%d:%d" % [Time.get_ticks_msec(), _next_token]
	_next_token += 1
	var reservation := {
		"token": token,
		"key": target_key,
		"item_id": item_id,
		"amount": amount,
		"last_seen": Time.get_ticks_msec(),
	}
	_register(reservation)
	return reservation.duplicate(true)


static func attach_to_stack(stack: Dictionary, reservation: Dictionary) -> Dictionary:
	var result := stack.duplicate(true)
	if not reservation.is_empty():
		result[STACK_META_KEY] = reservation.duplicate(true)
	return result


static func has_reservation(stack: Dictionary) -> bool:
	return stack.get(STACK_META_KEY, {}) is Dictionary and not (stack.get(STACK_META_KEY, {}) as Dictionary).is_empty()


static func reservation_matches_context(stack: Dictionary, context: Dictionary) -> bool:
	var reservation := _reservation_from_stack(stack)
	if reservation.is_empty():
		return false
	_touch(reservation)
	var item_id := str(reservation.get("item_id", ""))
	var target_key := str(reservation.get("key", ""))
	var allocations := context.get("allocations", {}) as Dictionary
	var entries: Array = allocations.get(item_id, []) if allocations.get(item_id, []) is Array else []
	for entry_value: Variant in entries:
		if entry_value is Dictionary and str((entry_value as Dictionary).get("key", "")) == target_key:
			return true
	return false


static func restore_stack(stack: Dictionary) -> void:
	var reservation := _reservation_from_stack(stack)
	if reservation.is_empty():
		return
	reservation["last_seen"] = Time.get_ticks_msec()
	_register(reservation)


static func release_stack(stack: Dictionary) -> void:
	var reservation := _reservation_from_stack(stack)
	if not reservation.is_empty():
		_release_token(str(reservation.get("token", "")))


static func payload_without_reservation(stack: Dictionary) -> Dictionary:
	var result := stack.duplicate(true)
	result.erase(STACK_META_KEY)
	return result


static func _reservation_from_stack(stack: Dictionary) -> Dictionary:
	var value: Variant = stack.get(STACK_META_KEY, {})
	return value as Dictionary if value is Dictionary else {}


static func _register(reservation: Dictionary) -> void:
	var token := str(reservation.get("token", ""))
	var target_key := str(reservation.get("key", ""))
	var item_id := str(reservation.get("item_id", ""))
	var amount := maxi(int(reservation.get("amount", 0)), 0)
	if token.is_empty() or target_key.is_empty() or item_id.is_empty() or amount <= 0:
		return
	if _reservations.has(token):
		_reservations[token] = reservation.duplicate(true)
		return
	_reservations[token] = reservation.duplicate(true)
	var target_totals := _reserved_totals.get(target_key, {}) as Dictionary
	target_totals[item_id] = int(target_totals.get(item_id, 0)) + amount
	_reserved_totals[target_key] = target_totals


static func _release_token(token: String) -> void:
	if token.is_empty() or not _reservations.has(token):
		return
	var reservation := _reservations[token] as Dictionary
	_reservations.erase(token)
	var target_key := str(reservation.get("key", ""))
	var item_id := str(reservation.get("item_id", ""))
	var amount := maxi(int(reservation.get("amount", 0)), 0)
	var target_totals := _reserved_totals.get(target_key, {}) as Dictionary
	var remaining := maxi(int(target_totals.get(item_id, 0)) - amount, 0)
	if remaining > 0:
		target_totals[item_id] = remaining
	else:
		target_totals.erase(item_id)
	if target_totals.is_empty():
		_reserved_totals.erase(target_key)
	else:
		_reserved_totals[target_key] = target_totals


static func _reserved_amount(target_key: String, item_id: String) -> int:
	return int((_reserved_totals.get(target_key, {}) as Dictionary).get(item_id, 0))


static func _touch(reservation: Dictionary) -> void:
	var token := str(reservation.get("token", ""))
	if not _reservations.has(token):
		_register(reservation)
		return
	var registered := _reservations[token] as Dictionary
	registered["last_seen"] = Time.get_ticks_msec()
	_reservations[token] = registered


static func _prune_expired() -> void:
	var now := Time.get_ticks_msec()
	for token_value: Variant in _reservations.keys():
		var token := str(token_value)
		var reservation := _reservations[token] as Dictionary
		if now - int(reservation.get("last_seen", now)) > RESERVATION_TTL_MSEC:
			_release_token(token)


static func _dictionary_total(values: Dictionary) -> int:
	var result := 0
	for value: Variant in values.values():
		result += int(value)
	return result
