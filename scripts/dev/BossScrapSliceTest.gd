extends SceneTree

const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage = BOSS_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	if stage.boss_hit_scrap_textures.size() != 7:
		_fail("BossStage should load seven boss scrap textures.")
		return

	var first_cycle := []
	for _index in range(7):
		var texture = stage._get_next_boss_hit_scrap_texture()
		if texture == null:
			_fail("Boss scrap texture sequence should not return null.")
			return
		first_cycle.append(texture)

	if stage._get_next_boss_hit_scrap_texture() != first_cycle[0]:
		_fail("Boss scrap texture sequence should loop after the last image.")
		return

	stage.start_boss(0, 0, GameBalance.MAX_HP)
	stage._success_pattern()
	await process_frame

	if stage.piece_root.z_index <= _max_effective_z_index(stage.boss_root):
		_fail("Boss slice pieces should render in front of every boss visual part.")
		return
	if stage.boss_hit_scrap_index != 1:
		_fail("Boss hit should consume exactly one scrap texture.")
		return
	if stage.piece_root.get_child_count() < 2:
		_fail("Boss hit should still create split slice pieces.")
		return

	for piece in stage.piece_root.get_children():
		var polygon = piece.find_child("Polygon2D", true, false)
		if polygon == null or polygon.texture == null:
			_fail("Boss slice pieces should use scrap image textures instead of plain colored polygons.")
			return
		if _max_polygon_extent(polygon.polygon) < 160.0:
			_fail("Boss scrap slice pieces should render at the enlarged hit size.")
			return

	stage.stop_boss()
	stage.queue_free()
	await process_frame
	quit()

func _max_polygon_extent(points: PackedVector2Array) -> float:
	var max_extent := 0.0
	for point in points:
		max_extent = maxf(max_extent, maxf(absf(point.x), absf(point.y)))
	return max_extent

func _max_effective_z_index(node: Node, inherited_z_index: int = 0) -> int:
	var current_z_index := inherited_z_index
	if node is CanvasItem:
		var canvas_item := node as CanvasItem
		current_z_index = inherited_z_index + canvas_item.z_index if canvas_item.z_as_relative else canvas_item.z_index

	var max_z_index := current_z_index
	for child in node.get_children():
		max_z_index = maxi(max_z_index, _max_effective_z_index(child, current_z_index))
	return max_z_index

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
