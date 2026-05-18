extends CanvasLayer
class_name GameHUD

signal debug_fever_fill_requested
signal gameplay_pointer_pressed(from_touch)
signal gameplay_pointer_released(from_touch)

const GameBalance := preload("res://scripts/data/GameBalance.gd")
const AudioHooksScript := preload("res://scripts/audio/AudioHooks.gd")
const COMBO_IMPACT_POPUP_SCRIPT := preload("res://scripts/ui/ComboImpactPopup.gd")
const HEART_DISPLAY_SCRIPT := preload("res://scripts/ui/HeartDisplay.gd")
const HUD_TEXT_OUTLINE_SIZE := 5
const HUD_TEXT_OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.88)
const DEBUG_INVINCIBLE_BUTTON_VISIBLE := false
const DEBUG_FEVER_FILL_VISIBLE := false
const FEVER_TAP_LABEL_SIZE := Vector2(500.0, 150.0)
const FEVER_TAP_LABEL_Y_RATIO := 0.2
const INVINCIBLE_DEBUG_WARNING_TEXT := "무적디버그 사용중"

var root: Control
var gameplay_touch_area: Control
var score_label: Label
var hp_label: Label
var hp_hearts
var combo_label: Label
var coins_label: Label
var hint_label: Label
var fever_back: ColorRect
var fever_fill: ColorRect
var boss_back: ColorRect
var boss_fill: ColorRect
var boss_label: Label
var feedback_label: Label
var fever_tap_label: Label
var invincible_debug_warning_label: Label
var combo_popup
var boss_timer_back: ColorRect
var boss_timer_fill: ColorRect
var debug_invincible_button: Button
var debug_fever_fill_button: Button
var _feedback_tween: Tween
var _fever_tap_tween: Tween
var _syncing_debug_invincible_button := false

func _ready() -> void:
	_build_ui()
	visible = false
	get_viewport().size_changed.connect(_sync_debug_buttons_layout)

func show_runner() -> void:
	visible = true
	_sync_debug_invincible_button()
	boss_back.visible = false
	boss_fill.visible = false
	boss_label.visible = false
	boss_timer_back.visible = false
	boss_timer_fill.visible = false
	#hint_label.text = "TAP / TAP TAP / HOLD / DON'T CUT ITEMS"
	_set_fever_tap_visible(false)

func show_boss() -> void:
	visible = true
	_sync_debug_invincible_button()
	boss_back.visible = true
	boss_fill.visible = true
	boss_label.visible = true
	boss_timer_back.visible = true
	boss_timer_fill.visible = true
	hint_label.text = ""
	_set_fever_tap_visible(false)

func update_runner(score: int, hp: int, combo: int, fever: int, is_fever: bool, coins: int) -> void:
	_sync_debug_invincible_button()
	score_label.text = "SCORE %06d" % score
	_set_hp_hearts(hp)
	combo_label.text = "COMBO %d" % combo
	coins_label.text = "COIN %d" % coins
	_set_bar_width(fever_fill, 260.0, clamp(float(fever) / float(GameBalance.FEVER_MAX), 0.0, 1.0))
	#if is_fever:
		#hint_label.text = "FEVER TAP!!"
	#else:
		#hint_label.text = "TAP / TAP TAP / HOLD / DON'T CUT ITEMS"
	_set_fever_tap_visible(is_fever)

func update_boss(score: int, hp: int, boss_hp: int, max_boss_hp: int, _pattern_hint: String, time_ratio: float) -> void:
	_sync_debug_invincible_button()
	score_label.text = "SCORE %06d" % score
	_set_hp_hearts(hp)
	combo_label.text = ""
	coins_label.text = ""
	_set_bar_width(fever_fill, 260.0, 0.0)
	_set_bar_width(boss_fill, 300.0, clamp(float(boss_hp) / float(max_boss_hp), 0.0, 1.0))
	_set_bar_width(boss_timer_fill, 300.0, clamp(time_ratio, 0.0, 1.0))
	boss_label.text = "BOSS %d/%d" % [boss_hp, max_boss_hp]
	_set_fever_tap_visible(false)

func show_feedback(text: String, color: Color) -> void:
	if _feedback_tween:
		_feedback_tween.kill()
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	feedback_label.scale = Vector2(1.12, 1.12)
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.08)
	_feedback_tween.tween_interval(0.55)
	_feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.22)

func show_combo_impact(combo: int = 0) -> void:
	if combo_popup:
		combo_popup.play(combo)

func _on_gameplay_touch_area_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			gameplay_pointer_pressed.emit(true)
		else:
			gameplay_pointer_released.emit(true)
		gameplay_touch_area.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			gameplay_pointer_pressed.emit(false)
		else:
			gameplay_pointer_released.emit(false)
		gameplay_touch_area.accept_event()

