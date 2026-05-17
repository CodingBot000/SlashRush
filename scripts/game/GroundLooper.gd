extends Node2D
class_name GroundLooper

const DEFAULT_VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const GROUND_TEXTURE_PATH := "res://assets/background/stage1/ground_tile_01.png"
const GROUND_SURFACE_OFFSET := 222.0

var tile_width := 220.0
var tile_count := 8
var ground_y := 560.0
var ground_height := 120.0
var alpha_key_shader: Shader

func setup() -> void:
	for child in get_children():
		child.queue_free()
	var texture := _load_texture(GROUND_TEXTURE_PATH)
	if texture == null:
		_add_generated_ground()
		return

	z_index = -20
	var viewport_size := _get_viewport_size()
	var texture_size := texture.get_size()
	var scale_value: float = viewport_size.y / texture_size.y
	tile_width = texture_size.x * scale_value
	tile_count = max(4, int(ceil(viewport_size.x / tile_width)) + 2)
	var tile_y := ground_y - GROUND_SURFACE_OFFSET * scale_value

	for index in range(tile_count):
		var tile := Sprite2D.new()
		tile.name = "GroundTile%d" % index
		tile.texture = texture
		tile.centered = false
		tile.position = Vector2(float(index) * tile_width, tile_y)
		tile.scale = Vector2(scale_value, scale_value)
		tile.material = _make_light_alpha_key_material()
		add_child(tile)

func process_scroll(delta: float, speed: float) -> void:
	for child in get_children():
		if child is Node2D:
			child.position.x -= speed * delta
			_wrap_tile(child)

func _add_generated_ground() -> void:
	push_warning("Failed to load ground texture: %s. Falling back to generated ground." % GROUND_TEXTURE_PATH)
	z_index = -20
	for index in range(tile_count):
		var tile := Polygon2D.new()
		tile.name = "GroundTile%d" % index
		tile.position = Vector2(float(index) * tile_width, ground_y)
		tile.color = Color.html("#38412f") if index % 2 == 0 else Color.html("#455035")
		tile.polygon = PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(tile_width, 0.0),
			Vector2(tile_width, ground_height),
			Vector2(0.0, ground_height)
		])
		add_child(tile)

		var top_line := Line2D.new()
		top_line.points = PackedVector2Array([Vector2(0.0, 0.0), Vector2(tile_width, 0.0)])
		top_line.width = 5.0
		top_line.default_color = Color.html("#9aa55f")
		tile.add_child(top_line)

func _wrap_tile(tile: Node2D) -> void:
	var width := _get_tile_width(tile)
	if width <= 0.0:
		return
	if tile.position.x + width >= -8.0:
		return

	var max_right := tile.position.x + width
	for sibling in get_children():
		if not sibling is Node2D:
			continue
		var sibling_width := _get_tile_width(sibling)
		max_right = max(max_right, sibling.position.x + sibling_width)
	tile.position.x = max_right

func _get_tile_width(tile: Node2D) -> float:
	if tile is Sprite2D and tile.texture != null:
		return tile.texture.get_width() * tile.scale.x
	return tile_width

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
