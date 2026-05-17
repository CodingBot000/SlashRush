extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_run()
	stage.spawner.stop()
	await process_frame

	stage.score = 0
	stage.combo = 0
	stage.fever = 0
	stage.fever_mode.fever = 0
	stage._sync_fever_state()

	var enemy_a = _add_zone_object(stage, "enemy_basic", Vector2(0.0, 0.0))
	var enemy_b = _add_zone_object(stage, "enemy_basic", Vector2(12.0, 0.0))
	var bomb = _add_zone_object(stage, "bomb", Vector2(-10.0, -18.0))

	stage.handle_player_action("tap")
	var enemy_a_handled: bool = enemy_a.handled
	var enemy_b_handled: bool = enemy_b.handled
	var bomb_handled: bool = bomb.handled

	if not enemy_a_handled or not enemy_b_handled or not bomb_handled:
		_fail("All overlapping dangerous objects in the action zone should be handled by one slash.")
		return
	if stage.score != 280:
		_fail("One slash should award score for both enemies and the bomb.")
		return
	if stage.combo != 3:
		_fail("One slash should count combo for every hit dangerous object.")
		return

	await process_frame
	stage.queue_free()
	await process_frame
	quit()

func _add_zone_object(stage, type_name: String, offset: Vector2):
	var object = INTERACTABLE_OBJECT_SCENE.instantiate()
	stage.object_root.add_child(object)
	object.setup(type_name)
	object.position = GameBalance.ACTION_ZONE_CENTER + offset
	return object

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
