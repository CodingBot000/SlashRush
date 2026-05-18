extends Node

const INPUT_INTERPRETER_SCRIPT := preload("res://scripts/player/InputInterpreter.gd")
const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const GAME_HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")
const RESULT_PANEL_SCENE := preload("res://scenes/ui/ResultPanel.tscn")
const PAUSE_OVERLAY_SCENE := preload("res://scenes/ui/PauseOverlay.tscn")
const MAIN_MENU_SCENE_PATH := "res://scenes/game/MainMenu.tscn"
const GameBalance := preload("res://scripts/data/GameBalance.gd")
const PlayerLifeState := preload("res://scripts/game/PlayerLifeState.gd")
const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "progress"

var input_interpreter
var runner_stage
var boss_stage
var game_hud
var result_panel
var pause_overlay

var state := "title"
var current_score := 0
var current_coins := 0
var current_hp := GameBalance.STARTING_HP
var best_score := 0
var total_coins := 0

func _ready() -> void:
	randomize()
	_ensure_input_actions()
	_load_save()
	_build_nodes()
	if _should_start_in_boss():
		_start_boss_debug()
	else:
		_start_game()

func _build_nodes() -> void:
	input_interpreter = INPUT_INTERPRETER_SCRIPT.new()
	input_interpreter.name = "InputInterpreter"
	add_child(input_interpreter)
	input_interpreter.tap_detected.connect(_on_input_action.bind("tap"))
	input_interpreter.double_tap_detected.connect(_on_input_action.bind("double_tap"))
	input_interpreter.long_tap_detected.connect(_on_input_action.bind("long_tap"))
	input_interpreter.debug_restart_requested.connect(_start_game)

	runner_stage = RUNNER_STAGE_SCENE.instantiate()
	add_child(runner_stage)
	runner_stage.stats_changed.connect(_on_runner_stats_changed)
	runner_stage.feedback_requested.connect(_on_feedback_requested)
	runner_stage.run_finished.connect(_on_runner_finished)
	runner_stage.combo_increased.connect(_on_combo_increased)

	boss_stage = BOSS_STAGE_SCENE.instantiate()
	add_child(boss_stage)
	boss_stage.stats_changed.connect(_on_boss_stats_changed)
	boss_stage.feedback_requested.connect(_on_feedback_requested)
	boss_stage.boss_finished.connect(_on_boss_finished)
	boss_stage.fever_state_changed.connect(_on_boss_fever_state_changed)
	boss_stage.combo_increased.connect(_on_combo_increased)

	game_hud = GAME_HUD_SCENE.instantiate()
	add_child(game_hud)
	game_hud.debug_fever_fill_requested.connect(_on_debug_fever_fill_requested)
	game_hud.gameplay_pointer_pressed.connect(input_interpreter.handle_pointer_pressed)
	game_hud.gameplay_pointer_released.connect(input_interpreter.handle_pointer_released)

	result_panel = RESULT_PANEL_SCENE.instantiate()
	add_child(result_panel)
	result_panel.retry_requested.connect(_start_game)
	result_panel.quit_requested.connect(_quit_game)

	pause_overlay = PAUSE_OVERLAY_SCENE.instantiate()
	add_child(pause_overlay)
	pause_overlay.quit_requested.connect(_quit_game)

func _show_title() -> void:
	state = "title"
	pause_overlay.set_gameplay_active(false)
	input_interpreter.clear_action_blocked_provider()
	runner_stage.stop_run()
	runner_stage.visible = false
	boss_stage.stop_boss()
	boss_stage.visible = false
	game_hud.visible = false
	result_panel.show_title(best_score)

func _start_game() -> void:
	state = "runner"
	pause_overlay.set_gameplay_active(true)
	current_score = 0
	current_coins = 0
	current_hp = GameBalance.STARTING_HP
	input_interpreter.reset_action_state()
	input_interpreter.set_fever_mode_active(false)
	input_interpreter.set_action_blocked_provider(Callable(runner_stage, "is_player_hurt_locked"))
	boss_stage.stop_boss()
	boss_stage.visible = false
	result_panel.hide_panel()
	game_hud.visible = true
	game_hud.show_runner()
	runner_stage.start_run()

func _start_boss() -> void:
	state = "boss"
	pause_overlay.set_gameplay_active(true)
	input_interpreter.reset_action_state()
	input_interpreter.set_fever_mode_active(false)
	input_interpreter.set_action_blocked_provider(Callable(boss_stage, "is_player_hurt_locked"))
	runner_stage.visible = false
	result_panel.hide_panel()
	game_hud.visible = true
	game_hud.show_boss()
	boss_stage.start_boss(current_score, current_coins, current_hp)

func _start_boss_debug() -> void:
	current_score = 0
	current_coins = 0
	current_hp = GameBalance.STARTING_HP
	runner_stage.stop_run()
	boss_stage.stop_boss()
	_start_boss()

