extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	if main.state != "runner":
		_fail("Main should start in runner state.")
		return
	if not main.pause_overlay.pause_button.visible:
		_fail("Pause button should be visible during runner stage.")
		return
	_assert_pause_popup(main, "runner")

	main.current_hp = 1
	main._start_boss()
	await process_frame

	if main.state != "boss":
		_fail("Main should enter boss state.")
		return
	if not main.pause_overlay.pause_button.visible:
		_fail("Pause button should be visible during boss stage.")
		return
	_assert_pause_popup(main, "boss")

	main.pause_overlay.open_popup()
	if not paused:
		_fail("Opening pause popup should pause the SceneTree.")
		return
	main._show_result(false)
	if paused:
		_fail("Showing result should unpause the SceneTree.")
		return
	if main.pause_overlay.pause_button.visible:
		_fail("Pause button should be hidden on result popup.")
		return

	main.queue_free()
	await process_frame
	quit()

func _assert_pause_popup(main, stage_name: String) -> void:
	main.pause_overlay.open_popup()
	if not paused:
		_fail("Opening pause popup should pause the SceneTree in %s." % stage_name)
		return
	if not main.pause_overlay.is_popup_open():
		_fail("Pause popup should be visible in %s." % stage_name)
		return
	main.pause_overlay.close_popup()
	if paused:
		_fail("Closing pause popup should unpause the SceneTree in %s." % stage_name)
		return
	if main.pause_overlay.is_popup_open():
		_fail("Pause popup should be hidden after resume in %s." % stage_name)
		return

func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
