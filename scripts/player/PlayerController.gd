extends Node2D
class_name PlayerController

const GameBalance := preload("res://scripts/data/GameBalance.gd")
const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const HapticHooksScript := preload("res://scripts/haptics/HapticHooks.gd")
const RUN_FRAME_PATHS := [
	"res://assets/sprites/samurai/run/frame_01.png",
	"res://assets/sprites/samurai/run/frame_02.png",
	"res://assets/sprites/samurai/run/frame_03.png",
	"res://assets/sprites/samurai/run/frame_04.png",
]
const RUN_ANIMATION_NAME := "run"
const RUN_ANIMATION_FPS := 12.0
const IDLE_TEXTURE_PATH := "res://assets/sprites/samurai/idle/player_stand.png"
const DAMAGE_TEXTURE_PATH := "res://assets/sprites/samurai/damage/player_damage.png"
const DEAD_TEXTURE_PATH := "res://assets/sprites/samurai/dead/dead.png"
const SWORD_SHEATH_TEXTURE_PATH := "res://assets/sprites/samurai/run/sword_sheath.png"
const SWORD_SLASH_TEXTURE_PATH := "res://assets/sprites/samurai/run/sword_slash.png"
const DAMAGE_DURATION := GameBalance.PLAYER_HURT_SLOW_DURATION
const DAMAGE_FLASH_PHASES := 8
const SPRITE_BASE_OFFSET := Vector2(4.0, 0.0)
const DEAD_SPRITE_OFFSET := Vector2(34.0, 0.0)
const SLASH_OFFSET := Vector2(190.0, -40.0)
const SLASH_ROTATION_DEGREES := 20.0
const SLASH_SCALE_MULTIPLIER := 1.18
const LONG_SLASH_SCALE_MULTIPLIER := 1.08

enum MotionState { IDLE, RUN, DAMAGE, DEAD }

var visual_root: Node2D
var foot_shadow: Polygon2D
var run_sprite: AnimatedSprite2D
var idle_sprite: Sprite2D
var damage_sprite: Sprite2D
var dead_sprite: Sprite2D
var sword_sheath_sprite: Sprite2D
var sword_slash_sprite: Sprite2D
var _slash_tween: Tween
var _damage_tween: Tween
var _slash_base_scale := Vector2.ONE
var _run_base_scale := Vector2.ONE
var _sprite_base_position := Vector2.ZERO
var _base_visual_y := 0.0
var _motion_state := MotionState.RUN
var _pre_damage_state := MotionState.RUN
var _slash_active := false

func _ready() -> void:
	_build_visual()
	play_run()

func _process(_delta: float) -> void:
	if visual_root:
		if _motion_state == MotionState.DEAD:
			visual_root.position.y = _base_visual_y
			return
		var bob := sin(float(Time.get_ticks_msec()) / 90.0) * 2.5
		visual_root.position.y = _base_visual_y + bob

func play_run() -> void:
	if _motion_state == MotionState.DAMAGE:
		_pre_damage_state = MotionState.RUN
		return
	_motion_state = MotionState.RUN
	_apply_motion_state()

func play_idle() -> void:
	if _motion_state == MotionState.DAMAGE:
		_pre_damage_state = MotionState.IDLE
		return
	_motion_state = MotionState.IDLE
	_apply_motion_state()

func play_dead() -> void:
	if _slash_tween:
		_slash_tween.kill()
	if _damage_tween:
		_damage_tween.kill()
	_slash_active = false
	_motion_state = MotionState.DEAD
	visual_root.modulate = Color.WHITE
	_apply_motion_state()

func play_slash(strong: bool = false) -> void:
	if not sword_slash_sprite or _motion_state == MotionState.DAMAGE or _motion_state == MotionState.DEAD:
		return
	if _slash_tween:
		_slash_tween.kill()

	_slash_active = true
	AudioHooksScript.play_sword_slash(self)
	HapticHooksScript.vibrate_attack(self)
	_update_weapon_layers()
	sword_slash_sprite.scale = _slash_base_scale * (LONG_SLASH_SCALE_MULTIPLIER if strong else 1.0)
	sword_slash_sprite.visible = true

	_slash_tween = create_tween()
	_slash_tween.tween_interval(GameBalance.SLASH_ACTIVE_DURATION)
	_slash_tween.tween_callback(Callable(self, "_finish_slash"))

