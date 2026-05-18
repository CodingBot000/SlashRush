extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var haptic_manager = root.get_node_or_null("HapticManager")
	if haptic_manager == null:
		_fail("HapticManager autoload should exist.")
		return

	await _assert_attack_haptic(haptic_manager)
	await _assert_runner_hurt_haptic(haptic_manager)
	await _assert_boss_hurt_haptic(haptic_manager)
	quit()

func _assert_attack_haptic(haptic_manager) -> void:
	haptic_manager.reset_debug_state()
	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	player.play_slash()
	await process_frame
	if haptic_manager.last_vibration_event != "attack":
		_fail("Player slash should trigger attack vibration.")
		return

	player.queue_free()
	await process_frame

func _assert_runner_hurt_haptic(haptic_manager) -> void:
	haptic_manager.reset_debug_state()
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_run()
	stage.spawner.stop()
	var bomb = INTERACTABLE_OBJECT_SCENE.instantiate()
	stage.object_root.add_child(bomb)
	bomb.setup("bomb")
	bomb.position = GameBalance.ACTION_ZONE_CENTER
	stage._fail_object(bomb, false)
	await process_frame

	if haptic_manager.last_vibration_event != "player_hurt":
		_fail("Runner player damage should trigger player_hurt vibration.")
		return

	stage.stop_run()
	stage.queue_free()
	await process_frame

func _assert_boss_hurt_haptic(haptic_manager) -> void:
	haptic_manager.reset_debug_state()
	var stage = BOSS_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_boss(0, 0, GameBalance.MAX_HP)
	stage._fail_pattern("MISS")
	await process_frame

	if haptic_manager.last_vibration_event != "player_hurt":
		_fail("Boss player damage should trigger player_hurt vibration.")
		return

	stage.stop_boss()
	stage.queue_free()
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
