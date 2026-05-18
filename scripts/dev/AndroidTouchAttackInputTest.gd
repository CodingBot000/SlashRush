extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var tap_count := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main.input_interpreter.tap_detected.connect(_on_tap_detected)

	for event in InputMap.action_get_events("tap_action"):
		if event is InputEventMouseButton:
			_fail("tap_action should not keep mouse events because pointer attacks need position filtering.")
			return

	if main.game_hud.root.mouse_filter == Control.MOUSE_FILTER_STOP:
		_fail("Gameplay HUD root should not block Android touch attacks.")
		return

	if main.game_hud.score_label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("Gameplay HUD labels should pass Android touches through to attack input.")
		return

	if main.game_hud.fever_back.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("Gameplay HUD bars should pass Android touches through to attack input.")
		return

	if main.game_hud.gameplay_touch_area.mouse_filter != Control.MOUSE_FILTER_STOP:
		_fail("Gameplay touch area should capture non-button Android touches.")
		return

	_emit_gameplay_area_screen_tap(main.game_hud)
	await process_frame
	if tap_count != 1:
		_fail("Android screen tap outside UI buttons should trigger a tap attack.")
		return

	main.input_interpreter.reset_action_state()
	await process_frame
	var tap_count_before_button := tap_count
	if main.game_hud.gameplay_touch_area.get_index() > main.game_hud.debug_invincible_button.get_index():
		_fail("Gameplay touch area should stay behind debug UI buttons.")
		return
	main.game_hud.debug_invincible_button.emit_signal("pressed")
	await process_frame
	if tap_count != tap_count_before_button:
		_fail("Android screen tap on UI buttons should not trigger attack input. before=%d after=%d" % [tap_count_before_button, tap_count])
		return

	main.queue_free()
	await process_frame
	quit()

func _emit_gameplay_area_screen_tap(hud) -> void:
	var press_event := InputEventScreenTouch.new()
	press_event.index = 0
	press_event.position = Vector2(220.0, 330.0)
	press_event.pressed = true
	hud._on_gameplay_touch_area_gui_input(press_event)

	var release_event := InputEventScreenTouch.new()
	release_event.index = 0
	release_event.position = Vector2(220.0, 330.0)
	release_event.pressed = false
	hud._on_gameplay_touch_area_gui_input(release_event)

func _on_tap_detected() -> void:
	tap_count += 1

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
