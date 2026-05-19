extends CanvasLayer
class_name SettingsPopup

const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const DebugFlagsAccess := preload("res://scripts/utils/DebugFlagsAccess.gd")
const GAME_SETTINGS_PATH := "/root/GameSettings"

var root: Control
var dim: ColorRect
var panel: PanelContainer
var title_label: Label
var volume_value_label: Label
var volume_slider: HSlider
var attack_vibration_toggle: CheckButton
var player_hurt_vibration_toggle: CheckButton
var invincible_debug_toggle: CheckButton
var close_button: Button
var _syncing_controls := false

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_bind_settings()
	_sync_from_settings()
	close_popup()
	get_viewport().size_changed.connect(_sync_layout)

func open_popup() -> void:
	_sync_from_settings()
	_set_popup_visible(true)

func close_popup() -> void:
	_set_popup_visible(false)

func is_popup_open() -> bool:
	return root != null and root.visible

func _build_ui() -> void:
	root = Control.new()
	root.name = "SettingsRoot"
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.64)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.size = Vector2(560.0, 500.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.09, 0.11, 0.98)
	panel_style.border_color = Color(1.0, 0.88, 0.45, 0.9)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 36.0
	content.offset_top = 30.0
	content.offset_right = -36.0
	content.offset_bottom = -30.0
	panel.add_child(content)

	title_label = _make_label("SETTING", 44, Color.WHITE, Vector2(488.0, 58.0))
	content.add_child(title_label)

	var volume_row := HBoxContainer.new()
	volume_row.name = "VolumeRow"
	volume_row.alignment = BoxContainer.ALIGNMENT_CENTER
	volume_row.add_theme_constant_override("separation", 16)
	volume_row.custom_minimum_size = Vector2(488.0, 48.0)
	content.add_child(volume_row)

	var volume_label := _make_label("VOLUME", 24, Color(1.0, 1.0, 1.0, 0.9), Vector2(130.0, 40.0))
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	volume_row.add_child(volume_label)

	volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.custom_minimum_size = Vector2(250.0, 40.0)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume_slider)

	volume_value_label = _make_label("100", 22, Color.html("#ffef8a"), Vector2(70.0, 40.0))
	volume_row.add_child(volume_value_label)

	attack_vibration_toggle = _make_toggle("공격진동")
	AudioHooksScript.bind_ui_button(self, attack_vibration_toggle)
	attack_vibration_toggle.toggled.connect(_on_attack_vibration_toggled)
	content.add_child(attack_vibration_toggle)

	player_hurt_vibration_toggle = _make_toggle("피격시진동")
	AudioHooksScript.bind_ui_button(self, player_hurt_vibration_toggle)
	player_hurt_vibration_toggle.toggled.connect(_on_player_hurt_vibration_toggled)
	content.add_child(player_hurt_vibration_toggle)

	invincible_debug_toggle = _make_toggle("무적 (게임테스트용)")
	AudioHooksScript.bind_ui_button(self, invincible_debug_toggle)
	invincible_debug_toggle.toggled.connect(_on_invincible_debug_toggled)
	content.add_child(invincible_debug_toggle)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "CLOSE"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(180.0, 58.0)
	close_button.add_theme_font_size_override("font_size", 24)
	AudioHooksScript.bind_ui_button(self, close_button)
	close_button.pressed.connect(close_popup)
	content.add_child(close_button)

	_sync_layout()

