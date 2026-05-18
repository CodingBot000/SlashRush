extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var slash_sprite = player.find_child("SwordSlash", true, false)
	if slash_sprite == null:
		_fail("Player should create a SwordSlash sprite.")
		return
	if not is_equal_approx(slash_sprite.rotation_degrees, 20.0):
		_fail("SwordSlash should be rotated +20 degrees.")
		return

	player.play_slash()
	await process_frame
	if not slash_sprite.visible:
		_fail("SwordSlash should be visible only while attacking.")
		return
	if not is_equal_approx(slash_sprite.rotation_degrees, 20.0):
		_fail("SwordSlash rotation should stay +20 degrees while attacking.")
		return

	player.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
