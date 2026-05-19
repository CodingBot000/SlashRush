extends Area2D
class_name InteractableObject

const ObjectTypes := preload("res://scripts/data/ObjectTypes.gd")
const ObjectVisualEffectUtil := preload("res://scripts/utils/ObjectVisualEffectUtil.gd")

const ENEMY_SPRING_JUMP_ENABLED := true
const ENEMY_SPRING_JUMP_DEFORM_ENABLED := true

@export var object_type := "enemy_basic"
@export var required_action := "tap"
@export var is_good_item := false
@export var score_value := 100
@export var fever_value := 6
@export var damage_on_fail := 1

var display_color := Color.html("#e94c4c")
var object_size := Vector2(82.0, 112.0)
var spawn_y_offset := 0.0
var slice_texture: Texture2D
var slice_render_size := Vector2.ZERO
var handled := false
var visual_center_offset := Vector2.ZERO
var visual_effect_target: Node2D
var visual_effect_mode := ""
var visual_effect_time := 0.0
var visual_effect_base_position := Vector2.ZERO
var visual_effect_base_scale := Vector2.ONE
var float_offset_y := 0.0
var float_velocity_y := 0.0
var visual_effect_time_offset := 0.0
var visual_effect_base_object_y := 0.0
var visual_effect_has_object_base_y := false

func setup(type_name: String, visual_set = null) -> void:
	object_type = type_name
	var data: Dictionary = ObjectTypes.get_data(type_name)
	if visual_set != null and visual_set.has_method("get_visual"):
		data = data.duplicate(true)
		var visual_data: Dictionary = visual_set.get_visual(type_name)
		for key in visual_data.keys():
			data[key] = visual_data[key]
	required_action = data["required_action"]
	is_good_item = data["is_good_item"]
	score_value = data["score"]
	fever_value = data["fever"]
	damage_on_fail = data["damage"]
	display_color = data["color"]
	object_size = data["size"]
	spawn_y_offset = float(data.get("spawn_y_offset", 0.0))
	_build_visual(data)

func disable_collision() -> void:
	monitoring = false
	monitorable = false
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true

func get_slice_color() -> Color:
	return display_color

func get_slice_size() -> Vector2:
	return slice_render_size if slice_render_size != Vector2.ZERO else object_size

func get_slice_texture() -> Texture2D:
	return slice_texture

func get_slice_center_global() -> Vector2:
	if visual_effect_target != null:
		return visual_effect_target.global_position
	return global_position + visual_center_offset

func _ready() -> void:
	if get_child_count() == 0:
		setup(object_type)

func _process(delta: float) -> void:
	if visual_effect_mode.is_empty() or visual_effect_target == null:
		return

	visual_effect_time += delta
	var effect_time := visual_effect_time + visual_effect_time_offset

	if visual_effect_mode == "pickup_float":
		_process_pickup_visual_effect(delta, effect_time)
	elif visual_effect_mode == "enemy_spring_jump":
		_process_enemy_visual_effect(effect_time)

func _process_pickup_visual_effect(delta: float, effect_time: float) -> void:
	visual_effect_target.scale = visual_effect_base_scale
	var result := ObjectVisualEffectUtil.calculate_floating_spring_y(
		delta,
		effect_time,
		visual_effect_base_position.y,
		float_offset_y,
		float_velocity_y,
		8.0,
		1.1,
		14.0,
		5.0
	)
	visual_effect_target.position.y = result["y"]
	float_offset_y = result["offset_y"]
	float_velocity_y = result["velocity_y"]

func _process_enemy_visual_effect(effect_time: float) -> void:
	if not visual_effect_has_object_base_y:
		visual_effect_base_object_y = position.y
		visual_effect_has_object_base_y = true

	var jump_height := 84.0
	var jump_speed := 1.55
	var squash_x := 1.10
	var squash_y := 1.07
	var stretch_x := 1.02
	var stretch_y := 1.07

	if object_type == "enemy_armor":
		jump_height = 56.0
		jump_speed = 1.2
		squash_x = 1.02
		squash_y = 1.03
		stretch_x = 1.03
		stretch_y = 1.04
	elif object_type == "enemy_fast":
		jump_height = 104.0
		jump_speed = 2.05
		squash_x = 1.05
		squash_y = 1.09
		stretch_x = 1.09
		stretch_y = 1.07

	if not ENEMY_SPRING_JUMP_DEFORM_ENABLED:
		squash_x = 1.0
		squash_y = 1.0
		stretch_x = 1.0
		stretch_y = 1.0

	ObjectVisualEffectUtil.apply_spring_jump_squash_stretch(
		visual_effect_target,
		effect_time,
		visual_effect_base_position,
		visual_effect_base_scale,
		jump_height,
		jump_speed,
		squash_x,
		squash_y,
		stretch_x,
		stretch_y,
		0.16,
		true,
		self,
		visual_effect_base_object_y
	)

