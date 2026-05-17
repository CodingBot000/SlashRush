extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._start_game()
	for index in range(180):
		if index == 120:
			main.runner_stage.handle_player_action("tap")
		await process_frame

	main.current_score = main.runner_stage.score
	main.current_coins = main.runner_stage.coins
	main.current_hp = max(1, main.runner_stage.hp)
	main.runner_stage.stop_run()
	main._start_boss()
	await process_frame

	main.boss_stage.handle_player_action("tap")
	await process_frame
	main.boss_stage.handle_player_action("tap")
	await process_frame
	main.boss_stage.handle_player_action("double_tap")
	await process_frame
	main.boss_stage.handle_player_action("long_tap")

	for _index in range(90):
		await process_frame

	quit()
