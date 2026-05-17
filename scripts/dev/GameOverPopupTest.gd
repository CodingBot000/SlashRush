extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
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

	quit()
