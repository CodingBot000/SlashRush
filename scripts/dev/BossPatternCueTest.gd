extends SceneTree

const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage = BOSS_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage._show_pattern_cue("tap")
	await process_frame
	_assert_circle_cues(stage, 1, 6.25, "tap")
	_assert_prompt_layout(stage)

	stage._show_pattern_cue("double_tap")
	await process_frame
	_assert_circle_cues(stage, 2, 6.25, "double_tap")

	stage._show_pattern_cue("long_tap")
	await process_frame
	_assert_circle_cues(stage, 1, 25.0, "long_tap")

	stage._show_pattern_cue("no_input")
	await process_frame
	_assert_wait_cue(stage)

	if stage.pattern_label.visible or stage.pattern_label.text != "":
		_fail("Boss pattern text label should stay hidden and empty.")
		return

	stage.queue_free()
	await process_frame
	quit()

func _assert_circle_cues(stage, expected_count: int, expected_speed: float, action_name: String) -> void:
	var cues := _visible_animated_cues(stage.pattern_cue_root)
	if cues.size() != expected_count:
		_fail("%s should show %d animated circle cue(s)." % [action_name, expected_count])
		return

	for cue in cues:
		if cue.sprite_frames == null:
			_fail("%s circle cue should have sprite frames." % action_name)
			return
		if cue.sprite_frames.get_frame_count("pulse") != 5:
			_fail("%s circle cue should use five frames." % action_name)
			return
		if not is_equal_approx(cue.sprite_frames.get_animation_speed("pulse"), expected_speed):
			_fail("%s circle cue speed was not configured from the requested loop duration." % action_name)
			return

	if expected_count == 2 and cues[0].position.x >= cues[1].position.x:
		_fail("double_tap circle cues should be arranged side by side.")
		return

func _assert_wait_cue(stage) -> void:
	var wait_cues := _visible_wait_cues(stage.pattern_cue_root)
	var circle_cues := _visible_animated_cues(stage.pattern_cue_root)
	if wait_cues.size() != 1 or not circle_cues.is_empty():
		_fail("wait should show one static window cue and no animated circle cues.")
		return
	if wait_cues[0].texture == null:
		_fail("wait cue should use window_01 texture.")
		return

func _assert_prompt_layout(stage) -> void:
	var viewport_size: Vector2 = stage._get_viewport_size()
	var expected_timer_position := Vector2((viewport_size.x - 400.0) * 0.5, viewport_size.y - 72.0 - 12.0)
	var expected_cue_position := Vector2(viewport_size.x * 0.5, expected_timer_position.y - 38.0 - 132.0 * 0.5)
	if not stage.timer_fill.position.is_equal_approx(expected_timer_position):
		_fail("Boss pattern timer should be centered near the bottom with a bottom margin.")
		return
	if not stage.pattern_cue_root.position.is_equal_approx(expected_cue_position):
		_fail("Boss pattern cue should sit above the bottom timer, centered horizontally.")
		return
	if stage.timer_fill.position.y <= viewport_size.y * 0.75:
		_fail("Boss pattern timer should be in the lower part of the screen.")
		return

func _visible_animated_cues(parent: Node) -> Array:
	var matches := []
	for child in parent.get_children():
		if child is AnimatedSprite2D and child.visible:
			matches.append(child)
	return matches

func _visible_wait_cues(parent: Node) -> Array:
	var matches := []
	for child in parent.get_children():
		if child is Sprite2D and child.visible:
			matches.append(child)
	return matches

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
