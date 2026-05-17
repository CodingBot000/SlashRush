extends Node2D
class_name PlayerController

const CHARACTER_KEY_SHADER := preload("res://assets/shaders/character_key.gdshader")
const GameBalance := preload("res://scripts/data/GameBalance.gd")
const RUN_FRAME_PATHS := [
	"res://assets/sprites/samurai/run/frame_01.png",
	"res://assets/sprites/samurai/run/frame_02.png",
	"res://assets/sprites/samurai/run/frame_03.png",
	"res://assets/sprites/samurai/run/frame_04.png",
	"res://assets/sprites/samurai/run/frame_05.png",
	"res://assets/sprites/samurai/run/frame_06.png",
]
const RUN_ANIMATION_NAME := "run"
const RUN_ANIMATION_FPS := 12.0
const SLASH_EFFECT_PATH := "res://assets/sprites/effect/slash_sword/slash_effect.png"

var visual_root: Node2D
var foot_shadow: Polygon2D
var slash_effect: Sprite2D
var _slash_tween: Tween
var _slash_effect_base_scale := Vector2.ONE
var _base_visual_y := 0.0

func _ready() -> void:
	_build_visual()

func _process(_delta: float) -> void:
	if visual_root:
		var bob := sin(float(Time.get_ticks_msec()) / 90.0) * 2.5
		visual_root.position.y = _base_visual_y + bob

func play_slash(strong: bool = false) -> void:
	if not slash_effect:
		return
	if _slash_tween:
		_slash_tween.kill()
	slash_effect.visible = true
	slash_effect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	slash_effect.scale = _slash_effect_base_scale * (1.16 if strong else 1.0)
	_slash_tween = create_tween()
	_slash_tween.tween_property(slash_effect, "modulate:a", 0.0, GameBalance.SLASH_ACTIVE_DURATION)
	_slash_tween.tween_callback(Callable(self, "_hide_slash_effect"))

func flash_hurt() -> void:
	if not visual_root:
		return
	var tween := create_tween()
	visual_root.modulate = Color(1.0, 0.35, 0.35, 1.0)
	tween.tween_property(visual_root, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)

func _hide_slash_effect() -> void:
	if slash_effect:
		slash_effect.visible = false

func _build_visual() -> void:
	_add_foot_shadow()

	visual_root = Node2D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	if not _add_run_animation():
		var texture := _find_character_texture()
		if texture:
			_add_static_character_sprite(texture)
		else:
			_add_placeholder_body()

	_add_slash_effect()

func _add_foot_shadow() -> void:
	foot_shadow = Polygon2D.new()
	foot_shadow.name = "FootShadow"
	foot_shadow.z_index = -10
	foot_shadow.position = Vector2(10.0, 7.0)
	foot_shadow.color = Color(0.0, 0.0, 0.0, 0.34)
	foot_shadow.polygon = _semi_ellipse_points(92.0, 18.0, 30)
	add_child(foot_shadow)

func _add_run_animation() -> bool:
	var frames := SpriteFrames.new()
	frames.add_animation(RUN_ANIMATION_NAME)
	frames.set_animation_loop(RUN_ANIMATION_NAME, true)
	frames.set_animation_speed(RUN_ANIMATION_NAME, RUN_ANIMATION_FPS)

	for frame_path in RUN_FRAME_PATHS:
		var texture := _load_texture(frame_path)
		if not texture:
			return false
		frames.add_frame(RUN_ANIMATION_NAME, texture)

	if frames.get_frame_count(RUN_ANIMATION_NAME) == 0:
		return false

	var sprite := AnimatedSprite2D.new()
	sprite.name = "RunSprite"
	sprite.sprite_frames = frames
	sprite.animation = RUN_ANIMATION_NAME
	var texture := frames.get_frame_texture(RUN_ANIMATION_NAME, 0)
	var texture_size := texture.get_size()
	var target_height := GameBalance.PLAYER_RENDER_HEIGHT
	var target_width := GameBalance.PLAYER_RENDER_WIDTH
	var fit_scale: float = min(target_width / texture_size.x, target_height / texture_size.y)
	sprite.scale = Vector2(fit_scale, fit_scale)
	sprite.position = Vector2(4.0, -target_height * 0.5)
	visual_root.add_child(sprite)
	sprite.play(RUN_ANIMATION_NAME)
	return true

