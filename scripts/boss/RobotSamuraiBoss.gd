extends Node2D
class_name RobotSamuraiBoss

const GameBalance := preload("res://scripts/data/GameBalance.gd")

signal attack_strike_started(attack_type)
signal attack_strike_finished(attack_type)

enum MotionState {
	IDLE,
	ATTACK_WINDUP,
	ATTACK_STRIKE,
	ATTACK_RECOVER,
	STUN,
	HIT,
	DEFEATED
}

enum AttackType {
	NONE,
	RIGHT_ARM_SLAM,
	BOTH_ARM_SLAM,
	CORE_CHARGE
}

@export var idle_enabled: bool = true
@export var idle_time_scale: float = 1.0
@export var breath_cycle_seconds: float = 3.2
@export var body_bob_amount: float = 17.0
@export var body_breath_scale_amount: float = 0.026
@export var head_bob_amount: float = 11.0
@export var head_tilt_amount: float = 2.8
@export var arm_sway_amount: float = 7.0
@export var cloth_sway_amount: float = 6.5
@export var core_pulse_amount: float = 0.085
@export var stun_seconds: float = 0.75
@export var hit_seconds: float = 1.0
@export var hit_shake_amount: float = 22.0
@export var hit_rotation_amount: float = 5.5
@export var defeated_seconds: float = 1.4
@export var debug_motion_keys_enabled: bool = true
@export var auto_viewport_scale_enabled: bool = true
@export_range(0.1, 1.0, 0.01) var target_viewport_height_ratio: float = 0.82
@export_range(0.1, 1.0, 0.01) var target_viewport_width_ratio: float = 0.52
@export var minimum_auto_scale: float = 0.15
@export var maximum_auto_scale: float = 1.2

@onready var body_pivot: Node2D = $BodyPivot
@onready var head_pivot: Node2D = $HeadPivot
@onready var left_arm_pivot: Node2D = $LeftArmPivot
@onready var right_arm_pivot: Node2D = $RightArmPivot
@onready var core_pivot: Node2D = $CorePivot
@onready var core_sprite: Sprite2D = $CorePivot/Core
@onready var cloth_left_pivot: Node2D = $ClothLeftPivot
@onready var cloth_right_pivot: Node2D = $ClothRightPivot

var motion_state := MotionState.IDLE
var current_attack_type := AttackType.NONE
var current_attack_window_seconds := GameBalance.BOSS_TAP_ATTACK_WINDOW_SECONDS
var state_time := 0.0

var _time := 0.0
var _base_positions := {}
var _base_rotations := {}
var _base_scales := {}
var _base_core_modulate := Color.WHITE
var _base_self_position := Vector2.ZERO
var _base_self_rotation := 0.0

func _ready() -> void:
	_base_self_position = position
	_base_self_rotation = rotation_degrees
	_cache_base_pose()
	_fit_scale_to_viewport()
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_fit_scale_to_viewport)

func _unhandled_input(event: InputEvent) -> void:
	if not debug_motion_keys_enabled:
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# Dev-only motion preview keys. They do not create hitboxes or damage.
	match key_event.keycode:
		KEY_1, KEY_KP_1:
			start_right_arm_slam()
		KEY_2, KEY_KP_2:
			start_both_arm_slam()
		KEY_3, KEY_KP_3:
			start_core_charge()
		KEY_4, KEY_KP_4:
			start_wait()
		KEY_5, KEY_KP_5:
			start_hit()
		KEY_6, KEY_KP_6:
			start_defeated()

func _process(delta: float) -> void:
	_time += delta * maxf(idle_time_scale, 0.0)
	state_time += delta

	match motion_state:
		MotionState.IDLE:
			_process_idle(delta)
		MotionState.ATTACK_WINDUP:
			_process_attack_windup(delta)
		MotionState.ATTACK_STRIKE:
			_process_attack_strike(delta)
		MotionState.ATTACK_RECOVER:
			_process_attack_recover(delta)
		MotionState.STUN:
			_process_stun(delta)
		MotionState.HIT:
			_process_hit(delta)
		MotionState.DEFEATED:
			_process_defeated(delta)

