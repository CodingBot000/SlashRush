extends RefCounted
class_name NormalScheduleGenerator

const SpawnBalance := preload("res://scripts/spawn/SpawnBalance.gd")
const SpawnEvent := preload("res://scripts/spawn/SpawnEvent.gd")

var _rng := RandomNumberGenerator.new()

func generate(seed_value: int = 0) -> Array:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

	var events: Array = []
	_generate_danger_events(events)
	_insert_item_candidates(events)
	_sort_events(events)
	return events

func _generate_danger_events(events: Array) -> void:
	for phase in SpawnBalance.PHASES:
		var t := float(phase["start"])
		while t < float(phase["end"]):
			t += _rng.randf_range(float(phase["spawn_interval_min"]), float(phase["spawn_interval_max"]))
			if t >= float(phase["end"]):
				break

			var object_type := _pick_danger_type(phase, t, events)
			if object_type.is_empty():
				continue
			events.append(SpawnEvent.new(t, object_type))

func _pick_danger_type(phase: Dictionary, t: float, events: Array) -> String:
	var allowed: Array = phase["allowed_danger"].duplicate()
	if t < 30.0:
		allowed.erase("enemy_armor")
	if not _can_place_armor_at(t, events):
		allowed.erase("enemy_armor")
	if _was_recent_type(events, "enemy_fast", 1):
		allowed.erase("enemy_fast")
	if _was_recent_type(events, "bomb", 2):
		allowed.erase("bomb")
	if allowed.is_empty():
		return "enemy_basic"
	return String(allowed[_rng.randi_range(0, allowed.size() - 1)])

func _insert_item_candidates(events: Array) -> void:
	_insert_fever_orb_candidates(events)
	_insert_heal_candidates(events)
	_insert_coin_candidates(events)

func _insert_fever_orb_candidates(events: Array) -> void:
	for window in SpawnBalance.FEVER_ORB_WINDOWS:
		if _count_type(events, "fever_orb") >= int(SpawnBalance.ITEM_BUDGET["fever_orb"]):
			return
		var item_time := _find_safe_item_time(float(window["start"]), float(window["end"]), events)
		if item_time >= 0.0:
			events.append(SpawnEvent.new(item_time, "fever_orb"))

func _insert_heal_candidates(events: Array) -> void:
	for candidate_time in SpawnBalance.HEAL_CANDIDATE_TIMES:
		if _count_type(events, "heal_candidate") >= int(SpawnBalance.ITEM_BUDGET["heal"]):
			return
		var item_time := _find_safe_item_time(
			max(0.5, float(candidate_time) - 1.2),
			min(SpawnBalance.STAGE_DURATION - 0.5, float(candidate_time) + 1.2),
			events
		)
		if item_time >= 0.0:
			events.append(SpawnEvent.new(item_time, "heal_candidate"))

func _insert_coin_candidates(events: Array) -> void:
	var target := _rng.randi_range(SpawnBalance.COIN_TARGET_MIN, SpawnBalance.COIN_TARGET_MAX)
	var attempts := 0
	while _count_type(events, "coin") < target and attempts < target * 24:
		attempts += 1
		var item_time := _find_safe_item_time(4.0, SpawnBalance.STAGE_DURATION - 1.0, events)
		if item_time < 0.0:
			break
		events.append(SpawnEvent.new(item_time, "coin"))

func _find_safe_item_time(start_time: float, end_time: float, events: Array) -> float:
	var safe_start: float = max(0.0, start_time)
	var safe_end: float = min(SpawnBalance.STAGE_DURATION, end_time)
	if safe_start >= safe_end:
		return -1.0

	for _attempt in range(40):
		var t: float = snapped(_rng.randf_range(safe_start, safe_end), 0.05)
		if _is_safe_item_time(t, events):
			return t

	var t: float = safe_start
	while t <= safe_end:
		if _is_safe_item_time(t, events):
			return t
		t += 0.1
	return -1.0

func _is_safe_item_time(t: float, events: Array) -> bool:
	for event in events:
		var gap: float = abs(float(event.time) - t)
		if gap < SpawnBalance.GOOD_ITEM_MIN_INTERVAL and _is_good_item_type(String(event.type)):
			return false
		if String(event.type) == "enemy_fast" and float(event.time) < t and t - float(event.time) < SpawnBalance.ITEM_AFTER_FAST_MIN_GAP:
			return false
		if String(event.type) == "enemy_armor" and gap < SpawnBalance.ARMOR_MIN_GAP_BEFORE:
			return false
	return true

func _can_place_armor_at(t: float, events: Array) -> bool:
	for event in events:
		if String(event.type) != "enemy_armor":
			continue
		var gap: float = abs(float(event.time) - t)
		if gap < SpawnBalance.ARMOR_MIN_GAP_BEFORE + SpawnBalance.ARMOR_MIN_GAP_AFTER:
			return false
	return true

func _was_recent_type(events: Array, type_name: String, count: int) -> bool:
	var matched := 0
	for index in range(events.size() - 1, -1, -1):
		var event = events[index]
		if _is_good_item_type(String(event.type)):
			continue
		if String(event.type) != type_name:
			return false
		matched += 1
		if matched >= count:
			return true
	return false

func _count_type(events: Array, type_name: String) -> int:
	var count := 0
	for event in events:
		if String(event.type) == type_name:
			count += 1
	return count

func _is_good_item_type(type_name: String) -> bool:
	return type_name == "coin" or type_name == "fever_orb" or type_name == "heal_candidate" or type_name == "heal"

func _sort_events(events: Array) -> void:
	events.sort_custom(func(a, b): return a.time < b.time)