func _build_ui() -> void:
	root = Control.new()
	root.name = "HUDRoot"
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	gameplay_touch_area = Control.new()
	gameplay_touch_area.name = "GameplayTouchArea"
	gameplay_touch_area.mouse_filter = Control.MOUSE_FILTER_STOP
	gameplay_touch_area.gui_input.connect(_on_gameplay_touch_area_gui_input)
	root.add_child(gameplay_touch_area)

	score_label = _make_label(Vector2(26.0, 18.0), Vector2(240.0, 40.0), 24, Color(1.0, 1.0, 1.0, 1.0))
	hp_label = _make_label(Vector2(285.0, 16.0), Vector2(140.0, 44.0), 29, Color.html("#ff5b6d"))
	hp_label.text = ""
	hp_label.visible = false
	hp_hearts = HEART_DISPLAY_SCRIPT.new()
	hp_hearts.name = "HPHearts"
	hp_hearts.position = Vector2(285.0, 16.0)
	hp_hearts.size = Vector2(150.0, 44.0)
	root.add_child(hp_hearts)
	_set_hp_hearts(GameBalance.STARTING_HP)
	combo_label = _make_label(Vector2(410.0, 18.0), Vector2(180.0, 40.0), 24, Color.html("#ffef8a"))
	coins_label = _make_label(Vector2(604.0, 18.0), Vector2(150.0, 40.0), 24, Color.html("#ffd84a"))

	fever_back = _make_rect(Vector2(782.0, 24.0), Vector2(264.0, 22.0), Color(0.0, 0.0, 0.0, 0.38))
	fever_fill = _make_rect(Vector2(784.0, 26.0), Vector2(0.0, 18.0), Color.html("#57d8ff"))
	var fever_label := _make_label(Vector2(786.0, 50.0), Vector2(260.0, 24.0), 15, Color(1.0, 1.0, 1.0, 0.72))
	fever_label.text = "FEVER"

	invincible_debug_warning_label = _make_label(Vector2.ZERO, Vector2(260.0, 24.0), 18, Color.html("#ff2f3a"))
	invincible_debug_warning_label.name = "InvincibleDebugWarningLabel"
	invincible_debug_warning_label.text = INVINCIBLE_DEBUG_WARNING_TEXT
	invincible_debug_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	invincible_debug_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	invincible_debug_warning_label.visible = false

	boss_back = _make_rect(Vector2(956.0, 84.0), Vector2(304.0, 20.0), Color(0.0, 0.0, 0.0, 0.38))
	boss_fill = _make_rect(Vector2(958.0, 86.0), Vector2(300.0, 16.0), Color.html("#ff5b6d"))
	boss_label = _make_label(Vector2(956.0, 108.0), Vector2(304.0, 28.0), 18, Color(1.0, 1.0, 1.0, 0.85))
	boss_timer_back = _make_rect(Vector2(956.0, 142.0), Vector2(304.0, 14.0), Color(0.0, 0.0, 0.0, 0.28))
	boss_timer_fill = _make_rect(Vector2(958.0, 144.0), Vector2(300.0, 10.0), Color.html("#f7fbff"))

	hint_label = _make_label(Vector2(290.0, 650.0), Vector2(700.0, 42.0), 24, Color(1.0, 1.0, 1.0, 0.82))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	feedback_label = _make_label(Vector2(460.0, 92.0), Vector2(360.0, 74.0), 42, Color(1.0, 1.0, 1.0, 1.0))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.modulate.a = 0.0

	fever_tap_label = _make_label(Vector2.ZERO, FEVER_TAP_LABEL_SIZE, 86, Color.html("#fff26a"))
	fever_tap_label.text = "TAP!!"
	fever_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fever_tap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fever_tap_label.pivot_offset = fever_tap_label.size * 0.5
	fever_tap_label.add_theme_constant_override("outline_size", 8)
	fever_tap_label.add_theme_color_override("font_outline_color", Color.html("#26344d"))
	fever_tap_label.visible = false

	combo_popup = COMBO_IMPACT_POPUP_SCRIPT.new()
	combo_popup.name = "ComboImpactPopup"
	root.add_child(combo_popup)

	debug_invincible_button = Button.new()
	debug_invincible_button.name = "DebugInvincibleButton"
	debug_invincible_button.toggle_mode = true
	debug_invincible_button.focus_mode = Control.FOCUS_NONE
	debug_invincible_button.size = Vector2(108.0, 46.0)
	debug_invincible_button.visible = DEBUG_INVINCIBLE_BUTTON_VISIBLE
	debug_invincible_button.add_theme_font_size_override("font_size", 18)
	AudioHooksScript.bind_ui_button(self, debug_invincible_button)
	debug_invincible_button.toggled.connect(_on_debug_invincible_toggled)
	root.add_child(debug_invincible_button)

	debug_fever_fill_button = Button.new()
	debug_fever_fill_button.name = "DebugFeverFillButton"
	debug_fever_fill_button.focus_mode = Control.FOCUS_NONE
	debug_fever_fill_button.size = Vector2(108.0, 46.0)
	debug_fever_fill_button.text = "FEVER FILL"
	debug_fever_fill_button.visible = DEBUG_FEVER_FILL_VISIBLE
	debug_fever_fill_button.add_theme_font_size_override("font_size", 15)
	AudioHooksScript.bind_ui_button(self, debug_fever_fill_button)
	debug_fever_fill_button.pressed.connect(_on_debug_fever_fill_pressed)
	root.add_child(debug_fever_fill_button)
	_sync_debug_buttons_layout()
	_sync_debug_invincible_button()