func start_right_arm_slam(attack_window_seconds: float = GameBalance.BOSS_TAP_ATTACK_WINDOW_SECONDS) -> void:
	start_attack(AttackType.RIGHT_ARM_SLAM, attack_window_seconds)

func start_both_arm_slam(attack_window_seconds: float = GameBalance.BOSS_DOUBLE_TAP_ATTACK_WINDOW_SECONDS) -> void:
	start_attack(AttackType.BOTH_ARM_SLAM, attack_window_seconds)

func start_core_charge(attack_window_seconds: float = GameBalance.BOSS_LONG_TAP_ATTACK_WINDOW_SECONDS) -> void:
	start_attack(AttackType.CORE_CHARGE, attack_window_seconds)

func start_attack(attack_type: int, attack_window_seconds: float) -> void:
	if motion_state == MotionState.DEFEATED:
		return
	if attack_type == AttackType.NONE:
		return

	current_attack_type = attack_type
	current_attack_window_seconds = maxf(attack_window_seconds, _get_min_attack_window_seconds(attack_type))
	if motion_state == MotionState.ATTACK_WINDUP:
		state_time = 0.0
		_enter_state(MotionState.ATTACK_WINDUP)
	else:
		set_motion_state(MotionState.ATTACK_WINDUP)

func start_stun() -> void:
	if motion_state == MotionState.DEFEATED:
		return

	current_attack_type = AttackType.NONE
	set_motion_state(MotionState.STUN)

func start_wait() -> void:
	if motion_state == MotionState.DEFEATED:
		return

	current_attack_type = AttackType.NONE
	set_motion_state(MotionState.IDLE)

func start_hit() -> void:
	if motion_state == MotionState.DEFEATED:
		return
	if motion_state == MotionState.HIT:
		state_time = 0.0
		return

	current_attack_type = AttackType.NONE
	set_motion_state(MotionState.HIT)

func start_defeated() -> void:
	current_attack_type = AttackType.NONE
	set_motion_state(MotionState.DEFEATED)

func set_motion_state(next_state: int) -> void:
	if motion_state == MotionState.DEFEATED and next_state != MotionState.DEFEATED:
		return
	if motion_state == next_state:
		return

	motion_state = next_state
	state_time = 0.0
	_enter_state(next_state)

func get_motion_state() -> int:
	return motion_state

func get_core_global_position() -> Vector2:
	return core_pivot.global_position

func _enter_state(next_state: int) -> void:
	if next_state != MotionState.HIT:
		_reset_whole_body_pose()
	match next_state:
		MotionState.IDLE:
			current_attack_type = AttackType.NONE
		MotionState.ATTACK_WINDUP:
			pass
		MotionState.ATTACK_STRIKE:
			# Later: enable the active attack hitbox and trigger camera shake/SFX here.
			attack_strike_started.emit(current_attack_type)
		MotionState.ATTACK_RECOVER:
			# Later: disable active attack hitboxes here.
			attack_strike_finished.emit(current_attack_type)
		MotionState.STUN:
			# Later: disable all active attack hitboxes here.
			pass
		MotionState.HIT:
			pass
		MotionState.DEFEATED:
			# Later: disable collision, spawn explosion particles, drop rewards, and notify the stage manager.
			pass

func _process_idle(_delta: float) -> void:
	_apply_idle_pose(_get_idle_weight())

func _process_attack_windup(_delta: float) -> void:
	var duration := _get_windup_duration(current_attack_type)
	var release_start_time := _get_attack_release_start_time(current_attack_type)
	var t := _ease_in_out(state_time / duration)

	_apply_idle_pose(_get_idle_weight())
	match current_attack_type:
		AttackType.RIGHT_ARM_SLAM:
			_apply_right_arm_slam_windup(t)
		AttackType.BOTH_ARM_SLAM:
			_apply_both_arm_slam_windup(t)
		AttackType.CORE_CHARGE:
			_apply_core_charge_windup(t)

	if state_time >= release_start_time:
		set_motion_state(MotionState.ATTACK_STRIKE)

