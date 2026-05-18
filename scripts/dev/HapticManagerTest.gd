extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var haptic_manager = root.get_node_or_null("HapticManager")
	if haptic_manager == null:
		_fail("HapticManager autoload should exist.")
		return

	haptic_manager.reset_debug_state()
	haptic_manager.vibrate_attack()
	if haptic_manager.last_vibration_event != "attack":
		_fail("Attack vibration should be recorded as a separate event.")
		return
	if haptic_manager.last_vibration_duration_ms != 35:
		_fail("Attack vibration should use the attack duration.")
		return

	haptic_manager.vibrate_player_hurt()
	if haptic_manager.last_vibration_event != "player_hurt":
		_fail("Player hurt vibration should be recorded as a separate event.")
		return
	if haptic_manager.last_vibration_duration_ms != 140:
		_fail("Player hurt vibration should use the hurt duration.")
		return
	if haptic_manager.last_vibration_amplitude <= haptic_manager.ATTACK_VIBRATION_AMPLITUDE:
		_fail("Player hurt vibration should be stronger than attack vibration.")
		return

	haptic_manager.reset_debug_state()
	haptic_manager.set_attack_vibration_enabled(false)
	haptic_manager.vibrate_attack()
	if haptic_manager.vibration_count != 0:
		_fail("Attack vibration toggle should block only attack vibration.")
		return

	haptic_manager.vibrate_player_hurt()
	if haptic_manager.vibration_count != 1 or haptic_manager.last_vibration_event != "player_hurt":
		_fail("Player hurt vibration should remain independent from attack vibration.")
		return

	haptic_manager.set_attack_vibration_enabled(true)
	haptic_manager.set_player_hurt_vibration_enabled(false)
	haptic_manager.reset_debug_state()
	haptic_manager.vibrate_player_hurt()
	if haptic_manager.vibration_count != 0:
		_fail("Player hurt vibration toggle should block player hurt vibration.")
		return

	haptic_manager.vibrate_attack()
	if haptic_manager.vibration_count != 1 or haptic_manager.last_vibration_event != "attack":
		_fail("Attack vibration should remain independent from player hurt vibration.")
		return

	haptic_manager.set_player_hurt_vibration_enabled(true)
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
