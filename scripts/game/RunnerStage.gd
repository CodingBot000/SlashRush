extends Node2D
class_name RunnerStage

signal stats_changed(score, hp, combo, fever, is_fever, coins)
signal feedback_requested(text, color)
signal run_finished(payload)
signal combo_increased(combo)

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const INPUT_INTERPRETER_SCRIPT := preload("res://scripts/player/InputInterpreter.gd")
const GAME_HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")
const PlayerLifeState := preload("res://scripts/game/PlayerLifeState.gd")
const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const PARALLAX_SCROLLER_SCRIPT := preload("res://scripts/game/ParallaxScroller.gd")
const GROUND_LOOPER_SCRIPT := preload("res://scripts/game/GroundLooper.gd")
const OBJECT_SPAWNER_SCRIPT := preload("res://scripts/game/ObjectSpawner.gd")
const RUNNER_FEVER_MODE_SCRIPT := preload("res://scripts/game/RunnerFeverMode.gd")
const SLICE_EFFECT_FACTORY_SCRIPT := preload("res://scripts/objects/SliceEffectFactory.gd")
const SLICE_CUT_SEQUENCE_LENGTH := 30
const SLICE_START_ANGLE_MIN := 240.0
const SLICE_START_ANGLE_MAX := 270.0
const SLICE_END_ANGLE_MIN := 75.0
const SLICE_END_ANGLE_MAX := 90.0

var world_root: Node2D
var object_root: Node2D
var piece_root: Node2D
var player
var standalone_input_interpreter
var standalone_hud
var standalone_boss_stage
var parallax
var ground
var spawner
var fever_mode
var slice_factory

var score := 0
var coins := 0
var hp := GameBalance.STARTING_HP
var combo := 0
var fever := 0
var is_fever := false
var fever_timer := 0.0
var run_elapsed := 0.0

var active := false
var hitstop_timer := 0.0
var hurt_slow_timer := 0.0
var shake_timer := 0.0
var shake_strength := 0.0
var _fever_rush_pause_applied := false
var slice_cut_sequence := []
var slice_cut_index := 0
var slice_cut_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_build_scene()
	visible = false
	call_deferred("_start_if_standalone")

func start_run() -> void:
	_clear_children(object_root)
	_clear_children(piece_root)
	score = 0
	coins = 0
	hp = GameBalance.STARTING_HP
	combo = 0
	fever = 0
	is_fever = false
	fever_timer = 0.0
	run_elapsed = 0.0
	active = true
	hitstop_timer = 0.0
	hurt_slow_timer = 0.0
	_fever_rush_pause_applied = false
	if player and player.has_method("play_run"):
		player.play_run()
	fever_mode.reset()
	_sync_fever_state()
	if standalone_input_interpreter:
		standalone_input_interpreter.reset_action_state()
		standalone_input_interpreter.set_fever_mode_active(false)
	_build_slice_cut_sequence()
	visible = true
	spawner.start()
	_sync_runner_footsteps()
	_emit_stats()
	_emit_feedback("TAP / TAP TAP / HOLD", Color(1.0, 1.0, 1.0, 1.0))

func stop_run() -> void:
	active = false
	_sync_runner_footsteps()
	spawner.stop()
	if fever_mode:
		fever_mode.reset()
	_sync_fever_state()

func handle_player_action(action: String) -> void:
	if not active:
		return
	if is_player_hurt_locked():
		return
	if action == "tap" or action == "double_tap" or action == "long_tap":
		player.play_slash(action == "long_tap")

	if _is_runner_fever_active():
		_handle_fever_player_action()
		return

	_handle_normal_player_action(action)

