extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio_manager = root.get_node_or_null("AudioManager")
	if audio_manager == null:
		_fail("AudioManager autoload should exist.")
		return
	if audio_manager.find_child("RunnerFootstepAudio", false, false) != null:
		_fail("AudioManager should not create runner footstep audio.")
		return

	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_run()
	stage.spawner.stop()
	await process_frame
	if audio_manager.find_child("RunnerFootstepAudio", false, false) != null:
		_fail("Runner footstep audio should not be created while RunStage is active.")
		return

	stage._start_hurt_slow()
	await process_frame
	if audio_manager.find_child("RunnerFootstepAudio", false, false) != null:
		_fail("Runner footstep audio should not be created while the player is hurt.")
		return

	stage._update_hurt_slow(GameBalance.PLAYER_HURT_SLOW_DURATION)
	await process_frame
	if audio_manager.find_child("RunnerFootstepAudio", false, false) != null:
		_fail("Runner footstep audio should not resume after hurt recovery.")
		return

	stage.stop_run()
	await process_frame
	if audio_manager.find_child("RunnerFootstepAudio", false, false) != null:
		_fail("Runner footstep audio should remain absent when RunStage stops.")
		return

	stage.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
