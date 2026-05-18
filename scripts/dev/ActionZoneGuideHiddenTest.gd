extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	var guide = stage.find_child("ActionZoneGuide", true, false)
	if guide != null and guide.visible:
		push_error("ActionZoneGuide debug rectangle should be hidden by default.")
		quit(1)
		return

	stage.queue_free()
	await process_frame
	quit()
