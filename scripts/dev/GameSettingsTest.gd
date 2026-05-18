extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings = root.get_node_or_null("GameSettings")
	var haptic_manager = root.get_node_or_null("HapticManager")
	if settings == null:
		_fail("GameSettings autoload should exist.")
		return
	if haptic_manager == null:
		_fail("HapticManager autoload should exist.")
		return

	settings.reset_to_defaults()

	settings.set_volume_percent(40)
	if settings.volume_percent != 40:
		_fail("GameSettings should store volume as a 0-100 value.")
		return
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		_fail("Master audio bus should exist.")
		return
	if AudioServer.is_bus_mute(master_bus):
		_fail("Master audio bus should not be muted above zero volume.")
		return
	if not is_equal_approx(AudioServer.get_bus_volume_db(master_bus), linear_to_db(0.4)):
		_fail("GameSettings should apply volume to the Master audio bus.")
		return

	settings.set_volume_percent(0)
	if not AudioServer.is_bus_mute(master_bus):
		_fail("Volume zero should mute the Master audio bus.")
		return

	settings.set_attack_vibration_enabled(false)
	if haptic_manager.attack_vibration_enabled:
		_fail("Attack vibration setting should apply to HapticManager.")
		return

	settings.set_player_hurt_vibration_enabled(false)
	if haptic_manager.player_hurt_vibration_enabled:
		_fail("Player hurt vibration setting should apply to HapticManager.")
		return

	settings.reset_to_defaults()
	if settings.volume_percent != 100 or not settings.attack_vibration_enabled or not settings.player_hurt_vibration_enabled:
		_fail("GameSettings defaults should be volume 100 and both vibrations on.")
		return

	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
