extends Control
class_name IntroScene

const LOGO_PATH := "res://assets/ui/logo.png"
const INTRO_BACKGROUND_PATH := "res://assets/background/intro/intro_background.png"
const MAIN_MENU_SCENE_PATH := "res://scenes/game/MainMenu.tscn"
const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")

var logo: TextureRect
var start_label: Label
var elapsed := 0.0
var opening_main_menu := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_scene()

func _process(delta: float) -> void:
	elapsed += delta
	if logo:
		var logo_scale := 1.0 + sin(elapsed * TAU / 3.0) * 0.035
		logo.scale = Vector2(logo_scale, logo_scale)
	if start_label:
		start_label.modulate.a = 0.32 + ((sin(elapsed * 3.2) + 1.0) * 0.34)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_open_main_menu()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_main_menu()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_open_main_menu()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_open_main_menu()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_main_menu()

func _build_scene() -> void:
	var screen_size := get_viewport_rect().size

	_add_background()

	logo = TextureRect.new()
	logo.name = "Logo"
	logo.texture = _load_texture(LOGO_PATH)
	logo.ignore_texture_size = true
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = Vector2(560.0, 374.0)
	logo.position = Vector2((screen_size.x - logo.size.x) * 0.5, 166.0)
	logo.pivot_offset = logo.size * 0.5
	add_child(logo)

	start_label = Label.new()
	start_label.name = "TapToStartLabel"
	start_label.text = "TAP TO START"
	start_label.position = Vector2(0.0, 540.0)
	start_label.size = Vector2(screen_size.x, 44.0)
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_label.add_theme_font_size_override("font_size", 22)
	start_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
	add_child(start_label)

func _add_background() -> void:
	var fallback := ColorRect.new()
	fallback.name = "DarkBackground"
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.color = Color.html("#070a11")
	add_child(fallback)

	var texture := _load_texture(INTRO_BACKGROUND_PATH)
	if texture == null:
		return

	var background := TextureRect.new()
	background.name = "IntroBackground"
	background.texture = texture
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.ignore_texture_size = true
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

func _open_main_menu() -> void:
	if opening_main_menu:
		return
	opening_main_menu = true
	AudioHooksScript.play_start_game(self)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		var imported_texture := load(path)
		if imported_texture is Texture2D:
			return imported_texture

	var image := Image.new()
	if image.load(path) == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null
