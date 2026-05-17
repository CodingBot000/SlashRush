extends Node
class_name SliceEffectFactory

const SLICE_PIECE_SCENE := preload("res://scenes/objects/SlicePiece.tscn")
const CUT_EPSILON := 0.001
const DEFAULT_CUT_START_ANGLE := 260.0
const DEFAULT_CUT_END_ANGLE := 80.0

func spawn_slice(parent: Node, global_pos: Vector2, piece_color: Color, source_size: Vector2, heavy: bool = false, source_texture: Texture2D = null, cut_angles: Dictionary = {}) -> void:
	var width: float = max(source_size.x, 56.0)
	var height: float = max(source_size.y, 56.0)
	var top_left := Vector2(-width * 0.5, -height * 0.5)
	var top_right := Vector2(width * 0.5, -height * 0.5)
	var bottom_right := Vector2(width * 0.5, height * 0.5)
	var bottom_left := Vector2(-width * 0.5, height * 0.5)
	var upper_points := PackedVector2Array()
	var lower_points := PackedVector2Array()
	var cut_edge := PackedVector2Array()
	var rect_points := PackedVector2Array([
		top_left,
		top_right,
		bottom_right,
		bottom_left
	])
	var radius: float = max(width, height)
	var cut_start := _angle_to_cut_point(float(cut_angles.get("start_angle", DEFAULT_CUT_START_ANGLE)), radius)
	var cut_end := _angle_to_cut_point(float(cut_angles.get("end_angle", DEFAULT_CUT_END_ANGLE)), radius)
	upper_points = _clip_polygon_by_cut(rect_points, cut_start, cut_end, -1.0)
	lower_points = _clip_polygon_by_cut(rect_points, cut_start, cut_end, 1.0)
	cut_edge = _get_cut_edge(rect_points, cut_start, cut_end)

	if upper_points.size() < 3 or lower_points.size() < 3:
		upper_points = PackedVector2Array([
			top_left,
			top_right,
			bottom_right
		])
		lower_points = PackedVector2Array([
			top_left,
			bottom_right,
			bottom_left
		])
		cut_edge = PackedVector2Array([cut_start, cut_end])

	var upper_uvs := PackedVector2Array()
	var lower_uvs := PackedVector2Array()
	if source_texture:
		var texture_size := source_texture.get_size()
		upper_uvs = _make_texture_uvs(upper_points, Vector2(width, height), texture_size)
		lower_uvs = _make_texture_uvs(lower_points, Vector2(width, height), texture_size)

	var impulse_scale: float = 1.35 if heavy else 1.0
	_create_piece(parent, global_pos + Vector2(-12.0, 6.0), piece_color, lower_points, Vector2(-170.0, -360.0) * impulse_scale, -4600.0 * impulse_scale, source_texture, lower_uvs, cut_edge)
	_create_piece(parent, global_pos + Vector2(12.0, -6.0), piece_color.lightened(0.08), upper_points, Vector2(190.0, -330.0) * impulse_scale, 5200.0 * impulse_scale, source_texture, upper_uvs, cut_edge)

func _create_piece(
	parent: Node,
	global_pos: Vector2,
	color: Color,
	points: PackedVector2Array,
	impulse: Vector2,
	torque: float,
	texture: Texture2D = null,
	uvs: PackedVector2Array = PackedVector2Array(),
	cut_edge: PackedVector2Array = PackedVector2Array()
) -> void:
	var piece := SLICE_PIECE_SCENE.instantiate()
	piece.setup(color, points, impulse, torque, 1.2, texture, uvs, cut_edge)
	if parent is Node2D:
		piece.position = parent.to_local(global_pos)
	parent.add_child(piece)
	if not parent is Node2D:
		piece.global_position = global_pos

func _angle_to_cut_point(degrees: float, radius: float) -> Vector2:
	var radians := deg_to_rad(degrees)
	return Vector2(sin(radians), -cos(radians)) * radius

func _clip_polygon_by_cut(points: PackedVector2Array, cut_start: Vector2, cut_end: Vector2, side_sign: float) -> PackedVector2Array:
	var input := []
	for point in points:
		input.append(point)

	var output := []
	for index in range(input.size()):
		var current: Vector2 = input[index]
		var previous: Vector2 = input[(index - 1 + input.size()) % input.size()]
		var current_inside := _is_inside_cut_side(current, cut_start, cut_end, side_sign)
		var previous_inside := _is_inside_cut_side(previous, cut_start, cut_end, side_sign)

		if current_inside:
			if not previous_inside:
				output.append(_line_segment_cut_intersection(previous, current, cut_start, cut_end))
			output.append(current)
		elif previous_inside:
			output.append(_line_segment_cut_intersection(previous, current, cut_start, cut_end))

	var clipped := PackedVector2Array()
	for point in output:
		clipped.append(point)
	return clipped

func _is_inside_cut_side(point: Vector2, cut_start: Vector2, cut_end: Vector2, side_sign: float) -> bool:
	return _cut_side(point, cut_start, cut_end) * side_sign >= -CUT_EPSILON

func _cut_side(point: Vector2, cut_start: Vector2, cut_end: Vector2) -> float:
	return (cut_end - cut_start).cross(point - cut_start)

func _line_segment_cut_intersection(segment_start: Vector2, segment_end: Vector2, cut_start: Vector2, cut_end: Vector2) -> Vector2:
	var start_side := _cut_side(segment_start, cut_start, cut_end)
	var end_side := _cut_side(segment_end, cut_start, cut_end)
	var denominator := start_side - end_side
	if absf(denominator) <= CUT_EPSILON:
		return segment_end

	var t: float = clampf(start_side / denominator, 0.0, 1.0)
	return segment_start.lerp(segment_end, t)

func _get_cut_edge(rect_points: PackedVector2Array, cut_start: Vector2, cut_end: Vector2) -> PackedVector2Array:
	var edge_points := []
	for index in range(rect_points.size()):
		var current := rect_points[index]
		var next := rect_points[(index + 1) % rect_points.size()]
		var current_side := _cut_side(current, cut_start, cut_end)
		var next_side := _cut_side(next, cut_start, cut_end)

		if absf(current_side) <= CUT_EPSILON:
			_append_unique_point(edge_points, current)
		if current_side * next_side < -CUT_EPSILON:
			_append_unique_point(edge_points, _line_segment_cut_intersection(current, next, cut_start, cut_end))
		elif absf(next_side) <= CUT_EPSILON:
			_append_unique_point(edge_points, next)

	if edge_points.size() < 2:
		return PackedVector2Array()

	var edge_start: Vector2 = edge_points[0]
	var edge_end: Vector2 = edge_points[1]
	var best_distance := -1.0
	for start_index in range(edge_points.size()):
		for end_index in range(start_index + 1, edge_points.size()):
			var distance: float = edge_points[start_index].distance_squared_to(edge_points[end_index])
			if distance > best_distance:
				best_distance = distance
				edge_start = edge_points[start_index]
				edge_end = edge_points[end_index]

	return PackedVector2Array([edge_start, edge_end])

func _append_unique_point(points: Array, point: Vector2) -> void:
	for existing in points:
		if existing.distance_squared_to(point) <= 0.25:
			return
	points.append(point)

func _make_texture_uvs(points: PackedVector2Array, source_size: Vector2, texture_size: Vector2) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(Vector2(
			(point.x + source_size.x * 0.5) / source_size.x * texture_size.x,
			(point.y + source_size.y * 0.5) / source_size.y * texture_size.y
		))
	return uvs
