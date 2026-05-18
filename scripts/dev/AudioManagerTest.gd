extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio_manager = root.get_node_or_null("AudioManager")
	if audio_manager == null:
		_fail("AudioManager autoload should exist.")
		return
	if audio_manager.ui_button_click_player == null:
		_fail("AudioManager should create a UI button click audio player.")
		return
	if audio_manager.ui_button_click_player.stream == null:
		_fail("AudioManager should load the UI button click sound.")
		return
	if audio_manager.start_game_player == null or audio_manager.start_game_player.stream == null:
		_fail("AudioManager should load the start game sound.")
		return
	if audio_manager.pickup_item_player == null or audio_manager.pickup_item_player.stream == null:
		_fail("AudioManager should load the pickup item sound.")
		return
	if audio_manager.player_hurt_player == null or audio_manager.player_hurt_player.stream == null:
		_fail("AudioManager should load the player hurt sound.")
		return

	var button := Button.new()
	root.add_child(button)
	audio_manager.bind_ui_button(button)
	button.emit_signal("pressed")
	await process_frame

	if not audio_manager.ui_button_click_player.playing:
		_fail("UI button click sound should play when a bound button is pressed.")
		return

	audio_manager.ui_button_click_player.stop()
	button.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
