extends Node2D
class_name BossStage

signal stats_changed(score, hp, boss_hp, max_boss_hp, pattern_hint, time_ratio)
signal feedback_requested(text, color)
signal boss_finished(payload)
signal fever_state_changed(is_fever)
signal combo_increased(combo)

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ROBOT_SAMURAI_BOSS_SCENE := preload("res://scenes/boss/RobotSamuraiBoss.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")
const PlayerLifeState := preload("res://scripts/game/PlayerLifeState.gd")
const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const SLICE_EFFECT_FACTORY_SCRIPT := preload("res://scripts/objects/SliceEffectFactory.gd")
const BOSS_FEVER_MODE_SCRIPT := preload("res://scripts/game/BossFeverMode.gd")
const BOSS_BACKGROUND_PATH := "res://assets/background/stage1/boss_background.png"
const BOSS_BACKGROUND_ROTATION_SPEED := 0.05

var player
var boss_background_fill: ColorRect
var boss_background_sprite: Sprite2D
var boss_root: Node2D
var boss_visual: Node2D
var piece_root: Node2D
var slice_factory
var pattern_label: Label
var timer_fill: Polygon2D
var boss_fever_mode

var active := false
var score := 0
var coins := 0
var hp := GameBalance.STARTING_HP
var boss_hp := GameBalance.BOSS_MAX_HP
var boss_combo := 0
var current_pattern := {}
var pattern_time_left := 0.0
var pattern_total_time := 1.0
var player_hurt_timer := 0.0
var phase1_patterns: Array = []
var phase2_patterns: Array = []
var phase1_pattern_index := 0
var phase2_pattern_index := 0
var current_phase := 1

enum BossPatternCode {
	RIGHT_ARM_SLAM = 1,
	BOTH_ARM_SLAM = 2,
	CORE_CHARGE = 3,
	WAIT = 4
}

const BOSS_PHASE_1 := 1
const BOSS_PHASE_2 := 2
const BOSS_PHASE_DECK_SIZE := 30
const PHASE_1_TAP_COUNT := 10
const PHASE_1_DOUBLE_TAP_COUNT := 8
const PHASE_1_LONG_TAP_COUNT := 8
const PHASE_1_WAIT_COUNT := 4
const PHASE_2_TAP_COUNT := 4
const PHASE_2_DOUBLE_TAP_COUNT := 11
const PHASE_2_LONG_TAP_COUNT := 11
const PHASE_2_WAIT_COUNT := 4

func _ready() -> void:
	_build_scene()
	visible = false

func start_boss(start_score: int, start_coins: int, start_hp: int) -> void:
	_clear_children(piece_root)
	score = start_score
	coins = start_coins
	hp = min(start_hp, GameBalance.MAX_HP) if _is_player_invincible() else clampi(start_hp, 1, GameBalance.MAX_HP)
	boss_hp = GameBalance.BOSS_MAX_HP
	boss_combo = 0
	player_hurt_timer = 0.0
	if player and player.has_method("play_run"):
		player.play_run()
	_build_phase_pattern_decks()
	phase1_pattern_index = 0
	phase2_pattern_index = 0
	current_phase = BOSS_PHASE_1
	boss_fever_mode.reset()
	if boss_visual:
		boss_visual.set_process(true)
	active = true
	visible = true
	fever_state_changed.emit(false)
	feedback_requested.emit("BOSS", Color.html("#ffef8a"))
	_next_pattern()

func stop_boss() -> void:
	active = false
	visible = false
	player_hurt_timer = 0.0
	if boss_fever_mode:
		boss_fever_mode.reset()
	if boss_visual:
		boss_visual.set_process(false)
	fever_state_changed.emit(false)

func handle_player_action(action: String) -> void:
	if not active or current_pattern.is_empty():
		return
	if is_player_hurt_locked():
		return
	player.play_slash(action == "long_tap")
	if _is_boss_fever_active():
		_success_pattern(true)
		return

	var required := String(current_pattern["action"])
	if required == "no_input":
		_fail_pattern("WAIT!")
	elif required == "double_tap" and action == "tap":
		feedback_requested.emit("TAP TAP", Color.html("#ffd84a"))
	elif required == "long_tap" and action == "tap":
		feedback_requested.emit("HOLD", Color.html("#9ec8ff"))
	elif _action_matches(required, action):
		_success_pattern()
	else:
		_fail_pattern("WRONG")

