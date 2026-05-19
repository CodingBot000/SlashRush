extends RefCounted
class_name FeverSpawner

const SpawnBalance := preload("res://scripts/spawn/SpawnBalance.gd")

var spawn_timer := 0.0
var runner_config = null
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func reset() -> void:
	spawn_timer = 0.0

func configure(config) -> void:
	runner_config = config

func update(delta: float, spawn_callback: Callable) -> void:
	spawn_timer -= delta
	while spawn_timer <= 0.0:
		spawn_callback.call(_pick_fever_object())
		spawn_timer += _rng.randf_range(
			_get_fever_spawn_interval_min(),
			_get_fever_spawn_interval_max()
		)

func _pick_fever_object() -> String:
	var weights := _get_fever_object_weights()
	var total := 0
	for value in weights.values():
		total += int(value)

	var roll := _rng.randi_range(0, total - 1)
	var acc := 0
	for key in weights.keys():
		acc += int(weights[key])
		if roll < acc:
			return String(key)
	return "enemy_basic"

func _get_fever_spawn_interval_min() -> float:
	if runner_config != null:
		return float(runner_config.fever_spawn_interval_min)
	return SpawnBalance.FEVER_SPAWN_INTERVAL_MIN

func _get_fever_spawn_interval_max() -> float:
	if runner_config != null:
		return float(runner_config.fever_spawn_interval_max)
	return SpawnBalance.FEVER_SPAWN_INTERVAL_MAX

func _get_fever_object_weights() -> Dictionary:
	if runner_config != null and runner_config.fever_object_weights is Dictionary:
		return runner_config.fever_object_weights
	return SpawnBalance.FEVER_OBJECT_WEIGHTS