func _build_visual(data: Dictionary) -> void:
	visual_effect_target = null
	visual_effect_mode = ""
	for child in get_children():
		child.queue_free()

	var shape_name: String = String(data["shape"])
	var texture_path := String(data.get("texture", ""))
	var texture := _load_icon_texture(texture_path)
	var slice_texture_path := String(data.get("slice_texture", texture_path))
	slice_texture = _load_icon_texture(slice_texture_path)
	if slice_texture == null:
		slice_texture = texture
	slice_render_size = Vector2.ZERO
	visual_center_offset = Vector2(0.0, -object_size.y * 0.5) if texture else _get_visual_center_offset(shape_name)
	if texture:
		_add_sprite_visual(texture)
	else:
		_add_placeholder_visual(data, shape_name)

	_add_collision(shape_name)
	_configure_visual_effect()

func _add_sprite_visual(texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "IconSprite"
	sprite.texture = texture
	var texture_size: Vector2 = texture.get_size()
	var scale_value: float = object_size.y / texture_size.y
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.position = visual_center_offset
	slice_render_size = texture_size * scale_value
	visual_effect_target = sprite
	add_child(sprite)

func _add_placeholder_visual(data: Dictionary, shape_name: String) -> void:
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.position = visual_center_offset
	visual.color = display_color
	slice_render_size = object_size
	visual_effect_target = visual
	match shape_name:
		"circle":
			visual.polygon = _circle_points(max(object_size.x, object_size.y) * 0.5, 24)
		"diamond":
			visual.polygon = PackedVector2Array([
				Vector2(0.0, -object_size.y * 0.56),
				Vector2(object_size.x * 0.55, 0.0),
				Vector2(0.0, object_size.y * 0.56),
				Vector2(-object_size.x * 0.55, 0.0)
			])
		_:
			visual.polygon = PackedVector2Array([
				Vector2(-object_size.x * 0.5, -object_size.y * 0.5),
				Vector2(object_size.x * 0.5, -object_size.y * 0.5),
				Vector2(object_size.x * 0.5, object_size.y * 0.5),
				Vector2(-object_size.x * 0.5, object_size.y * 0.5)
			])
	add_child(visual)

	var outline := Line2D.new()
	outline.name = "Outline"
	outline.position = visual_center_offset
	outline.width = 4.0
	outline.default_color = Color(1.0, 1.0, 1.0, 0.55)
	var outline_points := visual.polygon
	if outline_points.size() > 0:
		outline_points.append(outline_points[0])
	outline.points = outline_points
	add_child(outline)

	var label := Label.new()
	label.name = "IconLabel"
	label.text = String(data["label"])
	label.position = visual_center_offset + Vector2(-42.0, -28.0)
	label.size = Vector2(84.0, 56.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	add_child(label)

func _add_collision(shape_name: String) -> void:
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.position = visual_center_offset
	if shape_name == "circle":
		var circle := CircleShape2D.new()
		circle.radius = max(object_size.x, object_size.y) * 0.5
		collision.shape = circle
	else:
		var rect := RectangleShape2D.new()
		rect.size = object_size
		collision.shape = rect
	add_child(collision)

func _configure_visual_effect() -> void:
	visual_effect_time = 0.0
	float_offset_y = 0.0
	float_velocity_y = 0.0
	visual_effect_time_offset = randf() * TAU
	visual_effect_base_object_y = 0.0
	visual_effect_has_object_base_y = false

	if visual_effect_target == null:
		return

	if is_good_item or object_type == "bomb":
		visual_effect_base_position = visual_effect_target.position
		visual_effect_base_scale = visual_effect_target.scale
		visual_effect_mode = "pickup_float"
		return

	if ENEMY_SPRING_JUMP_ENABLED and object_type.begins_with("enemy_"):
		visual_effect_base_position = visual_effect_target.position
		visual_effect_base_scale = visual_effect_target.scale
		visual_effect_mode = "enemy_spring_jump"

func _get_visual_center_offset(shape_name: String) -> Vector2:
	match shape_name:
		"circle":
			return Vector2(0.0, -max(object_size.x, object_size.y) * 0.5)
		"diamond":
			return Vector2(0.0, -object_size.y * 0.56)
		_:
			return Vector2(0.0, -object_size.y * 0.5)

func _load_icon_texture(texture_path: String) -> Texture2D:
	if texture_path.is_empty():
		return null
	if ResourceLoader.exists(texture_path, "Texture2D"):
		var imported_texture := load(texture_path)
		if imported_texture is Texture2D:
			return imported_texture
	var image := Image.new()
	if image.load(texture_path) == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

func _circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
