extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

var runner_combo_events := 0
var boss_combo_events := 0
var runner_last_combo := 0
var boss_last_combo := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _assert_runner_combo_signal()
	await _assert_boss_combo_signal()
	quit()

func _assert_runner_combo_signal() -> void:
	runner_combo_events = 0
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.combo_increased.connect(_on_runner_combo_increased)
	stage.start_run()
	stage.spawner.stop()

	var enemy = INTERACTABLE_OBJECT_SCENE.instantiate()
	stage.object_root.add_child(enemy)
	enemy.setup("enemy_basic")
	enemy.position = GameBalance.ACTION_ZONE_CENTER
	stage.handle_player_action("tap")
	await process_frame

	if runner_combo_events != 1:
		_fail("RunnerStage should emit combo_increased when combo rises.")
		return
	if runner_last_combo != 1:
		_fail("RunnerStage should emit the actual runner combo count.")
		return

	stage.stop_run()
	stage.queue_free()
	await process_frame

func _assert_boss_combo_signal() -> void:
	boss_combo_events = 0
	var stage = BOSS_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.combo_increased.connect(_on_boss_combo_increased)
	stage.start_boss(0, 0, GameBalance.MAX_HP)
	stage._success_pattern()
	await process_frame

	if boss_combo_events != 1:
		_fail("BossStage should emit combo_increased when combo rises.")
		return
	if boss_last_combo != 1:
		_fail("BossStage should emit the actual boss combo count.")
		return

	stage.stop_boss()
	stage.queue_free()
	await process_frame

func _on_runner_combo_increased(combo: int) -> void:
	runner_combo_events += 1
	runner_last_combo = combo

func _on_boss_combo_increased(combo: int) -> void:
	boss_combo_events += 1
	boss_last_combo = combo

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