func _handle_normal_player_action(action: String) -> void:
	var attack_targets := _get_zone_attack_objects()
	if not attack_targets.is_empty():
		_handle_zone_attack_targets(action, attack_targets)
		return

	var target = _get_nearest_zone_object()
	if target == null:
		return

	if target.is_good_item:
		if is_fever:
			_collect_fever_sliced_good_item(target)
		else:
			_break_good_item(target)
		return

	var required := String(target.required_action)
	if _action_matches(required, action):
		_success_object(target, false, false)
	elif required == "double_tap" and action == "tap":
		_spawn_world_text("TAP TAP!", target.get_slice_center_global() + Vector2(-35.0, -70.0), Color.html("#ffd84a"))
	elif required == "long_tap" and action == "tap":
		_spawn_world_text("HOLD!", target.get_slice_center_global() + Vector2(-34.0, -70.0), Color.html("#9ec8ff"))
	else:
		_fail_object(target, true)

func _process(delta: float) -> void:
	if not active:
		return
	run_elapsed += delta
	if run_elapsed >= GameBalance.RUNNER_DURATION_SECONDS:
		_finish_run(true)
		return

	_update_fever(delta)
	_update_shake(delta)
	_update_hurt_slow(delta)
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	var scroll_multiplier := _get_scroll_speed_multiplier() * _get_hurt_background_speed_multiplier()
	parallax.process_scroll(delta, GameBalance.MAP_SCROLL_SPEED * scroll_multiplier)
	ground.process_scroll(delta, GameBalance.GROUND_SCROLL_SPEED * scroll_multiplier)
	_move_objects(delta, _get_hurt_object_speed_multiplier())

func _build_scene() -> void:
	world_root = Node2D.new()
	world_root.name = "WorldRoot"
	add_child(world_root)

	parallax = PARALLAX_SCROLLER_SCRIPT.new()
	parallax.name = "ParallaxScroller"
	world_root.add_child(parallax)
	parallax.setup()

	ground = GROUND_LOOPER_SCRIPT.new()
	ground.name = "GroundLooper"
	world_root.add_child(ground)
	ground.setup()

	object_root = Node2D.new()
	object_root.name = "ObjectRoot"
	world_root.add_child(object_root)

	piece_root = Node2D.new()
	piece_root.name = "SlicePieceRoot"
	world_root.add_child(piece_root)

	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector2(210.0, GameBalance.GAMEPLAY_BASELINE_Y)
	world_root.add_child(player)

	_add_action_zone_visual()

	spawner = OBJECT_SPAWNER_SCRIPT.new()
	spawner.name = "ObjectSpawner"
	add_child(spawner)
	spawner.set_player_health_provider(Callable(self, "_get_spawn_player_hp"), Callable(self, "_get_spawn_player_max_hp"))
	spawner.object_spawned.connect(_on_object_spawned)

	fever_mode = RUNNER_FEVER_MODE_SCRIPT.new()
	fever_mode.name = "RunnerFeverMode"
	add_child(fever_mode)
	fever_mode.started.connect(_on_runner_fever_started)
	fever_mode.ended.connect(_on_runner_fever_ended)
	fever_mode.changed.connect(_on_runner_fever_changed)

	slice_factory = SLICE_EFFECT_FACTORY_SCRIPT.new()
	slice_factory.name = "SliceEffectFactory"
	add_child(slice_factory)

func _start_if_standalone() -> void:
	if get_tree().current_scene != self:
		return
	_build_standalone_input()
	_build_standalone_hud()
	run_finished.connect(_on_standalone_run_finished)
	start_run()

func _build_standalone_input() -> void:
	if standalone_input_interpreter:
		return
	_ensure_standalone_input_actions()
	standalone_input_interpreter = INPUT_INTERPRETER_SCRIPT.new()
	standalone_input_interpreter.name = "StandaloneInputInterpreter"
	add_child(standalone_input_interpreter)
	standalone_input_interpreter.tap_detected.connect(_handle_standalone_player_action.bind("tap"))
	standalone_input_interpreter.double_tap_detected.connect(_handle_standalone_player_action.bind("double_tap"))
	standalone_input_interpreter.long_tap_detected.connect(_handle_standalone_player_action.bind("long_tap"))
	standalone_input_interpreter.debug_restart_requested.connect(_restart_standalone_run)
	standalone_input_interpreter.set_action_blocked_provider(Callable(self, "_is_standalone_player_action_blocked"))