func flash_hurt() -> void:
	if not visual_root:
		return
	if _slash_tween:
		_slash_tween.kill()
	if _damage_tween:
		_damage_tween.kill()

	_slash_active = false
	_pre_damage_state = _motion_state if _motion_state != MotionState.DAMAGE else _pre_damage_state
	_motion_state = MotionState.DAMAGE
	_apply_motion_state()

	visual_root.modulate = Color(1.0, 0.25, 0.25, 1.0)
	_damage_tween = create_tween()
	var phase_duration := DAMAGE_DURATION / float(DAMAGE_FLASH_PHASES)
	for phase in range(DAMAGE_FLASH_PHASES):
		var target_color := Color(1.0, 1.0, 1.0, 0.45) if phase % 2 == 0 else Color(1.0, 0.25, 0.25, 1.0)
		_damage_tween.tween_property(visual_root, "modulate", target_color, phase_duration)
	_damage_tween.tween_callback(Callable(self, "_finish_damage"))

func _finish_slash() -> void:
	_slash_active = false
	_update_weapon_layers()

func _finish_damage() -> void:
	visual_root.modulate = Color.WHITE
	_motion_state = _pre_damage_state
	_apply_motion_state()

func _build_visual() -> void:
	_add_foot_shadow()

	visual_root = Node2D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	if _add_run_animation():
		_add_static_sprite("IdleSprite", IDLE_TEXTURE_PATH, 0)
		_add_static_sprite("DamageSprite", DAMAGE_TEXTURE_PATH, 0)
		_add_static_sprite("DeadSprite", DEAD_TEXTURE_PATH, 0)
		_add_sword_layers()
	else:
		var texture := _find_character_texture()
		if texture:
			_add_static_character_sprite(texture)
		else:
			_add_placeholder_body()

func _add_foot_shadow() -> void:
	foot_shadow = Polygon2D.new()
	foot_shadow.name = "FootShadow"
	foot_shadow.z_index = -10
	foot_shadow.position = Vector2(10.0, 7.0)
	foot_shadow.color = Color(0.0, 0.0, 0.0, 0.34)
	foot_shadow.polygon = _ellipse_points(92.0, 18.0, 40)
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

	run_sprite = AnimatedSprite2D.new()
	run_sprite.name = "RunSprite"
	run_sprite.sprite_frames = frames
	run_sprite.animation = RUN_ANIMATION_NAME
	run_sprite.z_index = 0
	var texture := frames.get_frame_texture(RUN_ANIMATION_NAME, 0)
	var texture_size := texture.get_size()
	var target_height := GameBalance.PLAYER_RENDER_HEIGHT
	var target_width := GameBalance.PLAYER_RENDER_WIDTH
	var fit_scale: float = min(target_width / texture_size.x, target_height / texture_size.y)
	_run_base_scale = Vector2(fit_scale, fit_scale)
	_sprite_base_position = SPRITE_BASE_OFFSET + Vector2(0.0, -target_height * 0.5)
	run_sprite.scale = _run_base_scale
	run_sprite.position = _sprite_base_position
	visual_root.add_child(run_sprite)
	run_sprite.play(RUN_ANIMATION_NAME)
	return true

func _add_static_sprite(sprite_name: String, texture_path: String, z_index: int) -> Sprite2D:
	var texture := _load_texture(texture_path)
	if not texture:
		return null

	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.z_index = z_index
	if sprite_name == "DeadSprite":
		_fit_dead_sprite(sprite, texture)
	else:
		_fit_sprite_to_player(sprite, texture)
	sprite.visible = false
	visual_root.add_child(sprite)
	if sprite_name == "IdleSprite":
		idle_sprite = sprite
	elif sprite_name == "DamageSprite":
		damage_sprite = sprite
	elif sprite_name == "DeadSprite":
		dead_sprite = sprite
	return sprite

