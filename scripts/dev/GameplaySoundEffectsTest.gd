extends SceneTree

const INTRO_SCENE := preload("res://scenes/game/IntroScene.tscn")
const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const BOSS_STAGE_SCENE := preload("res://scenes/game/BossStage.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio_manager = root.get_node_or_null("AudioManager")
	if audio_manager == null:
		_fail("AudioManager autoload should exist.")
		return

	await _assert_lobby_music(audio_manager)
	await _assert_intro_start_sound(audio_manager)
	await _assert_runner_pickup_sound(audio_manager)
	await _assert_runner_hurt_sound(audio_manager)
	await _assert_boss_hurt_sound(audio_manager)
	await _assert_running_music(audio_manager)
	await _assert_boss_music(audio_manager)

	quit()

func _assert_intro_start_sound(audio_manager) -> void:
	audio_manager.start_game_player.stop()
	var intro = INTRO_SCENE.instantiate()
	root.add_child(intro)
	await process_frame

	intro._open_main_menu()
	await process_frame
	if not audio_manager.start_game_player.playing:
		_fail("Intro start should play start_game.ogg.")
		return

	audio_manager.start_game_player.stop()

func _assert_lobby_music(audio_manager) -> void:
	audio_manager.stop_music()

	var intro = INTRO_SCENE.instantiate()
	root.add_child(intro)
	await process_frame
	if not _is_music_playing(audio_manager, audio_manager.LOBBY_MUSIC_PATH):
		_fail("Intro should play lobby music.")
		return
	intro.queue_free()
	await process_frame

	var main_menu_scene := load("res://scenes/game/MainMenu.tscn")
	var main_menu = main_menu_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	if not _is_music_playing(audio_manager, audio_manager.LOBBY_MUSIC_PATH):
		_fail("MainMenu should play lobby music.")
		return
	main_menu.queue_free()
	await process_frame

	var character_select_scene := load("res://scenes/ui/CharacterSelect.tscn")
	var character_select = character_select_scene.instantiate()
	root.add_child(character_select)
	await process_frame
	if not _is_music_playing(audio_manager, audio_manager.LOBBY_MUSIC_PATH):
		_fail("CharacterSelect should play lobby music.")
		return
	character_select.queue_free()
	await process_frame

	var how_to_scene := load("res://scenes/ui/HowToScreen.tscn")
	var how_to = how_to_scene.instantiate()
	root.add_child(how_to)
	await process_frame
	if not _is_music_playing(audio_manager, audio_manager.LOBBY_MUSIC_PATH):
		_fail("HowToScreen should play lobby music.")
		return
	how_to.queue_free()
	await process_frame

func _assert_runner_pickup_sound(audio_manager) -> void:
	audio_manager.pickup_item_player.stop()
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_run()
	stage.spawner.stop()
	var coin = INTERACTABLE_OBJECT_SCENE.instantiate()
	stage.object_root.add_child(coin)
	coin.setup("coin")
	coin.position = GameBalance.ACTION_ZONE_CENTER
	stage._collect_good_item(coin, false)
	await process_frame

	if not audio_manager.pickup_item_player.playing:
		_fail("Runner item pickup should play pickup_item.ogg.")
		return

	audio_manager.pickup_item_player.stop()
	stage.stop_run()
	stage.queue_free()
	await process_frame

func _assert_runner_hurt_sound(audio_manager) -> void:
	audio_manager.player_hurt_player.stop()
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_run()
	stage.spawner.stop()
	var bomb = INTERACTABLE_OBJECT_SCENE.instantiate()
	stage.object_root.add_child(bomb)
	bomb.setup("bomb")
	bomb.position = GameBalance.ACTION_ZONE_CENTER
	stage._fail_object(bomb, false)
	await process_frame

	if not audio_manager.player_hurt_player.playing:
		_fail("Runner player hurt should play error_002.ogg.")
		return

	audio_manager.player_hurt_player.stop()
	stage.stop_run()
	stage.queue_free()
	await process_frame

func _assert_boss_hurt_sound(audio_manager) -> void:
	audio_manager.player_hurt_player.stop()
	var stage = BOSS_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_boss(0, 0, GameBalance.MAX_HP)
	stage._fail_pattern("MISS")
	await process_frame

	if not audio_manager.player_hurt_player.playing:
		_fail("Boss player hurt should play error_002.ogg.")
		return

	audio_manager.player_hurt_player.stop()
	stage.stop_boss()
	stage.queue_free()
	await process_frame

func _assert_boss_music(audio_manager) -> void:
	audio_manager.stop_music()
	var stage = BOSS_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_boss(0, 0, GameBalance.MAX_HP)
	await process_frame
	if not _is_music_playing(audio_manager, audio_manager.BOSS_MUSIC_PATH):
		_fail("Boss music should play when BossStage starts.")
		return

	stage.stop_boss()
	await process_frame
	if audio_manager.music_player.playing:
		_fail("Boss music should stop when BossStage stops.")
		return

	stage.start_boss(0, 0, 1)
	await process_frame
	stage._fail_pattern("MISS")
	await process_frame
	if audio_manager.music_player.playing:
		_fail("Boss music should stop when the player dies during BossStage.")
		return

	stage.start_boss(0, 0, GameBalance.MAX_HP)
	stage.boss_hp = 1
	await process_frame
	stage._success_pattern()
	await process_frame
	if audio_manager.music_player.playing:
		_fail("Boss music should stop when BossStage is cleared.")
		return

	stage.queue_free()
	await process_frame

func _assert_running_music(audio_manager) -> void:
	audio_manager.stop_music()
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.start_run()
	stage.spawner.stop()
	await process_frame
	if not _is_music_playing(audio_manager, audio_manager.RUNNING_MUSIC_PATH):
		_fail("Running music should play when RunnerStage starts.")
		return

	stage.stop_run()
	await process_frame
	if audio_manager.music_player.playing:
		_fail("Running music should stop when RunnerStage stops.")
		return

	stage.queue_free()
	await process_frame

func _is_music_playing(audio_manager, expected_path: String) -> bool:
	return audio_manager.music_player.playing and audio_manager.current_music_path == expected_path

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
