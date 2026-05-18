extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const FEVER_IMPACT_OVERLAY_SCRIPT := preload("res://scripts/effects/FeverImpactOverlay.gd")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _assert_runner_fever_overlay()
	await _assert_boss_fever_overlay()
	quit()

func _assert_runner_fever_overlay() -> void:
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	if stage.fever_impact_overlay == null or stage.fever_impact_overlay.get_script() != FEVER_IMPACT_OVERLAY_SCRIPT:
		_fail("RunnerStage should own a fever impact overlay.")
		return
	if stage.fever_impact_overlay.get_parent() != stage.world_root:
		_fail("RunnerStage fever impact overlay should be attached to the world root.")
		return
	if stage.fever_impact_overlay.z_index != FEVER_IMPACT_OVERLAY_SCRIPT.OVERLAY_Z_INDEX:
		_fail("RunnerStage fever impact overlay should render above background and below gameplay objects.")
		return

	stage.start_run()
	stage.spawner.stop()
	stage.fever_mode.start()
	await process_frame
	if not stage.fever_impact_overlay.visible:
		_fail("RunnerStage should show fever impact overlay when fever starts.")
		return

	stage.fever_mode.end()
	await process_frame
	if stage.fever_impact_overlay.visible:
		_fail("RunnerStage should hide fever impact overlay when fever ends.")
		return

	stage.stop_run()
	stage.queue_free()
	await process_frame

func _assert_boss_fever_overlay() -> void:
	var stage = BOSS_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	if stage.fever_impact_overlay == null or stage.fever_impact_overlay.get_script() != FEVER_IMPACT_OVERLAY_SCRIPT:
		_fail("BossStage should own a fever impact overlay.")
		return
	if stage.fever_impact_overlay.get_parent() != stage:
		_fail("BossStage fever impact overlay should be attached to BossStage.")
		return
	if stage.fever_impact_overlay.z_index != FEVER_IMPACT_OVERLAY_SCRIPT.OVERLAY_Z_INDEX:
		_fail("BossStage fever impact overlay should render above background and below gameplay objects.")
		return

	stage.start_boss(0, 0, GameBalance.MAX_HP)
	stage.boss_fever_mode.start()
	await process_frame
	if not stage.fever_impact_overlay.visible:
		_fail("BossStage should show fever impact overlay when fever starts.")
		return

	stage.boss_fever_mode.end()
	await process_frame
	if stage.fever_impact_overlay.visible:
		_fail("BossStage should hide fever impact overlay when fever ends.")
		return

	stage.stop_boss()
	stage.queue_free()
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