func _add_sword_layers() -> void:
	var sheath_texture := _load_texture(SWORD_SHEATH_TEXTURE_PATH)
	if sheath_texture:
		sword_sheath_sprite = Sprite2D.new()
		sword_sheath_sprite.name = "SwordSheath"
		sword_sheath_sprite.texture = sheath_texture
		sword_sheath_sprite.position = _sprite_base_position
		sword_sheath_sprite.scale = _run_base_scale
		sword_sheath_sprite.z_index = 10
		visual_root.add_child(sword_sheath_sprite)

	var slash_texture := _load_texture(SWORD_SLASH_TEXTURE_PATH)
	if slash_texture:
		sword_slash_sprite = Sprite2D.new()
		sword_slash_sprite.name = "SwordSlash"
		sword_slash_sprite.texture = slash_texture
		sword_slash_sprite.position = _sprite_base_position + SLASH_OFFSET
		sword_slash_sprite.rotation_degrees = SLASH_ROTATION_DEGREES
		sword_slash_sprite.scale = _run_base_scale * SLASH_SCALE_MULTIPLIER
		sword_slash_sprite.z_index = -1
		sword_slash_sprite.visible = false
		_slash_base_scale = _run_base_scale * SLASH_SCALE_MULTIPLIER
		visual_root.add_child(sword_slash_sprite)

func _apply_motion_state() -> void:
	if run_sprite:
		run_sprite.visible = _motion_state == MotionState.RUN
		if run_sprite.visible and not run_sprite.is_playing():
			run_sprite.play(RUN_ANIMATION_NAME)
	if idle_sprite:
		idle_sprite.visible = _motion_state == MotionState.IDLE
	if damage_sprite:
		damage_sprite.visible = _motion_state == MotionState.DAMAGE
	if dead_sprite:
		dead_sprite.visible = _motion_state == MotionState.DEAD
	if _motion_state != MotionState.DAMAGE:
		visual_root.modulate = Color.WHITE
	_update_weapon_layers()

func _update_weapon_layers() -> void:
	var can_show_weapon := _motion_state != MotionState.DAMAGE and _motion_state != MotionState.DEAD
	if sword_sheath_sprite:
		sword_sheath_sprite.visible = can_show_weapon and _motion_state == MotionState.RUN and not _slash_active
	if sword_slash_sprite:
		sword_slash_sprite.visible = can_show_weapon and _slash_active

func _fit_sprite_to_player(sprite: Sprite2D, texture: Texture2D) -> void:
	var texture_size := texture.get_size()
	var target_height := GameBalance.PLAYER_RENDER_HEIGHT
	var target_width := GameBalance.PLAYER_RENDER_WIDTH
	var fit_scale: float = min(target_width / texture_size.x, target_height / texture_size.y)
	sprite.scale = Vector2(fit_scale, fit_scale)
	sprite.position = SPRITE_BASE_OFFSET + Vector2(0.0, -target_height * 0.5)

func _fit_dead_sprite(sprite: Sprite2D, texture: Texture2D) -> void:
	var texture_size := texture.get_size()
	var target_width := GameBalance.PLAYER_RENDER_WIDTH * 1.22
	var target_height := GameBalance.PLAYER_RENDER_HEIGHT * 0.82
	var fit_scale: float = min(target_width / texture_size.x, target_height / texture_size.y)
	sprite.scale = Vector2(fit_scale, fit_scale)
	sprite.position = SPRITE_BASE_OFFSET + DEAD_SPRITE_OFFSET + Vector2(0.0, -texture_size.y * fit_scale * 0.5)

func _add_static_character_sprite(texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	_fit_sprite_to_player(sprite, texture)
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

func _ellipse_points(radius_x: float, radius_y: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
