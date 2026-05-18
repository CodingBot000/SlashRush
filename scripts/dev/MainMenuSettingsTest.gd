extends SceneTree

const MAIN_MENU_SCENE := preload("res://scenes/game/MainMenu.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame

	var settings_button = menu.find_child("SettingsButton", true, false)
	if settings_button == null:
		_fail("MainMenu should create a SettingsButton.")
		return
	if menu.settings_popup == null:
		_fail("MainMenu should create a reusable SettingsPopup instance.")
		return
	if menu.settings_popup.is_popup_open():
		_fail("MainMenu SettingsPopup should start closed.")
		return

	settings_button.emit_signal("pressed")
	await process_frame
	if not menu.settings_popup.is_popup_open():
		_fail("Pressing MainMenu SettingsButton should open SettingsPopup.")
		return

	menu.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
