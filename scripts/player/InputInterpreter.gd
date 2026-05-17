extends Node
class_name InputInterpreter

signal tap_detected
signal double_tap_detected
signal long_tap_detected
signal debug_restart_requested

const GameBalance := preload("res://scripts/data/GameBalance.gd")

var _press_started_at := -1.0
var _last_tap_at := -10.0
var _slash_recovery_until := -10.0
var _press_started_in_recovery := false
var _pressed_by_touch := false
var _fever_mode_active := false
var _action_blocked_provider := Callable()

func _process(_delta: float) -> void:
	if _is_action_blocked():
		_clear_current_press()
	if Input.is_action_just_pressed("tap_action"):
		_mark_pressed(false)
	if Input.is_action_just_released("tap_action"):
		_mark_released(false)
	if Input.is_action_just_pressed("debug_restart"):
		debug_restart_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_mark_pressed(true)
		else:
			_mark_released(true)

func reset_action_state() -> void:
	_press_started_at = -1.0
	_last_tap_at = -10.0
	_slash_recovery_until = -10.0
	_press_started_in_recovery = false
	_pressed_by_touch = false

func set_fever_mode_active(active: bool) -> void:
	_fever_mode_active = active
	if active:
		_slash_recovery_until = -10.0

func set_action_blocked_provider(provider: Callable) -> void:
	_action_blocked_provider = provider

func clear_action_blocked_provider() -> void:
	_action_blocked_provider = Callable()

func _mark_pressed(from_touch: bool) -> void:
	if _is_action_blocked():
		_clear_current_press()
		return
	if _pressed_by_touch and not from_touch:
		return
	_pressed_by_touch = from_touch
	var pressed_at := _now()
	_press_started_at = pressed_at
	_press_started_in_recovery = _is_recovering(pressed_at)

func _mark_released(from_touch: bool) -> void:
	if _is_action_blocked():
		_clear_current_press()
		return
	if _press_started_at < 0.0:
		return
	if _pressed_by_touch and not from_touch:
		return
	var released_at := _now()
	var duration := released_at - _press_started_at
	_press_started_at = -1.0
	_pressed_by_touch = false

	var is_double_tap_followup := _is_double_tap_followup(released_at)
	if min(duration, GameBalance.LONG_TAP_MAX_CHARGE_TIME) >= GameBalance.LONG_TAP_THRESHOLD:
		if _press_started_in_recovery or _is_recovering(released_at):
			_press_started_in_recovery = false
			return
		long_tap_detected.emit()
		_last_tap_at = -10.0
		_start_recovery(GameBalance.LONG_TAP_SLASH_RECOVERY, released_at)
		_press_started_in_recovery = false
		return

	if is_double_tap_followup:
		double_tap_detected.emit()
		_last_tap_at = -10.0
		_start_recovery(GameBalance.DOUBLE_TAP_SLASH_RECOVERY, released_at)
		_press_started_in_recovery = false
		return

	if _press_started_in_recovery or _is_recovering(released_at):
		_press_started_in_recovery = false
		return

	tap_detected.emit()
	_last_tap_at = released_at
	_start_recovery(GameBalance.TAP_SLASH_RECOVERY, released_at)
	_press_started_in_recovery = false

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _is_double_tap_followup(released_at: float) -> bool:
	return released_at - _last_tap_at <= GameBalance.DOUBLE_TAP_WINDOW

func _is_recovering(at_time: float) -> bool:
	if _fever_mode_active:
		return false
	return at_time < _slash_recovery_until

func _start_recovery(duration: float, started_at: float) -> void:
	if _fever_mode_active:
		return
	_slash_recovery_until = started_at + duration

func _is_action_blocked() -> bool:
	if not _action_blocked_provider.is_valid():
		return false
	return bool(_action_blocked_provider.call())

func _clear_current_press() -> void:
	_press_started_at = -1.0
	_press_started_in_recovery = false
	_pressed_by_touch = false
