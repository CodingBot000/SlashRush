extends SceneTree

const GAME_HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")
const GameBalance := preload("res://scripts/data/GameBalance.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var hud = GAME_HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame
	hud.show_runner()

	var hearts = hud.find_child("HPHearts", true, false)
	if hearts == null:
		_fail("GameHUD should draw HP hearts without relying on text glyphs.")
		return
	if not hearts.visible:
		_fail("HP heart display should be visible during gameplay.")
		return
	if hearts.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("HP heart display should not block gameplay touch input.")
		return
	if hud.hp_label.visible or hud.hp_label.text != "":
		_fail("HP text label should not render unicode hearts on Android.")
		return

	hud.update_runner(0, 2, 0, 0, false, 0)
	if hearts.current_hp != 2 or hearts.max_hp != GameBalance.MAX_HP:
		_fail("HP heart display should reflect runner HP.")
		return

	hud.update_boss(0, 1, 10, 10, "", 1.0)
	if hearts.current_hp != 1:
		_fail("HP heart display should reflect boss HP.")
		return

	hud.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