func _make_label(pos: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", HUD_TEXT_OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", HUD_TEXT_OUTLINE_COLOR)
	root.add_child(label)
	return label

func _make_rect(pos: Vector2, size_value: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size_value
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rect)
	return rect

func _set_bar_width(rect: ColorRect, max_width: float, ratio: float) -> void:
	rect.size.x = max_width * ratio

func _set_fever_tap_visible(visible_value: bool) -> void:
	if not fever_tap_label:
		return
	if fever_tap_label.visible == visible_value:
		return
	fever_tap_label.visible = visible_value
	if visible_value:
		_start_fever_tap_tween()
	else:
		_stop_fever_tap_tween()

func _start_fever_tap_tween() -> void:
	_stop_fever_tap_tween()
	fever_tap_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fever_tap_label.scale = Vector2.ONE
	_fever_tap_tween = create_tween()
	_fever_tap_tween.set_loops()
	_fever_tap_tween.tween_property(fever_tap_label, "scale", Vector2(1.26, 1.26), 0.08)
	_fever_tap_tween.tween_property(fever_tap_label, "scale", Vector2(0.96, 0.96), 0.08)

func _stop_fever_tap_tween() -> void:
	if _fever_tap_tween:
		_fever_tap_tween.kill()
		_fever_tap_tween = null
	if fever_tap_label:
		fever_tap_label.scale = Vector2.ONE

func _set_hp_hearts(hp: int) -> void:
	if hp_hearts != null and hp_hearts.has_method("set_hp"):
		hp_hearts.set_hp(hp, GameBalance.MAX_HP)

func _sync_debug_buttons_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if root:
		root.size = viewport_size
	if gameplay_touch_area:
		gameplay_touch_area.position = Vector2.ZERO
		gameplay_touch_area.size = viewport_size
	_sync_fever_tap_layout(viewport_size)
	if invincible_debug_warning_label:
		invincible_debug_warning_label.position = Vector2(viewport_size.x - invincible_debug_warning_label.size.x - 16.0, 0.0)
	if not debug_invincible_button:
		return
	debug_invincible_button.position = Vector2(viewport_size.x - debug_invincible_button.size.x - 8.0, viewport_size.y * 0.5 - debug_invincible_button.size.y * 0.5)
	if debug_fever_fill_button:
		debug_fever_fill_button.position = debug_invincible_button.position + Vector2(0.0, debug_invincible_button.size.y + 8.0)

func _sync_fever_tap_layout(viewport_size: Vector2) -> void:
	if not fever_tap_label:
		return
	fever_tap_label.size = FEVER_TAP_LABEL_SIZE
	fever_tap_label.pivot_offset = fever_tap_label.size * 0.5
	fever_tap_label.position = Vector2(
		(viewport_size.x - fever_tap_label.size.x) * 0.5,
		viewport_size.y * FEVER_TAP_LABEL_Y_RATIO - fever_tap_label.size.y * 0.5
	)

func _sync_debug_invincible_button() -> void:
	if not debug_invincible_button:
		return
	var debug_flags := _get_debug_flags()
	var enabled := debug_flags != null and bool(debug_flags.player_invincible)
	_syncing_debug_invincible_button = true
	debug_invincible_button.button_pressed = enabled
	_syncing_debug_invincible_button = false
	_update_debug_invincible_button_text(enabled)
	_update_invincible_debug_warning(enabled)

func _on_debug_invincible_toggled(enabled: bool) -> void:
	_update_debug_invincible_button_text(enabled)
	if _syncing_debug_invincible_button:
		return
	var debug_flags := _get_debug_flags()
	if debug_flags != null:
		debug_flags.player_invincible = enabled
	_update_invincible_debug_warning(enabled)

func _update_debug_invincible_button_text(enabled: bool) -> void:
	if debug_invincible_button:
		debug_invincible_button.text = "무적 %s" % ("ON" if enabled else "OFF")

func _update_invincible_debug_warning(enabled: bool) -> void:
	if invincible_debug_warning_label:
		invincible_debug_warning_label.visible = enabled

func _on_debug_fever_fill_pressed() -> void:
	debug_fever_fill_requested.emit()

func _get_debug_flags() -> Node:
	return get_node_or_null("/root/DebugFlags")
