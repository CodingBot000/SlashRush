extends Node

const UI_BUTTON_CLICK_SOUND_PATH := "res://assets/audio/sfx/ui-button-click.ogg"
const SWORD_SLASH_SOUND_PATH := "res://assets/audio/sfx/sword-slash.mp3"
const RUNNER_FOOTSTEP_SOUND_PATH := "res://assets/audio/sfx/footstep_grass_000.ogg"
const START_GAME_SOUND_PATH := "res://assets/audio/sfx/start_game.ogg"
const PICKUP_ITEM_SOUND_PATH := "res://assets/audio/sfx/pickup_item.ogg"
const PLAYER_HURT_SOUND_PATH := "res://assets/audio/sfx/error_002.ogg"
const UI_CLICK_BOUND_META := "ui_click_sound_bound"

var ui_button_click_player: AudioStreamPlayer
var sword_slash_player: AudioStreamPlayer
var runner_footstep_player: AudioStreamPlayer
var start_game_player: AudioStreamPlayer
var pickup_item_player: AudioStreamPlayer
var player_hurt_player: AudioStreamPlayer
var _runner_footsteps_requested := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_button_click_player = _make_audio_player("UIButtonClickAudio", UI_BUTTON_CLICK_SOUND_PATH)
	sword_slash_player = _make_audio_player("SwordSlashAudio", SWORD_SLASH_SOUND_PATH)
	runner_footstep_player = _make_audio_player("RunnerFootstepAudio", RUNNER_FOOTSTEP_SOUND_PATH)
	start_game_player = _make_audio_player("StartGameAudio", START_GAME_SOUND_PATH)
	pickup_item_player = _make_audio_player("PickupItemAudio", PICKUP_ITEM_SOUND_PATH)
	player_hurt_player = _make_audio_player("PlayerHurtAudio", PLAYER_HURT_SOUND_PATH)
	runner_footstep_player.finished.connect(_on_runner_footstep_finished)

func _process(_delta: float) -> void:
	if _runner_footsteps_requested and not get_tree().paused:
		_ensure_runner_footsteps_playing()
	elif runner_footstep_player != null and runner_footstep_player.playing:
		runner_footstep_player.stop()

func bind_ui_button(button: BaseButton) -> void:
	if button == null:
		return
	if button.has_meta(UI_CLICK_BOUND_META):
		return
	button.set_meta(UI_CLICK_BOUND_META, true)
	button.pressed.connect(play_ui_button_click)

func play_ui_button_click() -> void:
	_play(ui_button_click_player)

func play_sword_slash() -> void:
	_play(sword_slash_player)

func play_start_game() -> void:
	_play(start_game_player)

func play_pickup_item() -> void:
	_play(pickup_item_player)

func play_player_hurt() -> void:
	_play(player_hurt_player)

func set_runner_footsteps_active(active: bool) -> void:
	_runner_footsteps_requested = active
	if active:
		_ensure_runner_footsteps_playing()
	elif runner_footstep_player != null:
		runner_footstep_player.stop()

func _make_audio_player(player_name: String, stream_path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = _load_audio_stream(stream_path)
	if player.stream == null:
		push_warning("Failed to load audio stream: %s." % stream_path)
	add_child(player)
	return player

func _play(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()

func _ensure_runner_footsteps_playing() -> void:
	if get_tree().paused:
		return
	if runner_footstep_player == null or runner_footstep_player.stream == null:
		return
	if not runner_footstep_player.playing:
		runner_footstep_player.play()

func _on_runner_footstep_finished() -> void:
	if _runner_footsteps_requested:
		_ensure_runner_footsteps_playing()

func _load_audio_stream(resource_path: String) -> AudioStream:
	if ResourceLoader.exists(resource_path, "AudioStream"):
		var resource := load(resource_path)
		if resource is AudioStream:
			return resource
	var lower_path := resource_path.to_lower()
	if lower_path.ends_with(".mp3"):
		return AudioStreamMP3.load_from_file(resource_path)
	if lower_path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(resource_path)
	return null