func _process_attack_strike(_delta: float) -> void:
	var duration := _get_strike_duration(current_attack_type)
	var t := _ease_out(state_time / duration)

	_apply_idle_pose(_get_idle_weight())
	match current_attack_type:
		AttackType.RIGHT_ARM_SLAM:
			_apply_right_arm_slam_strike(t)
		AttackType.BOTH_ARM_SLAM:
			_apply_both_arm_slam_strike(t)
		AttackType.CORE_CHARGE:
			_apply_core_charge_strike(t)

	if state_time >= duration:
		set_motion_state(MotionState.ATTACK_RECOVER)

func _process_attack_recover(_delta: float) -> void:
	var duration := _get_recover_duration(current_attack_type)
	var t := _ease_in_out(state_time / duration)

	_apply_idle_pose(_get_idle_weight())
	match current_attack_type:
		AttackType.RIGHT_ARM_SLAM:
			_apply_right_arm_slam_recover(t)
		AttackType.BOTH_ARM_SLAM:
			_apply_both_arm_slam_recover(t)
		AttackType.CORE_CHARGE:
			_apply_core_charge_recover(t)

	if state_time >= duration:
		set_motion_state(MotionState.IDLE)

func _process_stun(_delta: float) -> void:
	_apply_idle_pose(_get_idle_weight())

	var shake_x := sin(state_time * 42.0) * 4.0
	var shake_y := sin(state_time * 35.0) * 3.0
	_add_pivot_pose(body_pivot, Vector2(shake_x, shake_y), sin(state_time * 30.0) * 2.0)
	_add_pivot_pose(head_pivot, Vector2(0.0, 8.0), sin(state_time * 40.0) * 7.0)
	_add_pivot_pose(left_arm_pivot, Vector2(0.0, 16.0), 18.0)
	_add_pivot_pose(right_arm_pivot, Vector2(0.0, 16.0), -18.0)
	_add_pivot_pose(cloth_left_pivot, Vector2(sin(state_time * 18.0) * 6.0, 8.0), sin(state_time * 28.0) * 11.0)
	_add_pivot_pose(cloth_right_pivot, Vector2(sin(state_time * 16.0 + 1.0) * 6.0, 8.0), sin(state_time * 26.0 + 1.7) * -11.0)

	var core_scale: float = 0.85 + absf(sin(state_time * 20.0)) * 0.25
	core_pivot.scale *= Vector2(core_scale, core_scale)
	core_sprite.modulate = Color(1.0, 0.78, 0.78, 0.45 + absf(sin(state_time * 20.0)) * 0.55)

	if state_time >= stun_seconds:
		set_motion_state(MotionState.IDLE)

func _process_hit(_delta: float) -> void:
	_apply_idle_pose(_get_idle_weight())

	var fade := 1.0 - clampf(state_time / maxf(hit_seconds, 0.1), 0.0, 1.0)
	var shake_x := (sin(state_time * 86.0) + sin(state_time * 141.0) * 0.45) * hit_shake_amount * fade
	var shake_y := (cos(state_time * 93.0) + sin(state_time * 119.0) * 0.35) * hit_shake_amount * 0.65 * fade
	position = _base_self_position + Vector2(shake_x, shake_y)
	rotation_degrees = _base_self_rotation + sin(state_time * 126.0) * hit_rotation_amount * fade
	core_sprite.modulate = Color(1.0, 0.45 + 0.35 * fade, 0.45 + 0.28 * fade, 1.0)

	if state_time >= hit_seconds:
		_reset_whole_body_pose()
		set_motion_state(MotionState.IDLE)

