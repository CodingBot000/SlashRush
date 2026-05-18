extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	var fever_button = main.game_hud.find_child("DebugFeverFillButton", true, false)
	if fever_button == null:
		_fail("Main HUD should expose a debug fever fill button.")
		return

	if main.state != "runner":
		_fail("Main should start in runner state for fever fill testing.")
		return

	fever_button.emit_signal("pressed")
	if not main.runner_stage.is_fever:
		_fail("Debug fever fill button should immediately start runner fever.")
		return
	if main.runner_stage.fever != GameBalance.FEVER_MAX:
		_fail("Debug fever fill button should fill the runner fever gauge.")
		return
	await process_frame

	main.current_score = main.runner_stage.score
	main.current_coins = main.runner_stage.coins
	main.current_hp = max(1, main.runner_stage.hp)
	main.runner_stage.stop_run()
	main._start_boss()
	await process_frame

	fever_button.emit_signal("pressed")
	await process_frame
	if not main.boss_stage.boss_fever_mode.active:
		_fail("Debug fever fill button should immediately start boss fever in boss state.")
		return

	main.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
