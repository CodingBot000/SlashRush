extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const RunnerStageContext := preload("res://scripts/game/runner/RunnerStageContext.gd")
const BossStageContext := preload("res://scripts/game/boss/BossStageContext.gd")
const StageCatalog := preload("res://scripts/data/stage/StageCatalog.gd")

var runner_finished_payload := {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _assert_runner_uses_injected_config()
	await _assert_boss_uses_injected_config()
	quit()

func _assert_runner_uses_injected_config() -> void:
	var stage = StageCatalog.get_default_stage()
	var context = RunnerStageContext.from_stage(stage, null)
	context.start_score = 7
	context.start_coins = 3
	context.start_hp = 2
	context.runner_config.duration_seconds = 0.2
	context.runner_config.map_scroll_speed = 123.0
	context.runner_config.ground_scroll_speed = 456.0
	context.runner_config.object_speed = 789.0
	context.runner_config.fever_scroll_speed_multiplier = 1.5
	context.runner_config.fever_object_speed_multiplier = 1.75
	context.character_profile.id = "stage_context_runner_player"
	context.object_visual_set.overrides["enemy_basic"] = {
		"color": Color.html("#123456"),
		"label": "X",
		"size": Vector2(44.0, 55.0),
		"shape": "box"
	}

	var runner = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(runner)
	await process_frame
	runner.configure(context)
	runner.run_finished.connect(_on_runner_finished)
	runner.start_run()
	runner.spawner.stop()

	if runner.score != 7 or runner.coins != 3 or runner.hp != 2:
		_fail("RunnerStage should start from RunnerStageContext values.")
		return
	if not is_equal_approx(runner._get_map_scroll_speed(), 123.0):
		_fail("RunnerStage should read map scroll speed from runner config.")
		return
	if not is_equal_approx(runner._get_ground_scroll_speed(), 456.0):
		_fail("RunnerStage should read ground scroll speed from runner config.")
		return
	if not is_equal_approx(runner._get_base_object_speed(), 789.0):
		_fail("RunnerStage should read object speed from runner config.")
		return
	if runner.player.visual_profile == null or String(runner.player.visual_profile.id) != "stage_context_runner_player":
		_fail("RunnerStage should inject character profile into PlayerController.")
		return

	runner.spawner._spawn_object("enemy_basic")
	await process_frame
	var spawned_object = runner.object_root.get_child(0)
	if spawned_object.object_size != Vector2(44.0, 55.0) or spawned_object.display_color != Color.html("#123456"):
		_fail("RunnerStage should inject object visual set into spawned objects.")
		return

	runner.fever_mode.start()
	runner._sync_fever_state()
	if not is_equal_approx(runner._get_scroll_speed_multiplier(), 1.5):
		_fail("RunnerStage should read fever scroll multiplier from runner config.")
		return
	if not is_equal_approx(runner._get_object_speed_multiplier(), 1.75):
		_fail("RunnerStage should read fever object multiplier from runner config.")
		return

	runner.fever_mode.end()
	runner._sync_fever_state()
	runner._process(0.25)
	await process_frame
	if not bool(runner_finished_payload.get("cleared", false)):
		_fail("RunnerStage should finish using configured duration.")
		return
	runner.queue_free()
	await process_frame

func _assert_boss_uses_injected_config() -> void:
	var stage = StageCatalog.get_default_stage()
	var context = BossStageContext.from_stage(stage, null)
	context.boss_config.boss_max_hp = 3
	context.boss_config.success_score = 11
	context.boss_config.fever_success_score = 22
	context.boss_config.clear_bonus_score = 33
	context.boss_config.boss_fever_gain_per_success = 44
	context.character_profile.id = "stage_context_boss_player"
	context.boss_config.phase_pattern_counts = {
		"phase_1": {"tap": 1, "double_tap": 0, "long_tap": 0, "no_input": 0},
		"phase_2": {"tap": 0, "double_tap": 1, "long_tap": 0, "no_input": 0}
	}

	var boss = BOSS_STAGE_SCENE.instantiate()
	root.add_child(boss)
	await process_frame
	boss.configure(context)
	boss.start_boss(5, 2, 3)
	await process_frame

	if boss.boss_hp != 3:
		_fail("BossStage should use configured boss max HP.")
		return
	if boss.player.visual_profile == null or String(boss.player.visual_profile.id) != "stage_context_boss_player":
		_fail("BossStage should inject character profile into PlayerController.")
		return
	if boss.phase1_patterns.size() != 1 or String(boss.phase1_patterns[0].get("action", "")) != "tap":
		_fail("BossStage should build phase 1 deck from boss config.")
		return
	if boss.phase2_patterns.size() != 1 or String(boss.phase2_patterns[0].get("action", "")) != "double_tap":
		_fail("BossStage should build phase 2 deck from boss config.")
		return

	boss.current_pattern = {"action": "tap", "hint": "TAP"}
	boss.boss_hp = 2
	boss._success_pattern(false)
	await process_frame
	if boss.score != 16:
		_fail("BossStage should use configured normal success score.")
		return

	boss.queue_free()
	await process_frame

func _on_runner_finished(payload: Dictionary) -> void:
	runner_finished_payload = payload

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
