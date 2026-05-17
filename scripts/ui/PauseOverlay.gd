extends CanvasLayer
class_name PauseOverlay

signal quit_requested

const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")

var root: Control
var pause_button: Button
var dim: ColorRect
var popup: PanelContainer
var title_label: Label
var resume_button: Button
var quit_button: Button

var _gameplay_active := false

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_gameplay_active(false)
	get_viewport().size_changed.connect(_sync_layout)

func set_gameplay_active(active: bool) -> void:
	_gameplay_active = active
	if pause_button:
		pause_button.visible = active
	if not active:
		close_popup()

func open_popup() -> void:
	if not _gameplay_active:
		return
	get_tree().paused = true
	_set_popup_visible(true)

func close_popup() -> void:
	get_tree().paused = false
	_set_popup_visible(false)

func is_popup_open() -> bool:
	return popup != null and popup.visible

func _build_ui() -> void:
	root = Control.new()
	root.name = "PauseRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "II"
	pause_button.tooltip_text = "Pause"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.add_theme_font_size_override("font_size", 24)
	AudioHooksScript.bind_ui_button(self, pause_button)
	pause_button.pressed.connect(_on_pause_pressed)
	root.add_child(pause_button)

	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	popup = PanelContainer.new()
	popup.name = "Popup"
	popup.size = Vector2(420.0, 260.0)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(popup)

	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.08, 0.09, 0.11, 0.98)
	popup_style.border_color = Color(1.0, 0.88, 0.45, 0.9)
	popup_style.set_border_width_all(3)
	popup_style.set_corner_radius_all(8)
	popup.add_theme_stylebox_override("panel", popup_style)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 34.0
	content.offset_top = 30.0
	content.offset_right = -34.0
	content.offset_bottom = -30.0
	popup.add_child(content)

	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = "PAUSED"
	title_label.custom_minimum_size = Vector2(352.0, 78.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	content.add_child(title_label)

	var button_row := HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)
	button_row.custom_minimum_size = Vector2(352.0, 64.0)
	content.add_child(button_row)

	resume_button = _make_popup_button("RESUME")
	resume_button.pressed.connect(_on_resume_pressed)
	button_row.add_child(resume_button)

	quit_button = _make_popup_button("QUIT")
	quit_button.pressed.connect(_on_quit_pressed)
	button_row.add_child(quit_button)

	_sync_layout()
	_set_popup_visible(false)

func _make_popup_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(154.0, 58.0)
	button.add_theme_font_size_override("font_size", 23)
	AudioHooksScript.bind_ui_button(self, button)
	return button

func _sync_layout() -> void:
	if root == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	root.size = viewport_size
	if pause_button:
		pause_button.position = Vector2(viewport_size.x - 84.0, 18.0)
		pause_button.size = Vector2(58.0, 58.0)
	if dim:
		dim.position = Vector2.ZERO
		dim.size = viewport_size
	if popup:
		popup.position = (viewport_size - popup.size) * 0.5

func _set_popup_visible(visible_value: bool) -> void:
	if dim:
		dim.visible = visible_value
	if popup:
		popup.visible = visible_value
	if pause_button:
		pause_button.disabled = visible_value

func _on_pause_pressed() -> void:
	open_popup()

func _on_resume_pressed() -> void:
	close_popup()

func _on_quit_pressed() -> void:
	close_popup()
	quit_requested.emit()
