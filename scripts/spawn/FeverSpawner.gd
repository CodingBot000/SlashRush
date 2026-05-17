extends RefCounted
class_name FeverSpawner

const SpawnBalance := preload("res://scripts/spawn/SpawnBalance.gd")

var spawn_timer := 0.0
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func reset() -> void:
	spawn_timer = 0.0

func update(delta: float, spawn_callback: Callable) -> void:
	spawn_timer -= delta
	while spawn_timer <= 0.0:
		spawn_callback.call(_pick_fever_object())
		spawn_timer += _rng.randf_range(
			SpawnBalance.FEVER_SPAWN_INTERVAL_MIN,
			SpawnBalance.FEVER_SPAWN_INTERVAL_MAX
		)

func _pick_fever_object() -> String:
	var weights := SpawnBalance.FEVER_OBJECT_WEIGHTS
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
