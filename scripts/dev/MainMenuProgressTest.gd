extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/game/MainMenu.tscn")
const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "progress"

var backup_config := ConfigFile.new()
var had_save := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	had_save = backup_config.load(SAVE_PATH) == OK

	_write_progress(77, 1200)
	var menu = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame
	if not _has_stats_text(menu, "Coins: 77.   Best Score: 1200"):
		_fail("MainMenu should show saved coins and best score.")
		return
	menu.queue_free()
	await process_frame

	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	main.current_score = 1500
	main.current_coins = 23
	main.state = "runner"
	main._show_result(false)
	await process_frame
	main.queue_free()
	await process_frame

	var progress := _load_progress()
	if int(progress.get("coins", 0)) != 100:
		_fail("Game results should add final coins to saved coins.")
		return
	if int(progress.get("best_score", 0)) != 1500:
		_fail("Game results should save a new best score.")
		return

	var lower_score_main = MAIN_SCENE.instantiate()
	root.add_child(lower_score_main)
	await process_frame
	lower_score_main.current_score = 900
	lower_score_main.current_coins = 5
	lower_score_main.state = "runner"
	lower_score_main._show_result(false)
	await process_frame
	lower_score_main.queue_free()
	await process_frame

	progress = _load_progress()
	if int(progress.get("coins", 0)) != 105:
		_fail("Later game results should continue accumulating coins.")
		return
	if int(progress.get("best_score", 0)) != 1500:
		_fail("Lower later scores should not replace the best score.")
		return

	var updated_menu = MAIN_MENU_SCENE.instantiate()
	root.add_child(updated_menu)
	await process_frame
	if not _has_stats_text(updated_menu, "Coins: 105.   Best Score: 1500"):
		_fail("MainMenu should show updated saved progress.")
		return
	updated_menu.queue_free()
	await process_frame

	_restore_save()
	quit()

func _has_stats_text(menu: Node, expected_text: String) -> bool:
	var label = menu.find_child("StatsLabel", true, false)
	return label is Label and label.text == expected_text

func _write_progress(coins: int, best_score: int) -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "coins", coins)
	config.set_value(SAVE_SECTION, "best_score", best_score)
	config.save(SAVE_PATH)

func _load_progress() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return {}
	return {
		"coins": int(config.get_value(SAVE_SECTION, "coins", 0)),
		"best_score": int(config.get_value(SAVE_SECTION, "best_score", 0))
	}

func _restore_save() -> void:
	if had_save:
		backup_config.save(SAVE_PATH)
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _fail(message: String) -> void:
	_restore_save()
	push_error(message)
	quit(1)
