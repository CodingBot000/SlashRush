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
	var warning_label = hud.find_child("InvincibleDebugWarningLabel", true, false)
	if warning_label == null:
		_fail("GameHUD should create an invincible debug warning label.")
		return
	if button.visible:
		_fail("Debug invincible button should stay hidden during gameplay HUD.")
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
	if warning_label.visible:
		_fail("Invincible debug warning should stay hidden while invincible debug is off.")
		return

	debug_flags.player_invincible = true
	hud.show_runner()
	await process_frame
	if not warning_label.visible:
		_fail("Invincible debug warning should show while invincible debug is on.")
		return
	if warning_label.text != "무적디버그 사용중":
		_fail("Invincible debug warning should show the expected warning text.")
		return
	if warning_label.get_theme_color("font_color").r < 0.9:
		_fail("Invincible debug warning should use red text.")
		return

	debug_flags.player_invincible = false
	hud.show_runner()
	await process_frame
	if warning_label.visible:
		_fail("Invincible debug warning should hide again when invincible debug is off.")
		return

	var viewport_width := root.get_visible_rect().size.x
	if warning_label.position.x + warning_label.size.x > viewport_width or warning_label.position.x < viewport_width - 290.0:
		_fail("Invincible debug warning should stay at the top-right edge of the gameplay screen.")
		return

	hud.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
