extends SceneTree

const COMBO_IMPACT_POPUP_SCRIPT := preload("res://scripts/ui/ComboImpactPopup.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var popup = COMBO_IMPACT_POPUP_SCRIPT.new()
	root.add_child(popup)
	await process_frame

	if popup.combo_image == null:
		_fail("Combo impact popup should create a texture node.")
		return
	if popup.combo_image.texture == null:
		_fail("Combo impact popup should load combo.png.")
		return
	if popup.combo_image.size != Vector2(500.0, 375.0):
		_fail("Combo impact popup should use 500x375 as its final size.")
		return
	if popup.digit_textures.size() != 10:
		_fail("Combo impact popup should cache digit textures for 0 through 9.")
		return
	for digit in range(10):
		if popup.digit_textures[digit] == null:
			_fail("Combo impact popup should load every digit texture.")
			return

	popup.play(27)
	if not popup.visible:
		_fail("Combo impact popup should become visible when played.")
		return
	if not is_equal_approx(popup.combo_group.scale.x, 0.4) or not is_equal_approx(popup.combo_group.scale.y, 0.4):
		_fail("Combo impact popup should start at 200px width scale.")
		return
	if popup.digit_images.size() != 2:
		_fail("Combo impact popup should create one digit node per displayed digit.")
		return
	if popup.digit_images[0].texture != popup.digit_textures[2] or popup.digit_images[1].texture != popup.digit_textures[7]:
		_fail("Combo impact popup should display the actual combo count digits.")
		return

	popup.combo_group.scale = Vector2(0.85, 0.85)
	popup.play(3)
	if not is_equal_approx(popup.combo_group.scale.x, 0.4):
		_fail("Combo impact popup should restart from the initial scale when replayed.")
		return
	if popup.digit_images[0].texture != popup.digit_textures[3]:
		_fail("Combo impact popup should update digits when replayed with a new combo.")
		return
	if popup.digit_images[1].visible:
		_fail("Combo impact popup should hide unused digit nodes when combo digit count shrinks.")
		return

	await create_timer(0.42).timeout
	if popup.visible:
		_fail("Combo impact popup should hide after the 0.5 second animation.")
		return

	popup.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
