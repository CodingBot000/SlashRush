extends SceneTree

const INPUT_INTERPRETER_SCRIPT := preload("res://scripts/player/InputInterpreter.gd")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

var _tap_count := 0
var _double_tap_count := 0
var _long_tap_count := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_ensure_input_actions()
	var input = INPUT_INTERPRETER_SCRIPT.new()
	root.add_child(input)
	input.tap_detected.connect(_on_tap_detected)
	input.double_tap_detected.connect(_on_double_tap_detected)
	input.long_tap_detected.connect(_on_long_tap_detected)

	await _assert_double_tap_uses_followup_exception(input)
	await _assert_recovery_blocks_presses_started_during_recovery(input)
	await _assert_long_tap_recovery(input)
	await _assert_fever_ignores_recovery(input)

	input.free()
	quit()

func _assert_double_tap_uses_followup_exception(input) -> void:
	_reset_counts(input)
	_quick_tap(input)
	await create_timer(0.04).timeout
	_quick_tap(input)
	await process_frame

	if _tap_count != 1 or _double_tap_count != 1 or _long_tap_count != 0:
		push_error("Double tap should emit one tap and one double_tap.")
		quit(1)

	_quick_tap(input)
	await process_frame
	if _tap_count != 1 or _double_tap_count != 1:
		push_error("Double tap recovery should block immediate extra taps.")
		quit(1)

func _assert_recovery_blocks_presses_started_during_recovery(input) -> void:
	_reset_counts(input)
	_quick_tap(input)
	await create_timer(0.05).timeout

	input._mark_pressed(false)
	await create_timer(GameBalance.DOUBLE_TAP_WINDOW + 0.03).timeout
	input._mark_released(false)
	await process_frame

	if _tap_count != 1 or _double_tap_count != 0:
		push_error("Tap recovery should block a tap that began during recovery.")
		quit(1)

func _assert_long_tap_recovery(input) -> void:
	_reset_counts(input)
	input._mark_pressed(false)
	await create_timer(GameBalance.LONG_TAP_THRESHOLD + 0.03).timeout
	input._mark_released(false)
	await process_frame

	if _long_tap_count != 1:
		push_error("Long tap should emit after the hold threshold.")
		quit(1)

	_quick_tap(input)
	await process_frame
	if _tap_count != 0:
		push_error("Long tap recovery should block immediate taps.")
		quit(1)

	await create_timer(GameBalance.LONG_TAP_SLASH_RECOVERY + 0.03).timeout
	_quick_tap(input)
	await process_frame
	if _tap_count != 1:
		push_error("Tap should emit after long tap recovery expires.")
		quit(1)

func _assert_fever_ignores_recovery(input) -> void:
	_reset_counts(input)
	input.set_fever_mode_active(true)
	input._mark_pressed(false)
	await create_timer(GameBalance.LONG_TAP_THRESHOLD + 0.03).timeout
	input._mark_released(false)
	await process_frame
	_quick_tap(input)
	await process_frame

	if _long_tap_count != 1 or _tap_count != 1:
		push_error("Fever mode should ignore slash recovery.")
		quit(1)

func _quick_tap(input) -> void:
	input._mark_pressed(false)
	input._mark_released(false)

func _reset_counts(input) -> void:
	_tap_count = 0
	_double_tap_count = 0
	_long_tap_count = 0
	input.reset_action_state()
	input.set_fever_mode_active(false)

func _ensure_input_actions() -> void:
	if not InputMap.has_action("tap_action"):
		InputMap.add_action("tap_action")
	if not InputMap.has_action("debug_restart"):
		InputMap.add_action("debug_restart")

func _on_tap_detected() -> void:
	_tap_count += 1

func _on_double_tap_detected() -> void:
	_double_tap_count += 1

func _on_long_tap_detected() -> void:
	_long_tap_count += 1
