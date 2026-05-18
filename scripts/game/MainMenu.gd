extends Control
class_name MainMenu

const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const LOGO_PATH := "res://assets/ui/logo.png"
const INTRO_BACKGROUND_PATH := "res://assets/background/intro/intro_background.png"
const MENU_BUTTON_BACKGROUND_PATH := "res://assets/ui/button_rectangle_depth_flat.png"
const SETTINGS_ICON_PATH := "res://assets/ui/icon_setting.png"
const PLAYER_PATH := "res://assets/characters/player1.png"
const SETTINGS_POPUP_SCENE := preload("res://scenes/ui/SettingsPopup.tscn")
const GAME_SCENE_PATH := "res://scenes/Main.tscn"
const HOW_TO_SCENE_PATH := "res://scenes/ui/HowToScreen.tscn"
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"

var settings_popup

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_scene()

func _build_scene() -> void:
	var screen_size := get_viewport_rect().size

	_add_background()
	_add_settings_popup()

	var logo := TextureRect.new()
	logo.name = "LogoSmall"
	logo.texture = _load_texture(LOGO_PATH)
	logo.ignore_texture_size = true
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(32.0, 24.0)
	logo.size = Vector2(220.0, 148.0)
	add_child(logo)

	_add_settings_button(Vector2(screen_size.x - 88.0, 32.0))

	var player := TextureRect.new()
	player.name = "PlayerPreview"
	player.texture = _load_texture(PLAYER_PATH)
	player.ignore_texture_size = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player.position = Vector2(155.0, 170.0)
	player.size = Vector2(430.0, 430.0)
	add_child(player)

	var button_x := 790.0
	var button_y := 228.0
	var button_size := Vector2(310.0, 68.0)
	var play_button := _make_menu_button("PLAY", Vector2(button_x, button_y), button_size)
	play_button.pressed.connect(_on_play_pressed)
	var character_button := _make_menu_button("CHARACTER", Vector2(button_x, button_y + 96.0), button_size)
	character_button.pressed.connect(_on_character_pressed)
	var how_to_button := _make_menu_button("HOW TO", Vector2(button_x, button_y + 192.0), button_size)
	how_to_button.pressed.connect(_on_how_to_pressed)

	var bottom_label := Label.new()
	bottom_label.name = "StatsLabel"
	bottom_label.text = "Coins: 0.   Best Score: 0"
	bottom_label.position = Vector2(0.0, screen_size.y - 58.0)
	bottom_label.size = Vector2(screen_size.x, 38.0)
	bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_label.add_theme_font_size_override("font_size", 20)
	bottom_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
	add_child(bottom_label)

func _make_menu_button(text: String, position_value: Vector2, size_value: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position_value
	button.size = size_value
	button.add_theme_font_size_override("font_size", 28)
	_apply_menu_button_background(button)
	AudioHooksScript.bind_ui_button(self, button)
	add_child(button)
	return button

func _add_settings_button(position_value: Vector2) -> void:
	var settings_button := Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = ""
	settings_button.icon = _load_texture(SETTINGS_ICON_PATH)
	settings_button.expand_icon = true
	settings_button.flat = true
	settings_button.position = position_value
	settings_button.size = Vector2(48.0, 48.0)
	var empty_stylebox := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		settings_button.add_theme_stylebox_override(state, empty_stylebox)
	AudioHooksScript.bind_ui_button(self, settings_button)
	settings_button.pressed.connect(_on_settings_pressed)
	add_child(settings_button)

func _add_settings_popup() -> void:
	settings_popup = SETTINGS_POPUP_SCENE.instantiate()
	add_child(settings_popup)

func _apply_menu_button_background(button: Button) -> void:
	var texture := _load_texture(MENU_BUTTON_BACKGROUND_PATH)
	if texture == null:
		return
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, _make_menu_button_stylebox(texture))

func _make_menu_button_stylebox(texture: Texture2D) -> StyleBoxTexture:
	var stylebox := StyleBoxTexture.new()
	stylebox.texture = texture
	return stylebox

func _add_background() -> void:
	var fallback := ColorRect.new()
	fallback.name = "MenuBackground"
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.color = Color.html("#0a0d14")
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

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_how_to_pressed() -> void:
	get_tree().change_scene_to_file(HOW_TO_SCENE_PATH)

func _on_character_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _on_settings_pressed() -> void:
	if settings_popup and settings_popup.has_method("open_popup"):
		settings_popup.open_popup()

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		var imported_texture := load(path)
		if imported_texture is Texture2D:
			return imported_texture

	var image := Image.new()
	if image.load(path) == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null
