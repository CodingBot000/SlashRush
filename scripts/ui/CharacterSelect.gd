extends Control
class_name CharacterSelect

const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/game/MainMenu.tscn"
const DEFAULT_MESSAGE := "More characters will be available in future versions."

const CARD_WIDTH := 206.0
const CARD_HEIGHT := 370.0
const PORTRAIT_HEIGHT := 252.0
const PORTRAIT_IMAGE_BOX_COLOR := Color.WHITE
const DRAG_CLICK_CANCEL_DISTANCE := 12.0

var characters := [
	{
		"id": "player1",
		"name": "Player 1",
		"image": "res://assets/characters/player1.png",
		"unlocked": true,
		"selected": true
	},
	{
		"id": "player2",
		"name": "Player 2",
		"image": "res://assets/characters/player2.png",
		"unlocked": false,
		"selected": false
	},
	{
		"id": "player3",
		"name": "Player 3",
		"image": "res://assets/characters/player3.png",
		"unlocked": false,
		"selected": false
	},
	{
		"id": "player4",
		"name": "Player 4",
		"image": "res://assets/characters/player4.png",
		"unlocked": false,
		"selected": false
	},
	{
		"id": "player5",
		"name": "Player 5",
		"image": "res://assets/characters/player5.png",
		"unlocked": false,
		"selected": false
	}
]

var message_label: Label
var reset_message_timer: Timer
var character_scroll: ScrollContainer
var scroll_drag_active := false
var scroll_drag_total := 0.0
var active_touch_index := -1
var suppress_next_card_press := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	AudioHooksScript.play_lobby_music(self)
	_build_scene()

func _input(event: InputEvent) -> void:
	if character_scroll == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_position_in_scroll(event.position):
			_begin_scroll_drag()
		elif not event.pressed and scroll_drag_active:
			_end_scroll_drag()
	elif event is InputEventMouseMotion and scroll_drag_active:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_drag_scroll(event.relative.x)
	elif event is InputEventScreenTouch:
		if event.pressed and active_touch_index == -1 and _is_position_in_scroll(event.position):
			active_touch_index = event.index
			_begin_scroll_drag()
		elif not event.pressed and scroll_drag_active and event.index == active_touch_index:
			_end_scroll_drag()
			active_touch_index = -1
	elif event is InputEventScreenDrag and scroll_drag_active and event.index == active_touch_index:
		_drag_scroll(event.relative.x)

func _build_scene() -> void:
	var background := ColorRect.new()
	background.name = "CharacterSelectBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.color = Color.html("#090c13")
	add_child(background)

	var safe_area := MarginContainer.new()
	safe_area.name = "SafeArea"
	safe_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_area.add_theme_constant_override("margin_left", 42)
	safe_area.add_theme_constant_override("margin_top", 28)
	safe_area.add_theme_constant_override("margin_right", 42)
	safe_area.add_theme_constant_override("margin_bottom", 28)
	add_child(safe_area)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 18)
	safe_area.add_child(layout)

	layout.add_child(_make_header())
	layout.add_child(_make_character_scroller())
	layout.add_child(_make_message_label())

	reset_message_timer = Timer.new()
	reset_message_timer.name = "ResetMessageTimer"
	reset_message_timer.wait_time = 1.6
	reset_message_timer.one_shot = true
	reset_message_timer.timeout.connect(_restore_default_message)
	add_child(reset_message_timer)

func _make_header() -> Control:
	var header := HBoxContainer.new()
	header.name = "Header"
	header.custom_minimum_size = Vector2(0.0, 70.0)
	header.alignment = BoxContainer.ALIGNMENT_CENTER

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "< BACK"
	back_button.custom_minimum_size = Vector2(154.0, 54.0)
	back_button.add_theme_font_size_override("font_size", 20)
	AudioHooksScript.bind_ui_button(self, back_button)
	back_button.pressed.connect(_on_back_button_pressed)
	header.add_child(back_button)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "CHARACTER SELECT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color.html("#fff2c2"))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(title)

	var balance_spacer := Control.new()
	balance_spacer.name = "HeaderRightSpacer"
	balance_spacer.custom_minimum_size = Vector2(154.0, 54.0)
	header.add_child(balance_spacer)

	return header