func _process(delta: float) -> void:
	_update_boss_background_layout()
	if boss_background_sprite and active:
		boss_background_sprite.rotation += BOSS_BACKGROUND_ROTATION_SPEED * delta
	if not active:
		return
	_update_player_hurt(delta)
	if current_pattern.is_empty():
		return
	_update_boss_fever(delta)
	pattern_time_left -= delta
	var ratio := _get_boss_timer_ratio()
	_update_timer_visual(ratio)
	_emit_boss_stats(ratio)
	if pattern_time_left <= 0.0:
		if _is_boss_fever_active():
			_next_pattern()
		elif String(current_pattern["action"]) == "no_input":
			_success_pattern()
		else:
			_fail_pattern("MISS")

func _build_scene() -> void:
	_add_boss_background()

	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(250.0, 500.0)
	add_child(player)

	boss_root = Node2D.new()
	boss_root.name = "BossRoot"
	boss_root.position = Vector2(970.0, 580.0)
	add_child(boss_root)

	# Temporary visual mount; combat state remains owned by BossStage for now.
	boss_visual = ROBOT_SAMURAI_BOSS_SCENE.instantiate()
	boss_visual.name = "RobotSamuraiBossTestVisual"
	boss_root.add_child(boss_visual)

	pattern_label = Label.new()
	pattern_label.name = "PatternLabel"
	pattern_label.position = Vector2(460.0, 220.0)
	pattern_label.size = Vector2(360.0, 130.0)
	pattern_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pattern_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pattern_label.add_theme_font_size_override("font_size", 58)
	add_child(pattern_label)

	timer_fill = Polygon2D.new()
	timer_fill.name = "TimerFill"
	timer_fill.position = Vector2(440.0, 360.0)
	timer_fill.color = Color.html("#f7fbff")
	add_child(timer_fill)

	piece_root = Node2D.new()
	piece_root.name = "BossSlicePieceRoot"
	add_child(piece_root)

	boss_fever_mode = BOSS_FEVER_MODE_SCRIPT.new()
	boss_fever_mode.name = "BossFeverMode"
	add_child(boss_fever_mode)
	boss_fever_mode.started.connect(_on_boss_fever_started)
	boss_fever_mode.ended.connect(_on_boss_fever_ended)

	slice_factory = SLICE_EFFECT_FACTORY_SCRIPT.new()
	add_child(slice_factory)

func _add_boss_background() -> void:
	boss_background_fill = ColorRect.new()
	boss_background_fill.name = "BossBackgroundFill"
	boss_background_fill.color = Color.BLACK
	boss_background_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_background_fill.z_index = -200
	add_child(boss_background_fill)

	var texture := _load_texture(BOSS_BACKGROUND_PATH)
	if texture == null:
		return

	boss_background_sprite = Sprite2D.new()
	boss_background_sprite.name = "BossBackground"
	boss_background_sprite.texture = texture
	boss_background_sprite.centered = true
	boss_background_sprite.z_index = -190
	add_child(boss_background_sprite)
	_update_boss_background_layout()

func _next_pattern() -> void:
	if boss_hp <= 0:
		_finish(true)
		return
	if PlayerLifeState.is_player_dead(hp, _is_player_invincible()):
		_finish(false)
		return
	current_phase = _get_current_boss_phase()
	current_pattern = _get_next_phase_pattern(current_phase)
	pattern_total_time = float(current_pattern["time"])
	pattern_time_left = pattern_total_time
	pattern_label.text = String(current_pattern["hint"])
	pattern_label.add_theme_color_override("font_color", current_pattern["color"])
	if _is_boss_fever_active():
		pattern_label.text = "FEVER"
		pattern_label.add_theme_color_override("font_color", Color.html("#5ef3ff"))
	else:
		_play_boss_pattern_motion(int(current_pattern["code"]))
	_update_timer_visual(1.0)
	_emit_boss_stats(1.0)

func _build_phase_pattern_decks() -> void:
	randomize()
	phase1_patterns = _build_pattern_deck(
		"phase_1",
		PHASE_1_TAP_COUNT,
		PHASE_1_DOUBLE_TAP_COUNT,
		PHASE_1_LONG_TAP_COUNT,
		PHASE_1_WAIT_COUNT
	)
	phase2_patterns = _build_pattern_deck(
		"phase_2",
		PHASE_2_TAP_COUNT,
		PHASE_2_DOUBLE_TAP_COUNT,
		PHASE_2_LONG_TAP_COUNT,
		PHASE_2_WAIT_COUNT
	)
	phase1_patterns.shuffle()
	phase2_patterns.shuffle()

