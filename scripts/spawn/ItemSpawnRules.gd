extends RefCounted
class_name ItemSpawnRules

const SpawnBalance := preload("res://scripts/spawn/SpawnBalance.gd")

var item_budget := {}
var item_spawned_count := {}
var runner_config = null

var last_good_item_time := -999.0
var last_heal_time := -999.0
var last_fever_orb_time := -999.0

func _init() -> void:
	reset()

func reset() -> void:
	item_budget = _get_item_budget().duplicate(true)
	item_spawned_count = {
		"coin": 0,
		"fever_orb": 0,
		"heal": 0
	}
	last_good_item_time = -999.0
	last_heal_time = -999.0
	last_fever_orb_time = -999.0

func configure(config) -> void:
	runner_config = config
	reset()

func can_spawn_good_item(type: String, stage_time: float, fever_active: bool) -> bool:
	if fever_active:
		return false
	if not item_budget.has(type):
		return false
	if item_spawned_count[type] >= item_budget[type]:
		return false
	if stage_time - last_good_item_time < _get_good_item_min_interval():
		return false
	return true

func can_spawn_coin(stage_time: float, fever_active: bool) -> bool:
	return can_spawn_good_item("coin", stage_time, fever_active)

func can_spawn_fever_orb(stage_time: float, fever_active: bool, last_fever_end_time: float) -> bool:
	if not can_spawn_good_item("fever_orb", stage_time, fever_active):
		return false
	if stage_time - last_fever_orb_time < _get_fever_orb_min_interval():
		return false
	if stage_time - last_fever_end_time < _get_fever_after_end_block_time():
		return false
	return true

func can_spawn_heal(stage_time: float, fever_active: bool, player_hp: int, player_max_hp: int) -> bool:
	if fever_active:
		return false
	if player_hp >= player_max_hp:
		return false
	if item_spawned_count["heal"] >= item_budget["heal"]:
		return false
	if stage_time - last_heal_time < _get_heal_min_interval():
		return false
	if stage_time - last_good_item_time < _get_good_item_min_interval():
		return false
	return true

func mark_spawned(type: String, stage_time: float) -> void:
	if not item_spawned_count.has(type):
		return
	item_spawned_count[type] += 1
	last_good_item_time = stage_time
	if type == "heal":
		last_heal_time = stage_time
	if type == "fever_orb":
		last_fever_orb_time = stage_time

func _get_item_budget() -> Dictionary:
	if runner_config != null and runner_config.item_budget is Dictionary:
		return runner_config.item_budget
	return SpawnBalance.ITEM_BUDGET

func _get_good_item_min_interval() -> float:
	if runner_config != null:
		return float(runner_config.good_item_min_interval)
	return SpawnBalance.GOOD_ITEM_MIN_INTERVAL

func _get_heal_min_interval() -> float:
	if runner_config != null:
		return float(runner_config.heal_min_interval)
	return SpawnBalance.HEAL_MIN_INTERVAL

func _get_fever_orb_min_interval() -> float:
	if runner_config != null:
		return float(runner_config.fever_orb_min_interval)
	return SpawnBalance.FEVER_ORB_MIN_INTERVAL

func _get_fever_after_end_block_time() -> float:
	if runner_config != null:
		return float(runner_config.fever_after_end_block_time)
	return SpawnBalance.FEVER_AFTER_END_BLOCK_TIME
