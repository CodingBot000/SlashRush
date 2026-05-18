extends RefCounted
class_name AudioHooks

const AUDIO_MANAGER_PATH := "/root/AudioManager"

static func bind_ui_button(owner: Node, button: BaseButton) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("bind_ui_button"):
		audio_manager.bind_ui_button(button)

static func play_ui_button_click(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_ui_button_click"):
		audio_manager.play_ui_button_click()

static func play_sword_slash(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_sword_slash"):
		audio_manager.play_sword_slash()

static func play_start_game(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_start_game"):
		audio_manager.play_start_game()

static func play_pickup_item(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_pickup_item"):
		audio_manager.play_pickup_item()

static func play_player_hurt(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_player_hurt"):
		audio_manager.play_player_hurt()

static func play_lobby_music(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_lobby_music"):
		audio_manager.play_lobby_music()

static func play_running_music(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_running_music"):
		audio_manager.play_running_music()

static func play_boss_music(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("play_boss_music"):
		audio_manager.play_boss_music()

static func stop_music(owner: Node) -> void:
	var audio_manager := _get_audio_manager(owner)
	if audio_manager != null and audio_manager.has_method("stop_music"):
		audio_manager.stop_music()

static func _get_audio_manager(owner: Node) -> Node:
	if owner == null:
		return null
	return owner.get_node_or_null(AUDIO_MANAGER_PATH)
