extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(runner)
	await process_frame
	runner.start_run()
	runner.spawner.stop()
	await process_frame

	await _assert_runner_fever_lifecycle_and_rush_pause(runner)
	await _assert_runner_fever_end_clears_rush_and_delays_spawn(runner)
	await _assert_runner_fever_scroll_speed_multiplier(runner)
	await _assert_runner_fever_object_speed_multiplier(runner)
	await _assert_runner_fever_run_animation_speed(runner)
	await _assert_runner_fever_missed_objects_are_discarded(runner)
	await _assert_runner_fever_direct_fail_is_invincible(runner)
	await _assert_runner_fever_any_slash_succeeds(runner)
	await _assert_runner_fever_orb_collection_starts_fever(runner)

	runner.free()

	var boss = BOSS_STAGE_SCENE.instantiate()
	root.add_child(boss)
	await process_frame
	await _assert_boss_fever_is_separate_and_invincible(boss)
	boss.free()

	quit()

func _assert_runner_fever_lifecycle_and_rush_pause(stage) -> void:
	stage._gain_runner_fever(GameBalance.FEVER_MAX)

	if not stage.is_fever:
		_fail("Runner fever should start when fever gauge reaches max.")
	if stage.fever_timer < GameBalance.FEVER_DURATION - 0.1:
		_fail("Runner fever should use the configured fever duration.")
	if not stage.spawner._fever_rush_enabled:
		_fail("Runner fever should enable rush spawning.")

	stage._update_fever(GameBalance.FEVER_DURATION - GameBalance.FEVER_RUSH_SPAWN_STOP_BEFORE_END + 0.01)
	if not stage.is_fever:
		_fail("Runner fever should still be active just before the end.")
	if stage.spawner._fever_rush_enabled:
		_fail("Runner fever rush spawning should pause before fever ends.")
	if stage.spawner._spawn_pause_timer <= 0.0:
		_fail("Runner fever rush pause should last across the fever ending.")

	stage._update_fever(GameBalance.FEVER_RUSH_SPAWN_STOP_BEFORE_END + 0.05)
	if stage.is_fever or stage.fever != 0:
		_fail("Runner fever should end with an empty fever gauge.")

func _assert_runner_fever_end_clears_rush_and_delays_spawn(stage) -> void:
	_prepare_runner_fever(stage)
	var rush_enemy = _add_zone_object(stage, "enemy_basic")
	rush_enemy.set_meta("fever_rush_spawn", true)
	stage.spawner._spawn_pause_timer = 0.0

	stage._update_fever(GameBalance.FEVER_DURATION + 0.1)
	await process_frame

	if _count_fever_rush_objects(stage) != 0:
		_fail("Runner fever end should clear remaining fever rush enemies.")
	if stage.spawner._spawn_pause_timer < GameBalance.FEVER_END_NORMAL_SPAWN_DELAY - 0.01:
		_fail("Runner fever end should delay normal spawning.")

func _assert_runner_fever_scroll_speed_multiplier(stage) -> void:
	stage._gain_runner_fever(GameBalance.FEVER_MAX)
	await process_frame
	if not is_equal_approx(stage._get_scroll_speed_multiplier(), GameBalance.RUNNER_FEVER_SCROLL_SPEED_MULTIPLIER):
		_fail("Runner fever should double background scroll speed.")

	stage._update_fever(GameBalance.FEVER_DURATION + 0.1)
	await process_frame
	if not is_equal_approx(stage._get_scroll_speed_multiplier(), 1.0):
		_fail("Runner fever scroll speed should return to normal when fever ends.")

func _assert_runner_fever_object_speed_multiplier(stage) -> void:
	_prepare_runner_fever(stage)
	if not is_equal_approx(stage._get_object_speed_multiplier(), GameBalance.RUNNER_FEVER_OBJECT_SPEED_MULTIPLIER):
		_fail("Runner fever should double object approach speed.")

	var enemy = _add_zone_object(stage, "enemy_basic")
	enemy.position = Vector2(1000.0, GameBalance.GAMEPLAY_BASELINE_Y)
	var start_x: float = enemy.position.x
	stage._move_objects(0.1, stage._get_object_speed_multiplier())
	var expected_x := start_x - GameBalance.OBJECT_SPEED * GameBalance.RUNNER_FEVER_OBJECT_SPEED_MULTIPLIER * 0.1
	if not is_equal_approx(enemy.position.x, expected_x):
		_fail("Runner fever objects should move at the fever object speed multiplier.")

	stage.fever_mode.end()
	stage._sync_fever_state()
	if not is_equal_approx(stage._get_object_speed_multiplier(), 1.0):
		_fail("Runner object speed should return to normal when fever ends.")

