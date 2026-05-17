extends SceneTree

const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

const TEST_TYPES := ["enemy_basic", "enemy_fast", "enemy_armor"]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for type_name in TEST_TYPES:
		var object = INTERACTABLE_OBJECT_SCENE.instantiate()
		root.add_child(object)
		object.setup(type_name)
		object.position = Vector2(GameBalance.SPAWN_X, GameBalance.SPAWN_Y)
		object.visual_effect_time_offset = 0.0
		object.visual_effect_has_object_base_y = false

		var base_y: float = object.position.y
		var min_y: float = base_y
		for _index in range(90):
			await process_frame
			min_y = min(min_y, object.position.y)

		object.queue_free()
		if min_y >= base_y - 12.0:
			push_error("%s root y did not jump enough. base=%f min=%f" % [type_name, base_y, min_y])
			quit(1)
			return

	quit()
