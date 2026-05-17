extends SceneTree

const OBJECT_SPAWNER_SCRIPT := preload("res://scripts/game/ObjectSpawner.gd")
const SpawnBalance := preload("res://scripts/spawn/SpawnBalance.gd")

var _spawn_log: Array = []
var _provider_hp := 1
var _provider_max_hp := 3

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _assert_normal_schedule_rules()
	await _assert_heal_is_conditional()
	await _assert_fever_rush_is_separate()
	quit()

func _assert_normal_schedule_rules() -> void:
	_spawn_log.clear()
	var spawner = OBJECT_SPAWNER_SCRIPT.new()
	root.add_child(spawner)
	spawner.object_spawned.connect(_on_object_spawned.bind(spawner))
	spawner.start(12345)

	for _index in range(610):
		spawner._process(0.1)

	var counts := _count_spawned_types(_spawn_log)
	if int(counts.get("coin", 0)) < SpawnBalance.COIN_TARGET_MIN or int(counts.get("coin", 0)) > int(SpawnBalance.ITEM_BUDGET["coin"]):
		_fail("Coin spawns should stay inside the configured normal-stage budget.")
	if int(counts.get("fever_orb", 0)) > int(SpawnBalance.ITEM_BUDGET["fever_orb"]):
		_fail("Fever orb spawns should stay inside the configured budget.")
	if int(counts.get("heal", 0)) != 0:
		_fail("Heal should not spawn when the health provider reports full HP.")

	for entry in _spawn_log:
		if String(entry["type"]) == "enemy_armor" and float(entry["time"]) < 30.0:
			_fail("Armor should not spawn before 30 seconds.")
		if float(entry["time"]) > SpawnBalance.STAGE_DURATION + 0.01:
			_fail("Normal stage should not spawn after 60 seconds.")

	_assert_good_item_spacing(_spawn_log)
	spawner.free()

func _assert_heal_is_conditional() -> void:
	_spawn_log.clear()
	var spawner = OBJECT_SPAWNER_SCRIPT.new()
	root.add_child(spawner)
	spawner.set_player_health_provider(Callable(self, "_get_provider_hp"), Callable(self, "_get_provider_max_hp"))
	spawner.object_spawned.connect(_on_object_spawned.bind(spawner))
	spawner.start(12345)

	for _index in range(610):
		spawner._process(0.1)

	var counts := _count_spawned_types(_spawn_log)
	if int(counts.get("heal", 0)) <= 0:
		_fail("Heal candidates should become heal spawns when HP is below max.")
	if int(counts.get("heal", 0)) > int(SpawnBalance.ITEM_BUDGET["heal"]):
		_fail("Heal spawns should stay inside the configured budget.")
	spawner.free()

func _assert_fever_rush_is_separate() -> void:
	_spawn_log.clear()
	var spawner = OBJECT_SPAWNER_SCRIPT.new()
	root.add_child(spawner)
	spawner.object_spawned.connect(_on_object_spawned.bind(spawner))
	spawner.start(12345)
	spawner.set_fever_rush_enabled(true)

	for _index in range(20):
		spawner._process(0.1)

	if _spawn_log.is_empty():
		_fail("Fever rush should spawn objects independently from the normal schedule.")

	for entry in _spawn_log:
		if not bool(entry["fever"]):
			_fail("Fever rush entries should be marked as fever spawns.")
		var type_name := String(entry["type"])
		if type_name == "enemy_armor" or type_name == "coin" or type_name == "heal" or type_name == "fever_orb":
			_fail("Fever rush should exclude armor and good items.")
	spawner.free()

func _assert_good_item_spacing(spawn_log: Array) -> void:
	var last_good_time := -999.0
	for entry in spawn_log:
		var type_name := String(entry["type"])
		if not _is_good_item_type(type_name):
			continue
		var current_time := float(entry["time"])
		if current_time - last_good_time < SpawnBalance.GOOD_ITEM_MIN_INTERVAL - 0.11:
			_fail("Good items should not spawn back-to-back.")
		last_good_time = current_time

func _count_spawned_types(spawn_log: Array) -> Dictionary:
	var counts := {}
	for entry in spawn_log:
		var type_name := String(entry["type"])
		counts[type_name] = int(counts.get(type_name, 0)) + 1
	return counts

func _is_good_item_type(type_name: String) -> bool:
	return type_name == "coin" or type_name == "heal" or type_name == "fever_orb"

func _on_object_spawned(object, spawner) -> void:
	_spawn_log.append({
		"time": spawner._elapsed,
		"type": object.object_type,
		"fever": object.has_meta("fever_rush_spawn") and object.get_meta("fever_rush_spawn") == true
	})
	object.free()

func _get_provider_hp() -> int:
	return _provider_hp

func _get_provider_max_hp() -> int:
	return _provider_max_hp

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
