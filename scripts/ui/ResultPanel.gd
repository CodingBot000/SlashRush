extends CanvasLayer
class_name ResultPanel

signal retry_requested
signal quit_requested

const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const GameBalance := preload("res://scripts/data/GameBalance.gd")
const ResourceLoadUtil := preload("res://scripts/utils/ResourceLoadUtil.gd")
const DEAD_TEXTURE_PATH := "res://assets/sprites/samurai/dead/dead.png"
const GAME_OVER_DIM_SECONDS := 1.0
const GAME_OVER_DIM_ALPHA := 0.84
const TITLE_DIM_ALPHA := 0.86
const NO_DEAD_VISUAL_POSITION := Vector2(-100000.0, -100000.0)

var root: Control
var dim: ColorRect
var dead_overlay_sprite: Sprite2D
var content: VBoxContainer
var button_row: HBoxContainer
var title_label: Label
var subtitle_label: Label
var score_label: Label
var best_label: Label
var retry_button: Button
var quit_button: Button
var _dim_tween: Tween

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_panel()
	get_viewport().size_changed.connect(_sync_layout)

func show_title(best_score: int) -> void:
	visible = true
	_sync_layout()
	_kill_dim_tween()
	_set_dim_alpha(TITLE_DIM_ALPHA)
	_set_dead_overlay_visible(false)
	title_label.text = "SLASH RUSH"
	subtitle_label.text = "TAP TO START"
	score_label.text = "Best Score  %d" % best_score
	best_label.text = "Cut enemies. Let good items pass."
	subtitle_label.visible = true
	score_label.visible = true
	best_label.visible = true
	retry_button.text = "START"
	quit_button.visible = false

func show_result(
	won: bool,
	score: int,
	coins: int,
	best_score: int,
	dead_position: Vector2 = NO_DEAD_VISUAL_POSITION,
	dead_scale: Vector2 = Vector2.ZERO,
	dead_texture: Texture2D = null
) -> void:
	visible = true
	_sync_layout()
	title_label.text = "VICTORY" if won else "GAME OVER"
	score_label.text = "Score %d   Coins %d" % [score, coins]
	best_label.text = "Best Score %d" % best_score
	subtitle_label.visible = false
	score_label.visible = true
	best_label.visible = true
	retry_button.text = "RETRY"
	quit_button.visible = true
	_configure_dead_overlay(not won, dead_position, dead_scale, dead_texture)
	_start_dim_fade()

func hide_panel() -> void:
	_kill_dim_tween()
	_set_dim_alpha(0.0)
	_set_dead_overlay_visible(false)
	visible = false

func _build_ui() -> void:
	root = Control.new()
	root.name = "ResultRoot"
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.03, 0.04, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.z_index = 0
	root.add_child(dim)

	dead_overlay_sprite = Sprite2D.new()
	dead_overlay_sprite.name = "DeadOverlay"
	dead_overlay_sprite.centered = true
	dead_overlay_sprite.visible = false
	dead_overlay_sprite.z_index = 1
	root.add_child(dead_overlay_sprite)

	content = VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	content.z_index = 2
	root.add_child(content)

	title_label = _make_label(68, Color(1.0, 1.0, 1.0, 1.0), Vector2(620.0, 92.0))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.78))
	subtitle_label = _make_label(28, Color.html("#ffef8a"), Vector2(620.0, 42.0))
	score_label = _make_label(24, Color(1.0, 1.0, 1.0, 0.84), Vector2(620.0, 38.0))
	best_label = _make_label(20, Color(1.0, 1.0, 1.0, 0.68), Vector2(620.0, 34.0))

	button_row = HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 18)
	button_row.custom_minimum_size = Vector2(620.0, 64.0)
	content.add_child(button_row)

	retry_button = Button.new()
	retry_button.custom_minimum_size = Vector2(180.0, 60.0)
	retry_button.text = "START"
	retry_button.focus_mode = Control.FOCUS_NONE
	retry_button.add_theme_font_size_override("font_size", 26)
	AudioHooksScript.bind_ui_button(self, retry_button)
	retry_button.pressed.connect(_on_retry_pressed)
	button_row.add_child(retry_button)

	quit_button = Button.new()
	quit_button.custom_minimum_size = Vector2(180.0, 60.0)
	quit_button.text = "QUIT"
	quit_button.focus_mode = Control.FOCUS_NONE
	quit_button.add_theme_font_size_override("font_size", 26)
	AudioHooksScript.bind_ui_button(self, quit_button)
	quit_button.pressed.connect(_on_quit_pressed)
	button_row.add_child(quit_button)
	_sync_layout()

func _sync_layout() -> void:
	if root == null or content == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	root.size = viewport_size
	if dim:
		dim.size = viewport_size

	var content_width := clampf(viewport_size.x - 80.0, 380.0, 620.0)
	var content_height := 320.0
	content.size = Vector2(content_width, content_height)
	content.position = Vector2(
		(viewport_size.x - content_width) * 0.5,
		maxf(42.0, viewport_size.y * 0.5 - content_height * 0.5)
	)
	for label in [title_label, subtitle_label, score_label, best_label]:
		if label:
			label.custom_minimum_size.x = content_width
	if button_row:
		button_row.custom_minimum_size.x = content_width

func _start_dim_fade() -> void:
	_kill_dim_tween()
	_set_dim_alpha(0.0)
	_dim_tween = create_tween()
	_dim_tween.tween_method(Callable(self, "_set_dim_alpha"), 0.0, GAME_OVER_DIM_ALPHA, GAME_OVER_DIM_SECONDS)

func _kill_dim_tween() -> void:
	if _dim_tween:
		_dim_tween.kill()
		_dim_tween = null

func _set_dim_alpha(alpha: float) -> void:
	if not dim:
		return
	var color := dim.color
	color.a = clampf(alpha, 0.0, 1.0)
	dim.color = color

func _configure_dead_overlay(show_dead: bool, dead_position: Vector2, dead_scale: Vector2, dead_texture: Texture2D) -> void:
	if not show_dead or dead_position == NO_DEAD_VISUAL_POSITION:
		_set_dead_overlay_visible(false)
		return

	var texture := dead_texture if dead_texture != null else _load_texture(DEAD_TEXTURE_PATH)
	if texture == null:
		_set_dead_overlay_visible(false)
		return

	dead_overlay_sprite.texture = texture
	dead_overlay_sprite.position = dead_position
	if dead_scale == Vector2.ZERO:
		_fit_dead_overlay_sprite(texture)
	else:
		dead_overlay_sprite.scale = dead_scale
	dead_overlay_sprite.modulate = Color.WHITE
	_set_dead_overlay_visible(true)

func _set_dead_overlay_visible(visible_value: bool) -> void:
	if dead_overlay_sprite:
		dead_overlay_sprite.visible = visible_value

func _fit_dead_overlay_sprite(texture: Texture2D) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		dead_overlay_sprite.scale = Vector2.ONE
		return
	var target_width := GameBalance.PLAYER_RENDER_WIDTH * 1.22
	var target_height := GameBalance.PLAYER_RENDER_HEIGHT * 0.82
	var fit_scale: float = min(target_width / texture_size.x, target_height / texture_size.y)
	dead_overlay_sprite.scale = Vector2(fit_scale, fit_scale)

func _load_texture(path: String) -> Texture2D:
	return ResourceLoadUtil.load_texture(path)

func _make_label(font_size: int, color: Color, size_value: Vector2) -> Label:
	var label := Label.new()
	label.custom_minimum_size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	content.add_child(label)
	return label

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
