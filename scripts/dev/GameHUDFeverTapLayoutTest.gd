extends SceneTree

const GAME_HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var hud = GAME_HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame
	hud.show_runner()
	hud.update_runner(0, 3, 0, 0, true, 0)
	await process_frame

	var viewport_size := root.get_visible_rect().size
	var label_center: Vector2 = hud.fever_tap_label.position + hud.fever_tap_label.size * 0.5
	var expected_center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.2)
	if not label_center.is_equal_approx(expected_center):
		_fail("Fever TAP label should be centered horizontally and placed at 1/5 screen height.")
		return
	if hud.fever_tap_label.pivot_offset != hud.fever_tap_label.size * 0.5:
		_fail("Fever TAP label should scale from its centered pivot.")
		return

	hud.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
