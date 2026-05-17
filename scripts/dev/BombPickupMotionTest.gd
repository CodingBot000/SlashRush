extends SceneTree

const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var heal = INTERACTABLE_OBJECT_SCENE.instantiate()
	var bomb = INTERACTABLE_OBJECT_SCENE.instantiate()
	root.add_child(heal)
	root.add_child(bomb)
	heal.setup("heal")
	bomb.setup("bomb")

	if bomb.is_good_item:
		push_error("Bomb should remain a dangerous object, not a good item.")
		quit(1)
		return
	if bomb.required_action != "tap":
		push_error("Bomb should keep tap handling.")
		quit(1)
		return
	if not is_equal_approx(bomb.spawn_y_offset, heal.spawn_y_offset):
		push_error("Bomb spawn y offset should match heal.")
		quit(1)
		return
	if bomb.visual_effect_mode != heal.visual_effect_mode or bomb.visual_effect_mode != "pickup_float":
		push_error("Bomb visual motion should match heal pickup float motion.")
		quit(1)
		return

	bomb.visual_effect_time_offset = 0.0
	bomb.float_offset_y = 0.0
	bomb.float_velocity_y = 0.0
	var start_y: float = bomb.visual_effect_target.position.y
	for _index in range(30):
		await process_frame
	if is_equal_approx(bomb.visual_effect_target.position.y, start_y):
		push_error("Bomb pickup float motion did not move the visual target.")
		quit(1)
		return

	quit()