func _make_character_scroller() -> ScrollContainer:
	character_scroll = ScrollContainer.new()
	character_scroll.name = "CharacterScrollContainer"
	character_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	character_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var row := HBoxContainer.new()
	row.name = "CharacterHBox"
	row.add_theme_constant_override("separation", 22)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	character_scroll.add_child(row)

	for character in characters:
		row.add_child(_make_character_card(character))

	row.add_child(_make_coming_soon_card())
	return character_scroll

func _make_message_label() -> Label:
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.text = DEFAULT_MESSAGE
	message_label.custom_minimum_size = Vector2(0.0, 62.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
	return message_label

func _make_character_card(data: Dictionary) -> Button:
	var selected := bool(data.get("selected", false))
	var unlocked := bool(data.get("unlocked", false))
	var card := _make_card_button("CharacterCard_%s" % String(data.get("id", "")), selected, false)
	card.pressed.connect(_on_character_card_pressed.bind(data))

	var margin := _make_card_margin()
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 9)
	margin.add_child(content)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = String(data.get("name", ""))
	name_label.custom_minimum_size = Vector2(0.0, 36.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.html("#f7f0dc") if selected else Color(1.0, 1.0, 1.0, 0.78))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	content.add_child(_make_portrait_area(data, unlocked, selected))
	content.add_child(_make_status_pill("SELECTED" if selected else "LOCKED", selected))

	return card

func _make_coming_soon_card() -> Button:
	var card := _make_card_button("CharacterCard_ComingSoon", false, true)
	card.pressed.connect(_on_coming_soon_card_pressed)

	var margin := _make_card_margin()
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var spacer_top := Control.new()
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer_top.custom_minimum_size = Vector2(0.0, 20.0)
	content.add_child(spacer_top)

	var mark := Label.new()
	mark.name = "QuestionMark"
	mark.text = "?"
	mark.custom_minimum_size = Vector2(0.0, 180.0)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 96)
	mark.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.42))
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(mark)

	var plus := Label.new()
	plus.name = "PlusLabel"
	plus.text = "+"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus.add_theme_font_size_override("font_size", 32)
	plus.add_theme_color_override("font_color", Color.html("#ffca5f"))
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(plus)

	content.add_child(_make_status_pill("COMING SOON", false))
	return card

func _make_card_button(card_name: String, selected: bool, soon: bool) -> Button:
	var card := Button.new()
	card.name = card_name
	card.text = ""
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.clip_contents = true
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("normal", _make_card_style(selected, soon, 0.0))
	card.add_theme_stylebox_override("hover", _make_card_style(selected, soon, 0.08))
	card.add_theme_stylebox_override("pressed", _make_card_style(selected, soon, 0.14))
	card.add_theme_stylebox_override("focus", _make_card_style(selected, soon, 0.0))
	return card

