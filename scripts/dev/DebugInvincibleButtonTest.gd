extends SceneTree

const GAME_HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var debug_flags = root.get_node_or_null("DebugFlags")
	if debug_flags == null:
		_fail("DebugFlags autoload should exist.")
		return
	debug_flags.player_invincible = false

	var hud = GAME_HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame
	hud.show_runner()
	await process_frame

	var button = hud.find_child("DebugInvincibleButton", true, false)
	if button == null:
		_fail("GameHUD should create a temporary debug invincible button.")
		return
	var fever_button = hud.find_child("DebugFeverFillButton", true, false)
	if fever_button == null:
		_fail("GameHUD should create a temporary debug fever fill button.")
		return
	if not button.visible:
		_fail("Debug invincible button should be visible during gameplay HUD.")
		return
	if fever_button.visible:
		_fail("Debug fever fill button should stay hidden during gameplay HUD.")
		return
	if button.text != "무적 OFF":
		_fail("Debug invincible button should show the current off state.")
		return
	if fever_button.text != "FEVER FILL":
		_fail("Debug fever fill button should show its fill label.")
		return

	button.emit_signal("toggled", true)
	await process_frame
	if not debug_flags.player_invincible or button.text != "무적 ON":
		_fail("Debug invincible button should enable player invincibility.")
		return

	button.emit_signal("toggled", false)
	await process_frame
	if debug_flags.player_invincible or button.text != "무적 OFF":
		_fail("Debug invincible button should disable player invincibility.")
		return

	var viewport_width := root.get_visible_rect().size.x
	if button.position.x + button.size.x > viewport_width or button.position.x < viewport_width - 140.0:
		_fail("Debug invincible button should stay at the right edge of the gameplay screen.")
		return
	if fever_button.position.y <= button.position.y:
		_fail("Debug fever fill button should be placed below the invincible button.")
		return

	hud.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
