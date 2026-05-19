extends Node
class_name StageSpawnDirector

signal object_spawned(object)

const OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")
const SpawnBalance := preload("res://scripts/spawn/SpawnBalance.gd")
const NormalScheduleGenerator := preload("res://scripts/spawn/NormalScheduleGenerator.gd")
const ItemSpawnRules := preload("res://scripts/spawn/ItemSpawnRules.gd")
const FeverSpawner := preload("res://scripts/spawn/FeverSpawner.gd")

var running := false
var objects_spawned := 0
var stage_time := 0.0
var normal_schedule: Array = []
var normal_index := 0

var item_rules: ItemSpawnRules
var fever_spawner: FeverSpawner
var runner_config = null
var object_visual_set = null

var fever_active := false
var fever_time_left := 0.0
var fever_recover_time := 0.0
var last_fever_end_time := -999.0

var schedule_seed := 0
var _elapsed := 0.0
var _timer := 0.0
var _fever_rush_enabled := false
var _fever_rush_timer := 0.0
var _spawn_pause_timer := 0.0
var _player_hp_provider: Callable
var _player_max_hp_provider: Callable

func _ready() -> void:
	item_rules = ItemSpawnRules.new()
	fever_spawner = FeverSpawner.new()
	_apply_config_to_helpers()

func configure(config, visual_set = null) -> void:
	runner_config = config
	object_visual_set = visual_set
	_apply_config_to_helpers()

func start(seed_value: int = 0) -> void:
	if item_rules == null:
		item_rules = ItemSpawnRules.new()
	if fever_spawner == null:
		fever_spawner = FeverSpawner.new()
	_apply_config_to_helpers()

	schedule_seed = seed_value
	running = true
	objects_spawned = 0
	stage_time = 0.0
	_elapsed = 0.0
	_timer = 0.0
	_fever_rush_enabled = false
	_fever_rush_timer = 0.0
	_spawn_pause_timer = 0.0
	fever_active = false
	fever_time_left = 0.0
	fever_recover_time = 0.0
	last_fever_end_time = -999.0
	item_rules.reset()
	fever_spawner.reset()
	var generator := NormalScheduleGenerator.new()
	normal_schedule = generator.generate(schedule_seed, runner_config)
	normal_index = 0

func stop() -> void:
	running = false
	_fever_rush_enabled = false
	fever_active = false
	_spawn_pause_timer = 0.0

func set_player_health_provider(hp_provider: Callable, max_hp_provider: Callable) -> void:
	_player_hp_provider = hp_provider
	_player_max_hp_provider = max_hp_provider

func set_fever_rush_enabled(enabled: bool) -> void:
	if _fever_rush_enabled == enabled:
		return
	_fever_rush_enabled = enabled
	fever_active = enabled
	if enabled:
		fever_spawner.reset()
		_fever_rush_timer = fever_spawner.spawn_timer
		_skip_normal_events_until(stage_time)

func pause_spawning(duration: float) -> void:
	_spawn_pause_timer = max(_spawn_pause_timer, duration)
	fever_recover_time = max(fever_recover_time, duration)

func mark_fever_ended() -> void:
	last_fever_end_time = stage_time
	fever_active = false

func debug_print_schedule() -> void:
	for event in normal_schedule:
		print("[SPAWN] ", event.time, " / ", event.type)

func _process(delta: float) -> void:
	if not running:
		return

	stage_time += delta
	_elapsed = stage_time

	if stage_time >= _get_stage_duration():
		_skip_normal_events_until(stage_time)
		return

	if _spawn_pause_timer > 0.0:
		_spawn_pause_timer = max(0.0, _spawn_pause_timer - delta)
		fever_recover_time = _spawn_pause_timer
		_skip_normal_events_until(stage_time)
		return

	if _fever_rush_enabled:
		_process_fever_rush(delta)
		_skip_normal_events_until(stage_time)
		return

	_update_normal_spawns()

func _process_fever_rush(delta: float) -> void:
	if fever_spawner == null:
		return
	fever_spawner.update(delta, Callable(self, "_spawn_fever_rush_object"))
	_fever_rush_timer = fever_spawner.spawn_timer

func _update_normal_spawns() -> void:
	while normal_index < normal_schedule.size():
		var event = normal_schedule[normal_index]
		if float(event.time) > stage_time:
			break
		_handle_spawn_event(event)
		normal_index += 1

func _handle_spawn_event(event) -> void:
	match String(event.type):
		"coin":
			if item_rules.can_spawn_coin(stage_time, _fever_rush_enabled):
				_spawn_object("coin")
				item_rules.mark_spawned("coin", stage_time)
		"fever_orb":
			if item_rules.can_spawn_fever_orb(stage_time, _fever_rush_enabled, last_fever_end_time):
				_spawn_object("fever_orb")
				item_rules.mark_spawned("fever_orb", stage_time)
		"heal_candidate":
			if item_rules.can_spawn_heal(stage_time, _fever_rush_enabled, _get_player_hp(), _get_player_max_hp()):
				_spawn_object("heal")
				item_rules.mark_spawned("heal", stage_time)
		_:
			_spawn_object(String(event.type))

func _skip_normal_events_until(current_time: float) -> void:
	while normal_index < normal_schedule.size():
		var event = normal_schedule[normal_index]
		if float(event.time) > current_time:
			break
		normal_index += 1

func _spawn_fever_rush_object(type_name: String) -> void:
	_spawn_object(type_name, true)

func _spawn_object(type_name: String, from_fever_rush: bool = false) -> void:
	var object := OBJECT_SCENE.instantiate()
	object.setup(type_name, object_visual_set)
	object.add_to_group("spawned_object")
	if from_fever_rush:
		object.set_meta("fever_rush_spawn", true)
	object.position = Vector2(GameBalance.SPAWN_X, GameBalance.SPAWN_Y + object.spawn_y_offset)
	object_spawned.emit(object)
	objects_spawned += 1

func _get_player_hp() -> int:
	if _player_hp_provider.is_valid():
		return int(_player_hp_provider.call())
	return GameBalance.MAX_HP

func _get_player_max_hp() -> int:
	if _player_max_hp_provider.is_valid():
		return int(_player_max_hp_provider.call())
	return GameBalance.MAX_HP

func _apply_config_to_helpers() -> void:
	if item_rules != null:
		item_rules.configure(runner_config)
	if fever_spawner != null:
		fever_spawner.configure(runner_config)

func _get_stage_duration() -> float:
	if runner_config != null:
		return float(runner_config.duration_seconds)
	return SpawnBalance.STAGE_DURATION
