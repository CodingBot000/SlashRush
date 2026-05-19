extends RefCounted
class_name ViewportUtil

const DEFAULT_VIEWPORT_SIZE := Vector2(1280.0, 720.0)

static func get_viewport_size(owner: Node, fallback: Vector2 = DEFAULT_VIEWPORT_SIZE) -> Vector2:
	if owner == null:
		return fallback
	var viewport_size: Vector2 = owner.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return fallback
	return viewport_size

static func get_visible_viewport_size(owner: Node, fallback: Vector2 = DEFAULT_VIEWPORT_SIZE) -> Vector2:
	if owner == null or owner.get_viewport() == null:
		return fallback
	var viewport_size: Vector2 = owner.get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return fallback
	return viewport_size