func _build_standalone_hud() -> void:
	if standalone_hud:
		return
	standalone_hud = GAME_HUD_SCENE.instantiate()
	standalone_hud.name = "StandaloneGameHUD"
	add_child(standalone_hud)
	stats_changed.connect(standalone_hud.update_runner)
	feedback_requested.connect(standalone_hud.show_feedback)
	combo_increased.connect(standalone_hud.show_combo_impact)
	standalone_hud.show_runner()

func _handle_standalone_player_action(action: String) -> void:
	if standalone_boss_stage and standalone_boss_stage.active:
		standalone_boss_stage.handle_player_action(action)
	else:
		handle_player_action(action)

func _restart_standalone_run() -> void:
	if standalone_boss_stage:
		standalone_boss_stage.queue_free()
		standalone_boss_stage = null
	if standalone_hud:
		standalone_hud.show_runner()
	start_run()

func _on_standalone_run_finished(payload: Dictionary) -> void:
	if not bool(payload.get("cleared", false)) or PlayerLifeState.is_player_dead(int(payload.get("hp", hp)), _is_player_invincible()):
		return
	call_deferred("_start_standalone_boss", payload)

func _start_standalone_boss(payload: Dictionary) -> void:
	if standalone_boss_stage:
		standalone_boss_stage.queue_free()

	if standalone_input_interpreter:
		standalone_input_interpreter.reset_action_state()
		standalone_input_interpreter.set_fever_mode_active(false)

	standalone_boss_stage = BOSS_STAGE_SCENE.instantiate()
	standalone_boss_stage.name = "StandaloneBossStage"
	add_child(standalone_boss_stage)
	standalone_boss_stage.stats_changed.connect(standalone_hud.update_boss)
	standalone_boss_stage.feedback_requested.connect(standalone_hud.show_feedback)
	standalone_boss_stage.boss_finished.connect(_on_standalone_boss_finished)
	standalone_boss_stage.fever_state_changed.connect(_on_standalone_boss_fever_state_changed)
	standalone_boss_stage.combo_increased.connect(standalone_hud.show_combo_impact)

	if standalone_hud:
		standalone_hud.show_boss()

	standalone_boss_stage.start_boss(
		int(payload.get("score", score)),
		int(payload.get("coins", coins)),
		int(payload.get("hp", hp))
	)

func _on_standalone_boss_finished(_payload: Dictionary) -> void:
	if standalone_boss_stage:
		standalone_boss_stage.stop_boss()

func _on_standalone_boss_fever_state_changed(active_value: bool) -> void:
	if standalone_input_interpreter:
		standalone_input_interpreter.set_fever_mode_active(active_value)

func _is_standalone_player_action_blocked() -> bool:
	if standalone_boss_stage and standalone_boss_stage.active and standalone_boss_stage.has_method("is_player_hurt_locked"):
		return standalone_boss_stage.is_player_hurt_locked()
	return is_player_hurt_locked()

func _ensure_standalone_input_actions() -> void:
	_add_action_if_missing("tap_action")
	_add_key_event("tap_action", KEY_SPACE)
	_add_mouse_event("tap_action", MOUSE_BUTTON_LEFT)
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

func _add_action_zone_visual() -> void:
	var zone := Polygon2D.new()
	zone.name = "ActionZoneGuide"
	zone.position = GameBalance.ACTION_ZONE_CENTER
	zone.z_index = 4096
	zone.color = Color(1.0, 0.0, 0.0, 0.28)
	var half: Vector2 = GameBalance.ACTION_ZONE_SIZE * 0.5
	zone.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	world_root.add_child(zone)

func _on_object_spawned(object) -> void:
	object_root.add_child(object)

func _get_spawn_player_hp() -> int:
	return hp

func _get_spawn_player_max_hp() -> int:
	return GameBalance.MAX_HP

