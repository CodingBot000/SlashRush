extends RefCounted
class_name ObjectVisualEffectUtil

# 둥실둥실 스프링 부유 효과: base_y 기준의 sin 목표 위치를 현재 offset이 탄성/감쇠로 늦게 따라가게 계산한다.
static func calculate_floating_spring_y(
	delta: float,
	time: float,
	base_y: float,
	current_offset_y: float,
	velocity_y: float,
	amplitude: float = 10.0,
	speed: float = 1.2,
	spring_strength: float = 18.0,
	damping: float = 7.0
) -> Dictionary:
	var safe_delta: float = max(delta, 0.0)
	var target_offset_y: float = sin(time * speed) * amplitude
	var spring_force: float = (target_offset_y - current_offset_y) * spring_strength
	var damping_force: float = -velocity_y * damping
	var new_velocity_y: float = velocity_y + (spring_force + damping_force) * safe_delta
	var new_offset_y: float = current_offset_y + new_velocity_y * safe_delta

	return {
		"y": base_y + new_offset_y,
		"offset_y": new_offset_y,
		"velocity_y": new_velocity_y
	}

# Squash & Stretch Bounce 효과: 원본 position/scale 기준으로 통통 튀는 y 이동과 바닥 찌그러짐/튀어오름 늘어남을 적용한다.
static func apply_bounce_squash_stretch(
	target: Node2D,
	time: float,
	base_position: Vector2,
	base_scale: Vector2,
	bounce_height: float = 18.0,
	bounce_speed: float = 4.0,
	squash_x: float = 1.18,
	squash_y: float = 0.82,
	stretch_x: float = 0.9,
	stretch_y: float = 1.12,
	ground_lock: bool = true
) -> void:
	if target == null:
		return

	var cycle_time: float = time * bounce_speed
	var phase: float = sin(cycle_time)
	var bounce: float = abs(phase)
	var y_offset: float = -bounce * max(0.0, bounce_height)
	var ground_contact: float = 1.0 - bounce

	var squash_amount: float = pow(clamp(ground_contact, 0.0, 1.0), 4.0)
	var scale_x: float = lerp(1.0, squash_x, squash_amount)
	var scale_y: float = lerp(1.0, squash_y, squash_amount)

	var bounce_velocity_sign := 1.0 if phase >= 0.0 else -1.0
	var rising_amount: float = max(0.0, cos(cycle_time) * bounce_velocity_sign)
	var takeoff_stretch: float = smoothstep(0.05, 0.35, bounce) * (1.0 - smoothstep(0.35, 0.72, bounce)) * rising_amount * 0.2
	var apex_stretch: float = pow(bounce, 2.6) * 0.35
	var stretch_amount: float = clamp(max(takeoff_stretch, apex_stretch) * (1.0 - squash_amount), 0.0, 0.45)
	scale_x = lerp(scale_x, stretch_x, stretch_amount)
	scale_y = lerp(scale_y, stretch_y, stretch_amount)

	target.position = base_position + Vector2(0.0, y_offset)
	target.scale = Vector2(base_scale.x * scale_x, base_scale.y * scale_y)

	if ground_lock and target is Sprite2D:
		var sprite := target as Sprite2D
		if sprite.texture != null:
			var pivot_to_bottom_y: float = sprite.get_rect().end.y
			target.position.y += pivot_to_bottom_y * (base_scale.y - target.scale.y)

# 스프링 점프 Squash & Stretch 효과: 바닥 접촉 때 크게 눌리고, 도약 초반에는 좁고 길게 늘어난다.
static func apply_spring_jump_squash_stretch(
	target: Node2D,
	time: float,
	base_position: Vector2,
	base_scale: Vector2,
	jump_height: float = 42.0,
	jump_speed: float = 1.55,
	landing_squash_x: float = 1.38,
	landing_squash_y: float = 0.62,
	takeoff_stretch_x: float = 0.62,
	takeoff_stretch_y: float = 1.42,
	ground_contact_duration: float = 0.16,
	ground_lock: bool = true,
	jump_target: Node2D = null,
	jump_target_base_y: float = 0.0
) -> void:
	if target == null:
		return

	var contact_duration: float = clamp(ground_contact_duration, 0.08, 0.28)
	var ascent_duration := 0.24
	var apex_duration := 0.12
	var descent_duration: float = max(0.01, 1.0 - contact_duration - ascent_duration - apex_duration)
	var ascent_start := contact_duration
	var apex_start := ascent_start + ascent_duration
	var descent_start := apex_start + apex_duration
	var cycle_progress: float = fposmod(time * max(0.01, jump_speed), 1.0)
	var y_offset := 0.0
	var squash_amount := 0.0
	var stretch_amount := 0.0

	if cycle_progress < ascent_start:
		var contact_progress: float = cycle_progress / contact_duration
		y_offset = 0.0
		squash_amount = 1.0 - smoothstep(0.74, 1.0, contact_progress) * 0.22
	elif cycle_progress < apex_start:
		var ascent_progress: float = (cycle_progress - ascent_start) / ascent_duration
		var ascent_height: float = 1.0 - pow(1.0 - ascent_progress, 3.2)
		y_offset = -ascent_height * max(0.0, jump_height)
		stretch_amount = (1.0 - smoothstep(0.58, 1.0, ascent_progress)) * smoothstep(0.0, 0.12, ascent_progress)
	elif cycle_progress < descent_start:
		y_offset = -max(0.0, jump_height)
	else:
		var descent_progress: float = (cycle_progress - descent_start) / descent_duration
		var descent_height: float = 1.0 - pow(descent_progress, 2.45)
		y_offset = -max(0.0, jump_height) * max(0.0, descent_height)
		stretch_amount = smoothstep(0.08, 0.78, descent_progress)
		squash_amount = smoothstep(0.88, 1.0, descent_progress)

	stretch_amount *= 1.0 - squash_amount

	var scale_x: float = lerp(1.0, landing_squash_x, squash_amount)
	var scale_y: float = lerp(1.0, landing_squash_y, squash_amount)
	scale_x = lerp(scale_x, takeoff_stretch_x, stretch_amount)
	scale_y = lerp(scale_y, takeoff_stretch_y, stretch_amount)

	if jump_target != null:
		jump_target.position.y = jump_target_base_y + y_offset
		target.position = base_position
	else:
		target.position = base_position + Vector2(0.0, y_offset)
	target.scale = Vector2(base_scale.x * scale_x, base_scale.y * scale_y)

	if ground_lock and target is Sprite2D:
		var sprite := target as Sprite2D
		if sprite.texture != null:
			var pivot_to_bottom_y: float = sprite.get_rect().end.y
			target.position.y += pivot_to_bottom_y * (base_scale.y - target.scale.y)