func _process_defeated(_delta: float) -> void:
	var duration := maxf(defeated_seconds, 0.1)
	var t := clampf(state_time / duration, 0.0, 1.0)
	var eased := _ease_in_out(t)

	_apply_idle_pose(_get_idle_weight())
	_add_pivot_pose(body_pivot, Vector2(0.0, eased * 45.0), eased * 8.0)
	_add_pivot_pose(head_pivot, Vector2(-eased * 35.0, eased * 60.0), -eased * 35.0)
	_add_pivot_pose(left_arm_pivot, Vector2(-eased * 70.0, eased * 80.0), eased * 55.0)
	_add_pivot_pose(right_arm_pivot, Vector2(eased * 70.0, eased * 80.0), -eased * 55.0)
	_add_pivot_pose(cloth_left_pivot, Vector2(-eased * 15.0, eased * 70.0), sin(eased * TAU) * 10.0 + eased * 18.0)
	_add_pivot_pose(cloth_right_pivot, Vector2(eased * 15.0, eased * 70.0), sin(eased * TAU + 0.8) * -10.0 - eased * 18.0)

	var core_scale := lerpf(1.0, 0.1, eased)
	core_pivot.scale *= Vector2(core_scale, core_scale)
	core_sprite.modulate = Color(1.0, 0.55, 0.55, lerpf(1.0, 0.0, eased))

func _get_windup_duration(attack_type: int) -> float:
	match attack_type:
		AttackType.RIGHT_ARM_SLAM:
			return 0.55
		AttackType.BOTH_ARM_SLAM:
			return 0.58
		AttackType.CORE_CHARGE:
			return 0.75
		_:
			return 0.5

func _get_strike_duration(attack_type: int) -> float:
	var finish_duration := _get_attack_finish_duration(attack_type)
	var base_strike := _get_base_strike_duration(attack_type)
	var base_recover := _get_base_recover_duration(attack_type)
	var base_total := maxf(base_strike + base_recover, 0.01)
	return maxf(finish_duration * base_strike / base_total, 0.05)

func _get_recover_duration(attack_type: int) -> float:
	var finish_duration := _get_attack_finish_duration(attack_type)
	return maxf(finish_duration - _get_strike_duration(attack_type), 0.05)

func _get_attack_release_start_time(attack_type: int) -> float:
	return maxf(_get_windup_duration(attack_type), current_attack_window_seconds - _get_attack_finish_duration(attack_type))

func _get_attack_finish_duration(attack_type: int) -> float:
	var windup_duration := _get_windup_duration(attack_type)
	var available_after_windup := maxf(current_attack_window_seconds - windup_duration, 0.1)
	return minf(GameBalance.BOSS_ATTACK_FINISH_LEAD_SECONDS, available_after_windup)

func _get_min_attack_window_seconds(attack_type: int) -> float:
	return _get_windup_duration(attack_type) + 0.1

func _get_base_strike_duration(attack_type: int) -> float:
	match attack_type:
		AttackType.RIGHT_ARM_SLAM:
			return 0.16
		AttackType.BOTH_ARM_SLAM:
			return 0.18
		AttackType.CORE_CHARGE:
			return 0.25
		_:
			return 0.2

func _get_base_recover_duration(attack_type: int) -> float:
	match attack_type:
		AttackType.RIGHT_ARM_SLAM:
			return 0.45
		AttackType.BOTH_ARM_SLAM:
			return 0.48
		AttackType.CORE_CHARGE:
			return 0.55
		_:
			return 0.45

func _apply_right_arm_slam_windup(t: float) -> void:
	_add_pivot_pose(body_pivot, Vector2(12.0 * t, -12.0 * t), 3.0 * t)
	_add_pivot_pose(head_pivot, Vector2(0.0, -8.0 * t), -5.0 * t)
	_add_pivot_pose(right_arm_pivot, Vector2(18.0 * t, -48.0 * t), 70.0 * t)
	_add_pivot_pose(left_arm_pivot, Vector2.ZERO, 10.0 * t)
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.0, 1.18, t))
	_apply_cloth_follow(t, 4.0, -3.0)
	_set_core_energy(0.45 * t, 1.0)