func _move_objects(delta: float, speed_multiplier: float = 1.0) -> void:
	for child in object_root.get_children():
		if not child.has_method("get_slice_color"):
			continue
		var object = child
		if object.handled:
			continue
		object.position.x -= GameBalance.OBJECT_SPEED * speed_multiplier * delta
		if object.position.x < GameBalance.ACTION_ZONE_CENTER.x - GameBalance.ACTION_ZONE_SIZE.x * 0.5 - 70.0:
			_handle_passed_object(object)

func _handle_fever_player_action() -> void:
	if is_player_hurt_locked():
		return
	var targets := _get_zone_objects()
	for target in targets:
		if target.is_good_item:
			_collect_fever_sliced_good_item(target)
		else:
			_success_object(target, false, false)

func _handle_zone_attack_targets(action: String, targets: Array) -> void:
	var success_targets := []
	var prompt_targets := []
	var fail_targets := []
	for target in targets:
		var required := String(target.required_action)
		if _action_matches(required, action):
			success_targets.append(target)
		elif required == "double_tap" and action == "tap":
			prompt_targets.append({"target": target, "text": "TAP TAP!", "offset": Vector2(-35.0, -70.0), "color": Color.html("#ffd84a")})
		elif required == "long_tap" and action == "tap":
			prompt_targets.append({"target": target, "text": "HOLD!", "offset": Vector2(-34.0, -70.0), "color": Color.html("#9ec8ff")})
		else:
			fail_targets.append(target)

	for target in success_targets:
		_success_object(target, false, false)

	for prompt in prompt_targets:
		var target = prompt["target"]
		if target.handled:
			continue
		_spawn_world_text(
			String(prompt["text"]),
			target.get_slice_center_global() + prompt["offset"],
			prompt["color"]
		)

	for target in fail_targets:
		if not active:
			return
		_fail_object(target, true)

func _get_nearest_zone_object():
	var nearest = null
	var nearest_distance := INF
	for child in object_root.get_children():
		if not child.has_method("get_slice_color"):
			continue
		var object = child
		if object.handled:
			continue
		if not _is_in_action_zone(object):
			continue
		var distance: float = abs(object.position.x - GameBalance.ACTION_ZONE_CENTER.x)
		if distance < nearest_distance:
			nearest = object
			nearest_distance = distance
	return nearest

func _get_zone_objects() -> Array:
	var objects := []
	for child in object_root.get_children():
		if not child.has_method("get_slice_color"):
			continue
		var object = child
		if object.handled:
			continue
		if _is_in_action_zone(object):
			objects.append(object)
	return objects

func _get_zone_attack_objects() -> Array:
	var objects := []
	for object in _get_zone_objects():
		if object.is_good_item:
			continue
		objects.append(object)
	return objects

func _is_in_action_zone(object) -> bool:
	var center: Vector2 = GameBalance.ACTION_ZONE_CENTER
	var half: Vector2 = GameBalance.ACTION_ZONE_SIZE * 0.5
	return abs(object.position.x - center.x) <= half.x and abs(object.position.y - center.y) <= half.y

func _action_matches(required: String, action: String) -> bool:
	if _is_runner_fever_active():
		return true
	if required == action:
		return true
	if required == "tap" and action == "double_tap":
		return true
	return false

func _counts_for_combo(object) -> bool:
	var object_type := String(object.object_type)
	return object_type.begins_with("enemy") or object_type == "bomb"

func _success_object(object, automatic: bool, play_player_slash: bool = true) -> void:
	if object.handled:
		return
	if is_player_hurt_locked():
		_discard_object_during_hurt(object)
		return
	object.handled = true
	object.disable_collision()
	var multiplier := 2 if _is_runner_fever_active() else 1
	score += object.score_value * multiplier
	if not _is_runner_fever_active():
		_gain_runner_fever(object.fever_value)
	if _counts_for_combo(object):
		combo += 1
		combo_increased.emit(combo)
	slice_factory.spawn_slice(piece_root, object.get_slice_center_global(), object.get_slice_color(), object.get_slice_size(), object.object_type == "enemy_armor", object.get_slice_texture(), _get_next_slice_cut())
	if play_player_slash:
		player.play_slash(object.required_action == "long_tap" or automatic)
	_spawn_world_text("+%d" % (object.score_value * multiplier), object.get_slice_center_global() + Vector2(-24.0, -70.0), Color(1.0, 1.0, 1.0, 1.0))
	object.queue_free()
	_start_hitstop(0.05, 4.0)
	_emit_stats()