func _build_pattern_deck(phase_id: String, tap_count: int, double_tap_count: int, long_tap_count: int, wait_count: int) -> Array:
	var deck := []
	_append_patterns(deck, phase_id, "tap", tap_count)
	_append_patterns(deck, phase_id, "double_tap", double_tap_count)
	_append_patterns(deck, phase_id, "long_tap", long_tap_count)
	_append_patterns(deck, phase_id, "no_input", wait_count)
	if deck.size() != BOSS_PHASE_DECK_SIZE:
		push_warning("%s boss pattern deck has %d entries, expected %d." % [phase_id, deck.size(), BOSS_PHASE_DECK_SIZE])
	return deck

func _append_patterns(deck: Array, phase_id: String, action: String, count: int) -> void:
	for index in range(count):
		deck.append(_make_boss_pattern(phase_id, action, index))

func _make_boss_pattern(phase_id: String, action: String, index: int) -> Dictionary:
	match action:
		"tap":
			return {"id": "%s_tap_%02d" % [phase_id, index], "code": BossPatternCode.RIGHT_ARM_SLAM, "action": "tap", "time": GameBalance.BOSS_TAP_ATTACK_WINDOW_SECONDS, "hint": "TAP", "color": Color.html("#f7fbff")}
		"double_tap":
			return {"id": "%s_double_tap_%02d" % [phase_id, index], "code": BossPatternCode.BOTH_ARM_SLAM, "action": "double_tap", "time": GameBalance.BOSS_DOUBLE_TAP_ATTACK_WINDOW_SECONDS, "hint": "TAP TAP", "color": Color.html("#ffd84a")}
		"long_tap":
			return {"id": "%s_long_tap_%02d" % [phase_id, index], "code": BossPatternCode.CORE_CHARGE, "action": "long_tap", "time": GameBalance.BOSS_LONG_TAP_ATTACK_WINDOW_SECONDS, "hint": "HOLD", "color": Color.html("#9ec8ff")}
		"no_input":
			return {"id": "%s_wait_%02d" % [phase_id, index], "code": BossPatternCode.WAIT, "action": "no_input", "time": GameBalance.BOSS_WAIT_WINDOW_SECONDS, "hint": "WAIT", "color": Color.html("#ff6b6b")}
		_:
			return {}

func _get_current_boss_phase() -> int:
	if float(boss_hp) <= float(GameBalance.BOSS_MAX_HP) * 0.5:
		return BOSS_PHASE_2
	return BOSS_PHASE_1

func _get_next_phase_pattern(phase: int) -> Dictionary:
	if phase == BOSS_PHASE_2:
		if phase2_patterns.is_empty():
			_build_phase_pattern_decks()
		var pattern: Dictionary = phase2_patterns[phase2_pattern_index]
		phase2_pattern_index = (phase2_pattern_index + 1) % phase2_patterns.size()
		return pattern.duplicate(true)

	if phase1_patterns.is_empty():
		_build_phase_pattern_decks()
	var pattern: Dictionary = phase1_patterns[phase1_pattern_index]
	phase1_pattern_index = (phase1_pattern_index + 1) % phase1_patterns.size()
	return pattern.duplicate(true)

func _success_pattern(from_fever: bool = false) -> void:
	if not active:
		return
	boss_hp -= 1
	score += 400 if from_fever else 200
	if not from_fever:
		boss_combo += 1
		combo_increased.emit(boss_combo)
		boss_fever_mode.add_fever(GameBalance.BOSS_FEVER_GAIN_PER_SUCCESS)
	current_pattern = {}
	if boss_hp > 0:
		_play_boss_hit()
	slice_factory.spawn_slice(piece_root, _get_boss_slice_center(), Color.html("#8a3042"), Vector2(170.0, 170.0), boss_hp <= 0)
	feedback_requested.emit("HIT", Color.html("#f7fbff"))
	if boss_hp <= 0:
		_finish(true)
	else:
		_advance_after_boss_hit()

func _fail_pattern(text: String) -> void:
	if not active:
		return
	if is_player_hurt_locked():
		_next_pattern()
		return
	if _is_boss_fever_active():
		feedback_requested.emit("FEVER", Color.html("#5ef3ff"))
		_next_pattern()
		return
	boss_combo = 0
	hp -= 1
	AudioHooksScript.play_player_hurt(self)
	var player_dead := PlayerLifeState.is_player_dead(hp, _is_player_invincible())
	if player_dead:
		PlayerLifeState.show_dead_visual(player)
	else:
		player.flash_hurt()
	_start_player_hurt_lock()
	feedback_requested.emit(text, Color.html("#ff6b6b"))
	if player_dead:
		_finish(false)
	else:
		_next_pattern()