func _make_card_style(selected: bool, soon: bool, hover_lift: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.html("#151923")
	if soon:
		style.bg_color = Color(0.12 + hover_lift, 0.13 + hover_lift, 0.17 + hover_lift, 0.72)
	elif selected:
		style.bg_color = Color(0.12 + hover_lift, 0.11 + hover_lift, 0.08 + hover_lift, 1.0)
	else:
		style.bg_color = Color(0.08 + hover_lift, 0.09 + hover_lift, 0.12 + hover_lift, 1.0)
	style.border_color = Color.html("#ffca5f") if selected else Color(1.0, 1.0, 1.0, 0.16)
	style.set_border_width_all(4 if selected else 1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 8
	return style

func _make_card_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = "CardMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	return margin

func _make_portrait_area(data: Dictionary, unlocked: bool, selected: bool) -> Control:
	var portrait := Control.new()
	portrait.name = "PortraitArea"
	portrait.custom_minimum_size = Vector2(CARD_WIDTH - 28.0, PORTRAIT_HEIGHT)
	portrait.clip_contents = true
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portrait_background := ColorRect.new()
	portrait_background.name = "PortraitBackground"
	portrait_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_background.color = PORTRAIT_IMAGE_BOX_COLOR
	portrait_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(portrait_background)

	var texture := TextureRect.new()
	texture.name = "CharacterImage"
	texture.texture = _load_texture(String(data.get("image", "")))
	texture.ignore_texture_size = true
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(texture)

	if not unlocked:
		var overlay := ColorRect.new()
		overlay.name = "LockedOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(0.0, 0.0, 0.0, 0.58)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(overlay)

		var lock_label := Label.new()
		lock_label.name = "LockedLabel"
		lock_label.text = "LOCKED"
		lock_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 28)
		lock_label.add_theme_color_override("font_color", Color.html("#f4f4f4"))
		lock_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
		lock_label.add_theme_constant_override("shadow_offset_x", 1)
		lock_label.add_theme_constant_override("shadow_offset_y", 2)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(lock_label)

	if selected:
		var selected_badge := PanelContainer.new()
		selected_badge.name = "SelectedBadge"
		selected_badge.position = Vector2(130.0, 10.0)
		selected_badge.size = Vector2(38.0, 30.0)
		selected_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color.html("#ffca5f")
		badge_style.set_corner_radius_all(8)
		selected_badge.add_theme_stylebox_override("panel", badge_style)

		var badge_label := Label.new()
		badge_label.text = "OK"
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.add_theme_font_size_override("font_size", 16)
		badge_label.add_theme_color_override("font_color", Color.html("#111111"))
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_badge.add_child(badge_label)

		portrait.add_child(selected_badge)

	return portrait

func _make_status_pill(text: String, selected: bool) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = "StatusLabel"
	pill.custom_minimum_size = Vector2(0.0, 38.0)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color.html("#ffca5f") if selected else Color(0.0, 0.0, 0.0, 0.34)
	style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	pill.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.html("#15100a") if selected else Color(1.0, 1.0, 1.0, 0.78))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(label)

	return pill

func _on_character_card_pressed(data: Dictionary) -> void:
	if suppress_next_card_press:
		suppress_next_card_press = false
		return
	AudioHooksScript.play_ui_button_click(self)
	if bool(data.get("selected", false)):
		_show_message("Already selected")
	else:
		_show_message("Coming soon")

func _on_coming_soon_card_pressed() -> void:
	if suppress_next_card_press:
		suppress_next_card_press = false
		return
	AudioHooksScript.play_ui_button_click(self)
	_show_message("Coming soon")

func _begin_scroll_drag() -> void:
	scroll_drag_active = true
	scroll_drag_total = 0.0

func _drag_scroll(relative_x: float) -> void:
	if is_zero_approx(relative_x):
		return
	character_scroll.scroll_horizontal = max(0, character_scroll.scroll_horizontal - int(round(relative_x)))
	scroll_drag_total += abs(relative_x)
	if scroll_drag_total >= DRAG_CLICK_CANCEL_DISTANCE:
		suppress_next_card_press = true
		get_viewport().set_input_as_handled()

func _end_scroll_drag() -> void:
	if scroll_drag_total >= DRAG_CLICK_CANCEL_DISTANCE:
		suppress_next_card_press = true
		call_deferred("_clear_drag_press_suppression")
	scroll_drag_active = false
	scroll_drag_total = 0.0

func _clear_drag_press_suppression() -> void:
	suppress_next_card_press = false

func _is_position_in_scroll(position_value: Vector2) -> bool:
	return character_scroll.get_global_rect().has_point(position_value)

func _show_message(text: String) -> void:
	message_label.text = text
	reset_message_timer.start()

func _restore_default_message() -> void:
	message_label.text = DEFAULT_MESSAGE

func _on_back_button_pressed() -> void:
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