func _fail_object(object, sliced_wrong: bool) -> void:
	if object.handled:
		return
	if is_player_hurt_locked():
		_discard_object_during_hurt(object)
		return
	object.handled = true
	combo = 0
	hp -= object.damage_on_fail
	AudioHooksScript.play_player_hurt(self)
	var player_dead := PlayerLifeState.is_player_dead(hp, _is_player_invincible())
	if sliced_wrong:
		slice_factory.spawn_slice(piece_root, object.get_slice_center_global(), Color.html("#c83f3f"), object.get_slice_size(), false, object.get_slice_texture(), _get_next_slice_cut())
		_spawn_world_text("MISS!", object.get_slice_center_global() + Vector2(-34.0, -70.0), Color.html("#ff6b6b"))
	else:
		_spawn_world_text("-HP", object.get_slice_center_global() + Vector2(-28.0, -70.0), Color.html("#ff6b6b"))
	if player_dead:
		PlayerLifeState.show_dead_visual(player)
	else:
		player.flash_hurt()
	_start_hurt_slow()
	object.queue_free()
	_start_hitstop(0.04, 5.0)
	_emit_stats()
	if player_dead:
		_finish_run(false)

func _handle_passed_object(object) -> void:
	if is_player_hurt_locked():
		_discard_object_during_hurt(object)
		return
	if _is_runner_fever_active():
		_discard_fever_missed_object(object)
	elif object.is_good_item:
		_collect_good_item(object, false)
	else:
		_fail_object(object, false)

func _discard_fever_missed_object(object) -> void:
	if object.handled:
		return
	object.handled = true
	object.queue_free()

func _discard_object_during_hurt(object) -> void:
	if object.handled:
		return
	object.handled = true
	object.queue_free()

func _collect_good_item(object, automatic: bool) -> void:
	if object.handled:
		return
	if is_player_hurt_locked():
		_discard_object_during_hurt(object)
		return
	object.handled = true
	AudioHooksScript.play_pickup_item(self)
	if object.object_type == "coin":
		coins += object.score_value
	var heal_was_full: bool = object.object_type == "heal" and hp >= GameBalance.MAX_HP
	if object.object_type == "heal":
		hp = min(GameBalance.MAX_HP, hp + 1)
	score += object.score_value * (2 if _is_runner_fever_active() else 1)
	if not _is_runner_fever_active():
		if object.object_type == "fever_orb":
			_start_fever()
		else:
			_gain_runner_fever(object.fever_value)
	var text := "GET" if automatic else "+%d" % object.score_value
	if object.object_type == "heal":
		text = "MAX" if heal_was_full else "+HP"
	_spawn_world_text(text, object.get_slice_center_global() + Vector2(-93.0, -88.0), Color.html("#76ff9c"), 48, Vector2(260.0, 80.0), true)
	object.queue_free()
	_emit_stats()

func _collect_fever_sliced_good_item(object) -> void:
	if object.object_type == "heal" and hp >= GameBalance.MAX_HP:
		_collect_good_item_as_fever_coin_bonus(object)
	elif object.object_type == "fever_orb":
		_collect_good_item_as_fever_coin_bonus(object)
	else:
		_collect_good_item(object, false)

func _collect_good_item_as_fever_coin_bonus(object) -> void:
	if object.handled:
		return
	if is_player_hurt_locked():
		_discard_object_during_hurt(object)
		return
	object.handled = true
	AudioHooksScript.play_pickup_item(self)
	var coin_bonus := GameBalance.FEVER_GOOD_ITEM_SLICE_COIN_BONUS
	coins += coin_bonus
	score += coin_bonus * 2
	_spawn_world_text("+%d" % coin_bonus, object.get_slice_center_global() + Vector2(-93.0, -88.0), Color.html("#ffd84a"), 48, Vector2(260.0, 80.0), true)
	object.queue_free()
	_emit_stats()

