extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const DEBUG_FLAGS_SCRIPT := preload("res://scripts/data/DebugFlags.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var debug_flags = root.get_node_or_null("DebugFlags")
	if debug_flags == null:
		debug_flags = DEBUG_FLAGS_SCRIPT.new()
		debug_flags.name = "DebugFlags"
		root.add_child(debug_flags)

	debug_flags.player_invincible = true
	await _assert_runner_death_is_ignored()
	await _assert_boss_death_is_ignored()

	debug_flags.player_invincible = false
	await _assert_boss_death_still_finishes()

	quit()

func _assert_runner_death_is_ignored() -> void:
	var runner = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(runner)
	await process_frame
	runner.start_run()
	runner.spawner.stop()
	runner.hp = 1

	var object = INTERACTABLE_OBJECT_SCENE.instantiate()
	runner.object_root.add_child(object)
	object.setup("enemy_basic")
	object.damage_on_fail = 1
	runner._fail_object(object, false)
	await process_frame

	if not runner.active:
		_fail("Runner should stay active when debug invincibility is enabled.")
	if runner.hp != 0:
		_fail("Runner HP should still be reduced by damage.")

	runner.free()

func _assert_boss_death_is_ignored() -> void:
	var boss = BOSS_STAGE_SCENE.instantiate()
	root.add_child(boss)
	await process_frame
	boss.start_boss(0, 0, 1)
	boss._fail_pattern("MISS")
	await process_frame

	if not boss.active:
		_fail("Boss stage should stay active when debug invincibility is enabled.")
	if boss.hp != 0:
		_fail("Boss stage HP should still be reduced by damage.")

	boss.free()

func _assert_boss_death_still_finishes() -> void:
	var boss = BOSS_STAGE_SCENE.instantiate()
	root.add_child(boss)
	await process_frame
	boss.start_boss(0, 0, 1)
	boss._fail_pattern("MISS")
	await process_frame

	if boss.active:
		_fail("Boss stage should finish normally when debug invincibility is disabled.")

	boss.free()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
