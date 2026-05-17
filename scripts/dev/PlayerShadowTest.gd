extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const GROUND_LOOPER_SCRIPT := preload("res://scripts/game/GroundLooper.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ground = GROUND_LOOPER_SCRIPT.new()
	root.add_child(ground)
	ground.setup()

	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var shadow = player.get_node_or_null("FootShadow")
	if shadow == null:
		push_error("Player foot shadow was not created.")
		quit(1)
		return
	if shadow.z_index <= ground.z_index:
		push_error("Player foot shadow should render above the ground layer.")
		quit(1)
		return
	if player.visual_root == null or shadow.z_index >= player.visual_root.z_index:
		push_error("Player foot shadow should render below the player visual.")
		quit(1)
		return

	quit()