func _apply_right_arm_slam_strike(t: float) -> void:
	_add_pivot_pose(body_pivot, Vector2(12.0, -12.0).lerp(Vector2(-22.0, 20.0), t), lerpf(3.0, -5.0, t))
	_add_pivot_pose(head_pivot, Vector2(0.0, -8.0).lerp(Vector2(0.0, 5.0), t), lerpf(-5.0, 4.0, t))
	_add_pivot_pose(right_arm_pivot, Vector2(18.0, -48.0).lerp(Vector2(-22.0, 74.0), t), lerpf(70.0, -72.0, t))
	_add_pivot_pose(left_arm_pivot, Vector2.ZERO, lerpf(10.0, -6.0, t))
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.18, 1.05, t))
	_apply_cloth_follow(t, -8.0, 8.0)
	_set_core_energy(0.25, 1.0)

func _apply_right_arm_slam_recover(t: float) -> void:
	var bounce := sin(t * PI) * 0.18
	_add_pivot_pose(body_pivot, Vector2(-22.0, 20.0).lerp(Vector2.ZERO, t), lerpf(-5.0, 0.0, t) + bounce * 2.0)
	_add_pivot_pose(head_pivot, Vector2(0.0, 5.0).lerp(Vector2.ZERO, t), lerpf(4.0, 0.0, t))
	_add_pivot_pose(right_arm_pivot, Vector2(-22.0, 74.0).lerp(Vector2.ZERO, t), lerpf(-72.0, 0.0, t) - bounce * 8.0)
	_add_pivot_pose(left_arm_pivot, Vector2.ZERO, lerpf(-6.0, 0.0, t))
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.05, 1.0, t))
	_apply_cloth_follow(1.0 - t, -5.0, 5.0)
	_set_core_energy(0.2 * (1.0 - t), 1.0)

func _apply_both_arm_slam_windup(t: float) -> void:
	_add_pivot_pose(body_pivot, Vector2(0.0, -16.0 * t), 0.0, Vector2(1.0, lerpf(1.0, 1.03, t)))
	_add_pivot_pose(head_pivot, Vector2(0.0, -9.0 * t), 0.0)
	_add_pivot_pose(left_arm_pivot, Vector2(18.0 * t, -48.0 * t), 70.0 * t)
	_add_pivot_pose(right_arm_pivot, Vector2(18.0 * t, -48.0 * t), 70.0 * t)
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.0, 1.22, t))
	_apply_cloth_follow(t, 5.0, -5.0)
	_set_core_energy(0.55 * t, 1.0)

func _apply_both_arm_slam_strike(t: float) -> void:
	_add_pivot_pose(body_pivot, Vector2(0.0, -16.0).lerp(Vector2(0.0, 30.0), t), 0.0, Vector2(1.0, lerpf(1.03, 0.96, t)))
	_add_pivot_pose(head_pivot, Vector2(0.0, -9.0).lerp(Vector2(0.0, 8.0), t), 0.0)
	_add_pivot_pose(left_arm_pivot, Vector2(18.0, -48.0).lerp(Vector2(-22.0, 78.0), t), lerpf(70.0, -72.0, t))
	_add_pivot_pose(right_arm_pivot, Vector2(18.0, -48.0).lerp(Vector2(-22.0, 78.0), t), lerpf(70.0, -72.0, t))
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.22, 1.08, t))
	_add_pivot_pose(cloth_left_pivot, Vector2(8.0 * t, 8.0 * t), 12.0 * t)
	_add_pivot_pose(cloth_right_pivot, Vector2(-8.0 * t, 8.0 * t), -12.0 * t)
	_set_core_energy(0.35, 1.0)