func _break_good_item(object) -> void:
	if object.handled:
		return
	if is_player_hurt_locked():
		_discard_object_during_hurt(object)
		return
	object.handled = true
	combo = 0
	if not _is_runner_fever_active():
		_penalize_runner_fever(GameBalance.GOOD_ITEM_BREAK_FEVER_PENALTY)
	slice_factory.spawn_slice(piece_root, object.get_slice_center_global(), object.get_slice_color().darkened(0.18), object.get_slice_size(), false, object.get_slice_texture(), _get_next_slice_cut())
	_spawn_world_text("BROKEN!", object.get_slice_center_global() + Vector2(-58.0, -70.0), Color.html("#ffdf6d"))
	object.queue_free()
	_start_hitstop(0.04, 3.0)
	_emit_stats()

func _start_fever() -> void:
	fever_mode.start()

func _update_fever(delta: float) -> void:
	if not fever_mode:
		return
	var was_active: bool = fever_mode.active
	fever_mode.update(delta)
	_sync_fever_state()
	if fever_mode.active and not _fever_rush_pause_applied and fever_timer <= GameBalance.FEVER_RUSH_SPAWN_STOP_BEFORE_END:
		_fever_rush_pause_applied = true
		spawner.set_fever_rush_enabled(false)
		spawner.pause_spawning(GameBalance.FEVER_RUSH_SPAWN_PAUSE_DURATION)
	else:
		spawner.set_fever_rush_enabled(fever_mode.should_spawn_rush())
	if was_active or fever_mode.active:
		_emit_stats()

func _gain_runner_fever(amount: int) -> void:
	if not fever_mode:
		fever = min(GameBalance.FEVER_MAX, fever + amount)
		if fever >= GameBalance.FEVER_MAX:
			_start_fever()
		return
	fever_mode.add_fever(amount)
	_sync_fever_state()

func _penalize_runner_fever(amount: int) -> void:
	if not fever_mode:
		fever = max(0, fever - amount)
		return
	fever_mode.fever = fever
	fever_mode.penalize_fever(amount)
	_sync_fever_state()

func _on_runner_fever_started() -> void:
	_sync_fever_state()
	_fever_rush_pause_applied = false
	_clear_active_normal_objects()
	spawner.set_fever_rush_enabled(true)
	_emit_feedback("FEVER!", Color.html("#5ef3ff"))
	_start_hitstop(0.08, 7.0)
	_emit_stats()

func _on_runner_fever_ended() -> void:
	_sync_fever_state()
	spawner.set_fever_rush_enabled(false)
	spawner.mark_fever_ended()
	spawner.pause_spawning(GameBalance.FEVER_END_NORMAL_SPAWN_DELAY)
	_clear_fever_rush_objects()
	_emit_feedback("FEVER END", Color.html("#d9f7ff"))
	_emit_stats()

func _clear_fever_rush_objects() -> void:
	for child in object_root.get_children():
		if not child.has_meta("fever_rush_spawn"):
			continue
		if child.get_meta("fever_rush_spawn") != true:
			continue
		if child.handled:
			continue
		child.handled = true
		child.queue_free()

func _clear_active_normal_objects() -> void:
	for child in object_root.get_children():
		if not child.has_method("get_slice_color"):
			continue
		if child.has_meta("fever_rush_spawn") and child.get_meta("fever_rush_spawn") == true:
			continue
		if child.handled:
			continue
		child.handled = true
		child.queue_free()

func _on_runner_fever_changed(fever_value: int, active_value: bool, time_left_value: float) -> void:
	fever = fever_value
	is_fever = active_value
	fever_timer = time_left_value

func _sync_fever_state() -> void:
	if not fever_mode:
		return
	fever = fever_mode.fever
	is_fever = fever_mode.active
	fever_timer = fever_mode.time_left

