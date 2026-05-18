extends Control
class_name HowToScreen

const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const ObjectTypes := preload("res://scripts/data/ObjectTypes.gd")

const MAIN_MENU_SCENE_PATH := "res://scenes/game/MainMenu.tscn"
const KNOWN_OBJECT_TYPES := ["enemy_basic", "bomb", "enemy_fast", "enemy_armor", "coin", "fever_orb", "heal"]

const CARD_WIDTH := 282.0
const CARD_HEIGHT := 390.0

const CARD_DATA := [
	{
		"title": "TAP",
		"targets": ["enemy_basic", "bomb"],
		"description": "기본 몬스터는 한 번 탭해서 제거하세요.\n위험 오브젝트도 타이밍에 맞춰 빠르게 반응해야 합니다.",
		"accent": "#ffca5f"
	},
	{
		"title": "TAP TAP",
		"targets": ["enemy_fast"],
		"description": "빠른 몬스터는 두 번 공격해야 제거됩니다.\n연속 입력 타이밍을 놓치지 마세요.",
		"accent": "#ff7d6e"
	},
	{
		"title": "HOLD",
		"targets": ["enemy_armor"],
		"description": "갑옷 몬스터는 길게 눌러 처리하세요.\n게이지가 차는 느낌으로 Hold 타이밍을 익히면 됩니다.",
		"accent": "#84b7ff"
	},
	{
		"title": "ITEMS",
		"targets": ["coin", "fever_orb", "heal"],
		"description": "Coin은 점수를 올립니다.\nFever Orb는 피버 게이지를 채웁니다.\nHeal은 체력을 회복합니다.",
		"accent": "#69df9a"
	},
	{
		"title": "COMBO & FEVER",
		"targets": ["combo", "fever"],
		"description": "연속으로 성공하면 콤보가 증가합니다.\n실패하거나 피격되면 콤보가 초기화됩니다.\nFever 중에는 빠른 연속 공격이 발동하고 콤보가 더 안정적으로 유지됩니다.",
		"accent": "#c997ff"
	}
]

var card_row: HBoxContainer
var card_scroll: ScrollContainer
var scroll_drag_active := false
var active_touch_index := -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	AudioHooksScript.play_lobby_music(self)
	_build_scene()

func _input(event: InputEvent) -> void:
	if card_scroll == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_position_in_scroll(event.position):
			scroll_drag_active = true
		elif not event.pressed and scroll_drag_active:
			scroll_drag_active = false
	elif event is InputEventMouseMotion and scroll_drag_active:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_drag_scroll(event.relative.x)
	elif event is InputEventScreenTouch:
		if event.pressed and active_touch_index == -1 and _is_position_in_scroll(event.position):
			active_touch_index = event.index
			scroll_drag_active = true
		elif not event.pressed and scroll_drag_active and event.index == active_touch_index:
			scroll_drag_active = false
			active_touch_index = -1
	elif event is InputEventScreenDrag and scroll_drag_active and event.index == active_touch_index:
		_drag_scroll(event.relative.x)

func _build_scene() -> void:
	var background := ColorRect.new()
	background.name = "HowToBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.color = Color.html("#0b0d12")
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
	layout.add_child(_make_card_scroller())

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
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "HOW TO PLAY"
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

func _make_card_scroller() -> ScrollContainer:
	card_scroll = ScrollContainer.new()
	card_scroll.name = "CardScroll"
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	card_row = HBoxContainer.new()
	card_row.name = "CardRow"
	card_row.add_theme_constant_override("separation", 18)
	card_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_scroll.add_child(card_row)

	for card_data in CARD_DATA:
		card_row.add_child(_make_card(card_data))

	return card_scroll

