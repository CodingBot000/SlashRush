extends SceneTree

const FEVER_IMPACT_OVERLAY_SCRIPT := preload("res://scripts/effects/FeverImpactOverlay.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var overlay = FEVER_IMPACT_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	await process_frame

	if overlay.visible:
		_fail("Fever impact overlay should start hidden.")
		return
	if overlay.is_processing():
		_fail("Fever impact overlay should not process while inactive.")
		return
	if overlay.speed_lines.size() != 100:
		_fail("Fever impact overlay should prebuild speed lines.")
		return
	if overlay.burst_pool.size() != 8:
		_fail("Fever impact overlay should prebuild burst nodes.")
		return

	overlay.set_active(true)
	await process_frame
	if not overlay.visible or not overlay.is_processing():
		_fail("Fever impact overlay should become visible and process when active.")
		return

	var line = overlay.speed_lines[0]
	if line.width < 25.0 or line.width > 45.0:
		_fail("Fever speed lines should use the dense fever width range.")
		return
	line.position = Vector2(600.0, 120.0)
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(900.0, 0.0)])
	line.set_meta("speed", 2000.0)
	var start_x: float = line.position.x
	overlay._process(0.1)
	if line.position.x >= start_x:
		_fail("Fever speed lines should move left while active.")
		return

	overlay.set_active(false)
	await process_frame
	if overlay.visible or overlay.is_processing():
		_fail("Fever impact overlay should hide and stop processing when inactive.")
		return

	overlay.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