func _apply_both_arm_slam_recover(t: float) -> void:
	var bounce := sin(t * PI) * 0.16
	_add_pivot_pose(body_pivot, Vector2(0.0, 30.0).lerp(Vector2.ZERO, t), 0.0, Vector2(1.0, lerpf(0.96, 1.0, t)))
	_add_pivot_pose(head_pivot, Vector2(0.0, 8.0).lerp(Vector2.ZERO, t), 0.0)
	_add_pivot_pose(left_arm_pivot, Vector2(-22.0, 78.0).lerp(Vector2.ZERO, t), lerpf(-72.0, 0.0, t))
	_add_pivot_pose(right_arm_pivot, Vector2(-22.0, 78.0).lerp(Vector2.ZERO, t), lerpf(-72.0, 0.0, t) - bounce * 8.0)
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.08, 1.0, t))
	_apply_cloth_follow(1.0 - t, -4.0, 4.0)
	_set_core_energy(0.22 * (1.0 - t), 1.0)

func _apply_core_charge_windup(t: float) -> void:
	_add_pivot_pose(body_pivot, Vector2(0.0, -10.0 * t), 0.0, Vector2(1.0, lerpf(1.0, 1.03, t)))
	_add_pivot_pose(head_pivot, Vector2(0.0, -5.0 * t), sin(state_time * 18.0) * 1.5 * t)
	_add_pivot_pose(left_arm_pivot, Vector2(-12.0 * t, 0.0), -14.0 * t)
	_add_pivot_pose(right_arm_pivot, Vector2(12.0 * t, 0.0), 14.0 * t)
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.0, 1.45, t))
	_apply_cloth_follow(t, 2.0, -2.0)
	_set_core_energy(t, 1.0)

func _apply_core_charge_strike(t: float) -> void:
	var release_scale := lerpf(1.65, 1.15, t)
	_add_pivot_pose(body_pivot, Vector2(0.0, lerpf(-10.0, 10.0, t)), 0.0, Vector2(1.0, lerpf(1.03, 0.98, t)))
	_add_pivot_pose(head_pivot, Vector2(sin(state_time * 55.0) * 2.0, 0.0), sin(state_time * 48.0) * 2.0)
	_add_pivot_pose(left_arm_pivot, Vector2(lerpf(-12.0, -4.0, t), 0.0), lerpf(-14.0, -5.0, t))
	_add_pivot_pose(right_arm_pivot, Vector2(lerpf(12.0, 4.0, t), 0.0), lerpf(14.0, 5.0, t))
	_add_pivot_pose(core_pivot, Vector2.ZERO, sin(state_time * 34.0) * 1.2, Vector2.ONE * release_scale)
	_apply_cloth_follow(1.0, -7.0 * (1.0 - t), 7.0 * (1.0 - t))
	_set_core_energy(1.0 - t * 0.25, 1.0)

func _apply_core_charge_recover(t: float) -> void:
	_add_pivot_pose(body_pivot, Vector2(0.0, 10.0).lerp(Vector2.ZERO, t), 0.0, Vector2(1.0, lerpf(0.98, 1.0, t)))
	_add_pivot_pose(head_pivot, Vector2(0.0, 2.0).lerp(Vector2.ZERO, t), sin((1.0 - t) * PI) * 1.0)
	_add_pivot_pose(left_arm_pivot, Vector2(-4.0, 0.0).lerp(Vector2.ZERO, t), lerpf(-5.0, 0.0, t))
	_add_pivot_pose(right_arm_pivot, Vector2(4.0, 0.0).lerp(Vector2.ZERO, t), lerpf(5.0, 0.0, t))
	_add_pivot_pose(core_pivot, Vector2.ZERO, 0.0, Vector2.ONE * lerpf(1.15, 1.0, t))
	_apply_cloth_follow(1.0 - t, -3.0, 3.0)
	_set_core_energy(0.5 * (1.0 - t), 1.0)

func _apply_cloth_follow(weight: float, left_rotation: float, right_rotation: float) -> void:
	var clamped := clampf(weight, 0.0, 1.0)
	_add_pivot_pose(cloth_left_pivot, Vector2(sin(state_time * 8.0) * 2.0 * clamped, 2.0 * clamped), left_rotation * clamped)
	_add_pivot_pose(cloth_right_pivot, Vector2(sin(state_time * 7.0 + 0.7) * 2.0 * clamped, 2.0 * clamped), right_rotation * clamped)

