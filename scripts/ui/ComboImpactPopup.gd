extends Control
class_name ComboImpactPopup

const ResourceLoadUtil := preload("res://scripts/utils/ResourceLoadUtil.gd")
const COMBO_TEXTURE_PATH := "res://assets/ui/combo.png"
const DIGIT_TEXTURE_PATH_FORMAT := "res://assets/ui/num%d.png"
const END_SIZE := Vector2(500.0, 375.0)
const DIGIT_SIZE := Vector2(250.0, 250.0)
const DIGIT_START_X := 490.0
const DIGIT_ADVANCE := 180.0
const START_SCALE := 0.4
const ANIMATION_SECONDS := 0.35

var combo_group: Control
var combo_image: TextureRect
var digit_textures: Array[Texture2D] = []
var digit_images: Array[TextureRect] = []
var _tween: Tween

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000
	_load_digit_textures()
	_build_group()
	visible = false

func play(combo: int = 0) -> void:
	if combo_image == null:
		return
	if _tween:
		_tween.kill()

	_layout_combo_digits(combo)
	visible = true
	combo_group.visible = true
	combo_image.visible = true
	combo_group.modulate = Color(1.0, 1.0, 1.0, 1.0)
	combo_group.scale = Vector2(START_SCALE, START_SCALE)
	_center_group()

	_tween = create_tween()
	_tween.tween_property(combo_group, "scale", Vector2.ONE, ANIMATION_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_hide_popup)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center_group()

func _load_digit_textures() -> void:
	digit_textures.clear()
	for digit in range(10):
		digit_textures.append(_load_texture(DIGIT_TEXTURE_PATH_FORMAT % digit))

func _build_group() -> void:
	combo_group = Control.new()
	combo_group.name = "ComboGroup"
	combo_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_group)

	combo_image = TextureRect.new()
	combo_image.name = "ComboImage"
	combo_image.texture = _load_texture(COMBO_TEXTURE_PATH)
	combo_image.ignore_texture_size = true
	combo_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	combo_image.size = END_SIZE
	combo_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_group.add_child(combo_image)
	_layout_combo_digits(0)

func _layout_combo_digits(combo: int) -> void:
	var combo_text := str(maxi(combo, 0))
	_ensure_digit_nodes(combo_text.length())
	for index in range(digit_images.size()):
		digit_images[index].visible = index < combo_text.length()

	for index in range(combo_text.length()):
		var digit := int(combo_text.substr(index, 1))
		var digit_image := digit_images[index]
		digit_image.texture = digit_textures[digit]
		digit_image.position = Vector2(DIGIT_START_X + DIGIT_ADVANCE * index, (END_SIZE.y - DIGIT_SIZE.y) * 0.5)
		digit_image.size = DIGIT_SIZE

	var total_width := DIGIT_START_X + DIGIT_SIZE.x
	if combo_text.length() > 1:
		total_width += DIGIT_ADVANCE * float(combo_text.length() - 1)
	combo_group.size = Vector2(total_width, END_SIZE.y)
	combo_group.pivot_offset = combo_group.size * 0.5
	_center_group()

func _ensure_digit_nodes(count: int) -> void:
	while digit_images.size() < count:
		var digit_image := TextureRect.new()
		digit_image.name = "Digit%d" % digit_images.size()
		digit_image.ignore_texture_size = true
		digit_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		digit_image.size = DIGIT_SIZE
		digit_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combo_group.add_child(digit_image)
		digit_images.append(digit_image)

func _center_group() -> void:
	if combo_group == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	combo_group.position = (viewport_size - combo_group.size) * 0.5

func _hide_popup() -> void:
	visible = false
	if combo_group:
		combo_group.visible = false
		combo_group.scale = Vector2.ONE
	_tween = null

func _load_texture(path: String) -> Texture2D:
	return ResourceLoadUtil.load_texture(path)