func _add_slash_effect() -> void:
	var texture := _load_texture(SLASH_EFFECT_PATH)
	if not texture:
		return

	slash_effect = Sprite2D.new()
	slash_effect.name = "SlashSwordEffect"
	slash_effect.texture = texture
	slash_effect.position = Vector2(100.0, -54.0)
	slash_effect.z_index = 20
	slash_effect.visible = false
	var texture_size := texture.get_size()
	var target_width := 220.0
	var scale_value: float = target_width / texture_size.x
	_slash_effect_base_scale = Vector2(scale_value, scale_value)
	slash_effect.scale = _slash_effect_base_scale
	add_child(slash_effect)

func _add_static_character_sprite(texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	var texture_size := texture.get_size()
	var target_height := GameBalance.PLAYER_RENDER_HEIGHT
	var target_width := GameBalance.PLAYER_RENDER_WIDTH
	var fit_scale: float = min(target_width / texture_size.x, target_height / texture_size.y)
	sprite.scale = Vector2(fit_scale, fit_scale)
	sprite.position = Vector2(4.0, -target_height * 0.5)
	sprite.material = _make_character_key_material()
	visual_root.add_child(sprite)

func _add_placeholder_body() -> void:
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = Color.html("#202d3a")
	body.polygon = PackedVector2Array([
		Vector2(-34.0, -82.0),
		Vector2(26.0, -98.0),
		Vector2(52.0, -32.0),
		Vector2(18.0, 36.0),
		Vector2(-42.0, 28.0),
		Vector2(-58.0, -36.0)
	])
	visual_root.add_child(body)

	var head := Polygon2D.new()
	head.name = "Head"
	head.color = Color.html("#f0c7a7")
	head.polygon = _circle_points(22.0, 16)
	head.position = Vector2(-18.0, -118.0)
	visual_root.add_child(head)

	var scarf := Polygon2D.new()
	scarf.name = "Scarf"
	scarf.color = Color.html("#df344c")
	scarf.polygon = PackedVector2Array([
		Vector2(-32.0, -80.0),
		Vector2(-92.0, -64.0),
		Vector2(-34.0, -56.0)
	])
	visual_root.add_child(scarf)

	var sword := Line2D.new()
	sword.name = "IdleSword"
	sword.points = PackedVector2Array([Vector2(26.0, -72.0), Vector2(90.0, -116.0)])
	sword.width = 6.0
	sword.default_color = Color.html("#d9edf7")
	visual_root.add_child(sword)

func _find_character_texture() -> Texture2D:
	var dir := DirAccess.open("res://assets/characters")
	if not dir:
		return null
	var files := dir.get_files()
	for file_name in files:
		var lower := file_name.to_lower()
		if lower.ends_with(".png") or lower.ends_with(".jpg") or lower.ends_with(".jpeg") or lower.ends_with(".webp"):
			var image_path := "res://assets/characters/%s" % file_name
			if ResourceLoader.exists(image_path, "Texture2D"):
				var imported_texture := load(image_path)
				if imported_texture is Texture2D:
					return imported_texture

			var image := Image.new()
			var error := image.load(image_path)
			if error == OK and not image.is_empty():
				return ImageTexture.create_from_image(image)
	return null

func _load_texture(resource_path: String) -> Texture2D:
	if ResourceLoader.exists(resource_path, "Texture2D"):
		var imported_texture := load(resource_path)
		if imported_texture is Texture2D:
			return imported_texture

	var image := Image.new()
	var error := image.load(resource_path)
	if error == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

func _circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _semi_ellipse_points(radius_x: float, radius_y: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count + 1):
		var t: float = float(index) / float(point_count)
		var angle: float = PI - PI * t
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points

func _make_character_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = CHARACTER_KEY_SHADER
	return material
