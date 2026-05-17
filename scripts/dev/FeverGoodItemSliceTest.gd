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

	stage.start_run()
	stage.spawner.stop()
	await process_frame

	await _assert_fever_coin_slice_collects(stage)
	await _assert_fever_heal_slice_heals(stage)
	await _assert_fever_full_heal_slice_gives_coin(stage)
	await _assert_fever_orb_slice_gives_coin(stage)
	await _assert_non_fever_good_item_slice_keeps_penalty(stage)

	stage.free()
	quit()

func _assert_fever_coin_slice_collects(stage) -> void:
	_prepare_stage_for_fever_slice(stage, 5)
	stage.coins = 0
	stage.score = 0
	_add_zone_object(stage, "coin")
	stage.handle_player_action("tap")
	await process_frame

	if stage.coins != 20:
		_fail("Fever coin slice should collect coin value.")
	if stage.score != 40:
		_fail("Fever coin slice should keep fever score multiplier.")
	if stage.combo != 5:
		_fail("Fever coin slice should not reset combo.")

func _assert_fever_heal_slice_heals(stage) -> void:
	_prepare_stage_for_fever_slice(stage, 6)
	stage.hp = GameBalance.MAX_HP - 1
	stage.coins = 0
	stage.score = 0
	_add_zone_object(stage, "heal")
	stage.handle_player_action("tap")
	await process_frame

	if stage.hp != GameBalance.MAX_HP:
		_fail("Fever heal slice should heal when HP is not full.")
	if stage.coins != 0:
		_fail("Fever heal slice should not give coin before HP is full.")
	if stage.combo != 6:
		_fail("Fever heal slice should not reset combo.")

func _assert_fever_full_heal_slice_gives_coin(stage) -> void:
	_prepare_stage_for_fever_slice(stage, 7)
	stage.hp = GameBalance.MAX_HP
	stage.coins = 3
	stage.score = 10
	_add_zone_object(stage, "heal")
	stage.handle_player_action("tap")
	await process_frame

	if stage.hp != GameBalance.MAX_HP:
		_fail("Fever full heal slice should keep HP full.")
	if stage.coins != 3 + GameBalance.FEVER_GOOD_ITEM_SLICE_COIN_BONUS:
		_fail("Fever full heal slice should give coin bonus.")
	if stage.score != 10 + GameBalance.FEVER_GOOD_ITEM_SLICE_COIN_BONUS * 2:
		_fail("Fever full heal slice should score the coin bonus with fever multiplier.")
	if stage.combo != 7:
		_fail("Fever full heal slice should not reset combo.")

func _assert_fever_orb_slice_gives_coin(stage) -> void:
	_prepare_stage_for_fever_slice(stage, 8)
	stage.coins = 4
	stage.score = 12
	_add_zone_object(stage, "fever_orb")
	stage.handle_player_action("tap")
	await process_frame

	if stage.coins != 4 + GameBalance.FEVER_GOOD_ITEM_SLICE_COIN_BONUS:
		_fail("Fever orb slice should give coin bonus.")
	if stage.score != 12 + GameBalance.FEVER_GOOD_ITEM_SLICE_COIN_BONUS * 2:
		_fail("Fever orb slice should score the coin bonus with fever multiplier.")
	if stage.combo != 8:
		_fail("Fever orb slice should not reset combo.")

func _assert_non_fever_good_item_slice_keeps_penalty(stage) -> void:
	_clear_stage_objects(stage)
	stage.fever_mode.reset()
	stage._sync_fever_state()
	stage.fever = 50
	stage.fever_mode.fever = stage.fever
	stage.combo = 9
	stage.coins = 0
	_add_zone_object(stage, "coin")
	stage.handle_player_action("tap")
	await process_frame

	if stage.combo != 0:
		_fail("Non-fever good item slice should still reset combo.")
	if stage.fever != 50 - GameBalance.GOOD_ITEM_BREAK_FEVER_PENALTY:
		_fail("Non-fever good item slice should still apply fever penalty.")
	if stage.coins != 0:
		_fail("Non-fever good item slice should not collect coin.")

func _prepare_stage_for_fever_slice(stage, combo_value: int) -> void:
	_clear_stage_objects(stage)
	stage.active = true
	stage.fever_mode.start()
	stage._sync_fever_state()
	stage.spawner.set_fever_rush_enabled(false)
	stage.combo = combo_value

func _clear_stage_objects(stage) -> void:
	for child in stage.object_root.get_children():
		child.free()

func _add_zone_object(stage, type_name: String):
	var object = INTERACTABLE_OBJECT_SCENE.instantiate()
	stage.object_root.add_child(object)
	object.setup(type_name)
	object.position = GameBalance.ACTION_ZONE_CENTER
	return object

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