func _make_label(text: String, font_size: int, color: Color, size_value: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_toggle(label_text: String) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = label_text
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.custom_minimum_size = Vector2(488.0, 54.0)
	toggle.alignment = HORIZONTAL_ALIGNMENT_CENTER
	toggle.add_theme_font_size_override("font_size", 24)
	return toggle

func _bind_settings() -> void:
	var settings = _get_game_settings()
	if settings == null:
		return
	settings.volume_changed.connect(_on_settings_volume_changed)
	settings.attack_vibration_changed.connect(_on_settings_attack_vibration_changed)
	settings.player_hurt_vibration_changed.connect(_on_settings_player_hurt_vibration_changed)

func _sync_from_settings() -> void:
	_syncing_controls = true
	var settings = _get_game_settings()
	if settings != null:
		volume_slider.value = float(settings.volume_percent)
		volume_value_label.text = "%d" % int(settings.volume_percent)
		attack_vibration_toggle.button_pressed = bool(settings.attack_vibration_enabled)
		player_hurt_vibration_toggle.button_pressed = bool(settings.player_hurt_vibration_enabled)
		_update_toggle_text(attack_vibration_toggle, "공격진동", attack_vibration_toggle.button_pressed)
		_update_toggle_text(player_hurt_vibration_toggle, "피격시진동", player_hurt_vibration_toggle.button_pressed)
	var debug_flags := _get_debug_flags()
	var invincible_enabled := debug_flags != null and bool(debug_flags.player_invincible)
	invincible_debug_toggle.button_pressed = invincible_enabled
	_update_toggle_text(invincible_debug_toggle, "무적 (게임테스트용)", invincible_enabled)
	_syncing_controls = false

func _sync_layout() -> void:
	if root == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	root.size = viewport_size
	if dim:
		dim.position = Vector2.ZERO
		dim.size = viewport_size
	if panel:
		panel.position = (viewport_size - panel.size) * 0.5

func _set_popup_visible(visible_value: bool) -> void:
	if root:
		root.visible = visible_value

func _on_volume_changed(value: float) -> void:
	if _syncing_controls:
		return
	var settings = _get_game_settings()
	if settings != null and settings.has_method("set_volume_percent"):
		settings.set_volume_percent(int(round(value)))

func _on_attack_vibration_toggled(enabled: bool) -> void:
	_update_toggle_text(attack_vibration_toggle, "공격진동", enabled)
	if _syncing_controls:
		return
	var settings = _get_game_settings()
	if settings != null and settings.has_method("set_attack_vibration_enabled"):
		settings.set_attack_vibration_enabled(enabled)

func _on_player_hurt_vibration_toggled(enabled: bool) -> void:
	_update_toggle_text(player_hurt_vibration_toggle, "피격시진동", enabled)
	if _syncing_controls:
		return
	var settings = _get_game_settings()
	if settings != null and settings.has_method("set_player_hurt_vibration_enabled"):
		settings.set_player_hurt_vibration_enabled(enabled)

func _on_invincible_debug_toggled(enabled: bool) -> void:
	_update_toggle_text(invincible_debug_toggle, "무적 (게임테스트용)", enabled)
	if _syncing_controls:
		return
	var debug_flags := _get_debug_flags()
	if debug_flags != null:
		debug_flags.player_invincible = enabled

func _on_settings_volume_changed(value: int) -> void:
	if volume_slider == null:
		return
	_syncing_controls = true
	volume_slider.value = float(value)
	volume_value_label.text = "%d" % value
	_syncing_controls = false

func _on_settings_attack_vibration_changed(enabled: bool) -> void:
	_syncing_controls = true
	attack_vibration_toggle.button_pressed = enabled
	_update_toggle_text(attack_vibration_toggle, "공격진동", enabled)
	_syncing_controls = false

func _on_settings_player_hurt_vibration_changed(enabled: bool) -> void:
	_syncing_controls = true
	player_hurt_vibration_toggle.button_pressed = enabled
	_update_toggle_text(player_hurt_vibration_toggle, "피격시진동", enabled)
	_syncing_controls = false

func _update_toggle_text(toggle: CheckButton, label_text: String, enabled: bool) -> void:
	if toggle:
		toggle.text = "%s  %s" % [label_text, "ON" if enabled else "OFF"]

func _get_game_settings() -> Node:
	return get_node_or_null(GAME_SETTINGS_PATH)

func _get_debug_flags() -> Node:
	return DebugFlagsAccess.get_debug_flags(self)
