extends Control
class_name HeartDisplay

const FULL_COLOR := Color(1.0, 0.22, 0.34, 1.0)
const EMPTY_FILL_COLOR := Color(0.0, 0.0, 0.0, 0.24)
const EMPTY_OUTLINE_COLOR := Color(1.0, 0.36, 0.45, 0.82)
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.78)
const HEART_SIZE := Vector2(29.0, 27.0)
const HEART_SPACING := 9.0

var max_hp := 3
var current_hp := 3

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_hp(value: int, max_value: int) -> void:
	max_hp = maxi(0, max_value)
	current_hp = clampi(value, 0, max_hp)
	queue_redraw()

func _draw() -> void:
	for index in range(max_hp):
		var origin := Vector2(float(index) * (HEART_SIZE.x + HEART_SPACING), 6.0)
		_draw_heart(origin, index < current_hp)

func _draw_heart(origin: Vector2, filled: bool) -> void:
	var points := _heart_points(origin, HEART_SIZE)
	var closed_points := PackedVector2Array(points)
	closed_points.append(points[0])
	if filled:
		draw_colored_polygon(points, FULL_COLOR)
		draw_polyline(closed_points, OUTLINE_COLOR, 3.0, true)
	else:
		draw_colored_polygon(points, EMPTY_FILL_COLOR)
		draw_polyline(closed_points, OUTLINE_COLOR, 4.0, true)
		draw_polyline(closed_points, EMPTY_OUTLINE_COLOR, 2.0, true)

func _heart_points(origin: Vector2, size_value: Vector2) -> PackedVector2Array:
	var raw_points := [
		Vector2(0.50, 0.98),
		Vector2(0.08, 0.56),
		Vector2(0.02, 0.34),
		Vector2(0.08, 0.16),
		Vector2(0.22, 0.04),
		Vector2(0.38, 0.07),
		Vector2(0.50, 0.22),
		Vector2(0.62, 0.07),
		Vector2(0.78, 0.04),
		Vector2(0.92, 0.16),
		Vector2(0.98, 0.34),
		Vector2(0.92, 0.56)
	]
	var points := PackedVector2Array()
	for point in raw_points:
		points.append(origin + Vector2(point.x * size_value.x, point.y * size_value.y))
	return points