func _make_card(data: Dictionary) -> PanelContainer:
	var accent := Color.html(String(data.get("accent", "#ffffff")))
	var card := PanelContainer.new()
	card.name = "%sCard" % String(data.get("title", "Guide")).replace(" ", "")
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var style := StyleBoxFlat.new()
	style.bg_color = Color.html("#151923")
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 8
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title := Label.new()
	title.name = "CardTitle"
	title.text = String(data.get("title", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", accent)
	content.add_child(title)

	content.add_child(_make_icon_area(data, accent))

	if String(data.get("title", "")) == "HOLD":
		content.add_child(_make_hold_bar(accent))

	var description := Label.new()
	description.name = "Description"
	description.text = String(data.get("description", ""))
	description.custom_minimum_size = Vector2(CARD_WIDTH - 46.0, 104.0)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_constant_override("line_spacing", 5)
	description.add_theme_color_override("font_color", Color.html("#f3f4f8"))
	content.add_child(description)

	var tags := Label.new()
	tags.name = "TargetTags"
	tags.text = "Targets: %s" % " / ".join(data.get("targets", []))
	tags.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tags.add_theme_font_size_override("font_size", 12)
	tags.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.54))
	content.add_child(tags)

	return card

func _make_icon_area(data: Dictionary, accent: Color) -> Control:
	var area := HBoxContainer.new()
	area.name = "IconArea"
	area.custom_minimum_size = Vector2(0.0, 104.0)
	area.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_theme_constant_override("separation", 10)

	if String(data.get("title", "")) == "COMBO & FEVER":
		area.add_child(_make_combo_visual(accent))
		return area

	for target in data.get("targets", []):
		area.add_child(_make_target_marker(String(target), accent))

	return area

func _make_target_marker(target: String, accent: Color) -> Control:
	var marker := VBoxContainer.new()
	marker.name = "%sMarker" % target
	marker.custom_minimum_size = Vector2(76.0, 98.0)
	marker.alignment = BoxContainer.ALIGNMENT_CENTER
	marker.add_theme_constant_override("separation", 4)

	var texture := _load_target_texture(target)
	if texture:
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = texture
		icon.ignore_texture_size = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(68.0, 62.0)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		marker.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.name = "FallbackIcon"
		fallback.text = String(target.substr(0, 1)).to_upper()
		fallback.custom_minimum_size = Vector2(68.0, 62.0)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 34)
		fallback.add_theme_color_override("font_color", accent)
		marker.add_child(fallback)

	var target_label := Label.new()
	target_label.name = "TargetName"
	target_label.text = target
	if target == "enemy_fast":
		target_label.text = "enemy_fast x2"
	target_label.custom_minimum_size = Vector2(78.0, 28.0)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_label.add_theme_font_size_override("font_size", 10)
	target_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.72))
	marker.add_child(target_label)

	return marker

func _make_combo_visual(accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ComboVisual"
	panel.custom_minimum_size = Vector2(210.0, 92.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.26)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var text := Label.new()
	text.text = "COMBO x12\nFEVER!\nTAP TAP TAP!"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 20)
	text.add_theme_color_override("font_color", accent)
	panel.add_child(text)

	return panel

func _make_hold_bar(accent: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = "HoldGauge"
	bar.custom_minimum_size = Vector2(CARD_WIDTH - 52.0, 20.0)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 72.0
	bar.show_percentage = false

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	background.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", background)

	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill)

	return bar

func _drag_scroll(relative_x: float) -> void:
	if is_zero_approx(relative_x):
		return
	card_scroll.scroll_horizontal = max(0, card_scroll.scroll_horizontal - int(round(relative_x)))
	get_viewport().set_input_as_handled()

func _is_position_in_scroll(position_value: Vector2) -> bool:
	return card_scroll.get_global_rect().has_point(position_value)

func _load_target_texture(target: String) -> Texture2D:
	if not KNOWN_OBJECT_TYPES.has(target):
		return null

	var data := ObjectTypes.get_data(target)
	var texture_path := String(data.get("texture", ""))
	if texture_path.is_empty():
		return null

	return _load_texture(texture_path)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		var imported_texture := load(path)
		if imported_texture is Texture2D:
			return imported_texture

	var image := Image.new()
	if image.load(path) == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
