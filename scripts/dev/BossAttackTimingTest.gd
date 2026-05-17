extends SceneTree

const BOSS_SCENE := preload("res://scenes/boss/RobotSamuraiBoss.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var boss = BOSS_SCENE.instantiate()
	root.add_child(boss)
	await process_frame
	boss.set_process(false)

	boss.start_right_arm_slam(GameBalance.BOSS_DOUBLE_TAP_ATTACK_WINDOW_SECONDS)
	_process_boss_for(boss, GameBalance.BOSS_DOUBLE_TAP_ATTACK_WINDOW_SECONDS - GameBalance.BOSS_ATTACK_FINISH_LEAD_SECONDS - 0.05)
	_assert_state(boss, RobotSamuraiBoss.MotionState.ATTACK_WINDUP, "Boss attack should keep holding the windup pose until the final lead time.")

	_process_boss_for(boss, 0.08)
	if boss.get_motion_state() == RobotSamuraiBoss.MotionState.ATTACK_WINDUP:
		_fail("Boss attack should enter the finishing motion during the final lead time.")

	boss.start_both_arm_slam(GameBalance.BOSS_DOUBLE_TAP_ATTACK_WINDOW_SECONDS)
	_process_boss_for(boss, 0.8)
	boss.start_hit()
	_assert_state(boss, RobotSamuraiBoss.MotionState.HIT, "Player success should interrupt the boss attack into hit state.")

	boss.free()
	quit()

func _process_boss_for(boss, seconds: float) -> void:
	var remaining := maxf(seconds, 0.0)
	while remaining > 0.0:
		var delta := minf(remaining, 1.0 / 60.0)
		boss._process(delta)
		remaining -= delta

func _assert_state(boss, expected_state: int, message: String) -> void:
	if boss.get_motion_state() != expected_state:
		_fail(message)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