func _apply_idle_pose(weight: float = 1.0) -> void:
	var idle_weight := clampf(weight, 0.0, 1.0)
	var cycle := maxf(breath_cycle_seconds, 0.1)
	var phase := _time * TAU / cycle
	var breath := sin(phase)
	var delayed_breath := sin(phase - 0.38)
	var arm_breath := sin(phase - 0.16)
	var cloth_breath := sin(phase - 0.72)
	var inhale := (breath + 1.0) * 0.5
	var body_y := breath * body_bob_amount * idle_weight
	var body_scale := Vector2(
		1.0 - breath * body_breath_scale_amount * 0.45 * idle_weight,
		1.0 + breath * body_breath_scale_amount * idle_weight
	)

	_set_pivot_pose(body_pivot, Vector2(0.0, -body_y), delayed_breath * 0.75 * idle_weight, body_scale)
	_set_pivot_pose(
		head_pivot,
		Vector2(
			cos(phase * 0.5 + 0.8) * 2.2 * idle_weight,
			-body_y * 0.32 - delayed_breath * head_bob_amount * idle_weight
		),
		(delayed_breath * head_tilt_amount + sin(phase * 0.5 + 1.1) * 0.7) * idle_weight
	)

	var left_arm_settle := sin(phase * 1.7 + 2.35) * 1.25
	var right_arm_settle := sin(phase * 1.55 + 0.95) * 1.05
	_set_pivot_pose(
		left_arm_pivot,
		Vector2(
			(-arm_breath * 2.6 + cos(phase * 0.65 + 1.7) * 1.2) * idle_weight,
			-body_y * 0.46 - arm_breath * 3.2 * idle_weight
		),
		(-arm_breath * arm_sway_amount + left_arm_settle) * idle_weight
	)
	_set_pivot_pose(
		right_arm_pivot,
		Vector2(
			(arm_breath * 2.1 + cos(phase * 0.58 + 3.1) * 1.0) * idle_weight,
			-body_y * 0.38 - arm_breath * 2.4 * idle_weight
		),
		(arm_breath * arm_sway_amount * 0.85 + right_arm_settle) * idle_weight
	)

	var core_scale := 1.0 + inhale * core_pulse_amount * idle_weight
	_set_pivot_pose(
		core_pivot,
		Vector2(0.0, -body_y * 0.58),
		sin(phase * 0.72 + 2.0) * 0.5 * idle_weight,
		Vector2(core_scale, core_scale)
	)
	core_sprite.modulate = Color(
		_base_core_modulate.r,
		lerpf(_base_core_modulate.g, 0.76 + inhale * 0.24, idle_weight),
		lerpf(_base_core_modulate.b, 0.72 + inhale * 0.26, idle_weight),
		lerpf(_base_core_modulate.a, 0.78 + inhale * 0.22, idle_weight)
	)

	var cloth_left_wave := cloth_breath + sin(phase * 1.4 + 0.35) * 0.28
	var cloth_right_wave := sin(phase - 0.92) + sin(phase * 1.25 + 2.05) * 0.24
	_set_pivot_pose(
		cloth_left_pivot,
		Vector2(
			cloth_left_wave * 3.2 * idle_weight,
			-body_y * 0.30 + cos(phase * 0.82 + 1.0) * 1.5 * idle_weight
		),
		cloth_left_wave * cloth_sway_amount * idle_weight
	)
	_set_pivot_pose(
		cloth_right_pivot,
		Vector2(
			cloth_right_wave * 2.8 * idle_weight,
			-body_y * 0.28 + cos(phase * 0.76 + 2.7) * 1.4 * idle_weight
		),
		cloth_right_wave * cloth_sway_amount * -0.88 * idle_weight
	)

func _get_idle_weight() -> float:
	if not idle_enabled:
		return 0.0

	match motion_state:
		MotionState.IDLE:
			return 1.0
		MotionState.ATTACK_WINDUP:
			return 0.35
		MotionState.ATTACK_STRIKE:
			return 0.05
		MotionState.ATTACK_RECOVER:
			return 0.25
		MotionState.STUN:
			return 0.15
		MotionState.HIT:
			return 0.1
		MotionState.DEFEATED:
			return 0.0
		_:
			return 0.0

