extends CanvasLayer
class_name ResultPanel

signal retry_requested
signal quit_requested

var root: Control
var popup: PanelContainer
var content: VBoxContainer
var button_row: HBoxContainer
var title_label: Label
var subtitle_label: Label
var score_label: Label
var best_label: Label
var retry_button: Button
var quit_button: Button

func _ready() -> void:
	layer = 100
	_build_ui()
	hide_panel()

func show_title(best_score: int) -> void:
	visible = true
	_sync_layout()
	title_label.text = "SLASH RUSH"
	subtitle_label.text = "TAP TO START"
	score_label.text = "Best Score  %d" % best_score
	best_label.text = "Cut enemies. Let good items pass."
	retry_button.text = "START"
	quit_button.visible = false

func show_result(won: bool, score: int, coins: int, best_score: int) -> void:
	visible = true
	_sync_layout()
	title_label.text = "VICTORY" if won else "GAME OVER"
	subtitle_label.text = "Choose your next move"
	score_label.text = "Score %d   Coins %d" % [score, coins]
	best_label.text = "Best Score %d" % best_score
	retry_button.text = "RETRY"
	quit_button.visible = true

func hide_panel() -> void:
	visible = false

func _build_ui() -> void:
	root = Control.new()
	root.name = "ResultRoot"
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.04, 0.86)
	root.add_child(dim)

	popup = PanelContainer.new()
	popup.name = "Popup"
	popup.size = Vector2(500.0, 380.0)
	root.add_child(popup)

	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.08, 0.09, 0.11, 0.96)
	popup_style.border_color = Color(1.0, 0.88, 0.45, 0.9)
	popup_style.set_border_width_all(3)
	popup_style.set_corner_radius_all(8)
	popup.add_theme_stylebox_override("panel", popup_style)

	content = VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 34.0
	content.offset_top = 34.0
	content.offset_right = -34.0
	content.offset_bottom = -34.0
	popup.add_child(content)

	title_label = _make_label(74, Color(1.0, 1.0, 1.0, 1.0), Vector2(432.0, 88.0))
	subtitle_label = _make_label(28, Color.html("#ffef8a"), Vector2(432.0, 42.0))
	score_label = _make_label(24, Color(1.0, 1.0, 1.0, 0.84), Vector2(432.0, 38.0))
	best_label = _make_label(20, Color(1.0, 1.0, 1.0, 0.68), Vector2(432.0, 34.0))

	button_row = HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 18)
	button_row.custom_minimum_size = Vector2(432.0, 64.0)
	content.add_child(button_row)

	retry_button = Button.new()
	retry_button.custom_minimum_size = Vector2(180.0, 60.0)
	retry_button.text = "START"
	retry_button.add_theme_font_size_override("font_size", 26)
	retry_button.pressed.connect(_on_retry_pressed)
	button_row.add_child(retry_button)

	quit_button = Button.new()
	quit_button.custom_minimum_size = Vector2(180.0, 60.0)
	quit_button.text = "QUIT"
	quit_button.add_theme_font_size_override("font_size", 26)
	quit_button.pressed.connect(_on_quit_pressed)
	button_row.add_child(quit_button)
	_sync_layout()

func _sync_layout() -> void:
	if root == null or popup == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	root.size = viewport_size
	popup.position = (viewport_size - popup.size) * 0.5

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