func _is_runner_fever_active() -> bool:
	return is_fever

func is_player_hurt_locked() -> bool:
	return active and hurt_slow_timer > 0.0

func _get_scroll_speed_multiplier() -> float:
	return GameBalance.RUNNER_FEVER_SCROLL_SPEED_MULTIPLIER if _is_runner_fever_active() else 1.0

func _start_hurt_slow() -> void:
	hurt_slow_timer = max(hurt_slow_timer, GameBalance.PLAYER_HURT_SLOW_DURATION)
	_sync_runner_footsteps()

func _update_hurt_slow(delta: float) -> void:
	if hurt_slow_timer <= 0.0:
		return
	hurt_slow_timer = max(0.0, hurt_slow_timer - delta)
	_sync_runner_footsteps()

func _get_hurt_background_speed_multiplier() -> float:
	return GameBalance.PLAYER_HURT_BACKGROUND_SPEED_MULTIPLIER if hurt_slow_timer > 0.0 else 1.0

func _get_hurt_object_speed_multiplier() -> float:
	return GameBalance.PLAYER_HURT_OBJECT_SPEED_MULTIPLIER if hurt_slow_timer > 0.0 else 1.0

func _start_hitstop(duration: float, strength: float) -> void:
	hitstop_timer = max(hitstop_timer, duration)
	shake_timer = max(shake_timer, duration * 2.0)
	shake_strength = max(shake_strength, strength)

func _update_shake(delta: float) -> void:
	if shake_timer <= 0.0:
		world_root.position = Vector2.ZERO
		return
	shake_timer -= delta
	world_root.position = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	if shake_timer <= 0.0:
		world_root.position = Vector2.ZERO
		shake_strength = 0.0

func _finish_run(cleared: bool) -> void:
	if not active:
		return
	stop_run()
	run_finished.emit({
		"cleared": cleared,
		"score": score,
		"coins": coins,
		"hp": hp
	})

func _emit_stats() -> void:
	if standalone_input_interpreter:
		standalone_input_interpreter.set_fever_mode_active(is_fever)
	stats_changed.emit(score, hp, combo, fever, is_fever, coins)

func _emit_feedback(text: String, color: Color) -> void:
	feedback_requested.emit(text, color)

func _build_slice_cut_sequence() -> void:
	slice_cut_rng.randomize()
	slice_cut_sequence.clear()
	for _index in range(SLICE_CUT_SEQUENCE_LENGTH):
		slice_cut_sequence.append({
			"start_angle": slice_cut_rng.randf_range(SLICE_START_ANGLE_MIN, SLICE_START_ANGLE_MAX),
			"end_angle": slice_cut_rng.randf_range(SLICE_END_ANGLE_MIN, SLICE_END_ANGLE_MAX)
		})
	slice_cut_index = 0

func _get_next_slice_cut() -> Dictionary:
	if slice_cut_sequence.is_empty():
		_build_slice_cut_sequence()

	var cut: Dictionary = slice_cut_sequence[slice_cut_index]
	slice_cut_index = (slice_cut_index + 1) % slice_cut_sequence.size()
	return cut

func _is_player_invincible() -> bool:
	var debug_flags := get_node_or_null("/root/DebugFlags")
	return debug_flags != null and bool(debug_flags.player_invincible)

func _sync_runner_footsteps() -> void:
	var player_dead := PlayerLifeState.is_player_dead(hp, _is_player_invincible())
	AudioHooksScript.set_runner_footsteps_active(self, active and hurt_slow_timer <= 0.0 and not player_dead)

func _spawn_world_text(text: String, pos: Vector2, color: Color, font_size: int = 24, label_size: Vector2 = Vector2(130.0, 40.0), emphasized: bool = false) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if emphasized:
		label.add_theme_constant_override("outline_size", 5)
		label.add_theme_color_override("font_outline_color", Color(0.05, 0.11, 0.08, 0.95))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 3)
	world_root.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -42.0), 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(label, "queue_free"))

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
