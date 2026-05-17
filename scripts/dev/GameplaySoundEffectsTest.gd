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

	await _assert_intro_start_sound(audio_manager)
	await _assert_runner_pickup_sound(audio_manager)
	await _assert_runner_hurt_sound(audio_manager)
	await _assert_boss_hurt_sound(audio_manager)

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

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