func _finish(won: bool) -> void:
	if not active:
		return
	active = false
	if won:
		score += 500
		feedback_requested.emit("FINISH", Color.html("#ffef8a"))
		if boss_visual and boss_visual.has_method("start_defeated"):
			boss_visual.call("start_defeated")
		await get_tree().create_timer(_get_boss_visual_float("defeated_seconds", 1.4)).timeout
	boss_finished.emit({
		"won": won,
		"score": score,
		"coins": coins,
		"hp": hp
	})

func _action_matches(required: String, action: String) -> bool:
	if _is_boss_fever_active():
		return true
	if required == action:
		return true
	if required == "tap" and action == "double_tap":
		return true
	return false

func is_player_hurt_locked() -> bool:
	return active and player_hurt_timer > 0.0

func _start_player_hurt_lock() -> void:
	player_hurt_timer = max(player_hurt_timer, GameBalance.PLAYER_HURT_SLOW_DURATION)

func _update_player_hurt(delta: float) -> void:
	if player_hurt_timer <= 0.0:
		return
	player_hurt_timer = max(0.0, player_hurt_timer - delta)

func _update_boss_fever(delta: float) -> void:
	if boss_fever_mode:
		boss_fever_mode.update(delta)

func _play_boss_pattern_motion(pattern_code: int) -> void:
	if not boss_visual:
		return

	match pattern_code:
		BossPatternCode.RIGHT_ARM_SLAM:
			if boss_visual.has_method("start_right_arm_slam"):
				boss_visual.call("start_right_arm_slam", pattern_total_time)
		BossPatternCode.BOTH_ARM_SLAM:
			if boss_visual.has_method("start_both_arm_slam"):
				boss_visual.call("start_both_arm_slam", pattern_total_time)
		BossPatternCode.CORE_CHARGE:
			if boss_visual.has_method("start_core_charge"):
				boss_visual.call("start_core_charge", pattern_total_time)
		BossPatternCode.WAIT:
			if boss_visual.has_method("start_wait"):
				boss_visual.call("start_wait")

func _play_boss_hit() -> void:
	if boss_visual and boss_visual.has_method("start_hit"):
		boss_visual.call("start_hit")

func _advance_after_boss_hit() -> void:
	await get_tree().create_timer(_get_boss_visual_float("hit_seconds", 1.0)).timeout
	if active:
		_next_pattern()

func _get_boss_visual_float(property_name: String, fallback: float) -> float:
	if not boss_visual:
		return fallback
	var value = boss_visual.get(property_name)
	if value == null:
		return fallback
	return float(value)

func _is_boss_fever_active() -> bool:
	return boss_fever_mode != null and boss_fever_mode.active

func _on_boss_fever_started() -> void:
	fever_state_changed.emit(true)
	feedback_requested.emit("BOSS FEVER!", Color.html("#5ef3ff"))
	pattern_label.text = "FEVER"
	pattern_label.add_theme_color_override("font_color", Color.html("#5ef3ff"))

func _on_boss_fever_ended() -> void:
	fever_state_changed.emit(false)
	feedback_requested.emit("BOSS FEVER END", Color.html("#d9f7ff"))

func _get_boss_timer_ratio() -> float:
	if _is_boss_fever_active():
		return boss_fever_mode.get_time_ratio()
	return clamp(pattern_time_left / pattern_total_time, 0.0, 1.0)

func _emit_boss_stats(time_ratio: float) -> void:
	var hint := "FEVER" if _is_boss_fever_active() else String(current_pattern["hint"])
	stats_changed.emit(score, hp, boss_hp, GameBalance.BOSS_MAX_HP, hint, time_ratio)

func _get_boss_slice_center() -> Vector2:
	if boss_visual and boss_visual.has_method("get_core_global_position"):
		return boss_visual.call("get_core_global_position")
	return boss_root.global_position + Vector2(-20.0, -120.0)

func _update_timer_visual(ratio: float) -> void:
	var width := 400.0 * ratio
	timer_fill.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(width, 0.0),
		Vector2(width, 12.0),
		Vector2(0.0, 12.0)
	])

func _update_boss_background_layout() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	if boss_background_fill:
		boss_background_fill.position = Vector2.ZERO
		boss_background_fill.size = viewport_size
	if boss_background_sprite:
		boss_background_sprite.position = viewport_size * 0.5

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		var imported_texture := load(path)
		if imported_texture is Texture2D:
			return imported_texture

	var image := Image.new()
	if image.load(path) == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _is_player_invincible() -> bool:
	var debug_flags := get_node_or_null("/root/DebugFlags")
	return debug_flags != null and bool(debug_flags.player_invincible)
