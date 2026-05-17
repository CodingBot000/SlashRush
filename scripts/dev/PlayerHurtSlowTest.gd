extends SceneTree

const RUNNER_STAGE_SCENE := preload("res://scenes/game/RunnerStage.tscn")
const INTERACTABLE_OBJECT_SCENE := preload("res://scenes/objects/InteractableObject.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage = RUNNER_STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame

	stage.active = true
	stage._start_hurt_slow()
	if not is_equal_approx(stage.hurt_slow_timer, GameBalance.PLAYER_HURT_SLOW_DURATION):
		_fail("Hurt slow timer should start at player hurt duration.")
		return
	if not stage.is_player_hurt_locked():
		_fail("Player should be action locked while hurt slow is active.")
		return
	if not is_equal_approx(stage._get_hurt_background_speed_multiplier(), 0.1):
		_fail("Background should move at 10% speed while hurt.")
		return
	if not is_equal_approx(stage._get_hurt_object_speed_multiplier(), 0.0):
		_fail("Objects should pause while hurt.")
		return
	if not _assert_hurt_background_scrolls_all_layers(stage):
		return

	var starting_hp: int = stage.hp
	var bomb = INTERACTABLE_OBJECT_SCENE.instantiate()
	bomb.setup("bomb")
	stage.object_root.add_child(bomb)
	stage._fail_object(bomb, false)
	if stage.hp != starting_hp:
		_fail("Additional damage should be ignored while player is hurt.")
		return

	var coin = INTERACTABLE_OBJECT_SCENE.instantiate()
	coin.setup("coin")
	stage.object_root.add_child(coin)
	stage._collect_good_item(coin, false)
	if stage.score != 0 or stage.coins != 0:
		_fail("Good item collection should be ignored while player is hurt.")
		return

	var object = INTERACTABLE_OBJECT_SCENE.instantiate()
	object.setup("enemy_basic")
	object.position = Vector2(1000.0, GameBalance.GAMEPLAY_BASELINE_Y)
	stage.object_root.add_child(object)

	var start_x: float = object.position.x
	stage._move_objects(0.1, stage._get_hurt_object_speed_multiplier())
	if not is_equal_approx(object.position.x, start_x):
		_fail("Object should pause while player is hurt.")
		return

	stage._update_hurt_slow(GameBalance.PLAYER_HURT_SLOW_DURATION)
	if stage.hurt_slow_timer > 0.0:
		_fail("Hurt slow timer should expire after 0.4 seconds.")
		return
	if stage.is_player_hurt_locked():
		_fail("Player action lock should expire with hurt slow timer.")
		return
	if not is_equal_approx(stage._get_hurt_background_speed_multiplier(), 1.0):
		_fail("Background speed should return to normal after hurt ends.")
		return
	if not is_equal_approx(stage._get_hurt_object_speed_multiplier(), 1.0):
		_fail("Object speed should return to normal after hurt ends.")
		return

	start_x = object.position.x
	stage._move_objects(0.1, stage._get_hurt_object_speed_multiplier())
	var expected_normal_x := start_x - GameBalance.OBJECT_SPEED * 0.1
	if not is_equal_approx(object.position.x, expected_normal_x):
		_fail("Object should move at normal speed after hurt ends.")
		return

	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _assert_hurt_background_scrolls_all_layers(stage) -> bool:
	var sky = stage.parallax.get_node_or_null("Sky")
	if sky == null or sky.has_meta("factor"):
		_fail("Sky should be static and should not have a scroll factor.")
		return false
	var cloud_layer = stage.parallax.get_node_or_null("CloudLayer")
	if cloud_layer == null or not cloud_layer.has_meta("factor"):
		_fail("Clouds should be a scrolling parallax layer.")
		return false

	var sky_start_x: float = sky.position.x
	var start_positions := {}
	for layer in stage.parallax.get_children():
		if not layer is Node2D or not layer.has_meta("factor") or layer.get_child_count() == 0:
			continue
		var item = layer.get_child(0)
		if item is Node2D:
			start_positions[layer.name] = item.position.x

	stage.parallax.process_scroll(0.1, GameBalance.MAP_SCROLL_SPEED * stage._get_hurt_background_speed_multiplier())

	if not is_equal_approx(sky.position.x, sky_start_x):
		_fail("Static sky should not move with hurt background scrolling.")
		return false

	for layer in stage.parallax.get_children():
		if not layer is Node2D or not layer.has_meta("factor") or layer.get_child_count() == 0:
			continue
		var item = layer.get_child(0)
		if not item is Node2D:
			continue
		var start_x: float = float(start_positions.get(layer.name, item.position.x))
		var expected_x := start_x - GameBalance.MAP_SCROLL_SPEED * 0.1 * float(layer.get_meta("factor")) * 0.1
		if not is_equal_approx(item.position.x, expected_x):
			_fail("%s should scroll at 10% speed with the hurt background multiplier." % layer.name)
			return false

	return true
