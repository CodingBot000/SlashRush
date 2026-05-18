extends Node

signal volume_changed(volume_percent)
signal attack_vibration_changed(enabled)
signal player_hurt_vibration_changed(enabled)

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "gameplay"
const DEFAULT_VOLUME_PERCENT := 100
const DEFAULT_ATTACK_VIBRATION_ENABLED := true
const DEFAULT_PLAYER_HURT_VIBRATION_ENABLED := true
const MIN_VOLUME_PERCENT := 0
const MAX_VOLUME_PERCENT := 100
const MUTED_VOLUME_DB := -80.0

var volume_percent := DEFAULT_VOLUME_PERCENT
var attack_vibration_enabled := DEFAULT_ATTACK_VIBRATION_ENABLED
var player_hurt_vibration_enabled := DEFAULT_PLAYER_HURT_VIBRATION_ENABLED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_apply_all()

func set_volume_percent(value: int) -> void:
	var clamped_value := clampi(value, MIN_VOLUME_PERCENT, MAX_VOLUME_PERCENT)
	if volume_percent == clamped_value:
		return
	volume_percent = clamped_value
	_apply_volume()
	_save_settings()
	volume_changed.emit(volume_percent)

func set_attack_vibration_enabled(enabled: bool) -> void:
	if attack_vibration_enabled == enabled:
		return
	attack_vibration_enabled = enabled
	_apply_attack_vibration()
	_save_settings()
	attack_vibration_changed.emit(attack_vibration_enabled)

func set_player_hurt_vibration_enabled(enabled: bool) -> void:
	if player_hurt_vibration_enabled == enabled:
		return
	player_hurt_vibration_enabled = enabled
	_apply_player_hurt_vibration()
	_save_settings()
	player_hurt_vibration_changed.emit(player_hurt_vibration_enabled)

func reset_to_defaults() -> void:
	volume_percent = DEFAULT_VOLUME_PERCENT
	attack_vibration_enabled = DEFAULT_ATTACK_VIBRATION_ENABLED
	player_hurt_vibration_enabled = DEFAULT_PLAYER_HURT_VIBRATION_ENABLED
	_apply_all()
	_save_settings()
	volume_changed.emit(volume_percent)
	attack_vibration_changed.emit(attack_vibration_enabled)
	player_hurt_vibration_changed.emit(player_hurt_vibration_enabled)

func _apply_all() -> void:
	_apply_volume()
	_apply_attack_vibration()
	_apply_player_hurt_vibration()

func _apply_volume() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	var ratio := float(volume_percent) / float(MAX_VOLUME_PERCENT)
	AudioServer.set_bus_mute(bus_index, volume_percent <= MIN_VOLUME_PERCENT)
	AudioServer.set_bus_volume_db(bus_index, MUTED_VOLUME_DB if volume_percent <= MIN_VOLUME_PERCENT else linear_to_db(ratio))

func _apply_attack_vibration() -> void:
	var haptic_manager := get_node_or_null("/root/HapticManager")
	if haptic_manager != null and haptic_manager.has_method("set_attack_vibration_enabled"):
		haptic_manager.set_attack_vibration_enabled(attack_vibration_enabled)

func _apply_player_hurt_vibration() -> void:
	var haptic_manager := get_node_or_null("/root/HapticManager")
	if haptic_manager != null and haptic_manager.has_method("set_player_hurt_vibration_enabled"):
		haptic_manager.set_player_hurt_vibration_enabled(player_hurt_vibration_enabled)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	volume_percent = clampi(int(config.get_value(SETTINGS_SECTION, "volume_percent", DEFAULT_VOLUME_PERCENT)), MIN_VOLUME_PERCENT, MAX_VOLUME_PERCENT)
	attack_vibration_enabled = bool(config.get_value(SETTINGS_SECTION, "attack_vibration_enabled", DEFAULT_ATTACK_VIBRATION_ENABLED))
	player_hurt_vibration_enabled = bool(config.get_value(SETTINGS_SECTION, "player_hurt_vibration_enabled", DEFAULT_PLAYER_HURT_VIBRATION_ENABLED))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, "volume_percent", volume_percent)
	config.set_value(SETTINGS_SECTION, "attack_vibration_enabled", attack_vibration_enabled)
	config.set_value(SETTINGS_SECTION, "player_hurt_vibration_enabled", player_hurt_vibration_enabled)
	config.save(SETTINGS_PATH)
