extends SceneTree

const SETTINGS_POPUP_SCENE := preload("res://scenes/ui/SettingsPopup.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings = root.get_node_or_null("GameSettings")
	if settings == null:
		_fail("GameSettings autoload should exist.")
		return
	settings.reset_to_defaults()

	var popup = SETTINGS_POPUP_SCENE.instantiate()
	root.add_child(popup)
	await process_frame

	if popup.is_popup_open():
		_fail("Settings popup should start closed.")
		return

	popup.open_popup()
	await process_frame
	if not popup.is_popup_open():
		_fail("Settings popup should open on request.")
		return
	if popup.volume_slider.min_value != 0.0 or popup.volume_slider.max_value != 100.0:
		_fail("Volume slider should cover 0 to 100.")
		return
	if int(popup.volume_slider.value) != 100:
		_fail("Volume slider should default to 100.")
		return

	popup.volume_slider.value = 35.0
	await process_frame
	if settings.volume_percent != 35:
		_fail("Volume slider changes should update GameSettings immediately.")
		return

	popup.attack_vibration_toggle.button_pressed = false
	await process_frame
	if settings.attack_vibration_enabled:
		_fail("Attack vibration toggle should update GameSettings immediately.")
		return
	if not popup.attack_vibration_toggle.text.ends_with("OFF"):
		_fail("Attack vibration toggle should display OFF when disabled.")
		return

	popup.player_hurt_vibration_toggle.button_pressed = false
	await process_frame
	if settings.player_hurt_vibration_enabled:
		_fail("Player hurt vibration toggle should update GameSettings immediately.")
		return
	if not popup.player_hurt_vibration_toggle.text.ends_with("OFF"):
		_fail("Player hurt vibration toggle should display OFF when disabled.")
		return

	popup.close_popup()
	await process_frame
	if popup.is_popup_open():
		_fail("Settings popup should close on request.")
		return

	settings.reset_to_defaults()
	popup.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
