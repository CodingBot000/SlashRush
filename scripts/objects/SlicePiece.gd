extends RigidBody2D
class_name SlicePiece

var _launch_impulse := Vector2.ZERO
var _launch_torque := 0.0
var _lifetime := 1.2

func setup(
	piece_color: Color,
	points: PackedVector2Array,
	launch_impulse: Vector2,
	launch_torque: float,
	lifetime: float = 1.2,
	piece_texture: Texture2D = null,
	uvs: PackedVector2Array = PackedVector2Array(),
	cut_edge: PackedVector2Array = PackedVector2Array()
) -> void:
	_launch_impulse = launch_impulse
	_launch_torque = launch_torque
	_lifetime = lifetime
	gravity_scale = 1.2
	linear_damp = 0.15
	angular_damp = 0.05

	var polygon := Polygon2D.new()
	polygon.name = "Polygon2D"
	polygon.polygon = points
	if piece_texture:
		polygon.texture = piece_texture
		polygon.uv = uvs
		polygon.color = Color.WHITE
	else:
		polygon.color = piece_color
	add_child(polygon)

	if cut_edge.size() >= 2 and not piece_texture:
		var edge := Line2D.new()
		edge.name = "CutEdge"
		edge.points = cut_edge
		edge.width = 3.0
		edge.default_color = Color(1.0, 1.0, 1.0, 0.45)
		add_child(edge)

	var collision := CollisionPolygon2D.new()
	collision.name = "CollisionPolygon2D"
	collision.polygon = points
	add_child(collision)

func _ready() -> void:
	apply_impulse(_launch_impulse)
	apply_torque_impulse(_launch_torque)
	var timer := get_tree().create_timer(_lifetime)
	timer.timeout.connect(Callable(self, "queue_free"))
