extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const PlayerLifeState := preload("res://scripts/game/PlayerLifeState.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _assert_runner_game_over()
	await _assert_boss_game_over()
	quit()

func _assert_runner_game_over() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var debug_flags = root.get_node_or_null("DebugFlags")
	if debug_flags != null:
		debug_flags.player_invincible = false

	main._start_game()
	await process_frame

	var object = INTERACTABLE_OBJECT_SCENE.instantiate()
	main.runner_stage.object_root.add_child(object)
	object.setup("enemy_basic")
	object.damage_on_fail = main.runner_stage.hp
	main.runner_stage._fail_object(object, false)
	await process_frame

	if main.state != "result":
		push_error("Main did not enter result state after HP reached 0.")
		quit(1)
		return
	if not main.result_panel.visible:
		push_error("Result panel is hidden after HP reached 0.")
		quit(1)
		return
	if main.result_panel.title_label.text != "GAME OVER":
		push_error("Game over popup title was not shown.")
		quit(1)
		return
	if main.runner_stage.active:
		push_error("Runner stage should stop after game over.")
		quit(1)
		return
	if not PlayerLifeState.is_player_dead(main.runner_stage.hp, false):
		push_error("Player death state should be evaluated by PlayerLifeState.")
		quit(1)
		return
	if not main.runner_stage.visible:
		push_error("Runner stage should remain visible behind the game over popup.")
		quit(1)
		return
	if not _has_visible_dead_sprite(main.runner_stage.player):
		push_error("Runner player dead sprite should be visible after game over.")
		quit(1)
		return

	main.queue_free()
	await process_frame

func _assert_boss_game_over() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var debug_flags = root.get_node_or_null("DebugFlags")
	if debug_flags != null:
		debug_flags.player_invincible = false

	main.current_hp = 1
	main._start_boss()
	await process_frame

	main.boss_stage.hp = 1
	main.boss_stage._fail_pattern("MISS")
	await process_frame

	if main.state != "result":
		push_error("Main did not enter result state after boss player HP reached 0.")
		quit(1)
		return
	if not main.boss_stage.visible:
		push_error("Boss stage should remain visible behind the game over popup.")
		quit(1)
		return
	if not _has_visible_dead_sprite(main.boss_stage.player):
		push_error("Boss player dead sprite should be visible after game over.")
		quit(1)
		return

	main.queue_free()
	await process_frame

func _has_visible_dead_sprite(player) -> bool:
	var dead_sprite = player.find_child("DeadSprite", true, false)
	return dead_sprite != null and dead_sprite.visible
