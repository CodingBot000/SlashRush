extends Node2D
class_name ParallaxScroller

const SEGMENT_WIDTH := 420.0
const SEGMENT_COUNT := 5
const DEFAULT_VIEWPORT_SIZE := Vector2(1280.0, 720.0)

const SKY_TEXTURE_PATH := "res://assets/background/stage1/sky_static.png"
const FAR_TEXTURE_PATH := "res://assets/background/stage1/far_mountains_01.png"
const MID_TEXTURE_PATH := "res://assets/background/stage1/mid_structures_01.png"
const NEAR_TEXTURE_PATH := "res://assets/background/stage1/near_foreground_01.png"
const ENABLE_NEAR_FOREGROUND_LAYER := false

var alpha_key_shader: Shader

func setup() -> void:
	for child in get_children():
		child.queue_free()
	_add_sky()
	_add_image_layer("FarLayer", FAR_TEXTURE_PATH, 0.24, -80, Color.html("#94cbe6"), 350.0, 120.0)
	_add_image_layer("MidLayer", MID_TEXTURE_PATH, 0.58, -60, Color.html("#5c7788"), 430.0, 95.0)
	if ENABLE_NEAR_FOREGROUND_LAYER:
		_add_image_layer("NearLayer", NEAR_TEXTURE_PATH, 1.12, -40, Color.html("#2c4a42"), 515.0, 58.0)

func process_scroll(delta: float, run_speed: float) -> void:
	for layer in get_children():
		if not layer is Node2D:
			continue
		if not layer.has_meta("factor"):
			continue
		var factor := float(layer.get_meta("factor"))
		var uses_sprite_wrap := bool(layer.get_meta("uses_sprite_wrap", false))
		for item in layer.get_children():
			if item is Node2D:
				item.position.x -= run_speed * factor * delta
				if uses_sprite_wrap:
					_wrap_sprite_item(layer, item)
				elif item.position.x <= -SEGMENT_WIDTH:
					item.position.x += SEGMENT_WIDTH * float(SEGMENT_COUNT)

func _add_sky() -> void:
	var texture := _load_texture(SKY_TEXTURE_PATH)
	if texture == null:
		_add_sky_fallback()
		return

	var sky := Sprite2D.new()
	sky.name = "Sky"
	sky.texture = texture
	sky.centered = false
	sky.position = Vector2.ZERO
	sky.z_index = -100
	var viewport_size := _get_viewport_size()
	var texture_size := texture.get_size()
	var scale_value: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	sky.scale = Vector2(scale_value, scale_value)
	add_child(sky)

func _add_sky_fallback() -> void:
	push_warning("Failed to load sky texture: %s. Falling back to generated sky." % SKY_TEXTURE_PATH)
	var sky := Polygon2D.new()
	sky.name = "Sky"
	sky.color = Color.html("#8fd0ff")
	sky.z_index = -100
	sky.polygon = PackedVector2Array([
		Vector2(-80.0, -80.0),
		Vector2(1500.0, -80.0),
		Vector2(1500.0, 720.0),
		Vector2(-80.0, 720.0)
	])
	add_child(sky)

func _add_image_layer(layer_name: String, texture_path: String, factor: float, z_value: int, fallback_color: Color, fallback_base_y: float, fallback_height: float) -> void:
	var texture := _load_texture(texture_path)
	if texture == null:
		push_warning("Failed to load parallax texture: %s. Falling back to generated layer." % texture_path)
		_add_layer(layer_name, factor, fallback_color, fallback_base_y, fallback_height)
		return

	var layer := Node2D.new()
	layer.name = layer_name
	layer.z_index = z_value
	layer.set_meta("factor", factor)
	layer.set_meta("uses_sprite_wrap", true)
	add_child(layer)

	var viewport_size := _get_viewport_size()
	var texture_size := texture.get_size()
	var scale_value: float = viewport_size.y / texture_size.y
	var segment_width: float = texture_size.x * scale_value
	var segment_count: int = max(3, int(ceil(viewport_size.x / segment_width)) + 2)
	layer.set_meta("segment_width", segment_width)

	for index in range(segment_count):
		var sprite := Sprite2D.new()
		sprite.name = "%sSegment%d" % [layer_name, index]
		sprite.texture = texture
		sprite.centered = false
		sprite.position = Vector2(float(index) * segment_width, 0.0)
		sprite.scale = Vector2(scale_value, scale_value)
		sprite.material = _make_light_alpha_key_material()
		layer.add_child(sprite)

