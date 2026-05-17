extends CanvasLayer
class_name GameHUD

const GameBalance := preload("res://scripts/data/GameBalance.gd")
const HEART_FULL := "♥"
const HEART_EMPTY := "♡"

var root: Control
var score_label: Label
var hp_label: Label
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
var boss_timer_back: ColorRect
var boss_timer_fill: ColorRect
var _feedback_tween: Tween
var _fever_tap_tween: Tween

func _ready() -> void:
	_build_ui()
	visible = false

func show_runner() -> void:
	visible = true
	boss_back.visible = false
	boss_fill.visible = false
	boss_label.visible = false
	boss_timer_back.visible = false
	boss_timer_fill.visible = false
	hint_label.text = "TAP / TAP TAP / HOLD / DON'T CUT ITEMS"
	_set_fever_tap_visible(false)

func show_boss() -> void:
	visible = true
	boss_back.visible = true
	boss_fill.visible = true
	boss_label.visible = true
	boss_timer_back.visible = true
	boss_timer_fill.visible = true
	hint_label.text = "READ THE SIGNAL"
	_set_fever_tap_visible(false)

func update_runner(score: int, hp: int, combo: int, fever: int, is_fever: bool, coins: int) -> void:
	score_label.text = "SCORE %06d" % score
	hp_label.text = _heart_text(hp)
	combo_label.text = "COMBO %d" % combo
	coins_label.text = "COIN %d" % coins
	_set_bar_width(fever_fill, 260.0, clamp(float(fever) / float(GameBalance.FEVER_MAX), 0.0, 1.0))
	if is_fever:
		hint_label.text = "FEVER TAP!!"
	else:
		hint_label.text = "TAP / TAP TAP / HOLD / DON'T CUT ITEMS"
	_set_fever_tap_visible(is_fever)

func update_boss(score: int, hp: int, boss_hp: int, max_boss_hp: int, pattern_hint: String, time_ratio: float) -> void:
	score_label.text = "SCORE %06d" % score
	hp_label.text = _heart_text(hp)
	combo_label.text = pattern_hint
	coins_label.text = ""
	_set_bar_width(fever_fill, 260.0, 0.0)
	_set_bar_width(boss_fill, 300.0, clamp(float(boss_hp) / float(max_boss_hp), 0.0, 1.0))
	_set_bar_width(boss_timer_fill, 300.0, clamp(time_ratio, 0.0, 1.0))
	boss_label.text = "BOSS %d/%d" % [boss_hp, max_boss_hp]
	_set_fever_tap_visible(pattern_hint == "FEVER")

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

func _build_ui() -> void:
	root = Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	score_label = _make_label(Vector2(26.0, 18.0), Vector2(240.0, 40.0), 24, Color(1.0, 1.0, 1.0, 1.0))
	hp_label = _make_label(Vector2(285.0, 16.0), Vector2(140.0, 44.0), 29, Color.html("#ff5b6d"))
	combo_label = _make_label(Vector2(410.0, 18.0), Vector2(180.0, 40.0), 24, Color.html("#ffef8a"))
	coins_label = _make_label(Vector2(604.0, 18.0), Vector2(150.0, 40.0), 24, Color.html("#ffd84a"))

	fever_back = _make_rect(Vector2(782.0, 24.0), Vector2(264.0, 22.0), Color(0.0, 0.0, 0.0, 0.38))
	fever_fill = _make_rect(Vector2(784.0, 26.0), Vector2(0.0, 18.0), Color.html("#57d8ff"))
	var fever_label := _make_label(Vector2(786.0, 50.0), Vector2(260.0, 24.0), 15, Color(1.0, 1.0, 1.0, 0.72))
	fever_label.text = "FEVER"

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

	fever_tap_label = _make_label(Vector2(390.0, 252.0), Vector2(500.0, 150.0), 86, Color.html("#fff26a"))
	fever_tap_label.text = "TAP!!"
	fever_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fever_tap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fever_tap_label.pivot_offset = fever_tap_label.size * 0.5
	fever_tap_label.add_theme_constant_override("outline_size", 8)
	fever_tap_label.add_theme_color_override("font_outline_color", Color.html("#26344d"))
	fever_tap_label.visible = false

func _make_label(pos: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

func _make_rect(pos: Vector2, size_value: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size_value
	rect.color = color
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

func _heart_text(hp: int) -> String:
	var clamped_hp: int = clampi(hp, 0, GameBalance.MAX_HP)
	var hearts := ""
	for index in range(GameBalance.MAX_HP):
		hearts += HEART_FULL if index < clamped_hp else HEART_EMPTY
		if index < GameBalance.MAX_HP - 1:
			hearts += " "
	return hearts
