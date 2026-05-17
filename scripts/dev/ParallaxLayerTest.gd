extends SceneTree

const PARALLAX_SCROLLER_SCRIPT := preload("res://scripts/game/ParallaxScroller.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var parallax = PARALLAX_SCROLLER_SCRIPT.new()
	root.add_child(parallax)
	parallax.setup()
	await process_frame

	var sky = parallax.get_node_or_null("Sky")
	var cloud_layer = parallax.get_node_or_null("CloudLayer")
	var far_layer = parallax.get_node_or_null("FarLayer")
	if sky == null:
		_fail("Static sky node should exist.")
		return
	if cloud_layer == null:
		_fail("Cloud layer should exist.")
		return
	if far_layer == null:
		_fail("Far layer should exist.")
		return
	if sky.has_meta("factor"):
		_fail("Static sky should not have a scroll factor.")
		return
	if float(cloud_layer.get_meta("factor", 1.0)) >= float(far_layer.get_meta("factor", 0.0)):
		_fail("Cloud layer should scroll slower than the far layer.")
		return
	if cloud_layer.z_index <= sky.z_index or cloud_layer.z_index >= far_layer.z_index:
		_fail("Cloud layer should be above sky and below far scenery.")
		return

	var sky_start_x: float = sky.position.x
	var cloud_start_x: float = cloud_layer.get_child(0).position.x
	parallax.process_scroll(1.0, 100.0)
	if sky.position.x != sky_start_x:
		_fail("Static sky should not move during parallax scroll.")
		return
	if cloud_layer.get_child(0).position.x >= cloud_start_x:
		_fail("Cloud layer should scroll left during parallax scroll.")
		return

	parallax.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
