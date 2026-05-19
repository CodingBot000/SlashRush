extends Node

const ResourceLoadUtil := preload("res://scripts/utils/ResourceLoadUtil.gd")
const UI_BUTTON_CLICK_SOUND_PATH := "res://assets/audio/sfx/ui-button-click.ogg"
const SWORD_SLASH_SOUND_PATH := "res://assets/audio/sfx/sword-slash.mp3"
const START_GAME_SOUND_PATH := "res://assets/audio/sfx/start_game.ogg"
const PICKUP_ITEM_SOUND_PATH := "res://assets/audio/sfx/pickup_item.ogg"
const PLAYER_HURT_SOUND_PATH := "res://assets/audio/sfx/error_002.ogg"
const LOBBY_MUSIC_PATH := "res://assets/audio/music/lobby.wav"
const RUNNING_MUSIC_PATH := "res://assets/audio/music/runningplay.mp3"
const BOSS_MUSIC_PATH := "res://assets/audio/music/boss.mp3"
const UI_CLICK_BOUND_META := "ui_click_sound_bound"

var ui_button_click_player: AudioStreamPlayer
var sword_slash_player: AudioStreamPlayer
var start_game_player: AudioStreamPlayer
var pickup_item_player: AudioStreamPlayer
var player_hurt_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var current_music_path := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_button_click_player = _make_audio_player("UIButtonClickAudio", UI_BUTTON_CLICK_SOUND_PATH)
	sword_slash_player = _make_audio_player("SwordSlashAudio", SWORD_SLASH_SOUND_PATH)
	start_game_player = _make_audio_player("StartGameAudio", START_GAME_SOUND_PATH)
	pickup_item_player = _make_audio_player("PickupItemAudio", PICKUP_ITEM_SOUND_PATH)
	player_hurt_player = _make_audio_player("PlayerHurtAudio", PLAYER_HURT_SOUND_PATH)
	music_player = _make_empty_audio_player("MusicAudio")

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

func play_lobby_music() -> void:
	_play_music(LOBBY_MUSIC_PATH)

func play_running_music() -> void:
	_play_music(RUNNING_MUSIC_PATH)

func play_boss_music() -> void:
	_play_music(BOSS_MUSIC_PATH)

func stop_music() -> void:
	current_music_path = ""
	if music_player != null and music_player.playing:
		music_player.stop()

func _make_audio_player(player_name: String, stream_path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = _load_audio_stream(stream_path)
	if player.stream == null:
		push_warning("Failed to load audio stream: %s." % stream_path)
	add_child(player)
	return player

func _make_empty_audio_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player

func _play(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()

func _play_music(stream_path: String) -> void:
	if music_player == null:
		return
	if current_music_path == stream_path and music_player.playing:
		return

	var stream := _load_audio_stream(stream_path)
	if stream == null:
		push_warning("Failed to load music stream: %s." % stream_path)
		return
	_set_stream_loop(stream, true)
	music_player.stop()
	music_player.stream = stream
	current_music_path = stream_path
	music_player.play()

func _set_stream_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamMP3:
		stream.loop = enabled
	elif stream is AudioStreamOggVorbis:
		stream.loop = enabled
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if enabled else AudioStreamWAV.LOOP_DISABLED
		if enabled:
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * float(stream.mix_rate))

func _load_audio_stream(resource_path: String) -> AudioStream:
	return ResourceLoadUtil.load_audio_stream(resource_path)
