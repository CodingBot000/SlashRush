extends Node

const ATTACK_VIBRATION_DURATION_MS := 35
const ATTACK_VIBRATION_AMPLITUDE := 0.35
const PLAYER_HURT_VIBRATION_DURATION_MS := 140
const PLAYER_HURT_VIBRATION_AMPLITUDE := 0.9

var attack_vibration_enabled := true
var player_hurt_vibration_enabled := true
var last_vibration_event := ""
var last_vibration_duration_ms := 0
var last_vibration_amplitude := 0.0
var vibration_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_from_game_settings()

func vibrate_attack() -> void:
	if not attack_vibration_enabled:
		return
	_vibrate("attack", ATTACK_VIBRATION_DURATION_MS, ATTACK_VIBRATION_AMPLITUDE)

func vibrate_player_hurt() -> void:
	if not player_hurt_vibration_enabled:
		return
	_vibrate("player_hurt", PLAYER_HURT_VIBRATION_DURATION_MS, PLAYER_HURT_VIBRATION_AMPLITUDE)

func set_attack_vibration_enabled(enabled: bool) -> void:
	attack_vibration_enabled = enabled

func set_player_hurt_vibration_enabled(enabled: bool) -> void:
	player_hurt_vibration_enabled = enabled

func reset_debug_state() -> void:
	last_vibration_event = ""
	last_vibration_duration_ms = 0
	last_vibration_amplitude = 0.0
	vibration_count = 0

func _vibrate(event_name: String, duration_ms: int, amplitude: float) -> void:
	last_vibration_event = event_name
	last_vibration_duration_ms = duration_ms
	last_vibration_amplitude = amplitude
	vibration_count += 1
	Input.vibrate_handheld(duration_ms, amplitude)

func _sync_from_game_settings() -> void:
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings == null:
		return
	attack_vibration_enabled = bool(game_settings.attack_vibration_enabled)
	player_hurt_vibration_enabled = bool(game_settings.player_hurt_vibration_enabled)
