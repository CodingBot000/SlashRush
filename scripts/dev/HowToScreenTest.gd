extends SceneTree

const HOW_TO_SCREEN_SCENE := preload("res://scenes/ui/HowToScreen.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/game/MainMenu.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var how_to_screen := HOW_TO_SCREEN_SCENE.instantiate()
	root.add_child(how_to_screen)
	await process_frame

	var card_row := how_to_screen.get_node_or_null("SafeArea/Layout/CardScroll/CardRow")
	if card_row == null:
		_fail("How To card row was not created.")
		return
	if card_row.get_child_count() != 5:
		_fail("How To screen should create exactly 5 cards.")
		return

	var expected_tags := [
		"enemy_basic / bomb",
		"enemy_fast",
		"enemy_armor",
		"coin / fever_orb / heal",
		"combo / fever"
	]
	for expected_tag in expected_tags:
		if not _card_row_has_tag(card_row, expected_tag):
			_fail("Missing How To target mapping: %s" % expected_tag)
			return

	if how_to_screen.get_node_or_null("SafeArea/Layout/Footer/BackButton") == null:
		_fail("How To screen is missing BackButton.")
		return
	if how_to_screen.get_node_or_null("SafeArea/Layout/Footer/StartButton") == null:
		_fail("How To screen is missing StartButton.")
		return

	var main_menu := MAIN_MENU_SCENE.instantiate()
	root.add_child(main_menu)
	await process_frame

	var how_to_button := _find_button_with_text(main_menu, "HOW TO")
	if how_to_button == null:
		_fail("MainMenu is missing HOW TO button.")
		return
	if how_to_button.disabled:
		_fail("MainMenu HOW TO button should be enabled.")
		return

	quit()

func _card_row_has_tag(card_row: Node, expected_tag: String) -> bool:
	for card in card_row.get_children():
		var tag_label := card.find_child("TargetTags", true, false)
		if tag_label is Label and expected_tag in tag_label.text:
			return true
	return false

func _find_button_with_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var found := _find_button_with_text(child, text)
		if found:
			return found
	return null

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