func _show_result(won: bool) -> void:
	if state == "result":
		return
	var finished_state := state
	var dead_overlay_data := _get_dead_overlay_data(finished_state, won)
	state = "result"
	pause_overlay.set_gameplay_active(false)
	input_interpreter.clear_action_blocked_provider()
	runner_stage.stop_run()
	runner_stage.visible = not won and finished_state == "runner"
	boss_stage.stop_boss()
	boss_stage.visible = not won and finished_state == "boss"
	game_hud.visible = false
	total_coins += max(0, current_coins)
	best_score = max(best_score, current_score)
	_save_game()
	if dead_overlay_data.is_empty():
		result_panel.show_result(won, current_score, current_coins, best_score)
	else:
		result_panel.show_result(
			won,
			current_score,
			current_coins,
			best_score,
			dead_overlay_data["position"],
			dead_overlay_data["scale"],
			dead_overlay_data["texture"]
		)

func _on_input_action(action: String) -> void:
	match state:
		"title":
			_start_game()
		"runner":
			runner_stage.handle_player_action(action)
		"boss":
			boss_stage.handle_player_action(action)
		"result":
			pass

func _on_runner_stats_changed(score: int, hp: int, combo: int, fever: int, is_fever: bool, coins: int) -> void:
	current_score = score
	current_coins = coins
	current_hp = hp
	input_interpreter.set_fever_mode_active(is_fever)
	game_hud.update_runner(score, hp, combo, fever, is_fever, coins)

func _on_runner_finished(payload: Dictionary) -> void:
	current_score = int(payload.get("score", current_score))
	current_coins = int(payload.get("coins", current_coins))
	current_hp = int(payload.get("hp", current_hp))
	if bool(payload.get("cleared", false)) and PlayerLifeState.can_player_continue(current_hp, _is_player_invincible()):
		_start_boss()
	else:
		_show_result(false)

func _on_boss_stats_changed(score: int, hp: int, boss_hp: int, max_boss_hp: int, pattern_hint: String, time_ratio: float) -> void:
	current_score = score
	current_hp = hp
	game_hud.update_boss(score, hp, boss_hp, max_boss_hp, pattern_hint, time_ratio)

func _on_boss_fever_state_changed(is_fever: bool) -> void:
	input_interpreter.set_fever_mode_active(is_fever)

func _on_boss_finished(payload: Dictionary) -> void:
	current_score = int(payload.get("score", current_score))
	current_coins = int(payload.get("coins", current_coins))
	current_hp = int(payload.get("hp", current_hp))
	_show_result(bool(payload.get("won", false)))

func _on_feedback_requested(text: String, color: Color) -> void:
	game_hud.show_feedback(text, color)

func _on_combo_increased(combo: int) -> void:
	game_hud.show_combo_impact(combo)

func _on_debug_fever_fill_requested() -> void:
	match state:
		"runner":
			if runner_stage and runner_stage.has_method("debug_fill_fever"):
				runner_stage.debug_fill_fever()
		"boss":
			if boss_stage and boss_stage.has_method("debug_fill_fever"):
				boss_stage.debug_fill_fever()

func _quit_game() -> void:
	pause_overlay.set_gameplay_active(false)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _get_dead_overlay_data(finished_state: String, won: bool) -> Dictionary:
	if won:
		return {}

	var finished_player = null
	if finished_state == "runner" and runner_stage:
		finished_player = runner_stage.player
	elif finished_state == "boss" and boss_stage:
		finished_player = boss_stage.player

	if finished_player == null:
		return {}

	var dead_sprite = finished_player.find_child("DeadSprite", true, false)
	if not (dead_sprite is Sprite2D) or dead_sprite.texture == null or not dead_sprite.visible:
		return {}

	var transform: Transform2D = dead_sprite.get_global_transform_with_canvas()
	return {
		"position": transform.origin,
		"scale": transform.get_scale(),
		"texture": dead_sprite.texture
	}

func _ensure_input_actions() -> void:
	_add_action_if_missing("tap_action")
	_add_key_event("tap_action", KEY_SPACE)
	_remove_mouse_event("tap_action", MOUSE_BUTTON_LEFT)

	_add_action_if_missing("alt_slice")
	_add_mouse_event("alt_slice", MOUSE_BUTTON_RIGHT)
	_add_key_event("alt_slice", KEY_SHIFT)
	_add_key_event("alt_slice", KEY_CTRL)

	_add_action_if_missing("debug_restart")
	_add_key_event("debug_restart", KEY_R)

func _add_action_if_missing(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

func _add_key_event(action_name: String, keycode: Key) -> void:
	if _action_has_key(action_name, keycode):
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

func _add_mouse_event(action_name: String, button_index: MouseButton) -> void:
	if _action_has_mouse(action_name, button_index):
		return
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

func _action_has_key(action_name: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false

func _action_has_mouse(action_name: String, button_index: MouseButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return true
	return false

func _remove_mouse_event(action_name: String, button_index: MouseButton) -> void:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			InputMap.action_erase_event(action_name, event)

func _load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value(SAVE_SECTION, "best_score", 0))
		total_coins = int(config.get_value(SAVE_SECTION, "coins", 0))

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "best_score", best_score)
	config.set_value(SAVE_SECTION, "coins", total_coins)
	config.save(SAVE_PATH)

func _is_player_invincible() -> bool:
	var debug_flags := get_node_or_null("/root/DebugFlags")
	return debug_flags != null and bool(debug_flags.player_invincible)

func _should_start_in_boss() -> bool:
	var debug_flags := get_node_or_null("/root/DebugFlags")
	return debug_flags != null and bool(debug_flags.start_in_boss)