func _assert_runner_fever_run_animation_speed(stage) -> void:
	_prepare_runner_fever(stage)
	await process_frame

	if stage.player.run_sprite == null:
		_fail("Runner player should have a run animation sprite.")
	if not is_equal_approx(stage.player.run_sprite.speed_scale, GameBalance.RUNNER_FEVER_RUN_ANIMATION_SPEED_MULTIPLIER):
		_fail("Runner fever should triple player run animation speed.")

	stage.fever_mode.end()
	await process_frame
	if not is_equal_approx(stage.player.run_sprite.speed_scale, 1.0):
		_fail("Runner run animation speed should return to normal when fever ends.")

func _assert_runner_fever_missed_objects_are_discarded(stage) -> void:
	_prepare_runner_fever(stage)
	stage.hp = GameBalance.MAX_HP
	stage.score = 0
	stage.coins = 0

	var enemy = _add_zone_object(stage, "enemy_basic")
	enemy.position.x = GameBalance.ACTION_ZONE_CENTER.x - GameBalance.ACTION_ZONE_SIZE.x * 0.5 - 90.0
	stage._move_objects(0.0)
	await process_frame

	if stage.hp != GameBalance.MAX_HP:
		_fail("Missed enemies during runner fever should not damage the player.")
	if stage.score != 0 or stage.coins != 0:
		_fail("Missed objects during runner fever should not give score or coins.")

	var coin = _add_zone_object(stage, "coin")
	coin.position.x = GameBalance.ACTION_ZONE_CENTER.x - GameBalance.ACTION_ZONE_SIZE.x * 0.5 - 90.0
	stage._move_objects(0.0)
	await process_frame

	if stage.score != 0 or stage.coins != 0:
		_fail("Missed good items during runner fever should not be collected.")

func _assert_runner_fever_direct_fail_is_invincible(stage) -> void:
	_prepare_runner_fever(stage)
	stage.hp = GameBalance.MAX_HP
	var bomb = _add_zone_object(stage, "bomb")
	stage._fail_object(bomb, false)
	var bomb_handled: bool = bomb.handled
	await process_frame

	if stage.hp != GameBalance.MAX_HP:
		_fail("Runner fever should ignore direct fail damage.")
	if not bomb_handled:
		_fail("Runner fever direct fail objects should be discarded.")

func _assert_runner_fever_any_slash_succeeds(stage) -> void:
	_prepare_runner_fever(stage)
	stage.score = 0
	stage.hp = GameBalance.MAX_HP
	_add_zone_object(stage, "enemy_armor")
	stage.handle_player_action("tap")
	await process_frame

	if stage.score != 300:
		_fail("Runner fever slash should score the cut with fever multiplier.")
	if stage.hp != GameBalance.MAX_HP:
		_fail("Runner fever slash should not damage the player.")

func _assert_runner_fever_orb_collection_starts_fever(stage) -> void:
	_clear_stage_objects(stage)
	stage.active = true
	stage.fever_mode.reset()
	stage._sync_fever_state()
	stage.spawner.set_fever_rush_enabled(false)
	stage.spawner._spawn_pause_timer = 0.0

	var orb = _add_zone_object(stage, "fever_orb")
	stage._collect_good_item(orb, true)
	await process_frame

	if not stage.is_fever:
		_fail("Collecting a fever orb should start runner fever immediately.")

func _assert_boss_fever_is_separate_and_invincible(boss) -> void:
	boss.start_boss(0, 0, GameBalance.MAX_HP)
	await process_frame

	boss.boss_fever_mode.start()
	var hp_before: int = boss.hp
	var boss_hp_before: int = boss.boss_hp
	boss.handle_player_action("tap")
	await process_frame

	if boss.hp != hp_before:
		_fail("Boss fever should not damage the player on input.")
	if boss.boss_hp != boss_hp_before - 1:
		_fail("Boss fever input should damage the boss regardless of pattern.")

	boss.boss_fever_mode.start()
	hp_before = boss.hp
	boss.pattern_time_left = 0.0
	boss._process(0.01)
	await process_frame

	if boss.hp != hp_before:
		_fail("Boss fever timeout should be invincible and skip reward.")

func _prepare_runner_fever(stage) -> void:
	_clear_stage_objects(stage)
	stage.active = true
	stage.fever_mode.start()
	stage._sync_fever_state()
	stage.spawner.set_fever_rush_enabled(false)
	stage.spawner._spawn_pause_timer = 0.0

func _clear_stage_objects(stage) -> void:
	for child in stage.object_root.get_children():
		child.free()

func _add_zone_object(stage, type_name: String):
	var object = INTERACTABLE_OBJECT_SCENE.instantiate()
	stage.object_root.add_child(object)
	object.setup(type_name)
	object.position = GameBalance.ACTION_ZONE_CENTER
	return object

func _count_fever_rush_objects(stage) -> int:
	var count := 0
	for child in stage.object_root.get_children():
		if child.has_meta("fever_rush_spawn") and child.get_meta("fever_rush_spawn") == true:
			count += 1
	return count

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