func _cache_base_pose() -> void:
	for pivot in _get_motion_pivots():
		var key := String(pivot.name)
		_base_positions[key] = pivot.position
		_base_rotations[key] = pivot.rotation_degrees
		_base_scales[key] = pivot.scale
	_base_core_modulate = core_sprite.modulate

func _reset_whole_body_pose() -> void:
	position = _base_self_position
	rotation_degrees = _base_self_rotation

func _fit_scale_to_viewport() -> void:
	if not auto_viewport_scale_enabled:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(
			float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
			float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
		)

	var bounds := _get_unscaled_visual_bounds()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return

	var target_width := viewport_size.x * target_viewport_width_ratio
	var target_height := viewport_size.y * target_viewport_height_ratio
	var fitted_scale: float = minf(target_width / bounds.size.x, target_height / bounds.size.y)
	fitted_scale = clampf(fitted_scale, minimum_auto_scale, maximum_auto_scale)
	scale = Vector2(fitted_scale, fitted_scale)

func _get_unscaled_visual_bounds() -> Rect2:
	var sprites: Array[Sprite2D] = []
	_collect_visual_sprites(self, sprites)

	var has_bounds := false
	var bounds := Rect2()
	var to_boss_local := global_transform.affine_inverse()

	for sprite in sprites:
		if not sprite.visible or sprite.texture == null:
			continue

		var sprite_to_boss := to_boss_local * sprite.global_transform
		var sprite_bounds := _transform_rect(sprite_to_boss, sprite.get_rect())
		if not has_bounds:
			bounds = sprite_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(sprite_bounds)

	return bounds

func _collect_visual_sprites(node: Node, sprites: Array[Sprite2D]) -> void:
	for child in node.get_children():
		if child is Sprite2D:
			sprites.append(child)
		_collect_visual_sprites(child, sprites)

func _transform_rect(transform: Transform2D, rect: Rect2) -> Rect2:
	var points := [
		transform * rect.position,
		transform * Vector2(rect.position.x + rect.size.x, rect.position.y),
		transform * Vector2(rect.position.x, rect.position.y + rect.size.y),
		transform * (rect.position + rect.size)
	]
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]

	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)

	return Rect2(min_point, max_point - min_point)

func _set_pivot_pose(pivot: Node2D, offset: Vector2, rotation_offset_degrees: float, scale_multiplier: Vector2 = Vector2.ONE) -> void:
	var key := String(pivot.name)
	var base_position: Vector2 = _base_positions[key]
	var base_rotation: float = _base_rotations[key]
	var base_scale: Vector2 = _base_scales[key]
	pivot.position = base_position + offset
	pivot.rotation_degrees = base_rotation + rotation_offset_degrees
	pivot.scale = base_scale * scale_multiplier

func _add_pivot_pose(pivot: Node2D, offset: Vector2, rotation_offset_degrees: float, scale_multiplier: Vector2 = Vector2.ONE) -> void:
	pivot.position += offset
	pivot.rotation_degrees += rotation_offset_degrees
	pivot.scale *= scale_multiplier

func _set_core_energy(intensity: float, alpha: float) -> void:
	var amount := clampf(intensity, 0.0, 1.0)
	core_sprite.modulate = Color(
		1.0,
		lerpf(core_sprite.modulate.g, 0.45, amount),
		lerpf(core_sprite.modulate.b, 0.45, amount),
		clampf(alpha, 0.0, 1.0)
	)

func _ease_in_out(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _ease_out(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)

func _ease_in(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t

func _get_motion_pivots() -> Array[Node2D]:
	return [
		body_pivot,
		head_pivot,
		left_arm_pivot,
		right_arm_pivot,
		core_pivot,
		cloth_left_pivot,
		cloth_right_pivot
	]
