extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var audio_manager = root.get_node_or_null("AudioManager")
	if audio_manager == null:
		_fail("AudioManager autoload should exist.")
		return
	if audio_manager.sword_slash_player == null:
		_fail("AudioManager should create a sword slash audio player.")
		return
	if audio_manager.sword_slash_player.stream == null:
		_fail("AudioManager should load the sword-slash sound.")
		return

	player.play_slash()
	await process_frame
	if not audio_manager.sword_slash_player.playing:
		_fail("Sword slash audio should play when player attacks.")
		return

	audio_manager.sword_slash_player.stop()
	player.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
