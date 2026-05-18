extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner = RUNNER_STAGE_SCENE.instantiate()
	var boss = BOSS_STAGE_SCENE.instantiate()
	root.add_child(runner)
	root.add_child(boss)
	await process_frame

	if boss.player.position != runner.player.position:
		push_error("Boss player position should match Runner player position.")
		quit(1)
		return

	runner.queue_free()
	boss.queue_free()
	await process_frame
	quit()