func _add_layer(layer_name: String, factor: float, color: Color, base_y: float, height: float) -> void:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.set_meta("factor", factor)
	add_child(layer)

	for index in range(SEGMENT_COUNT):
		var x := float(index) * SEGMENT_WIDTH
		if layer_name == "FarLayer":
			_add_mountain(layer, x, base_y, height, color)
			_add_cloud(layer, x + 130.0, 115.0 + float(index % 2) * 28.0)
		elif layer_name == "MidLayer":
			_add_columns(layer, x, base_y, height, color)
		else:
			_add_grass(layer, x, base_y, height, color)

func _add_mountain(parent: Node2D, x: float, y: float, height: float, color: Color) -> void:
	var mountain := Polygon2D.new()
	mountain.position = Vector2(x, y)
	mountain.color = color
	mountain.polygon = PackedVector2Array([
		Vector2(-80.0, 90.0),
		Vector2(120.0, -height),
		Vector2(360.0, 90.0)
	])
	parent.add_child(mountain)

func _add_cloud(parent: Node2D, x: float, y: float) -> void:
	for offset in [Vector2(0.0, 0.0), Vector2(32.0, -8.0), Vector2(68.0, 4.0)]:
		var cloud := Polygon2D.new()
		cloud.position = Vector2(x, y) + offset
		cloud.color = Color(1.0, 1.0, 1.0, 0.42)
		cloud.polygon = _circle_points(24.0, 16)
		parent.add_child(cloud)

func _add_columns(parent: Node2D, x: float, y: float, height: float, color: Color) -> void:
	for index in range(3):
		var width := 44.0 + float(index % 2) * 12.0
		var column := Polygon2D.new()
		column.position = Vector2(x + 45.0 + float(index) * 130.0, y)
		column.color = color
		column.polygon = PackedVector2Array([
			Vector2(-width * 0.5, 0.0),
			Vector2(width * 0.5, 0.0),
			Vector2(width * 0.5, -height),
			Vector2(-width * 0.5, -height)
		])
		parent.add_child(column)

func _add_grass(parent: Node2D, x: float, y: float, height: float, color: Color) -> void:
	for index in range(6):
		var tuft := Polygon2D.new()
		tuft.position = Vector2(x + 24.0 + float(index) * 68.0, y)
		tuft.color = color
		tuft.polygon = PackedVector2Array([
			Vector2(-20.0, 0.0),
			Vector2(-8.0, -height),
			Vector2(0.0, 0.0),
			Vector2(10.0, -height * 0.7),
			Vector2(24.0, 0.0)
		])
		parent.add_child(tuft)

func _circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _wrap_sprite_item(layer: Node2D, item: Node2D) -> void:
	var item_width := _get_sprite_width(item)
	if item_width <= 0.0:
		return
	if item.position.x + item_width >= -8.0:
		return

	var max_right := item.position.x + item_width
	for sibling in layer.get_children():
		if not sibling is Node2D:
			continue
		var sibling_width := _get_sprite_width(sibling)
		max_right = max(max_right, sibling.position.x + sibling_width)
	item.position.x = max_right

func _get_sprite_width(item: Node2D) -> float:
	if item is Sprite2D and item.texture != null:
		return item.texture.get_width() * item.scale.x
	return float(item.get_meta("segment_width", 0.0))

func _get_viewport_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return DEFAULT_VIEWPORT_SIZE
	return viewport_size

func _load_texture(path: String) -> Texture2D:
	var resource := load(path)
	if resource is Texture2D:
		return resource
	return null

func _make_light_alpha_key_material() -> ShaderMaterial:
	if alpha_key_shader == null:
		alpha_key_shader = Shader.new()
		alpha_key_shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float max_channel = max(max(tex.r, tex.g), tex.b);
	float min_channel = min(min(tex.r, tex.g), tex.b);
	bool light_neutral = min_channel > 0.86 && (max_channel - min_channel) < 0.045;
	if (light_neutral) {
		tex.a = 0.0;
	}
	COLOR = tex * COLOR;
}
"""
	var material := ShaderMaterial.new()
	material.shader = alpha_key_shader
	return material
