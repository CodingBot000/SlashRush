extends SceneTree

const RESULT_PANEL_SCENE := preload("res://scenes/ui/ResultPanel.tscn")

var retry_count := 0
var quit_count := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel = RESULT_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame

	panel.retry_requested.connect(_on_retry_requested)
	panel.quit_requested.connect(_on_quit_requested)

	panel.show_title(1200)
	if panel.quit_button.visible:
		push_error("Quit button should be hidden on title screen.")
		quit(1)
		return

	panel.show_result(false, 320, 40, 1200, Vector2(210.0, 500.0))
	if panel.title_label.text != "GAME OVER":
		push_error("Game over title was not shown.")
		quit(1)
		return
	if panel.retry_button.text != "RETRY" or not panel.quit_button.visible:
		push_error("Result buttons were not configured.")
		quit(1)
		return
	if panel.find_child("Popup", true, false) != null:
		push_error("Result UI should not use a visible popup container.")
		quit(1)
		return
	if not panel.dead_overlay_sprite.visible or panel.dead_overlay_sprite.z_index <= panel.dim.z_index:
		push_error("Dead overlay should be visible above the dim layer.")
		quit(1)
		return
	if panel.dim.color.a > 0.01:
		push_error("Game over dim should start transparent before fading in.")
		quit(1)
		return
	await create_timer(1.1).timeout
	if panel.dim.color.a < 0.8:
		push_error("Game over dim should fade in over time.")
		quit(1)
		return

	panel._on_retry_pressed()
	panel._on_quit_pressed()
	if retry_count != 1 or quit_count != 1:
		push_error("Result panel button signals were not emitted.")
		quit(1)
		return

	quit()

func _on_retry_requested() -> void:
	retry_count += 1

func _on_quit_requested() -> void:
	quit_count += 1
